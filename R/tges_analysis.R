# ==============================================================================
# TGES Comparative Analysis Toolkit
# ==============================================================================
#
# Comparative-fiscal helpers that sit on top of fetch_tges() / fetch_many_tges().
# They mirror the peer-benchmarking engine in percentile_rank.R (which was built
# for outcomes such as graduation rates) and point it at dollars:
#
#   tges_composition()      one row per district-year, each spending category as a
#                           per-pupil column plus its share of budgetary per-pupil cost
#   tges_percentile_rank()  rank any TGES metric within a peer group (TGES enrollment
#                           band, DFG, county, or statewide)
#   tges_efficiency()       join per-pupil spend to an outcome percentile and label
#                           the spend-vs-outcome efficiency quadrant
#
# Design notes (see dev-docs/tges-coverage.md for the source schema):
#   - TGES rows key on a 4-digit `district_code` (Newark = "3570"), which lines up
#     directly with the `district_id` used by grate/parcc data. Group-average rows
#     carry no real code (NA or "00NA") and are dropped.
#   - Budget indicators carry `calc_type` ("Actuals"/"Budgeted"); compare like with
#     like. The TGES-native peer set is the `group` column (enrollment band), which
#     is also the set the published `District rank` is computed within.
#
# ==============================================================================


# -----------------------------------------------------------------------------
# internal: pull one tidied table out of a fetch_tges()/fetch_many_tges() object
# -----------------------------------------------------------------------------

# fetch_tges() returns a named list of tibbles (names are table codes: CSG1, ...).
# fetch_many_tges() returns a named list of those lists (names are years). Detect
# which we have and return the requested table, stacked across years if needed.
.tges_is_many <- function(tges) {
  length(tges) > 0 && is.list(tges[[1]]) && !is.data.frame(tges[[1]])
}

.tges_get_table <- function(tges, table) {
  if (.tges_is_many(tges)) {
    purrr::map_dfr(tges, function(yr_list) {
      tbl <- yr_list[[table]]
      if (is.null(tbl)) NULL else tibble::as_tibble(tbl)
    })
  } else {
    tbl <- tges[[table]]
    if (is.null(tbl)) NULL else tibble::as_tibble(tbl)
  }
}

# real district rows only (drop group-average / sentinel rows)
.tges_real_districts <- function(df) {
  if ("district_code" %in% names(df)) {
    df <- df %>%
      dplyr::filter(!is.na(.data$district_code), .data$district_code != "00NA")
  }
  df
}


# -----------------------------------------------------------------------------
# tges_composition()
# -----------------------------------------------------------------------------

#' Build a per-pupil spending composition table
#'
#' @description Reshapes the per-category TGES indicator tables into one row per
#' district-year with each major spending category as a per-pupil-dollar column,
#' plus that category's share of the budgetary per-pupil cost. This is the
#' backbone for "dollars to the classroom" and composition-drift analysis.
#'
#' Categories are pulled by table code (robust to label changes):
#' \itemize{
#'   \item \code{budgetary_pp} (CSG1) -- budgetary per-pupil cost (the share denominator)
#'   \item \code{classroom} (CSG2), \code{support_services} (CSG6),
#'         \code{administration} (CSG8), \code{plant_ops} (CSG10),
#'         \code{food_service} (CSG12), \code{extracurricular} (CSG13),
#'         \code{equipment} (CSG15)
#'   \item \code{total_pp} (CSG1AA) -- total per-pupil expenditures, if available
#' }
#'
#' Shares are each category divided by \code{budgetary_pp}. They are not
#' guaranteed to sum to 1: the categories are the standard TGES reporting
#' buckets, not a strict partition, and some (food, extracurricular) sit outside
#' the budgetary per-pupil definition.
#'
#' @param tges Output of \code{fetch_tges()} (one year) or \code{fetch_many_tges()}
#'   (several years).
#' @param years Optional numeric vector. Keep only these \code{end_year} values.
#' @param calc_type Optional character. Keep only this calc type, e.g.
#'   \code{"Actuals"} or \code{"Budgeted"}.
#'
#' @return A tibble with entity columns (\code{county_name}, \code{district_code},
#'   \code{district_name}, \code{group}), \code{end_year}, \code{calc_type}, the
#'   per-pupil category columns, and the matching \code{*_share} columns.
#'
#' @examples
#' \dontrun{
#' # One year
#' comp <- tges_composition(fetch_tges(2024))
#'
#' # Classroom share for Newark, actuals only
#' library(dplyr)
#' tges_composition(fetch_many_tges(2020:2024), calc_type = "Actuals") %>%
#'   filter(district_code == "3570") %>%
#'   select(end_year, classroom, budgetary_pp, classroom_share)
#'
#' # Lowest classroom-share districts in 2024
#' tges_composition(fetch_tges(2024), calc_type = "Budgeted") %>%
#'   arrange(classroom_share) %>%
#'   select(district_name, classroom_share, administration_share) %>%
#'   head(10)
#' }
#'
#' @export
tges_composition <- function(tges, years = NULL, calc_type = NULL) {

  value_col <- "Per Pupil costs"
  keys <- c("county_name", "district_code", "district_name", "group",
            "end_year", "calc_type")

  # table code -> friendly category column
  budget_map <- c(
    budgetary_pp     = "CSG1",
    classroom        = "CSG2",
    support_services = "CSG6",
    administration   = "CSG8",
    plant_ops        = "CSG10",
    food_service     = "CSG12",
    extracurricular  = "CSG13",
    equipment        = "CSG15"
  )

  pull_one <- function(col_name, table) {
    tbl <- .tges_get_table(tges, table)
    if (is.null(tbl) || !value_col %in% names(tbl)) return(NULL)
    present_keys <- intersect(keys, names(tbl))
    tbl %>%
      .tges_real_districts() %>%
      dplyr::transmute(
        dplyr::across(dplyr::all_of(present_keys)),
        !!col_name := suppressWarnings(as.numeric(.data[[value_col]]))
      )
  }

  pieces <- purrr::compact(purrr::imap(budget_map, ~ pull_one(.y, .x)))
  if (length(pieces) == 0) {
    stop("No budget indicator tables found in `tges`. Did you pass the output ",
         "of fetch_tges()/fetch_many_tges()?")
  }

  join_keys <- Reduce(intersect, lapply(pieces, names))
  join_keys <- intersect(keys, join_keys)
  out <- Reduce(function(a, b) dplyr::full_join(a, b, by = join_keys), pieces)

  # total per-pupil expenditures (CSG1AA) has no `group` column; join without it
  aa <- .tges_get_table(tges, "CSG1AA_AVGS")
  aa_col <- "Per Pupil Total Expenditures"
  if (!is.null(aa) && aa_col %in% names(aa)) {
    aa_keys <- intersect(
      c("county_name", "district_code", "district_name", "end_year", "calc_type"),
      names(aa)
    )
    aa_keys <- intersect(aa_keys, names(out))
    aa2 <- aa %>%
      .tges_real_districts() %>%
      dplyr::transmute(
        dplyr::across(dplyr::all_of(aa_keys)),
        total_pp = suppressWarnings(as.numeric(.data[[aa_col]]))
      ) %>%
      dplyr::distinct()
    out <- dplyr::left_join(out, aa2, by = aa_keys)
  }

  # shares of budgetary per-pupil cost
  share_cols <- intersect(
    c("classroom", "support_services", "administration", "plant_ops",
      "food_service", "extracurricular", "equipment"),
    names(out)
  )
  if ("budgetary_pp" %in% names(out)) {
    for (cc in share_cols) {
      out[[paste0(cc, "_share")]] <- dplyr::if_else(
        is.finite(out$budgetary_pp) & out$budgetary_pp > 0,
        out[[cc]] / out$budgetary_pp,
        NA_real_
      )
    }
  }

  if (!is.null(years) && "end_year" %in% names(out)) {
    keep_years <- years
    out <- out[out$end_year %in% keep_years, , drop = FALSE]
  }
  if (!is.null(calc_type) && "calc_type" %in% names(out)) {
    keep_ct <- calc_type
    out <- out[out$calc_type %in% keep_ct, , drop = FALSE]
  }

  # stable column order: keys, totals, categories, shares
  lead <- intersect(c("county_name", "district_code", "district_name", "group",
                      "end_year", "calc_type", "total_pp", "budgetary_pp"),
                    names(out))
  cat_cols <- intersect(names(budget_map)[-1], names(out))
  share_out <- intersect(paste0(cat_cols, "_share"), names(out))
  rest <- setdiff(names(out), c(lead, cat_cols, share_out))
  out %>% dplyr::select(dplyr::all_of(c(lead, cat_cols, share_out, rest)))
}


