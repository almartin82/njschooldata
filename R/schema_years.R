# Sheet coverage is shared by the fetcher guards and schema tests.
spr_supported_years <- function(fetcher) {
  minimum <- switch(fetcher,
    essa_status = 2019L,
    teacher_experience = 2019L,
    cte_participation = 2019L,
    stop("Unknown SPR coverage declaration: ", fetcher, call. = FALSE)
  )
  years <- get_source_years("spr")
  years[years >= minimum]
}

spr_check_supported_year <- function(end_year, fetcher) {
  years <- spr_supported_years(fetcher)
  if (!end_year %in% years) {
    stop(fetcher, " sheet is not published for end_year ", end_year,
         ". Supported years: ", paste(years, collapse = ", "), call. = FALSE)
  }
}
