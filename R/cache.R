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
