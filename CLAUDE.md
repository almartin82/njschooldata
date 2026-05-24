## CRITICAL DATA SOURCE RULES

**NEVER use Urban Institute API, NCES CCD, or ANY federal data source** — the entire point of these packages is to provide STATE-LEVEL data directly from state DOEs. Federal sources aggregate/transform data differently and lose state-specific details. If a state DOE source is broken, FIX IT or find an alternative STATE source — do not fall back to federal data.

**NEVER fabricate data in ANY form.** This is the single most important rule in the entire project. Violations include but are not limited to:

- **Random generation:** `rnorm()`, `runif()`, `set.seed()`, `sample()`, `rlnorm()`, `rgamma()`, or any random number generation
- **Hardcoded numbers:** Hand-typing enrollment counts in `tribble()`, `data.frame()`, `tibble()`, or any other data structure. If a human typed the number instead of downloading it from a state DOE, it is fabricated.
- **"Plausible-looking" fake data:** Creating numbers that look real but aren't — smooth monotonic trends, round numbers, demographically "reasonable" percentages applied uniformly. This is the WORST form of fabrication because it is designed to deceive.
- **`create_example_data()` functions:** Helper functions that generate fake datasets, regardless of how realistic they look
- **Fixed demographic percentages:** Applying constant demographic ratios across all years/districts (real demographics change year to year)
- **Uniform grade distributions:** Using the same grade-level percentages for every district (real districts vary significantly)

**The test is simple: can you trace every number back to a downloaded file from a state DOE website?** If not, it is fabricated. There is no gray area. If the data source is unavailable, the package MUST use Under Construction status — not fake data.

---


# CLAUDE.md

## Project Overview
R package for fetching and processing New Jersey school data from the NJ Department of Education.

## Reference Docs (`dev-docs/`)

Detailed reference lives in `dev-docs/`. This file holds the always-on rules; load
the relevant doc only when the trigger applies, to keep context lean.

| Doc | Load when |
|-----|-----------|
| [`dev-docs/enrollment-filter-values.md`](dev-docs/enrollment-filter-values.md) | Writing `filter()` calls against `fetch_enr(tidy = TRUE)`, authoring enrollment stories, or a filter silently returns 0 rows |
| [`dev-docs/vignette-authoring.md`](dev-docs/vignette-authoring.md) | Editing any vignette `.Rmd`, regenerating/restyling charts, or debugging stale/missing charts (committed-PNG + knitr cache rules) |
| [`dev-docs/pkgdown-deploy.md`](dev-docs/pkgdown-deploy.md) | Configuring or debugging the pkgdown deploy, editing `_pkgdown.yml`, or enabling Pages on a new repo |
| [`dev-docs/data-source-urls.md`](dev-docs/data-source-urls.md) | A fetcher 404s / returns HTML, a download is empty, or a fetch URL needs updating for a new year |
| [`dev-docs/spr-coverage-gap.md`](dev-docs/spr-coverage-gap.md) | Triaging which redesigned 2024-25 SPR sheets to expose as new fetchers, or scoping SPR coverage work |

## Project Structure - PUBLIC vs PRIVATE

**njschooldata is a PUBLIC, OPEN SOURCE project.** Only general-purpose infrastructure code belongs in the package itself (`R/`, `tests/`, etc.).

| Location | Visibility | Purpose |
|----------|------------|---------|
| `R/`, `tests/`, `man/` | **PUBLIC** | General-purpose functions for fetching/processing NJ school data |

**Guidelines:**
- Code that could benefit any user of NJ school data → goes in `R/`
- Code specific to a particular research question or district → goes in `research-private/`
- Helper functions created during research that are general-purpose → refactor into `R/`
- District-specific constants, analysis scripts, cached data → stay in `research-private/`

## Commit Guidelines
- Do NOT include Claude's name, "Co-Authored-By", or any AI attribution in commit messages
- Keep commit messages concise and focused on the changes made

## Slash Commands
- `/deploy` - Full deployment pipeline: security review, tests, linter, build, deploy
- `/security-review` - Security audit of the package

## Testing
Run tests with: `devtools::test()` or `Rscript -e "devtools::test()"`

**Note:** Tests are disabled in CI/CD due to NJ DOE network dependencies. Run locally before deploying.

## Caching

Two layers, both on by default.

**1. Session cache (in-memory, per parsed sheet)** — avoids re-parsing within a session:
- `njsd_cache_info()` - view cache status
- `njsd_cache_clear()` - clear cache
- `njsd_cache_enable(FALSE)` - disable caching

The cache validates responses and will NOT cache network errors or bot protection pages.

**2. SPR workbook cache (on-disk, per year+level)** — the SPR Excel databases are
large (the 2024-25 District file is ~119 MB, the School file ~350 MB) and hold dozens
of sheets. `fetch_spr_data()`, `fetch_spr_sheet_raw()`, and `list_spr_sheets()` download
each workbook at most once and reuse the cached copy across sheet reads and across
sessions (reading a second sheet from the same workbook drops from ~12s to ~0.1s):
- `njsd_workbook_cache_dir()` - cache location (defaults to `tools::R_user_dir("njschooldata", "cache")`; override with `options(njschooldata.cache_dir=)`)
- `njsd_workbook_cache_info()` - list cached workbooks and sizes
- `njsd_workbook_cache_clear()` / `njsd_workbook_cache_clear(end_year)` - delete cached workbooks
- disable with `options(njschooldata.workbook_cache = FALSE)`

Downloads are validated as real `.xlsx` (ZIP magic bytes) before being cached, so an
HTTP error or bot-protection page is never written to the cache or parsed as data.
SPR workbooks for past years are static snapshots; clear the cache to force a refresh.
