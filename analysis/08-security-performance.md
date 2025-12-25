# Security and Performance Analysis

## Security Considerations

### 1. Hardcoded URLs

**Current State**: URLs are scattered throughout the codebase

```r
# enr.R:31-33
enr_url <- paste0(
  "https://www.nj.gov/education/doedata/enr/", enr_folder, "/", enr_filename
)

# parcc.R:31
stem <- 'https://www.nj.gov/education/assessment/results/reports/'

# grate.R:448
grd_constant <- "https://www.state.nj.us/education/data/grd/grd"

# directory.R:8
dir_url = "https://homeroom4.doe.state.nj.us/public/districtpublicschools/download/"
```

**Risk Level**: Low
- All URLs are to official NJ government sites
- No API keys or secrets involved
- However, URL changes can break the package silently

**Recommendation**:
Create a centralized configuration:
```r
# R/urls.R
nj_doe_urls <- list(
  enrollment = "https://www.nj.gov/education/doedata/enr/",
  assessment = "https://www.nj.gov/education/assessment/results/reports/",
  graduation = "https://www.nj.gov/education/schoolperformance/grad/data/",
  directory = "https://homeroom4.doe.state.nj.us/public/"
)
```

### 2. Input Sanitization

**Current State**: Minimal input validation

```r
# No validation example (enr.R)
get_raw_enr <- function(end_year) {
  # end_year is used directly in URL construction
  yy <- substr(end_year, 3, 4)  # Could fail with bad input
  ...
}
```

**Potential Issues**:
- Non-numeric `end_year` could cause cryptic errors
- Values outside valid range download non-existent files
- No protection against injection (though URLs are to .gov sites)

**Recommendation**:
Add validation layer:
```r
validate_end_year <- function(end_year, min_year, max_year, data_type) {
  if (!is.numeric(end_year) || length(end_year) != 1) {
    stop(sprintf("%s: end_year must be a single numeric value", data_type))
  }
  if (end_year < min_year || end_year > max_year) {
    stop(sprintf("%s: end_year must be between %d and %d",
                 data_type, min_year, max_year))
  }
  invisible(TRUE)
}
```

### 3. Downloaded File Handling

**Current State**: Files are downloaded to temp directories

```r
# enr.R:36-40
tname <- tempfile(pattern = "enr", tmpdir = tempdir(), fileext = ".zip")
tdir <- tempdir()
downloader::download(enr_url, dest = tname, mode = "wb")
utils::unzip(tname, exdir = tdir)
```

**Security Assessment**:
- [x] Uses `tempfile()` - good, prevents predictable paths
- [x] Uses `tempdir()` - good, OS-managed temp space
- [ ] No cleanup after use - temp files may accumulate
- [ ] No file integrity checks

**Recommendations**:
1. Add `on.exit()` cleanup:
```r
get_raw_enr <- function(end_year) {
  tname <- tempfile(pattern = "enr", tmpdir = tempdir(), fileext = ".zip")
  on.exit(unlink(tname), add = TRUE)
  ...
}
```

2. Consider file size limits for safety:
```r
if (file.size(tname) > 100 * 1024 * 1024) {  # 100MB limit
  stop("Downloaded file exceeds expected size limit")
}
```

### 4. Error Message Information Disclosure

**Current State**: Some error messages might reveal internal details

```r
# Example that could be improved
stop("read_fwf and readlines don't agree on size of df.  probably a layout error.")
```

**Assessment**: Low risk for this package (educational data, not sensitive)

### 5. Dependency Security

**Current Vulnerabilities**: None known in current dependencies

**Recommendation**: Add GitHub Dependabot for security alerts
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

## Performance Analysis

### 1. Network Performance

**Current State**: Synchronous downloads, one file at a time

```r
# Typical pattern
downloader::download(url, dest = tname, mode = "wb")
```

**Performance Impact**:
- `fetch_all_parcc()` downloads 50+ files sequentially
- Each file requires a separate HTTP connection
- Total time: 10+ minutes for full dataset

**Recommendations**:

1. **Add progress indicators**:
```r
fetch_all_parcc <- function(verbose = TRUE) {
  if (verbose) {
    pb <- progress::progress_bar$new(
      total = length(all_combinations),
      format = "  downloading [:bar] :percent eta: :eta"
    )
  }
  ...
}
```

2. **Consider parallel downloads** (for batch operations):
```r
# Using future + furrr for parallel downloads
future::plan(future::multisession, workers = 4)
results <- furrr::future_map(years, ~fetch_enr(.x))
```

3. **Add connection timeout and retry**:
```r
safe_download <- function(url, dest, retries = 3, timeout = 60) {
  for (i in seq_len(retries)) {
    tryCatch({
      downloader::download(url, dest, mode = "wb",
                          extra = sprintf("--connect-timeout %d", timeout))
      return(invisible(TRUE))
    }, error = function(e) {
      if (i == retries) stop(e)
      Sys.sleep(2^i)  # Exponential backoff
    })
  }
}
```

### 2. Caching Strategies

**Current State**: No caching - data re-downloaded every call

**Impact**:
- Repeated calls waste bandwidth
- NJ DOE servers receive unnecessary load
- Users wait unnecessarily

**Recommendations**:

