# NJ CDS -> NCES identifier crosswalk

## Exact CCD state LEA keys for SpEd and EL

`nj_ccd_state_leaid_2024.csv` contains all 700 distinct NJ CCD 2024
`state_leaid` / `leaid` pairs, with `leaid` named `nces_dist`. Source:
https://educationdata.urban.org/api/v1/school-districts/ccd/directory/2024/?fips=34
(CCD republication). It contains identifiers only, no population values.
Rebuild with `python3 data-raw/build_program_sources.py`.

SpEd and EL use an exact match on `NJ-` + the two-character **published county
code** + the four-character **published district code**. County codes are the
NJDOE codes (01, 03, ..., 41, plus special sectors), not county name ordinals.
District codes repeat across counties. There is no name match, fuzzy match,
directory fallback, or use of district code alone. Unmatched keys remain NA.
The original columns always retain their state identifiers.

## Existing CDS school bridge

**Vintage:** CCD 2024 (school NCESSCH) + the current NJ DOE Homeroom directory
(CDS -> LEAID bridge).

**Source:**
- NJ DOE Homeroom district/school directory — publishes the federal `NCES ID`
  keyed by the state's County-District-School (CDS) code.
- CCD 2024 directory (districts + schools) via the Urban Institute Education Data
  API, a republication of the federal NCES Common Core of Data, `fips=34`.

**Contents:** identifiers ONLY — no enrollment/performance values. Maps the NJ
CDS code (the package's `county_id` + `district_id` + `school_id`) to the
7-digit NCES `LEAID` (`nces_dist`) and 12-digit `NCESSCH` (`nces_sch`).

**How this older bridge works:** the NJ DOE directory supplies the CDS code
and full 7-digit LEAID. CCD also supports the direct county-plus-district join
documented above: its six-digit `state_leaid` suffix includes both codes,
rather than the four-digit `district_id` alone.
Schools join to CCD on the composite key (district LEAID + 3-digit
school code) to get the 12-digit NCESSCH; NJ school codes are reused across
districts, so the bare school code is never used alone. Every district LEAID is
cross-validated against the CCD 2024 NJ universe; the build aborts on an
implausibly large disagreement.

**Coverage:** ~95%+ of bundled-enrollment districts and ~97%+ of schools match.
Entities absent from the directory/CCD snapshot (new/closed/charter additions)
keep `NA`, never a guessed id.

**Rebuild:** `Rscript data-raw/build_nces_crosswalk.R`. Never hand-edit.

