#' Get an ESSA comprehensive or targeted accountability file
#'
#' @param end_year a school year.  end_year is the end of the academic year - eg 2016-17
#' school year is end_year 2017.  valid values are 2017
#' @param file_type 'comprehensive' or 'targeted'? 
#'
#' @return list of data frames
#' @export

get_essa_file <- function(end_year, file_type = 'comprehensive') {
  validate_end_year(end_year, "essa")
  file_type <- match.arg(file_type, c("comprehensive", "targeted"))
  target_url <- resolve_source_url(
    "essa", end_year = end_year, file_type = file_type
  )
  transport <- download_source(target_url, source_type = "xlsx")
  tmp_essa <- source_result_data(transport)
  on.exit(unlink(tmp_essa), add = TRUE)

  parsed <- transform_source_result(transport, function(path) {
    sheets_pr <- readxl::excel_sheets(path) %>%
      clean_name_vector()

    # read all the sheets
    essa_list <- map2(
      .x = seq_along(sheets_pr),
      .y = sheets_pr,
      .f = function(.x, .y) {
        df <- readxl::read_excel(path, sheet = .x) %>%
          mutate(
            end_year = end_year,
            indicator = .y
          ) %>%
          janitor::clean_names()

        pad_cds(df)
      }
    )
    names(essa_list) <- sheets_pr
    essa_list
  })
  essa_list <- source_result_data(parsed)
  
  attach_source_results(
    essa_list,
    source_result_record(parsed, "essa", end_year, file_type)
  )
}
