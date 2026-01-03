# njschooldata (Python)

Python bindings for the njschooldata R package, providing access to New Jersey Department of Education school data.

## Prerequisites

This package requires:
1. R (>= 4.0) installed on your system
2. The njschooldata R package

Install the R package first:

```r
# In R
install.packages("remotes")
remotes::install_github("almartin82/njschooldata")
```

## Installation

```bash
pip install git+https://github.com/almartin82/njschooldata.git#subdirectory=python
```

Or for development:

```bash
git clone https://github.com/almartin82/njschooldata.git
cd njschooldata/python
pip install -e ".[dev]"
```

## Usage

```python
import njschooldata as njsd

# Enrollment data
enr_2024 = njsd.fetch_enr(2024)
enr_tidy = njsd.fetch_enr(2024, tidy=True)

# Assessment data (PARCC/NJSLA)
math_g4 = njsd.fetch_parcc(2023, 4, 'math')
ela_g8 = njsd.fetch_parcc(2023, 8, 'ela')
alg1 = njsd.fetch_parcc(2023, 'ALG1', 'math')

# ACCESS for ELLs
access_2024 = njsd.fetch_access(2024)

# Graduation rates
grate_2023 = njsd.fetch_grad_rate(2023)
grate_5yr = njsd.fetch_grad_rate(2023, methodology="5 year")

# School/district directories
schools = njsd.get_school_directory()
districts = njsd.get_district_directory()
```

## Available Functions

| Function | Description |
|----------|-------------|
| `fetch_enr(end_year, tidy=False)` | Enrollment data (2000-2025) |
| `fetch_parcc(end_year, grade_or_subj, subj, tidy=False)` | PARCC/NJSLA assessment data (2015-2024) |
| `fetch_access(end_year, grade="all")` | ACCESS for ELLs data (2022-2024) |
| `fetch_grad_rate(end_year, methodology="4 year")` | Graduation rates (2011-2024) |
| `get_school_directory()` | Current school directory |
| `get_district_directory()` | Current district directory |

## License

GPL-3.0
