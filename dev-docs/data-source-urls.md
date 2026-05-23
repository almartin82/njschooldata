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
