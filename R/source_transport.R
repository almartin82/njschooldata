# ==============================================================================
# Validated source transport
# ==============================================================================

.source_url_parts <- function(url) {
  parsed <- httr::parse_url(url)
  list(
    scheme = tolower(parsed$scheme %||% ""),
    host = tolower(parsed$hostname %||% "")
  )
}

.validate_source_url <- function(url, allowed_hosts, allow_http = FALSE,
                                 redirect = FALSE) {
  parts <- .source_url_parts(url)
  permitted_schemes <- if (isTRUE(allow_http)) c("https", "http") else "https"
  if (!parts$scheme %in% permitted_schemes) {
    label <- if (redirect) "redirect URL" else "source URL"
    stop(label, " must use HTTPS.", call. = FALSE)
  }
  if (!nzchar(parts$host) || !parts$host %in% tolower(allowed_hosts)) {
    label <- if (redirect) "redirect host" else "source host"
    stop(
      label, " '", parts$host, "' is not in the registered source allowlist.",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

# NJ DOE's Homeroom directory downloads sit behind an Imperva policy that
# answers a self-identifying agent string with HTTP 403 and a 963-byte
# challenge page, while the identical request carrying a browser agent
# returns the real CSV (961,540 bytes for the school download, 2,525 rows;
# 426,689 bytes for the district download, 683 rows). That 403 is a property
# of OUR request, not an NJ DOE outage, and reporting it as
# `source_unavailable` blamed the department for our own header. The
# facilities downloader has always sent the browser agent for the same
# reason; the shared transport now does too.
.source_user_agent <- function() {
  paste0(
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 ",
    "(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
  )
}

.default_source_request <- function(url, dest, timeout,
                                    user_agent = .source_user_agent()) {
  response <- httr::GET(
    url,
    httr::write_disk(dest, overwrite = TRUE),
    httr::timeout(timeout),
    httr::user_agent(user_agent)
  )
  list(
    status_code = httr::status_code(response),
    final_url = response$url,
    content_type = httr::headers(response)[["content-type"]] %||%
      "application/octet-stream"
  )
}

.read_source_prefix <- function(path, bytes = 1024L) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  readBin(connection, what = "raw", n = bytes)
}

.raw_starts_with <- function(value, signature) {
  length(value) >= length(signature) &&
    identical(value[seq_along(signature)], as.raw(signature))
}

.looks_like_html <- function(prefix) {
  if (!length(prefix)) return(FALSE)
  values <- as.integer(prefix)
  ascii <- prefix[values %in% c(9L, 10L, 13L, 32L:126L)]
  text <- tolower(rawToChar(ascii, multiple = FALSE))
  grepl("<!doctype[[:space:]]+html|<html|<head|<body", text)
}

.validate_archive_members <- function(names) {
  names <- gsub("\\\\", "/", as.character(names))
  unsafe <- startsWith(names, "/") |
    grepl("^[A-Za-z]:/", names) |
    grepl("(^|/)\\.\\.(/|$)", names)
  if (any(unsafe)) {
    stop(
      "Archive contains an unsafe absolute or parent-relative member path.",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

.validate_archive <- function(path, source_type) {
  prefix <- .read_source_prefix(path, 8L)
  if (!.raw_starts_with(prefix, c(0x50, 0x4b))) {
    stop(toupper(source_type), " source is truncated or has no ZIP signature.",
         call. = FALSE)
  }
  listing <- tryCatch(
    suppressWarnings(utils::unzip(path, list = TRUE)),
    error = function(error) NULL
  )
  if (is.null(listing) || !nrow(listing)) {
    stop(toupper(source_type), " source is corrupt or empty.", call. = FALSE)
  }
  .validate_archive_members(listing$Name)
  if (identical(source_type, "xlsx")) {
    names <- gsub("\\\\", "/", listing$Name)
    if (!"[Content_Types].xml" %in% names ||
        !any(startsWith(names, "xl/"))) {
      stop("XLSX source is not a valid Excel workbook.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

.validate_source_file <- function(path, source_type, content_type = NULL) {
  source_type <- match.arg(
    tolower(source_type),
    c("xlsx", "xls", "zip", "csv", "text", "json", "html")
  )
  size <- file.info(path)$size
  if (is.na(size) || size <= 0) {
    stop("Downloaded source is empty.", call. = FALSE)
  }

  content_type <- content_type %||% ""
  content_type <- if (length(content_type) && !is.na(content_type) &&
                      nzchar(content_type)) {
    tolower(strsplit(content_type, ";", fixed = TRUE)[[1]][1])
  } else {
    ""
  }
  prefix <- .read_source_prefix(path)
  if (.looks_like_html(prefix) && source_type != "html") {
    stop("Downloaded source is an HTML error page, not ", toupper(source_type),
         ".", call. = FALSE)
  }

  expected_types <- list(
    xlsx = c(
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "application/zip", "application/octet-stream", ""
    ),
    xls = c("application/vnd.ms-excel", "application/octet-stream", ""),
    zip = c("application/zip", "application/x-zip-compressed",
            "application/octet-stream", ""),
    csv = c("text/csv", "application/csv", "text/plain",
            "application/octet-stream", ""),
    text = c("text/plain", "text/csv", "application/octet-stream", ""),
    json = c("application/json", "text/json", "text/plain",
             "application/octet-stream", ""),
    html = c("text/html", "application/xhtml+xml", "text/plain", "")
  )
  if (!content_type %in% expected_types[[source_type]]) {
    stop(
      "Unexpected content type '", content_type, "' for ", toupper(source_type),
      " source.", call. = FALSE
    )
  }

  if (source_type %in% c("zip", "xlsx")) {
    .validate_archive(path, source_type)
  } else if (source_type == "xls") {
    if (!.raw_starts_with(prefix, c(0xd0, 0xcf, 0x11, 0xe0))) {
      stop("XLS source has an invalid workbook signature.", call. = FALSE)
    }
  } else if (source_type == "json") {
    tryCatch(
      jsonlite::fromJSON(path, simplifyVector = FALSE),
      error = function(error) stop(
        "JSON source could not be parsed: ", conditionMessage(error),
        call. = FALSE
      )
    )
  } else if (source_type == "html" && !.looks_like_html(prefix)) {
    stop("HTML source has no recognizable HTML document signature.", call. = FALSE)
  } else if (source_type %in% c("csv", "text") && any(prefix == as.raw(0))) {
    stop("Text source contains binary NUL bytes.", call. = FALSE)
  }
  invisible(TRUE)
}

.source_digest <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

.source_failure <- function(status, url, error, retrieved_at = NULL) {
  new_source_result(
    source_status = status,
    source_url = url,
    retrieved_at = retrieved_at,
    error = conditionMessage(error)
  )
}

# Explicit maintainer adoption of verified retained bytes; never performs a
# request. The expected digest must come from the retained-source evidence.
# Unknown original acquisition time remains NULL, not file mtime or adoption time.
.adopt_source_cache <- function(cache_path, url, source_type, expected_digest,
                                retrieved_at = NULL, final_url = url) {
  .validate_source_url(url, source_host_allowlist())
  .validate_source_url(final_url, source_host_allowlist(), redirect = TRUE)
  .validate_source_file(cache_path, source_type)
  if (!identical(.source_digest(cache_path), expected_digest)) {
    stop("Retained source digest does not match adoption evidence.", call. = FALSE)
  }
  if (!is.null(retrieved_at) &&
      (!inherits(retrieved_at, "POSIXct") || length(retrieved_at) != 1L ||
       !is.finite(as.numeric(retrieved_at)))) {
    stop("Acquisition time must be a recorded POSIXct or NULL.", call. = FALSE)
  }
  lock_path <- paste0(cache_path, ".acquiring")
  if (!dir.create(lock_path, showWarnings = FALSE)) {
    stop("Source cache acquisition is already active.", call. = FALSE)
  }
  on.exit(unlink(lock_path, recursive = TRUE), add = TRUE)
  metadata <- list(version = 1L, requested_url = url, final_url = final_url,
                   source_type = source_type, retrieved_at = retrieved_at,
                   clock = if (is.null(retrieved_at)) "unknown" else "recorded",
                   size = as.numeric(file.info(cache_path)$size), digest = expected_digest)
  path <- tempfile(".njsd-adoption-", tmpdir = dirname(cache_path))
  on.exit(unlink(path), add = TRUE)
  saveRDS(metadata, path)
  if (!file.rename(path, paste0(cache_path, ".source.rds"))) {
    stop("Retained source metadata could not be atomically promoted.", call. = FALSE)
  }
  invisible(metadata)
}

#' Download and validate a registered NJ DOE source
#'
#' Downloads are written to a temporary file, validated, and then atomically
#' promoted into an optional cache path. Transport failures and artifact/parser
#' failures have distinct source statuses.
#'
#' @param url HTTPS source URL.
#' @param source_type One of `xlsx`, `xls`, `zip`, `csv`, `text`, `json`, or
#'   `html`.
#' @param cache_path Optional validated artifact cache path.
#' @param timeout Bounded request timeout in seconds.
#' @param retries Number of retries after the initial transient failure.
#' @param allowed_hosts Explicit host allowlist, defaulting to registered hosts.
#' @param allow_http Permit plaintext HTTP for a narrowly scoped historical
#'   source. Active sources should leave this `FALSE`.
#' @param request_fn Injectable request implementation for offline tests.
#' @param sleep_fn Injectable retry delay implementation.
#' @return An `njsd_source_result` whose data is the validated local path.
#' @keywords internal
download_source <- function(url, source_type, cache_path = NULL,
                            timeout = 60, retries = 2L,
                            allowed_hosts = source_host_allowlist(),
                            allow_http = FALSE,
                            request_fn = .default_source_request,
                            sleep_fn = Sys.sleep) {
  source_type <- match.arg(
    tolower(source_type),
    c("xlsx", "xls", "zip", "csv", "text", "json", "html")
  )
  retries <- max(0L, as.integer(retries))

  if (identical(request_fn, .default_source_request)) {
    packaged <- .package_source(url, source_type)
    if (!is.null(packaged)) return(packaged)
  }

  initial_check <- tryCatch(
    {
      .validate_source_url(url, allowed_hosts, allow_http = allow_http)
      NULL
    },
    error = identity
  )
  if (inherits(initial_check, "error")) {
    return(.source_failure("source_unavailable", url, initial_check))
  }

  metadata_path <- if (!is.null(cache_path)) paste0(cache_path, ".source.rds") else NULL
  if (!is.null(cache_path) && file.exists(cache_path)) {
    # Legacy or changed-source entries remain intact. A cache miss is not
    # permission to reacquire historical DOE bytes or invent their clock.
    metadata <- if (file.exists(metadata_path)) {
      tryCatch(readRDS(metadata_path), error = function(e) NULL)
    } else NULL
    valid_metadata <- is.list(metadata) && identical(metadata$version, 1L) &&
      identical(metadata$requested_url, url) &&
      identical(metadata$source_type, source_type) &&
      is.character(metadata$final_url) && length(metadata$final_url) == 1L &&
      ((identical(metadata$clock, "unknown") && is.null(metadata$retrieved_at)) ||
       (identical(metadata$clock, "recorded") &&
        inherits(metadata$retrieved_at, "POSIXct") && length(metadata$retrieved_at) == 1L &&
        is.finite(as.numeric(metadata$retrieved_at)))) && is.numeric(metadata$size) &&
      length(metadata$size) == 1L && is.character(metadata$digest) &&
      length(metadata$digest) == 1L
    if (!isTRUE(valid_metadata)) {
      return(.source_failure("source_unavailable", url, simpleError(
        "Cached source identity is missing or differs; explicit source repair is required."
      )))
    }
    cache_check <- tryCatch({
      .validate_source_url(metadata$final_url, allowed_hosts,
                           allow_http = allow_http, redirect = TRUE)
      .validate_source_file(cache_path, source_type)
      if (!identical(as.numeric(file.info(cache_path)$size), metadata$size) ||
          !identical(.source_digest(cache_path), metadata$digest)) {
        stop("Cached source length or digest differs from acquisition metadata.")
      }
      NULL
    }, error = identity)
    if (inherits(cache_check, "error")) {
      return(.source_failure("parse_error", url, cache_check))
    }
    result <- new_source_result(
      data = cache_path, source_status = "actual",
      source_url = metadata$final_url, retrieved_at = metadata$retrieved_at,
      digest = metadata$digest, warning = "Validated cache artifact reused."
    )
    result$verified_at <- Sys.time()
    result$requested_url <- metadata$requested_url
    result$ownership <- "persistent"
    return(result)
  }

  target_dir <- if (is.null(cache_path)) tempdir() else dirname(cache_path)
  if (!dir.exists(target_dir)) dir.create(target_dir, recursive = TRUE)
  if (!is.null(cache_path)) {
    lock_path <- paste0(cache_path, ".acquiring")
    if (!dir.create(lock_path, showWarnings = FALSE)) {
      return(.source_failure("source_unavailable", url, simpleError(
        "Source cache acquisition is already active; retry after its owner exits."
      )))
    }
    on.exit(unlink(lock_path, recursive = TRUE), add = TRUE)
    # Another publisher may have completed between the initial lookup and lock.
    if (file.exists(cache_path)) {
      return(download_source(url, source_type, cache_path, timeout, retries,
                             allowed_hosts, allow_http, request_fn, sleep_fn))
    }
  }
  temporary <- tempfile(
    pattern = ".njsd-download-", tmpdir = target_dir,
    fileext = paste0(".", source_type)
  )
  keep_temporary <- FALSE
  on.exit(if (!keep_temporary && file.exists(temporary)) unlink(temporary), add = TRUE)

  retrieved_at <- NULL
  last_error <- NULL
  response <- NULL
  for (attempt in seq_len(retries + 1L)) {
    if (file.exists(temporary)) unlink(temporary)
    retrieved_at <- Sys.time()
    response <- tryCatch(
      request_fn(url, temporary, timeout),
      error = function(error) error
    )

    if (inherits(response, "error")) {
      last_error <- response
      transient <- TRUE
    } else {
      status <- as.integer(response$status_code %||% 0L)
      transient <- status %in% c(408L, 425L, 429L) || status >= 500L
      if (status >= 200L && status < 300L) break
      last_error <- simpleError(paste0("HTTP ", status, " for ", url))
    }
    if (!transient || attempt > retries) break
    sleep_fn(min(2^(attempt - 1L), 4L))
  }

  if (inherits(response, "error") || is.null(response) ||
      as.integer(response$status_code %||% 0L) < 200L ||
      as.integer(response$status_code %||% 0L) >= 300L) {
    return(.source_failure(
      "source_unavailable", url,
      last_error %||% simpleError("Source request failed."), retrieved_at
    ))
  }

  final_url <- response$final_url %||% url
  redirect_check <- tryCatch(
    {
      .validate_source_url(
        final_url, allowed_hosts, allow_http = allow_http, redirect = TRUE
      )
      NULL
    },
    error = identity
  )
  if (inherits(redirect_check, "error")) {
    return(.source_failure("source_unavailable", url, redirect_check, retrieved_at))
  }

  artifact_check <- tryCatch(
    {
      .validate_source_file(
        temporary, source_type, response$content_type %||% NULL
      )
      NULL
    },
    error = identity
  )
  if (inherits(artifact_check, "error")) {
    return(.source_failure("parse_error", url, artifact_check, retrieved_at))
  }

  digest <- .source_digest(temporary)
  if (!is.null(cache_path)) {
    if (!file.rename(temporary, cache_path)) {
      return(.source_failure("source_unavailable", url, simpleError(
        "Validated artifact could not be atomically promoted to cache."
      ), retrieved_at))
    }
    metadata <- list(
      version = 1L, requested_url = url, final_url = final_url,
      source_type = source_type, retrieved_at = retrieved_at, clock = "recorded",
      size = as.numeric(file.info(cache_path)$size), digest = digest
    )
    metadata_temp <- tempfile(".njsd-metadata-", tmpdir = target_dir)
    on.exit(unlink(metadata_temp), add = TRUE)
    saveRDS(metadata, metadata_temp)
    if (!file.rename(metadata_temp, metadata_path)) {
      return(.source_failure("source_unavailable", url, simpleError(
        "Source acquisition metadata could not be atomically promoted."
      ), retrieved_at))
    }
    cache_warning <- NULL
    data_path <- cache_path
  } else {
    data_path <- temporary
    cache_warning <- NULL
  }

  result <- new_source_result(
    data = data_path,
    source_status = "actual",
    source_url = final_url,
    retrieved_at = retrieved_at,
    digest = digest,
    warning = cache_warning
  )
  result$ownership <- if (is.null(cache_path)) "temporary" else "persistent"
  if (is.null(cache_path)) {
    released <- FALSE
    result$release <- function() {
      if (!released) {
        released <<- TRUE
        unlink(data_path)
      }
      invisible(NULL)
    }
    # Retain only after the complete ownership handle exists. Construction
    # errors/interruptions still belong to this function's on.exit cleanup.
    keep_temporary <- TRUE
  }
  result
}