# -----------------------------------------------------------------------------
# tges_percentile_rank()
# -----------------------------------------------------------------------------

#' Percentile-rank a TGES metric within a peer group
#'
#' @description Fiscal counterpart to \code{grate_percentile_rank()} /
#' \code{parcc_percentile_rank()}. Ranks any numeric TGES column within a peer
#' group and adds \code{{prefix}_rank}, \code{{prefix}_n}, and
#' \code{{prefix}_percentile}. Higher metric value = higher percentile.
#'
#' Ranking is computed within \code{year_col} and the peer column, and also
#' within \code{indicator} and \code{calc_type} when those columns are present,
#' so stacked multi-indicator / multi-calc-type frames rank correctly.
#'
#' @param df A tidied TGES table (e.g. \code{fetch_tges(2024)$CSG1}) or the output
#'   of \code{tges_composition()}.
#' @param metric_col Character. Column to rank. Default \code{"Per Pupil costs"}.
#' @param peer Character. Peer group:
#'   \itemize{
#'     \item \code{"tges_group"} (default): the TGES enrollment-band \code{group}
#'       (no network; matches the set NJ's published rank uses)
#'     \item \code{"dfg"}: District Factor Group (fetches DFG data over the network)
#'     \item \code{"county"}: within \code{county_name} (the "town next door" set)
#'     \item \code{"statewide"}: all districts
#'   }
#' @param year_col Character. Year column. Default \code{"end_year"}.
#' @param prefix Character. Prefix for the output columns. Default \code{"peer"}.
#' @param dfg_revision Numeric. DFG revision when \code{peer = "dfg"}. Default 2000.
#'
#' @return \code{df} (ungrouped) with the three percentile columns added.
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' # Rank budgetary per-pupil cost within each TGES enrollment band
#' fetch_tges(2024)$CSG1 %>%
#'   tges_percentile_rank() %>%
#'   filter(district_code == "3570") %>%
#'   select(end_year, `Per Pupil costs`, peer_percentile)
#'
#' # Rank classroom share within DFG peers
#' tges_composition(fetch_tges(2024), calc_type = "Budgeted") %>%
#'   tges_percentile_rank("classroom_share", peer = "dfg")
#'
#' # Rank per-pupil cost against county neighbors
#' fetch_tges(2024)$CSG1 %>%
#'   tges_percentile_rank(peer = "county", prefix = "county")
#' }
#'
#' @export
tges_percentile_rank <- function(df,
                                 metric_col = "Per Pupil costs",
                                 peer = c("tges_group", "dfg", "county", "statewide"),
                                 year_col = "end_year",
                                 prefix = "peer",
                                 dfg_revision = 2000) {

  peer <- match.arg(peer)
  if (!metric_col %in% names(df)) {
    stop(sprintf("Column '%s' not found in dataframe", metric_col))
  }

  df <- .tges_real_districts(df)

  # attach DFG if needed (join 4-digit district_code straight to DFG's padded code)
  if (peer == "dfg" && !"dfg" %in% names(df)) {
    if (!"district_code" %in% names(df)) {
      stop("peer = 'dfg' needs a `district_code` column to attach DFG.")
    }
    dfg_lk <- fetch_dfg(revision = dfg_revision) %>%
      dplyr::group_by(.data$district_code) %>%
      dplyr::summarise(dfg = dplyr::first(.data$dfg), .groups = "drop")
    df <- dplyr::left_join(df, dfg_lk, by = "district_code")
  }

  peer_col <- switch(peer,
    statewide  = character(0),
    tges_group = "group",
    county     = "county_name",
    dfg        = "dfg"
  )
  if (length(peer_col) && !peer_col %in% names(df)) {
    stop(sprintf("peer = '%s' requires a '%s' column.", peer, peer_col))
  }

  group_cols <- c(year_col, peer_col)
  for (extra in c("indicator", "calc_type")) {
    if (extra %in% names(df)) group_cols <- c(group_cols, extra)
  }
  group_cols <- intersect(group_cols, names(df))

  df %>%
    dplyr::ungroup() %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(group_cols))) %>%
    add_percentile_rank(metric_col, prefix = prefix) %>%
    dplyr::ungroup()
}


# -----------------------------------------------------------------------------
# tges_efficiency()
# -----------------------------------------------------------------------------

