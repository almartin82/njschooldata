#' Get an ESSA comprehensive or targeted accountability file
#'
#' @param end_year a school year.  end_year is the end of the academic year - eg 2016-17
#' school year is end_year 2017.  valid values are 2017
#' @param file_type 'comprehensive' or 'targeted'? 
#'
#' @return list of data frames
#' @export

get_essa_file <- function(end_year, file_type = 'comprehensive') {
  essa_urls <- list(
    "comprehensive_2017" = "http://www.state.nj.us/education/title1/accountability/progress/17/public_comprehensivefile.xlsx",
    "targeted_2017" = "http://www.state.nj.us/education/title1/accountability/progress/17/public_targetfile.xlsx"
  )
  target_url <- essa_urls[[paste(file_type, as.character(end_year), sep = '_')]]
  
  tmp_essa = tempfile(fileext = '.xlsx')
  download.file(url = target_url, destfile = tmp_essa, mode = "wb")
  
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