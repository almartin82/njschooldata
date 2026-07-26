make_transport_request <- function(status = 200L, final_url = NULL,
                                   content_type = "application/octet-stream",
                                   writer = NULL, error = NULL) {
  force(status); force(final_url); force(content_type); force(writer); force(error)
  function(url, dest, timeout) {
    if (!is.null(error)) stop(error)
    if (!is.null(writer)) writer(dest)
    list(
      status_code = status,
      final_url = final_url %||% url,
      content_type = content_type
    )
  }
}

write_minimal_zip <- function(path) {
  work <- tempfile("zip-source-")
  dir.create(work)
  on.exit(unlink(work, recursive = TRUE), add = TRUE)
  writeLines("adapter boundary", file.path(work, "source.txt"))
  zip::zipr(path, "source.txt", root = work)
}

test_that("download adapter validates a ZIP and records provenance", {
  result <- download_source(
    "https://www.nj.gov/example.zip",
    source_type = "zip",
    request_fn = make_transport_request(writer = write_minimal_zip),
    retries = 0L
  )
  on.exit(unlink(result$data), add = TRUE)

  expect_identical(result$source_status, "actual")
  expect_true(file.exists(result$data))
  expect_match(result$digest, "^[0-9a-f]{64}$")
  expect_s3_class(result$retrieved_at, "POSIXct")
})

test_that("download adapter rejects disallowed hosts and unsafe redirects", {
  disallowed <- download_source(
    "https://example.com/data.csv",
    source_type = "csv",
    request_fn = make_transport_request()
  )
  expect_identical(disallowed$source_status, "source_unavailable")
  expect_match(disallowed$error, "allowlist")

  redirected <- download_source(
    "https://www.nj.gov/data.csv",
    source_type = "csv",
    request_fn = make_transport_request(
      final_url = "https://example.com/stolen.csv",
      content_type = "text/csv",
      writer = function(path) writeLines("header", path)
    ),
    retries = 0L
  )
  expect_identical(redirected$source_status, "source_unavailable")
  expect_match(redirected$error, "redirect")
})

test_that("archive member validation rejects traversal paths", {
  expect_error(
    .validate_archive_members(c("data/file.csv", "../outside.csv")),
    "unsafe"
  )
  expect_error(.validate_archive_members("C:/outside.csv"), "unsafe")
  expect_silent(.validate_archive_members(c("data/file.csv", "nested/")))
})

test_that("HTTP failures and retry exhaustion are source outages", {
  attempts <- 0L
  request <- function(url, dest, timeout) {
    attempts <<- attempts + 1L
    list(status_code = 503L, final_url = url, content_type = "text/plain")
  }
  result <- download_source(
    "https://www.nj.gov/unavailable.csv",
    source_type = "csv",
    request_fn = request,
    retries = 2L,
    sleep_fn = function(seconds) NULL
  )

  expect_identical(attempts, 3L)
  expect_identical(result$source_status, "source_unavailable")
  expect_match(result$error, "HTTP 503")
})

test_that("HTML masquerading as XLSX and corrupt archives are parse errors", {
  html <- download_source(
    "https://www.nj.gov/error.xlsx",
    source_type = "xlsx",
    request_fn = make_transport_request(
      content_type = "text/html",
      writer = function(path) writeLines("<html><body>blocked</body></html>", path)
    ),
    retries = 0L
  )
  expect_identical(html$source_status, "parse_error")
  expect_match(html$error, "HTML|content type")

  corrupt <- download_source(
    "https://www.nj.gov/truncated.zip",
    source_type = "zip",
    request_fn = make_transport_request(
      writer = function(path) writeBin(as.raw(c(0x50, 0x4b, 0x03)), path)
    ),
    retries = 0L
  )
  expect_identical(corrupt$source_status, "parse_error")
  expect_match(corrupt$error, "corrupt|truncated|ZIP")
})

test_that("validated cache artifacts are reused atomically", {
  cache <- tempfile(fileext = ".zip")
  calls <- 0L
  request <- function(url, dest, timeout) {
    calls <<- calls + 1L
    write_minimal_zip(dest)
    list(status_code = 200L, final_url = url,
         content_type = "application/zip")
  }

  first <- download_source(
    "https://www.nj.gov/cache.zip", "zip",
    cache_path = cache, request_fn = request, retries = 0L
  )
  second <- download_source(
    "https://www.nj.gov/cache.zip", "zip",
    cache_path = cache, request_fn = request, retries = 0L
  )
  on.exit(unlink(cache), add = TRUE)

  expect_identical(calls, 1L)
  expect_identical(first$digest, second$digest)
  expect_match(second$warning, "cache", ignore.case = TRUE)
})
