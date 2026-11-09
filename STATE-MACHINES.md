# njschooldata: data flow and state machines

What states the data passes through on its way from an NJ DOE file to a frame
a caller gets back, what must hold in each state, which transitions exist, and
which bad states the code can actually reach. Written 2026-11-09 from the code
on `master`. Update it in the same commit as any change to a transition below.

Companion docs: `CLAUDE.md` (family rules and traps), `R/cache.R` (why there
is no schema version to bump), `R/release_sources.R` (held release assets),
`dev-docs/source-outage-runbook.md`.

---

## 1. The pipeline at a glance

```
NJ DOE publication
   │
   ├─ bundled in inst/extdata (new_jersey_shipped_sources manifest) ─┐
   │                                                                 │
   ├─ held as a release asset (new_jersey_release_sources: 130 files │
   │   by URL, byte length, sha256)                                  │
   │      ▼ M2: shared historical source store (vendored resolver)   │
   │   verified blob ──copy──▶ per-call temp file ◀──────────────────┘
   │
   └─ any URL neither manifest names (current enrollment 2023+, current-year
      files, directory)
          ▼ A: download_source() transport, optionally into a persistent
            source cache (spr-workbooks/, source-artifacts/, sped-placement/)
          validated local file
        │
        ▼  parse → process_*() → attach_nces_ids() → tidy_*()
derived frame
        │
        ▼  M3: in-memory session cache (per R session, opt-in use_cache)
        ▼  M4: multi-year composition (combine_source_captures)
caller
```

Directory (M5) is always fetched live and never enters M2, M3 or a persistent
source cache.

`download_source()` resolves in a fixed order: (1) a bundled package source
whose URL matches a complete publication; (2) a held release asset (never
falls through to nj.gov once matched); (3) the validated persistent cache
entry, if a `cache_path` was given; (4) a live request. Steps 1 and 2 are
skipped only when a test injects its own `request_fn`, or when
`options(njschooldata.release_sources = FALSE)` opts out of step 2.

## 2. What triggers a regeneration

| Change | What makes the old value unreachable | Automatic? |
|---|---|---|
| Parser / processor / tidier change | Nothing on disk holds parsed output; the session cache dies with the R session | Yes, at the next session. A running session keeps old parsed entries until `njsd_cache_clear()` |
| NJ DOE republishes a held file | Nothing: the release asset is pinned by sha256 | No. A new release asset has to be cut |
| NJ DOE republishes a live-fetched file in place | The persistent source cache keeps the first bytes it validated | No. `njsd_workbook_cache_clear()` or deleting the cache entry forces a fresh pull |
| Download URL changes | The SPR cache file name embeds `sha256(url)`; `source-artifacts/` is keyed by `sha256(url)`; the sidecar's `requested_url` must match | Yes (new key). Old entries stay on disk, unreachable |
| Package version change | Nothing persistent to invalidate (parsed output is session-only) | n/a |
| Directory source changes | Nothing to invalidate; directory is never cached | n/a |

---

## M1. Source policy

njschooldata has no `source =` argument and no live-authorization gate. The
policy is the resolution order in section 1: a URL a manifest names is served
from the package (bundled bytes or release asset) and never from nj.gov; any
other URL is fetched live. `use_cache` only selects the in-memory session
cache. A held URL that fails verification stops with a typed
`njschooldata_historical_*` error; it is never retried against nj.gov.

| From | Condition | To |
|---|---|---|
| request | URL in `new_jersey_shipped_sources` (complete publication) | package source (installed bytes, length + sha256 checked, private temp copy) |
| request | URL in `new_jersey_release_sources` and release sources on | release asset via M2 (temp copy) |
| request | URL held, asset missing or tampered | stop, `njschooldata_historical_*_error` |
| request | otherwise | transport A (live) |
| any | `NJSCHOOLDATA_OFFLINE` / `EGRESS_BOUNDARY=1` | M2 offline: an unseeded asset is a typed miss |

## M2. Historical source store (`R/resolve_historical_asset.R`)

Vendored byte-for-byte from the shared canonical resolver (store protocol v1).
Root: `STATE_SCHOOLDATA_HISTORICAL_ROOT`; else
`<NJSCHOOLDATA_CACHE_DIR or njschooldata.cache_dir>/historical-assets-v1`
when a package cache override is set; else the shared user-cache store.

