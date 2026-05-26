# Normalize a raw NJ state-aid column label to a standard category name

The published column labels drift across years ("Choice Aid" vs "School
Choice Aid"; "Special Education Categorical Aid" vs "Special Education
Aid"). This maps the recognized aid categories to a single cross-year
name and passes everything else (year totals, differences) through a
snake-case clean, so total/difference columns keep their year token and
never collide.

## Usage

``` r
normalize_state_aid_category(raw)
```

## Arguments

- raw:

  character vector of raw column labels

## Value

character vector of normalized names
