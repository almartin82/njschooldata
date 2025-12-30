# Fetch ACCESS for ELLs data

Downloads and processes ACCESS for ELLs (English Language Learner)
assessment results. ACCESS measures English language proficiency for ELL
students across grades K-12.

## Usage

``` r
fetch_access(end_year, grade = "all")
```

## Arguments

- end_year:

  A school year. Valid values are 2022-2024.

- grade:

  Grade level: "K" or 0 for Kindergarten, 1-12 for other grades, or
  "all" (default) to get all grades combined.

## Value

Processed ACCESS dataframe with columns including:

- testing_year, assess_name, test_name, grade

- county_id, county_name, district_id, district_name

- school_id, school_name, valid_scores

- pct_l1 through pct_l6 (proficiency level percentages)

- proficient_above (L5 + L6 percentage)

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 ACCESS results for all grades
access_2024 <- fetch_access(2024)

# Get 2024 ACCESS results for Grade 3 only
access_g3 <- fetch_access(2024, grade = 3)

# Get Kindergarten ACCESS results
access_k <- fetch_access(2024, grade = "K")
} # }
```
