# Fetch New Jersey school facilities data

New Jersey facilities data is fragmented across state sources rather
than a single bulk API. This function dispatches by \`category\` and
returns a canonical long table with character-valued \`value\`, source
provenance, and true source vintages on every row.

## Usage

``` r
fetch_facilities(category, year = NULL, tidy = TRUE, use_cache = TRUE)
```

## Arguments

- category:

  Facilities category. Run \[get_available_facilities()\] for shipped
  New Jersey categories.

- year:

  Optional source-vintage filter. If no shipped vintage contains the
  requested year, the available rows are returned with a message.

- tidy:

  If TRUE (default), return the canonical long schema. Facilities has no
  separate wide form, so FALSE currently returns the same rows.

- use_cache:

  If TRUE (default), use cached source downloads when fresh.

## Value

Data frame with columns \`category\`, \`entity_level\`, \`entity_id\`,
\`entity_name\`, \`metric\`, \`value\`, \`unit\`, \`source_agency\`,
\`source_type\`, \`source_url\`, \`vintage\`, \`nces_dist\`, and
\`nces_sch\`.

## Details

New Jersey currently ships honest partial coverage: \`inventory\`,
\`attributes\`, \`capacity\`, \`projects\`, \`finance\`,
\`environmental\`, and \`closures\`. The full controlled vocabulary also
contains \`condition\` and \`capital_needs\`, but no verified populated
public statewide bulk source is shipped for those categories yet, so
they error with a coverage message rather than returning placeholders.

Geometry is served by \[fetch_facility_gis()\]. Inventory rows still
include latitude/longitude metrics from NJGIN where available.

## Examples

``` r
if (FALSE) { # \dontrun{
inv <- fetch_facilities("inventory")
grants <- fetch_facilities("finance")
lead <- fetch_facilities("environmental")

library(dplyr)
grants |>
  mutate(allocation = as.numeric(value))
} # }
```
