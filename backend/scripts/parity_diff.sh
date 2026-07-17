#!/usr/bin/env bash
# Structured parity diff between Phoenix (local) and Ruby (prod) responses.
#
# Flattens each JSON response to one [path, value] tuple per scalar (via jq),
# sorts, then uses `comm` to find paths present in only one side. Categorizes
# the differences:
#
#   extra_null    Phoenix emits a `null` for a path Ruby doesn't have
#                 (acceptable wire diff — Ruby's grape-entity drops nils)
#   ruby_only     Path/value present in Ruby but absent (non-null) in Phoenix
#   phx_extra     Path/value present in Phoenix (non-null) but absent in Ruby
#   value_change  Same path, different scalar value
#
# Usage: CSP_API_KEY=… ./parity_diff.sh path1 path2 ...
#
# Env knobs:
#   CSP_API_KEY   required — any key valid against both backends
#   PHX_BASE      default http://localhost:4000
#   RUBY_BASE     default https://api.commonstandardsproject.com
#   OUT_DIR       default /tmp/parity
set -u
KEY="${CSP_API_KEY:?CSP_API_KEY is required (see backend/.env.example)}"
PHX="${PHX_BASE:-http://localhost:4000}"
RUBY="${RUBY_BASE:-https://api.commonstandardsproject.com}"
OUT_DIR="${OUT_DIR:-/tmp/parity}"
mkdir -p "$OUT_DIR"

# `jq` filter: emit one JSON line per scalar leaf, shaped [path_array, value].
# Sorting these lines as text effectively sorts by path then value.
FLATTEN='paths(scalars) as $p | [$p, getpath($p)]'

flatten() {
  local f="$1" out="$2"
  jq -c "$FLATTEN" "$f" | LC_ALL=C sort > "$out"
}

total=0
clean=0

for path in "$@"; do
  total=$((total+1))
  slug=$(printf '%s' "$path" | tr '/?&=' '____' | sed 's/^_*//; s/_*$//')

  r="$OUT_DIR/r_${slug}.json"
  p="$OUT_DIR/p_${slug}.json"

  r_code=$(curl -s -H "Api-Key: $KEY" -H "Authorization: TEST" -w "%{http_code}" -o "$r" "$RUBY$path")
  p_code=$(curl -s -H "Api-Key: $KEY" -H "Authorization: TEST" -w "%{http_code}" -o "$p" "$PHX$path")

  if [ "$r_code" != "$p_code" ]; then
    printf '%s\n  status: ruby=%s phx=%s\n' "$path" "$r_code" "$p_code"
    continue
  fi

  # Non-JSON (e.g. /sitemap.xml) — fall back to byte equality.
  if ! jq -e . "$r" >/dev/null 2>&1 || ! jq -e . "$p" >/dev/null 2>&1; then
    if cmp -s "$r" "$p"; then
      clean=$((clean+1))
      printf '%s\n  ok (byte-identical, non-JSON)\n' "$path"
    else
      printf '%s\n  non-JSON content differs\n' "$path"
    fi
    continue
  fi

  flatten "$r" "$OUT_DIR/r_${slug}.flat"
  flatten "$p" "$OUT_DIR/p_${slug}.flat"

  # comm -23: lines only in file 1 (Ruby).  comm -13: only in file 2 (Phoenix).
  ruby_only="$OUT_DIR/${slug}.ruby_only"
  phx_only="$OUT_DIR/${slug}.phx_only"
  comm -23 "$OUT_DIR/r_${slug}.flat" "$OUT_DIR/p_${slug}.flat" > "$ruby_only"
  comm -13 "$OUT_DIR/r_${slug}.flat" "$OUT_DIR/p_${slug}.flat" > "$phx_only"

  # Phoenix-only lines whose value is null = the agreed-acceptable
  # "extra null key" pattern.
  extra_null=$(grep -c ',null\]$' "$phx_only" || true)
  phx_other=$(grep -cv ',null\]$' "$phx_only" || true)
  ruby_count=$(wc -l < "$ruby_only" | tr -d ' ')

  # value_change is the size of the *intersection of paths* with different
  # values. Compute by extracting just the path arrays from each side and
  # finding paths that appear in both ruby_only and phx_only.
  paths_only() { jq -c '.[0]' "$1" | LC_ALL=C sort -u; }
  paths_only "$ruby_only" > "$OUT_DIR/${slug}.r_paths"
  paths_only "$phx_only" > "$OUT_DIR/${slug}.p_paths"
  value_change=$(comm -12 "$OUT_DIR/${slug}.r_paths" "$OUT_DIR/${slug}.p_paths" | wc -l | tr -d ' ')

  # Adjust the raw counts: paths that show up in BOTH ruby_only and phx_only
  # were counted in each — they're really value_change, not ruby_only or
  # phx_other. Subtract.
  ruby_only_count=$((ruby_count - value_change))
  phx_other=$((phx_other - value_change))

  if [ "$extra_null" -eq 0 ] && [ "$ruby_only_count" -eq 0 ] && [ "$phx_other" -eq 0 ] && [ "$value_change" -eq 0 ]; then
    clean=$((clean+1))
    printf '%s\n  ok (byte-identical)\n' "$path"
    continue
  fi

  printf '%s\n' "$path"
  [ "$extra_null"      -gt 0 ] && printf '  extra_null:   %d  (Phoenix emits null where Ruby drops the key)\n' "$extra_null"
  [ "$value_change"    -gt 0 ] && printf '  value_change: %d  (same path, different value)\n' "$value_change"
  [ "$ruby_only_count" -gt 0 ] && printf '  ruby_only:    %d  (Ruby has, Phoenix missing)\n' "$ruby_only_count"
  [ "$phx_other"       -gt 0 ] && printf '  phx_extra:    %d  (Phoenix has non-null, Ruby missing)\n' "$phx_other"

  if [ "$value_change" -gt 0 ]; then
    echo "    value_change examples:"
    comm -12 "$OUT_DIR/${slug}.r_paths" "$OUT_DIR/${slug}.p_paths" | head -3 | while IFS= read -r pth; do
      r_val=$(grep -F "$pth," "$ruby_only" | head -1)
      p_val=$(grep -F "$pth," "$phx_only" | head -1)
      printf '      ruby: %s\n      phx:  %s\n' "$r_val" "$p_val"
    done
  fi
  if [ "$ruby_only_count" -gt 0 ]; then
    echo "    ruby_only examples (NOT in extra_null bucket):"
    grep -v -F -f "$OUT_DIR/${slug}.p_paths" "$ruby_only" | head -3 | sed 's/^/      /'
  fi
  if [ "$phx_other" -gt 0 ]; then
    echo "    phx_extra examples:"
    grep -v ',null\]$' "$phx_only" | grep -v -F -f "$OUT_DIR/${slug}.r_paths" | head -3 | sed 's/^/      /'
  fi
done

echo
echo "=== Summary: $clean/$total fully clean (modulo acceptable extra-null) ==="
