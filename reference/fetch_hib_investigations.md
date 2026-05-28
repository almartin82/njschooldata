# Fetch HIB (Harassment, Intimidation, Bullying) Investigations

Downloads the `HIBInvestigations` sheet from the NJ DOE School
Performance Reports. The sheet is long-format: each row reports, for one
entity (state / county / district / school depending on `level`) and one
HIB-nature category, the number of investigations alleged, confirmed,
and the per-nature total.

## Usage

``` r
fetch_hib_investigations(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2018-2025). Year is the end of the academic year - e.g.
  the 2023-24 school year is `end_year` 2024.

- level:

  One of `"school"` or `"district"`. `"school"` returns school-level
  data; `"district"` returns district and state-level data.

## Value

Data frame with entity identifiers, `hib_nature`, `hib_alleged`,
`hib_confirmed`, `total_hib_investigations`, the 2025-only `school_year`
column when present, and the standard aggregation flags (`is_state`,
`is_county`, `is_district`, `is_school`, `is_charter`,
`is_charter_sector`, `is_allpublic`).

## Details

Sheet coverage and harmonization:

- The `HIBInvestigations` sheet is present in both the School and
  District/State workbooks for **end_year 2018-2025**. It is **absent
  from SY2016-17** (end_year 2017), so this function errors for that
  year.

- Each entity carries eight rows, one per HIB-nature category:
  `Ancestry`, `Disability`, `Gender`, `No Identified Nature`, `Other`,
  `Race`, `Religion`, `Sexual Orientation`.

- The 2024-25 sheet adds a `school_year` column (single value, e.g.
  `"2024-25"`); it is preserved in the output. Pre-2025 sheets have no
  `school_year` column.

- The raw NJ DOE column names `HIBNature`, `HIBAlleged`, `HIBConfirmed`,
  and `TotalHIBInvestigations` snake-case to ambiguous
  `hibnature`/`hiballeged`/`hibconfirmed`/ `total_hibinvestigations`;
  this function renames them to the more readable `hib_nature`,
  `hib_alleged`, `hib_confirmed`, and `total_hib_investigations`.

- Count columns are returned as numeric. Suppressed cells (NJ DOE uses
  `*`, `N`, `-` as suppression markers) become `NA`.

- The SY2019-20 School workbook ships a duplicate sheet named
  `HIBInvestigations1` alongside `HIBInvestigations`; this fetcher
  always reads the canonical `HIBInvestigations` sheet.

The companion analysis helper
[`calc_discipline_rates_by_subgroup`](https://almartin82.github.io/njschooldata/reference/calc_discipline_rates_by_subgroup.md)
is designed for sheets with a `subgroup` column and an enrollment
denominator (e.g.
[`fetch_disciplinary_removals`](https://almartin82.github.io/njschooldata/reference/fetch_disciplinary_removals.md)).
The `HIBInvestigations` sheet is long-by-`hib_nature` and has no
enrollment denominator, so `calc_*` cannot be applied directly; pair
with
[`fetch_enr`](https://almartin82.github.io/njschooldata/reference/fetch_enr.md)
to compute rates against enrollment.

## Examples

``` r
if (FALSE) { # \dontrun{
# School-level HIB investigations (latest year)
hib <- fetch_hib_investigations(2025)

# District/state-level counts
hib_dist <- fetch_hib_investigations(2024, level = "district")

# Statewide HIB nature mix (which categories drive the most investigations?)
library(dplyr)
fetch_hib_investigations(2024, level = "district") %>%
  filter(is_state) %>%
  arrange(desc(total_hib_investigations)) %>%
  select(hib_nature, hib_alleged, hib_confirmed, total_hib_investigations)
} # }
```
