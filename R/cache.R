# ==============================================================================
# Caching System for njschooldata
# ==============================================================================

# Create package environment for session cache
.njsd_cache <- new.env(parent = emptyenv())

# Initialize cache state
.njsd_cache$data <- list()
.njsd_cache$enabled <- TRUE
.njsd_cache$stats <- list(hits = 0, misses = 0)

# -----------------------------------------------------------------------------
# Cache Configuration
# -----------------------------------------------------------------------------

#' Enable or disable the session cache
#'
#' Controls whether downloaded data is cached in memory for the current session.
#' Caching is enabled by default.
#'
#' @param enable Logical; TRUE to enable caching, FALSE to disable
#' @return Previous cache state (invisibly)
#' @export
#' @examples
#' njsd_cache_enable(FALSE)  # Disable caching
#' njsd_cache_enable(TRUE)   # Re-enable caching
njsd_cache_enable <- function(enable = TRUE) {
  validate_logical(enable, "enable")
  old_state <- .njsd_cache$enabled
  .njsd_cache$enabled <- enable

  if (!enable) {
    message("njschooldata cache disabled. Data will be downloaded fresh each time.")
  } else {
    message("njschooldata cache enabled.")
  }

  invisible(old_state)
}

#' Check if caching is enabled
#'
#' @return Logical indicating whether caching is currently enabled
#' @export
njsd_cache_enabled <- function() {
  .njsd_cache$enabled
}

# -----------------------------------------------------------------------------
# Cache Operations
# -----------------------------------------------------------------------------

#' Generate a cache key for a data request
#'
#' @param fn_name Name of the fetch function
#' @param ... Arguments passed to the fetch function
#' @return Character string cache key
#' @keywords internal
make_cache_key <- function(fn_name, ...) {
  args <- list(...)
  # Sort by name for consistent keys
  if (length(args) > 0 && !is.null(names(args))) {
    args <- args[order(names(args))]
  }
  paste0(fn_name, "_", digest::digest(args, algo = "md5"))
}

#' Get data from cache
#'
#' @param key Cache key
#' @return Cached data or NULL if not found
#' @keywords internal
cache_get <- function(key) {
  if (!.njsd_cache$enabled) {
    return(NULL)
  }

  if (key %in% names(.njsd_cache$data)) {
    .njsd_cache$stats$hits <- .njsd_cache$stats$hits + 1
    .njsd_cache$data[[key]]
  } else {
    .njsd_cache$stats$misses <- .njsd_cache$stats$misses + 1
    NULL
  }
}

#' Store data in cache
#'
#' @param key Cache key
#' @param value Data to cache
#' @return The value (invisibly)
#' @keywords internal
cache_set <- function(key, value) {
  if (.njsd_cache$enabled) {
    .njsd_cache$data[[key]] <- value
  }
  invisible(value)
}

#' Check if a key exists in cache
#'
#' @param key Cache key
#' @return Logical
#' @keywords internal
cache_exists <- function(key) {
  .njsd_cache$enabled && key %in% names(.njsd_cache$data)
}

# -----------------------------------------------------------------------------
# Cache Management
# -----------------------------------------------------------------------------

#' Clear the session cache
#'
#' Removes all cached data from memory. Useful when you want to force
#' fresh downloads or free up memory.
#'
#' @param reset_stats Logical; also reset hit/miss statistics
#' @return Number of items cleared (invisibly)
#' @export
#' @examples
#' njsd_cache_clear()
njsd_cache_clear <- function(reset_stats = FALSE) {
  n_items <- length(.njsd_cache$data)
  .njsd_cache$data <- list()

  if (reset_stats) {
    .njsd_cache$stats <- list(hits = 0, misses = 0)
  }

  message(sprintf("Cleared %d item(s) from njschooldata cache.", n_items))
  invisible(n_items)
}

