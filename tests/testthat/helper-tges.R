# ==============================================================================
# Shared fixtures for the Taxpayers' Guide to Educational Spending (TGES) tests
# ==============================================================================
#
# TGES zips are re-downloaded on every fetch, so memoize the raw and tidy results
# per year: the whole live suite then costs one download per year instead of one
# per test.
#
# Representative years span every code path:
#   2024-2025  per-year bundle URL (docs/{year}/TGES{nn}_Zipped.zip)
#   2011-2023  docs/{year}_TGES.zip, "rank|out_of" rank format, 4-digit personnel
#              codes (strat0016 / strat0116)
#   2004-2010  docs/{year}_CSG.zip (Comparative Spending Guide), rrk/srk personnel
#   2001-2003  year_variable_converter path; 2001/2002 DBF "rk" budget ranks;
#              2003 "rk{yy}_{col}" personnel ranks
# ==============================================================================

tges_years_live <- c(2025, 2024, 2020, 2015, 2011, 2010, 2004, 2003, 2001)

# Budget indicators tidied by tidy_generic_budget_indicator() -> 3-year window.
# CSG14 reshapes the same way (3 years) even though its value is a salary share.
tges_budget_tables <- c(
  "CSG1", "CSG2", "CSG3", "CSG4", "CSG5", "CSG6", "CSG7",
  "CSG8", "CSG8A", "CSG9", "CSG10", "CSG11", "CSG12", "CSG13", "CSG14", "CSG15"
)

# Personnel ratio/salary indicators tidied by tidy_generic_personnel() -> 2 years
tges_personnel_tables <- c("CSG16", "CSG17", "CSG18", "CSG19")

# Memoization caches (one network download per year for the whole suite)
.tges_raw_cache <- new.env(parent = emptyenv())
.tges_tidy_cache <- new.env(parent = emptyenv())

tges_raw <- function(end_year) {
  k <- as.character(end_year)
  if (is.null(.tges_raw_cache[[k]])) {
    .tges_raw_cache[[k]] <- suppressWarnings(suppressMessages(
      njschooldata:::get_raw_tges(end_year)
    ))
  }
  .tges_raw_cache[[k]]
}

tges_tidy <- function(end_year) {
  k <- as.character(end_year)
  if (is.null(.tges_tidy_cache[[k]])) {
    .tges_tidy_cache[[k]] <- suppressWarnings(suppressMessages(
      tidy_tges_data(tges_raw(end_year), end_year)
    ))
  }
  .tges_tidy_cache[[k]]
}

# One district's tidy row for a given table + reporting year
tges_district_row <- function(end_year, district_id, table = "CSG1",
                              row_year = end_year) {
  d <- tges_tidy(end_year)[[table]]
  d[!is.na(d$district_id) &
      d$district_id == district_id &
      d$end_year == row_year, , drop = FALSE]
}

# Ground-truth anchors verified by hand against the NJ DOE files at
# https://www.nj.gov/education/guide/ (Absecon City = county 01, district 0010;
# Alpine Boro = district 0080).  Values are the budgeted-year figures.
tges_anchor_csg1 <- list(
  # end_year, district_id, per_pupil, rank
  list(2025, "0010", 22164, 47L),
  list(2024, "0010", 19098, 25L),
  list(2015, "0010", 11463,  7L),
  list(2010, "0010", 11436, 17L),
  list(2025, "0080", 32865, 66L)
)
