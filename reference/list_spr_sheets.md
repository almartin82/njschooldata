# List Available SPR Sheets

Returns a vector of all sheet names available in the SPR database for a
given year and level. Useful for discovering what data is available.

## Usage

``` r
list_spr_sheets(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024). Year is the end of the academic year - eg
  2020-21 school year is end_year '2021'.

- level:

  One of "school" or "district". Determines which database file to
  query.

## Value

Character vector of sheet names

## Examples

``` r
if (FALSE) { # \dontrun{
# List all school-level sheets for 2024
sheets <- list_spr_sheets(2024)

# List all district-level sheets
district_sheets <- list_spr_sheets(2024, level = "district")

# Search for specific types of sheets
attendance_sheets <- sheets[grepl("Absent|Attendance", sheets, ignore.case = TRUE)]
} # }
```
