# Get districts in a specific District Factor Group

Returns the district IDs for all districts in a specific District Factor
Group. DFG A represents the highest-need communities in New Jersey and
is commonly used as a peer group for urban districts.

This function fetches the DFG data from NJ DOE and filters to the
requested group.

## Usage

``` r
get_dfg_districts(dfg_code, revision = 2000)
```

## Arguments

- dfg_code:

  Character. The DFG code to filter to (e.g., "A", "B", "CD").

- revision:

  Numeric. Which DFG revision to use (2000 or 1990). Default 2000.

## Value

Character vector of district_ids in the specified DFG

## Examples

``` r
if (FALSE) { # \dontrun{
# Get all DFG A districts (highest need)
dfg_a <- get_dfg_districts("A")

# Use as peer group for percentile ranking
grate %>%
  define_peer_group("custom", custom_ids = dfg_a) %>%
  add_percentile_rank("grad_rate")
} # }
```
