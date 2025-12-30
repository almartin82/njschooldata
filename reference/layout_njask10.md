# NJASK 2010 Fixed-Width File Layout

Column layout specification for reading New Jersey Assessment of Skills
and Knowledge (NJASK) 2010 fixed-width format data files.

## Usage

``` r
layout_njask10
```

## Format

A data frame with 524 rows and 10 columns:

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

## Source

NJ Department of Education NJASK 2010 file specifications
