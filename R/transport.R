# Canonical vendorable live transport classifier, contract v1.
# Requires base R; transport_stop_for_status() also needs httr. Sourcing is inert.
#
# Vendored byte-for-byte as R/transport.R in every package that acquires live
# source bytes. Edit ONLY contracts/transport/v1/transport.R, then run
# scripts/transport/sync.py. The package prefix is always an argument, never a
# constant here; package wrappers (extra legacy classes, provenance recording)
# live in the package's own files.
#
# It answers one question: did the SOURCE fail? Only three things say yes:
#   1. a curl failure to reach or hear back from the host (transport_curl_classes);
#   2. an HTTP status the source uses for "not now" (transport_http_statuses);
#   3. a small HTML page (a DOE error page or WAF interstitial) where the caller
#      expected a file, checked as bytes before any parser runs.
# Each becomes `<prefix>_acquisition_error` (plus "transport_acquisition_error"),
# keeps the original condition as `parent` and its classes, and is the only
# kind of failure a multi-year fetcher may drop under allow_partial = TRUE.
# Everything else is re-raised untouched: local read/write, callback, URL or
# setup errors, every other 4xx (our own malformed request is a package bug,
# never a source failure), 501/505, TLS verification, and every parse error.
# Parsing happens outside these functions.

transport_curl_classes <- c(
  "curl_error_couldnt_resolve_proxy", "curl_error_couldnt_resolve_host",
  "curl_error_couldnt_connect", "curl_error_operation_timedout",
  "curl_error_send_error", "curl_error_recv_error",
  "curl_error_got_nothing", "curl_error_partial_file",
  "curl_error_ssl_connect_error"
)

transport_http_statuses <- c(408L, 429L, 500L, 502L, 503L, 504L)

.transport_prefix <- function(prefix) {
  if (!is.character(prefix) || length(prefix) != 1L || is.na(prefix) ||
      !grepl("^[A-Za-z][A-Za-z0-9._]*$", prefix)) {
    stop("transport: `prefix` must be one package prefix, e.g. \"txschooldata\"",
         call. = FALSE)
  }
  prefix
}

# The condition every classified source failure raises.
transport_condition <- function(prefix, message, parent = NULL, status = NULL,
                                url = NULL, class = character()) {
  prefix <- .transport_prefix(prefix)
  inherited <- if (inherits(parent, "condition")) class(parent) else character()
  structure(
    list(message = as.character(message)[[1L]],
         call = if (inherits(parent, "condition")) parent$call else NULL,
         parent = parent,
         status = if (is.null(status)) NULL else as.integer(status),
         url = url),
    class = unique(c(paste0(prefix, "_acquisition_error"), class,
                     "transport_acquisition_error",
                     setdiff(inherited, c("error", "condition")),
                     "error", "condition"))
  )
}

transport_abort <- function(prefix, message, parent = NULL, status = NULL,
                            url = NULL, class = character()) {
  stop(transport_condition(prefix, message, parent = parent, status = status,
                           url = url, class = class))
}

# TRUE only for a curl failure to reach or hear back from the host. Never
# inferred from message text.
transport_is_transport_failure <- function(e) {
  inherits(e, "condition") && inherits(e, transport_curl_classes)
}

transport_status_classified <- function(status) {
  length(status) == 1L && !is.na(suppressWarnings(as.integer(status))) &&
    as.integer(status) %in% transport_http_statuses
}

# Evaluate one request. A transport failure becomes the acquisition error with
# the same message; any other error is re-raised untouched.
transport_classify <- function(expr, prefix, url = NULL, class = character()) {
  .transport_prefix(prefix)
  tryCatch(force(expr), error = function(e) {
    if (!transport_is_transport_failure(e)) stop(e)
    transport_abort(prefix, conditionMessage(e), parent = e, url = url,
                    class = class)
  })
}

.transport_http_condition <- function(message, status) {
  structure(
    list(message = message, call = NULL),
    class = unique(c(paste0("http_", status),
                     paste0("http_", (status %/% 100L) * 100L),
                     "http_error", "error", "condition"))
  )
}

# Check an httr response's status. 1xx-3xx return the response invisibly. A
# classified status raises the acquisition error whose parent is the httr
# status condition (same message, its classes kept); any other status raises
# that status condition untouched. With `message`, both carry it; without,
# httr::stop_for_status() writes it.
transport_stop_for_status <- function(response, prefix, message = NULL,
                                      url = NULL, class = character()) {
  .transport_prefix(prefix)
  status <- as.integer(response$status_code)
  if (length(status) != 1L || is.na(status)) {
    stop("transport: the response carries no status code", call. = FALSE)
  }
  if (status < 400L) return(invisible(response))
  if (is.null(url)) url <- response$url
  if (!is.null(message)) {
    parent <- .transport_http_condition(as.character(message)[[1L]], status)
    if (!transport_status_classified(status)) stop(parent)
    transport_abort(prefix, conditionMessage(parent), parent = parent,
                    status = status, url = url, class = class)
  }
  tryCatch(httr::stop_for_status(response), error = function(e) {
    if (!inherits(e, "http_error") || !transport_status_classified(status)) stop(e)
    transport_abort(prefix, conditionMessage(e), parent = e, status = status,
                    url = url, class = class)
  })
  invisible(response)
}

# TRUE when `x` (a file path or a raw vector) begins as an HTML document.
transport_looks_like_html <- function(x, n = 2048L) {
  bytes <- if (is.raw(x)) x[seq_len(min(length(x), n))] else {
    if (!is.character(x) || length(x) != 1L || is.na(x) || !file.exists(x)) {
      return(FALSE)
    }
    readBin(x, what = "raw", n = n)
  }
  if (length(bytes) >= 3L && identical(as.integer(bytes[1:3]), c(239L, 187L, 191L))) {
    bytes <- bytes[-(1:3)]
  }
  bytes <- bytes[bytes != as.raw(0L)]
  text <- tolower(rawToChar(bytes))
  text <- sub("^[[:space:]]+", "", text, useBytes = TRUE)
  startsWith(text, "<") &&
    grepl("<!doctype html|<html[[:space:]>]", text, useBytes = TRUE)
}

.transport_size <- function(x) {
  if (is.raw(x)) length(x) else as.numeric(file.info(x)$size)
}

# Call only where the caller expects a non-HTML file (CSV, workbook, zip,
# JSON). A small HTML page in its place is a DOE error page or WAF
# interstitial: the acquisition error, class "transport_error_page". A large
# HTML page is left alone for the caller's own byte checks or parser to refuse
# loudly (often a landing page our own wrong URL reached). Empty bytes are
# never classified here: an empty 200 can be our request's fault.
transport_check_error_page <- function(x, prefix, url = NULL,
                                       max_bytes = 262144, class = character()) {
  .transport_prefix(prefix)
  if (!transport_looks_like_html(x)) return(invisible(x))
  size <- .transport_size(x)
  if (is.na(size) || size > max_bytes) return(invisible(x))
  transport_abort(prefix,
                  paste0("Source returned an HTML page (", size,
                         " bytes) where a data file was expected",
                         if (!is.null(url)) paste0(": ", url) else ""),
                  url = url, class = c("transport_error_page", class))
}

# The droppable test for a multi-year fetcher: classified at a transport seam,
# looking through purrr's indexed wrapper without changing the cause.
transport_is_acquisition_error <- function(e, prefix) {
  prefix <- .transport_prefix(prefix)
  while (inherits(e, "purrr_error_indexed") && inherits(e$parent, "condition")) {
    e <- e$parent
  }
  inherits(e, paste0(prefix, "_acquisition_error"))
}
