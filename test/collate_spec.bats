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
  container="${COLLATEX_CONTAINER:-collatex}"
  status=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$container")
  [ "$status" = "healthy" ]
}

@test "POST /collate aligns two witnesses (JSON)" {
  result=$(curl -sf -H 'Content-Type: application/json' -H 'Accept: application/json' \
    --data @"$FIXTURES/simple-request.json" "$BASE_URL/collate" | jq -S .)
  diff <(echo "$result") "$FIXTURES/simple-expected.json"
}

# eXist-db's Apache HttpClient hangs on Grizzly's chunked keep-alive replies
# (BetaMasaheft/collatex-service#7). HttpClient sends Expect: 100-continue on
# POSTs, which makes CollateX answer with Transfer-Encoding: chunked and no
# Content-Length. The image must re-frame those responses with Content-Length.
@test "POST /collate JSON response includes Content-Length under Expect: 100-continue" {
  headers=$(curl -sD - -o /dev/null --http1.1 \
    -H 'Content-Type: application/json' -H 'Accept: application/json' -H 'Expect: 100-continue' \
    --data @"$FIXTURES/simple-request.json" "$BASE_URL/collate")
  echo "$headers" | grep -qi '^Content-Length:'
  ! echo "$headers" | grep -qi '^Transfer-Encoding:[[:space:]]*chunked'
}

@test "POST /collate TEI response includes Content-Length under Expect: 100-continue" {
  headers=$(curl -sD - -o /dev/null --http1.1 \
    -H 'Content-Type: application/json' -H 'Accept: application/tei+xml' -H 'Expect: 100-continue' \
    --data @"$FIXTURES/simple-request.json" "$BASE_URL/collate")
  echo "$headers" | grep -qi '^Content-Length:'
  ! echo "$headers" | grep -qi '^Transfer-Encoding:[[:space:]]*chunked'
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

# Raw servlet-layer goldens for production witness ids (ESamm007 / ESmr001).
# Captured from collatex-tools 1.7.1 in this image (same jar as the legacy
# host servlet). Stack cutover parity for /api/collatex lives in betmas-e2e
# (legacy-parity fixtures); this suite only asserts the CollateX POST surface.
# See BetaMasaheft/collatex-service#5.
@test "POST /collate servlet-parity JSON (ESamm007/ESmr001)" {
  result=$(curl -sf -H 'Content-Type: application/json' -H 'Accept: application/json' \
    --data @"$FIXTURES/servlet-parity-request.json" "$BASE_URL/collate" | jq -S .)
  diff <(echo "$result") "$FIXTURES/servlet-parity-expected.json"
}

@test "POST /collate servlet-parity TEI (ESamm007/ESmr001)" {
  result=$(curl -sf -H 'Content-Type: application/json' -H 'Accept: application/tei+xml' \
    --data @"$FIXTURES/servlet-parity-request.json" "$BASE_URL/collate")
  diff <(echo "$result") "$FIXTURES/servlet-parity-expected.tei.xml"
}
