# Track sector ecosystem dynamics over time

Tracks charter market share, sector performance gap, and all-public
percentile over time for a host city. Answers questions like "As
Newark's charter share grew, how did overall city performance change?"

## Usage

``` r
ecosystem_trend(
  df_enrollment,
  df_performance,
  host_district_id,
  metric_col,
  peer_type = "statewide",
  year_col = "end_year"
)
```

## Arguments

- df_enrollment:

  Enrollment data (output of
  [`fetch_enr()`](https://almartin82.github.io/njschooldata/reference/fetch_enr.md))
  with sector aggregates

- df_performance:

  Performance data (e.g., graduation rates) with sector aggregates

- host_district_id:

  Character. Host district ID (e.g., "3570").

- metric_col:

  Character. Performance metric to track.

- peer_type:

  Character. Peer group for percentile. Default "statewide".

- year_col:

  Character. Year column. Default "end_year".

## Value

Dataframe with yearly ecosystem metrics:

- `charter_enrollment`: Students in charter sector

- `total_enrollment`: All public students in city

- `charter_share`: Percent of students in charters

- `sector_gap`: Charter - district performance difference

- `allpublic_percentile`: City's overall percentile rank
