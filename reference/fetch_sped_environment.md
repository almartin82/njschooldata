# Fetch NJ IDEA Indicator 5C by LEA

Reads NJDOE's published Local Special Education Profiles, indicator
IND_5C: students with IEPs ages 5 in kindergarten through 21 served in
separate schools, residential facilities, or homebound/hospital
placements. This reads the published profile rate, not a sum of rounded
placement percentages. Correctional facilities and parentally placed
private students are not 5C component settings. The profile's published
denominator is retained without substituting classification or
public-IEP enrollment totals.

## Usage

``` r
fetch_sped_environment(end_year)
```

## Arguments

- end_year:

  School year end, 2023 through 2025. 2026 is not published.

## Value

A tibble, one row per LEA, indicator and year, with district_id,
district_name, indicator, value_pct (0-100), value_count, n_students
(the published denominator), source_value, age_group, source_file,
report_year, school_year, entity_level and definition. value_count is
the published numerator. A marker prevents returning either count.

## Details

end_year follows SCHOOL_YEAR, not REPORT_YEAR: report 2026 has school
year 2024-25 and is returned as end_year 2025. The complete NJDOE
Tableau workbook and a reproducible IND_5C projection are bundled and
both are verified on every call. No live fallback occurs. LOCAL is the
displayed percent text; nonnumeric markers such as N remain NA with
source_value unchanged. No unsuppressed hidden rate is substituted.
State rows are included only where present in the source (2025 in this
snapshot), with the state's own 9999 id.

## Examples

``` r
fetch_sped_environment(2025)
#> # A tibble: 652 × 14
#>    end_year district_id district_name indicator value_pct value_count n_students
#>       <int> <chr>       <chr>         <chr>         <dbl>       <dbl>      <dbl>
#>  1     2025 0010        Absecon Publ… 5C             4.94           8        162
#>  2     2025 0020        Alexandria T… 5C             1.23           1         81
#>  3     2025 0030        Allamuchy To… 5C             1.49           1         67
#>  4     2025 0040        Allendale Pu… 5C            11.6           11         95
#>  5     2025 0060        Alloway Twp … 5C             6              3         50
#>  6     2025 0070        Alpha Boroug… 5C             2.78           1         36
#>  7     2025 0080        Alpine Publi… 5C             9.09           2         22
#>  8     2025 0090        Andover Regi… 5C             3.7            3         81
#>  9     2025 0100        Asbury Park … 5C            11.6           34        293
#> 10     2025 0110        Atlantic Cit… 5C             9.64          93        965
#> # ℹ 642 more rows
#> # ℹ 7 more variables: source_value <chr>, age_group <chr>, source_file <chr>,
#> #   report_year <int>, school_year <chr>, entity_level <chr>, definition <chr>
subset(fetch_sped_environment(2024), district_id == "3570")
#> # A tibble: 1 × 14
#>   end_year district_id district_name  indicator value_pct value_count n_students
#>      <int> <chr>       <chr>          <chr>         <dbl>       <dbl>      <dbl>
#> 1     2024 3570        Newark Public… 5C             3.29         192       5836
#> # ℹ 7 more variables: source_value <chr>, age_group <chr>, source_file <chr>,
#> #   report_year <int>, school_year <chr>, entity_level <chr>, definition <chr>
lapply(2023:2025, fetch_sped_environment)
#> [[1]]
#> # A tibble: 652 × 14
#>    end_year district_id district_name indicator value_pct value_count n_students
#>       <int> <chr>       <chr>         <chr>         <dbl>       <dbl>      <dbl>
#>  1     2023 0010        Absecon Publ… 5C             3.01           5        166
#>  2     2023 0020        Alexandria T… 5C             2.25           2         89
#>  3     2023 0030        Allamuchy To… 5C             0              0         74
#>  4     2023 0040        Allendale Pu… 5C             7.78           7         90
#>  5     2023 0060        Alloway Twp … 5C             4.55           2         44
#>  6     2023 0070        Alpha Boroug… 5C             7.14           2         28
#>  7     2023 0080        Alpine Publi… 5C             5.26           1         19
#>  8     2023 0090        Andover Regi… 5C             1.32           1         76
#>  9     2023 0100        Asbury Park … 5C             9.97          29        291
#> 10     2023 0110        Atlantic Cit… 5C             9.95          86        864
#> # ℹ 642 more rows
#> # ℹ 7 more variables: source_value <chr>, age_group <chr>, source_file <chr>,
#> #   report_year <int>, school_year <chr>, entity_level <chr>, definition <chr>
#> 
#> [[2]]
#> # A tibble: 658 × 14
#>    end_year district_id district_name indicator value_pct value_count n_students
#>       <int> <chr>       <chr>         <chr>         <dbl>       <dbl>      <dbl>
#>  1     2024 0010        Absecon Publ… 5C             3.8            6        158
#>  2     2024 0020        Alexandria T… 5C             2.38           2         84
#>  3     2024 0030        Allamuchy To… 5C             0              0         72
#>  4     2024 0040        Allendale Pu… 5C            11.1           11         99
#>  5     2024 0060        Alloway Twp … 5C            11.1            5         45
#>  6     2024 0070        Alpha Boroug… 5C             5.88           1         17
#>  7     2024 0080        Alpine Publi… 5C            24              6         25
#>  8     2024 0090        Andover Regi… 5C             1.35           1         74
#>  9     2024 0100        Asbury Park … 5C            11.8           36        306
#> 10     2024 0110        Atlantic Cit… 5C             9.66          88        911
#> # ℹ 648 more rows
#> # ℹ 7 more variables: source_value <chr>, age_group <chr>, source_file <chr>,
#> #   report_year <int>, school_year <chr>, entity_level <chr>, definition <chr>
#> 
#> [[3]]
#> # A tibble: 652 × 14
#>    end_year district_id district_name indicator value_pct value_count n_students
#>       <int> <chr>       <chr>         <chr>         <dbl>       <dbl>      <dbl>
#>  1     2025 0010        Absecon Publ… 5C             4.94           8        162
#>  2     2025 0020        Alexandria T… 5C             1.23           1         81
#>  3     2025 0030        Allamuchy To… 5C             1.49           1         67
#>  4     2025 0040        Allendale Pu… 5C            11.6           11         95
#>  5     2025 0060        Alloway Twp … 5C             6              3         50
#>  6     2025 0070        Alpha Boroug… 5C             2.78           1         36
#>  7     2025 0080        Alpine Publi… 5C             9.09           2         22
#>  8     2025 0090        Andover Regi… 5C             3.7            3         81
#>  9     2025 0100        Asbury Park … 5C            11.6           34        293
#> 10     2025 0110        Atlantic Cit… 5C             9.64          93        965
#> # ℹ 642 more rows
#> # ℹ 7 more variables: source_value <chr>, age_group <chr>, source_file <chr>,
#> #   report_year <int>, school_year <chr>, entity_level <chr>, definition <chr>
#> 
```
