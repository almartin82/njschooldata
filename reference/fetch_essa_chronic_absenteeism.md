# Fetch ESSA Chronic Absenteeism data

Downloads and processes chronic absenteeism data from ESSA
Accountability Workbooks. Data shows attendance rates by student
subgroup; chronic absenteeism rate = 100 - attendance rate.

## Usage

``` r
fetch_essa_chronic_absenteeism(end_year)
```

## Arguments

- end_year:

  A school year. Valid values are 2017-2019 and 2022-2024.

## Value

Processed chronic absenteeism dataframe with columns including:

- county_id, district_id, school_id, configuration

- Attendance rates by student subgroup (asian, black, hispanic, etc.)

- total_attendance_rate, total_chronic_absenteeism_rate

## Details

Note: This data is from ESSA accountability workbooks and covers schools
included in ESSA accountability calculations (approximately 2,300+
schools). Data for 2020-2021 is not available due to COVID-19 pandemic
disruptions.

For chronic absenteeism data from SPR databases (2017-2024), use
[`fetch_chronic_absenteeism`](https://almartin82.github.io/njschooldata/reference/fetch_chronic_absenteeism.md)
instead.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 chronic absenteeism data from ESSA workbooks
ca_2024 <- fetch_essa_chronic_absenteeism(2024)

# Calculate chronic absenteeism rates
ca_2024$chronic_absent_black <- 100 - ca_2024$attendance_black
} # }
```
