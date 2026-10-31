# Get available end years under default selectors

Reports years served by a type's fetcher with \`source = "live"\` or
\`source = "package"\`, and all other selectors at their defaults.
Coverage is computed offline from the declarations the fetchers enforce.
Years requiring non-default selectors or private stores are excluded.

## Usage

``` r
get_available_years(type = NULL)
```

## Arguments

- type:

  A single fetch family name, such as \`"enrollment"\`, or \`NULL\` for
  all declared types.

## Value

With \`type\`, a sorted, unique integer vector of school year ends. With
\`NULL\`, a data frame with columns \`type\`, \`end_year\`, and
\`fetcher\`, ordered by type and year. Gaps in coverage remain visible.

## Details

Enrollment, absence, graduation, finance, and sped_share coverage is
declared. Absence excludes 2020, when chronic absenteeism was not
published. Assessment requires explicit grade/course and subject
selectors and remains undeclared. Other known fetch families raise an
error containing "coverage not yet declared".

## Examples

``` r
get_available_years("enrollment")
#>  [1] 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013
#> [16] 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025 2026
get_available_years()
#>          type end_year          fetcher
#> 44    absence     2017    fetch_absence
#> 45    absence     2018    fetch_absence
#> 46    absence     2019    fetch_absence
#> 47    absence     2021    fetch_absence
#> 48    absence     2022    fetch_absence
#> 49    absence     2023    fetch_absence
#> 50    absence     2024    fetch_absence
#> 51    absence     2025    fetch_absence
#> 1  enrollment     1999        fetch_enr
#> 2  enrollment     2000        fetch_enr
#> 3  enrollment     2001        fetch_enr
#> 4  enrollment     2002        fetch_enr
#> 5  enrollment     2003        fetch_enr
#> 6  enrollment     2004        fetch_enr
#> 7  enrollment     2005        fetch_enr
#> 8  enrollment     2006        fetch_enr
#> 9  enrollment     2007        fetch_enr
#> 10 enrollment     2008        fetch_enr
#> 11 enrollment     2009        fetch_enr
#> 12 enrollment     2010        fetch_enr
#> 13 enrollment     2011        fetch_enr
#> 14 enrollment     2012        fetch_enr
#> 15 enrollment     2013        fetch_enr
#> 16 enrollment     2014        fetch_enr
#> 17 enrollment     2015        fetch_enr
#> 18 enrollment     2016        fetch_enr
#> 19 enrollment     2017        fetch_enr
#> 20 enrollment     2018        fetch_enr
#> 21 enrollment     2019        fetch_enr
#> 22 enrollment     2020        fetch_enr
#> 23 enrollment     2021        fetch_enr
#> 24 enrollment     2022        fetch_enr
#> 25 enrollment     2023        fetch_enr
#> 26 enrollment     2024        fetch_enr
#> 27 enrollment     2025        fetch_enr
#> 28 enrollment     2026        fetch_enr
#> 52    finance     2001    fetch_finance
#> 53    finance     2002    fetch_finance
#> 54    finance     2003    fetch_finance
#> 55    finance     2004    fetch_finance
#> 56    finance     2005    fetch_finance
#> 57    finance     2006    fetch_finance
#> 58    finance     2007    fetch_finance
#> 59    finance     2008    fetch_finance
#> 60    finance     2009    fetch_finance
#> 61    finance     2010    fetch_finance
#> 62    finance     2011    fetch_finance
#> 63    finance     2012    fetch_finance
#> 64    finance     2013    fetch_finance
#> 65    finance     2014    fetch_finance
#> 66    finance     2015    fetch_finance
#> 67    finance     2016    fetch_finance
#> 68    finance     2017    fetch_finance
#> 69    finance     2018    fetch_finance
#> 70    finance     2019    fetch_finance
#> 71    finance     2020    fetch_finance
#> 72    finance     2021    fetch_finance
#> 73    finance     2022    fetch_finance
#> 74    finance     2023    fetch_finance
#> 75    finance     2024    fetch_finance
#> 76    finance     2025    fetch_finance
#> 77    finance     2026    fetch_finance
#> 29 graduation     2011  fetch_grad_rate
#> 30 graduation     2012  fetch_grad_rate
#> 31 graduation     2013  fetch_grad_rate
#> 32 graduation     2014  fetch_grad_rate
#> 33 graduation     2015  fetch_grad_rate
#> 34 graduation     2016  fetch_grad_rate
#> 35 graduation     2017  fetch_grad_rate
#> 36 graduation     2018  fetch_grad_rate
#> 37 graduation     2019  fetch_grad_rate
#> 38 graduation     2020  fetch_grad_rate
#> 39 graduation     2021  fetch_grad_rate
#> 40 graduation     2022  fetch_grad_rate
#> 41 graduation     2023  fetch_grad_rate
#> 42 graduation     2024  fetch_grad_rate
#> 43 graduation     2025  fetch_grad_rate
#> 78 sped_share     2023 fetch_sped_share
#> 79 sped_share     2024 fetch_sped_share
#> 80 sped_share     2025 fetch_sped_share
#> 81 sped_share     2026 fetch_sped_share
coverage <- get_available_years()
subset(coverage, end_year == max(end_year))
#>          type end_year          fetcher
#> 28 enrollment     2026        fetch_enr
#> 77    finance     2026    fetch_finance
#> 81 sped_share     2026 fetch_sped_share
```
