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

## Project Structure - PUBLIC vs PRIVATE

**njschooldata is a PUBLIC, OPEN SOURCE project.** Only general-purpose
infrastructure code belongs in the package itself (`R/`, `tests/`,
etc.).

| Location | Visibility | Purpose |
|----|----|----|
| `R/`, `tests/`, `man/` | **PUBLIC** | General-purpose functions for fetching/processing NJ school data |
| `research-private/` | **PRIVATE** | Applied analyses of specific school districts (e.g., Newark MarGrady analysis) |

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

## Valid Filter Values (tidy enrollment via `fetch_enr(tidy = TRUE)`)

### subgroup

`total_enrollment`, `male`, `female`, `white`, `black`, `hispanic`,
`asian`, `native_american`, `pacific_islander`, `multiracial`,
`white_m`, `white_f`, `black_m`, `black_f`, `hispanic_m`, `hispanic_f`,
`asian_m`, `asian_f`, `native_american_m`, `native_american_f`,
`pacific_islander_m`, `pacific_islander_f`, `free_lunch`,
`reduced_lunch`, `free_reduced_lunch`, `lep`, `migrant`

**NOT in tidy enrollment:** `econ_disadv`, `lep_current`,
`special_education` – these live in
[`fetch_sped()`](https://almartin82.github.io/njschooldata/reference/fetch_sped.md)
or report card data, not
[`fetch_enr()`](https://almartin82.github.io/njschooldata/reference/fetch_enr.md)

### grade_level

`PK`, `K` (normalized from KF/KH/KG), `01`-`12`, `TOTAL`

Aggregates from
[`enr_grade_aggs()`](https://almartin82.github.io/njschooldata/reference/enr_grade_aggs.md):
`PK (Any)`, `K (Any)`, `K12`, `K12UG`, `K8`, `HS`

**Common trap:** Raw data uses `KF` for kindergarten, but
[`clean_enr_grade()`](https://almartin82.github.io/njschooldata/reference/clean_enr_grade.md)
normalizes to `K`. Always filter on `K`, never `KF`.

### entity flags

`is_state`, `is_county`, `is_district`, `is_charter`, `is_school`,
`is_subprogram`

## pkgdown / GitHub Pages

Site: <https://almartin82.github.io/njschooldata/>

**Setup:** - GitHub Action (`.github/workflows/pkgdown.yml`) builds on
push to master - Deploys to `gh-pages` branch automatically - `docs/` is
gitignored on master (build artifacts only)

**Configuration:** - `_pkgdown.yml` - site config, reference sections,
articles - All exported functions must be listed in reference sections
(use `matches(".*")` as catch-all) - Vignettes in `vignettes/` appear as
articles

**To enable on a new repo:** 1. Add workflow file and `_pkgdown.yml` 2.
Push to master 3. Enable GitHub Pages via API or Settings:
`bash gh api repos/OWNER/REPO/pages -X POST --input - <<EOF {"build_type": "legacy", "source": {"branch": "gh-pages", "path": "/"}} EOF`

## Vignette Charts: Committed Figures Are the Source of Truth (REQUIRED)

**Vignette figures are pre-rendered and committed to git. Editing a
vignette’s `.Rmd` does NOT update the published charts — you MUST
regenerate and commit the figure PNGs.**

- Rendered figures live in
  `vignettes/<vignette>_files/figure-html/*.png` and are **tracked in
  git**. The pkgdown build serves these committed binaries; it does not
  reliably re-knit them on every run.
- The README/home page chart images point at the deployed copies
  (`https://almartin82.github.io/njschooldata/articles/<vignette>_files/figure-html/<chunk>-1.png`),
  which come from those same committed PNGs.

**Workflow to update any chart (data refresh, new year, restyle):** 1.
Edit the vignette code/prose. 2. Re-render locally:
`rmarkdown::render("vignettes/<vignette>.Rmd")`. 3. **Copy the
regenerated `figure-html/*.png` over the committed ones and `git add`
them.** This step is the one that actually moves the published chart. 4.
Visually open the regenerated PNG and confirm it shows the new data
before committing — do not trust a green pkgdown build; the build can
succeed while serving stale committed figures.

**Incident (2026-05, 2026 enrollment integration):** the vignette prose
and data tables were updated to 2026 and merged, and pkgdown deployed
green three times, but the live charts kept showing the old 2020-2025
series. Root cause: the committed `statewide-enrollment-1.png` (and 14
others) were never replaced, and the build served them byte-for-byte.
The fix was committing the freshly rendered 2026 PNGs. Two earlier
attempts (changing `.Rmd` text, then `cache = FALSE`) failed because
neither touched the committed figure binaries.

## Vignette knitr Cache Discipline (REQUIRED)

- Default the vignette chunk cache to **`cache = FALSE`** in the setup
  chunk.
- Enable `cache = TRUE` **only** on the expensive data-fetch chunk (e.g.
  `{r fetch-data, cache = TRUE}`), never on plot chunks.
- Do **not** commit `vignettes/<vignette>_cache/` directories. Cached
  plot chunks replay stale figures across build environments (the
  caschooldata 2026-03 incident); keeping plots un-cached forces a fresh
  render every time.

## Data Source URLs Move Without Notice

NJ DOE relocates and renames files frequently; the actual fetch URLs are
built inside the fetch functions (not always `config_urls.R`). Two cases
handled in code, kept here as a reminder to expect more: -
**Enrollment** (`get_raw_enr`): the 2025-26 file shipped as
`Enrollment_2526.zip` (capital E) vs the historical lowercase
`enrollment_*.zip`; the fetcher tries both capitalizations. -
**Graduation** (`get_raw_grad_file`): in 2026 the entire
`/schoolperformance/grad/` tree was retired and files moved to
`/spr/adddata/doc/acgrdocs/`.
[`fetch_postsecondary()`](https://almartin82.github.io/njschooldata/reference/fetch_postsecondary.md)
points at the old tree and its file did not move there — its new
location is still unknown (open follow-up).
