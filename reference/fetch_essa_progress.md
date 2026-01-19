# Fetch ESSA Accountability Progress

Downloads ESSA accountability progress indicators from SPR database.
Includes metrics on academic proficiency, growth, graduation rates, and
chronic absenteeism.

## Usage

``` r
fetch_essa_progress(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024)

- level:

  One of "school" or "district"

## Value

Data frame with ESSA progress indicators including:

- School/district identifying information

- elaproficiency - ELA proficiency status

- math_proficiency - Math proficiency status

- ela_growth - ELA growth indicator

- math_growth - Math growth indicator

- x_4_year_graduation_rate - 4-year graduation rate

- x_5_year_graduation_rate - 5-year graduation rate

- progress_toward_english_language_proficiency - ELL progress

- chronic_absenteeism - Chronic absenteeism rate

## Examples

``` r
if (FALSE) { # \dontrun{
progress <- fetch_essa_progress(2024)
} # }
```