#' Get cache statistics and information
#'
#' Returns information about the current cache state including
#' number of items, memory usage, and hit/miss statistics.
#'
#' @return A list with cache information
#' @export
#' @examples
#' njsd_cache_info()
njsd_cache_info <- function() {
  n_items <- length(.njsd_cache$data)

  # Calculate approximate memory usage
  if (n_items > 0) {
    mem_bytes <- sum(vapply(.njsd_cache$data, function(x) {
      as.numeric(object.size(x))
    }, numeric(1)))
    mem_mb <- round(mem_bytes / 1024 / 1024, 2)
  } else {
    mem_mb <- 0
  }

  info <- list(
    enabled = .njsd_cache$enabled,
    n_items = n_items,
    memory_mb = mem_mb,
    hits = .njsd_cache$stats$hits,
    misses = .njsd_cache$stats$misses,
    hit_rate = if (.njsd_cache$stats$hits + .njsd_cache$stats$misses > 0) {
      round(.njsd_cache$stats$hits /
        (.njsd_cache$stats$hits + .njsd_cache$stats$misses) * 100, 1)
    } else {
      NA_real_
    },
    keys = names(.njsd_cache$data)
  )

  class(info) <- c("njsd_cache_info", "list")
  info
}

#' Print cache information
#'
#' @param x Object from njsd_cache_info()
#' @param ... Additional arguments (unused)
#' @export
print.njsd_cache_info <- function(x, ...) {
  cat("njschooldata Session Cache\n")
  cat("==========================\n")
  cat(sprintf("Status:     %s\n", if (x$enabled) "Enabled" else "Disabled"))
  cat(sprintf("Items:      %d\n", x$n_items))
  cat(sprintf("Memory:     %.2f MB\n", x$memory_mb))
  cat(sprintf("Cache hits: %d\n", x$hits))
  cat(sprintf("Misses:     %d\n", x$misses))
  if (!is.na(x$hit_rate)) {
    cat(sprintf("Hit rate:   %.1f%%\n", x$hit_rate))
  }
  if (x$n_items > 0 && x$n_items <= 10) {
    cat("\nCached items:\n")
    for (key in x$keys) {
      cat(sprintf("  - %s\n", key))
    }
  } else if (x$n_items > 10) {
    cat(sprintf("\nCached items: %d (use $keys to see all)\n", x$n_items))
  }
  invisible(x)
}

#' List all cached items
#'
#' @return Character vector of cache keys
#' @export
njsd_cache_list <- function() {
  names(.njsd_cache$data)
}

#' Remove a specific item from cache
#'
#' @param key The cache key to remove
#' @return TRUE if item was removed, FALSE if not found (invisibly)
#' @export
njsd_cache_remove <- function(key) {
  if (key %in% names(.njsd_cache$data)) {
    .njsd_cache$data[[key]] <- NULL
    invisible(TRUE)
  } else {
    invisible(FALSE)
  }
}

# -----------------------------------------------------------------------------
# On-Disk Workbook Cache (SPR databases)
# -----------------------------------------------------------------------------
#
# The SPR Excel databases are large (the 2024-25 District file is ~119 MB, the
# School file ~350 MB) and each holds dozens of sheets. The session cache above
# stores parsed *sheets*, so reading two different sheets from the same workbook
# -- or rerunning in a fresh session -- used to re-download the entire file.
# This disk cache stores the downloaded workbook itself, keyed by year + level,
# so a workbook is fetched from NJ DOE at most once and reused across calls and
# across sessions.

#' Directory holding cached SPR workbooks
#'
#' On-disk location where downloaded SPR Excel databases are cached. Defaults to
#' a per-user cache directory (\code{tools::R_user_dir("njschooldata", "cache")});
#' override with \code{options(njschooldata.cache_dir = "/path")}.
#'
#' @return Absolute path to the workbook cache directory (it is not created by
#'   this getter).
#' @export
#' @examples
#' njsd_workbook_cache_dir()
njsd_workbook_cache_dir <- function() {
  base <- getOption(
    "njschooldata.cache_dir",
    tools::R_user_dir("njschooldata", which = "cache")
  )
  file.path(base, "spr-workbooks")
}

