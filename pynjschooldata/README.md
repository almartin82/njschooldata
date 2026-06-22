# pynjschooldata

Python wrapper for New Jersey school enrollment data.

This is a thin rpy2 wrapper around the [njschooldata](https://github.com/almartin82/njschooldata) R package. It provides the same functionality but returns pandas DataFrames.

## Requirements

- Python 3.9+
- R 4.0+
- The `njschooldata` R package installed

## Installation

```bash
# First, install the R package
# In R:
# remotes::install_github("almartin82/njschooldata")

# Then install the Python package
pip install pynjschooldata
```

## Quick Start

```python
import pynjschooldata as nj

# Check available years
years = nj.get_available_years()
print(f"Data available from {years['min_year']} to {years['max_year']}")

# Fetch one year
df = nj.fetch_enr(2025)

# Fetch multiple years
df_multi = nj.fetch_enr_multi([2020, 2021, 2022, 2023, 2024, 2025])

# Convert to tidy format
tidy = nj.tidy_enr(df)

# Fetch facilities data
facilities = nj.fetch_facilities("finance")
facility_points = nj.fetch_facility_gis("school_points")
```

## API

### `fetch_enr(end_year: int) -> pd.DataFrame`

Fetch enrollment data for a single school year.

### `fetch_enr_multi(end_years: list[int]) -> pd.DataFrame`

Fetch enrollment data for multiple school years.

### `tidy_enr(df: pd.DataFrame) -> pd.DataFrame`

Convert enrollment data to tidy (long) format.

### `get_available_years() -> dict`

Get the range of available years (`min_year`, `max_year`).

### `fetch_facilities(category: str, year=None) -> pd.DataFrame`

Fetch source-backed New Jersey facilities data on the canonical long schema.

### `fetch_facility_gis(layer: str = "school_points") -> pd.DataFrame`

Fetch NJGIN school point geometry. Returns a GeoDataFrame when spatial Python
packages are installed, otherwise a pandas DataFrame with coordinates and WKT.

### `get_available_facilities() -> pd.DataFrame`

List shipped facilities categories with source agency, URL, type, and vintage.

## Part of the 50 State Schooldata Family

This package is part of a family of packages providing school enrollment data for all 50 US states.

**See also:** [caschooldata](https://github.com/almartin82/caschooldata)

## License

MIT
