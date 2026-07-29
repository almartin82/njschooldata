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
  if (nzchar(installed)) installed else package_source_path(
    "inst", "extdata", "test-fixtures", "source-adapters", name
  )
}
