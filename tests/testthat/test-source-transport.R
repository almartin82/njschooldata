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

test_that("only classified transport failures are source outages", {
  url <- "https://www.nj.gov/classified.csv"
  counted <- function(status = 200L, error = NULL) {
    calls <- 0L
    list(
      request = function(url, dest, timeout) {
        calls <<- calls + 1L
        if (!is.null(error)) stop(error)
        list(status_code = status, final_url = url, content_type = "text/plain")
      },
      calls = function() calls
    )
  }
  curl_condition <- function(class) {
    structure(list(message = paste("diagnostic", class), call = NULL),
              class = c(class, "error", "condition"))
  }
  no_sleep <- function(seconds) NULL

  # A curl failure to reach the host is retried and is a source outage.
  outage <- counted(error = curl_condition("curl_error_couldnt_connect"))
  result <- download_source(url, "csv", request_fn = outage$request,
                            retries = 1L, sleep_fn = no_sleep)
  expect_identical(result$source_status, "source_unavailable")
  expect_identical(outage$calls(), 2L)

  # A status we caused (403 for a header we sent, 400, 501) is loud, not retried.
  for (status in c(400L, 403L, 425L, 501L)) {
    refused <- counted(status = status)
    expect_error(download_source(url, "csv", request_fn = refused$request,
                                 retries = 2L, sleep_fn = no_sleep),
                 class = paste0("http_", status))
    expect_identical(refused$calls(), 1L)
  }

  # Kept until the fleet rules: 404/410 stay source outages without a retry,
  # TLS certificate verification failure stays a retried source outage.
  for (status in c(404L, 410L)) {
    gone <- counted(status = status)
    result <- download_source(url, "csv", request_fn = gone$request,
                              retries = 2L, sleep_fn = no_sleep)
    expect_identical(result$source_status, "source_unavailable")
    expect_identical(gone$calls(), 1L)
  }
  tls <- counted(error = curl_condition("curl_error_peer_failed_verification"))
  result <- download_source(url, "csv", request_fn = tls$request,
                            retries = 1L, sleep_fn = no_sleep)
  expect_identical(result$source_status, "source_unavailable")
  expect_identical(tls$calls(), 2L)
})

test_that("HTML masquerading as XLSX and corrupt archives are source failures (M4, Q4)", {
  # Bytes that are not the file, checked as bytes before any parser runs, are
  # a source failure (droppable under allow_partial). They used to be
  # parse_error, which is now reserved for our parser failing on good bytes.
  html <- download_source(
    "https://www.nj.gov/error.xlsx",
    source_type = "xlsx",
    request_fn = make_transport_request(
      content_type = "text/html",
      writer = function(path) writeLines("<html><body>blocked</body></html>", path)
    ),
    retries = 0L
  )
  expect_identical(html$source_status, "source_unavailable")
  expect_match(html$error, "HTML|content type")

  corrupt <- download_source(
    "https://www.nj.gov/truncated.zip",
    source_type = "zip",
    request_fn = make_transport_request(
      writer = function(path) writeBin(as.raw(c(0x50, 0x4b, 0x03)), path)
    ),
    retries = 0L
  )
  expect_identical(corrupt$source_status, "source_unavailable")
  expect_match(corrupt$error, "corrupt|truncated|ZIP")
})

test_that("live downloads are per-call and carry independently acquired provenance", {
  calls <- 0L
  request <- function(url, dest, timeout) {
    calls <<- calls + 1L
    write_minimal_zip(dest)
    list(status_code = 200L, final_url = url, content_type = "application/zip")
  }
  first <- download_source("https://www.nj.gov/cache.zip", "zip", request_fn = request)
  second <- download_source("https://www.nj.gov/cache.zip", "zip", request_fn = request)
  withr::defer({.release_source_result(first); .release_source_result(second)})
  expect_identical(calls, 2L)
  expect_false(identical(first$data, second$data))
  expect_identical(first$ownership, "temporary")
  expect_identical(second$ownership, "temporary")
  expect_identical(first$digest, .source_digest(first$data))
  expect_identical(second$digest, .source_digest(second$data))
  expect_false(file.exists(paste0(first$data, ".source.rds")))
  .release_source_result(first)
  expect_false(file.exists(first$data))
  expect_true(file.exists(second$data))
})

test_that("the shared transport identifies as a browser, not as njschooldata", {
  # NJ DOE's Homeroom directory downloads answer a self-identifying agent with
  # HTTP 403 and a 963-byte challenge page. get_school_directory() and
  # get_district_directory() therefore stopped on every call and reported the
  # refusal as `source_unavailable`, blaming NJ DOE for our own header.
  agent <- .source_user_agent()

  expect_true(is.character(agent) && length(agent) == 1L && nzchar(agent))
  expect_match(agent, "^Mozilla/5\\.0 ")
  expect_false(grepl("njschooldata", agent, fixed = TRUE))

  default_agent <- eval(formals(.default_source_request)$user_agent)
  expect_identical(default_agent, agent)
})
