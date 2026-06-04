# Load the bundled NJ CDS -\> NCES crosswalk

Reads the identifiers-only crosswalk shipped in
`inst/extdata/crosswalk/nj_nces_crosswalk.csv`. All columns are returned
as character so the CDS codes keep their zero-padding.

## Usage

``` r
load_nces_crosswalk()
```

## Value

A data frame with columns `entity_level`, `county_id`, `district_id`,
`school_id`, `nces_dist`, `nces_sch`.