# residual of outcome ~ spend within a year group; NA when too few points or no
# spend variation. Computed by hand so NA rows pass through cleanly.
.efficiency_residual <- function(spend_p, out_p) {
  ok <- is.finite(spend_p) & is.finite(out_p)
  res <- rep(NA_real_, length(out_p))
  if (sum(ok) >= 3 && stats::sd(spend_p[ok]) > 0) {
    m <- stats::lm(out_p[ok] ~ spend_p[ok])
    cf <- stats::coef(m)
    pred <- cf[1] + cf[2] * spend_p
    res <- out_p - pred
  }
  res
}

#' Spend-versus-outcome efficiency frontier
#'
#' @description Joins a TGES per-pupil spend metric to an outcome percentile and
#' labels each district's spend-vs-outcome position. This is the comparative
#' fiscal analyst's headline product, and the literal answer to the MarGrady
#' brief's open "cost-effectiveness" question: outcomes rose, but at what cost,
#' and was that efficient relative to peers?
#'
#' Spend is ranked within the chosen peer group via
#' \code{tges_percentile_rank()}. The outcome percentile is supplied by the
#' caller (e.g. from \code{grate_percentile_rank()} or
#' \code{parcc_percentile_rank()}), so the outcome metric and its peer definition
#' stay the caller's choice. The efficiency residual is the vertical distance
#' from a per-year regression of outcome percentile on spend percentile: positive
#' means more outcome than the spending would predict.
#'
#' @param spend_df A tidied TGES table (one report year, ideally filtered to a
#'   single \code{calc_type}) carrying \code{district_code} and \code{spend_col}.
#' @param outcome_df A district-level frame with \code{district_id}, the year
#'   column, and \code{outcome_percentile_col} (a 0-100 percentile).
#' @param spend_col Character. Spend column in \code{spend_df}. Default
#'   \code{"Per Pupil costs"}.
#' @param outcome_percentile_col Character. Percentile column in \code{outcome_df}.
#' @param spend_peer Character. Peer group for ranking spend. See
#'   \code{tges_percentile_rank()}. Default \code{"tges_group"}.
#' @param year_col Character. Year column, present in both frames. Default
#'   \code{"end_year"}.
#'
#' @return A tibble: entity columns, \code{end_year}, the spend value,
#'   \code{spend_percentile}, \code{outcome_percentile}, \code{efficiency_residual},
#'   and \code{quadrant}.
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' # Graduation outcomes ranked within DFG A, joined to per-pupil spend
#' grate <- load_grate_multi(2018:2024) %>%
#'   add_dfg() %>%
#'   filter(dfg == "A", is_district, subgroup == "total population") %>%
#'   grate_percentile_rank(peer_type = "dfg")
#'
#' spend <- fetch_tges(2024)$CSG1 %>% filter(calc_type == "Actuals")
#'
#' tges_efficiency(
#'   spend, grate,
#'   outcome_percentile_col = "grad_rate_percentile",
#'   spend_peer = "dfg"
#' ) %>%
#'   filter(district_code == "3570")
#'
#' # The "watch" quadrant: high spend, low outcome
#' eff <- tges_efficiency(spend, grate,
#'   outcome_percentile_col = "grad_rate_percentile")
#' eff %>% filter(grepl("watch", quadrant))
#' }
#'
#' @export
tges_efficiency <- function(spend_df,
                            outcome_df,
                            spend_col = "Per Pupil costs",
                            outcome_percentile_col,
                            spend_peer = c("tges_group", "dfg", "county", "statewide"),
                            year_col = "end_year") {

  spend_peer <- match.arg(spend_peer)
  if (missing(outcome_percentile_col)) {
    stop("`outcome_percentile_col` is required (e.g. 'grad_rate_percentile').")
  }
  if (!outcome_percentile_col %in% names(outcome_df)) {
    stop(sprintf("Column '%s' not found in outcome_df", outcome_percentile_col))
  }
  if (!"district_id" %in% names(outcome_df)) {
    stop("outcome_df must contain a `district_id` column.")
  }
  if (!year_col %in% names(outcome_df)) {
    stop(sprintf("outcome_df must contain a '%s' column.", year_col))
  }

  ranked <- tges_percentile_rank(
    spend_df, metric_col = spend_col, peer = spend_peer,
    year_col = year_col, prefix = "spend"
  )

  out <- outcome_df %>%
    dplyr::select(
      dplyr::all_of(c("district_id", year_col)),
      outcome_percentile = dplyr::all_of(outcome_percentile_col)
    ) %>%
    dplyr::distinct()

  by_vec <- stats::setNames(c("district_id", year_col), c("district_code", year_col))

  joined <- ranked %>%
    dplyr::inner_join(out, by = by_vec) %>%
    dplyr::group_by(.data[[year_col]]) %>%
    dplyr::mutate(
      efficiency_residual = .efficiency_residual(
        .data$spend_percentile, .data$outcome_percentile
      )
    ) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      quadrant = dplyr::case_when(
        is.na(.data$spend_percentile) | is.na(.data$outcome_percentile) ~ NA_character_,
        .data$spend_percentile <  50 & .data$outcome_percentile >= 50 ~ "Low spend / High outcome (efficient)",
        .data$spend_percentile >= 50 & .data$outcome_percentile >= 50 ~ "High spend / High outcome",
        .data$spend_percentile >= 50 & .data$outcome_percentile <  50 ~ "High spend / Low outcome (watch)",
        TRUE ~ "Low spend / Low outcome"
      )
    )

  lead <- intersect(
    c("county_name", "district_code", "district_name", "group", year_col,
      "calc_type", spend_col, "spend_percentile", "outcome_percentile",
      "efficiency_residual", "quadrant"),
    names(joined)
  )
  joined %>% dplyr::select(dplyr::all_of(lead), dplyr::everything())
}


# -----------------------------------------------------------------------------
# tges_revenue_mix()
# -----------------------------------------------------------------------------

