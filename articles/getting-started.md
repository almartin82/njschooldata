# Getting Started with njschooldata

## Introduction

The `njschooldata` package provides a simple interface for accessing New
Jersey Department of Education (NJ DOE) school data in R. The NJ DOE
publishes raw data files covering enrollment, assessments, graduation
rates, and more - but these files use inconsistent formats across years,
making longitudinal analysis challenging.

This package solves that problem by:

- Automatically downloading data from NJ DOE servers
- Parsing various file formats (fixed-width, Excel, CSV)
- Standardizing column names across years
- Providing both wide and tidy data formats

## Installation

Install the package from GitHub:

``` r
# Using remotes (recommended)
remotes::install_github("almartin82/njschooldata")

# Or using devtools
devtools::install_github("almartin82/njschooldata")
```

Load the package:

``` r
library(njschooldata)
library(dplyr)  # for data manipulation examples
```

## Understanding NJ Education Data

### The `end_year` Convention

All functions use `end_year` to specify the school year. This refers to
the **spring semester year**:

| School Year | `end_year` Value |
|-------------|------------------|
| 2023-24     | 2024             |
| 2022-23     | 2023             |
| 2019-20     | 2020             |

### CDS Codes

New Jersey uses a County-District-School (CDS) identifier system:

- **county_id**: 2-digit county code (e.g., “13” = Essex County)
- **district_id**: 4-digit district code
- **school_id**: 3-digit school code (“999” indicates a district-level
  aggregate)

``` r
# A complete CDS code example:
# County 13 (Essex), District 3570 (Newark), School 050 (specific school)
```

### Aggregation Levels

Data is provided at multiple aggregation levels, identified by boolean
flags:

| Level    | `is_state` | `is_district` | `is_school` | Description                         |
|----------|------------|---------------|-------------|-------------------------------------|
| State    | TRUE       | FALSE         | FALSE       | Statewide totals                    |
| District | FALSE      | TRUE          | FALSE       | District totals (school_id = “999”) |
| School   | FALSE      | FALSE         | TRUE        | Individual school data              |

## Quick Start: Enrollment Data

### Fetching Basic Enrollment

``` r
# Get 2024 enrollment data (2023-24 school year)
enr_2024 <- fetch_enr(2024)

# View the structure
glimpse(enr_2024)
#> Rows: 101,650
#> Columns: 26
#> $ end_year         <dbl> 2024, 2024, 2024, 2024, 2024, 2024, 2024, 2024, 2024,…
#> $ CDS_Code         <chr> "010010999", "010010999", "010010999", "010010999", "…
#> $ county_id        <chr> "01", "01", "01", "01", "01", "01", "01", "01", "01",…
#> $ county_name      <chr> "Atlantic", "Atlantic", "Atlantic", "Atlantic", "Atla…
#> $ district_id      <chr> "0010", "0010", "0010", "0010", "0010", "0010", "0010…
#> $ district_name    <chr> "Absecon Public Schools District", "Absecon Public Sc…
#> $ school_id        <chr> "999", "999", "999", "999", "999", "999", "999", "999…
#> $ school_name      <chr> "District Total", "District Total", "District Total",…
#> $ program_code     <chr> "PH", NA, "PF", NA, "KH", NA, "KF", NA, "01", NA, "02…
#> $ program_name     <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ male             <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ female           <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ white            <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ black            <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ hispanic         <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ asian            <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ native_american  <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ pacific_islander <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ multiracial      <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ row_total        <dbl> 0.0, 0.0, 123.0, 13.3, 0.0, 0.0, 77.0, 8.3, 89.0, 9.6…
#> $ free_lunch       <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ reduced_lunch    <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ lep              <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ migrant          <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ homeless         <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ grade_level      <chr> "PK", NA, "PK", NA, "K", NA, "K", NA, "01", NA, "02",…

# Check dimensions
dim(enr_2024)  # Rows and columns
#> [1] 101650     26
```

### Wide vs. Tidy Format

The `tidy` parameter transforms data for easier analysis:

``` r
# Wide format (default) - one row per school, many demographic columns
enr_wide <- fetch_enr(2024, tidy = FALSE)

# Tidy format - one row per school-subgroup combination
enr_tidy <- fetch_enr(2024, tidy = TRUE)
```

The tidy format is better for: - Comparing subgroups within schools -
Longitudinal analysis across years - Filtering to specific demographics

### Filtering to Specific Levels

``` r
# Get only district-level totals
district_totals <- enr_tidy %>%
  filter(is_district, subgroup == "total_enrollment")

# Get only school-level data
school_data <- enr_tidy %>%
  filter(is_school)

# Get state totals
state_totals <- enr_tidy %>%
  filter(is_state)
```

## Assessment Data

### NJSLA / PARCC (2015-present)

