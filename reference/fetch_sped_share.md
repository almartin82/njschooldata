# Fetch the share of students with IEPs, district rows by grade band or school rows

Rows of the share of students with an IEP, at the finest grain New
Jersey publishes, in the shape
[`sped_all_vs_all`](https://almartin82.github.io/njschooldata/reference/sped_all_vs_all.md)
and
[`sped_like_for_like`](https://almartin82.github.io/njschooldata/reference/sped_like_for_like.md)
read. Every value is from a NJDOE file.

## Usage

``` r
fetch_sped_share(end_year, basis = c("lea_idea", "school_report"))
```

## Arguments

- end_year:

  ending school year. `"lea_idea"`: 2023-2026. `"school_report"`:
  2021-2025.

- basis:

  `"lea_idea"` (default) or `"school_report"`.

## Value

A data frame with end_year, entity_level (state, district or school),
district_id, school_id, district_name, school_name, grade_band (all,
elementary, middle, high), grade_low, grade_high, n_sped, n_enrolled,
pct_sped, pct_sped_lo, pct_sped_hi, is_charter, construct, count_date
and source_file. Suppressed values are NA, never zero.

## Details

Two bases, because the state publishes two different counts at different
grains, and one year's return uses one:

- `"lea_idea"` (default, 2023-2026):

  District (LEA) rows. For 2023-2025, an `all` row per district and the
  state from the IDEA classification files (count, enrollment, rate).
  For every year, rows for `elementary` (K-5), `middle` (6-8) and `high`
  (9-12) from NJDOE's response to OPRA request C255254 (see
  [`fetch_sped_by_grade`](https://almartin82.github.io/njschooldata/reference/fetch_sped_by_grade.md)),
  over the same year's Fall Enrollment by grade. Pre-K is left out of
  every band. A band with a suppressed grade cell (a count under 5) has
  `n_sped = NA` and `pct_sped_lo/hi` from the published bound of 1 to 4
  for each suppressed cell. A cell NJDOE left blank is zero students:
  wherever nothing is suppressed, the OPRA grade cells sum to the IDEA
  child count for every district in 2023-2025. The band rows carry no
  `pct_sped`: NJDOE publishes counts by grade, and the helpers pool the
  counts. **2025-26 is flagged**: known OPRA counts fall 8 percent from
  2024-25, there is no IDEA file yet, and the call warns.

- `"school_report"` (2021-2025, live):

  School rows, plus district and state rows, from the School Performance
  Reports: Students with Disabilities as a percent of enrollment, one
  decimal, with no suppression. `n_enrolled` is the same report's total
  enrollment, and `grade_low`/`grade_high` are the lowest and highest
  grades with students in that report. This is a different construct
  from the IDEA child count (in 2024-25 the statewide figure is 18.1
  percent against 17.35 percent for IDEA, and some schools differ by
  more); NJDOE does not explain the gap. Downloads the School
  Performance Reports workbooks, which are large.

`is_charter` is TRUE for the state's charter sector (county code 80) and
for the three Camden renaissance operators in county 07 (1799, 1801,
1802) listed by the NJDOE Renaissance School Project, and FALSE
otherwise.

## See also

[`fetch_sped`](https://almartin82.github.io/njschooldata/reference/fetch_sped.md),
[`fetch_sped_by_grade`](https://almartin82.github.io/njschooldata/reference/fetch_sped_by_grade.md)

## Examples

``` r
# 1. District rows by grade band, with the IDEA all-grades row
share <- fetch_sped_share(2025)
#> Unknown column name: Column1
#> Unknown column name: Column2
head(share)
#>   end_year entity_level district_id school_id
#> 1     2025        state        <NA>      <NA>
#> 2     2025     district        0010      <NA>
#> 3     2025     district        0010      <NA>
#> 4     2025     district        0010      <NA>
#> 5     2025     district        0020      <NA>
#> 6     2025     district        0020      <NA>
#>                         district_name school_name grade_band grade_low
#> 1                     Statewide Total        <NA>        all      <NA>
#> 2     Absecon Public Schools District        <NA>        all      <NA>
#> 3     Absecon Public Schools District        <NA> elementary      <NA>
#> 4     Absecon Public Schools District        <NA>     middle      <NA>
#> 5 Alexandria Township School District        <NA>        all      <NA>
#> 6 Alexandria Township School District        <NA> elementary      <NA>
#>   grade_high n_sped n_enrolled pct_sped pct_sped_lo pct_sped_hi is_charter
#> 1       <NA> 242001    1394970 17.34812          NA          NA         NA
#> 2       <NA>    165        915 18.03000          NA          NA      FALSE
#> 3       <NA>     93        474       NA          NA          NA      FALSE
#> 4       <NA>     54        304       NA          NA          NA      FALSE
#> 5       <NA>     88        422 20.85000          NA          NA      FALSE
#> 6       <NA>     NA        256       NA    19.53125    20.70312      FALSE
#>                                      construct count_date
#> 1 students with an IEP, October 15 child count October 15
#> 2 students with an IEP, October 15 child count October 15
#> 3 students with an IEP, October 15 child count October 15
#> 4 students with an IEP, October 15 child count October 15
#> 5 students with an IEP, October 15 child count October 15
#> 6 students with an IEP, October 15 child count October 15
#>                                                                                                                           source_file
#> 1 https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/2025_618data/2025IDEA618PublicReporting_ClassificationRates.xlsx
#> 2 https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/2025_618data/2025IDEA618PublicReporting_ClassificationRates.xlsx
#> 3                                                     opra://njdoe/C255254/Districtlevel_C255254_Suppressed.xlsx; enrollment-2025.zip
#> 4                                                     opra://njdoe/C255254/Districtlevel_C255254_Suppressed.xlsx; enrollment-2025.zip
#> 5 https://www.nj.gov/education/specialed/monitor/ideapublicdata/docs/2025_618data/2025IDEA618PublicReporting_ClassificationRates.xlsx
#> 6                                                     opra://njdoe/C255254/Districtlevel_C255254_Suppressed.xlsx; enrollment-2025.zip

# 2. Band counts for the district-run and charter sectors
library(dplyr)
share %>%
  filter(entity_level == "district", grade_band != "all") %>%
  group_by(is_charter, grade_band) %>%
  summarise(n_sped = sum(n_sped, na.rm = TRUE), n_enrolled = sum(n_enrolled, na.rm = TRUE))
#> `summarise()` has regrouped the output.
#> ℹ Summaries were computed grouped by is_charter and grade_band.
#> ℹ Output is grouped by is_charter.
#> ℹ Use `summarise(.groups = "drop_last")` to silence this message.
#> ℹ Use `summarise(.by = c(is_charter, grade_band))` for per-operation grouping
#>   (`?dplyr::dplyr_by`) instead.
#> # A tibble: 6 × 4
#> # Groups:   is_charter [2]
#>   is_charter grade_band n_sped n_enrolled
#>   <lgl>      <chr>       <dbl>      <dbl>
#> 1 FALSE      elementary  89068    533221 
#> 2 FALSE      high        70872    404992 
#> 3 FALSE      middle      51142    280688 
#> 4 TRUE       elementary   1747     36371 
#> 5 TRUE       high         1668     14256.
#> 6 TRUE       middle       2068     19254 

# 3. School rows from the School Performance Reports (large download)
if (FALSE) { # \dontrun{
fetch_sped_share(2024, basis = "school_report") %>%
  filter(entity_level == "school", is_charter)
} # }
```
