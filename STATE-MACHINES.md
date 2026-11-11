# njschooldata: data flow and state machines

What states the data passes through on its way from an NJ DOE file to a frame
a caller gets back, what must hold in each state, which transitions exist, and
which bad states the code can actually reach. Updated 2026-11-10 from the code
on `master`. Update it in the same commit as any change to a transition below.

Companion docs: `CLAUDE.md` (family rules and traps), `R/cache.R` (why there
is no schema version to bump), `R/release_sources.R` (held release assets),
`dev-docs/source-outage-runbook.md`.

---

## 1. The pipeline at a glance

```
NJ state publication / register
   │
   ├─ bundled in inst/extdata (new_jersey_shipped_sources manifest) ─┐
   │                                                                 │
   ├─ held as a release asset (new_jersey_release_sources: 160 files │
   │   by URL, byte length, sha256)                                  │
   │      ▼ M2: shared historical source store (vendored resolver)   │
   │   verified blob ──copy──▶ per-call temp file ◀──────────────────┘
   │
   └─ any URL neither manifest names (current-year files and live registers)
          ▼ A / M7: download_source() transport into a per-call temp file
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
falls through to nj.gov once matched); (3) a live request into a per-call temporary file. Steps 1 and 2 are
skipped only when a test injects its own `request_fn`, or when
`options(njschooldata.release_sources = FALSE)` opts out of step 2.

## 2. What triggers a regeneration

| Change | What makes the old value unreachable | Automatic? |
|---|---|---|
| Parser / processor / tidier change | Nothing on disk holds parsed output; the session cache dies with the R session | Yes, at the next session. A running session keeps old parsed entries until `njsd_cache_clear()` |
| NJ DOE republishes a held file | Nothing: the release asset is pinned by sha256 | No. A new release asset has to be cut |
| NJ DOE republishes a live-fetched file in place | The next acquisition reads it again; registers are live on every call | Yes, on the next call without a session-cached frame |
| Download URL changes | Held URLs keep their pinned identities; an unheld URL uses a fresh temp file | Yes on acquisition; a held-source change requires a new manifest identity |
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

## A / M7. Validated per-call transport (`R/source_transport.R`)

`download_source(url, source_type, ...)` returns an `njsd_source_result`.
Bundled publications resolve first, then verified release assets; only unheld
URLs reach the publisher. Each path returns a private temporary copy that the
caller releases. Live acquisitions validate the redirect host, content type,
file signature and archive members, and compute SHA-256 before parsing.
Transport failures and invalid source bytes are `source_unavailable`; a parser
failure on good bytes remains `parse_error`. Programmer errors propagate.

SPR, graduation, TGES and state aid use package-held release bytes for their
manifest URLs. Five-year ACGR 2012-2019 and standalone SPR 2012-2016 were added
in `sources-2026-11-10` (30 new artifacts, 39,692,151 bytes including facilities).
All 30 were downloaded anonymously after publication and checked by length and
SHA-256. Acquisition timestamps record the downloaded files' completion clocks.

There is no persistent live payload, sidecar, acquisition lock or adoption
path. The five former folders (`spr-workbooks`, `source-artifacts`,
`enrollment-sources`, `sped-placement`, `facilities`) are no longer written.
`njsd_workbook_cache_dir/info/clear` remain compatibility helpers for inspecting
and removing legacy files; clear leaves `historical-assets-v1` untouched.

### Facilities: live registers and dated captures

CDS and NJGIN school points are live on every call, regardless of `use_cache`.
SDA allocation (FY26 in the workbook title), lead SOA (2024-2025, filename dated
2025-10-28), and the NJSDA capital index plus all 14 linked project pages are
held captures from 2026-11-10. Each has a URL, length and SHA-256 in the release
manifest. HTML was screened for injected challenge scripts and IP addresses;
none were found and no publisher bytes were modified. Snapshot frames are
reparsed from those verified bytes, without a persistent processed cache.

**To converge:** allocation and lead rows still join the live CDS district
register. Their values come from held workbooks, but joined identifiers and
names may change with CDS. Reproducing those joined outputs therefore also
requires the same live register. Question NJ-E8b in the fleet `DECISIONS.md`
records the choice; the join remains unchanged pending that ruling.

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
| valid (enrollment) | its session-local source zip missing or digest differs | refetched |
| valid | `njsd_cache_clear()` / `njsd_cache_remove()` / session ends | absent |

Enrollment retains its source zip under `tempdir()/njschooldata-enrollment-sources/` so
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

Historical repair below; E8b subsequently removed this entire persistent path.
The replacement lifecycle tests cover per-call cleanup and fresh acquisition.

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

- **O1 closed in 0.10.0:** multi-year parser errors and unclassified errors
  propagate, and all-source-failed requests stop. Declared all-gap requests
  still return an annotated empty frame.
- **O2, O4, O5 closed in E8b:** facilities caches, placement caches and
  persistent live download folders are removed. Facilities registers remain
  live; dated captures are held. The CDS-join caveat above remains to converge.
- **O3 closed in E8b:** enrollment source copies live under `tempdir()`, with
  the same path resolver used by cache validation and contract attachment.
  Independent R sessions no longer share that mutable copy.
- **Pre-existing graduation warning, to converge:** the 0.10.0 live baseline
  and the held-byte comparison each emit eight `Unknown columns:
  five_yr_grad_rate` warnings for the eight requested five-year years. E8b
  leaves that parser/selector behaviour unchanged; no warning was suppressed.
- **Pre-existing test inventory failure, to converge:** the original HEAD test
  contents and the E8b suite each flag `test-historical-store-recovery.R` in
  `test-test-inventory.R`. The canonical recovery tests themselves pass. E8b
  preserves the inventory assertion and adds no allowlist exception.