#' Decompose where a district's school dollars come from
#'
#' @description Reshapes the VITSTAT revenue shares into one row per
#' district-year with each revenue source as both a share (0-1, as the source
#' reports it) and a per-pupil-dollar attribution (the share times total spending
#' per pupil). This is the taxpayer's whole question in one table: how much of
#' this budget is local property tax versus state aid versus one-time federal
#' money.
#'
#' VITSTAT is a single-year table (it reports \code{end_year - 1} for a given
#' guide), so pass \code{fetch_many_tges()} output to build a revenue-mix series
#' across years.
#'
#' @details Shares are NJ DOE's reported fractions and are not guaranteed to sum
#' to exactly 1 (rounding). The per-pupil dollar columns (\code{local_pp},
#' \code{state_pp}, ...) are \code{total_pp} multiplied by each share, so they
#' carry the same rounding. \code{total_pp} is VITSTAT's "Total Spending Per
#' Pupil", which equals the CSG1AA per-pupil total expenditure for that year.
#'
#' @param tges Output of \code{fetch_tges()} or \code{fetch_many_tges()}.
#' @param years Optional numeric vector. Keep only these \code{end_year} values.
#'
#' @return A tibble with entity columns, \code{end_year}, \code{total_pp}, the
#'   \code{*_share} columns (local, state, federal, tuition, free_balance,
#'   other), and the matching \code{*_pp} per-pupil dollar columns.
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' # Newark: what share is local property tax?
#' tges_revenue_mix(fetch_tges(2024)) %>%
#'   filter(district_code == "3570") %>%
#'   select(end_year, total_pp, local_share, state_share, federal_share)
#'
#' # The most local-tax-dependent districts in the latest year
#' tges_revenue_mix(fetch_tges(2024)) %>%
#'   arrange(desc(local_share)) %>%
#'   select(district_name, local_share, local_pp) %>%
#'   head(10)
#' }
#'
#' @export
tges_revenue_mix <- function(tges, years = NULL) {

  vs <- .tges_get_table(tges, "VITSTAT_TOTAL")
  if (is.null(vs)) {
    stop("No VITSTAT_TOTAL table found in `tges`. Did you pass the output of ",
         "fetch_tges()/fetch_many_tges()?")
  }
  vs <- .tges_real_districts(vs)

  keys <- intersect(
    c("county_name", "district_code", "district_name", "group", "end_year"),
    names(vs)
  )

  rename_map <- c(
    total_pp           = "Total Spending Per Pupil",
    local_share        = "Revenue: Local %",
    state_share        = "Revenue: State %",
    federal_share      = "Revenue: Federal %",
    tuition_share      = "Revenue: Tuition %",
    free_balance_share = "Revenue: Free balance %",
    other_share        = "Revenue: Other %"
  )
  present <- rename_map[rename_map %in% names(vs)]
  if (!"Total Spending Per Pupil" %in% present) {
    stop("VITSTAT_TOTAL is missing 'Total Spending Per Pupil'; cannot attribute ",
         "per-pupil dollars.")
  }

  out <- vs %>%
    dplyr::select(dplyr::all_of(keys), dplyr::all_of(unname(present)))
  names(out)[match(unname(present), names(out))] <- names(present)

  # coerce metrics to numeric (defensive; tidy_vitstat already does)
  for (nm in names(present)) out[[nm]] <- suppressWarnings(as.numeric(out[[nm]]))

  # per-pupil dollar attribution: share * total_pp
  share_cols <- setdiff(names(present), "total_pp")
  for (sc in share_cols) {
    pp_col <- sub("_share$", "_pp", sc)
    out[[pp_col]] <- dplyr::if_else(
      is.finite(out$total_pp), round(out[[sc]] * out$total_pp), NA_real_
    )
  }

  if (!is.null(years) && "end_year" %in% names(out)) {
    out <- out[out$end_year %in% years, , drop = FALSE]
  }

  share_out <- intersect(c("local_share", "state_share", "federal_share",
                           "tuition_share", "free_balance_share", "other_share"),
                         names(out))
  pp_out <- intersect(sub("_share$", "_pp", share_out), names(out))
  lead <- intersect(c(keys, "total_pp"), names(out))
  out %>% dplyr::select(dplyr::all_of(c(lead, share_out, pp_out)))
}


# -----------------------------------------------------------------------------
# tges_fund_balance_health()
# -----------------------------------------------------------------------------

#' Fund-balance health: budgeted vs actual and excess surplus
#'
#' @description Joins the two TGES governance tables -- CSG20 (budgeted general
#' fund balance vs. actual) and CSG21 (excess unreserved general fund balance) --
#' into one row per district-year, and adds the two flags a board member needs
#' before a budget vote: a structural-deficit signal and a surplus-over-cap
#' signal.
#'
#' @details Two failure modes, two flags:
#' \itemize{
#'   \item \code{excess_surplus_flag}: \code{TRUE} when NJ DOE reports a positive
#'     excess unreserved balance (\code{excess_unreserved > 0}). NJ districts may
#'     hold undesignated general fund surplus only up to a statutory cap (2% of
#'     the general fund budget, or $250k if greater); CSG21 reports the amount
#'     above that allowance, so a positive value is the surplus-hoarding signal.
#'   \item \code{declining_balance_flag}: \code{TRUE} when the actual general
#'     fund balance fell year over year (\code{balance_yoy_change < 0}). Computed
#'     only when more than one year is present for a district; reserves drawn down
#'     to paper over operating gaps are the structural-deficit signal.
#' }
#' \code{fund_balance_variance} (\code{actual - budgeted}) is reported for
#' context: a large negative variance means the district held far less surplus
#' than it budgeted. These flags are descriptive summaries of NJ DOE's reported
#' figures, not audit determinations.
#'
#' CSG20/CSG21 report \code{end_year - 2} and \code{end_year - 1} for a guide;
#' pass \code{fetch_many_tges()} output for a longer series.
#'
#' @param tges Output of \code{fetch_tges()} or \code{fetch_many_tges()}.
#' @param years Optional numeric vector. Keep only these \code{end_year} values.
#'
#' @return A tibble with entity columns, \code{end_year},
#'   \code{budgeted_fund_balance}, \code{actual_fund_balance},
#'   \code{fund_balance_variance}, \code{excess_unreserved},
#'   \code{balance_yoy_change}, and the two logical flags.
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' # Newark fund-balance health over the available window
#' tges_fund_balance_health(fetch_many_tges(2022:2024)) %>%
#'   filter(district_code == "3570") %>%
#'   select(end_year, budgeted_fund_balance, actual_fund_balance,
#'          excess_unreserved, excess_surplus_flag)
#'
#' # Districts drawing down reserves in the latest year
#' tges_fund_balance_health(fetch_tges(2024)) %>%
#'   filter(declining_balance_flag)
#' }
#'
#' @export
tges_fund_balance_health <- function(tges, years = NULL) {

  fb <- .tges_get_table(tges, "CSG20")
  ex <- .tges_get_table(tges, "CSG21")
  if (is.null(fb) && is.null(ex)) {
    stop("Neither CSG20 nor CSG21 found in `tges`. Did you pass the output of ",
         "fetch_tges()/fetch_many_tges()?")
  }

  keys <- c("county_name", "district_code", "district_name", "group", "end_year")

  if (!is.null(fb)) {
    fb <- .tges_real_districts(fb)
    fb_keys <- intersect(keys, names(fb))
    fb <- fb %>%
      dplyr::transmute(
        dplyr::across(dplyr::all_of(fb_keys)),
        budgeted_fund_balance = suppressWarnings(as.numeric(.data[["Budgeted General Fund Balance"]])),
        actual_fund_balance   = suppressWarnings(as.numeric(.data[["Actual"]]))
      ) %>%
      dplyr::distinct()
  }
  if (!is.null(ex)) {
    ex <- .tges_real_districts(ex)
    ex_keys <- intersect(keys, names(ex))
    ex <- ex %>%
      dplyr::transmute(
        dplyr::across(dplyr::all_of(ex_keys)),
        excess_unreserved = suppressWarnings(as.numeric(.data[["Actual Excess"]]))
      ) %>%
      dplyr::distinct()
  }

  if (is.null(fb)) {
    out <- ex
  } else if (is.null(ex)) {
    out <- fb
  } else {
    join_keys <- intersect(names(fb), names(ex))
    join_keys <- intersect(keys, join_keys)
    out <- dplyr::full_join(fb, ex, by = join_keys)
  }

  if ("budgeted_fund_balance" %in% names(out) && "actual_fund_balance" %in% names(out)) {
    out$fund_balance_variance <- out$actual_fund_balance - out$budgeted_fund_balance
  }

  out$excess_surplus_flag <- if ("excess_unreserved" %in% names(out)) {
    is.finite(out$excess_unreserved) & out$excess_unreserved > 0
  } else NA

  # year-over-year change in actual balance (structural-deficit signal)
  if ("actual_fund_balance" %in% names(out) && "end_year" %in% names(out)) {
    out <- out %>%
      dplyr::group_by(.data$district_code) %>%
      dplyr::arrange(.data$end_year, .by_group = TRUE) %>%
      dplyr::mutate(
        balance_yoy_change = .data$actual_fund_balance -
          dplyr::lag(.data$actual_fund_balance),
        declining_balance_flag = is.finite(.data$balance_yoy_change) &
          .data$balance_yoy_change < 0
      ) %>%
      dplyr::ungroup()
  }

  if (!is.null(years) && "end_year" %in% names(out)) {
    out <- out[out$end_year %in% years, , drop = FALSE]
  }

  lead <- intersect(
    c("county_name", "district_code", "district_name", "group", "end_year",
      "budgeted_fund_balance", "actual_fund_balance", "fund_balance_variance",
      "excess_unreserved", "balance_yoy_change", "excess_surplus_flag",
      "declining_balance_flag"),
    names(out)
  )
  out %>% dplyr::select(dplyr::all_of(lead), dplyr::everything())
}


