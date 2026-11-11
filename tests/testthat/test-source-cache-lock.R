# Retired persistent source locks must not be replaced by another live store.
test_that("per-call downloads remove failed and released payloads without sidecars", {
  paths <- character()
  request <- function(url, dest, timeout) {
    paths <<- c(paths, dest)
    writeLines("partial download", dest)
    list(status_code = 503L, final_url = url, content_type = "text/plain")
  }
  result <- download_source("https://www.nj.gov/failure.csv", "csv",
                            request_fn = request, retries = 1L, sleep_fn = function(s) NULL)
  expect_identical(result$source_status, "source_unavailable")
  expect_length(paths, 2L)
  expect_false(any(file.exists(paths)))
  expect_false(any(file.exists(paste0(paths, ".source.rds"))))

  request <- function(url, dest, timeout) {
    paths <<- c(paths, dest)
    writeLines("publisher header", dest)
    list(status_code = 200L, final_url = url, content_type = "text/csv")
  }
  good <- download_source("https://www.nj.gov/file.csv", "csv", request_fn = request)
  expect_true(file.exists(good$data))
  expect_identical(good$ownership, "temporary")
  expect_identical(dirname(good$data), tempdir())
  .release_source_result(good)
  .release_source_result(good)
  expect_false(file.exists(good$data))
})

test_that("unexpected transport errors clean partial files and propagate", {
  path <- NULL
  request <- function(url, dest, timeout) {
    path <<- dest
    writeLines("partial source", dest)
    stop("diagnostic transport defect")
  }
  expect_error(download_source("https://www.nj.gov/file.csv", "csv", request_fn = request),
               "diagnostic transport defect")
  expect_false(file.exists(path))
  expect_false(file.exists(paste0(path, ".source.rds")))
})
