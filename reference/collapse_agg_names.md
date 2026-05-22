# Collapse repeated names in aggregation output

When aggregating across schools/districts,
[`toString()`](https://rdrr.io/r/base/toString.html) produces long
strings with duplicated names (e.g., the same school repeated for each
grade). This function deduplicates: if all names are the same, returns
the single name; if names differ, returns each unique name with its
count.

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
# => "School A"

# Multiple schools
collapse_agg_names(c("School A", "School A", "School B"))
# => "School A (2), School B (1)"
} # }
```
