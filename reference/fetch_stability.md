# Fetch NJ high school cohort persistence

Reads state-published high school persistence from bundled text extracts
of the 2023-24 and 2024-25 School Performance Reports school databases.
NJDOE defines it as the percentage of students in a graduation cohort
who either graduated with a state-endorsed diploma or remained enrolled
six years after entering high school. This is a cohort-persistence
proxy, not annual same-school stability, mobility or fall-to-fall
attrition. The definition is repeated in every row.

## Usage

``` r
fetch_stability(end_year)
```

## Arguments

- end_year:

  Report school year end, 2024 or 2025.

## Value

A tibble with end_year, entity_level, district_id, school_id,
district_name, school_name, measure, student_group, value (percent),
source_value, value_lo, value_hi, numerator, denominator, period,
count_date, definition and source_file. Counts are unpublished and NA.

## Details

The 2024-25 accountability release uses Cohort 2022 six-year data from
2023-24. It is distinct from the current-cohort persistence in the
GraduationCohortProfile sheet. Groups with fewer than 10 students are
unavailable; accountability calculations require at least 20 students.
Published markers are retained in source_value. Specialized receiving
schools are attributed to sending schools for accountability, per the
SPR Reference Guide. No count or annual retention rate is inferred. The
2023-24 six-year profile names its measure HighSchoolPersistance; the
2024-25 profile names it Persisting. Those current-cohort rows are kept
separately from HS Persistence accountability rows by measure and
period.

## Examples

``` r
x <- fetch_stability(2025)
subset(x, student_group == "Students with Disabilities")
#> # A tibble: 435 × 18
#>    end_year entity_level district_id school_id district_name school_name measure
#>       <int> <chr>        <chr>       <chr>     <chr>         <chr>       <chr>  
#>  1     2025 school       0110        010       Atlantic Cit… Atlantic C… HS Per…
#>  2     2025 school       0120        010       Atlantic Cou… Atlantic C… HS Per…
#>  3     2025 school       0590        025       Buena Region… Buena Regi… HS Per…
#>  4     2025 school       1310        005       Egg Harbor T… Egg Harbor… HS Per…
#>  5     2025 school       1790        040       Greater Egg … Absegami H… HS Per…
#>  6     2025 school       1790        050       Greater Egg … Oakcrest H… HS Per…
#>  7     2025 school       1790        060       Greater Egg … Cedar Cree… HS Per…
#>  8     2025 school       1960        050       Hammonton Sc… Hammonton … HS Per…
#>  9     2025 school       2910        050       Mainland Reg… Mainland R… HS Per…
#> 10     2025 school       4180        050       Pleasantvill… Pleasantvi… HS Per…
#> # ℹ 425 more rows
#> # ℹ 11 more variables: student_group <chr>, value <dbl>, source_value <chr>,
#> #   value_lo <dbl>, value_hi <dbl>, numerator <dbl>, denominator <dbl>,
#> #   count_date <chr>, period <chr>, definition <chr>, source_file <chr>
subset(x, district_id == "3570", select = c(school_name, student_group, value))
#> # A tibble: 68 × 3
#>    school_name                   student_group              value
#>    <chr>                         <chr>                      <dbl>
#>  1 Arts High School              All Students                96.1
#>  2 Arts High School              Students with disabilities 100  
#>  3 Barringer High School         All Students                82.3
#>  4 Barringer High School         Students with disabilities  83.3
#>  5 Central High School           All Students                92.5
#>  6 Central High School           Students with disabilities  87.5
#>  7 East Side High School         All Students                96.2
#>  8 East Side High School         Students with disabilities  96.2
#>  9 Newark Vocational High School All Students                93.8
#> 10 Newark Vocational High School Students with disabilities  88.2
#> # ℹ 58 more rows
```
