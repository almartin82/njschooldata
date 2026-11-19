# Canonical counted ArcGIS controls: identifiers only, no education data or network.
# Vendor byte-for-byte with scripts/arcgis-counted/sync.py.
arcgis_control <- function(protocol = "offset", count = 4L, cap = 2L,
                           change = function(body, query, kind, phase) body) {
  calls <- list()
  counts <- 0L
  request <- function(kind, query) {
    calls[[length(calls) + 1L]] <<- list(kind = kind, query = query)
    if (kind == "metadata") {
      phase <- "metadata"
      body <- list(objectIdField = "fid", maxRecordCount = cap)
    } else if (!is.null(query$returnCountOnly)) {
      counts <<- counts + 1L
      phase <- if (counts == 1L) "count" else "final-count"
      body <- list(count = count)
    } else if (!is.null(query$returnIdsOnly)) {
      phase <- "inventory"
      body <- list(objectIdFieldName = "fid", objectIds = seq_len(count))
    } else {
      phase <- if (is.null(query$orderByFields)) "probe" else "page"
      ids <- if (!is.null(query$objectIds)) as.integer(strsplit(query$objectIds, ",", fixed = TRUE)[[1]]) else {
        offset <- if (is.null(query$resultOffset)) 0L else query$resultOffset
        size <- if (is.null(query$resultRecordCount)) 1L else query$resultRecordCount
        seq.int(offset + 1L, min(count, offset + size))
      }
      body <- list(features = lapply(ids, function(id) list(attributes = list(fid = id))))
    }
    change(body, query, kind, phase)
  }
  list(read = function(...) arcgis_counted_read(request, protocol = protocol, ...),
       calls = function() calls)
}

test_that("offset requests use publisher fid, identical predicate and explicit geometry", {
  client <- arcgis_control()
  pages <- client$read(where = "active=1", out_fields = "name", return_geometry = TRUE, page_size = 3L)
  expect_identical(unlist(lapply(pages, function(p) vapply(p, function(f) f$attributes$fid, integer(1)))), 1:4)
  calls <- client$calls()
  expect_identical(calls[[1]]$kind, "metadata")
  queries <- lapply(calls[-1], `[[`, "query")
  expect_true(all(vapply(queries, function(q) identical(q$where, "active=1"), logical(1))))
  page_queries <- Filter(function(q) !is.null(q$orderByFields), queries)
  expect_equal(vapply(page_queries, `[[`, numeric(1), "resultOffset"), c(0, 2))
  expect_true(all(vapply(page_queries, function(q) q$resultRecordCount == 2, logical(1))))
  expect_true(all(vapply(page_queries, function(q) identical(q$orderByFields, "fid ASC") &&
    identical(q$outFields, "fid,name") && identical(q$returnGeometry, "true") &&
    identical(q$outSR, "4326"), logical(1))))
  expect_identical(tail(queries, 1)[[1]]$returnCountOnly, "true")
  plain <- arcgis_control()
  plain$read()
  expect_true(all(vapply(plain$calls()[-1], function(c) identical(c$query$returnGeometry, "false"), logical(1))))
})

test_that("exact-ID batches retain publisher inventory protocol and predicate", {
  client <- arcgis_control("ids")
  expect_length(client$read(where = "open=1"), 2L)
  queries <- lapply(client$calls()[-1], `[[`, "query")
  expect_true(all(vapply(queries, function(q) identical(q$where, "open=1"), logical(1))))
  batches <- Filter(function(q) !is.null(q$objectIds), queries)
  expect_identical(vapply(batches, `[[`, character(1), "objectIds"), c("1,2", "3,4"))
  expect_true(all(vapply(batches, function(q) is.null(q$resultOffset) && is.null(q$resultRecordCount), logical(1))))
})

