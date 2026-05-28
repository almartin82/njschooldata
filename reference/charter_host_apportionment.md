# Multi-Campus Charter Host-City Apportionment

A year-aware companion to
[`charter_city`](https://almartin82.github.io/njschooldata/reference/charter_city.md)
that splits the NJ-reported totals of multi-campus charter schools
across their host cities. NJ DOE assigns one `district_id` per charter
and does NOT report charter campuses separately, but a few charters
operate campuses in more than one host city under a single
`district_id`. For those, attributing 100 charter's enrollment to one
host city (as the 1:1 `charter_city` map would) overstates that city's
charter sector and erases the other host city.

## Usage

``` r
charter_host_apportionment
```

## Format

A data frame with 8 columns:

- district_id:

  Charter school district identifier (matches
  `charter_city$district_id`)

- end_year:

  School year ending year the share applies to (integer)

- host_county_id:

  County code of the host district

- host_county_name:

  County name of the host district

- host_district_id:

  Host district identifier

- host_district_name:

  Host district name

- share:

  Fraction of the charter's NJ-reported totals attributed to this host
  city; sums to 1.0 per district_id per end_year

- share_basis:

  Documented provenance of the share (e.g. single-campus year vs
  PLACEHOLDER split)

## Source

NJ Department of Education enrollment files and school directory;
host-city allocation is an explicit documented apportionment (see
Details).

## Details

Each row gives the fraction (`share`) of a charter's NJ-reported totals
attributed to one host city in one year. Shares sum to 1.0 per
`district_id` per `end_year`. Single-city charters need NO entry here
(their implicit share is 1.0 via `charter_city`);
[`id_charter_hosts`](https://almartin82.github.io/njschooldata/reference/id_charter_hosts.md)
only expands charters that appear in this table. Downstream
charter-sector and all-public aggregations multiply summed counts by
`share` before summing, so the charter's total is preserved exactly
across host cities.

**This is apportionment of real data, not fabrication.** The charter
TOTAL enrollment is REAL NJ DOE data; only its allocation across host
cities is an explicit, documented apportionment, used because NJ does
not report campuses separately. A 0.5/0.5 split is an explicit
PLACEHOLDER (see `share_basis`), never an NJ-reported campus count. No
campus-level enrollment numbers are invented.

Currently the only entry is M.E.T.S. Charter School (district 6068),
which ran a Jersey City campus and opened a Newark campus in 2017:
through 2017 it is 100 placeholder. KIPP TEAM Academy / KIPP Paterson
(district 7325) was investigated as a candidate but NOT added: the NJ
DOE directory shows district 7325 in Newark only, with no Paterson
campus reporting under that `district_id`, so no verifiable share
exists.

## See also

[`charter_city`](https://almartin82.github.io/njschooldata/reference/charter_city.md),
[`id_charter_hosts`](https://almartin82.github.io/njschooldata/reference/id_charter_hosts.md)
