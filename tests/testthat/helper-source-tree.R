package_source_root <- function() {
  test_root <- normalizePath(
    testthat::test_path("..", ".."), mustWork = TRUE
  )
  candidates <- c(
    test_root,
    file.path(test_root, "00_pkg_src", "njschooldata")
  )
  matches <- candidates[vapply(candidates, function(path) {
    description <- file.path(path, "DESCRIPTION")
    file.exists(description) &&
      any(grepl("^Package: njschooldata$", readLines(description, warn = FALSE)))
  }, logical(1))]
  if (!length(matches)) {
    stop("Could not locate the njschooldata package source tree.", call. = FALSE)
  }
  normalizePath(matches[[1]], mustWork = TRUE)
}

package_source_path <- function(...) {
  file.path(package_source_root(), ...)
}

source_adapter_fixture <- function(name) {
  installed <- system.file(
    "extdata", "test-fixtures", "source-adapters", name,
    package = "njschooldata"
  )
  path <- if (nzchar(installed)) installed else package_source_path(
    "inst", "extdata", "test-fixtures", "source-adapters", name
  )
  provenance_path <- if (nzchar(installed)) {
    file.path(dirname(path), "provenance.json")
  } else {
    package_source_path(
      "inst", "extdata", "test-fixtures", "source-adapters", "provenance.json"
    )
  }
  if (!file.exists(path) || !file.exists(provenance_path)) {
    stop("Missing source-adapter fixture or provenance: ", name, call. = FALSE)
  }

  provenance <- jsonlite::read_json(provenance_path, simplifyVector = FALSE)
  records <- Filter(function(record) identical(record$fixture, name), provenance)
  if (length(records) != 1L) {
    stop("Source-adapter fixture has no unique provenance record: ", name,
         call. = FALSE)
  }
  actual_digest <- digest::digest(file = path, algo = "sha256", serialize = FALSE)
  if (!identical(actual_digest, records[[1L]]$fixture_sha256)) {
    stop("Source-adapter fixture SHA-256 mismatch: ", name, call. = FALSE)
  }
  path
}
