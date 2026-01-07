#' Fetch NJ District Factor Group (DFG) data
#'
#' @description Downloads DFG classification data from NJ DOE. DFGs group
#' districts by socioeconomic status for comparison purposes. DFG A represents
#' the highest-need communities; DFG J represents the lowest-need.
#'
#' Note: DFGs were last updated using 2000 Census data and are no longer
#' maintained by NJ DOE, but remain useful for peer comparisons.
#'
#' @param revision c(2000, 1990) Which census revision to use. Default 2000.
#'
#' @return data.frame with columns: county_code, county_name, district_code,
#'   district_name, dfg
#'
#' @references
#' \url{https://www.nj.gov/education/stateaid/dfg.shtml}
#'
#' @export
fetch_dfg <- function(revision = 2000) {
  # URL updated Dec 2025 - old URL was http://www.nj.gov/education/finance/rda/dfg.xls
  dfg_url <- "https://www.nj.gov/education/stateaid/docs/DFG2000.xlsx"

  tname <- tempfile(pattern = "dfg", tmpdir = tempdir(), fileext = ".xlsx")
  utils::download.file(dfg_url, destfile = tname, mode = "wb", quiet = TRUE)

  df <- readxl::read_excel(path = tname)

  # Clean column names - the source file has \r\n in headers
  names(df) <- gsub("\r\n", "_", names(df))
  df <- df %>%
    janitor::clean_names() %>%
    # Remove "End of worksheet" row and any other invalid rows
    dplyr::filter(!is.na(county_name))

  df <- clean_cds_fields(df)
  df$county_code <- pad_leading(df$county_code, 2)
  df$district_code <- pad_leading(df$district_code, 4)

  if (revision == 2000) {
    df <- df %>%
      dplyr::select(-x1990_dfg) %>%
      dplyr::rename(dfg = x2000_dfg)
  } else if (revision == 1990) {
    df <- df %>%
      dplyr::select(-x2000_dfg) %>%
      dplyr::rename(dfg = x1990_dfg)
  }

  df
}