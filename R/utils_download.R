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
  tname <- tempfile(pattern = file_pattern, tmpdir = tempdir())
  tdir <- tempdir()
  downloader::download(url, dest = tname, mode = "wb")
  unzip_loc <- paste0(tempfile(pattern = "subfolder"))
  dir.create(unzip_loc)
  utils::unzip(tname, exdir = unzip_loc)
  new_files <- utils::unzip(tname, exdir = ".", list = TRUE)
  closeAllConnections()

  paste(unzip_loc, new_files$Name, sep = "/")
}
