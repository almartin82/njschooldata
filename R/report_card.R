
#' Get Raw Report Card Database
#'
#' @param end_year a school year.  end_year is the end of the academic year - eg 2014-15
#' school year is end_year '2015'.  valid values are 2003 to 2017
#'
#' @return list of data frames
#' @export

get_raw_rc_database <- function(end_year) {
  
  pr_urls <- list(
    "2017" = "https://rc.doe.state.nj.us/ReportsDatabase/PerformanceReports.xlsx",
    "2016" = "https://rc.doe.state.nj.us/ReportsDatabase/15-16/PerformanceReports.xlsx",
    "2015" = "http://www.nj.gov/education/pr/1415/database/2015PRDATABASE.xlsx",
    "2014" = "http://www.nj.gov/education/pr/1314/database/2014%20performance%20report%20database.xlsx",
    "2013" = "http://www.nj.gov/education/pr/1213/database/nj%20pr13%20database.xlsx",
    "2012" = "http://www.nj.gov/education/pr/2013/database/nj%20pr12%20database.xlsx",
    "2011" = "http://www.nj.gov/education/reportcard/2011/database/RC11%20database.xls",
    "2010" = "http://www.nj.gov/education/reportcard/2010/database/RC10%20database.xls",
    "2009" = "http://www.nj.gov/education/reportcard/2009/database/RC09%20database.xls",
    "2008" = "http://www.nj.gov/education/reportcard/2008/database/nj_rc08.xls",
    "2007" = "http://www.nj.gov/education/reportcard/2007/database/nj_rc07.xls",
    "2006" = "http://www.nj.gov/education/reportcard/2006/database/nj_rc06_data.xls",
    "2005" = "http://www.nj.gov/education/reportcard/2005/database/NJ_RC05_DATA.XLS",
    "2004" = "http://www.nj.gov/education/reportcard/2004/database/nj_rc04_data.xls",
    "2003" = "http://www.nj.gov/education/reportcard/2003/database/nj_rc03_data.xls"
  )
  
  #temp file for downloading
  file_exts <- c(
    rep('xlsx', 6),
    rep('xls', 9)
  )
  tmp_pr = tempfile(fileext = paste0('.', file_exts[1 + (2017-end_year)]))
  
  #download to temp
  download.file(url = pr_urls[[as.character(end_year)]], destfile = tmp_pr, mode = "wb")
  
  #get the sheet names
  sheets_pr <- readxl::excel_sheets(tmp_pr) %>%
    clean_name_vector()
  
  #get all the data.frames as list
  pr_list <- map(
    .x = c(1:length(sheets_pr)),
    .f = function(.x) {
      readxl::read_excel(tmp_pr, sheet = .x) %>%
        mutate(end_year = end_year) %>%
        janitor::clean_names()
    }
  )
  
  #rename each pr
  names(pr_list) <- sheets_pr
  
  pr_list
}
