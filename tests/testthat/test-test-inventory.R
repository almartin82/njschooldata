test_that("network-bearing R tests are explicitly gated", {
  test_dir <- testthat::test_path()
  files <- list.files(test_dir, pattern = "^test.*[.]R$", full.names = TRUE)
  offline_contracts <- c(
    "test-finance-source-results.R",
    # Argument validation fails before transport is reached.
    "test-absence-offline-contract.R",
    "test-source-adapter-fixtures.R",
    "test-source-registry.R",
    "test-source-result.R",
    "test-source-transport.R",
    "test-site-render-security.R",
    # The site fetcher is replaced with an in-memory contract stub.
    "test-site-build-contract.R",
    # Byte-identical conformance suite reads only a committed RDS fixture.
    "test-directory-contract.R",
    "test-tges-url.R"
  )
  network_pattern <- paste(
    c(
      "https?://", "httr::(GET|HEAD)", "download[.]file",
      "downloader::download", "\\bfetch_[[:alnum:]_.]+[[:space:]]*[(]",
      "\\bget_raw_[[:alnum:]_.]+[[:space:]]*[(]",
      "\\bstandard_assess[[:space:]]*[(]"
    ),
    collapse = "|"
  )

  offenders <- vapply(files, function(path) {
    lines <- readLines(path, warn = FALSE)
    lines <- lines[!grepl("^[[:space:]]*#", lines)]
    bears_network <- any(grepl(network_pattern, lines, perl = TRUE))
    gated <- startsWith(basename(path), "test-live-") ||
      any(grepl("skip_if_no_live_tests[(]", lines, fixed = FALSE)) ||
      basename(path) %in% c(offline_contracts, "test-test-inventory.R")
    bears_network && !gated
  }, logical(1))

  expect_length(basename(files[offenders]), 0)
})
