.nj_year_fetchers <- c(
  enrollment = "fetch_enr", absence = "fetch_absence",
  assessment = "fetch_parcc", graduation = "fetch_grad_rate",
  finance = "fetch_finance", sped = "fetch_sped", ell = "fetch_ell",
  staff = "fetch_staff_demographics", facilities = "fetch_facilities",
  facility_gis = "fetch_facility_gis", directory = "fetch_directory"
)

# Only verified families enter the coverage table in this wave.
.nj_live_years <- function() list(
  enrollment = get_source_years("enrollment"),
  graduation = .nj_grad_live_years,
  finance = .nj_finance_live_years
)

.nj_available_years_coverage <- function() {
  live <- .nj_live_years()
  rows <- lapply(names(live), function(type) {
    fetcher <- .nj_year_fetchers[[type]]
    # These fetchers have no package-source mode; their guards and source
    # registry own coverage.
    years <- sort(unique(as.integer(live[[type]])))
    data.frame(type = type, end_year = years,
               mode = "live",
               fetcher = fetcher, stringsAsFactors = FALSE)
  })
  coverage <- do.call(rbind, rows)
  coverage[order(coverage$type, coverage$end_year), , drop = FALSE]
}

#' Get available end years under default selectors
#'
#' Reports years served by a type's fetcher with `source = "live"` or
#' `source = "package"`, and all other selectors at their defaults. Coverage
#' is computed offline from the declarations the fetchers enforce. Years
#' requiring non-default selectors or private stores are excluded.
#'
#' Enrollment, graduation, and finance coverage is declared.
#' Absence cannot yet be verified against the source cache.
#' Assessment requires explicit grade/course and subject selectors and remains
#' undeclared. Other known fetch families
#' raise an error containing "coverage not yet declared".
#'
#' @param type A single fetch family name, such as `"enrollment"`, or `NULL`
#'   for all declared types.
#' @return With `type`, a sorted, unique integer vector of school year ends.
#'   With `NULL`, a data frame with columns `type`, `end_year`, and `fetcher`,
#'   ordered by type and year. Gaps in coverage remain visible.
#' @export
#' @examples
#' get_available_years("enrollment")
#' get_available_years()
#' coverage <- get_available_years()
#' subset(coverage, end_year == max(end_year))
get_available_years <- function(type = NULL) {
  coverage <- .nj_available_years_coverage()
  declared <- sort(unique(coverage$type))
  if (is.null(type)) return(coverage[c("type", "end_year", "fetcher")])
  if (!is.character(type) || length(type) != 1L || is.na(type) ||
      !type %in% names(.nj_year_fetchers)) {
    stop("Unknown type. Declared types: ", paste(declared, collapse = ", "),
         call. = FALSE)
  }
  if (!type %in% declared) {
    stop(type, ": coverage not yet declared", call. = FALSE)
  }
  coverage$end_year[coverage$type == type]
}
