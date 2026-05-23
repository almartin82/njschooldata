# Reference: Vignette Authoring (Charts & Cache)

> **Load this when:** editing any vignette `.Rmd`, regenerating or restyling
> charts, refreshing a vignette for a new data year, or debugging
> stale/missing charts on the pkgdown site or README.

## Committed Figures Are the Source of Truth (REQUIRED)

**Vignette figures are pre-rendered and committed to git. Editing a vignette's
`.Rmd` does NOT update the published charts — you MUST regenerate and commit the
figure PNGs.**

- Rendered figures live in `vignettes/<vignette>_files/figure-html/*.png` and are
  **tracked in git**. The pkgdown build serves these committed binaries; it does
  not reliably re-knit them on every run.
- The README/home page chart images point at the deployed copies
  (`https://almartin82.github.io/njschooldata/articles/<vignette>_files/figure-html/<chunk>-1.png`),
  which come from those same committed PNGs.

**Workflow to update any chart (data refresh, new year, restyle):**
1. Edit the vignette code/prose.
2. Re-render locally: `rmarkdown::render("vignettes/<vignette>.Rmd")`.
3. **Copy the regenerated `figure-html/*.png` over the committed ones and
   `git add` them.** This step is the one that actually moves the published chart.
4. Visually open the regenerated PNG and confirm it shows the new data before
   committing — do not trust a green pkgdown build; the build can succeed while
   serving stale committed figures.

**Incident (2026-05, 2026 enrollment integration):** the vignette prose and data
tables were updated to 2026 and merged, and pkgdown deployed green three times,
but the live charts kept showing the old 2020-2025 series. Root cause: the
committed `statewide-enrollment-1.png` (and 14 others) were never replaced, and
the build served them byte-for-byte. The fix was committing the freshly rendered
2026 PNGs. Two earlier attempts (changing `.Rmd` text, then `cache = FALSE`)
failed because neither touched the committed figure binaries.

## knitr Cache Discipline (REQUIRED)

- Default the vignette chunk cache to **`cache = FALSE`** in the setup chunk.
- Enable `cache = TRUE` **only** on the expensive data-fetch chunk (e.g.
  `{r fetch-data, cache = TRUE}`), never on plot chunks.
- Do **not** commit `vignettes/<vignette>_cache/` directories. Cached plot chunks
  replay stale figures across build environments (the caschooldata 2026-03
  incident); keeping plots un-cached forces a fresh render every time.
