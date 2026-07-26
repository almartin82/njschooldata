html_escape <- function(x) {
  x <- as.character(x)
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  gsub("'", "&#39;", x, fixed = TRUE)
}

safe_http_url <- function(x) {
  if (is.null(x) || length(x) != 1L || is.na(x)) return(NA_character_)
  x <- trimws(as.character(x))
  if (!nzchar(x) || grepl("[[:cntrl:]]", x)) return(NA_character_)
  parsed <- tryCatch(httr::parse_url(x), error = function(e) NULL)
  if (is.null(parsed)) return(NA_character_)
  scheme <- if (is.null(parsed$scheme)) "" else tolower(parsed$scheme)
  hostname <- if (is.null(parsed$hostname)) "" else parsed$hostname
  if (!scheme %in% c("http", "https") || !nzchar(hostname)) {
    return(NA_character_)
  }
  x
}

safe_profile_id <- function(x) {
  x <- as.character(x)
  if (length(x) != 1L || is.na(x) || !grepl("^[A-Za-z0-9_-]+$", x)) {
    stop("Unsafe district identifier cannot be used as a filename: ", x,
         call. = FALSE)
  }
  x
}

yaml_scalar <- function(x) {
  as.character(jsonlite::toJSON(
    as.character(x), auto_unbox = TRUE, na = "null"
  ))
}

safe_profile_href <- function(id, prefix = "") {
  id <- safe_profile_id(id)
  paste0(prefix, utils::URLencode(id, reserved = TRUE), ".html")
}
