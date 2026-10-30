# Read complete NJDOE releases declared in the existing v1 artifact manifest.
# A private copy protects installed bytes from legacy parsers' unlink() calls.
.package_source <- function(url, source_type) {
  root <- system.file("extdata", "source-contract", "contracts",
                      "new_jersey_shipped_sources", package = "njschooldata")
  manifest <- jsonlite::read_json(file.path(root, "artifact-manifest.json"))
  matches <- Filter(function(x) identical(x$source_identity$url, url),
                    manifest$artifacts)
  if (!length(matches)) return(NULL)
  if (length(matches) != 1L) stop("Ambiguous package source: ", url)
  artifact <- matches[[1]]
  relative <- sub("^inst/", "", artifact$storage$path)
  path <- system.file(relative, package = "njschooldata")
  if (!nzchar(path) || !file.exists(path) ||
      file.info(path)$size != artifact$byte_length ||
      !identical(.source_digest(path), artifact$sha256)) {
    stop("Package source length or SHA-256 mismatch: ", url, call. = FALSE)
  }
  .validate_source_file(path, source_type)
  copy <- tempfile("njschooldata-source-", fileext = paste0(".", source_type))
  if (!file.copy(path, copy)) stop("Cannot copy package source: ", url)
  result <- new_source_result(
    data = copy, source_status = "actual", source_url = url,
    retrieved_at = as.POSIXct(artifact$source_identity$retrieved_at, tz = "UTC"),
    digest = artifact$sha256
  )
  result$release <- function() unlink(copy)
  result
}