# -----------------------------------------------------------------------------
# tges_federal_exposure()
# -----------------------------------------------------------------------------

#' ESSER-cliff exposure: did recurring spending ride one-time federal money?
#'
#' @description The most current fiscal-analyst question in the country, computed
#' off the VITSTAT federal-revenue share. For each district it compares a
#' pre-pandemic baseline federal share to the peak federal share during the ESSER
#' window, and flags districts whose per-pupil spending grew while they were
#' leaning on that one-time federal bump -- the structural set-up for a funding
#' cliff when the federal money expires.
#'
#' @details Requires a multi-year revenue series (pass \code{fetch_many_tges()}
#' output spanning the baseline and ESSER years). For each district:
#' \itemize{
#'   \item \code{baseline_federal_share}: mean federal share over
#'     \code{baseline_years}.
#'   \item \code{peak_federal_share}: max federal share over \code{esser_years}.
#'   \item \code{federal_bump}: \code{peak - baseline} (in share points, 0-1).
#'   \item \code{baseline_pp} / \code{peak_pp}: mean baseline and max ESSER-window
#'     total spending per pupil.
#'   \item \code{pp_growth}: \code{peak_pp / baseline_pp - 1}.
#'   \item \code{cliff_exposure}: \code{TRUE} when \code{federal_bump >=
#'     bump_threshold} AND \code{pp_growth > growth_threshold} -- a district that
#'     grew operating spend during a federal-revenue surge.
#' }
#' This is a screen, not a finding: it cannot see whether a district reserved the
#' federal money for one-time uses. It surfaces who to look at.
#'
#' @param tges Output of \code{fetch_many_tges()} (multi-year) or
#'   \code{fetch_tges()}.
#' @param baseline_years Numeric vector of pre-pandemic years. Default: the
#'   present years \code{<= 2020}.
#' @param esser_years Numeric vector of ESSER-window years. Default
#'   \code{2021:2024}.
#' @param bump_threshold Numeric. Minimum federal-share increase (0-1) to flag.
#'   Default 0.03 (3 share points).
#' @param growth_threshold Numeric. Minimum per-pupil spending growth to flag.
#'   Default 0 (any growth).
#'
#' @return One row per district with the baseline/peak/bump/growth columns and
#'   the \code{cliff_exposure} flag.
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' tg <- fetch_many_tges(2018:2025)
#'
#' tges_federal_exposure(tg) %>%
#'   filter(cliff_exposure) %>%
#'   arrange(desc(federal_bump)) %>%
#'   select(district_name, baseline_federal_share, peak_federal_share,
#'          federal_bump, pp_growth)
#' }
#'
#' @export
tges_federal_exposure <- function(tges,
                                  baseline_years = NULL,
                                  esser_years = 2021:2024,
                                  bump_threshold = 0.03,
                                  growth_threshold = 0) {

  rev <- tges_revenue_mix(tges)
  if (!all(c("federal_share", "total_pp", "end_year") %in% names(rev))) {
    stop("Revenue mix is missing federal_share/total_pp/end_year.")
  }

  yrs <- sort(unique(rev$end_year))
  if (is.null(baseline_years)) baseline_years <- yrs[yrs <= 2020]
  if (length(baseline_years) == 0) {
    stop("No baseline years available (none <= 2020 in the data). Pass ",
         "`baseline_years` explicitly or include earlier guides.")
  }
  if (!any(esser_years %in% yrs)) {
    stop("None of `esser_years` are present in the data.")
  }

  rev %>%
    dplyr::group_by(.data$county_name, .data$district_code, .data$district_name) %>%
    dplyr::summarise(
      baseline_federal_share = mean(
        .data$federal_share[.data$end_year %in% baseline_years], na.rm = TRUE),
      peak_federal_share = suppressWarnings(max(
        .data$federal_share[.data$end_year %in% esser_years], na.rm = TRUE)),
      baseline_pp = mean(
        .data$total_pp[.data$end_year %in% baseline_years], na.rm = TRUE),
      peak_pp = suppressWarnings(max(
        .data$total_pp[.data$end_year %in% esser_years], na.rm = TRUE)),
      .groups = "drop"
    ) %>%
    # max() over an all-NA slice returns -Inf; normalise back to NA
    dplyr::mutate(
      peak_federal_share = dplyr::if_else(is.finite(.data$peak_federal_share),
                                          .data$peak_federal_share, NA_real_),
      peak_pp = dplyr::if_else(is.finite(.data$peak_pp), .data$peak_pp, NA_real_),
      federal_bump = .data$peak_federal_share - .data$baseline_federal_share,
      pp_growth = dplyr::if_else(
        is.finite(.data$baseline_pp) & .data$baseline_pp > 0,
        .data$peak_pp / .data$baseline_pp - 1, NA_real_),
      cliff_exposure = is.finite(.data$federal_bump) &
        .data$federal_bump >= bump_threshold &
        is.finite(.data$pp_growth) & .data$pp_growth > growth_threshold
    )
}


