# Fetch NJ School Directory Data

Downloads and processes the current school and/or district directory
from the NJ Department of Education. The directory includes contact
information, addresses, grade levels served, and administrative
personnel.

## Usage

``` r
fetch_directory(level = "school", use_cache = FALSE)
```

## Arguments

- level:

  Character string specifying what to return. One of:

  - `"school"` - School-level directory only (default)

  - `"district"` - District-level directory only

  - `"both"` - Combined school and district data

- use_cache:

  Logical; if TRUE (default), use session cache to avoid re-downloading
  data within the same R session.

## Value

A data frame with directory data. The exact columns depend on the
`level` parameter, but all include:

- `county_id`, `county_name` - County identifiers

- `district_id`, `district_name` - District identifiers

- `entity_type` - "school" or "district"

- `address`, `city`, `state`, `zip`

- `phone`

- `is_charter`, `is_school`, `is_district` - Boolean flags

- `cds_code` - Combined County-District-School code

School-level data additionally includes:

- `school_id`, `school_name`

- `principal_name`, `principal_email`

- `grades_served` - Comma-separated grade levels

District-level data additionally includes:

- `superintendent_name`, `superintendent_email`

- `website`

## Examples

``` r
if (FALSE) { # \dontrun{
# Get school directory
schools <- fetch_directory()

# Get district directory
districts <- fetch_directory(level = "district")

# Get both combined
all_dir <- fetch_directory(level = "both")

# Get charter school directory
charters <- fetch_directory() %>%
  dplyr::filter(is_charter)
} # }
```
