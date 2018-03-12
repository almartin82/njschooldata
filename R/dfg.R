#' Fetch NJ District Factor Group (DFG) data
#'
#' @param revision c(2000, 1990)
#'
#' @return data.frame
#' @export

fetch_dfg <- function(revision = 2000) {
  tname <- tempfile(pattern = "dfg", tmpdir = tempdir(), fileext = ".xls")
  downloader::download('http://www.nj.gov/education/finance/rda/dfg.xls', dest = tname, mode = "wb") 
  
  df <- readxl::read_excel(path = tname) %>%
    janitor::clean_names()
  
  df <- clean_cds_fields(df)
  df$county_code <- pad_leading(df$county_code, 2)
  df$district_code <- pad_leading(df$district_code, 4)
  
  if (revision == 2000) {
    df <- df %>% 
      select(-x1990_dfg) %>%
      rename(dfg = x2000_dfg)
  } else if (revision == 1990) {
    df <- df %>% 
      select(-x2000_dfg) %>%
      rename(dfg = x1990_dfg)
  }
  
  df
}