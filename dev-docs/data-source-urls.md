# Reference: Data Source URLs Move Without Notice

> **Load this when:** a fetcher returns a 404 / HTML error page instead of data,
> a download is empty, or you need to update a fetch URL for a new data year.

NJ DOE relocates and renames files frequently. `R/source_registry.R` is the
authoritative owner of supported years, source types, hosts, and URL resolvers;
fetchers must delegate to it rather than grow independent URL tables. The shared
adapter in `R/source_transport.R` validates registered hosts, redirects, HTTP
status, content type, and file signatures before a parser sees an artifact.
Cases handled in the registry/resolvers include:

- **Enrollment** (`get_raw_enr`): the 2025-26 file shipped as `Enrollment_2526.zip`
  (capital E) vs the historical lowercase `enrollment_*.zip`; the registered
  resolver carries the verified capitalization for each era.
- **Graduation** (`get_raw_grad_file`): in 2026 the entire
  `/schoolperformance/grad/` tree was retired and files moved to
  `/spr/adddata/doc/acgrdocs/`. `fetch_postsecondary()` points at the old tree and
  its file did not move there — its new location is still unknown (open follow-up).
- **TGES / Comparative Spending Guide** (registered TGES resolver): the old
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
- **Historical report cards** (`get_one_rc_database`): verified registry-owned
  workbook URLs cover 2012-2019. NJ DOE removed the 2003-2011 database files;
  those years are explicit `not_published` gaps and are not advertised as tidy
  support. The report-card downloader uses the shared workbook validation and
  records separate school/district provenance for 2017-2019.
- **District Factor Groups** (`fetch_dfg`): the registered HTTPS
  `DFG2000.xlsx` workbook contains both the 1990 and 2000 revision columns. It
  is validated before either revision is parsed for site peer groups.

When a source moves, update its registry resolver and its boundary/fixture tests
together. Do not bypass the adapter with a new direct downloader. See
`dev-docs/source-outage-runbook.md` for interpreting `source_unavailable` versus
`parse_error` and recovering a strict site build.