test_that("publisher OID field descriptors are accepted without guessing a name", {
  for (shape in c("list", "frame")) for (type in c("esriFieldTypeOID", "esriFieldTypeObjectID")) {
    client <- arcgis_control(change = function(b, q, k, phase) {
      if (phase == "metadata") {
        b$objectIdField <- NULL
        b$fields <- if (shape == "list") list(list(name = "fid", type = type)) else
          data.frame(name = "fid", type = type)
      }
      b
    })
    expect_length(client$read(), 2L)
  }
})

test_that("invalid metadata and counts cannot publish a prefix", {
  for (bad in list(NULL, "4", -1, Inf, NA_real_, 1.5, c(4, 4))) {
    client <- arcgis_control(change = function(b, q, k, phase) {
      if (phase == "count") b$count <- bad
      b
    })
    expect_error(client$read(), "unusable source count")
  }
  for (bad in list(NULL, "", NA_character_, c("fid", "oid"))) {
    client <- arcgis_control(change = function(b, q, k, phase) {
      if (phase == "metadata") b$objectIdField <- bad
      b
    })
    expect_error(client$read(), "publisher object-ID")
  }
  for (bad in list(0, "2", NA_real_)) {
    client <- arcgis_control(cap = bad)
    expect_error(client$read(), "page cap")
  }
})

test_that("empty layers complete honestly without a feature request", {
  client <- arcgis_control(count = 0L)
  expect_identical(client$read(), list())
  expect_length(client$calls(), 3L)
  client <- arcgis_control("ids", count = 0L)
  expect_identical(client$read(), list())
})

test_that("every response body including metadata, count and later pages is checked", {
  for (broken in c("metadata", "count", "inventory", "page", "final-count")) {
    client <- arcgis_control("ids", change = function(b, q, k, phase) {
      if (phase == broken && (phase != "page" || identical(q$objectIds, "3,4")))
        return(list(error = list(code = 503L, message = "control unavailable")))
      b
    })
    expect_error(client$read(), "in-body error")
  }
  client <- arcgis_control(change = function(b, q, k, phase) if (phase == "page") "bad envelope" else b)
  expect_error(client$read(), "response envelope")
})

test_that("query defects use plain same-layer probe and retain local condition fields", {
  original <- errorCondition("local request defect", class = "control_request_error",
    call = quote(publisher_query()), publisher_detail = "retained")
  client <- arcgis_control(change = function(b, q, k, phase) {
    if (phase == "page") return(list(error = list(code = 400L)))
    b
  })
  caught <- tryCatch(client$read(invalid = function(message, kind, body) {
    if (kind == "request") stop(original)
    stop(message)
  }), error = identity)
  expect_identical(caught, original)
  probes <- Filter(function(x) !is.null(x$query$outFields) && is.null(x$query$orderByFields), client$calls())
  expect_length(probes, 1L)
  expect_identical(probes[[1]]$query$where, "1=1")
  expect_identical(probes[[1]]$query$returnGeometry, "false")
  outage <- arcgis_control(change = function(b, q, k, phase) {
    if (phase %in% c("page", "probe")) return(list(error = list(code = 400L)))
    b
  })
  expect_error(outage$read(), "in-body error")
})

test_that("HTTP parser and custom body conditions propagate with original call", {
  original <- errorCondition("parse diagnostic", class = "control_parse_error",
    call = quote(parse_control()), detail = list(code = 42L))
  for (broken in c("metadata", "count", "page", "final-count")) {
    client <- arcgis_control(change = function(b, q, k, phase) {
      if (phase == broken) stop(original)
      b
    })
    expect_identical(tryCatch(client$read(), error = identity), original)
  }
  client <- arcgis_control(change = function(b, q, k, phase) {
    if (phase == "page") return(list(error = list(code = 503L)))
    b
  })
  expect_identical(tryCatch(client$read(body_error = function(body, phase, probe) stop(original)), error = identity), original)
})

