retained_source_blocks_are_guarded <- function(text) {
  expressions <- tryCatch(parse(text = text, keep.source = FALSE), error = function(e) NULL)
  if (is.null(expressions)) return(FALSE)
  is_test <- function(x) is.call(x) && identical(x[[1L]], as.name("test_that"))
  tests <- Filter(is_test, as.list(expressions))
  if (!length(tests)) return(FALSE)
  first_call <- function(test) {
    if (length(test) < 3L || !is.call(test[[3L]]) ||
        !identical(test[[3L]][[1L]], as.name("{")) || length(test[[3L]]) < 2L) return(NULL)
    test[[3L]][[2L]]
  }
  guarded <- vapply(tests, function(test) {
    first <- first_call(test)
    if (!is.call(first)) return(FALSE)
    if (identical(first[[1L]], as.name("local_nj_offline_transport")) && length(first) == 1L) return(TRUE)
    identical(first, quote(testthat::skip_if_not(live_tests_enabled(), "Explicit live-source opt-in required")))
  }, logical(1))
  if (!all(guarded)) return(FALSE)
  # Sourcing the file may evaluate only simple, non-transporting construction.
  # Reject unknown calls, including indirect helper calls, rather than assuming
  # an unrecognized helper cannot reach a source before its test guard runs.
  # Function bodies and test blocks are deferred and are not evaluated here.
  dangerous <- function(x) {
    if (!is.call(x)) return(FALSE)
    if (identical(x[[1L]], as.name("function")) || is_test(x)) return(FALSE)
    head <- paste(deparse(x[[1L]]), collapse = "")
    safe <- c("{", "(", "<-", "=", ":", "c", "list", "local")
    if (!head %in% safe) return(TRUE)
    # A file cannot replace one of these constructors with a network helper
    # and then call it while still looking syntactically harmless.
    protected <- c(safe, "local_nj_offline_transport", "live_tests_enabled", "test_that")
    if (head %in% c("<-", "=") && length(x) >= 2L &&
        is.symbol(x[[2L]]) && as.character(x[[2L]]) %in% protected) return(TRUE)
    any(vapply(as.list(x)[-1L], dangerous, logical(1)))
  }
  !any(vapply(as.list(expressions), dangerous, logical(1)))
}

test_that("network-bearing R tests are explicitly gated", {
  test_dir <- testthat::test_path()
  files <- list.files(test_dir, pattern = "^test.*[.]R$", full.names = TRUE)
  offline_contracts <- c(
    # Complete package source files; the transport function throws if reached.
    "test-program-contract.R",
    "test-finance-source-results.R",
    # Argument validation fails before transport is reached.
    "test-absence-offline-contract.R",
    "test-source-adapter-fixtures.R",
    # get_raw_sla_result() gets an injected request_fn that copies a
    # checked-in fixture; no transport is reached.
    "test-shipped-fixture-values.R",
    "test-source-registry.R",
    "test-source-result.R",
    "test-source-transport.R",
    "test-site-render-security.R",
    # The site fetcher is replaced with an in-memory contract stub.
    "test-site-build-contract.R",
    # Byte-identical conformance suite reads only a committed RDS fixture.
    "test-directory-contract.R",
    # Homeroom byte fixtures and mocked acquisition; no live requests.
    "test-directory-source-fidelity.R",
    # Both acquisition functions receive fixture-copy request_fn callbacks;
    # fetch_directory() also receives the mocked Homeroom source results.
    "test-directory-source-provenance.R",
    # Source transport, enrollment, and SPR calls inject request/read fixtures;
    # the URLs in this file are examples or inputs to mocked requests.
    "test-audit-round-a.R",
    # fetch_dfg() and fetch_spr_data() are replaced with in-memory fixtures via
    # local_mocked_bindings(); the assertions pin literals that the real
    # downloads could not produce, so a mock that failed to take effect fails
    # the test rather than silently reaching the network.
    "test-id-preservation.R",
    "test-tges-url.R",
    # Release-asset delivery: every transfer is an injected transport or an
    # offline read of a seeded store; the URLs are manifest lookup keys.
    "test-release-sources.R"
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
      retained_source_blocks_are_guarded(lines) ||
      basename(path) %in% c(offline_contracts, "test-test-inventory.R")
    bears_network && !gated
  }, logical(1))

  expect_length(basename(files[offenders]), 0)
})

test_that("retained-source guard classification requires an executable guard in every block", {
  guard <- 'local_nj_offline_transport()'
  expect_true(retained_source_blocks_are_guarded(paste0('test_that("x", {', guard, '; fetch_enr(2025)})')))
  expect_false(retained_source_blocks_are_guarded(paste0('test_that("x", {', guard, '; fetch_enr(2025)}); test_that("y", {fetch_enr(2026)})')))
  expect_false(retained_source_blocks_are_guarded(paste0('fetch_enr(2025); test_that("x", {', guard, '})')))
  expect_false(retained_source_blocks_are_guarded(paste0('load_source <- function() fetch_enr(2025); load_source(); test_that("x", {', guard, '})')))
  expect_false(retained_source_blocks_are_guarded(paste0('c <- fetch_enr; c(2025); test_that("x", {', guard, '})')))
  expect_false(retained_source_blocks_are_guarded(paste0('local_nj_offline_transport <- function() NULL; test_that("x", {', guard, '; fetch_enr(2025)})')))
  expect_false(retained_source_blocks_are_guarded('test_that("x", {if (FALSE) local_nj_offline_transport(); fetch_enr(2025)})'))
})

test_that("retained-source transport guard fails closed", {
  local_nj_offline_transport()
  expect_error(njschooldata:::.default_source_request("https://www.nj.gov/", tempfile(), 1),
               "Unexpected network transport")
  expect_error(downloader::download("https://www.nj.gov/", tempfile()), "Unexpected network transport")
  expect_error(httr::GET("https://www.nj.gov/"), "Unexpected network transport")
  expect_error(utils::download.file("https://www.nj.gov/", tempfile()), "Unexpected network transport")
  expect_error(curl::curl_fetch_memory("https://www.nj.gov/"), "Unexpected network transport")
  expect_error(curl::curl_fetch_stream("https://www.nj.gov/", identity), "Unexpected network transport")
  expect_error(curl::curl("https://www.nj.gov/"), "Unexpected network transport")
  expect_error(curl::curl_download("https://www.nj.gov/", tempfile()), "Unexpected network transport")
  expect_error(curl::multi_run(), "Unexpected network transport")
  expect_error(base::url("https://www.nj.gov/"), "Unexpected network transport")
  expect_error(base::socketConnection("www.nj.gov", 443), "Unexpected network transport")
})
