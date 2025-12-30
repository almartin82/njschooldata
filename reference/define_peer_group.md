# Define a peer comparison group

Creates grouping on a dataframe that defines which entities are compared
to each other for percentile rank calculations. The returned df can be
piped directly to
[`percentile_rank()`](https://almartin82.github.io/njschooldata/reference/percentile_rank.md).

## Usage

``` r
define_peer_group(
  df,
  peer_type = c("statewide", "dfg", "county", "custom"),
  custom_ids = NULL,
  level = c("district", "school"),
  year_col = "end_year",
  additional_groups = NULL
)
```

## Arguments

- df:

  Dataframe with entity identifiers

- peer_type:

  Character. One of:

  - "statewide": Compare to all districts/schools in state

  - "dfg": Compare within District Factor Group

  - "county": Compare within county

  - "custom": Compare to custom list of district_ids

- custom_ids:

  Character vector of district_ids for custom peer groups. Only used
  when peer_type = "custom".

- level:

  Character. One of "district" or "school" - what level to compare.

- year_col:

  Character. Name of the year column. Default "end_year".

- additional_groups:

  Character vector. Additional columns to group by (e.g., "subgroup",
  "grade", "test_name").

## Value

Grouped dataframe ready for
[`add_percentile_rank()`](https://almartin82.github.io/njschooldata/reference/add_percentile_rank.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# DFG peer group for districts
grate %>%
  define_peer_group("dfg", level = "district") %>%
  add_percentile_rank("grad_rate")

# Custom peer group (DFG A districts)
grate %>%
  define_peer_group("custom", custom_ids = dfg_a_districts, level = "district") %>%
  add_percentile_rank("grad_rate")
} # }
```
