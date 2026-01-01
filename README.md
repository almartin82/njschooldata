# njschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/njschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/njschooldata/actions/workflows/R-CMD-check.yaml)
[![Python Tests](https://github.com/almartin82/njschooldata/actions/workflows/python-test.yaml/badge.svg)](https://github.com/almartin82/njschooldata/actions/workflows/python-test.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

Fetch and analyze New Jersey school enrollment data from [NJDOE](https://www.nj.gov/education/doedata/) in R or Python.

## Installation

```r
# install.packages("remotes")
remotes::install_github("almartin82/njschooldata")
```

## Quick Start

### R

```r
library(njschooldata)

# Get available years
get_available_years()

# Fetch enrollment data for 2024-25
df <- fetch_enr(2025)
head(df)
```

### Python

```python
import pynjschooldata as nj

# Get available years
years = nj.get_available_years()
print(f"Data available from {years['min_year']} to {years['max_year']}")

# Fetch enrollment data for 2024-25
df = nj.fetch_enr(2025)
df.head()

# Fetch multiple years
df_multi = nj.fetch_enr_multi([2023, 2024, 2025])
```

## Part of the State Schooldata Project

A simple, consistent interface for accessing state-published school data in Python and R.

**All 50 state packages:** [github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

[Andy Martin](https://github.com/almartin82) (almartin@gmail.com)

## License

MIT
