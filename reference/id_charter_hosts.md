# Identify charter host districts

Joins NJ school data to the 1:1 `charter_city` host map, attaching
`host_county_id`, `host_county_name`, `host_district_id` and
`host_district_name` for every charter record.

## Usage

``` r
id_charter_hosts(df)
```

## Arguments

- df:

  dataframe of NJ school data containing a `district_id` (or
  `district_code`) column. If an `end_year` column is present,
  apportionment is applied year-aware; otherwise the apportionment
  shares are matched on `district_id` alone (use a year column for
  correct results when shares vary by year).

## Value

df with host district id/name plus a `share` column (1.0 for single-host
charters and non-charters; fractional for apportioned multi-campus
charters) and an `is_apportioned` logical flag. Rows for apportioned
charters are duplicated, one per host city.

## Details

**Multi-campus charters.** NJ DOE assigns one `district_id` per charter
and does NOT report charter campuses separately, but a few charters
operate campuses in more than one host city under a single `district_id`
(e.g. M.E.T.S. Charter School, district 6068, which ran a Jersey City
campus and later a Newark campus). For those, the
`charter_host_apportionment` table splits the charter's NJ-reported
totals across host cities by a `share` fraction that sums to 1.0 per
`district_id` per `end_year`. When a charter has an apportionment entry
for the relevant year, its single input row is expanded into one row per
host city, the host columns are overwritten from the apportionment
table, and `share` is set accordingly so downstream aggregations can
multiply summed counts by `share` before summing. The charter total is
preserved exactly.

The apportioned host assignment for these charters is an explicit,
documented apportionment of real NJ-reported totals (the 50/50 METS
split is a PLACEHOLDER), never an NJ-reported campus count. See
[`charter_host_apportionment`](https://almartin82.github.io/njschooldata/reference/charter_host_apportionment.md).