Per blob: `absent` → `staging/<lease>/<sha>.partial` → `verified` → `evicted` |
`corrupt` → (repair) → `absent`. Per reader: `none` → `leased` → `parsing` →
`released`, or `orphaned` (owner died) → `reclaimed`. LOCK: `free` ⇄ `held` →
`held_by_dead_owner` → (explicit `historical_cache_recover()`) → `free`.

Invariants: a blob in `blobs/` always verifies; bytes under a lease are never
evicted or repaired; a held URL never falls through to nj.gov; a LOCK is never
taken over automatically; dead same-host leases are reclaimed under LOCK; the
source budget is 3 GiB, separate from any processed budget. Readers copy the
verified blob to a per-call temp file (a real copy, never a link), so a parser
that rewrites or unlinks its input cannot touch the store.

## A. Validated transport and persistent source cache (`R/source_transport.R`)

`download_source(url, source_type, cache_path = NULL, ...)` returns an
`njsd_source_result`. With no `cache_path` the bytes land in a per-call temp
file the caller releases. With a `cache_path` (SPR workbooks for URLs not held,
`source-artifacts/` for graduation / state aid / TGES, report-card temp paths)
the entry is a payload plus a `.source.rds` sidecar (requested URL, final URL,
type, clock, size, sha256).

Entry states: `absent` · `acquiring` (lock held) · `valid` (payload + matching
sidecar) · `legacy` (payload, no or foreign sidecar) · `corrupt` (sidecar
present, size or sha256 differs) · `sidecar_only` (no payload).

Lock states (`<cache_path>.acquiring/owner.rds`: pid, host, started):

| From | Condition | To |
|---|---|---|
| free | `dir.create` succeeds; owner record written | held |
| held | owner exits normally | free (`on.exit`) |
| held | owner on this host confirmed dead (`ps -p` / `tasklist`, never a signal) | free, warning (**new**) |
| held | no owner record and older than 2 hours | free, warning (**new**: locks from releases that wrote no owner) |
| held | owner alive on this host | wait, polling once a second up to `timeout` seconds, then busy (**new**: was busy at once) |
| held | liveness unknown, other host, or fresh owner-less lock | busy at once: `source_unavailable` "acquisition is already active" |

Entry transitions:

| From | Event | To |
|---|---|---|
| absent / sidecar_only | lock taken, request 2xx, redirect host allowed, artifact validates | sidecar promoted, then payload promoted → valid (**new order**) |
| absent | transport failure / HTTP error after retries | unchanged; `source_unavailable` |
| absent | bytes arrive but fail validation (HTML page, bad ZIP, wrong type) | unchanged; `parse_error` |
| valid | read: final URL allowed, artifact validates, size + sha256 match sidecar | valid; result `actual`, "Validated cache artifact reused." |
| legacy | read | unchanged; `source_unavailable` "explicit source repair is required" (never re-downloaded, never given an invented clock) |
| corrupt | read | unchanged; `parse_error` |
| legacy | `.adopt_source_cache()` with digest evidence | valid |
| any | `njsd_workbook_cache_clear()` | dead locks reclaimed first (**new**); entries with a live lock kept |

Invariants: a payload without a matching sidecar is never served; a cache miss
on a historical entry is never permission to re-download it; liveness is never
probed by signalling a process.

Reachable bad states found: **F1** (below).

## M3. Session cache (`R/cache.R`)

`.njsd_cache$data`, a list keyed by `fn_name + md5(args)`. In memory only, no
eviction, no schema version, no package version in the key (none is needed:
it cannot outlive the R session). Users: enrollment (`fetch_enr(use_cache =
TRUE)`, `fetch_enr_cached()`), ELL, absence, SPR sheet reads, SPED placement,
restraint and seclusion, and the doedata staff readers. No directory function
touches it.

| From | Event | To |
|---|---|---|
| absent | fetch with `use_cache = TRUE` | valid |
| valid (enrollment) | its retained source zip (`enrollment-sources/<year>-<sha>.zip`) missing or digest differs | refetched |
| valid | `njsd_cache_clear()` / `njsd_cache_remove()` / session ends | absent |

