# Materialize one IDEA 618 placement workbook for this call

Uses verified release bytes when held, otherwise a per-call download.
ZIP members are extracted to a temporary workbook and validated before
use.

## Usage

``` r
sped_placement_cached_workbook(
  end_year,
  file_label = "consolidated",
  url = NULL,
  zip_member = NULL
)
```

## Arguments

- end_year:

  ending school year

- file_label:

  per-file slug for cache differentiation (eg "5-21_district_race",
  "consolidated"). Defaults to "consolidated" so v1 callers continue to
  work.

- url:

  full HTTP URL of the workbook (or the parent zip)

- zip_member:

  if the URL is a .zip, path inside the archive to extract

## Value

path to a local, validated .xlsx file
