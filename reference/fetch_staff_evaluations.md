# Fetch Summative Educator Evaluation Rating Distributions

Downloads the NJ DOE standalone summative educator-evaluation workbook
and returns, for each entity and staff category (teachers vs
principals/APs/VPs), how many educators landed in each of the four
rating tiers (ineffective, partially effective, effective, highly
effective) plus the total evaluated. Rating distributions are a
rarely-analyzed window into evaluation-system rigor (e.g. how
concentrated ratings are at the top of the scale).

## Usage

``` r
fetch_staff_evaluations(end_year, level = "school")
```

## Arguments

- end_year:

  A school year: 2014, 2015, or 2016.

- level:

  `"school"` (default) returns the per-school rows; `"district"` returns
  the district-total rows (`school_id == "999"`, plus the statewide
  aggregate where published).

## Value

Data frame with `end_year`, the entity identifiers, the raw `category`
and normalized `staff_category`, the five numeric rating columns
(`ineffective`, `partially_effective`, `effective`, `highly_effective`,
`total`), and the entity flags (`is_state`, `is_county`, `is_district`,
`is_school`, `is_charter`).

## Details

**Source.** Standalone Excel workbooks under
`nj.gov/education/doedata/staff/` – distinct from the SPR-sourced staff
fetchers. **Only three years exist:** `end_year` 2014 (SY2013-14), 2015
(SY2014-15), and 2016 (SY2015-16); any other year errors.

**Sheets differ by year.** The 2014 workbook ships one combined sheet
(school rows plus district-total rows, `school_id == "999"`); the 2015
and 2016 workbooks split district totals and school totals into two
sheets that are read and stacked.

**Staff category.** The raw `CATEGORY` (`"TEACHERS"` / `"PRIN/AP/VP"`)
is normalized to `staff_category` (`"teachers"` / `"principals_vps"`)
and the raw label is kept as `category`.

**Suppression -\> NA (never a guessed number).** Small cells are masked
with `"*"`; every rating column maps `"*"` to `NA`. A real published `0`
stays `0`. A trailing data-certification note row in each workbook is
dropped.

**Entity flags.** `is_school` (per-school rows) vs `is_district`
(district totals, `school_id == "999"`). A statewide aggregate row
(county `"99"` / district `"9999"`) is present in 2014 and 2015 and is
flagged `is_state`; it is returned at `level = "district"`. The 2016
workbook publishes no statewide row.

## Examples

``` r
if (FALSE) { # \dontrun{
# School-level teacher rating distribution, 2015-16
fetch_staff_evaluations(2016)

# District-total rows, including the statewide aggregate (2014)
library(dplyr)
fetch_staff_evaluations(2014, level = "district") %>%
  filter(is_state, staff_category == "teachers")

# Share of teachers rated highly effective, by district (2015)
fetch_staff_evaluations(2015, level = "district") %>%
  filter(staff_category == "teachers", !is_state) %>%
  mutate(pct_highly = 100 * highly_effective / total) %>%
  select(district_name, highly_effective, total, pct_highly)
} # }
```