Enrollment retains its source zip under `<cache root>/enrollment-sources/` so
that every frame can carry `raw_path` and `raw_sha256` attributes pointing at
the exact bytes it was parsed from.

A persistent processed store (version in the key, byte
budget, cross-package eviction) does not apply: no parsed output is persisted.

## M4. Multi-year composition (`R/source_result.R`)

`capture_source_call()` / `capture_registered_source_call()` turn each year's
call into a capture (data + one provenance record); `combine_source_captures()`
assembles them. Used by `fetch_ell_multi()`, `fetch_absence_multi()`,
`fetch_finance_multi()`, `fetch_all_parcc()`, `fetch_all_njgpa()`,
`fetch_all_access()`, `fetch_all_chronic_absenteeism()`,
`fetch_all_6yr_grad_rate()`, `get_rc_databases()`, the SPED placement and TGES
multi fetchers and the progress wrappers.

Per year: `requested` → `gap` (`not_published` / `not_yet_observed`, from the
registry, no request) | `actual` | `source_unavailable` | `parse_error`.

| Condition | `allow_partial = FALSE` (default) | `allow_partial = TRUE` |
|---|---|---|
| registry gap | stop | keep going, record |
| transport failure | stop | warn (**new**), drop, record |
| parse error | stop | warn (**new**), drop, record (see decision D2) |
| any other error raised inside the year's call | stop, labelled `source_unavailable` (see decision D1) | warn (**new**), drop, record |
| every year dropped | stop | returns an empty frame with records (see decision D3) |

Invariants (**new**): the combined frame always carries `requested_years` and
`missing_years`; a short frame never arrives without an `njsd_partial_result`
warning; a strict failure's message keeps each underlying error text.

Reachable bad states found: **F3**.

## M5. Directory (`R/fetch_directory.R`, `R/directory_contract.R`)

Call: `acquire district CSV` + `acquire school CSV` (Homeroom, live, temp
files) → `structural screen` → `clean` → `row screen` → `build entities` →
`build roles` → `finalize roles` → `meta`. If either Homeroom download fails
in transport (an Imperva challenge included), the School Performance Reports
contact roster JSON is the fallback.

Result states: `ok` · `ok` from the fallback (narrower coverage, declared in
`meta$coverage`) · `source_unavailable` (both Homeroom and the fallback failed
in transport; empty frames, complete meta) · `error`.

| Failure | Blast radius |
|---|---|
| Homeroom transport failure | falls back to the roster; both fail → `source_unavailable` |
| Homeroom bytes arrive malformed (missing required column, no rows) | whole call → `directory_parse_error` (no fallback: corruption is not hidden behind another source) |
| CSV row with the wrong field count, one of the two verified repair shapes | that row repaired, all 53 fields kept, noted in `meta$coverage$notes` |
| CSV row with the wrong field count, any other shape | **that row only** (**new**: was whole call): withheld, recorded |
| more than five such rows and more than 1% of rows | whole call → `directory_parse_error` (the file itself is wrong) |
| cleaning a validated download fails | whole call → `directory_parse_error` (**new**: was reported as `source_unavailable`) |
| one row: county / district / school code missing or not 2 / 4 / 3 digits | **that row only** (**new**: was whole call `directory_integrity_error`) |
| one school row with no school name | **that row only** (**new**: was whole call `directory_parse_error`) |
| title maps to no role | row kept as `other`, counted in `meta$quality$unmapped_title_count` |
| conflicting duplicate assignment | group quarantined, counted in `meta$quality$quarantined_*` |

Every withheld row is named in one `nj_directory_row_rejected` warning, listed
in `attr(result, "rejected_source_rows")` (level, locator, codes, reason) and
counted in `meta$quality$rejected_source_row_count` (directory-contract v1,
optional field). `get_school_directory()` / `get_district_directory()` warn
the same way for structurally withheld rows.

Invariants: never cached; never fabricates or pads an id; a vacancy is never
published as a person; every withheld row is named and counted; state CDS ids
kept, NCES ids alongside where the source publishes them.

Reachable bad states found: **F2**.

## M6. Revision recheck

