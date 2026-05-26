# Fetch NJ K-12 State Aid by District and Category

One year of NJ DOE K-12 state aid, broken out per district by category
(equalization, educational adequacy, school choice, transportation,
special education, security, adjustment, vocational expansion
stabilization, military impact) plus the year totals. This is the
state-aid (revenue subsidy) counterpart to the spending data in
[`fetch_tges`](https://almartin82.github.io/njschooldata/reference/fetch_tges.md).

## Usage

``` r
fetch_state_aid(end_year)
```

## Arguments

- end_year:

  school year (end of the academic year): the 2025-26 year (state
  FY2026) is `end_year = 2026`.

## Value

A tibble with one row per district per aid category: `county_name`,
`district_code`, `district_name`, `end_year`, `is_state`, `is_district`,
`aid_category`, `is_aid_category`, `amount`, and the raw label
`aid_category_raw`.

## Details

Returned long, one row per district per category. `is_aid_category`
marks the individual aid categories (`TRUE`) versus the year totals and
difference columns (`FALSE`); filter to `is_aid_category` for the clean
categorical breakdown. Category names are normalized across years (e.g.
"Choice Aid" and "School Choice Aid" both become `school_choice_aid`;
"Special Education Categorical Aid" becomes `special_education_aid`).

Data come from the NJ DOE Office of School Finance "District Details"
workbook published with the Governor's Budget Message. These are
**appropriated / proposed** aid figures, not audited expenditures. Note
in particular that `transportation_aid` is a formula subsidy and is
typically far below a district's actual transportation cost.

Valid `end_year` values are 2019 and later. Each year's workbook is
located by trying the current-year direct URL first, then the archived
per-year zip bundle.

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

# All categories for one year
fetch_state_aid(2026) %>%
  filter(is_district, is_aid_category) %>%
  select(district_name, aid_category, amount)

# Transportation aid, biggest recipients
fetch_state_aid(2026) %>%
  filter(is_district, aid_category == "transportation_aid") %>%
  arrange(desc(amount)) %>%
  select(district_name, amount)

# One district's aid mix
fetch_state_aid(2026) %>%
  filter(district_code == "3570", is_aid_category) %>%
  select(aid_category, amount)
} # }
```
