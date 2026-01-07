# Fetch Seal of Biliteracy Data

Downloads and extracts Seal of Biliteracy data from the SPR database.
The Seal of Biliteracy recognizes students who attain proficiency in
English and one or more world languages.

## Usage

``` r
fetch_biliteracy_seal(end_year, level = "school")
```

## Arguments

- end_year:

  A school year (2017-2024). Year is the end of the academic year - eg
  2020-21 school year is end_year '2021'.

- level:

  One of "school" or "district". "school" returns school-level data,
  "district" returns district and state-level data.

## Value

Data frame with Seal of Biliteracy data including:

- end_year, county_id, county_name, district_id, district_name

- school_id, school_name (for school-level data)

- language - Language (e.g., "Spanish", "French", "Chinese")

- seals_earned - Number of seals earned in this language

- pct_12th_graders - Percentage of 12th graders earning seals

- Aggregation flags (is_state, is_county, is_district, is_school,
  is_charter)

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 biliteracy seal data
biliteracy <- fetch_biliteracy_seal(2024)

# Top languages by seal count
biliteracy %>%
  group_by(language) %>%
  summarize(total_seals = sum(seals_earned, na.rm = TRUE)) %>%
  dplyr::arrange(desc(total_seals))

# Schools with most diverse language offerings
biliteracy %>%
  group_by(school_name) %>%
  summarize(num_languages = sum(seals_earned > 0, na.rm = TRUE)) %>%
  dplyr::arrange(desc(num_languages))
} # }
```
