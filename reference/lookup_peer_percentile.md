# Looks up caclulated percentile value by searching for closest scale score / proficient above match

Given a peer percentile lookup table with calculated mean scale score
and percent proficient distributions by year, grade, subgroup, take the
given values (likely of assessment aggregates) and find the closest
match to return percentiles

## Usage

``` r
lookup_peer_percentile(assess_agg, assess_percentiles)
```

## Arguments

- assess_agg:

  an assessments aggregate such as the output of
  `charter_sector_parcc_aggs`

- assess_percentiles:

  calculated assessments peer percentiles such as the output of
  `statewide_peer_percentile`

## Value

data.frame with percent proficient and scale score percentile ranks
