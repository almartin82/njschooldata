# Keep real package-owned source paths, but fail closed if they ever fall
# through to a transport.  The independent CI network boundary is still needed.
local_nj_offline_transport <- function(.local_envir = parent.frame()) {
  deny <- function(...) stop("Unexpected network transport in retained-source test", call. = FALSE)
  testthat::local_mocked_bindings(.default_source_request = deny,
    .package = "njschooldata", .env = .local_envir)
  testthat::local_mocked_bindings(download = deny,
    .package = "downloader", .env = .local_envir)
  testthat::local_mocked_bindings(GET = deny, HEAD = deny,
    .package = "httr", .env = .local_envir)
  testthat::local_mocked_bindings(download.file = deny,
    .package = "utils", .env = .local_envir)
  testthat::local_mocked_bindings(curl_download = deny, curl_fetch_memory = deny,
    curl_fetch_disk = deny, curl_fetch_stream = deny, curl = deny, multi_run = deny,
    .package = "curl", .env = .local_envir)
  original_url <- base::url
  safe_url <- function(description, ...) {
    if (is.character(description) && length(description) == 1L &&
        grepl("^(https?|ftp)://", description, ignore.case = TRUE)) deny()
    original_url(description, ...)
  }
  testthat::local_mocked_bindings(url = safe_url, socketConnection = deny,
    .package = "base", .env = .local_envir)
  invisible(NULL)
}
