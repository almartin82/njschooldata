# GEPA Fixed-Width File Layout

Column layout specification for reading Grade Eight Proficiency
Assessment (GEPA) fixed-width format data files.

A processed R version of the 'File Layout' for the 2004-2007 GEPA.
Original file is in .xls format on NJDOE website

## Usage

``` r
layout_gepa

layout_gepa
```

## Format

A data frame with 486 rows and 10 columns:

- field_start_position:

  Starting position of field in fixed-width file

- field_end_position:

  Ending position of field in fixed-width file

- field_length:

  Length of field in characters

- data_type:

  Data type of field (e.g., "Text", "Numeric")

- description:

  Description of field

- comments:

  Additional comments about field

- valid_values:

  Valid values or ranges for field

- spanner1:

  First-level column grouping label

- spanner2:

  Second-level column grouping label

- final_name:

  Final column name to use in parsed data

&nbsp;

- field_start_position:

  field_start_position

- field_end_position:

  field_end_position

- field_length:

  field_length

- data_type:

  data_type

- description:

  description

- comments:

  comments

- valid_values:

  valid_values

- spanner1:

  spanner1

- spanner2:

  spanner2

- final_name:

  final_name

## Source

NJ Department of Education GEPA file specifications

NJDOE website - eg the 'File Layout' link on
http://www.nj.gov/education/schools/achievement/2005/gepa/
