# Apply multi-campus charter host apportionment

Internal helper for
[`id_charter_hosts`](https://almartin82.github.io/njschooldata/reference/id_charter_hosts.md).
For charters present in `charter_host_apportionment`, expands the single
NJ-reported row into one row per host city (year-aware when `end_year`
is present), overwriting the host columns and setting `share`. Rows for
charters without an apportionment entry pass through unchanged with
`share == 1.0`.

## Usage

``` r
apply_charter_apportionment(df, id_col = "district_id")
```

## Arguments

- df:

  output of the 1:1 host join, already carrying `share == 1.0` and
  `is_apportioned == FALSE`

- id_col:

  name of the district identifier column (`"district_id"` or
  `"district_code"`)

## Value

df with apportioned charters expanded share-weighted

## Details

The expansion is share-preserving: the shares for the rows produced from
a single input row always sum to 1.0, so multiplying any summed count by
`share` before aggregating preserves the charter's total.
