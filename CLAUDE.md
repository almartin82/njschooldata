# CLAUDE.md

## CRITICAL DATA SOURCE RULES

**NEVER use Urban Institute API, NCES CCD, or ANY federal data source**
— the entire point of these packages is to provide STATE-LEVEL data
directly from state DOEs. Federal sources aggregate/transform data
differently and lose state-specific details. If a state DOE source is
broken, FIX IT or find an alternative STATE source — do not fall back to
federal data.

**NEVER fabricate data in ANY form.** This is the single most important
rule in the entire project. Violations include but are not limited to:

- **Random generation:**
  [`rnorm()`](https://rdrr.io/r/stats/Normal.html),
  [`runif()`](https://rdrr.io/r/stats/Uniform.html),
  [`set.seed()`](https://rdrr.io/r/base/Random.html),
  [`sample()`](https://rdrr.io/r/base/sample.html),
  [`rlnorm()`](https://rdrr.io/r/stats/Lognormal.html),
  [`rgamma()`](https://rdrr.io/r/stats/GammaDist.html), or any random
  number generation
- **Hardcoded numbers:** Hand-typing enrollment counts in `tribble()`,
  [`data.frame()`](https://rdrr.io/r/base/data.frame.html), `tibble()`,
  or any other data structure. If a human typed the number instead of
  downloading it from a state DOE, it is fabricated.
- **“Plausible-looking” fake data:** Creating numbers that look real but
  aren’t — smooth monotonic trends, round numbers, demographically
  “reasonable” percentages applied uniformly. This is the WORST form of
  fabrication because it is designed to deceive.
- **`create_example_data()` functions:** Helper functions that generate
  fake datasets, regardless of how realistic they look
- **Fixed demographic percentages:** Applying constant demographic
  ratios across all years/districts (real demographics change year to
  year)
- **Uniform grade distributions:** Using the same grade-level
  percentages for every district (real districts vary significantly)

**The test is simple: can you trace every number back to a downloaded
file from a state DOE website?** If not, it is fabricated. There is no
gray area. If the data source is unavailable, the package MUST use Under
Construction status — not fake data.

------------------------------------------------------------------------

## Project Overview

R package for fetching and processing New Jersey school data from the NJ
Department of Education.

## Reference Docs (`dev-docs/`)

Detailed reference lives in `dev-docs/`. This file holds the always-on
rules; load the relevant doc only when the trigger applies, to keep
context lean.

| Doc | Load when |
|----|----|
| [`dev-docs/enrollment-filter-values.md`](https://almartin82.github.io/njschooldata/dev-docs/enrollment-filter-values.md) | Writing [`filter()`](https://rdrr.io/r/stats/filter.html) calls against `fetch_enr(tidy = TRUE)`, authoring enrollment stories, or a filter silently returns 0 rows |
| [`dev-docs/vignette-authoring.md`](https://almartin82.github.io/njschooldata/dev-docs/vignette-authoring.md) | Editing any vignette `.Rmd`, regenerating/restyling charts, or debugging stale/missing charts (committed-PNG + knitr cache rules) |
| [`dev-docs/pkgdown-deploy.md`](https://almartin82.github.io/njschooldata/dev-docs/pkgdown-deploy.md) | Configuring or debugging the pkgdown deploy, editing `_pkgdown.yml`, or enabling Pages on a new repo |
| [`dev-docs/data-source-urls.md`](https://almartin82.github.io/njschooldata/dev-docs/data-source-urls.md) | A fetcher 404s / returns HTML, a download is empty, or a fetch URL needs updating for a new year |
| [`dev-docs/spr-coverage-gap.md`](https://almartin82.github.io/njschooldata/dev-docs/spr-coverage-gap.md) | Triaging which redesigned 2024-25 SPR sheets to expose as new fetchers, or scoping SPR coverage work |

## Project Structure - PUBLIC vs PRIVATE

**njschooldata is a PUBLIC, OPEN SOURCE project.** Only general-purpose
infrastructure code belongs in the package itself (`R/`, `tests/`,
etc.).

| Location | Visibility | Purpose |
|----|----|----|
| `R/`, `tests/`, `man/` | **PUBLIC** | General-purpose functions for fetching/processing NJ school data |

**Guidelines:** - Code that could benefit any user of NJ school data →
goes in `R/` - Code specific to a particular research question or
district → goes in `research-private/` - Helper functions created during
research that are general-purpose → refactor into `R/` -
District-specific constants, analysis scripts, cached data → stay in
`research-private/`

## Commit Guidelines

- Do NOT include Claude’s name, “Co-Authored-By”, or any AI attribution
  in commit messages
- Keep commit messages concise and focused on the changes made

## Slash Commands

- `/deploy` - Full deployment pipeline: security review, tests, linter,
  build, deploy
- `/security-review` - Security audit of the package

## Testing

Run tests with: `devtools::test()` or `Rscript -e "devtools::test()"`

**Note:** Tests are disabled in CI/CD due to NJ DOE network
dependencies. Run locally before deploying.

## Caching

Session caching is enabled by default to avoid hitting NJ DOE bot
protection: -
[`njsd_cache_info()`](https://almartin82.github.io/njschooldata/reference/njsd_cache_info.md) -
view cache status -
[`njsd_cache_clear()`](https://almartin82.github.io/njschooldata/reference/njsd_cache_clear.md) -
clear cache - `njsd_cache_enable(FALSE)` - disable caching

The cache validates responses and will NOT cache network errors or bot
protection pages.
