# Synthetic identifiers and point geometry only; exercise the real HTTP seam.
nj_arcgis_http <- function(change = identity, .env = parent.frame()) {
  calls <- list()
  count_calls <- 0L
  get <- function(url, query, ...) {
    calls[[length(calls) + 1L]] <<- list(url = url, query = query, config = list(...))
    body <- if (!grepl("/query$", url)) {
      list(objectIdField = "fid", maxRecordCount = 2L)
    } else if (identical(query$returnCountOnly, "true")) {
      count_calls <<- count_calls + 1L
      list(count = 3L)
    } else {
      ids <- if (query$resultOffset == 0) c(11L, 12L) else 13L
      list(features = lapply(ids, function(id) list(
        attributes = list(fid = id, OGIS_ID = paste0("synthetic-", id),
                          COUNTYCODE = "00", DIST_CODE = "0000", SCHOOLCODE = "000"),
        geometry = list(x = id, y = -id))))
    }
    body <- change(list(body = body, query = query, url = url, count_calls = count_calls))
    structure(list(status_code = 200L, headers = list(`content-type` = "application/json"),
      content = charToRaw(jsonlite::toJSON(body, auto_unbox = TRUE)), url = url), class = "response")
  }
  testthat::local_mocked_bindings(GET = get, .package = "httr", .env = .env)
  function() calls
}
nj_arcgis_body <- function(x) x$body

test_that("NJGIN keeps offset JSON, native IDs, geometry and HTTP settings", {
  local_nj_offline_transport()
  calls <- nj_arcgis_http(nj_arcgis_body)
  src <- facilities_sources()$njgin_school_points
  out <- get_raw_facilities_arcgis(src)
  expect_identical(out$fid, 11:13)
  expect_identical(out$OGIS_ID, paste0("synthetic-", 11:13))
  expect_identical(out$COUNTYCODE, rep("00", 3))
  expect_equal(out$.longitude, 11:13)
  expect_equal(out$.latitude, -(11:13))
  sent <- calls()
  expect_length(sent, 5)
  expect_identical(sent[[1]]$url, sub("/query$", "", src$url))
  for (i in 2:5) {
    expect_identical(sent[[i]]$url, src$url)
    expect_identical(sent[[i]]$query$where, "1=1")
  }
  for (i in c(2, 5)) {
    expect_identical(sent[[i]]$query$returnCountOnly, "true")
    expect_identical(sent[[i]]$query$returnGeometry, "false")
  }
  for (i in 3:4) {
    q <- sent[[i]]$query
    expect_identical(q$orderByFields, "fid ASC")
    expect_identical(q$outFields, "*")
    expect_identical(q$returnGeometry, "true")
    expect_identical(q$outSR, "4326")
    expect_identical(q$f, "json")
    expect_null(q$objectIds)
  }
  expect_equal(sent[[3]]$query$resultOffset, 0)
  expect_equal(sent[[4]]$query$resultOffset, 2)
  expect_equal(sent[[3]]$query$resultRecordCount, 2)
  expect_equal(sent[[4]]$query$resultRecordCount, 1)
  for (call in sent) expect_equal(call$config[[1]]$options$timeout_ms, 60000)
})

test_that("NJGIN refuses miscounts, repeated IDs, short pages and wrong OID", {
  local_nj_offline_transport()
  for (fault in c("recount", "repeat", "short", "oid", "missing", "transfer")) {
    nj_arcgis_http(function(x) {
      if (fault == "recount" && x$count_calls == 2) x$body$count <- 4L
      if (!is.null(x$query$resultOffset)) {
        if (fault == "repeat" && x$query$resultOffset > 0)
          x$body$features[[1]]$attributes$fid <- 11L
        if (fault == "short" && x$query$resultOffset == 0)
          x$body$features <- x$body$features[1]
        if (fault == "missing") x$body$features <- NULL
        if (fault == "transfer") x$body$exceededTransferLimit <- TRUE
      }
      if (fault == "oid" && !grepl("/query$", x$url)) x$body$objectIdField <- "other_id"
      x$body
    })
    expect_error(get_raw_facilities_arcgis(facilities_sources()$njgin_school_points),
                 switch(fault, recount = "source count changed", "repeat" = "missing or repeated object IDs",
                   short = "short completion", oid = "missing or repeated object IDs",
                   missing = "missing features", transfer = "transfer flag contradicts advertised count"),
                 info = fault)
  }
})

test_that("NJGIN checks error bodies at metadata, count, later page and recount", {
  local_nj_offline_transport()
  for (phase in c("metadata", "count", "page", "recount")) {
    nj_arcgis_http(function(x) {
      hit <- switch(phase, metadata = !grepl("/query$", x$url),
        count = x$count_calls == 1 && !is.null(x$query$returnCountOnly),
        page = !is.null(x$query$resultOffset) && x$query$resultOffset > 0,
        recount = x$count_calls == 2)
      if (hit) list(error = list(code = 503L, message = "synthetic unavailable")) else x$body
    })
    expect_error(get_raw_facilities_arcgis(facilities_sources()$njgin_school_points),
                 "publisher returned an in-body error", info = phase)
  }
})

test_that("NJGIN preserves empty-source, transport and parser conditions", {
  local_nj_offline_transport()
  src <- facilities_sources()$njgin_school_points
  nj_arcgis_http(function(x) {
    if (!is.null(x$body$count)) x$body$count <- 0L
    x$body
  })
  e <- tryCatch(get_raw_facilities_arcgis(src), error = identity)
  expect_identical(class(e), c("simpleError", "error", "condition"))
  expect_identical(conditionMessage(e), paste0("ArcGIS source returned no school points: ", src$url))
  expect_null(conditionCall(e))
  sentinel <- structure(list(message = "synthetic", call = quote(original_client()), detail = "unchanged"),
                        class = c("synthetic_client_error", "error", "condition"))
  local_mocked_bindings(GET = function(...) stop(sentinel), .package = "httr")
  expect_identical(tryCatch(get_raw_facilities_arcgis(src), error = identity), sentinel)
  nj_arcgis_http(nj_arcgis_body)
  local_mocked_bindings(fromJSON = function(...) stop(sentinel), .package = "jsonlite")
  expect_identical(tryCatch(get_raw_facilities_arcgis(src), error = identity), sentinel)
})

test_that("NJGIN preserves native HTTP status classes and reader call", {
  local_nj_offline_transport()
  src <- facilities_sources()$njgin_school_points
  response <- structure(list(status_code = 503L, headers = list(), url = src$url), class = "response")
  local_mocked_bindings(GET = function(...) response, .package = "httr")
  expected <- httr::http_condition(response, "error", call = quote(get_raw_facilities_arcgis(src)))
  expect_identical(tryCatch(get_raw_facilities_arcgis(src), error = identity), expected)
})

test_that("NJGIN refuses offsets beyond its original safety ceiling before HTTP", {
  local_nj_offline_transport()
  local_mocked_bindings(arcgis_counted_read = function(request, ...) {
    request("query", list(resultOffset = 500001L))
  }, .package = "njschooldata")
  e <- tryCatch(get_raw_facilities_arcgis(facilities_sources()$njgin_school_points), error = identity)
  expect_identical(conditionMessage(e), "ArcGIS paging safety limit exceeded")
  expect_identical(class(e), c("simpleError", "error", "condition"))
  expect_null(conditionCall(e))
})
