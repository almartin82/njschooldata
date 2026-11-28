# njschooldata Instructions

Follow [../AGENTS.md](../AGENTS.md) for shared state-schooldata instructions.

<!-- data-storage-rules:start -->
## Where the data lives (REQUIRED)

- **Source files are held once, as published.** A state DOE download or a records-request file
  is stored byte for byte with its sha256 and byte length. Never recompress, re-save or trim it.
- **Home for source files: the package's Pages store.** Files are published under
  `historical-assets/<digest>` on the package's Pages site, fetched on first use, verified against
  the manifest, and kept in the shared local store. A missing or mismatched file stops. It never
  falls through to a live DOE download.
- **Too big for Pages: a release asset on the package repo.** Same manifest, same verification.
- **`inst/extdata/` holds only** manifests, the NCES id crosswalk, registry files, small test
  fixtures, and source files that have not been moved yet. Do not add new large files there.
- **Records-request files are public.** A file obtained under OPRA or another public-records law
  may go to Pages like any DOE release.
- **Client-supplied data never enters a package.** Not in `inst/`, not on Pages, not in a release
  asset on a package repo, not in a test fixture.
- **Processed results never go in git.** They live in the shared processed store and are rebuilt
  from source.
- **Vignette caches are not committed.** `vignettes/*_cache/` is gitignored. The `.Rmd` files and
  the rendered `docs/` stay committed. Keep data-fetch chunks and plot chunks separate.
- **Directory data is live.** Never cached, never bundled, never served from a retained file.
<!-- data-storage-rules:end -->

## Data and Plot Caching

Set global knitr `cache = FALSE`. Keep data fetching and plotting in separate
chunks: data-fetching chunks use `cache = TRUE`; plot chunks use `cache = FALSE`
(or inherit the global default). Never put data fetching and ggplot code in the
same cached chunk.
