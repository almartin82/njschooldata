# Canonical tests for the vendored live transport classifier (R/transport.R).
# Vendored byte-for-byte as tests/testthat/test-transport-canonical.R; edit ONLY
# contracts/transport/v1/test-transport-canonical.R, then run scripts/transport/sync.py.
# No network: every response below is a payload-free control object.

transport_test_response <- function(status) {
  structure(list(status_code = as.integer(status), url = "control://no-network",
                 headers = list(), all_headers = list(), content = raw()),
            class = "response")
}

transport_test_catch <- function(expr) tryCatch(expr, error = identity)

test_that("each curl transport failure becomes the prefixed acquisition error", {
  # Listed here by hand, not read from transport_curl_classes, so dropping a
  # class from the classifier fails this test.
  for (cls in c("curl_error_couldnt_resolve_proxy", "curl_error_couldnt_resolve_host",
                "curl_error_couldnt_connect", "curl_error_operation_timedout",
                "curl_error_send_error", "curl_error_recv_error",
                "curl_error_got_nothing", "curl_error_partial_file",
                "curl_error_ssl_connect_error")) {
    original <- errorCondition("diagnostic transport failure",
                               class = c(cls, "curl_error"))
    caught <- transport_test_catch(transport_classify(stop(original), "testpkg"))
    expect_s3_class(caught, "testpkg_acquisition_error")
    expect_s3_class(caught, "transport_acquisition_error")
    expect_s3_class(caught, cls)
    expect_identical(caught$parent, original)
    expect_identical(conditionMessage(caught), conditionMessage(original))
    expect_true(transport_is_acquisition_error(caught, "testpkg"))
    expect_false(transport_is_acquisition_error(caught, "otherpkg"))
  }
})

test_that("local, programmer and TLS-verification errors are re-raised untouched", {
  for (cls in c("simpleError", "curl_error", "curl_error_write_error",
                "curl_error_read_error", "curl_error_aborted_by_callback",
                "curl_error_failed_init", "curl_error_url_malformat",
                "curl_error_unsupported_protocol",
                "curl_error_peer_failed_verification")) {
    original <- errorCondition("local/programmer diagnostic", class = cls)
    caught <- transport_test_catch(transport_classify(stop(original), "testpkg"))
    expect_identical(caught, original)
    expect_false(transport_is_acquisition_error(caught, "testpkg"))
  }
  expect_identical(transport_classify(41L + 1L, "testpkg"), 42L)
})

test_that("classified statuses raise the acquisition error over httr's own condition", {
  for (status in c(408L, 429L, 500L, 502L, 503L, 504L)) {
    caught <- transport_test_catch(
      transport_stop_for_status(transport_test_response(status), "testpkg"))
    expect_s3_class(caught, "testpkg_acquisition_error")
    expect_s3_class(caught, paste0("http_", status))
    expect_s3_class(caught$parent, paste0("http_", status))
    expect_identical(caught$status, status)
    expect_identical(conditionMessage(caught), conditionMessage(caught$parent))
    expect_true(transport_is_acquisition_error(caught, "testpkg"))
  }
})

test_that("every other error status, our own request's included, stays fatal", {
  for (status in c(400L, 401L, 403L, 404L, 405L, 410L, 422L, 501L, 505L)) {
    caught <- transport_test_catch(
      transport_stop_for_status(transport_test_response(status), "testpkg"))
    expect_s3_class(caught, paste0("http_", status))
    expect_false(inherits(caught, "transport_acquisition_error"))
    expect_false(transport_is_acquisition_error(caught, "testpkg"))
    expect_null(caught$parent)
  }
  for (status in c(200L, 204L, 301L)) {
    response <- transport_test_response(status)
    expect_identical(transport_stop_for_status(response, "testpkg"), response)
  }
})

