# Fetch Violence/Vandalism/HIB Data

Downloads incident data from SPR database.

## Usage

``` r
fetch_violence_vandalism_hib(
  end_year,
  level = "school",
  with_status = FALSE,
  with_denominator = FALSE
)
```

## Arguments

- end_year:

  A school year (2017-2025)

- level:

  One of "school" or "district"

- with_status:

  Logical, default `FALSE`. If `TRUE`, appends `value_status`,
  classified from the raw incidents-per-100-students rate token before
  numeric coercion.

- with_denominator:

  Logical, default `FALSE`. If `TRUE`, appends `n_students` from the
  matching total-enrollment row in
  [`fetch_enr`](https://almartin82.github.io/njschooldata/reference/fetch_enr.md)
  on `end_year` and CDS identifiers. Unmatched rows remain `NA`.

## Value

Data frame with incident counts

## Examples

``` r
if (FALSE) { # \dontrun{
incidents <- fetch_violence_vandalism_hib(2024)
} # }
```
