# Fetch Police Notifications

Downloads the `PoliceNotifications` sheet from the NJ DOE School
Performance Reports. Each row reports, for one entity (state / county /
district / school depending on `level`), the count of incidents that
triggered a police notification, broken out by the six SPR offense
categories (violence, weapons, vandalism, substances, HIB, other).

## Usage

``` r
fetch_police_notifications(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2018-2025). Year is the end of the academic year - e.g.
  the 2023-24 school year is `end_year` 2024.

- level:

  One of `"school"` or `"district"`. `"school"` returns school-level
  data; `"district"` returns district and state-level data.

## Value

Data frame with entity identifiers, the six incident-category columns
(`violence`, `weapons`, `vandalism`, `substances`, `hib`,
`other_incidents`), the 2025-only `school_year` column when present, and
the standard aggregation flags (`is_state`, `is_county`, `is_district`,
`is_school`, `is_charter`, `is_charter_sector`, `is_allpublic`).

## Details

Sheet coverage and harmonization:

- The `PoliceNotifications` sheet is present in both the School
  (`Database_SchoolDetail.xlsx`) and District/State
  (`Database_DistrictStateDetail.xlsx`) workbooks for **end_year
  2018-2025**. It is **absent from SY2016-17** (end_year 2017), so this
  function errors for that year.

- The 2024-25 redesign renamed the HIB column from
  `harassment_intimidation_bullying_hib` (legacy) to `hib`; this
  function harmonizes both layouts to `hib`.

- The 2024-25 sheet adds a `school_year` column (single value, e.g.
  `"2024-25"`); it is preserved in the output. Pre-2025 sheets have no
  `school_year` column.

- All six incident-category columns are returned as numeric counts.
  Suppressed cells (NJ DOE uses `*`, `N`, `-` as suppression markers)
  become `NA`.

The companion analysis helper
[`calc_discipline_rates_by_subgroup`](https://almartin82.github.io/njschooldata/reference/calc_discipline_rates_by_subgroup.md)
is designed for sheets with a `subgroup` column and an enrollment
denominator (e.g.
[`fetch_disciplinary_removals`](https://almartin82.github.io/njschooldata/reference/fetch_disciplinary_removals.md)).
The `PoliceNotifications` sheet has neither (it is one row per entity,
with no subgroup breakdown and no denominator), so `calc_*` cannot be
applied directly; pair with
[`fetch_enr`](https://almartin82.github.io/njschooldata/reference/fetch_enr.md)
to compute rates against enrollment.

## Examples

``` r
if (FALSE) { # \dontrun{
# School-level police notifications (latest year)
pn <- fetch_police_notifications(2025)

# District/state-level counts
pn_dist <- fetch_police_notifications(2024, level = "district")

# Districts with the most violence-related police notifications
library(dplyr)
fetch_police_notifications(2024, level = "district") %>%
  filter(is_district) %>%
  slice_max(violence, n = 10) %>%
  select(county_name, district_name, violence, weapons, substances, hib)
} # }
```
