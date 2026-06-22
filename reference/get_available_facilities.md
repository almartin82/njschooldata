# What facilities categories are available for New Jersey

Returns the shipped category-to-source mapping with source agency, type,
URL, and vintage. This is metadata-only and does not download full
source files.

## Usage

``` r
get_available_facilities()
```

## Value

Data frame with \`category\`, \`source\`, \`source_agency\`,
\`source_type\`, \`source_url\`, and \`vintage\`.

## Examples

``` r
available <- get_available_facilities()
unique(available$category)
#> [1] "inventory"     "attributes"    "capacity"      "projects"     
#> [5] "finance"       "environmental" "closures"     
subset(available, category == "environmental")
#>        category         source source_agency source_type
#> 7 environmental njdoe_lead_soa         NJDOE        xlsx
#>                                                                     source_url
#> 7 https://www.nj.gov/education/lead/docs/24-25SOA_SubmissionsLeadDW102825.xlsx
#>                                                 vintage
#> 7 2024-2025 Lead SOA submissions, file dated 2025-10-28
```
