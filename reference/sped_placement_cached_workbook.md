# Download (and disk-cache) one IDEA 618 placement workbook

Validates the download as a real .xlsx before caching, so an HTTP error
or bot-protection page is never written to the cache or parsed as data.
For zip-archive years (2020, 2021), downloads the zip once, extracts the
requested member, and caches the member as a standalone .xlsx.

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
