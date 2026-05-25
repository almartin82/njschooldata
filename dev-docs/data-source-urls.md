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
