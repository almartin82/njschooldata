# Ensure an apportionment `share` column exists

[`id_charter_hosts`](https://almartin82.github.io/njschooldata/reference/id_charter_hosts.md)
adds a `share` column (the multi-campus charter apportionment weight;
1.0 for single-host charters and non-charters). Aggregation helpers
multiply summed counts by `share` so an apportioned charter contributes
`share` of its NJ-reported total to each host city, preserving the
charter total exactly. Some inputs never pass through `id_charter_hosts`
(e.g. `calculate_agg_parcc_prof`); for those this helper supplies
`share = 1`, leaving counts unchanged. The grouping/grouped-ness of the
input is preserved.

## Usage

``` r
ensure_appt_share(df)
```

## Arguments

- df:

  data frame (possibly grouped) being summarized

## Value

df with a `share` column guaranteed present
