# Get raw English Learner population data for one year

Returns one row per entity (state, district, school) carrying the
published EL headcount and total enrollment. The entity scaffold (ids,
names, CDS code, NCES ids, total enrollment) is taken from
\`fetch_enr()\`; the EL headcount is read directly from the published
source so 2020+ years keep the real count rather than the derived value
\`get_raw_enr()\` computes.

## Usage

``` r
get_raw_ell(end_year)
```

## Arguments

- end_year:

  ending academic year. Valid values: 2006-2026.

## Value

data.frame with entity identifiers, \`total_enrollment\`, \`el_count\`
(NA where only a percent is published), and \`el_pct\`.
