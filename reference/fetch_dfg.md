# Fetch NJ District Factor Group (DFG) data

Downloads DFG classification data from NJ DOE. DFGs group districts by
socioeconomic status for comparison purposes. DFG A represents the
highest-need communities; DFG J represents the lowest-need.

Note: DFGs were last updated using 2000 Census data and are no longer
maintained by NJ DOE, but remain useful for peer comparisons.

## Usage

``` r
fetch_dfg(revision = 2000)
```

## Arguments

- revision:

  c(2000, 1990) Which census revision to use. Default 2000.

## Value

data.frame with columns: county_code, county_name, district_code,
district_name, dfg

## References

<https://www.nj.gov/education/stateaid/dfg.shtml>
