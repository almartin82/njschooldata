# New Jersey official source endpoints

The package-owned source registry in `R/source_registry.R` is the authority for
New Jersey Department of Education endpoint families and supported periods.
The source-adapter provenance ledger at
`inst/extdata/test-fixtures/source-adapters/provenance.json` pins the official
NJDOE URL and full-source checksum used for each checked-in parser fixture.

Those fixtures are deliberately small source-derived slices, not complete
upstream artifacts. They remain excluded from shipped coverage.

The manifest now separately declares complete NJDOE enrollment ZIP releases
(2023-2026), district classification workbooks (2023-2025), and public statewide
classification workbooks (2023-2024). These are immutable package sources under
`inst/extdata/program-sources/`, checked by byte length and SHA-256 before use.
Default downloads for those exact URLs read the package bytes. No DOE request is
needed, even with `use_cache = FALSE`. Other source families retain their
existing acquisition behavior. Rebuild explicitly with
`python3 data-raw/build_program_sources.py`; this is never an automatic job.
