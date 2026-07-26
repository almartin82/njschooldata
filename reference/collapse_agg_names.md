# Collapse repeated names in aggregation output

When aggregating across schools/districts,
[`toString()`](https://rdrr.io/r/base/toString.html) produces long
strings with duplicated names (e.g., the same school repeated for each
grade). This function returns each unique name once with its input-row
count, including the single-name case.

## Usage

``` r
collapse_agg_names(name_vector)
```

## Arguments

- name_vector:

  Character vector of names to collapse

## Value

Single collapsed string

## Examples

``` r
if (FALSE) { # \dontrun{
# Same school across grades
collapse_agg_names(c("School A", "School A", "School A"))
# => "School A (3)"

# Multiple schools
collapse_agg_names(c("School A", "School A", "School B"))
# => "School A (2), School B (1)"
} # }
```
