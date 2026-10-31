# Fetch students with an active IEP by district and grade

Counts of students with an active IEP for every public school district
and charter school, by grade, from NJDOE's response to OPRA request
C255254. The workbook is bundled in the package and verified by SHA-256
on every read.

## Usage

``` r
fetch_sped_by_grade(end_year)
```

## Arguments

- end_year:

  ending school year, 2022 through 2026 (2023-24 is 2024).

## Value

a tibble with end_year, county_id, county_name, district_id,
district_name, grade_level (PK, K, 01-12, NO_GRADE), n_students and
suppressed, plus the standard entity flags.

## Details

NJDOE suppressed counts under 5. A suppressed cell returns
`n_students = NA` with `suppressed = TRUE`, never zero. A grade NJDOE
left blank for a district has no row. The file has no statewide row and
no denominators, and this function adds neither.

**2025-26 looks incomplete.** Statewide known counts fall 8% from
2024-25, grades 9-12 fall about 15%, and some large districts have no
known counts. NJDOE has not explained this, so `end_year = 2026` warns.
The values are returned as released.

## See also

[`fetch_sped`](https://almartin82.github.io/njschooldata/reference/fetch_sped.md)
for published classification rates.

## Examples

``` r
# 1. Every district and grade for one year
fetch_sped_by_grade(2025)
#> # A tibble: 6,718 × 15
#>    end_year county_id county_name district_id district_name          grade_level
#>       <int> <chr>     <chr>       <chr>       <chr>                  <chr>      
#>  1     2025 01        Atlantic    0010        Absecon Public School… PK         
#>  2     2025 01        Atlantic    0010        Absecon Public School… K          
#>  3     2025 01        Atlantic    0010        Absecon Public School… 01         
#>  4     2025 01        Atlantic    0010        Absecon Public School… 02         
#>  5     2025 01        Atlantic    0010        Absecon Public School… 03         
#>  6     2025 01        Atlantic    0010        Absecon Public School… 04         
#>  7     2025 01        Atlantic    0010        Absecon Public School… 05         
#>  8     2025 01        Atlantic    0010        Absecon Public School… 06         
#>  9     2025 01        Atlantic    0010        Absecon Public School… 07         
#> 10     2025 01        Atlantic    0010        Absecon Public School… 08         
#> # ℹ 6,708 more rows
#> # ℹ 9 more variables: n_students <dbl>, suppressed <lgl>, is_state <lgl>,
#> #   is_county <lgl>, is_district <lgl>, is_school <lgl>, is_charter <lgl>,
#> #   is_charter_sector <lgl>, is_allpublic <lgl>

# 2. One district, by grade
library(dplyr)
#> 
#> Attaching package: ‘dplyr’
#> The following objects are masked from ‘package:stats’:
#> 
#>     filter, lag
#> The following objects are masked from ‘package:base’:
#> 
#>     intersect, setdiff, setequal, union
fetch_sped_by_grade(2025) %>%
  filter(district_name == "Newark Public School District") %>%
  select(grade_level, n_students, suppressed)
#> # A tibble: 15 × 3
#>    grade_level n_students suppressed
#>    <chr>            <dbl> <lgl>     
#>  1 PK                 800 FALSE     
#>  2 K                  369 FALSE     
#>  3 01                 410 FALSE     
#>  4 02                 416 FALSE     
#>  5 03                 434 FALSE     
#>  6 04                 447 FALSE     
#>  7 05                 469 FALSE     
#>  8 06                 499 FALSE     
#>  9 07                 508 FALSE     
#> 10 08                 513 FALSE     
#> 11 09                 439 FALSE     
#> 12 10                 476 FALSE     
#> 13 11                 461 FALSE     
#> 14 12                 551 FALSE     
#> 15 NO_GRADE             3 FALSE     

# 3. Charter schools only, across years
lapply(2022:2025, fetch_sped_by_grade) %>%
  bind_rows() %>%
  filter(is_charter, grade_level == "K")
#> # A tibble: 169 × 15
#>    end_year county_id county_name district_id district_name          grade_level
#>       <int> <chr>     <chr>       <chr>       <chr>                  <chr>      
#>  1     2022 80        Charters    6017        Foundation Academy Ch… K          
#>  2     2022 80        Charters    6018        Central Jersey Colleg… K          
#>  3     2022 80        Charters    6026        Riverbank Charter Sch… K          
#>  4     2022 80        Charters    6029        Newark Educators Comm… K          
#>  5     2022 80        Charters    6041        Hatikvah Internationa… K          
#>  6     2022 80        Charters    6053        Great Oaks Legacy Cha… K          
#>  7     2022 80        Charters    6058        Roseville Community C… K          
#>  8     2022 80        Charters    6060        Atlantic Community Ch… K          
#>  9     2022 80        Charters    6079        John P Holland Charte… K          
#> 10     2022 80        Charters    6081        Thomas Edison Energys… K          
#> # ℹ 159 more rows
#> # ℹ 9 more variables: n_students <dbl>, suppressed <lgl>, is_state <lgl>,
#> #   is_county <lgl>, is_district <lgl>, is_school <lgl>, is_charter <lgl>,
#> #   is_charter_sector <lgl>, is_allpublic <lgl>
```
