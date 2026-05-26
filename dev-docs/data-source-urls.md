# Reference: Data Source URLs Move Without Notice

> **Load this when:** a fetcher returns a 404 / HTML error page instead of data,
> a download is empty, or you need to update a fetch URL for a new data year.

NJ DOE relocates and renames files frequently; the actual fetch URLs are built
inside the fetch functions (not always `config_urls.R`). Two cases handled in
code, kept here as a reminder to expect more:

- **Enrollment** (`get_raw_enr`): the 2025-26 file shipped as `Enrollment_2526.zip`
  (capital E) vs the historical lowercase `enrollment_*.zip`; the fetcher tries
  both capitalizations.
- **Graduation** (`get_raw_grad_file`): in 2026 the entire
  `/schoolperformance/grad/` tree was retired and files moved to
  `/spr/adddata/doc/acgrdocs/`. `fetch_postsecondary()` points at the old tree and
  its file did not move there — its new location is still unknown (open follow-up).
- **TGES / Comparative Spending Guide** (`tges_url_for_year`): the old
  `state.nj.us/education/guide/{year}/*.zip` URLs all 404. Files now live under
  `nj.gov/education/guide/docs/`: `{year}_CSG.zip` for 2001-2010, `{year}_TGES.zip`
  for 2011-2023, and a per-year subfolder bundle `{year}/TGES{nn}_Zipped.zip` for
  2024+. 1999/2000 are linked on the NJ index page but 404 at the source. The
  download zips wrap members in a per-year subfolder (`2011_TGES/CSG1.CSV`), so the
  parser keys off the bare file name.
- **State Aid** (`get_raw_state_aid`, `R/state_aid.R`): per-district K-12 aid by
  category, under `nj.gov/education/stateaid/`. Two access paths, tried in order:
  the current year is a direct workbook `{code}/FY{yy}_GBM_District_Details.xlsx`
  (where `code` is the two-year span, e.g. FY26 = "2526"); prior years are bundled
  in `zippedfiles/{code}.zip`. The district-details member name drifts across
  years ("FY25 GBM District Details Rev.xlsx", "District Details FY20 Revised.xlsx",
  "district.xlsx"), so the parser locates it by a fuzzy name match and detects the
  header row (first row carrying both "County" and "Dist"; usually row 5). Aid
  category labels also drift and are normalized in `normalize_state_aid_category()`.
  Supported 2019+; FY2016 and earlier use a layout the parser does not handle, and
  FY2010 has no per-district workbook at all.