# -----------------------------------------------------------------------------
# tges_staffing()
# -----------------------------------------------------------------------------

#' Staffing ratios, median salaries, and the benefits squeeze
#'
#' @description Reshapes the personnel tables (CSG16-CSG19) plus the benefits
#' share (CSG14) into one row per district-year. This is the board's negotiation
#' and "administrative bloat" dashboard in a single frame: students per teacher /
#' special-service provider / administrator, faculty per administrator, the
#' median salary for each role, and benefits as a share of total salaries.
#'
#' @details Sources, by friendly column:
#' \itemize{
#'   \item \code{student_teacher_ratio}, \code{teacher_salary} (CSG16)
#'   \item \code{student_special_service_ratio}, \code{special_service_salary} (CSG17)
#'   \item \code{student_admin_ratio}, \code{admin_salary} (CSG18)
#'   \item \code{faculty_admin_ratio} (CSG19)
#'   \item \code{benefits_pct_salary} (CSG14, employee benefits as a fraction of
#'     total salaries)
#' }
#' CSG16-CSG19 report \code{end_year - 1} and \code{end_year}; CSG14 also reports
#' \code{end_year - 2}, so the earliest year may carry a benefits share with no
#' ratios. The most recent year's benefits share is the budgeted figure.
#'
#' @param tges Output of \code{fetch_tges()} or \code{fetch_many_tges()}.
#' @param years Optional numeric vector. Keep only these \code{end_year} values.
#'
#' @return A tibble with entity columns, \code{end_year}, the ratio columns, the
#'   median-salary columns, and \code{benefits_pct_salary}.
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' # Is Newark administratively heavy, and competitive on teacher pay?
#' tges_staffing(fetch_tges(2024)) %>%
#'   filter(district_code == "3570") %>%
#'   select(end_year, student_admin_ratio, faculty_admin_ratio,
#'          teacher_salary, admin_salary, benefits_pct_salary)
#'
#' # Rank student/administrator ratio within enrollment-band peers
#' tges_staffing(fetch_tges(2024)) %>%
#'   tges_percentile_rank("student_admin_ratio", peer = "tges_group")
#' }
#'
#' @export
tges_staffing <- function(tges, years = NULL) {

  keys <- c("county_name", "district_code", "district_name", "group", "end_year")

  pull_sel <- function(table, mapping) {
    tbl <- .tges_get_table(tges, table)
    if (is.null(tbl)) return(NULL)
    if (!any(unname(mapping) %in% names(tbl))) return(NULL)
    tbl <- .tges_real_districts(tbl)
    present_keys <- intersect(keys, names(tbl))
    present_map <- mapping[mapping %in% names(tbl)]
    out <- tbl %>%
      dplyr::select(dplyr::all_of(present_keys), dplyr::all_of(unname(present_map)))
    names(out)[match(unname(present_map), names(out))] <- names(present_map)
    for (nm in names(present_map)) out[[nm]] <- suppressWarnings(as.numeric(out[[nm]]))
    dplyr::distinct(out)
  }

  pieces <- purrr::compact(list(
    pull_sel("CSG16", c(student_teacher_ratio = "Student/Teacher ratio",
                        teacher_salary = "Teacher Salary")),
    pull_sel("CSG17", c(student_special_service_ratio = "Student/Special Service ratio",
                        special_service_salary = "Special Service Salary")),
    pull_sel("CSG18", c(student_admin_ratio = "Student/Administrator ratio",
                        admin_salary = "Administrator Salary")),
    pull_sel("CSG19", c(faculty_admin_ratio = "Faculty/Administrator ratio")),
    pull_sel("CSG14", c(benefits_pct_salary = "% of Total Salaries"))
  ))

  if (length(pieces) == 0) {
    stop("No personnel tables (CSG14, CSG16-CSG19) found in `tges`.")
  }

  join_keys <- Reduce(intersect, lapply(pieces, names))
  join_keys <- intersect(keys, join_keys)
  out <- Reduce(function(a, b) dplyr::full_join(a, b, by = join_keys), pieces)

  if (!is.null(years) && "end_year" %in% names(out)) {
    out <- out[out$end_year %in% years, , drop = FALSE]
  }

  lead <- intersect(
    c(keys, "student_teacher_ratio", "teacher_salary",
      "student_special_service_ratio", "special_service_salary",
      "student_admin_ratio", "admin_salary", "faculty_admin_ratio",
      "benefits_pct_salary"),
    names(out)
  )
  out %>% dplyr::select(dplyr::all_of(lead), dplyr::everything())
}


# -----------------------------------------------------------------------------
# tges_red_flags()
# -----------------------------------------------------------------------------

# the indicators the red-flag scan ranks, and what a high value means.
# per-pupil cost tables are ranked on "Per Pupil costs"; composition shares are
# ranked on the share column computed by tges_composition().
.tges_red_flag_indicators <- function() {
  tibble::tribble(
    ~source,        ~code,            ~metric,                ~label,                              ~higher_means,
    "table",        "CSG1",           "Per Pupil costs",      "Budgetary per-pupil cost",          "spends more than peers",
    "table",        "CSG2",           "Per Pupil costs",      "Classroom instruction $/pupil",     "spends more than peers",
    "table",        "CSG6",           "Per Pupil costs",      "Support services $/pupil",          "spends more than peers",
    "table",        "CSG8",           "Per Pupil costs",      "Administration $/pupil",            "spends more than peers",
    "table",        "CSG8A",          "Per Pupil costs",      "Legal services $/pupil",            "spends more than peers",
    "table",        "CSG10",          "Per Pupil costs",      "Plant operations & maintenance $/pupil", "spends more than peers",
    "table",        "CSG12",          "Per Pupil costs",      "Food service $/pupil",              "spends more than peers",
    "table",        "CSG13",          "Per Pupil costs",      "Extracurricular $/pupil",           "spends more than peers",
    "table",        "CSG15",          "Per Pupil costs",      "Equipment $/pupil",                 "spends more than peers",
    "composition",  "classroom_share", "classroom_share",     "Classroom share of budget",         "more dollars reach the classroom",
    "composition",  "administration_share", "administration_share", "Administration share of budget", "more overhead than peers"
  )
}

