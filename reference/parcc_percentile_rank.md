# Assessment proficiency percentile rank

Convenience wrapper for calculating percentile rank of assessment
proficiency within a peer group. This is the generic version of the
assessment-specific functions in peer_percentiles.R.

## Usage

``` r
parcc_percentile_rank(
  df,
  peer_type = "statewide",
  custom_ids = NULL,
  metric = c("proficient_above", "scale_score_mean"),
  by_grade = TRUE,
  by_subject = TRUE,
  by_subgroup = TRUE
)
```

## Arguments

- df:

  Output of
  [`fetch_parcc()`](https://almartin82.github.io/njschooldata/reference/fetch_parcc.md)
  or similar assessment data

- peer_type:

  Character. Peer group type. See
  [`define_peer_group()`](https://almartin82.github.io/njschooldata/reference/define_peer_group.md).

- custom_ids:

  Character vector. Custom peer group district IDs.

- metric:

  Character. Which metric to rank on. One of "proficient_above" or
  "scale_score_mean". Default "proficient_above".

- by_grade:

  Logical. Calculate separate percentiles by grade? Default TRUE.

- by_subject:

  Logical. Calculate separate percentiles by test/subject? Default TRUE.

- by_subgroup:

  Logical. Calculate separate percentiles by subgroup? Default TRUE.

## Value

df with percentile rank columns for the specified metric
