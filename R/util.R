#' Trim whitespace
#' 
#' @param x string or vector of strings
#' @return a string or vector of strings, with whitespace removed.
#' @export

trim_whitespace <- function (x) gsub("^\\s+|\\s+$", "", x)


#' Parse PARCC subject
#'
#' @param x a subject (function parameter subj)
#' @return the subject coded as ELA or MAT.
#' @export

parse_parcc_subj <- function(x) {
  x <- tolower(x)
  
  if (x == 'ela') {
    'ELA'
  } else if (x == 'math') {
    'MAT'
  } else if (x == 'Reading') {
    'ELA'
  } else {
    stop('Not a valid subject.  Check the function documentation for valid subjects.')
  }
}


#' Pad grade level
#'
#' @param x a grade level argument, length 1
#' @return a string, length 2, with appropriate padding for PARCC naming conventions
#' @export

pad_grade <- function(x) {
  x <- as.character(x)
  
  if (nchar(x) == 1) {
    paste0('0', x)
  } else {
    x
  }
}
