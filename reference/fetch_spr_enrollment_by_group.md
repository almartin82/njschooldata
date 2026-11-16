# Fetch enrollment share by student group from the School Performance Reports

The percent of each school's (or district's) enrollment in each student
group, from the "Enrollment Trends by Student Group" sheet of the NJ
School Performance Reports, in one layout for every year 2016-17 through
2024-25.

## Usage

``` r
fetch_spr_enrollment_by_group(end_year, level = "school")
```

## Arguments

- end_year:

  A school year end, 2017-2025 (2016-17 is 2017).

- level:

  `"school"` (default) or `"district"`. The district file also holds the
  state rows.

## Value

A data frame, columns in this order:

- end_year:

  integer

- county_id, county_name, district_id, district_name, school_id,
  school_name:

  character; `school_id` is `"999"` on district and state rows

- subgroup:

  character, the student group

- pct:

  numeric, the published percent of enrollment (0-100). `NA` when NJDOE
  published a range, a bound or a suppression note instead of one
  number, or left the cell blank.

- pct_published:

  character, the cell exactly as NJDOE published it (for example
  `"39.1"`, `"39.1%"`, `"<=5%"`, `"20-30%"`)

- is_state, is_county, is_district, is_school, is_charter,
  is_charter_sector, is_allpublic:

  logical entity flags

## Details

NJDOE changed this sheet's layout several times (one row per group in
2016-17, one column per group afterward, text cells with percent signs
in 2024-25, five school years per sheet in 2024-25). This function
returns one row per entity x student group for the requested year only;
earlier years in a trend sheet are dropped, and come from their own
year's file.

Subgroup names are stable across NJDOE's relabels: English Learners and
Multilingual Learners are both `"limited english proficiency"`; Homeless
Students and Students Experiencing Homelessness are both
`"homeless students"`. `"non-binary/undesignated gender"` has rows only
in years NJDOE published it (district file from 2019-20, school file
from 2020-21).

## Examples

``` r
if (FALSE) { # \dontrun{
groups <- fetch_spr_enrollment_by_group(2024)
econ <- groups[groups$subgroup == "economically disadvantaged", ]
} # }
```
