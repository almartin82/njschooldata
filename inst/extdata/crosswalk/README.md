# NJ CDS -> NCES identifier crosswalk

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

**How the join works:** the federal CCD's `state_leaid` is the NJ 6-digit DOE
LEA code, not the CDS `district_id`, so CCD alone cannot be CDS-keyed. The NJ DOE
directory carries BOTH the CDS code and the full 7-digit LEAID, providing the
bridge. Schools join to CCD on the composite key (district LEAID + 3-digit
school code) to get the 12-digit NCESSCH; NJ school codes are reused across
districts, so the bare school code is never used alone. Every district LEAID is
cross-validated against the CCD 2024 NJ universe; the build aborts on an
implausibly large disagreement.

**Coverage:** ~95%+ of bundled-enrollment districts and ~97%+ of schools match.
Entities absent from the directory/CCD snapshot (new/closed/charter additions)
keep `NA`, never a guessed id.

**Rebuild:** `Rscript data-raw/build_nces_crosswalk.R`. Never hand-edit.

