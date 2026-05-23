# Fetch Graduation Pathways

Downloads the `GraduationPathways` sheet from the redesigned 2024-25
School Performance Reports. For each entity and subject (ELA and Math),
it reports the percentage of graduates who satisfied the
graduation-assessment requirement through each available pathway.

## Usage

``` r
fetch_spr_grad_pathways(end_year, level = "school")
```

## Arguments

- end_year:

  A school year. Only `2025` (SY2024-25) and later are supported.

- level:

  One of `"school"` or `"district"`.

## Value

Data frame with entity identifiers, school_year, subject, the four
pathway percentage columns, and the aggregation flags.

## Details

Pathways (columns, each a percentage on a 0-100 scale):

- `statewide_assessment` – met via the statewide NJSLA/NJGPA assessment.

- `substitute_competency_test` – met via an approved substitute
  competency test (e.g. SAT, ACT, PSAT, ASVAB).

- `portfolio_appeals` – met via the portfolio appeals process.

- `alternate_requirements_in_iep` – met via alternate requirements
  specified in the student's IEP.

Percentages are returned numeric (suppressed cells become `NA`).

**Supported years:** only `end_year >= 2025` (the redesigned SY2024-25
SPR). Earlier databases do not include this sheet.

## Examples

``` r
if (FALSE) { # \dontrun{
# School-level graduation pathways
gp <- fetch_spr_grad_pathways(2025)

# Statewide ELA pathway mix
library(dplyr)
fetch_spr_grad_pathways(2025, level = "district") %>%
  filter(is_state, subject == "ELA") %>%
  select(statewide_assessment, substitute_competency_test,
         portfolio_appeals, alternate_requirements_in_iep)

# Schools leaning hardest on portfolio appeals for Math
fetch_spr_grad_pathways(2025) %>%
  filter(is_school, subject == "Math") %>%
  slice_max(portfolio_appeals, n = 10) %>%
  select(district_name, school_name, portfolio_appeals)
} # }
```
