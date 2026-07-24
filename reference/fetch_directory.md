# Fetch the current New Jersey education directory (directory-contract/v1)

Downloads the current official New Jersey directory from the NJDOE
Homeroom public download endpoints and returns the canonical triple
`list(entities, roles, meta)` defined by directory-contract/v1.
Districts (including single-site charter LEAs) are keyed by the county +
district CDS code; schools by the county + district + school CDS code.
District superintendents, business administrators, and special-education
coordinators are attached as district-grain `roles`; school principals
as school-grain `roles`. Source-declared vacancies are rows with
`person_name` `NA` and the verbatim `title_raw` preserved.

## Usage

``` r
fetch_directory()
```

## Value

A named list with components:

- entities:

  One row per organization (district / school), canonically sorted.

- roles:

  One row per organization-role assignment (long), canonically sorted.

- meta:

  Self-describing metadata: schema version, sources, id scheme,
  coverage, counts, and quality.

## Details

The New Jersey source publishes SPLIT first/last name fields;
`first_name` and `last_name` come directly from those source columns and
`person_name` is assembled from them (see `R/directory_contract.R`).

## Examples

``` r
if (FALSE) { # \dontrun{
dir <- fetch_directory()
dir$entities
dir$roles
dir$meta$counts
} # }
```
