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

## Project Structure - PUBLIC vs PRIVATE

**njschooldata is a PUBLIC, OPEN SOURCE project.** Only general-purpose infrastructure code belongs in the package itself (`R/`, `tests/`, etc.).

| Location | Visibility | Purpose |
|----------|------------|---------|
| `R/`, `tests/`, `man/` | **PUBLIC** | General-purpose functions for fetching/processing NJ school data |
| `research-private/` | **PRIVATE** | Applied analyses of specific school districts (e.g., Newark MarGrady analysis) |

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
Session caching is enabled by default to avoid hitting NJ DOE bot protection:
- `njsd_cache_info()` - view cache status
- `njsd_cache_clear()` - clear cache
- `njsd_cache_enable(FALSE)` - disable caching

The cache validates responses and will NOT cache network errors or bot protection pages.

## Valid Filter Values (tidy enrollment via `fetch_enr(tidy = TRUE)`)

### subgroup
`total_enrollment`, `male`, `female`, `white`, `black`, `hispanic`, `asian`, `native_american`, `pacific_islander`, `multiracial`, `white_m`, `white_f`, `black_m`, `black_f`, `hispanic_m`, `hispanic_f`, `asian_m`, `asian_f`, `native_american_m`, `native_american_f`, `pacific_islander_m`, `pacific_islander_f`, `free_lunch`, `reduced_lunch`, `free_reduced_lunch`, `lep`, `migrant`

**NOT in tidy enrollment:** `econ_disadv`, `lep_current`, `special_education` -- these live in `fetch_sped()` or report card data, not `fetch_enr()`

### grade_level
`PK`, `K` (normalized from KF/KH/KG), `01`-`12`, `TOTAL`

Aggregates from `enr_grade_aggs()`: `PK (Any)`, `K (Any)`, `K12`, `K12UG`, `K8`, `HS`

**Common trap:** Raw data uses `KF` for kindergarten, but `clean_enr_grade()` normalizes to `K`. Always filter on `K`, never `KF`.

### entity flags
`is_state`, `is_county`, `is_district`, `is_charter`, `is_school`, `is_subprogram`


## pkgdown / GitHub Pages

Site: https://almartin82.github.io/njschooldata/

**Setup:**
- GitHub Action (`.github/workflows/pkgdown.yml`) builds on push to master
- Deploys to `gh-pages` branch automatically
- `docs/` is gitignored on master (build artifacts only)

**Configuration:**
- `_pkgdown.yml` - site config, reference sections, articles
- All exported functions must be listed in reference sections (use `matches(".*")` as catch-all)
- Vignettes in `vignettes/` appear as articles

**To enable on a new repo:**
1. Add workflow file and `_pkgdown.yml`
2. Push to master
3. Enable GitHub Pages via API or Settings:
   ```bash
   gh api repos/OWNER/REPO/pages -X POST --input - <<EOF
   {"build_type": "legacy", "source": {"branch": "gh-pages", "path": "/"}}
   EOF
   ```
