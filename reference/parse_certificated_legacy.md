# Parse a legacy (2000-2008) certificated-staff CSV into harmonized long form

The legacy member is a 20-column CSV (member filename varies:
`STAT_STFrae.CSV`, `STAT_STFSUM.CSV`, `STAT_STF.CSV`, `cert.csv`) with
one row per entity x position x sex. `POSITION` is printed only on the
`MALE` row of each (entity, position) triple and is filled down. The
race columns are `WHITE`, `BLACK`, `HISP`, `ALS_IND` (American Indian)
and `ASI_PAC` (a single combined Asian/Pacific-Islander bucket – NJ did
not separate them in this era, so `asian` carries the combined count and
`pacific_islander` / `two_or_more` are `NA`, never 0). Entity
conventions: state = `CONAME == "STATE SUM"`, county = `DIST == "9998"`
(CO SUMMARY), district total = `SCH == "998"` (DIST SUMMARY), school =
everything else.

## Usage

``` r
parse_certificated_legacy(path, end_year)
```

## Arguments

- path:

  Path to the legacy CSV.

- end_year:

  The school year end.

## Value

A harmonized long-by-gender data frame.