#' Is a file a real .xlsx (ZIP) rather than an HTTP error / bot page?
#'
#' \code{.xlsx} files are ZIP archives and begin with the bytes \code{PK}
#' (\code{0x50 0x4B}). Error pages begin with \code{<} or are tiny. This guard
#' prevents a failed download from being cached or parsed as data.
#'
#' @param path File path to check.
#' @return \code{TRUE} if the file looks like a valid workbook.
#' @keywords internal
is_valid_xlsx <- function(path) {
  if (!file.exists(path)) return(FALSE)
  if (isTRUE(file.info(path)$size < 1000)) return(FALSE)
  con <- file(path, "rb")
  on.exit(close(con))
  sig <- readBin(con, what = "raw", n = 2L)
  length(sig) == 2L && identical(sig, as.raw(c(0x50, 0x4B)))
}

#' Download an SPR workbook, caching it on disk
#'
#' Returns a local path to the SPR Excel database for \code{end_year} /
#' \code{level}, downloading it from NJ DOE on first use and reusing the cached
#' copy thereafter. The download is validated as a real \code{.xlsx} (see
#' \code{\link{is_valid_xlsx}}) before it is cached or returned, so an HTTP error
#' or bot-protection page is never silently treated as data.
#'
#' Disk caching is on by default. Disable it with
#' \code{options(njschooldata.workbook_cache = FALSE)} or by turning off the
#' session cache (\code{\link{njsd_cache_enable}(FALSE)}); in either case the
#' workbook is downloaded to a temporary file each call.
#'
#' @param end_year SPR school year end (2017-2025).
#' @param level One of \code{"school"} or \code{"district"}.
#' @return Path to a local, validated \code{.xlsx} file.
#' @keywords internal
spr_cached_workbook <- function(end_year, level) {
  url <- get_spr_url(end_year, level)  # also validates end_year / level

  use_cache <- isTRUE(getOption("njschooldata.workbook_cache", TRUE)) &&
    njsd_cache_enabled()

  if (use_cache) {
    cache_dir <- njsd_workbook_cache_dir()
    dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
    dest <- file.path(cache_dir, sprintf("SPR_%s_%d.xlsx", level, end_year))
    if (is_valid_xlsx(dest)) {
      return(dest)
    }
    dl_dir <- cache_dir
  } else {
    dest <- tempfile(pattern = "spr_", fileext = ".xlsx")
    dl_dir <- dirname(dest)
  }

  # Download to a sibling temp file, validate, then move into place so an
  # interrupted or failed download never leaves a corrupt file in the cache.
  tmp <- tempfile(pattern = "spr_dl_", tmpdir = dl_dir, fileext = ".xlsx")
  on.exit(unlink(tmp), add = TRUE)
  downloader::download(url, destfile = tmp, mode = "wb")

  if (!is_valid_xlsx(tmp)) {
    stop(sprintf(
      paste0(
        "Downloaded SPR workbook for %d (%s) is not a valid .xlsx file -- the ",
        "NJ DOE source may be unavailable or returned an error page.\n  URL: %s"
      ),
      end_year, level, url
    ), call. = FALSE)
  }

  if (!file.rename(tmp, dest)) {
    # rename() can fail across filesystems; fall back to copy.
    file.copy(tmp, dest, overwrite = TRUE)
  }
  dest
}

