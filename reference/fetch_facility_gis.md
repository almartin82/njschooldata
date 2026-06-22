# Fetch New Jersey school facility geometry

Spatial companion to \[fetch_facilities()\]. Returns NJGIN school points
as an \`sf\` object when \`sf\` is installed and \`sf = TRUE\`;
otherwise returns a data frame with latitude, longitude, and WKT.

## Usage

``` r
fetch_facility_gis(layer = "school_points", sf = TRUE, use_cache = TRUE)
```

## Arguments

- layer:

  GIS layer. Currently \`"school_points"\`.

- sf:

  If TRUE, return an \`sf\` object when the \`sf\` package is installed.
  If FALSE, always return a data frame.

- use_cache:

  If TRUE (default), use cached source downloads when fresh.

## Value

An \`sf\` object or data frame with \`latitude\`, \`longitude\`, and
\`wkt\`.

## Examples

``` r
if (FALSE) { # \dontrun{
points <- fetch_facility_gis("school_points")
points_df <- fetch_facility_gis("school_points", sf = FALSE)
} # }
```
