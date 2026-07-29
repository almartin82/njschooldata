# ==============================================================================
# Download Utility Functions
# ==============================================================================
#
# Functions for downloading and unzipping files from remote sources.
#
# ==============================================================================

#' Download and unzip a file from URL
#'
#' Downloads a zip file from a URL to a temporary location and extracts it.
#'
#' @param url character, target url
#' @param file_pattern character, stub to use for temporary file
#'
#' @return list of unzipped files in a temp directory
#' @keywords internal
unzipper <- function(url, file_pattern = "njschooldata") {
  transport <- download_source(url, source_type = "zip")
  tname <- source_result_data(transport)
  on.exit(unlink(tname), add = TRUE)
  unzip_loc <- tempfile(pattern = paste0(file_pattern, "-unpack-"))
  dir.create(unzip_loc)
  utils::unzip(tname, exdir = unzip_loc)
  new_files <- utils::unzip(tname, list = TRUE)

  file.path(unzip_loc, new_files$Name)
}