#' Red-flag scan: where a district sits in the top or bottom decile of peers
#'
#' @description The product a board member actually wants before a meeting. Runs
#' \code{tges_percentile_rank()} across every major spending indicator for one
#' district and surfaces the ones where it lands in the top or bottom decile of
#' its peer group. The output is a one-page "you are top-decile in legal services
#' and plant O&M, bottom-decile in classroom share" brief.
#'
#' @details The scan covers the per-pupil cost tables (CSG1, CSG2, CSG6, CSG8,
#' CSG8A, CSG10, CSG12, CSG13, CSG15) ranked on "Per Pupil costs", plus the
#' classroom and administration shares from \code{tges_composition()}. Each row
#' carries \code{higher_means} so the direction is unambiguous: a top-decile
#' "Administration $/pupil" is a cost flag, while a top-decile "Classroom share"
#' is favourable. Percentile is recomputed within the chosen peer group (not NJ's
#' published enrollment-band rank, unless \code{peer = "tges_group"}), so all
#' indicators use one consistent peer system.
#'
#' @param tges Output of \code{fetch_tges()} (a single guide) or
#'   \code{fetch_many_tges()}.
#' @param district_code Character. The 4-digit focal district code (Newark =
#'   "3570").
#' @param peer Character. Peer group. See \code{tges_percentile_rank()}. Default
#'   \code{"tges_group"}.
#' @param year Numeric. Report year to scan. Default: the latest \code{end_year}
#'   present.
#' @param calc_type Character. For the per-pupil cost tables, which calc type to
#'   rank. Default \code{"Budgeted"} (the current-year budgeted figure).
#' @param threshold Numeric. Decile width in percentile points. Default 10:
#'   percentile \code{<= 10} is bottom-decile, \code{>= 90} is top-decile.
#' @param only_flagged Logical. If \code{TRUE} (default) return only the
#'   top/bottom-decile rows; if \code{FALSE} return the full indicator profile
#'   with a \code{flag} column (\code{NA} when not extreme).
#' @param dfg_revision Numeric. DFG revision when \code{peer = "dfg"}. Default 2000.
#'
#' @return A tibble: \code{indicator}, \code{value}, \code{peer_percentile},
#'   \code{peer_n}, \code{higher_means}, \code{end_year}, and \code{flag}.
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' # Newark's red flags within its enrollment-band peers
#' tges_red_flags(fetch_tges(2024), district_code = "3570")
#'
#' # Full profile within DFG A peers, nothing hidden
#' tges_red_flags(fetch_tges(2024), district_code = "3570",
#'                peer = "dfg", only_flagged = FALSE)
#' }
#'
#' @export
tges_red_flags <- function(tges,
                           district_code,
                           peer = c("tges_group", "dfg", "county", "statewide"),
                           year = NULL,
                           calc_type = "Budgeted",
                           threshold = 10,
                           only_flagged = TRUE,
                           dfg_revision = 2000) {

  peer <- match.arg(peer)
  if (missing(district_code)) stop("`district_code` is required.")
  spec <- .tges_red_flag_indicators()

  # the composition frame, ranked per share, is reused across composition rows
  comp <- tryCatch(tges_composition(tges), error = function(e) NULL)

  rank_one <- function(source, code, metric, label, higher_means) {
    df <- if (source == "table") {
      tbl <- .tges_get_table(tges, code)
      if (is.null(tbl) || !metric %in% names(tbl)) return(NULL)
      tbl <- .tges_real_districts(tbl)
      if (!is.null(calc_type) && "calc_type" %in% names(tbl)) {
        tbl <- tbl[tbl$calc_type %in% calc_type, , drop = FALSE]
      }
      tbl
    } else {
      if (is.null(comp) || !metric %in% names(comp)) return(NULL)
      comp
    }
    if (!"end_year" %in% names(df) || nrow(df) == 0) return(NULL)

    target_year <- if (is.null(year)) max(df$end_year, na.rm = TRUE) else year
    df <- df[df$end_year == target_year, , drop = FALSE]
    if (nrow(df) == 0) return(NULL)

    ranked <- tges_percentile_rank(df, metric_col = metric, peer = peer,
                                   prefix = "peer", dfg_revision = dfg_revision)
    row <- ranked[ranked$district_code == district_code, , drop = FALSE]
    if (nrow(row) == 0) return(NULL)
    row <- row[1, , drop = FALSE]

    tibble::tibble(
      indicator       = label,
      value           = suppressWarnings(as.numeric(row[[metric]])),
      peer_percentile = row[["peer_percentile"]],
      peer_n          = row[["peer_n"]],
      higher_means    = higher_means,
      end_year        = target_year
    )
  }

  out <- purrr::pmap_dfr(
    list(spec$source, spec$code, spec$metric, spec$label, spec$higher_means),
    rank_one
  )
  if (nrow(out) == 0) {
    stop("No indicators could be ranked for district ", district_code,
         " (check the code, year, and that the guide carries these tables).")
  }

  out <- out %>%
    dplyr::mutate(
      flag = dplyr::case_when(
        !is.finite(.data$peer_percentile) ~ NA_character_,
        .data$peer_percentile >= 100 - threshold ~ "top decile",
        .data$peer_percentile <= threshold ~ "bottom decile",
        TRUE ~ NA_character_
      )
    ) %>%
    dplyr::arrange(dplyr::desc(.data$peer_percentile))

  if (only_flagged) out <- out[!is.na(out$flag), , drop = FALSE]
  out
}


# -----------------------------------------------------------------------------
# tges_real_growth()
# -----------------------------------------------------------------------------