1. **Session-level caching**:
```r
.njschooldata_cache <- new.env(parent = emptyenv())

fetch_enr_cached <- function(end_year, tidy = FALSE) {
  cache_key <- paste0("enr_", end_year, "_", tidy)

  if (exists(cache_key, envir = .njschooldata_cache)) {
    return(get(cache_key, envir = .njschooldata_cache))
  }

  result <- fetch_enr(end_year, tidy)
  assign(cache_key, result, envir = .njschooldata_cache)
  result
}
```

2. **Disk caching with memoise**:
```r
# Add memoise to Suggests
fetch_enr_memoised <- memoise::memoise(
  fetch_enr,
  cache = memoise::cache_filesystem("~/.njschooldata_cache")
)
```

3. **User-controlled caching**:
```r
fetch_enr <- function(end_year, tidy = FALSE, cache = TRUE,
                      cache_dir = NULL) {
  if (cache) {
    cache_dir <- cache_dir %||% rappdirs::user_cache_dir("njschooldata")
    cache_file <- file.path(cache_dir,
                           sprintf("enr_%d_%s.rds", end_year, tidy))

    if (file.exists(cache_file)) {
      cache_age <- difftime(Sys.time(), file.mtime(cache_file), units = "days")
      if (cache_age < 30) {  # Cache valid for 30 days
        return(readRDS(cache_file))
      }
    }
  }

  result <- # ... fetch data ...

  if (cache) {
    dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
    saveRDS(result, cache_file)
  }

  result
}
```

### 3. Memory Efficiency

**Current State**: Data frames loaded entirely into memory

**Analysis of Large Operations**:
```r
# fetch_all_parcc() creates 50+ data frames then binds
parcc_results <- list()
for (i in ...) {
  parcc_results[[key]] <- fetch_parcc(...)
}
dplyr::bind_rows(parcc_results)  # Large memory spike here
```

**Potential Issues**:
- Memory spikes during binding
- No streaming for very large datasets
- Full data retained even when filtering

**Recommendations**:

1. **Use data.table for large binds** (optional):
```r
# data.table::rbindlist is faster and more memory-efficient
data.table::rbindlist(parcc_results)
```

2. **Garbage collection hints**:
```r
fetch_all_parcc <- function() {
  results <- list()
  for (...) {
    results[[key]] <- fetch_parcc(...)
    if (length(results) %% 10 == 0) gc()  # Periodic cleanup
  }
  bind_rows(results)
}
```

3. **Consider arrow/parquet for archival** (future enhancement):
```r
# For users who want to save all data
arrow::write_parquet(all_data, "nj_school_data.parquet")
```

### 4. Timeout Handling

**Current State**: No explicit timeouts

```r
# downloader::download uses defaults
# httr::GET uses defaults
```

**Risk**: Hanging connections on slow/unresponsive server

**Recommendation**:
```r
# Set reasonable timeouts
httr::GET(url, httr::timeout(120))  # 2 minute timeout

# Or globally
httr::set_config(httr::timeout(120))
```

### 5. Retry Logic

**Current State**: No retry on transient failures

**Recommendation**:
```r
retry_download <- function(url, dest, max_retries = 3) {
  for (attempt in seq_len(max_retries)) {
    result <- tryCatch({
      downloader::download(url, dest, mode = "wb")
      return(TRUE)
    }, error = function(e) {
      if (attempt < max_retries) {
        message(sprintf("Attempt %d failed, retrying...", attempt))
        Sys.sleep(2^attempt)  # Exponential backoff
        return(FALSE)
      } else {
        stop(sprintf("Failed after %d attempts: %s", max_retries, e$message))
      }
    })
    if (result) break
  }
}
```

### 6. Rate Limiting

**Current State**: No rate limiting

**Consideration**:
- NJ DOE is a government site
- No documented rate limits
- But courtesy delays are good practice for batch operations

**Recommendation**:
```r
fetch_all_parcc <- function(delay = 0.5) {
  for (...) {
    result <- fetch_parcc(...)
    Sys.sleep(delay)  # Be nice to the server
  }
}
```

## Performance Benchmarks (Estimated)

| Operation | Current Time | With Caching | With Parallel |
|-----------|-------------|--------------|---------------|
| `fetch_enr(2023)` | 3-5s | <0.1s (cached) | N/A |
| `fetch_all_parcc()` | 10-15 min | <1s (cached) | 3-4 min |
| `map(2000:2023, fetch_enr)` | 2-3 min | <1s (cached) | 30-45s |

## Summary Recommendations

### Security (Priority Order)
1. Add input validation to all exported functions
2. Implement proper temp file cleanup
3. Centralize URL configuration
4. Add timeout handling

### Performance (Priority Order)
1. Add session-level caching (low effort, high impact)
2. Add progress indicators for batch operations
3. Implement retry logic with exponential backoff
4. Consider disk caching option for power users
5. Add parallel download option for batch operations

### Implementation Plan

**Phase 1 (Critical)**:
- Input validation
- Timeout handling
- Temp file cleanup

**Phase 2 (High Value)**:
- Session caching
- Progress indicators
- Retry logic

**Phase 3 (Enhancement)**:
- Disk caching
- Parallel downloads
- Rate limiting
