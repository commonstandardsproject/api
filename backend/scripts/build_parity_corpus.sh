#!/usr/bin/env bash
# Build a representative parity-diff corpus by pulling real IDs from the
# running Phoenix port (assumed to be aimed at production read-only Mongo
# via `MONGO_URL=...mongodb+srv://...` + MONGO_READ_ONLY=1).
#
# Output: paths-newline-separated to stdout. Pipe to `parity_diff.sh`.
#
# Usage:
#   CSP_API_KEY=... ./scripts/build_parity_corpus.sh > /tmp/parity_corpus.txt
#   CSP_API_KEY=... ./scripts/parity_diff.sh $(< /tmp/parity_corpus.txt)
set -eu

KEY="${CSP_API_KEY:?CSP_API_KEY is required}"
PHX="${PHX_BASE:-http://localhost:4000}"

curl_phx() { curl -s -H "Api-Key: $KEY" "$PHX$1"; }

# 1. Listing endpoints.
echo "/api/v1/jurisdictions"
echo "/api/v1/swagger_doc"
echo "/api/v1/sitemap.xml"

# 2. Per-jurisdiction detail for a mix of types. Sample ~40 of each major
#    type (state, organization, school) — gives ~120 detail URLs with
#    enough variety to exercise the joined-standard-sets path.
juris="$(curl_phx /api/v1/jurisdictions)"

for type in state organization school; do
  echo "$juris" \
    | jq -r --arg t "$type" '.data | map(select(.type == $t)) | .[0:40] | .[].id' \
    | while IFS= read -r id; do
        echo "/api/v1/jurisdictions/$id"
      done
done

# 3. From a slice of jurisdictions, pull their standard sets and the
#    underlying standard documents — exercises /standard_sets/:id and
#    /standard_documents/:id.
echo "$juris" \
  | jq -r '.data | map(select(.type=="state")) | .[0:20] | .[].id' \
  | while IFS= read -r juris_id; do
      detail="$(curl_phx "/api/v1/jurisdictions/$juris_id")"

      # First 3 standard sets per jurisdiction (cap to keep corpus ~200).
      echo "$detail" \
        | jq -r '.data.standardSets // [] | .[0:3] | .[].id' \
        | while IFS= read -r set_id; do
            echo "/api/v1/standard_sets/$set_id"
            echo "/api/v1/standard_sets/$set_id?standardsAsArray=true"
          done
    done

# 4. Sample a handful of standard documents from a popular jurisdiction so
#    the /standard_documents/:id path gets coverage.
detail_md="$(curl_phx /api/v1/jurisdictions/49FCDFBD2CF04033A9C347BFA0584DF0)"
echo "$detail_md" \
  | jq -r '.data.standardSets // [] | .[0:10] | .[] | .document.id' \
  | sort -u \
  | while IFS= read -r doc_id; do
      [ -n "$doc_id" ] && echo "/api/v1/standard_documents/$doc_id"
    done