test_that("a caller's message is kept on both the classified and the fatal branch", {
  caught <- transport_test_catch(transport_stop_for_status(
    transport_test_response(503L), "testpkg", message = "diagnostic HTTP 503",
    class = "testpkg_legacy_class"))
  expect_s3_class(caught, "testpkg_acquisition_error")
  expect_s3_class(caught, "testpkg_legacy_class")
  expect_s3_class(caught, "http_503")
  expect_s3_class(caught, "http_500")
  expect_identical(conditionMessage(caught), "diagnostic HTTP 503")
  expect_identical(caught$status, 503L)
  fatal <- transport_test_catch(transport_stop_for_status(
    transport_test_response(404L), "testpkg", message = "diagnostic HTTP 404",
    class = "testpkg_legacy_class"))
  expect_s3_class(fatal, "http_404")
  expect_s3_class(fatal, "http_400")
  expect_false(inherits(fatal, "testpkg_legacy_class"))
  expect_false(transport_is_acquisition_error(fatal, "testpkg"))
  expect_identical(conditionMessage(fatal), "diagnostic HTTP 404")
})

test_that("an error that is not httr's status condition is never relabelled", {
  programmer <- simpleError("503 words do not make an HTTP status failure")
  testthat::local_mocked_bindings(stop_for_status = function(...) stop(programmer),
                                  .package = "httr")
  caught <- transport_test_catch(
    transport_stop_for_status(transport_test_response(503L), "testpkg"))
  expect_identical(caught, programmer)
})

test_that("a small HTML page where a file was expected is a source failure", {
  page <- tempfile(fileext = ".csv")
  on.exit(unlink(page), add = TRUE)
  writeBin(c(as.raw(c(239L, 187L, 191L)),
             charToRaw("\n  <!DOCTYPE html><html><body>Request blocked</body></html>")),
           page)
  caught <- transport_test_catch(transport_check_error_page(page, "testpkg",
                                                            url = "control://x"))
  expect_s3_class(caught, "testpkg_acquisition_error")
  expect_s3_class(caught, "transport_error_page")
  expect_true(transport_is_acquisition_error(caught, "testpkg"))
  expect_match(conditionMessage(caught), "control://x", fixed = TRUE)
  raw_page <- charToRaw("<html>\n<head><title>503</title></head></html>")
  expect_s3_class(transport_test_catch(transport_check_error_page(raw_page, "testpkg")),
                  "testpkg_acquisition_error")
})

test_that("data bytes, empty bytes and large HTML pass the page check untouched", {
  csv <- tempfile(fileext = ".csv")
  empty <- tempfile(fileext = ".csv")
  big <- tempfile(fileext = ".html")
  on.exit(unlink(c(csv, empty, big)), add = TRUE)
  writeLines(c("district,note", "001,\"<html> in a cell\""), csv)
  file.create(empty)
  writeLines(c("<!DOCTYPE html><html><body>", strrep("x", 300000L), "</body></html>"), big)
  expect_identical(transport_check_error_page(csv, "testpkg"), csv)
  expect_identical(transport_check_error_page(empty, "testpkg"), empty)
  expect_identical(transport_check_error_page(big, "testpkg"), big)
  zip <- as.raw(c(0x50, 0x4b, 0x03, 0x04, 0x14, 0x00))
  expect_identical(transport_check_error_page(zip, "testpkg"), zip)
  expect_false(transport_looks_like_html(tempfile()))
})

test_that("the droppable test looks through purrr's wrapper and nothing else", {
  inner <- transport_condition("testpkg", "diagnostic", status = 503L)
  wrapped <- structure(list(message = "In index: 1.", call = NULL, parent = inner),
                       class = c("purrr_error_indexed", "rlang_error", "error", "condition"))
  expect_true(transport_is_acquisition_error(wrapped, "testpkg"))
  other <- structure(list(message = "wrapped", call = NULL, parent = inner),
                     class = c("rlang_error", "error", "condition"))
  expect_false(transport_is_acquisition_error(other, "testpkg"))
  expect_false(transport_is_acquisition_error(simpleError("HTTP 503"), "testpkg"))
})

test_that("a missing or malformed prefix is refused", {
  for (prefix in list(NULL, NA_character_, "", c("a", "b"), "1pkg", "bad prefix")) {
    expect_error(transport_condition(prefix, "x"), "prefix")
  }
  expect_error(transport_classify(1, ""), "prefix")
})