None. Every file in the release-asset and bundled manifests is pinned by
sha256 and cannot change under its key. Files a recheck would cover: the live
current-year enrollment zips (2023 onward), current SPR workbooks once a new
year is published, the IDEA-618 2025 consolidated workbook, and the facilities
sources.

---

## 3. Findings (2026-11-09)

Ranked by impact. "Confirmed" means reproduced on this code.

### F1. A crashed download wedged its persistent cache entry. MEDIUM, fixed

*Confirmed by stubbed interleavings.* `download_source()` took its lock with
a bare `dir.create("<path>.acquiring")` and removed it with `on.exit`. A
process killed mid-download (OOM, SIGKILL, CI timeout) never runs `on.exit`,
so the lock stayed and every later call for that URL returned
`source_unavailable` "acquisition is already active": an NJ DOE outage
reported for our own leftover directory, permanently. `njsd_workbook_cache_clear()`
skipped any entry with a lock, so it could not clear it either. A process that
died between the payload rename and the sidecar rename left a payload with no
sidecar, which reads as a legacy entry and refuses with "explicit source
repair is required", again permanently. A second session wanting the same file
while the first was still downloading got `source_unavailable` at once.

Fix: the lock records its owner; a same-host owner confirmed dead (`ps -p`,
no signal) or an owner-less lock older than two hours is reclaimed with a
warning, at acquisition and at clear; a live owner is waited for (bounded by
the request timeout); the sidecar is promoted before the payload. Tests:
`tests/testthat/test-source-cache-lock.R` (6 tests; 5 fail on the old code,
the sixth guards against over-reclaiming).

### F2. One bad directory row failed the whole directory. MEDIUM, fixed

*Confirmed in code and fixture tests.* Any single row with a missing county,
district or school code stopped `fetch_directory()` with
`directory_integrity_error`; a school row with no name stopped it with
`directory_parse_error`; a CSV row with an unexpected field count stopped it
with `directory_parse_error` unless one of the two verified repairs applied. A
failure in our own cleaning step after a good download was reported as a
declared upstream miss (`source_unavailable`). The SPR roster fallback failed
the same way on one row.

Fix: rows are screened one at a time (see M5); the file-level stop stays for
widespread damage. This reverses the fixture test "unknown overflow remains a
structural error", which pinned the whole-call failure. Tests: four new tests
in `tests/testthat/test-directory-source-fidelity.R` (three fail on the old
code; the widespread-damage test guards the file-level stop).

### F3. Partial multi-year frames arrived silently. LOW, fixed

*Confirmed.* `combine_source_captures(allow_partial = TRUE)` dropped failed
years with no warning and no `requested_years` / `missing_years`, so a caller
who did not inspect `get_source_results()` could not tell a short frame from a
full one. In strict mode the error message listed only `year [status]`, so a
defect of ours caught inside a year (for example "object not found") surfaced
as a bare `source_unavailable`. Fix: warning plus attributes; each failure's
own message is kept. Test: `tests/testthat/test-partial-frame.R`.

### Open (not fixed here)

- **O1.** Errors raised inside a multi-year call that are not source errors
  are classified `source_unavailable` (`source_status_from_condition()`), and
  `allow_partial = TRUE` drops parse errors and returns an empty frame when
  every year fails. Existing tests pin all three; changing them is a behaviour
  change for callers.
- **O2.** `get_raw_facilities()` reuses a parsed facilities source for 30 days
  and writes it with a plain `saveRDS()`, so a crash mid-write leaves a
  truncated file that errors on every read until it ages out or is deleted.
  The CDS code workbook it reads is a register NJ DOE updates in place.
- **O3.** `.retain_enr_source()` falls back to a non-atomic `file.copy()` when
  the temp file and the cache root are on different filesystems; a second
  session hashing the half-written copy deletes and replaces it. The final
  digest check catches a mismatch, so no wrong bytes are served, but the call
  can fail spuriously.
- **O4.** `sped_placement_cached_workbook()` reuses any cached file that is a
  valid xlsx, with no sidecar or URL identity, for URLs that are not held as
  release assets.
- **O5.** Live downloads that are not package artifacts persist under the
  per-package cache root (`spr-workbooks/`, `source-artifacts/`,
  `sped-placement/`, `enrollment-sources/`, `facilities/`) rather than a
  per-call temp file.
