# Source outage and partial-build runbook

NJ DOE requests have a request-level status that is separate from row-level
`value_status`:

- `actual`: an artifact was retrieved, validated, and parsed;
- `not_published`: the source deliberately does not publish that component/year;
- `not_yet_observed`: the requested observation is structurally later than the
  latest published source;
- `source_unavailable`: DNS, timeout, redirect, HTTP, or retry exhaustion;
- `parse_error`: bytes arrived, but content/signature/schema validation failed.

Use `get_source_results(x)` for package results. It records source URL,
retrieval time, SHA-256 digest when available, and warning/error context. Do not
infer source success from the presence of some rows: for example, finance has
separate spending and state-aid records.

## Profile builds

`Rscript site/build-data.R` is strict. It writes
`site/_bundles/build-manifest.json`, then stops if any required domain/year (or
NJGPA subject) is incomplete. The profiles workflow renders and deploys only
after this command succeeds.

Use `Rscript site/build-data.R --allow-partial ...` only for a deliberate local
diagnostic or preview. The manifest records `allow_partial: true`; do not deploy
that output as a complete production build.

The optional enrichment command `Rscript site/discovery-build.R` follows the
same rule. It writes `site/_bundles/discovery-build-manifest.json`, refuses to
write an incomplete category cache in strict mode, and accepts partial caches
only with `--allow-partial`. Cached discovery artifacts without embedded
per-request provenance are rejected and must be rebuilt with `--refresh`.

For recovery:

1. Inspect every non-`actual` manifest row, its URL, status, and error.
2. For `source_unavailable`, verify NJ DOE service health and rerun after the
   outage. Do not change parser assertions for an HTTP outage.
3. For `parse_error`, preserve the artifact digest, compare the upstream format
   with the adapter fixture, update the domain parser and fixture provenance,
   then rerun offline contracts.
4. For `not_published` or `not_yet_observed`, confirm the registry marks the gap
   as deliberate/optional. If a required row has that status, correct the build
   request or registry only after verifying publication coverage.
5. Rerun the manual live-source canary. `SOURCE_OUTAGE` indicates transport;
   `PARSER_OR_CONTRACT_REGRESSION` indicates valid bytes that failed parsing or
   a pinned contract.
