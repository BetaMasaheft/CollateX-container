#!/usr/bin/env bats

# Golden-output contract tests for the CollateX service.
#
# Expects a running service (default http://localhost:17105, override via
# COLLATEX_URL), e.g.:
#
#   docker build -t collatex-service .
#   docker run -d --rm -p 17105:17105 collatex-service
#   bats test/collate_spec.bats
#
# Requires curl and jq. Expected files hold the exact service output
# (JSON normalised with `jq -S .`); regenerate them the same way after a
# deliberate CollateX upgrade.

BASE_URL="${COLLATEX_URL:-http://localhost:17105}"
FIXTURES="$BATS_TEST_DIRNAME/fixtures"

@test "service root responds" {
  code=$(curl -so /dev/null -w '%{http_code}' "$BASE_URL/")
  [ "$code" -eq 200 ]
}

@test "container reports healthy to docker" {
  result=$(docker ps | grep -c 'healthy')
  [ "$result" -eq 1 ]
}

@test "POST /collate aligns two witnesses (JSON)" {
  result=$(curl -sf -H 'Content-Type: application/json' -H 'Accept: application/json' \
    --data @"$FIXTURES/simple-request.json" "$BASE_URL/collate" | jq -S .)
  diff <(echo "$result") "$FIXTURES/simple-expected.json"
}

@test "POST /collate aligns three Ethiopic witnesses (JSON)" {
  result=$(curl -sf -H 'Content-Type: application/json' -H 'Accept: application/json' \
    --data @"$FIXTURES/ethiopic-request.json" "$BASE_URL/collate" | jq -S .)
  diff <(echo "$result") "$FIXTURES/ethiopic-expected.json"
}

@test "POST /collate produces a TEI apparatus" {
  result=$(curl -sf -H 'Content-Type: application/json' -H 'Accept: application/tei+xml' \
    --data @"$FIXTURES/simple-request.json" "$BASE_URL/collate")
  diff <(echo "$result") "$FIXTURES/simple-expected.tei.xml"
}