test_that("empty missing oversized and prematurely terminal pages stop", {
  for (mode in c("empty", "missing", "oversize", "short", "terminal")) {
    client <- arcgis_control(count = if (mode == "oversize") 2L else 4L, change = function(b, q, k, phase) {
      if (phase == "page") {
        if (mode == "empty") b$features <- list()
        if (mode == "missing") b$features <- NULL
        if (mode == "oversize") b$features <- c(b$features, list(list(attributes = list(fid = 9L))))
        if (mode == "short") b$features <- b$features[1]
        if (mode == "terminal") b$exceededTransferLimit <- FALSE
      }
      b
    })
    expect_error(client$read(), if (mode %in% c("empty", "oversize")) "empty or oversized raw page" else "Incomplete ArcGIS acquisition")
  }
})

test_that("raw IDs are checked within and across pages before any dedup", {
  for (mode in c("missing", "duplicate", "repeat", "blank")) {
    client <- arcgis_control(change = function(b, q, k, phase) {
      if (phase == "page") {
        if (mode == "missing") b$features[[1]]$attributes$fid <- NULL
        if (mode == "blank") b$features[[1]]$attributes$fid <- ""
        if (mode == "duplicate") b$features[[2]] <- b$features[[1]]
        if (mode == "repeat" && q$resultOffset > 0) b$features[[1]]$attributes$fid <- 1L
      }
      b
    })
    expect_error(client$read(), "object IDs")
  }
})

test_that("inventory and raw ID batches cannot silently replace advertised features", {
  for (mode in c("count", "duplicate", "field", "replacement")) {
    client <- arcgis_control("ids", change = function(b, q, k, phase) {
      if (phase == "inventory") {
        if (mode == "count") b$objectIds <- 1:3
        if (mode == "duplicate") b$objectIds <- c(1L, 1L, 3L, 4L)
        if (mode == "field") b$objectIdFieldName <- "OBJECTID"
      }
      if (phase == "page" && mode == "replacement") b$features[[1]]$attributes$fid <- 99L
      b
    })
    expect_error(client$read(), "inventory")
  }
})

test_that("transfer flags and changing counts refuse false completion", {
  client <- arcgis_control("ids", change = function(b, q, k, phase) {
    if (phase == "page" && identical(q$objectIds, "1,2")) b$exceededTransferLimit <- TRUE
    b
  })
  expect_error(client$read(), "exact-ID batch")
  for (bad in list(TRUE, "false", NA, c(TRUE, FALSE))) {
    client <- arcgis_control(change = function(b, q, k, phase) {
      if (phase == "page") b$exceededTransferLimit <- bad
      b
    })
    expect_error(client$read(), "transfer")
  }
  for (bad in list(3L, NULL, NA_real_, "4")) {
    client <- arcgis_control(change = function(b, q, k, phase) {
      if (phase == "final-count") b$count <- bad
      b
    })
    expect_error(client$read(), "count changed")
  }
})

test_that("GeoJSON and dataframe adapters preserve their raw geometry protocol", {
  client <- arcgis_control(change = function(b, q, k, phase) {
    if (phase == "page") {
      b$features <- lapply(b$features, function(f) list(properties = f$attributes,
        geometry = list(type = "Point", coordinates = c(0, 0))))
    }
    b
  })
  pages <- client$read(page_format = "geojson", return_geometry = TRUE,
    feature_ids = function(features, field) vapply(features, function(f) as.character(f$properties[[field]]), character(1)))
  expect_identical(pages[[1]][[1]]$geometry$type, "Point")
  queries <- lapply(client$calls(), `[[`, "query")
  expect_true(all(vapply(Filter(function(q) !is.null(q$orderByFields), queries),
    function(q) identical(q$f, "geojson"), logical(1))))
  client <- arcgis_control()
  pages <- client$read(decode = function(b) data.frame(fid = vapply(b$features, function(f) f$attributes$fid, integer(1))),
    feature_count = nrow, feature_ids = function(features, field) features[[field]])
  expect_identical(pages[[2]]$fid, 3:4)
})
