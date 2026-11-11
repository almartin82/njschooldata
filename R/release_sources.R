# ==============================================================================
# Historical NJ DOE source files served from this package's GitHub release
# ==============================================================================
#
# Point-in-time NJ DOE publications (SPR databases, fall enrollment zips, ACGR
# files, spending guides, state aid, IDEA 618 files, grade 4 ELA results) are
# held as immutable assets of the releases pinned in the manifest. The
# new_jersey_release_sources contract names each one by its original nj.gov
# URL, byte length and SHA-256. The vendored resolver (R/resolve_historical_asset.R)
# downloads an asset into the shared source store, checks length and SHA-256
# before every read, and stops with a typed error when an asset is missing or
# altered. A held URL never falls through to a live nj.gov request; URLs the
# contract does not name keep their existing path.

.nj_release <- new.env(parent = emptyenv())
.nj_release_repository <- "almartin82/njschooldata"

.nj_release_documents <- function() {
  if (!is.null(.nj_release$documents)) return(.nj_release$documents)
  root <- system.file("extdata", "source-contract", "contracts",
                      "new_jersey_release_sources", package = "njschooldata")
  if (!nzchar(root)) return(NULL)
  read <- function(name) jsonlite::read_json(file.path(root, name), simplifyVector = FALSE)
  documents <- list(contract = read("contract.json"), manifest = read("artifact-manifest.json"))
  .historical_validate(documents$contract, documents$manifest, .nj_release_repository)
  urls <- vapply(documents$manifest$artifacts, `[[`, "", "source_identity")
  if (anyDuplicated(urls)) stop("Release source contract names a URL twice.", call. = FALSE)
  documents$by_url <- setNames(documents$manifest$artifacts, urls)
  .nj_release$documents <- documents
  documents
}

# The held artifact for a publisher URL, or NULL when the contract does not name it.
# options(njschooldata.release_sources = FALSE) opts out explicitly and keeps
# the pre-release path (the offline suite does this so injected transports stay
# in charge); a failure with the option on is never retried against nj.gov.
.nj_release_lookup <- function(url) {
  if (!isTRUE(getOption("njschooldata.release_sources", TRUE))) return(NULL)
  documents <- .nj_release_documents()
  if (is.null(documents) || !is.character(url) || length(url) != 1L || is.na(url)) return(NULL)
  documents$by_url[[url]]
}

.nj_release_root <- function() {
  # An explicitly seeded shared root wins; a package cache override gets its own subfolder.
  if (nzchar(Sys.getenv("STATE_SCHOOLDATA_HISTORICAL_ROOT", ""))) return(NULL)
  if (!is.null(.njsd_cache_override())) {
    return(njsd_cache_subdir("historical-assets-v1"))
  }
  NULL
}

.nj_release_offline <- function() {
  identical(Sys.getenv("EGRESS_BOUNDARY"), "1") ||
    tolower(Sys.getenv("NJSCHOOLDATA_OFFLINE")) %in% c("true", "yes", "1")
}

# Typed failure: a missing or tampered source is never turned into empty data,
# and never into a request to nj.gov.
.nj_release_call <- function(action) {
  tryCatch(action(), historical_error = function(e) {
    class(e) <- unique(c(paste0("njschooldata_", class(e)[[1L]]),
                         "njschooldata_source_error", class(e)))
    stop(e)
  })
}

# Copy one verified asset to `destination`. Always a real copy: a hard link
# would let a reader that rewrites its file in place alter the store blob.
.nj_release_materialize <- function(artifact, destination,
                                    root = .nj_release_root(),
                                    offline = .nj_release_offline(),
                                    .transport = NULL) {
  documents <- .nj_release_documents()
  selection <- historical_select(
    documents$contract, documents$manifest, "nj_release_source",
    list(family = artifact$selectors$family, file_id = artifact$artifact_id),
    .nj_release_repository
  )
  .nj_release_call(function() {
    historical_with_assets(selection, function(paths, workspace) {
      blob <- paths[[artifact$artifact_id]]
      if (file.exists(destination)) unlink(destination)
      if (!file.copy(blob, destination)) {
        .historical_error("store", paste("Cannot copy release asset:", artifact$artifact_id))
      }
      invisible(destination)
    }, root = root, offline = offline, .transport = .transport)
  })
}

# download_source() hook: an njsd_source_result for a held URL, else NULL.
.release_source <- function(url, source_type, .transport = NULL) {
  artifact <- .nj_release_lookup(url)
  if (is.null(artifact)) return(NULL)
  copy <- tempfile("njschooldata-release-", fileext = paste0(".", source_type))
  .nj_release_materialize(artifact, copy, .transport = .transport)
  .validate_source_file(copy, source_type)
  publisher <- artifact$publisher_identity
  result <- new_source_result(
    data = copy, source_status = "actual", source_url = url,
    retrieved_at = as.POSIXct(publisher$retrieved_at, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC"),
    digest = artifact$sha256,
    warning = "Verified NJ DOE file served from the package's release assets."
  )
  result$requested_url <- url
  result$ownership <- "temporary"
  result$release <- function() unlink(copy)
  result
}

# downloader::download() stand-in for readers that write to a destination path.
# Returns TRUE when the URL is held (and `destfile` now holds verified bytes).
.release_download_to <- function(url, destfile) {
  artifact <- .nj_release_lookup(url)
  if (is.null(artifact)) return(FALSE)
  .nj_release_materialize(artifact, destfile)
  TRUE
}
