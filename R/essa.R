#' Get the ESSA comprehensive file
#'
#' @param end_year a school year.  end_year is the end of the academic year - eg 2016-17
#' school year is end_year 2017.  valid values are 2017
#'
#' @return list of data frames
#' @export

get_essa_comprehensive_file <- function(end_year) {
  essa_urls <- list(
    "2017" = "http://www.state.nj.us/education/title1/accountability/progress/17/public_comprehensivefile.xlsx"
  )
  tmp_essa = tempfile(fileext = '.xlsx')
  
  download.file(url = essa_urls[[as.character(end_year)]], destfile = tmp_essa, mode = "wb")
  
  sheets_pr <- readxl::excel_sheets(tmp_essa) %>%
    clean_name_vector()
  
  #read all the sheets
  essa_list <- map2(
    .x = c(1:length(sheets_pr)),
    .y = sheets_pr,
    .f = function(.x, .y) {
      df <- readxl::read_excel(tmp_essa, sheet = .x) %>%
        mutate(
          end_year = end_year,
          indicator = .y
        ) %>%
        janitor::clean_names()
      
      df <- pad_cds(df)
      
      df
    }
  )
  
  names(essa_list) <- sheets_pr
  
  essa_list
}