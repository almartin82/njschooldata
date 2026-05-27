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
#   - TGES rows key on a 4-digit `district_id` (Newark = "3570"), which lines up
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
  if ("district_id" %in% names(df)) {
    df <- df %>%
      dplyr::filter(!is.na(.data$district_id), .data$district_id != "00NA")
  }
  df
}

# stack every Total Spending Detail table (DETAIL_FY24, DETAIL_FY23, ...) across
# one or many guides. Each is already tidied with its own data-year `end_year`.
.tges_get_detail <- function(tges) {
  grab <- function(yr_list) {
    keys <- grep("^DETAIL_FY", names(yr_list), value = TRUE)
    if (!length(keys)) return(NULL)
    purrr::map_dfr(keys, function(k) tibble::as_tibble(yr_list[[k]]))
  }
  if (.tges_is_many(tges)) {
    purrr::map_dfr(tges, grab)
  } else {
    grab(tges)
  }
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
#' @return A tibble with entity columns (\code{county_name}, \code{district_id},
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
#'   filter(district_id == "3570") %>%
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
  keys <- c("county_name", "district_id", "district_name", "group",
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
      c("county_name", "district_id", "district_name", "end_year", "calc_type"),
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
  lead <- intersect(c("county_name", "district_id", "district_name", "group",
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
#'     \item \code{"custom"}: a caller-supplied set of district codes (see
#'       \code{custom_ids}); ranks within that set only. This is the hook for
#'       \code{tges_find_peers()} output.
#'   }
#' @param year_col Character. Year column. Default \code{"end_year"}.
#' @param prefix Character. Prefix for the output columns. Default \code{"peer"}.
#' @param dfg_revision Numeric. DFG revision when \code{peer = "dfg"}. Default 2000.
#' @param custom_ids Character vector of \code{district_id}s. Required when
#'   \code{peer = "custom"}; the frame is restricted to these codes and ranked
#'   within them. Ignored otherwise.
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
#'   filter(district_id == "3570") %>%
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
                                 peer = c("tges_group", "dfg", "county", "statewide", "custom"),
                                 year_col = "end_year",
                                 prefix = "peer",
                                 dfg_revision = 2000,
                                 custom_ids = NULL) {

  peer <- match.arg(peer)
  if (!metric_col %in% names(df)) {
    stop(sprintf("Column '%s' not found in dataframe", metric_col))
  }

  df <- .tges_real_districts(df)

  # custom peer set: restrict to the supplied codes and rank within them
  if (peer == "custom") {
    if (is.null(custom_ids) || length(custom_ids) == 0) {
      stop("peer = 'custom' requires a non-empty `custom_ids` vector.")
    }
    if (!"district_id" %in% names(df)) {
      stop("peer = 'custom' needs a `district_id` column.")
    }
    df <- df[df$district_id %in% custom_ids, , drop = FALSE]
  }

  # attach DFG if needed (join 4-digit district_id straight to DFG's padded code)
  if (peer == "dfg" && !"dfg" %in% names(df)) {
    if (!"district_id" %in% names(df)) {
      stop("peer = 'dfg' needs a `district_id` column to attach DFG.")
    }
    dfg_lk <- fetch_dfg(revision = dfg_revision) %>%
      dplyr::group_by(.data$district_id) %>%
      dplyr::summarise(dfg = dplyr::first(.data$dfg), .groups = "drop")
    df <- dplyr::left_join(df, dfg_lk, by = "district_id")
  }

  peer_col <- switch(peer,
    statewide  = character(0),
    custom     = character(0),
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
#'   single \code{calc_type}) carrying \code{district_id} and \code{spend_col}.
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
#' grate <- fetch_grad_rate(2023, methodology = "4 year") %>%
#'   add_dfg() %>%
#'   filter(dfg == "A", is_district, subgroup == "total") %>%
#'   grate_percentile_rank(peer_type = "dfg")
#'
#' spend <- fetch_tges(2024)$CSG1 %>%
#'   filter(calc_type == "Actuals", end_year == 2023)
#'
#' tges_efficiency(
#'   spend, grate,
#'   outcome_percentile_col = "grad_rate_percentile",
#'   spend_peer = "dfg"
#' ) %>%
#'   filter(district_id == "3570")
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

  by_vec <- stats::setNames(c("district_id", year_col), c("district_id", year_col))

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
    c("county_name", "district_id", "district_name", "group", year_col,
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
#'   filter(district_id == "3570") %>%
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
    c("county_name", "district_id", "district_name", "group", "end_year"),
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
#'   filter(district_id == "3570") %>%
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

  keys <- c("county_name", "district_id", "district_name", "group", "end_year")

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
      dplyr::group_by(.data$district_id) %>%
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
    c("county_name", "district_id", "district_name", "group", "end_year",
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
    dplyr::group_by(.data$county_name, .data$district_id, .data$district_name) %>%
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
#'   filter(district_id == "3570") %>%
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

  keys <- c("county_name", "district_id", "district_name", "group", "end_year")

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
#' @param district_id Character. The 4-digit focal district code (Newark =
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
#' tges_red_flags(fetch_tges(2024), district_id = "3570")
#'
#' # Full profile within DFG A peers, nothing hidden
#' tges_red_flags(fetch_tges(2024), district_id = "3570",
#'                peer = "dfg", only_flagged = FALSE)
#' }
#'
#' @export
tges_red_flags <- function(tges,
                           district_id,
                           peer = c("tges_group", "dfg", "county", "statewide"),
                           year = NULL,
                           calc_type = "Budgeted",
                           threshold = 10,
                           only_flagged = TRUE,
                           dfg_revision = 2000) {

  peer <- match.arg(peer)
  if (missing(district_id)) stop("`district_id` is required.")
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
    row <- ranked[ranked$district_id == district_id, , drop = FALSE]
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
    stop("No indicators could be ranked for district ", district_id,
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
#'   filter(district_id == "3570") %>%
#'   select(end_year, per_pupil_growth, real_cost_component,
#'          enrollment_component, enrollment_effect_share)
#'
#' # With a real deflator (caller-supplied CPI), get real per-pupil growth
#' cpi <- data.frame(end_year = 2018:2024,
#'                   price_index = c(251.1, 255.7, 258.8, 271.0, 292.7, 304.7, 313.7))
#' tges_real_growth(fetch_many_tges(2018:2024), deflator = cpi) %>%
#'   filter(district_id == "3570") %>%
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

  keys <- intersect(c("county_name", "district_id", "district_name"), names(aa))

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
    dplyr::distinct(.data$district_id, .data$end_year, .keep_all = TRUE)

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
    dplyr::group_by(.data$district_id) %>%
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


# ==============================================================================
# Cross-district comparative layer
# ==============================================================================
#
# The functions above are point-in-time benchmarking and single-district
# decomposition. The ones below reason across districts (and across time at the
# same time): who are a district's real structural peers, where the efficiency
# frontier sits, whether the system is converging, how budgets drift, what a gap
# costs in dollars, and how fragile a district's funding is.
#
#   tges_find_peers()         data-driven nearest-neighbour peer construction
#   tges_frontier()           free-disposal-hull spend-vs-outcome efficiency score
#   tges_convergence()        beta-convergence of spend across a peer group
#   tges_composition_drift()  ranked budget-share shift vectors vs peers
#   tges_gap_cost()           translate a peer gap into per-pupil and total dollars
#   tges_volatility()         year-to-year funding volatility, ranked vs peers
#   tges_compare()            a named multi-district scorecard (counterfactual cities)
#
# ==============================================================================


# -----------------------------------------------------------------------------
# internal: attach a single `peer_group` column under one of the four peer systems
# -----------------------------------------------------------------------------

.tges_attach_peer <- function(df, peer, dfg_revision = 2000) {
  if (peer == "dfg") {
    if (!"dfg" %in% names(df)) {
      if (!"district_id" %in% names(df)) {
        stop("peer = 'dfg' needs a `district_id` column to attach DFG.")
      }
      dfg_lk <- fetch_dfg(revision = dfg_revision) %>%
        dplyr::group_by(.data$district_id) %>%
        dplyr::summarise(dfg = dplyr::first(.data$dfg), .groups = "drop")
      df <- dplyr::left_join(df, dfg_lk, by = "district_id")
    }
    df$peer_group <- df$dfg
  } else if (peer == "tges_group") {
    if (!"group" %in% names(df)) {
      stop("peer = 'tges_group' needs a `group` (enrollment band) column.")
    }
    df$peer_group <- df$group
  } else if (peer == "county") {
    if (!"county_name" %in% names(df)) {
      stop("peer = 'county' needs a `county_name` column.")
    }
    df$peer_group <- df$county_name
  } else {  # statewide
    df$peer_group <- "statewide"
  }
  df
}

# internal: latest reported average daily enrollment per district (from CSG1AA)
.tges_latest_ade <- function(tges) {
  aa <- .tges_get_table(tges, "CSG1AA_AVGS")
  ade_col <- "Average Daily Enrollment plus Sent Pupils"
  if (is.null(aa) || !ade_col %in% names(aa)) return(NULL)
  aa %>%
    .tges_real_districts() %>%
    dplyr::transmute(
      .data$district_id,
      end_year = .data$end_year,
      ade = suppressWarnings(as.numeric(.data[[ade_col]]))
    ) %>%
    dplyr::filter(is.finite(.data$ade)) %>%
    dplyr::group_by(.data$district_id) %>%
    dplyr::arrange(.data$end_year, .by_group = TRUE) %>%
    dplyr::summarise(ade = dplyr::last(.data$ade),
                     ade_year = dplyr::last(.data$end_year), .groups = "drop")
}


# -----------------------------------------------------------------------------
# tges_find_peers()
# -----------------------------------------------------------------------------

#' Find a district's data-driven structural peers
#'
#' @description DFG is a 1990s census construct and county is just geography;
#' neither answers "which districts are actually structurally like mine?" This
#' standardizes a set of structural features (enrollment, per-pupil cost,
#' spending composition, revenue mix) and returns the \code{n} nearest districts
#' by scaled Euclidean distance. The result is the honest peer set for every
#' other comparison in this toolkit: pass the returned codes to
#' \code{tges_percentile_rank(peer = "custom", custom_ids = ...)}.
#'
#' @details Features are assembled per district from the latest available report
#' for each source (composition for the chosen \code{year}, the most recent
#' \code{CSG1AA} enrollment, the most recent VITSTAT revenue mix), then each
#' feature is z-scored across all districts with complete data. \code{ade}
#' (enrollment) is log-transformed before scaling because it is heavy-tailed.
#' Distance is the Euclidean norm over the scaled features; the focal district
#' must have a complete feature vector. Zero-variance features are dropped with a
#' warning. \code{dfg} is reported for context but is not part of the distance.
#'
#' @param tges Output of \code{fetch_tges()} or \code{fetch_many_tges()}.
#' @param district_id Character. The 4-digit focal district code (Newark = "3570").
#' @param n Integer. Number of peers to return (besides the focal row). Default 10.
#' @param year Numeric. Composition report year to anchor on. Default: latest present.
#' @param features Character vector of feature columns to match on. Default
#'   \code{c("ade", "budgetary_pp", "classroom_share", "administration_share",
#'   "local_share", "state_share")}. Any numeric column in the assembled frame is
#'   allowed (e.g. \code{total_pp}, \code{federal_share},
#'   \code{support_services_share}, \code{plant_ops_share}).
#' @param calc_type Character. Composition calc type. Default \code{"Budgeted"}.
#' @param dfg_revision Numeric. DFG revision for the reported \code{dfg} column.
#'
#' @return A tibble sorted by \code{distance} ascending, with the focal district
#'   first (\code{is_focal = TRUE}, \code{distance = 0}) followed by the \code{n}
#'   nearest peers: \code{district_id}, \code{district_name}, \code{county_name},
#'   \code{group}, \code{dfg}, \code{is_focal}, \code{distance}, and the raw
#'   feature columns.
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' # Newark's data-driven fiscal twins
#' peers <- tges_find_peers(fetch_tges(2024), district_id = "3570")
#' peers %>% select(district_name, dfg, distance, ade, budgetary_pp, local_share)
#'
#' # Use them as the peer set for an honest rank
#' twin_ids <- peers$district_id
#' fetch_tges(2024)$CSG1 %>%
#'   tges_percentile_rank(peer = "custom", custom_ids = twin_ids) %>%
#'   filter(district_id == "3570") %>%
#'   select(`Per Pupil costs`, peer_percentile, peer_n)
#' }
#'
#' @export
tges_find_peers <- function(tges,
                            district_id,
                            n = 10,
                            year = NULL,
                            features = c("ade", "budgetary_pp", "classroom_share",
                                         "administration_share", "local_share",
                                         "state_share"),
                            calc_type = "Budgeted",
                            dfg_revision = 2000) {

  if (missing(district_id)) stop("`district_id` is required.")

  comp <- tges_composition(tges, calc_type = calc_type)
  if (!"end_year" %in% names(comp) || nrow(comp) == 0) {
    stop("No composition rows available to build features from.")
  }
  yr <- if (is.null(year)) max(comp$end_year, na.rm = TRUE) else year
  comp1 <- comp[comp$end_year == yr, , drop = FALSE]
  if (nrow(comp1) == 0) stop("No composition rows for year ", yr, ".")

  comp_cols <- intersect(
    c("budgetary_pp", "total_pp", "classroom_share", "administration_share",
      "support_services_share", "plant_ops_share"),
    names(comp1)
  )
  feat <- comp1 %>%
    dplyr::select(dplyr::all_of(c("county_name", "district_id", "district_name",
                                  "group")),
                  dplyr::all_of(comp_cols))

  ade_lk <- .tges_latest_ade(tges)
  if (!is.null(ade_lk)) {
    feat <- dplyr::left_join(feat, ade_lk[, c("district_id", "ade")],
                             by = "district_id")
  }

  rev <- tryCatch(tges_revenue_mix(tges), error = function(e) NULL)
  if (!is.null(rev)) {
    rev_cols <- intersect(c("local_share", "state_share", "federal_share"),
                          names(rev))
    if (length(rev_cols)) {
      rev_lk <- rev %>%
        dplyr::group_by(.data$district_id) %>%
        dplyr::arrange(.data$end_year, .by_group = TRUE) %>%
        dplyr::summarise(dplyr::across(dplyr::all_of(rev_cols), dplyr::last),
                         .groups = "drop")
      feat <- dplyr::left_join(feat, rev_lk, by = "district_id")
    }
  }

  # informational DFG (not part of the distance)
  dfg_lk <- tryCatch(
    fetch_dfg(revision = dfg_revision) %>%
      dplyr::group_by(.data$district_id) %>%
      dplyr::summarise(dfg = dplyr::first(.data$dfg), .groups = "drop"),
    error = function(e) NULL
  )
  if (!is.null(dfg_lk)) feat <- dplyr::left_join(feat, dfg_lk, by = "district_id")
  if (!"dfg" %in% names(feat)) feat$dfg <- NA_character_

  missing_feats <- setdiff(features, names(feat))
  if (length(missing_feats)) {
    stop("Requested feature(s) not available: ",
         paste(missing_feats, collapse = ", "),
         ". Available: ", paste(setdiff(names(feat),
           c("county_name", "district_id", "district_name", "group", "dfg")),
           collapse = ", "))
  }
  if (!district_id %in% feat$district_id) {
    stop("District ", district_id, " not found for year ", yr, ".")
  }

  fmat <- as.data.frame(feat[, features, drop = FALSE])
  if ("ade" %in% features) fmat$ade <- log(fmat$ade)

  # drop zero-variance features (constant -> no information, divides by 0)
  sds <- vapply(fmat, function(col) stats::sd(col, na.rm = TRUE), numeric(1))
  dead <- names(sds)[!is.finite(sds) | sds == 0]
  if (length(dead)) {
    warning("Dropping zero-variance feature(s) from the distance: ",
            paste(dead, collapse = ", "))
    fmat <- fmat[, setdiff(names(fmat), dead), drop = FALSE]
  }
  if (ncol(fmat) == 0) stop("No usable (non-constant) features remain.")

  cc <- stats::complete.cases(fmat)
  focal_row <- which(feat$district_id == district_id)[1]
  if (!cc[focal_row]) {
    stop("District ", district_id, " is missing one or more of the requested ",
         "features; cannot place it. Drop the feature or pick another district.")
  }

  mu  <- vapply(fmat[cc, , drop = FALSE], mean, numeric(1))
  sdv <- vapply(fmat[cc, , drop = FALSE], stats::sd, numeric(1))
  z <- sweep(sweep(as.matrix(fmat), 2, mu, "-"), 2, sdv, "/")
  focal_z <- z[focal_row, , drop = FALSE]
  diff <- sweep(z, 2, focal_z, "-")
  distance <- sqrt(rowSums(diff^2))

  feat$is_focal <- feat$district_id == district_id
  feat$distance <- round(distance, 4)
  feat <- feat[cc | feat$is_focal, , drop = FALSE]

  lead <- c("district_id", "district_name", "county_name", "group", "dfg",
            "is_focal", "distance")
  out <- feat %>%
    dplyr::arrange(dplyr::desc(.data$is_focal == FALSE), .data$distance) %>%
    dplyr::select(dplyr::all_of(lead), dplyr::all_of(features))
  # focal first, then the n nearest
  out <- out[order(!out$is_focal, out$distance), , drop = FALSE]
  utils::head(out, n + 1)
}


# -----------------------------------------------------------------------------
# tges_frontier()
# -----------------------------------------------------------------------------

# Free-disposal-hull input-oriented efficiency within one peer-year group.
# Input = spend (less is better), output = outcome (more is better).
# score_i = min{ spend_j : outcome_j >= outcome_i } / spend_i, in (0, 1].
# score 1 => on the frontier (nobody matches your outcome for less money).
.tges_fdh_group <- function(d) {
  spend   <- d$.spend
  outcome <- d$.outcome
  code <- d$district_id
  name <- if ("district_name" %in% names(d)) d$district_name else code
  k <- nrow(d)
  score    <- rep(NA_real_, k)
  ref_code <- rep(NA_character_, k)
  ref_name <- rep(NA_character_, k)
  ref_spd  <- rep(NA_real_, k)
  ok <- is.finite(spend) & is.finite(outcome) & spend > 0
  for (i in which(ok)) {
    dom  <- ok & outcome >= outcome[i]      # peers at least as good on outcome
    cand <- which(dom)
    best <- cand[which.min(spend[cand])]    # the one doing it for the least money
    ref_spd[i]  <- spend[best]
    score[i]    <- spend[best] / spend[i]
    ref_code[i] <- code[best]
    ref_name[i] <- name[best]
  }
  d$efficiency_score         <- round(score, 4)
  d$reference_district_id  <- ref_code
  d$reference_district_name  <- ref_name
  d$reference_spend          <- ref_spd
  d$excess_spend             <- d$.spend - ref_spd
  d$on_frontier              <- is.finite(score) & abs(score - 1) < 1e-9
  d
}

#' Spend-versus-outcome efficiency frontier (free-disposal hull)
#'
#' @description Where \code{tges_efficiency()} only labels a quadrant, this
#' computes a proper efficiency score against the free-disposal-hull frontier.
#' For each district it finds the peer that achieves at least the same outcome for
#' the least spend, and reports the ratio (0-1, 1 = on the frontier) plus that
#' reference district and the dollars overspent relative to it. This answers the
#' MarGrady brief's open cost-effectiveness question with a number, not a
#' quadrant: "Bayonne hits your graduation rate for $2,100/pupil less; you are at
#' 0.81 efficiency."
#'
#' @details The free-disposal hull (FDH) is the dependency-free efficiency
#' frontier: a district is efficient if no peer in the same group does at least as
#' well on the outcome for strictly less spend. The input-oriented score is
#' \code{min(spend among peers with outcome >= yours) / your spend}. It needs no
#' linear-programming solver and makes no functional-form assumption (unlike the
#' regression residual in \code{tges_efficiency()}). Spend is treated as the input
#' (lower is better) and the outcome as the output (higher is better); pass an
#' outcome where higher is better (a rate or a percentile).
#'
#' \strong{Cautions.} Use one consistent per-pupil definition for \code{spend_col}
#' (CSG1 budgetary vs CSG1AA total), filter \code{spend_df} to one
#' \code{calc_type}, and make sure the outcome and spend peer systems are stated.
#' The frontier is only as meaningful as the peer group: with few districts per
#' group, most land on the frontier by default.
#'
#' @param spend_df A tidied TGES table (one report year, one \code{calc_type})
#'   carrying \code{district_id} and \code{spend_col}.
#' @param outcome_df A district-level frame with \code{district_id}, the year
#'   column, and \code{outcome_col} (higher = better).
#' @param spend_col Character. Spend column in \code{spend_df}. Default
#'   \code{"Per Pupil costs"}.
#' @param outcome_col Character. Outcome column in \code{outcome_df}.
#' @param peer Character. Peer group for the frontier. One of \code{"tges_group"}
#'   (default), \code{"dfg"}, \code{"county"}, \code{"statewide"}.
#' @param year_col Character. Year column, present in both frames. Default
#'   \code{"end_year"}.
#' @param dfg_revision Numeric. DFG revision when \code{peer = "dfg"}. Default 2000.
#'
#' @return A tibble: entity columns, \code{peer_group}, the year, \code{spend},
#'   \code{outcome}, \code{efficiency_score}, \code{on_frontier},
#'   \code{reference_district_id}, \code{reference_district_name},
#'   \code{reference_spend}, and \code{excess_spend}.
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' grate <- fetch_grad_rate(2023, methodology = "4 year") %>%
#'   add_dfg() %>%
#'   filter(dfg == "A", is_district, subgroup == "total") %>%
#'   grate_percentile_rank(peer_type = "dfg")
#'
#' spend <- fetch_tges(2024)$CSG1 %>%
#'   filter(calc_type == "Actuals", end_year == 2023)
#'
#' fr <- tges_frontier(spend, grate, outcome_col = "grad_rate_percentile",
#'                     peer = "dfg")
#' fr %>% filter(district_id == "3570") %>%
#'   select(district_name, efficiency_score, reference_district_name, excess_spend)
#' }
#'
#' @export
tges_frontier <- function(spend_df,
                          outcome_df,
                          spend_col = "Per Pupil costs",
                          outcome_col,
                          peer = c("tges_group", "dfg", "county", "statewide"),
                          year_col = "end_year",
                          dfg_revision = 2000) {

  peer <- match.arg(peer)
  if (missing(outcome_col)) {
    stop("`outcome_col` is required (the outcome where higher = better).")
  }
  if (!spend_col %in% names(spend_df)) {
    stop(sprintf("Column '%s' not found in spend_df", spend_col))
  }
  if (!outcome_col %in% names(outcome_df)) {
    stop(sprintf("Column '%s' not found in outcome_df", outcome_col))
  }
  if (!"district_id" %in% names(outcome_df)) {
    stop("outcome_df must contain a `district_id` column.")
  }
  if (!all(c("district_id", year_col) %in% names(spend_df))) {
    stop(sprintf("spend_df must contain `district_id` and '%s'.", year_col))
  }

  sp <- spend_df %>%
    .tges_real_districts() %>%
    .tges_attach_peer(peer, dfg_revision = dfg_revision)
  sp$.spend <- suppressWarnings(as.numeric(sp[[spend_col]]))

  oc <- outcome_df %>%
    dplyr::select(
      dplyr::all_of(c("district_id", year_col)),
      .outcome = dplyr::all_of(outcome_col)
    ) %>%
    dplyr::distinct()

  by_vec <- stats::setNames(c("district_id", year_col), c("district_id", year_col))

  joined <- dplyr::inner_join(sp, oc, by = by_vec)
  if (nrow(joined) == 0) {
    stop("No district_id/", year_col, " rows matched between spend_df and ",
         "outcome_df.")
  }

  out <- joined %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(c(year_col, "peer_group")))) %>%
    dplyr::group_modify(~ .tges_fdh_group(.x)) %>%
    dplyr::ungroup() %>%
    dplyr::rename(spend = ".spend", outcome = ".outcome")

  lead <- intersect(
    c("county_name", "district_id", "district_name", "peer_group", year_col,
      "calc_type", "spend", "outcome", "efficiency_score", "on_frontier",
      "reference_district_id", "reference_district_name", "reference_spend",
      "excess_spend"),
    names(out)
  )
  out %>% dplyr::select(dplyr::all_of(lead), dplyr::everything())
}


# -----------------------------------------------------------------------------
# tges_convergence()
# -----------------------------------------------------------------------------

# OLS of growth on initial log level within one peer group; NA-safe, returns the
# slope (beta), its p-value, and R^2. Negative beta = convergence.
.tges_convergence_fit <- function(growth, log_start) {
  ok <- is.finite(growth) & is.finite(log_start)
  res <- list(beta = NA_real_, beta_pvalue = NA_real_,
              r_squared = NA_real_, n_districts = sum(ok))
  if (sum(ok) >= 4 && stats::sd(log_start[ok]) > 0) {
    m <- stats::lm(growth[ok] ~ log_start[ok])
    sm <- summary(m)
    co <- sm$coefficients
    if (nrow(co) >= 2) {
      res$beta        <- unname(co[2, 1])
      res$beta_pvalue <- unname(co[2, 4])
      res$r_squared   <- sm$r.squared
    }
  }
  res
}

#' Beta-convergence of spending across a peer group
#'
#' @description Are spending gaps within a peer group closing or widening? This
#' is the classic public-finance convergence test, pointed at school dollars: it
#' regresses each district's growth in per-pupil spend on its starting level,
#' within each peer group. A negative slope (beta) means low-spenders grew faster
#' and the group is converging; a positive slope means the high-spenders pulled
#' further ahead (divergence).
#'
#' @details Needs a multi-year input (\code{fetch_many_tges()}). For each district
#' the function takes the metric at \code{start_year} and \code{end_year}, drops
#' to one value per district-year, and computes annualized log growth
#' \eqn{(\ln v_{end} - \ln v_{start}) / (end - start)}. Within each peer group it
#' fits \code{growth ~ log(start_value)} by OLS (requires >= 4 districts with both
#' endpoints and starting-level variation). The slope and its stats are broadcast
#' onto every district row in the group, so the same frame both plots the
#' convergence scatter (\code{log_start_value} vs \code{growth}) and reports the
#' group beta. For one peer group's headline, take
#' \code{distinct(peer_group, beta, beta_pvalue, r_squared, n_districts, converging)}.
#'
#' @param tges Output of \code{fetch_many_tges()} (multi-year).
#' @param metric_col Character. Numeric column to track. Default
#'   \code{"Per Pupil costs"}.
#' @param table Character. TGES table code carrying \code{metric_col}. Default
#'   \code{"CSG1"} (budgetary per-pupil cost).
#' @param peer Character. Peer group. One of \code{"tges_group"} (default),
#'   \code{"dfg"}, \code{"county"}, \code{"statewide"}.
#' @param start_year,end_year Numeric. Endpoints. Default: the min and max
#'   \code{end_year} present.
#' @param calc_type Character. Calc type to keep. Default \code{"Budgeted"}.
#' @param dfg_revision Numeric. DFG revision when \code{peer = "dfg"}. Default 2000.
#'
#' @return A per-district tibble: entity columns, \code{peer_group},
#'   \code{start_year}, \code{end_year}, \code{start_value}, \code{end_value},
#'   \code{log_start_value}, \code{growth}, and the broadcast group statistics
#'   \code{beta}, \code{beta_pvalue}, \code{r_squared}, \code{n_districts}, and
#'   \code{converging} (\code{beta < 0} and \code{beta_pvalue < 0.05}).
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' conv <- tges_convergence(fetch_many_tges(2015:2024), peer = "dfg")
#'
#' # one row per peer group: is each DFG converging on spend?
#' conv %>% distinct(peer_group, beta, beta_pvalue, converging, n_districts)
#' }
#'
#' @export
tges_convergence <- function(tges,
                             metric_col = "Per Pupil costs",
                             table = "CSG1",
                             peer = c("tges_group", "dfg", "county", "statewide"),
                             start_year = NULL,
                             end_year = NULL,
                             calc_type = "Budgeted",
                             dfg_revision = 2000) {

  peer <- match.arg(peer)
  tbl <- .tges_get_table(tges, table)
  if (is.null(tbl) || !metric_col %in% names(tbl)) {
    stop("Table '", table, "' with column '", metric_col, "' not found in `tges`.")
  }
  tbl <- .tges_real_districts(tbl)
  if (!is.null(calc_type) && "calc_type" %in% names(tbl)) {
    tbl <- tbl[tbl$calc_type %in% calc_type, , drop = FALSE]
  }
  if (!"end_year" %in% names(tbl) || nrow(tbl) == 0) {
    stop("No usable rows in table '", table, "'.")
  }

  yrs <- sort(unique(tbl$end_year))
  sy <- if (is.null(start_year)) min(yrs) else start_year
  ey <- if (is.null(end_year))   max(yrs) else end_year
  if (sy == ey) stop("start_year and end_year must differ (got ", sy, ").")

  keys <- intersect(c("county_name", "district_id", "district_name", "group"),
                    names(tbl))
  vals <- tbl %>%
    dplyr::filter(.data$end_year %in% c(sy, ey)) %>%
    dplyr::transmute(
      dplyr::across(dplyr::all_of(keys)),
      end_year = .data$end_year,
      .v = suppressWarnings(as.numeric(.data[[metric_col]]))
    ) %>%
    dplyr::distinct(.data$district_id, .data$end_year, .keep_all = TRUE)

  wide <- vals %>%
    dplyr::mutate(.which = dplyr::if_else(.data$end_year == sy, "start_value",
                                          "end_value")) %>%
    dplyr::select(-"end_year") %>%
    tidyr::pivot_wider(names_from = ".which", values_from = ".v") %>%
    dplyr::filter(is.finite(.data$start_value), is.finite(.data$end_value),
                  .data$start_value > 0, .data$end_value > 0)

  if (nrow(wide) == 0) {
    stop("No districts have both ", sy, " and ", ey, " values for '",
         metric_col, "'.")
  }

  span <- ey - sy
  wide <- wide %>%
    .tges_attach_peer(peer, dfg_revision = dfg_revision) %>%
    dplyr::mutate(
      start_year = sy,
      end_year   = ey,
      log_start_value = log(.data$start_value),
      growth = (log(.data$end_value) - log(.data$start_value)) / span
    )

  out <- wide %>%
    dplyr::group_by(.data$peer_group) %>%
    dplyr::group_modify(function(d, key) {
      fit <- .tges_convergence_fit(d$growth, d$log_start_value)
      d$beta        <- fit$beta
      d$beta_pvalue <- fit$beta_pvalue
      d$r_squared   <- fit$r_squared
      d$n_districts <- fit$n_districts
      d
    }) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      converging = is.finite(.data$beta) & .data$beta < 0 &
        is.finite(.data$beta_pvalue) & .data$beta_pvalue < 0.05
    )

  lead <- intersect(
    c("county_name", "district_id", "district_name", "peer_group",
      "start_year", "end_year", "start_value", "end_value", "log_start_value",
      "growth", "beta", "beta_pvalue", "r_squared", "n_districts", "converging"),
    names(out)
  )
  out %>% dplyr::select(dplyr::all_of(lead), dplyr::everything())
}


# -----------------------------------------------------------------------------
# tges_composition_drift()
# -----------------------------------------------------------------------------

#' Ranked composition-share drift versus peers
#'
#' @description Where did a district's budget move, and how does that move rank
#' against its peers? This takes the spending-share composition at two years and
#' returns the drift (end minus start, in share points) for each tracked
#' category, then ranks one chosen drift (classroom share by default) within the
#' peer group. The output is the "Newark moved 4 points from classroom to plant
#' O&M, the 2nd-largest classroom-share decline in DFG A" finding.
#'
#' @param tges Output of \code{fetch_many_tges()} (multi-year).
#' @param start_year,end_year Numeric. Endpoints. Default: min and max present.
#' @param shares Character vector of share columns from \code{tges_composition()}
#'   to compute drift for. Default classroom / administration / support_services /
#'   plant_ops shares.
#' @param rank_on Character. Which share's drift to percentile-rank within the
#'   peer group. Default \code{"classroom_share"}.
#' @param peer Character. Peer group. One of \code{"tges_group"} (default),
#'   \code{"dfg"}, \code{"county"}, \code{"statewide"}.
#' @param calc_type Character. Composition calc type. Default \code{"Budgeted"}.
#' @param dfg_revision Numeric. DFG revision when \code{peer = "dfg"}. Default 2000.
#'
#' @return A per-district tibble: entity columns, \code{peer_group},
#'   \code{start_year}, \code{end_year}, a \code{{share}_start},
#'   \code{{share}_end}, and \code{{share}_drift} triple per tracked share, and
#'   the rank columns \code{drift_rank}, \code{drift_n}, \code{drift_percentile}
#'   for \code{rank_on} (computed on the signed drift, so a larger positive drift
#'   ranks higher).
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' drift <- tges_composition_drift(fetch_many_tges(2019:2024), peer = "dfg")
#'
#' # biggest classroom-share declines among DFG A
#' drift %>%
#'   arrange(classroom_share_drift) %>%
#'   select(district_name, classroom_share_start, classroom_share_end,
#'          classroom_share_drift, drift_percentile) %>%
#'   head(10)
#' }
#'
#' @export
tges_composition_drift <- function(tges,
                                   start_year = NULL,
                                   end_year = NULL,
                                   shares = c("classroom_share", "administration_share",
                                              "support_services_share", "plant_ops_share"),
                                   rank_on = "classroom_share",
                                   peer = c("tges_group", "dfg", "county", "statewide"),
                                   calc_type = "Budgeted",
                                   dfg_revision = 2000) {

  peer <- match.arg(peer)
  comp <- tges_composition(tges, calc_type = calc_type)
  if (!"end_year" %in% names(comp) || nrow(comp) == 0) {
    stop("No composition rows available.")
  }
  shares <- intersect(shares, names(comp))
  if (length(shares) == 0) {
    stop("None of the requested share columns are present in the composition.")
  }
  if (!rank_on %in% shares) {
    stop("`rank_on` ('", rank_on, "') must be one of the tracked `shares`.")
  }

  yrs <- sort(unique(comp$end_year))
  sy <- if (is.null(start_year)) min(yrs) else start_year
  ey <- if (is.null(end_year))   max(yrs) else end_year
  if (sy == ey) stop("start_year and end_year must differ (got ", sy, ").")

  keys <- intersect(c("county_name", "district_id", "district_name", "group"),
                    names(comp))

  two <- comp %>%
    dplyr::filter(.data$end_year %in% c(sy, ey)) %>%
    dplyr::select(dplyr::all_of(keys), "end_year", dplyr::all_of(shares)) %>%
    dplyr::distinct(.data$district_id, .data$end_year, .keep_all = TRUE)

  start_df <- two %>% dplyr::filter(.data$end_year == sy) %>%
    dplyr::select(-"end_year") %>%
    dplyr::rename_with(~ paste0(.x, "_start"), dplyr::all_of(shares))
  end_df <- two %>% dplyr::filter(.data$end_year == ey) %>%
    dplyr::select(dplyr::all_of(c("district_id", shares))) %>%
    dplyr::rename_with(~ paste0(.x, "_end"), dplyr::all_of(shares))

  out <- dplyr::inner_join(start_df, end_df, by = "district_id")
  if (nrow(out) == 0) {
    stop("No districts have both ", sy, " and ", ey, " composition rows.")
  }

  for (sh in shares) {
    out[[paste0(sh, "_drift")]] <- out[[paste0(sh, "_end")]] -
      out[[paste0(sh, "_start")]]
  }
  out$start_year <- sy
  out$end_year   <- ey

  drift_col <- paste0(rank_on, "_drift")
  out <- out %>%
    .tges_attach_peer(peer, dfg_revision = dfg_revision) %>%
    dplyr::group_by(.data$peer_group) %>%
    add_percentile_rank(drift_col, prefix = "drift") %>%
    dplyr::ungroup()

  drift_triples <- as.vector(rbind(paste0(shares, "_start"),
                                   paste0(shares, "_end"),
                                   paste0(shares, "_drift")))
  lead <- intersect(
    c(keys, "peer_group", "start_year", "end_year", drift_triples,
      "drift_rank", "drift_n", "drift_percentile"),
    names(out)
  )
  out %>% dplyr::select(dplyr::all_of(lead), dplyr::everything())
}


# -----------------------------------------------------------------------------
# tges_gap_cost()
# -----------------------------------------------------------------------------

#' Translate a peer gap into per-pupil and total dollars
#'
#' @description The board/taxpayer-facing translation: "matching the DFG A median
#' classroom share would cost $X per pupil, $Y district-wide." Given a focal
#' district and a composition metric, it computes the gap to a peer benchmark and
#' converts it to dollars, using the district's budgetary per-pupil cost (for a
#' share metric) and its latest reported enrollment (for the district-wide total).
#'
#' @details For a \code{*_share} metric, the per-pupil dollar gap is
#' \code{(target_share - focal_share) * budgetary_pp}; for a per-pupil dollar
#' metric (e.g. \code{classroom}) the gap is already in dollars per pupil. The
#' district-wide total multiplies the per-pupil gap by the latest \code{CSG1AA}
#' average daily enrollment (reported in \code{ade}/\code{ade_year}; this is the
#' most recent actuals year, which may differ from the composition year). A
#' positive gap means the district spends \emph{less} than the benchmark and would
#' need to add dollars to reach it; a negative gap means it already exceeds the
#' benchmark.
#'
#' @param tges Output of \code{fetch_tges()} or \code{fetch_many_tges()}.
#' @param district_id Character. The 4-digit focal district code.
#' @param metric Character. A column from \code{tges_composition()}. Default
#'   \code{"classroom_share"}.
#' @param target Benchmark within the peer group: \code{"median"} (default),
#'   \code{"mean"}, \code{"max"}, or a numeric quantile in \code{[0, 1]}.
#' @param peer Character. Peer group. One of \code{"tges_group"} (default),
#'   \code{"dfg"}, \code{"county"}, \code{"statewide"}.
#' @param year Numeric. Composition report year. Default: latest present.
#' @param calc_type Character. Composition calc type. Default \code{"Budgeted"}.
#' @param dfg_revision Numeric. DFG revision when \code{peer = "dfg"}. Default 2000.
#'
#' @return A one-row tibble: entity columns, \code{peer_group}, \code{n_peers},
#'   \code{metric}, \code{focal_value}, \code{target_basis}, \code{target_value},
#'   \code{gap}, \code{budgetary_pp}, \code{per_pupil_gap_dollars}, \code{ade},
#'   \code{ade_year}, and \code{total_gap_dollars}.
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' # What would it cost Newark to reach the DFG A median classroom share?
#' tges_gap_cost(fetch_tges(2024), district_id = "3570",
#'               metric = "classroom_share", target = "median", peer = "dfg")
#' }
#'
#' @export
tges_gap_cost <- function(tges,
                          district_id,
                          metric = "classroom_share",
                          target = "median",
                          peer = c("tges_group", "dfg", "county", "statewide"),
                          year = NULL,
                          calc_type = "Budgeted",
                          dfg_revision = 2000) {

  peer <- match.arg(peer)
  if (missing(district_id)) stop("`district_id` is required.")

  comp <- tges_composition(tges, calc_type = calc_type)
  if (!metric %in% names(comp)) {
    stop("Metric '", metric, "' is not a tges_composition() column.")
  }
  yr <- if (is.null(year)) max(comp$end_year, na.rm = TRUE) else year
  comp1 <- comp[comp$end_year == yr, , drop = FALSE] %>%
    .tges_attach_peer(peer, dfg_revision = dfg_revision)

  focal <- comp1[comp1$district_id == district_id, , drop = FALSE]
  if (nrow(focal) == 0) {
    stop("District ", district_id, " not found for year ", yr, ".")
  }
  focal <- focal[1, , drop = FALSE]
  pg <- focal$peer_group

  peers <- comp1[!is.na(comp1$peer_group) & comp1$peer_group == pg, , drop = FALSE]
  vals <- suppressWarnings(as.numeric(peers[[metric]]))
  vals <- vals[is.finite(vals)]
  if (length(vals) == 0) stop("No finite peer values for '", metric, "'.")

  if (is.numeric(target)) {
    if (target < 0 || target > 1) stop("Numeric `target` must be a quantile in [0, 1].")
    target_value <- unname(stats::quantile(vals, probs = target, names = FALSE))
    target_basis <- paste0("p", round(target * 100))
  } else {
    target_basis <- match.arg(target, c("median", "mean", "max"))
    target_value <- switch(target_basis,
      median = stats::median(vals),
      mean   = mean(vals),
      max    = max(vals)
    )
  }

  focal_value <- suppressWarnings(as.numeric(focal[[metric]]))
  gap <- target_value - focal_value
  budgetary_pp <- if ("budgetary_pp" %in% names(focal)) {
    suppressWarnings(as.numeric(focal$budgetary_pp))
  } else NA_real_

  is_share <- grepl("_share$", metric)
  per_pupil_gap <- if (is_share) gap * budgetary_pp else gap

  ade_lk <- .tges_latest_ade(tges)
  ade <- NA_real_; ade_year <- NA_real_
  if (!is.null(ade_lk)) {
    row <- ade_lk[ade_lk$district_id == district_id, , drop = FALSE]
    if (nrow(row)) { ade <- row$ade[1]; ade_year <- row$ade_year[1] }
  }

  tibble::tibble(
    county_name   = focal$county_name,
    district_id = district_id,
    district_name = focal$district_name,
    peer_group    = pg,
    n_peers       = length(vals),
    metric        = metric,
    focal_value   = focal_value,
    target_basis  = target_basis,
    target_value  = target_value,
    gap           = gap,
    budgetary_pp  = budgetary_pp,
    per_pupil_gap_dollars = round(per_pupil_gap),
    ade           = ade,
    ade_year      = ade_year,
    total_gap_dollars = round(per_pupil_gap * ade)
  )
}


# -----------------------------------------------------------------------------
# tges_volatility()
# -----------------------------------------------------------------------------

#' Year-to-year funding volatility, ranked against peers
#'
#' @description How bumpy is a district's funding, and is it more fragile than its
#' peers? For a chosen series this computes per-district volatility across the
#' available years (coefficient of variation plus the typical and worst
#' year-over-year swing) and ranks it within the peer group. Pointed at the
#' federal-revenue share it is the quantitative companion to the ESSER-cliff
#' screen; pointed at total per-pupil spend it flags districts whose budgets lurch
#' from year to year.
#'
#' @details Needs a multi-year input (\code{fetch_many_tges()}). The metric is
#' pulled from \code{tges_revenue_mix()} (e.g. \code{total_pp}, \code{federal_share},
#' \code{local_share}), else \code{tges_composition()} (e.g. \code{classroom_share}),
#' else a per-pupil cost table column. Districts with fewer than \code{min_years}
#' finite observations are dropped. \code{cv} is \code{sd / |mean|};
#' \code{mean_abs_yoy} and \code{max_abs_yoy} are the mean and max absolute
#' year-over-year percent change. The volatility rank is computed on \code{cv}
#' within the peer group (higher cv = higher percentile = more volatile).
#'
#' @param tges Output of \code{fetch_many_tges()} (multi-year).
#' @param metric Character. Series to measure. Default \code{"total_pp"}.
#' @param peer Character. Peer group. One of \code{"tges_group"} (default),
#'   \code{"dfg"}, \code{"county"}, \code{"statewide"}.
#' @param min_years Integer. Minimum finite observations per district. Default 3.
#' @param table Character. Per-pupil cost table to source \code{metric} from when
#'   it is neither a revenue-mix nor a composition column. Default \code{"CSG1"}.
#' @param calc_type Character. Calc type for composition/table sources. Default
#'   \code{"Budgeted"}.
#' @param dfg_revision Numeric. DFG revision when \code{peer = "dfg"}. Default 2000.
#'
#' @return A per-district tibble: entity columns, \code{peer_group},
#'   \code{n_years}, \code{mean_value}, \code{sd_value}, \code{cv},
#'   \code{mean_abs_yoy}, \code{max_abs_yoy}, and the rank columns
#'   \code{vol_rank}, \code{vol_n}, \code{vol_percentile}.
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' # Whose federal-revenue share whipsawed the most through the ESSER years?
#' tges_volatility(fetch_many_tges(2018:2025), metric = "federal_share",
#'                 peer = "dfg") %>%
#'   arrange(desc(vol_percentile)) %>%
#'   select(district_name, mean_value, cv, max_abs_yoy, vol_percentile) %>%
#'   head(10)
#' }
#'
#' @export
tges_volatility <- function(tges,
                            metric = "total_pp",
                            peer = c("tges_group", "dfg", "county", "statewide"),
                            min_years = 3,
                            table = "CSG1",
                            calc_type = "Budgeted",
                            dfg_revision = 2000) {

  peer <- match.arg(peer)

  # source the series: revenue mix -> composition -> per-pupil cost table
  series <- NULL
  rev <- tryCatch(tges_revenue_mix(tges), error = function(e) NULL)
  if (!is.null(rev) && metric %in% names(rev)) {
    series <- rev %>%
      dplyr::transmute(
        dplyr::across(dplyr::any_of(c("county_name", "district_id",
                                      "district_name", "group"))),
        end_year = .data$end_year,
        .v = suppressWarnings(as.numeric(.data[[metric]]))
      )
  }
  if (is.null(series)) {
    comp <- tryCatch(tges_composition(tges, calc_type = calc_type),
                     error = function(e) NULL)
    if (!is.null(comp) && metric %in% names(comp)) {
      series <- comp %>%
        dplyr::transmute(
          dplyr::across(dplyr::any_of(c("county_name", "district_id",
                                        "district_name", "group"))),
          end_year = .data$end_year,
          .v = suppressWarnings(as.numeric(.data[[metric]]))
        )
    }
  }
  if (is.null(series)) {
    tbl <- .tges_get_table(tges, table)
    if (!is.null(tbl) && metric %in% names(tbl)) {
      tbl <- .tges_real_districts(tbl)
      if (!is.null(calc_type) && "calc_type" %in% names(tbl)) {
        tbl <- tbl[tbl$calc_type %in% calc_type, , drop = FALSE]
      }
      series <- tbl %>%
        dplyr::transmute(
          dplyr::across(dplyr::any_of(c("county_name", "district_id",
                                        "district_name", "group"))),
          end_year = .data$end_year,
          .v = suppressWarnings(as.numeric(.data[[metric]]))
        )
    }
  }
  if (is.null(series)) {
    stop("Metric '", metric, "' not found in revenue mix, composition, or table '",
         table, "'.")
  }

  series <- series %>%
    dplyr::filter(is.finite(.data$.v)) %>%
    dplyr::distinct(.data$district_id, .data$end_year, .keep_all = TRUE)

  meta <- series %>%
    dplyr::group_by(.data$district_id) %>%
    dplyr::summarise(dplyr::across(dplyr::any_of(c("county_name", "district_name",
                                                   "group")), dplyr::first),
                     .groups = "drop")

  stats_df <- series %>%
    dplyr::group_by(.data$district_id) %>%
    dplyr::arrange(.data$end_year, .by_group = TRUE) %>%
    dplyr::summarise(
      n_years    = dplyr::n(),
      mean_value = mean(.data$.v),
      sd_value   = stats::sd(.data$.v),
      mean_abs_yoy = mean(abs(.data$.v / dplyr::lag(.data$.v) - 1), na.rm = TRUE),
      max_abs_yoy  = suppressWarnings(max(abs(.data$.v / dplyr::lag(.data$.v) - 1),
                                          na.rm = TRUE)),
      .groups = "drop"
    ) %>%
    dplyr::filter(.data$n_years >= min_years) %>%
    dplyr::mutate(
      cv = dplyr::if_else(is.finite(.data$mean_value) & .data$mean_value != 0,
                          .data$sd_value / abs(.data$mean_value), NA_real_),
      max_abs_yoy = dplyr::if_else(is.finite(.data$max_abs_yoy),
                                   .data$max_abs_yoy, NA_real_)
    )

  if (nrow(stats_df) == 0) {
    stop("No district has at least ", min_years, " years of '", metric, "'.")
  }

  out <- stats_df %>%
    dplyr::left_join(meta, by = "district_id") %>%
    .tges_attach_peer(peer, dfg_revision = dfg_revision) %>%
    dplyr::group_by(.data$peer_group) %>%
    add_percentile_rank("cv", prefix = "vol") %>%
    dplyr::ungroup()

  lead <- intersect(
    c("county_name", "district_id", "district_name", "peer_group",
      "n_years", "mean_value", "sd_value", "cv", "mean_abs_yoy", "max_abs_yoy",
      "vol_rank", "vol_n", "vol_percentile"),
    names(out)
  )
  out %>% dplyr::select(dplyr::all_of(lead), dplyr::everything())
}


# -----------------------------------------------------------------------------
# tges_compare()
# -----------------------------------------------------------------------------

#' A side-by-side fiscal scorecard for a named set of districts
#'
#' @description The "counterfactual cities" table: line up several districts on
#' the headline fiscal metrics in one frame. It assembles the per-pupil totals and
#' composition shares, the revenue mix, the staffing ratios and salaries, and the
#' excess-surplus flag, one row per district, so different reform strategies and
#' cost structures sit next to each other.
#'
#' @details This is assembly over the existing primitives
#' (\code{tges_composition()}, \code{tges_revenue_mix()}, \code{tges_staffing()},
#' \code{tges_fund_balance_health()}). Each metric is pulled at \code{year} when a
#' row for that year exists, otherwise at that source's latest available year for
#' the district (revenue and personnel tables report a different year than the
#' budgeted composition, so strict year-alignment would blank most cells). The
#' \code{*_year} columns record which year each block came from.
#'
#' @param tges Output of \code{fetch_tges()} or \code{fetch_many_tges()}.
#' @param district_codes Character vector of 4-digit district codes to compare.
#' @param year Numeric. Preferred report year. Default: latest composition year.
#' @param calc_type Character. Composition calc type. Default \code{"Budgeted"}.
#'
#' @return A tibble, one row per requested district, with entity columns and the
#'   headline metrics (\code{total_pp}, \code{budgetary_pp},
#'   \code{classroom_share}, \code{administration_share}, \code{local_share},
#'   \code{state_share}, \code{federal_share}, \code{student_teacher_ratio},
#'   \code{student_admin_ratio}, \code{teacher_salary}, \code{benefits_pct_salary},
#'   \code{excess_surplus_flag}) plus \code{comp_year}, \code{revenue_year},
#'   \code{staffing_year}.
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' big_cities <- c("3570", "0680", "5210", "4010", "2330", "1330")  # Newark, Camden, ...
#' tges_compare(fetch_tges(2024), district_codes = big_cities) %>%
#'   select(district_name, total_pp, classroom_share, local_share,
#'          student_admin_ratio, excess_surplus_flag)
#' }
#'
#' @export
tges_compare <- function(tges,
                         district_codes,
                         year = NULL,
                         calc_type = "Budgeted") {

  if (missing(district_codes) || length(district_codes) == 0) {
    stop("`district_codes` must be a non-empty character vector.")
  }

  # pick the row at `year` if present, else the latest year, per district
  pick <- function(df, cols, codes, prefer_year) {
    if (is.null(df) || !all(c("district_id", "end_year") %in% names(df))) {
      return(NULL)
    }
    have <- intersect(cols, names(df))
    if (length(have) == 0) return(NULL)
    df %>%
      dplyr::filter(.data$district_id %in% codes, is.finite(.data$end_year)) %>%
      dplyr::group_by(.data$district_id) %>%
      dplyr::arrange(.data$end_year, .by_group = TRUE) %>%
      dplyr::slice(if (!is.null(prefer_year) && any(.data$end_year == prefer_year)) {
        utils::tail(which(.data$end_year == prefer_year), 1)
      } else {
        dplyr::n()
      }) %>%
      dplyr::ungroup() %>%
      dplyr::select(dplyr::all_of(c("district_id", have)),
                    dplyr::any_of("end_year"))
  }

  comp <- tges_composition(tges, calc_type = calc_type)
  cy <- if (is.null(year)) max(comp$end_year, na.rm = TRUE) else year

  base <- comp %>%
    dplyr::filter(.data$district_id %in% district_codes) %>%
    dplyr::group_by(.data$district_id) %>%
    dplyr::arrange(.data$end_year, .by_group = TRUE) %>%
    dplyr::slice(if (any(.data$end_year == cy)) {
      utils::tail(which(.data$end_year == cy), 1)
    } else dplyr::n()) %>%
    dplyr::ungroup() %>%
    dplyr::transmute(
      .data$county_name, .data$district_id, .data$district_name, .data$group,
      comp_year = .data$end_year,
      budgetary_pp = .data$budgetary_pp,
      classroom_share = .data$classroom_share,
      administration_share = .data$administration_share
    )

  # total per-pupil comes from VITSTAT, not composition: the budgeted CSG1AA
  # total is absent, so composition$total_pp is NA in the Budgeted scorecard.
  rev <- tryCatch(tges_revenue_mix(tges), error = function(e) NULL)
  rev1 <- pick(rev, c("total_pp", "local_share", "state_share", "federal_share"),
               district_codes, year)
  if (!is.null(rev1)) {
    names(rev1)[names(rev1) == "end_year"] <- "revenue_year"
    base <- dplyr::left_join(base, rev1, by = "district_id")
  }

  st <- tryCatch(tges_staffing(tges), error = function(e) NULL)
  st1 <- pick(st, c("student_teacher_ratio", "student_admin_ratio",
                    "teacher_salary", "benefits_pct_salary"),
              district_codes, year)
  if (!is.null(st1)) {
    names(st1)[names(st1) == "end_year"] <- "staffing_year"
    base <- dplyr::left_join(base, st1, by = "district_id")
  }

  fb <- tryCatch(tges_fund_balance_health(tges), error = function(e) NULL)
  fb1 <- pick(fb, c("excess_surplus_flag"), district_codes, year)
  if (!is.null(fb1)) {
    fb1$end_year <- NULL
    base <- dplyr::left_join(base, fb1, by = "district_id")
  }

  # keep the requested order, warn on any not found
  missing_codes <- setdiff(district_codes, base$district_id)
  if (length(missing_codes)) {
    warning("No data for district code(s): ", paste(missing_codes, collapse = ", "))
  }
  base %>%
    dplyr::arrange(match(.data$district_id, district_codes))
}


# -----------------------------------------------------------------------------
# tges_excluded_costs()
# -----------------------------------------------------------------------------

#' What the budgetary per-pupil figure leaves out (incl. on-behalf TPAF pension)
#'
#' @description NJ's headline comparative measure, \emph{Budgetary Per Pupil Cost}
#' (CSG1), deliberately excludes a long list of spending, most notably the
#' state-paid on-behalf TPAF pension, post-retirement medical, and social
#' security contributions, which by law are paid by the state and never appear in
#' a district's own budget.  This helper joins the Total Spending Detail workbook
#' (a 2024+ TGES table) to CSG1 so you can see, per district-year, every component
#' that sits between budgetary cost and total spending.
#'
#' @details
#' The Detail workbook splits \emph{Total Spending Per Pupil} into six components
#' that sum to the published total; this helper returns them as clean per-pupil
#' columns:
#' \itemize{
#'   \item \code{general_current_expense_pp} -- general-fund current expense
#'     (this is where on-behalf TPAF, transportation, tuition, and judgments live)
#'   \item \code{capital_outlay_pp}, \code{grants_entitlements_pp},
#'     \code{food_services_pp}, \code{debt_service_local_pp},
#'     \code{debt_service_sda_pp} -- the other five components
#' }
#'
#' It then computes two differences against the budgetary per-pupil cost:
#' \itemize{
#'   \item \code{excluded_total_pp} = \code{total_spending_pp - budgetary_pp}.
#'     This is the full wedge of \emph{everything} excluded from the budgetary
#'     figure: on-behalf TPAF pension/PRM/social security \strong{plus}
#'     transportation, capital outlay, grants/entitlements, food service, tuition,
#'     debt service, and judgments.
#'   \item \code{gce_excess_pp} = \code{general_current_expense_pp - budgetary_pp}.
#'     A narrower residual: general-fund items excluded from budgetary cost, i.e.
#'     roughly \emph{transportation + on-behalf TPAF + tuition + judgments}.
#' }
#'
#' \strong{Neither difference isolates pension.}  No public TGES file breaks out
#' the on-behalf TPAF line; it is buried inside General Current Expense alongside
#' transportation and tuition.  An itemized per-district pension figure exists
#' only in NJDOE's login-gated AudSum submission.  Treat \code{gce_excess_pp} as
#' an upper bound on pension, not a measurement of it.
#'
#' \strong{Denominator caveat.}  Budgetary per-pupil cost divides by resident
#' enrollment; the Detail per-pupil amounts divide by enrollment \emph{plus sent
#' pupils}.  For districts that educate all their own pupils the two agree within
#' ~1\%, but for sending districts (including big cities that place special-ed or
#' vocational pupils out of district) the denominators diverge and the per-pupil
#' subtraction breaks down.  \code{sent_pupil_share} reports
#' \code{(enrollment_plus_sent - resident_enrollment) / enrollment_plus_sent}, and
#' \code{residual_reliable} is \code{TRUE} only when that share is at or below
#' \code{reliable_max_sent_share}.  Filter to \code{residual_reliable} before
#' reading anything into \code{gce_excess_pp}.
#'
#' Total Spending Detail tables ship only in the 2024 guide onward, so this needs
#' \code{fetch_tges(2024)} or later (each guide carries two prior fiscal years).
#'
#' @param tges Output of \code{fetch_tges()} or \code{fetch_many_tges()} for a
#'   2024+ guide.
#' @param years Optional numeric vector. Keep only these \code{end_year} values.
#' @param reliable_max_sent_share Numeric in [0, 1]; the maximum sent-pupil share
#'   for which the per-pupil differences are treated as reliable. Default 0.02.
#'
#' @return A tibble with one row per district-year: entity columns,
#'   \code{end_year}, \code{budgetary_pp}, the six Detail components,
#'   \code{total_spending_pp}, \code{excluded_total_pp}, \code{gce_excess_pp},
#'   \code{enrollment_plus_sent}, \code{budgetary_denom}, \code{sent_pupil_share},
#'   and the logical \code{residual_reliable}.
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' # All excluded-cost components for the latest two fiscal years
#' tges_excluded_costs(fetch_tges(2025)) %>%
#'   select(district_name, end_year, budgetary_pp, total_spending_pp,
#'          excluded_total_pp, gce_excess_pp)
#'
#' # Only districts where the residual is denominator-reliable (self-contained),
#' # ranked by the general-fund excess (~ transportation + on-behalf TPAF)
#' tges_excluded_costs(fetch_tges(2025)) %>%
#'   filter(residual_reliable, end_year == 2024) %>%
#'   arrange(desc(gce_excess_pp)) %>%
#'   select(district_name, budgetary_pp, gce_excess_pp, sent_pupil_share)
#'
#' # Track one district's excluded-cost wedge across guides
#' tges_excluded_costs(fetch_many_tges(2024:2025)) %>%
#'   filter(district_id == "3570") %>%
#'   select(end_year, budgetary_pp, gce_excess_pp, excluded_total_pp)
#' }
#'
#' @export
tges_excluded_costs <- function(tges, years = NULL,
                                reliable_max_sent_share = 0.02) {

  detail <- .tges_get_detail(tges)
  if (is.null(detail) || !nrow(detail)) {
    stop("No Total Spending Detail table (DETAIL_FY##) found in `tges`. These ",
         "ship only in 2024+ guides; pass fetch_tges(2024) or later.",
         call. = FALSE)
  }
  detail <- .tges_real_districts(detail)

  budg <- .tges_get_table(tges, "CSG1")
  if (is.null(budg) || !nrow(budg)) {
    stop("No CSG1 (budgetary per-pupil cost) table found in `tges`.",
         call. = FALSE)
  }
  budg <- budg %>%
    dplyr::filter(.data$calc_type == "Actuals") %>%
    .tges_real_districts() %>%
    dplyr::transmute(
      county_name   = .data$county_name,
      district_id = .data$district_id,
      end_year      = .data$end_year,
      budgetary_pp    = suppressWarnings(as.numeric(.data[["Per Pupil costs"]])),
      budgetary_denom = suppressWarnings(as.numeric(.data[["Enrollment (ADE)"]]))
    ) %>%
    dplyr::distinct()

  out <- detail %>%
    dplyr::inner_join(budg, by = c("county_name", "district_id", "end_year")) %>%
    dplyr::mutate(
      excluded_total_pp = .data$total_spending_pp - .data$budgetary_pp,
      gce_excess_pp     = .data$general_current_expense_pp - .data$budgetary_pp,
      sent_pupil_share  = dplyr::if_else(
        is.finite(.data$enrollment_plus_sent) & .data$enrollment_plus_sent > 0,
        (.data$enrollment_plus_sent - .data$budgetary_denom) /
          .data$enrollment_plus_sent,
        NA_real_
      ),
      residual_reliable = is.finite(.data$sent_pupil_share) &
        .data$sent_pupil_share <= reliable_max_sent_share
    )

  if (!is.null(years)) {
    out <- out[out$end_year %in% years, , drop = FALSE]
  }

  out$file_name <- NULL

  lead <- intersect(
    c("county_name", "district_id", "district_name", "end_year",
      "budgetary_pp", "general_current_expense_pp", "capital_outlay_pp",
      "grants_entitlements_pp", "food_services_pp", "debt_service_local_pp",
      "debt_service_sda_pp", "total_spending_pp", "excluded_total_pp",
      "gce_excess_pp", "enrollment_plus_sent", "budgetary_denom",
      "sent_pupil_share", "residual_reliable"),
    names(out)
  )
  out %>% dplyr::select(dplyr::all_of(lead), dplyr::everything())
}
