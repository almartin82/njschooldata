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


#' clean_id
#'
#' @description cleans district id columns(mixed numeric/character) of leading zeros
#' @param x id vector
#'
#' @return cleaned id vector
#' @export

clean_id <- function(x) {
  gsub("(^|[^0-9])0+", "\\1", x, perl = TRUE)
}


#' Clean up CDS field names
#'
#' @param df 
#'
#' @return df, with consistent county_code, district_code, school_code fields
#' @export

clean_cds_fields <- function(df) {
  names(df) <- gsub('co_code|co\\b', 'county_code', names(df))
  names(df) <- gsub('dist_code|dist\\b', 'district_code', names(df))
  names(df) <- gsub('sch_code|sch\\b', 'school_code', names(df))
  names(df) <- gsub('yr\\b', 'year', names(df))
  
  df
}


#' report card year matcher
#'
#' @param df a report card table that includes trailing/longitudinal data
#' @param end_year the correct year
#'
#' @return data frame with only data for the year of the report
#' @export

rc_year_matcher <- function(df) {
  #convert the 0708 to 2008, etc
  yy <- stringr::str_sub(df$year, 3, 4) %>% as.numeric()
  df$yy <- ifelse(yy >= 68 %% 100, 1900+yy, 2000+yy)
  
  #filter on end year
  df %>%
    filter(yy == end_year) %>%
    select(-yy)
}


clean_name_vector <- . %>%
  gsub("'", "", .) %>% 
  gsub("\"", "", .) %>% 
  gsub("%", ".percent_", .) %>% 
  gsub("#", ".number_", .) %>% 
  gsub('-', '_', .) %>%
  gsub("^[[:space:][:punct:]]+", "", .) %>% 
  make.names(.) %>% 
  snakecase::to_any_case(
    case = 'snake', 
    sep_in = "\\.",
    transliterations = c("Latin-ASCII"), parsing_option = 4
  )

