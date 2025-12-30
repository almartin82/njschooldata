# Newark Address Addendum

Additional address data for Newark schools to supplement geocoding.
Contains school addresses that were not included in the main school
directory or needed corrections for proper geocoding.

## Usage

``` r
nwk_address_addendum
```

## Format

A data frame with 98 rows and 5 columns:

- district_id:

  District identifier (Newark district is 3570)

- school_id:

  School identifier code

- school_name:

  Name of the school

- address:

  Full street address with city, state

- in_geocode:

  Logical indicating if address is in geocode cache

## Source

Manual address corrections for Newark schools
