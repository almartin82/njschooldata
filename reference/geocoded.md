# Geocoded School Addresses

Cached geocoding results for New Jersey school addresses. Contains
latitude, longitude, and formatted addresses for schools, primarily
Newark addresses.

## Usage

``` r
geocoded
```

## Format

A data frame with 2,549 rows and 8 columns:

- lat:

  Latitude coordinate

- lng:

  Longitude coordinate

- formatted_address:

  Standardized address string

- status:

  Geocoding status (e.g., "tidygeocoder cascade")

- location_type:

  Location type from geocoding service

- error_message:

  Error message if geocoding failed

- locations:

  Original location string used for geocoding

- input_url:

  Input URL for geocoding request

## Source

Geocoded using tidygeocoder package