Use
[`fetch_parcc()`](https://almartin82.github.io/njschooldata/reference/fetch_parcc.md)
for both NJSLA (2019+) and PARCC (2015-2018) data:

``` r
# Get 2024 Grade 4 Math results
math_g4_2024 <- fetch_parcc(
  end_year = 2024,
  grade_or_subj = 4,
  subj = "math"
)

# Get 2024 Grade 8 ELA results
ela_g8_2024 <- fetch_parcc(
  end_year = 2024,
  grade_or_subj = 8,
  subj = "ela"
)

# Get Algebra 1 results (high school)
alg1_2024 <- fetch_parcc(
  end_year = 2024,
  grade_or_subj = "ALG1",
  subj = "math"
)
```

**Note**: 2020 assessments were cancelled due to COVID-19.

### Available Grade Levels

| Subject      | PARCC (2015-2018) | NJSLA (2019+)   |
|--------------|-------------------|-----------------|
| ELA          | Grades 3-11       | Grades 3-10     |
| Math         | Grades 3-8        | Grades 3-8      |
| Math Courses | ALG1, GEO, ALG2   | ALG1, GEO, ALG2 |

### Legacy Assessments (2004-2014)

For historical data, use
[`fetch_old_nj_assess()`](https://almartin82.github.io/njschooldata/reference/fetch_old_nj_assess.md):

``` r
# Get 2010 Grade 5 NJASK results
njask_2010 <- fetch_old_nj_assess(
  end_year = 2010,
  grade = 5,
  tidy = TRUE
)
```

## Graduation Data

### Graduation Rates

``` r
# Get 4-year graduation rates for 2024
grad_rate_2024 <- fetch_grad_rate(
  end_year = 2024,
  methodology = "4 year"
)

# Get 5-year graduation rates (available 2012-2019)
grad_rate_5yr <- fetch_grad_rate(
  end_year = 2019,
  methodology = "5 year"
)
```

### Graduation Counts

``` r
# Get graduation counts
grad_count_2024 <- fetch_grad_count(end_year = 2024)
```

## School and District Directories

Get metadata about schools and districts:

``` r
# Current school directory with addresses, coordinates, grades served
schools <- get_school_directory()

# Current district directory
districts <- get_district_directory()

# View available columns
names(schools)
#>  [1] "county_id"                   "county_name"                
#>  [3] "district_id"                 "district_name"              
#>  [5] "school_id"                   "school_name"                
#>  [7] "princ_title"                 "princ_first_name"           
#>  [9] "princ_last_name"             "princ_title_2"              
#> [11] "princ_email"                 "address1"                   
#> [13] "address2"                    "city"                       
#> [15] "state"                       "zip"                        
#> [17] "mailing_address1"            "mailing_address2"           
#> [19] "mailing_city"                "mailing_state"              
#> [21] "mailing_zip"                 "hib_title1"                 
#> [23] "hib_first_nname"             "hib_last_name"              
#> [25] "hib_title2"                  "homeless_liaison_title1"    
#> [27] "homeless_liaison_first_name" "homeless_liaison_last_name" 
#> [29] "homeless_liaison_title2"     "phone"                      
#> [31] "pre_k"                       "kindergarten"               
#> [33] "grade_1"                     "grade_2"                    
#> [35] "grade_3"                     "grade_4"                    
#> [37] "grade_5"                     "grade_6"                    
#> [39] "grade_7"                     "grade_8"                    
#> [41] "grade_9"                     "grade_10"                   
#> [43] "grade_11"                    "grade_12"                   
#> [45] "post_grad"                   "adult_ed"                   
#> [47] "nces_code"                   "address"                    
#> [49] "CDS_Code"
```

## Data Coverage Summary

| Data Type         | Function                                                                                              | Years Available |
|-------------------|-------------------------------------------------------------------------------------------------------|-----------------|
| Enrollment        | [`fetch_enr()`](https://almartin82.github.io/njschooldata/reference/fetch_enr.md)                     | 2000-2025       |
| NJSLA/PARCC       | [`fetch_parcc()`](https://almartin82.github.io/njschooldata/reference/fetch_parcc.md)                 | 2015-2024       |
| NJASK             | [`fetch_old_nj_assess()`](https://almartin82.github.io/njschooldata/reference/fetch_old_nj_assess.md) | 2004-2014       |
| Graduation Rates  | [`fetch_grad_rate()`](https://almartin82.github.io/njschooldata/reference/fetch_grad_rate.md)         | 2011-2024       |
| Graduation Counts | [`fetch_grad_count()`](https://almartin82.github.io/njschooldata/reference/fetch_grad_count.md)       | 2012-2024       |

## Common Subgroups

When working with tidy data, you’ll encounter these subgroup codes:

### Race/Ethnicity

- `white`, `black`, `hispanic`, `asian`
- `pacific_islander`, `native_american`, `multiracial`

### Other Demographics

- `male`, `female`
- `free_lunch`, `reduced_lunch`, `free_reduced_lunch`
- `lep` (English learners)
- `migrant`
- `total_enrollment`

**Note:** Special education data is available via
[`fetch_sped()`](https://almartin82.github.io/njschooldata/reference/fetch_sped.md),
not through enrollment subgroups.

## Tips and Best Practices

### 1. Use Session Caching

The package includes built-in session caching to avoid re-downloading:

``` r
# Use session cache (avoids re-downloading within same session)
enr_2024 <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

# Or save to disk for reuse across sessions
saveRDS(enr_2024, "data/enr_2024.rds")
enr_2024 <- readRDS("data/enr_2024.rds")

# Check cache status
njsd_cache_info()
```

### 2. Handle Suppressed Data

Small cell sizes are suppressed with `*` or `NA`:

``` r
# Filter out suppressed values before calculations
reliable_data <- enr_tidy %>%
  filter(!is.na(n_students), n_students >= 10)
```

### 3. Multi-Year Analysis

Use
[`purrr::map_df()`](https://purrr.tidyverse.org/reference/map_dfr.html)
for combining multiple years:

``` r
library(purrr)

# Fetch 5 years of enrollment data
years <- 2020:2024
multi_year_enr <- map_df(years, ~fetch_enr(.x, tidy = TRUE))

# Now you can analyze trends
enrollment_trends <- multi_year_enr %>%
  filter(is_state, subgroup == "total_enrollment") %>%
  select(end_year, n_students)
```

## Next Steps

- See
  [`vignette("nj-enrollment-insights")`](https://almartin82.github.io/njschooldata/articles/nj-enrollment-insights.md)
  for 15 data stories with visualizations
- See
  [`vignette("spr-dictionary")`](https://almartin82.github.io/njschooldata/articles/spr-dictionary.md)
  for School Performance Report data
- Visit the [package
  website](https://almartin82.github.io/njschooldata/) for full
  documentation

## Getting Help

- File issues: <https://github.com/almartin82/njschooldata/issues>
- Email: <almartin@gmail.com>

``` r
sessionInfo()
#> R version 4.5.2 (2025-10-31)
#> Platform: x86_64-pc-linux-gnu
#> Running under: Ubuntu 24.04.3 LTS
#> 
#> Matrix products: default
#> BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 
#> LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0
#> 
#> locale:
#>  [1] LC_CTYPE=C.UTF-8       LC_NUMERIC=C           LC_TIME=C.UTF-8       
#>  [4] LC_COLLATE=C.UTF-8     LC_MONETARY=C.UTF-8    LC_MESSAGES=C.UTF-8   
#>  [7] LC_PAPER=C.UTF-8       LC_NAME=C              LC_ADDRESS=C          
#> [10] LC_TELEPHONE=C         LC_MEASUREMENT=C.UTF-8 LC_IDENTIFICATION=C   
#> 
#> time zone: UTC
#> tzcode source: system (glibc)
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#> [1] purrr_1.2.1        dplyr_1.2.0        njschooldata_0.9.0
#> 
#> loaded via a namespace (and not attached):
#>  [1] sass_0.4.10       generics_0.1.4    tidyr_1.3.2       stringi_1.8.7    
#>  [5] hms_1.1.4         digest_0.6.39     magrittr_2.0.4    evaluate_1.0.5   
#>  [9] timechange_0.4.0  fastmap_1.2.0     cellranger_1.1.0  jsonlite_2.0.0   
#> [13] httr_1.4.8        codetools_0.2-20  textshaping_1.0.4 jquerylib_0.1.4  
#> [17] cli_3.6.5         crayon_1.5.3      rlang_1.1.7       bit64_4.6.0-1    
#> [21] withr_3.0.2       cachem_1.1.0      yaml_2.3.12       parallel_4.5.2   
#> [25] tools_4.5.2       downloader_0.4.1  tzdb_0.5.0        curl_7.0.0       
#> [29] vctrs_0.7.1       R6_2.6.1          lifecycle_1.0.5   lubridate_1.9.5  
#> [33] snakecase_0.11.1  stringr_1.6.0     bit_4.6.0         fs_1.6.6         
#> [37] vroom_1.7.0       ragg_1.5.0        janitor_2.2.1     pkgconfig_2.0.3  
#> [41] desc_1.4.3        pkgdown_2.2.0     pillar_1.11.1     bslib_0.10.0     
#> [45] glue_1.8.0        systemfonts_1.3.1 xfun_0.56         tibble_3.3.1     
#> [49] tidyselect_1.2.1  knitr_1.51        htmltools_0.5.9   rmarkdown_2.30   
#> [53] readr_2.2.0       compiler_4.5.2    readxl_1.4.5
```
