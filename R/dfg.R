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
#' @return data.frame with columns: county_id, county_name, district_id,
#'   district_name, dfg
#'
#' @references
#' \url{https://www.nj.gov/education/stateaid/dfg.shtml}
#'
#' @export
fetch_dfg <- function(revision = 2000) {
  result <- .fetch_dfg_result(revision)
  attach_source_results(
    source_result_data(result),
    source_result_record(result, "dfg", as.integer(revision))
  )
}

.fetch_dfg_result <- function(revision = 2000,
                              request_fn = .default_source_request) {
  revision_number <- suppressWarnings(as.numeric(revision))
  if (length(revision_number) != 1L || is.na(revision_number) ||
      !is.finite(revision_number) || revision_number %% 1 != 0 ||
      !revision_number %in% c(1990, 2000)) {
    stop("`revision` must be exactly 1990 or 2000.", call. = FALSE)
  }
  revision <- as.integer(revision_number)
  dfg_url <- resolve_source_url("dfg", revision = revision)
  transport <- download_source(
    dfg_url, source_type = "xlsx", request_fn = request_fn
  )
  if (!identical(transport$source_status, "actual")) return(transport)
  on.exit(unlink(transport$data), add = TRUE)

  df <- tryCatch({
    parsed <- readxl::read_excel(path = transport$data)

    # Clean column names - the source file has \r\n in headers
    names(parsed) <- gsub("\r\n", "_", names(parsed))
    parsed <- parsed %>%
      janitor::clean_names() %>%
      # Remove "End of worksheet" row and any other invalid rows
      dplyr::filter(!is.na(county_name))

    parsed <- clean_cds_fields(parsed)
    parsed <- cds_codes_to_ids(parsed)
    parsed$county_id <- pad_leading(parsed$county_id, 2)
    parsed$district_id <- pad_leading(parsed$district_id, 4)

    if (revision == 2000) {
      parsed <- parsed %>%
        dplyr::select(-x1990_dfg) %>%
        dplyr::rename(dfg = x2000_dfg)
    } else {
      parsed <- parsed %>%
        dplyr::select(-x2000_dfg) %>%
        dplyr::rename(dfg = x1990_dfg)
    }
    parsed
  }, error = identity)
  if (inherits(df, "error")) {
    return(new_source_result(
      source_status = "parse_error", source_url = transport$source_url,
      retrieved_at = transport$retrieved_at, digest = transport$digest,
      error = conditionMessage(df)
    ))
  }

  new_source_result(
    data = df, source_status = "actual", source_url = transport$source_url,
    retrieved_at = transport$retrieved_at, digest = transport$digest
  )
}
