# Fetch ESSA Accountability Status

Downloads ESSA accountability status/ratings (CSI/ATSI/TSI
identification) from the SPR database. Each row carries the entity's
status for the school year (`status_for_sy`), the
`category_of_identification` that drove it, the year eligible to exit,
and (for targeted statuses) the affected student group.

## Usage

``` r
fetch_essa_status(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2025)

- level:

  One of "school" or "district"

## Value

Data frame with ESSA status ratings

## Details

The 2024-25 (end_year 2025) SPR redesign reorganized the accountability
sheets per database file:

- **School DB**: keeps the `ESSAAccountabilityStatus` sheet (one row per
  identified school).

- **District/State DB**: the `ESSAAccountabilityStatus` sheet was
  removed and replaced by two new sheets: `ESSAAccountabilityStatusList`
  (one row per identified school, with the same 12-column layout as the
  School DB sheet) and `ESSAAccountabilityStatusCounts` (per-district
  CSI/ATSI/TSI tallies). The *List* sheet is the structural analogue of
  the legacy `ESSAAccountabilityStatus` sheet – it carries the
  per-entity status and `category_of_identification` that downstream
  functions such as
  [`identify_focus_schools`](https://almartin82.github.io/njschooldata/reference/identify_focus_schools.md)
  require – so this function maps district-level 2025+ requests to
  `ESSAAccountabilityStatusList`. The *Counts* sheet holds only
  aggregate tallies and is not used here.

## Examples

``` r
if (FALSE) { # \dontrun{
# School-level status (all years use the ESSAAccountabilityStatus sheet)
essa <- fetch_essa_status(2024)

# District/State-level status for the redesigned 2024-25 database
essa_dist <- fetch_essa_status(2025, level = "district")

# Identify schools needing comprehensive support
library(dplyr)
fetch_essa_status(2025) %>%
  filter(grepl("Comprehensive", status_for_sy))
} # }
```