#' Decompose per-pupil spending growth into real cost vs the enrollment effect
#'
#' @description Per-pupil spend mechanically rises when enrollment falls, because
#' fixed costs spread over fewer students. This function separates that
#' denominator artifact from real cost growth, so "costs are exploding" can be
#' checked against "or do we simply have fewer kids." It is the most important
#' TGES data caution turned into a tool.
#'
#' @details Built from CSG1AA (total expenditures + average daily enrollment +
#' per-pupil total). Because adjacent guides report overlapping actual years, the
#' rows are de-duplicated on district-year before differencing. For each
#' district-year (after the first), using the identity
#' \eqn{\ln(pp) = \ln(exp) - \ln(ade)}:
#' \itemize{
#'   \item \code{total_exp_growth}, \code{ade_growth}, \code{per_pupil_growth}:
#'     simple year-over-year percent changes.
#'   \item \code{real_cost_component}: \eqn{\ln(exp_t / exp_{t-1})}, the
#'     spending-driven part of per-pupil log growth.
#'   \item \code{enrollment_component}: \eqn{-\ln(ade_t / ade_{t-1})}, the part
#'     driven purely by the changing denominator (positive when enrollment falls).
#'   \item \code{enrollment_effect_share}: \code{enrollment_component} divided by
#'     total per-pupil log change -- the fraction of per-pupil growth that is the
#'     enrollment artifact rather than real spending.
#' }
#' If a real price index is supplied via \code{deflator}, the function also
#' returns inflation-adjusted total expenditure and a \code{real_pp_growth}.
#' \strong{No deflator is fabricated}: you must pass a real index (e.g. BLS CPI);
#' without one, only nominal decomposition is returned.
#'
#' @param tges Output of \code{fetch_tges()} or \code{fetch_many_tges()}.
#' @param years Optional numeric vector. Keep only these \code{end_year} values
#'   (applied after differencing, so lags still use adjacent years).
#' @param deflator Optional data frame with columns \code{end_year} and
#'   \code{price_index} (a real index supplied by the caller). When present,
#'   adds \code{real_total_exp}, \code{real_per_pupil}, and \code{real_pp_growth}.
#'
#' @return A tibble with entity columns, \code{end_year}, \code{total_exp},
#'   \code{ade}, \code{per_pupil}, the growth and decomposition columns, and
#'   (if \code{deflator} is supplied) the real-terms columns.
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' rg <- tges_real_growth(fetch_many_tges(2018:2024))
#'
#' # Newark: how much of per-pupil growth is just falling enrollment?
#' rg %>%
#'   filter(district_code == "3570") %>%
#'   select(end_year, per_pupil_growth, real_cost_component,
#'          enrollment_component, enrollment_effect_share)
#'
#' # With a real deflator (caller-supplied CPI), get real per-pupil growth
#' cpi <- data.frame(end_year = 2018:2024,
#'                   price_index = c(251.1, 255.7, 258.8, 271.0, 292.7, 304.7, 313.7))
#' tges_real_growth(fetch_many_tges(2018:2024), deflator = cpi) %>%
#'   filter(district_code == "3570") %>%
#'   select(end_year, per_pupil_growth, real_pp_growth)
#' }
#'
#' @export
tges_real_growth <- function(tges, years = NULL, deflator = NULL) {

  aa <- .tges_get_table(tges, "CSG1AA_AVGS")
  if (is.null(aa)) {
    stop("No CSG1AA_AVGS table found in `tges`. Did you pass the output of ",
         "fetch_tges()/fetch_many_tges()?")
  }
  aa <- .tges_real_districts(aa)

  exp_col <- "Total Expenditures, actual costs"
  ade_col <- "Average Daily Enrollment plus Sent Pupils"
  pp_col  <- "Per Pupil Total Expenditures"
  if (!all(c(exp_col, ade_col) %in% names(aa))) {
    stop("CSG1AA_AVGS is missing total expenditures and/or ADE columns.")
  }

  keys <- intersect(c("county_name", "district_code", "district_name"), names(aa))

  base <- aa %>%
    dplyr::transmute(
      dplyr::across(dplyr::all_of(keys)),
      end_year  = .data$end_year,
      total_exp = suppressWarnings(as.numeric(.data[[exp_col]])),
      ade       = suppressWarnings(as.numeric(.data[[ade_col]])),
      per_pupil = if (pp_col %in% names(aa)) {
        suppressWarnings(as.numeric(.data[[pp_col]]))
      } else {
        suppressWarnings(as.numeric(.data[[exp_col]])) /
          suppressWarnings(as.numeric(.data[[ade_col]]))
      }
    ) %>%
    # collapse overlapping reports of the same actual year
    dplyr::distinct(.data$district_code, .data$end_year, .keep_all = TRUE)

  # optional real deflator (caller-supplied; never fabricated here)
  if (!is.null(deflator)) {
    if (!all(c("end_year", "price_index") %in% names(deflator))) {
      stop("`deflator` must be a data frame with `end_year` and `price_index`.")
    }
    base_index <- deflator$price_index[which.min(deflator$end_year)]
    base <- base %>%
      dplyr::left_join(
        deflator[, c("end_year", "price_index")], by = "end_year") %>%
      dplyr::mutate(
        real_total_exp = .data$total_exp * (base_index / .data$price_index),
        real_per_pupil = .data$per_pupil * (base_index / .data$price_index)
      )
  }

  out <- base %>%
    dplyr::group_by(.data$district_code) %>%
    dplyr::arrange(.data$end_year, .by_group = TRUE) %>%
    dplyr::mutate(
      total_exp_growth  = .data$total_exp / dplyr::lag(.data$total_exp) - 1,
      ade_growth        = .data$ade / dplyr::lag(.data$ade) - 1,
      per_pupil_growth  = .data$per_pupil / dplyr::lag(.data$per_pupil) - 1,
      real_cost_component  = log(.data$total_exp / dplyr::lag(.data$total_exp)),
      enrollment_component = -log(.data$ade / dplyr::lag(.data$ade)),
      .pp_log_change       = log(.data$per_pupil / dplyr::lag(.data$per_pupil)),
      enrollment_effect_share = dplyr::if_else(
        is.finite(.data$.pp_log_change) & .data$.pp_log_change != 0,
        .data$enrollment_component / .data$.pp_log_change, NA_real_)
    )

  if (!is.null(deflator) && "real_per_pupil" %in% names(out)) {
    out <- out %>%
      dplyr::mutate(
        real_pp_growth = .data$real_per_pupil / dplyr::lag(.data$real_per_pupil) - 1
      )
  }

  out <- out %>%
    dplyr::select(-".pp_log_change") %>%
    dplyr::ungroup()

  if (!is.null(years) && "end_year" %in% names(out)) {
    out <- out[out$end_year %in% years, , drop = FALSE]
  }

  out
}
