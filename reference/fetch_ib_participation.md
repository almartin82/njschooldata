# Fetch IB Participation Data

Downloads and extracts International Baccalaureate participation from
the SPR database. Note: Most IB data is included in the AP/IB sheet, use
[`fetch_ap_participation`](https://almartin82.github.io/njschooldata/reference/fetch_ap_participation.md)
for comprehensive data.

## Usage

``` r
fetch_ib_participation(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024). Year is the end of the academic year - eg
  2020-21 school year is end_year '2021'.

- level:

  One of "school" or "district". "school" returns school-level data,
  "district" returns district and state-level data.

## Value

Data frame with IB participation metrics

## Examples

``` r
if (FALSE) { # \dontrun{
ib <- fetch_ib_participation(2024)
} # }
```
