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


#' Clean up CDS field names
#'
#' @param df data frame with county, district and school variables
#' @param tges if run in the taxpayers guide to ed spending (tges) mode, 
#' 'district' resolves to district code.  defaults to FALSE.
#'
#' @return df, with consistent county_code, district_code, school_code fields
#' @export

clean_cds_fields <- function(df, tges=FALSE) {
  names(df) <- gsub('co_code|co\\b', 'county_code', names(df))
  names(df) <- gsub('dist_code|dist\\b', 'district_code', names(df))
  names(df) <- gsub('sch_code|sch\\b', 'school_code', names(df))
  
  names(df) <- gsub('co_name|coname|county$', 'county_name', names(df))
  names(df) <- gsub('dist_name|dis_name|distname', 'district_name', names(df))
  names(df) <- gsub('sch_name', 'school_name', names(df))
  
  if (tges) {
    names(df) <- gsub('district$', 'district_code', names(df))
  } else {
    names(df) <- gsub('district$', 'district_name', names(df))
  }
  
  names(df) <- gsub('yr\\b', 'year', names(df))
  
  df
}


#' pad leading digits
#'
#' @param vector character vector
#' @param digits ensure exactly this many digits by leading zero-padding
#'
#' @return character vector
#' @export

pad_leading <- function(vector, digits) {
  sprintf(paste0("%0", digits, "d"), as.numeric(vector))
}


#' pad cds fields
#'
#' @param df containing county_code, district_code, school_code
#'
#' @return data frame with zero padded cds columns
#' @export

pad_cds <- function(df) {
  df %>%
    mutate(
      county_code = pad_leading(county_code, 2),
      district_code = pad_leading(district_code, 4),
      school_code = pad_leading(school_code, 3)
    )
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


clean_name_vector <- function(x) {
  x <- gsub("'", "", x)
  x <- gsub("\"", "", x)
  x <- gsub("%", ".percent_", x)
  x <- gsub("#", ".number_", x)
  x <- gsub('-', '_', x)
  x <- gsub("^[[:space:][:punct:]]+", "", x)
  x <- make.names(x)
  snakecase::to_any_case(
    x,
    case = 'snake',
    sep_in = "\\.",
    transliterations = c("Latin-ASCII"), parsing_option = 3
  )
}


#' Report Card Numeric Data Cleaner
#'
#' @param data_vector vector of data that has percent signs, supression codes, or 
#' a variety of representations of N/A
#'
#' @return numeric vector
#' @export

rc_numeric_cleaner <- function(data_vector) {
  data_vector <- gsub('%', '', data_vector, fixed = TRUE)
  data_vector <- gsub('*', NA_character_, data_vector, fixed = TRUE)
  data_vector <- gsub('N', NA_character_, data_vector, fixed = TRUE)
  data_vector <- gsub('N/A', NA_character_, data_vector, fixed = TRUE)
  
  data_vector %>% as.numeric()
}


#' Percentile Rank
#'
#' @param x vector of values
#' @param xo target value
#'
#' @return numeric percentile rank
#' @export

percentile_rank <- function(x, xo) {
  length(x[x <= xo]) / length(x) * 100
}


#' Peek at a data frame
#'
#' @param df data.frame
#' @param nrows how many rows to sample
#'
#' @return prints random sample of nrows of a dataframe
#' @export

peek <- function(df, nrows = 5) {
  df %>%
  ungroup() %>% 
  sample_n(nrows) %>% 
  print.AsIs()
}


#' Wrapper to download a file from a url and unzip
#'
#' @param url character, target url
#' @param file_pattern charcter, stub to use for temporary file
#'
#' @return list of unzipped files in a temp directory

unzipper <- function(url, file_pattern = 'njschooldata') {
  tname <- tempfile(pattern = file_pattern, tmpdir = tempdir())
  tdir <- tempdir()
  downloader::download(url, dest = tname, mode = "wb")
  unzip_loc <- paste0(tempfile(pattern = 'subfolder'))
  dir.create(unzip_loc)
  utils::unzip(tname, exdir = unzip_loc)
  new_files <- utils::unzip(tname, exdir = ".", list = TRUE)
  closeAllConnections()
  
  paste(unzip_loc, new_files$Name, sep = '/')
}


#' Truncate with configurable precision
#'
#' @param x numeric vector
#' @param prec desired precision
#'
#' @return truncated numeric vector
#' @export

trunc2 <- function(x, prec = 0) {
  base::trunc(x * 10^prec) / 10^prec
}


#' Kill Excel Formula Padding For Numeric Strings
#'
#' @param x a vector with strings entered as formulas - eg =\"01\"
#'
#' @return a vector with normalized strings
#' @export

kill_padformulas <- function(x) {
  gsub('="', '', x, fixed=TRUE) %>%
    gsub('"', "", ., fixed=TRUE)
}