#' Inspect the on-disk SPR workbook cache
#'
#' @return A data frame (one row per cached workbook) with \code{file},
#'   \code{size_mb}, and \code{modified}; returned invisibly after printing a
#'   one-line summary. Empty if nothing is cached.
#' @export
#' @seealso \code{\link{njsd_workbook_cache_clear}}, \code{\link{njsd_workbook_cache_dir}}
#' @examples
#' njsd_workbook_cache_info()
njsd_workbook_cache_info <- function() {
  cache_dir <- njsd_workbook_cache_dir()
  files <- list.files(cache_dir, pattern = "\\.xlsx$", full.names = TRUE)
  if (length(files) == 0) {
    message(sprintf("No cached SPR workbooks in %s", cache_dir))
    return(invisible(data.frame()))
  }
  info <- file.info(files)
  out <- data.frame(
    file = basename(files),
    size_mb = round(info$size / 1024 / 1024, 1),
    modified = info$mtime,
    row.names = NULL,
    stringsAsFactors = FALSE
  )
  message(sprintf(
    "%d cached SPR workbook(s), %.1f MB total, in %s",
    nrow(out), sum(out$size_mb), cache_dir
  ))
  out
}

#' Clear cached SPR workbooks from disk
#'
#' @param end_year Optional school year; clear only that year's workbooks (both
#'   levels). Default \code{NULL} removes all cached workbooks.
#' @return Number of files removed (invisibly).
#' @export
#' @seealso \code{\link{njsd_workbook_cache_info}}
#' @examples
#' \dontrun{
#' njsd_workbook_cache_clear()      # remove all
#' njsd_workbook_cache_clear(2025)  # remove just SY2024-25
#' }
njsd_workbook_cache_clear <- function(end_year = NULL) {
  cache_dir <- njsd_workbook_cache_dir()
  pattern <- if (is.null(end_year)) {
    "\\.xlsx$"
  } else {
    sprintf("_%d\\.xlsx$", end_year)
  }
  files <- list.files(cache_dir, pattern = pattern, full.names = TRUE)
  bytes <- if (length(files) > 0) sum(file.info(files)$size) else 0
  unlink(files)
  message(sprintf(
    "Removed %d cached SPR workbook(s) (%.1f MB).",
    length(files), bytes / 1024 / 1024
  ))
  invisible(length(files))
}

# -----------------------------------------------------------------------------
# Cached Fetch Wrapper
# -----------------------------------------------------------------------------

#' Create a cached version of a fetch function
#'
#' Wraps a data fetching function to use the session cache.
#'
#' @param fn The fetch function to wrap
#' @param fn_name Name of the function (for cache keys)
#' @return A cached version of the function
#' @keywords internal
with_cache <- function(fn, fn_name) {
  function(...) {
    key <- make_cache_key(fn_name, ...)

    # Try to get from cache
    cached <- cache_get(key)
    if (!is.null(cached)) {
      message(sprintf("Using cached %s data.", fn_name))
      return(cached)
    }

    # Not in cache, fetch fresh
    result <- fn(...)

    # Store in cache
    cache_set(key, result)

    result
  }
}

# -----------------------------------------------------------------------------
# Cached versions of common fetch functions
# -----------------------------------------------------------------------------

#' Fetch enrollment data with caching
#'
#' This is a cached wrapper around \code{\link{fetch_enr}}. On the first call
#' with a given set of parameters, data is downloaded from NJ DOE. Subsequent
#' calls with the same parameters return cached data instantly.
#'
#' @inheritParams fetch_enr
#' @return Enrollment data frame (from cache if available)
#' @export
#' @seealso \code{\link{fetch_enr}}, \code{\link{njsd_cache_info}}
#' @examples
#' \dontrun{
#' # First call downloads data
#' enr <- fetch_enr_cached(2024)
#'
#' # Second call returns cached data
#' enr <- fetch_enr_cached(2024)  # Instant!
#'
#' # Check cache status
#' njsd_cache_info()
#' }
fetch_enr_cached <- function(end_year, tidy = FALSE) {
  key <- make_cache_key("fetch_enr", end_year = end_year, tidy = tidy)

  cached <- cache_get(key)
  if (!is.null(cached)) {
    message("Using cached enrollment data.")
    return(cached)
  }

  # Fetch fresh
  result <- fetch_enr(end_year, tidy)

  # Cache and return
  cache_set(key, result)
  result
}
