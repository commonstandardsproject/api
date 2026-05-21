#!/usr/bin/env bash
# Diffs the JSON responses of mutating PR endpoints across two backends.
# Drives create_blank → user_update → comment → submit → change_status
# against each base URL in turn, captures the raw response bodies, then
# uses `jq` to flatten + `comm` (via parity_diff.sh's primitives) to
# categorize differences.
#
# Assumes the two backends point at SEPARATE Mongo databases — the test
# user is created from scratch on each side, so we get matching initial
# state without trying to dump/restore.
#
# Usage:
#   RUBY_BASE=http://localhost:3000 \
#     PHX_BASE=http://localhost:4000 \
#     CSP_API_KEY=... \
#     ./scripts/post_parity_diff.sh
#
# Both backends MUST:
#   * Accept `Authorization: TEST` as a JWT bypass (Ruby: ENVIRONMENT=test;
#     Phoenix: config :csp_api, :auth, jwt_test_bypass?: true)
#   * Have a user with the given API key and isCommitter:true
set -eu

KEY="${CSP_API_KEY:?CSP_API_KEY is required}"
RUBY="${RUBY_BASE:-http://localhost:3000}"
PHX="${PHX_BASE:-http://localhost:4000}"
OUT_DIR="${OUT_DIR:-/tmp/post_parity}"
mkdir -p "$OUT_DIR"

H_KEY="Api-Key: $KEY"
H_AUTH="Authorization: TEST"
H_JSON="Content-Type: application/json"

# Hits a path against $1, saves response body to $2, prints status.
hit() {
  local base="$1" method="$2" path="$3" out="$4" body="${5:-}"
  if [ -n "$body" ]; then
    curl -s -X "$method" -H "$H_KEY" -H "$H_AUTH" -H "$H_JSON" \
         -d "$body" -w '%{http_code}' -o "$out" "$base$path"
  else
    curl -s -X "$method" -H "$H_KEY" -H "$H_AUTH" -w '%{http_code}' \
         -o "$out" "$base$path"
  fi
}

# Runs the full mutating sequence against one base URL.
run_sequence() {
  local base="$1" tag="$2"

  # 1. Create blank PR
  hit "$base" POST "/api/v1/pull_requests" "$OUT_DIR/${tag}_01_create.json" '{}' > /dev/null
  local pr_id
  pr_id=$(jq -r '.data.id // .data._id // empty' "$OUT_DIR/${tag}_01_create.json")
  if [ -z "$pr_id" ]; then
    echo "[$tag] could not extract PR id from create response" >&2
    cat "$OUT_DIR/${tag}_01_create.json" >&2
    return 1
  fi
  echo "$pr_id" > "$OUT_DIR/${tag}_pr_id"

  # 2. user_update — populate a minimal standardSet
  local update_body
  update_body=$(cat <<'JSON'
{"data":{"standardSet":{"id":"PARITY_TEST_SET","title":"Parity Test","subject":"Math","educationLevels":["01"],"jurisdiction":{"id":"PARITY","title":"Parity Jurisdiction"},"document":{"id":"PARITY_DOC"},"standards":{"S1":{"id":"S1","depth":0,"position":1,"description":"only standard"}}}}}
JSON
)
  hit "$base" POST "/api/v1/pull_requests/$pr_id" "$OUT_DIR/${tag}_02_update.json" "$update_body" > /dev/null

  # 3. Comment
  hit "$base" POST "/api/v1/pull_requests/$pr_id/comment" "$OUT_DIR/${tag}_03_comment.json" '{"comment":"looks good"}' > /dev/null

  # 4. Submit (changes status to approval-requested)
  hit "$base" POST "/api/v1/pull_requests/$pr_id/submit" "$OUT_DIR/${tag}_04_submit.json" '{}' > /dev/null

  # 5. change_status — reject (don't approve, to avoid upserting the test set)
  hit "$base" POST "/api/v1/pull_requests/$pr_id/change_status" \
      "$OUT_DIR/${tag}_05_change_status.json" '{"status":"rejected","message":"end of test"}' > /dev/null

  # 6. show after the sequence
  hit "$base" GET "/api/v1/pull_requests/$pr_id" "$OUT_DIR/${tag}_06_show.json" > /dev/null
}

# Flatten one response to sorted [path,value] tuples, dropping fields
# that legitimately differ between runs (timestamps, UUIDs, PR ids).
flatten() {
  jq -c '
    walk(if type == "object" then
      with_entries(select(.key | test("^(id|_id|createdAt|updatedAt|updatedAtDate|forkedFromStandardSetId|asanaTaskId|pullRequestUrl|submitterId)$") | not))
    else . end)
    | paths(scalars) as $p | [$p, getpath($p)]
  ' "$1" | LC_ALL=C sort
}

categorize_diff() {
  local r="$1" p="$2" label="$3"
  flatten "$r" > "$OUT_DIR/${label}.r.flat"
  flatten "$p" > "$OUT_DIR/${label}.p.flat"
  local ruby_only phx_only extra_null
  ruby_only=$(comm -23 "$OUT_DIR/${label}.r.flat" "$OUT_DIR/${label}.p.flat" | wc -l | tr -d ' ')
  phx_only=$(comm -13 "$OUT_DIR/${label}.r.flat" "$OUT_DIR/${label}.p.flat" | wc -l | tr -d ' ')
  extra_null=$(comm -13 "$OUT_DIR/${label}.r.flat" "$OUT_DIR/${label}.p.flat" | grep -c ',null\]$' || true)

  if [ "$ruby_only" -eq 0 ] && [ "$phx_only" -eq 0 ]; then
    printf '%-40s ok\n' "$label"
    return 0
  fi

  printf '%-40s ruby_only=%d phx_only=%d (extra_null=%d)\n' \
    "$label" "$ruby_only" "$phx_only" "$extra_null"

  if [ "$ruby_only" -gt 0 ]; then
    echo "  ruby_only first 3:"
    comm -23 "$OUT_DIR/${label}.r.flat" "$OUT_DIR/${label}.p.flat" | head -3 | sed 's/^/    /'
  fi
  if [ "$phx_only" -gt 0 ]; then
    echo "  phx_only  first 3:"
    comm -13 "$OUT_DIR/${label}.r.flat" "$OUT_DIR/${label}.p.flat" | head -3 | sed 's/^/    /'
  fi
}

echo "==> running sequence against Ruby ($RUBY)"
run_sequence "$RUBY" "ruby"
echo "==> running sequence against Phoenix ($PHX)"
run_sequence "$PHX" "phx"

echo
echo "==> diff"
for step in 01_create 02_update 03_comment 04_submit 05_change_status 06_show; do
  categorize_diff "$OUT_DIR/ruby_${step}.json" "$OUT_DIR/phx_${step}.json" "$step"
done
