# Docker container for CollateX

Wraps [collatex-tools](https://collatex.net/) 1.7.1 as an HTTP service on port **17105**.

Published responses are framed by an in-image nginx reverse proxy so clients receive `Content-Length` instead of chunked encoding. That avoids hangs in Apache HttpClient-based stacks (for example eXist-db EXPath `hc:send-request`) when the client sends `Expect: 100-continue`. See [#7](https://github.com/BetaMasaheft/collatex-service/issues/7).

## Run

```sh
docker build -t collatex-service .
docker run -d --rm -p 17105:17105 collatex-service
```

## HTTP POST requests with CURL

```sh
curl --header "Content-Type: application/json" --header "Accept: application/tei+xml" --request POST --data '{"witnesses":[{"id":"W1","content":"<p>Hallo</p>"},{"id":"W2","content":"<p>Hello</p>"}],"algorithm":"dekker","tokenComparator":{"type":"equality"},"joined":true,"transpositions":true}' http://localhost:17105/collate
```

`Accept: application/json` returns the alignment table as JSON instead.

## Tests

Golden-output contract tests live in `test/collate_spec.bats` (requires `bats`, `curl`, `jq`; run against a started container as above):

```sh
bats --tap test/collate_spec.bats
```

CI runs them on every push before the image is built and pushed to ghcr. The expected files under `test/fixtures/` capture the exact service output (JSON normalised with `jq -S .`); regenerate them the same way after a deliberate CollateX version bump.

`servlet-parity-*` fixtures freeze a raw `POST /collate` with production witness ids (`ESamm007` / `ESmr001`) against collatex-tools 1.7.1 (same jar as the legacy host servlet). The BetMasWeb `/api/collatex` wrapper is gated separately in [betmas-e2e](https://github.com/BetaMasaheft/betmas-e2e) via `cypress/fixtures/legacy-parity/` — see [#5](https://github.com/BetaMasaheft/collatex-service/issues/5).
