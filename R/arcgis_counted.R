# Canonical counted ArcGIS reader
# Edit contracts/arcgis-counted/v1/arcgis_counted.R, then vendor with
# scripts/arcgis-counted/sync.py. Adapters own HTTP, parsing, geometry and conditions.

arcgis_counted_read <- function(request, where = "1=1", return_geometry = FALSE,
                               out_fields = "*", page_size = 2000L,
                               protocol = c("offset", "ids"), page_format = "json",
                               decode = function(body) body$features,
                               feature_count = length,
                               feature_ids = function(features, field) {
                                 vapply(features, function(x) {
                                   value <- x$attributes[[field]]
                                   if (is.null(value) || length(value) != 1L) return(NA_character_)
                                   as.character(value)
                                 }, character(1))
                               },
                               invalid = function(message, kind = "response", body = NULL) {
                                 stop(message, call. = FALSE)
                               }, body_error = NULL) {
  protocol <- match.arg(protocol)
  fail <- function(message, kind = "response", body = NULL) {
    invalid(paste("Incomplete ArcGIS acquisition:", message), kind, body)
    stop("ArcGIS invalid callback returned", call. = FALSE)
  }
  integer_scalar <- function(x) is.numeric(x) && length(x) == 1L &&
    !is.na(x) && is.finite(x) && x >= 0 && x == floor(x)
  field_scalar <- function(x) is.character(x) && length(x) == 1L &&
    !is.na(x) && nzchar(trimws(x))
  valid_ids <- function(x) (is.character(x) || is.numeric(x)) &&
    !anyNA(x) && !anyDuplicated(x) && all(nzchar(trimws(as.character(x)))) &&
    (!is.numeric(x) || all(is.finite(x) & x == floor(x)))
  if (!integer_scalar(page_size) || page_size < 1) stop("Invalid ArcGIS page_size")
  if (!is.logical(return_geometry) || length(return_geometry) != 1L || is.na(return_geometry))
    stop("ArcGIS return_geometry must be explicit TRUE or FALSE")
  # A plain query on the same endpoint distinguishes our malformed request from
  # an unavailable publisher. The adapter may retain its existing condition/probe.
  probe <- function() request("query", list(where = "1=1", outFields = "*",
    returnGeometry = "false", resultRecordCount = 1L, f = "json"))
  read <- function(kind, query, phase) {
    body <- request(kind, query) # thrown conditions propagate without wrapping
    if (!is.list(body) || is.null(names(body))) fail("invalid response envelope")
    if (!is.null(body$error)) {
      if (!is.null(body_error)) body_error(body, phase, probe)
      error <- body$error
      if (is.list(error) && identical(as.character(error$code), "400")) {
        plain <- probe()
        if (is.list(plain) && is.null(plain$error) && !is.null(plain$features))
          fail("query failed but same-layer plain probe succeeded", "request", body)
      }
      fail("publisher returned an in-body error", body = body)
    }
    body
  }
  metadata <- read("metadata", list(f = "json"), "metadata")
  field <- metadata$objectIdField
  if (is.null(field)) field <- metadata$objectIdFieldName
  if (is.null(field)) {
    fields <- metadata$fields
    candidates <- if (is.data.frame(fields)) {
      fields$name[fields$type %in% c("esriFieldTypeOID", "esriFieldTypeObjectID")]
    } else {
      unlist(lapply(fields, function(x) if (x$type %in% c("esriFieldTypeOID", "esriFieldTypeObjectID")) x$name), use.names = FALSE)
    }
    if (length(candidates) == 1L) field <- candidates
  }
  if (!field_scalar(field)) fail("layer has no publisher object-ID field")
  cap <- metadata$maxRecordCount
  if (!is.null(cap)) {
    if (!integer_scalar(cap) || cap < 1) fail("invalid publisher page cap")
    page_size <- min(page_size, cap)
  }
  count_query <- list(where = where, returnCountOnly = "true", returnGeometry = "false", f = "json")
  expected <- read("query", count_query, "count")$count
  if (!integer_scalar(expected)) fail("unusable source count")
  inventory <- NULL
  if (protocol == "ids") {
    listed <- read("query", list(where = where, returnIdsOnly = "true",
      returnGeometry = "false", f = "json"), "inventory")
    inventory <- listed$objectIds
    if (expected == 0 && is.null(inventory)) inventory <- numeric()
    if (!valid_ids(inventory) || length(inventory) != expected ||
        !identical(listed$objectIdFieldName, field)) fail("invalid object-ID inventory")
    inventory <- sort(inventory)
  }
  pages <- list()
  seen <- character()
  acquired <- 0
  while (acquired < expected) {
    limit <- min(page_size, expected - acquired)
    query <- list(where = where,
      outFields = if (identical(out_fields, "*")) "*" else paste(unique(c(field, out_fields)), collapse = ","),
      returnGeometry = tolower(as.character(return_geometry)),
      outSR = if (return_geometry) "4326" else NULL,
      orderByFields = paste(field, "ASC"), f = page_format)
    if (protocol == "offset") {
      query$resultOffset <- acquired
      query$resultRecordCount <- limit
    } else {
      selected <- inventory[seq.int(acquired + 1, acquired + limit)]
      query$objectIds <- paste(selected, collapse = ",")
    }
    body <- read("query", query, "page")
    flag <- body$exceededTransferLimit
    if (!is.null(flag) && (!is.logical(flag) || length(flag) != 1L || is.na(flag)))
      fail("malformed transfer-limit flag")
    if (protocol == "ids" && isTRUE(flag)) fail("transfer flag contradicts exact-ID batch")
    features <- decode(body)
    if (is.null(features)) fail("missing features before advertised count")
    n <- feature_count(features)
    if (!integer_scalar(n) || n < 1 || n > limit) fail("empty or oversized raw page")
    ids <- feature_ids(features, field)
    if (!valid_ids(ids) || length(ids) != n || any(as.character(ids) %in% seen))
      fail("missing or repeated object IDs")
    if (protocol == "ids" && (n != length(selected) || !setequal(as.character(ids), as.character(selected))))
      fail("raw page differs from requested object-ID inventory")
    seen <- c(seen, as.character(ids))
    acquired <- acquired + n # raw rows, before any source-specific deduplication
    pages[[length(pages) + 1L]] <- features
    if (acquired == expected && isTRUE(flag)) fail("transfer flag contradicts advertised count")
    if (acquired < expected && (identical(flag, FALSE) || (n < limit && !isTRUE(flag))))
      fail("short completion before advertised count")
  }
  final <- read("query", count_query, "final-count")$count
  if (!integer_scalar(final) || final != expected) fail("source count changed during paging")
  pages
}
