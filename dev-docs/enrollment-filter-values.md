# Reference: Valid Filter Values (tidy enrollment)

> **Load this when:** writing `filter()` calls against `fetch_enr(tidy = TRUE)`
> output, authoring vignette/README enrollment stories, or debugging a filter
> that silently returns 0 rows.

These are the valid values for `fetch_enr(tidy = TRUE)`.

## subgroup

`total_enrollment`, `male`, `female`, `white`, `black`, `hispanic`, `asian`,
`native_american`, `pacific_islander`, `multiracial`, `white_m`, `white_f`,
`black_m`, `black_f`, `hispanic_m`, `hispanic_f`, `asian_m`, `asian_f`,
`native_american_m`, `native_american_f`, `pacific_islander_m`,
`pacific_islander_f`, `free_lunch`, `reduced_lunch`, `free_reduced_lunch`,
`lep`, `migrant`

**NOT in tidy enrollment:** `econ_disadv`, `lep_current`, `special_education` —
these live in `fetch_sped()` or report card data, not `fetch_enr()`.

## grade_level

`PK`, `K` (normalized from KF/KH/KG), `01`-`12`, `TOTAL`

Aggregates from `enr_grade_aggs()`: `PK (Any)`, `K (Any)`, `K12`, `K12UG`,
`K8`, `HS`

**Common trap:** Raw data uses `KF` for kindergarten, but `clean_enr_grade()`
normalizes to `K`. Always filter on `K`, never `KF`.

## entity flags

`is_state`, `is_county`, `is_district`, `is_charter`, `is_school`,
`is_subprogram`
