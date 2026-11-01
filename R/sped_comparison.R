# Comparisons of special education share between a focal set of schools and a
# comparison set, and the focal set's place on a distribution of comparison rows.
# Generated from contracts/sped-comparison/v1; do not hand-edit.
# Base R only. Nothing here estimates a value: a cell with no published figure
# stays NA and says why.

SPED_BANDS <- c("elementary", "middle", "high")
SPED_GRADE_ORDER <- c("K", sprintf("%02d", 1:12))

.sped_grade_band <- function(grade) {
  index <- match(grade, SPED_GRADE_ORDER)
  ifelse(is.na(index), NA_character_,
         ifelse(index <= 6L, "elementary", ifelse(index <= 9L, "middle", "high")))
}

#' Grade band of a school's span
#'
#' A span inside one band returns that band. A span crossing bands returns
#' "mixed": its share cannot be split by band without assuming every band has
#' the same rate, so like-for-like leaves it out and reports how much it left out.
#'
#' @param grade_low,grade_high Lowest and highest grade: "K", or "01" to "12".
#'   PK reads as K. Anything else gives NA.
#' @return Character vector: elementary, middle, high, mixed or NA.
#' @export
sped_grade_band <- function(grade_low, grade_high) {
  low <- .sped_grade_band(ifelse(grade_low == "PK", "K", grade_low))
  high <- .sped_grade_band(ifelse(grade_high == "PK", "K", grade_high))
  ifelse(is.na(low) | is.na(high), NA_character_, ifelse(low == high, low, "mixed"))
}

#' Pool special education rows into one share
#'
#' Counts over enrollment where every row has a count. A rate-only row enters as
#' a range from its published bounds. A suppressed row with published bounds, such
#' as a count under 10, enters at those bounds. A row with enrollment and nothing
#' else enters the range as 0 to 100, so a suppressed school can only widen the
#' answer. A row with no enrollment cannot be weighted and is reported, not used.
#'
#' @param rows Rows of \code{fetch_sped_share()}.
#' @return One-row data frame: pct, pct_lo, pct_hi, method, n_rows, the enrollment
#'   behind the figure, the shares of it with a count, a rate, bounds only or
#'   nothing, and rows_no_enrollment. pct is NA when any row has no point value,
#'   since only the range is then known.
#' @export
sped_pool <- function(rows) {
  empty <- data.frame(pct = NA_real_, pct_lo = NA_real_, pct_hi = NA_real_,
                      method = "no_rows", n_rows = nrow(rows), n_enrolled = NA_real_,
                      share_count = NA_real_, share_rate = NA_real_, share_bounds = NA_real_,
                      share_neither = NA_real_, rows_no_enrollment = 0L, stringsAsFactors = FALSE)
  if (!nrow(rows)) return(empty)
  enrolled <- !is.na(rows$n_enrolled) & rows$n_enrolled > 0
  empty$rows_no_enrollment <- sum(!enrolled)
  rows <- rows[enrolled, , drop = FALSE]
  if (!nrow(rows)) {
    empty$method <- "no_enrollment"
    return(empty)
  }
  e <- rows$n_enrolled
  has_count <- !is.na(rows$n_sped)
  has_rate <- !has_count & !is.na(rows$pct_sped)
  has_bounds <- !has_count & !has_rate & !is.na(rows$pct_sped_lo) & !is.na(rows$pct_sped_hi)
  neither <- !has_count & !has_rate & !has_bounds
  ranged <- has_rate | has_bounds
  lo_pct <- ifelse(is.na(rows$pct_sped_lo), rows$pct_sped, rows$pct_sped_lo)
  hi_pct <- ifelse(is.na(rows$pct_sped_hi), rows$pct_sped, rows$pct_sped_hi)
  low <- ifelse(has_count, rows$n_sped, ifelse(ranged, e * lo_pct / 100, 0))
  high <- ifelse(has_count, rows$n_sped, ifelse(ranged, e * hi_pct / 100, e))
  mid <- ifelse(has_count, rows$n_sped, ifelse(has_rate, e * rows$pct_sped / 100, NA_real_))
  total <- sum(e)
  data.frame(
    pct = if (anyNA(mid)) NA_real_ else 100 * sum(mid) / total,
    pct_lo = 100 * sum(low) / total,
    pct_hi = 100 * sum(high) / total,
    method = if (all(has_count)) "counts_over_enrollment"
      else if (all(has_rate)) "published_rates_weighted"
      else if (anyNA(mid)) "bounded_range"
      else "counts_and_rates",
    n_rows = nrow(rows), n_enrolled = total,
    share_count = sum(e[has_count]) / total, share_rate = sum(e[has_rate]) / total,
    share_bounds = sum(e[has_bounds]) / total, share_neither = sum(e[neither]) / total,
    rows_no_enrollment = empty$rows_no_enrollment, stringsAsFactors = FALSE
  )
}

.sped_key <- function(x) paste(x$district_id, ifelse(is.na(x$school_id), "", x$school_id), sep = "\r")

.sped_take <- function(rows, ids) {
  if (!all(c("district_id", "school_id") %in% names(ids))) {
    stop("ids needs district_id and school_id; use NA school_id for a whole district row",
         call. = FALSE)
  }
  # An NA school_id names the district row. A school whose state id is unknown
  # also has NA here, so entity_level keeps it from reading as its district.
  key <- function(d, s) paste(d, ifelse(is.na(s), "", s), sep = "\r")
  no_id <- is.na(rows$school_id) & rows$entity_level == "school"
  rows <- rows[!no_id, , drop = FALSE]
  rows[key(rows$district_id, rows$school_id) %in% key(ids$district_id, ids$school_id), , drop = FALSE]
}

#' Specification 1: all students against all students
#'
#' @param rows Rows of \code{fetch_sped_share()} for one year.
#' @param focal,comparison Data frames with district_id and school_id naming rows.
#'   Use NA school_id for a district row.
#' @return Two rows from \code{sped_pool()}, labeled focal and comparison.
#' @export
sped_all_vs_all <- function(rows, focal, comparison) {
  rows <- rows[rows$grade_band == "all", , drop = FALSE]
  out <- rbind(sped_pool(.sped_take(rows, focal)), sped_pool(.sped_take(rows, comparison)))
  cbind(group = c("focal", "comparison"), out, stringsAsFactors = FALSE)
}

#' Specification 2: like for like by grade band
#'
#' Builds what the comparison group's share would read with the focal group's mix
#' of grades. Each band's comparison share is pooled from rows published by band
#' where the state has them, otherwise from schools whose span sits inside that
#' band. The composite weights those shares by the focal group's enrollment in
#' each band. A band the focal group enrolls with no comparison data leaves the
#' composite NA with the reason.
#'
#' @param rows Rows of \code{fetch_sped_share()} for one year.
#' @param focal,comparison As in \code{sped_all_vs_all()}.
#' @param focal_bands Data frame: grade_band, n_enrolled, the focal group's K-12
#'   enrollment by band, from \code{fetch_enr()} grade rows.
#' @return One-row data frame: pct, pct_lo, pct_hi, method, source (by_band or
#'   single_band_schools), n_bands, mixed_share (comparison enrollment left out
#'   as crossing bands), share_neither, and reason.
#' @export
sped_like_for_like <- function(rows, focal, comparison, focal_bands) {
  blank <- function(reason) {
    data.frame(pct = NA_real_, pct_lo = NA_real_, pct_hi = NA_real_, method = "none",
               source = NA_character_, n_bands = 0L, mixed_share = NA_real_,
               share_neither = NA_real_, reason = reason, stringsAsFactors = FALSE)
  }
  bands <- focal_bands[!is.na(focal_bands$n_enrolled) & focal_bands$n_enrolled > 0, , drop = FALSE]
  bad <- setdiff(bands$grade_band, SPED_BANDS)
  if (length(bad)) stop("Unknown grade band: ", paste(bad, collapse = ", "), call. = FALSE)
  if (anyDuplicated(bands$grade_band)) stop("focal_bands repeats a band", call. = FALSE)
  if (!nrow(bands)) return(blank("no focal enrollment by band"))
  group <- .sped_take(rows, comparison)
  published <- group[group$grade_band %in% SPED_BANDS, , drop = FALSE]
  schools <- group[group$grade_band == "all" & !is.na(group$school_id), , drop = FALSE]
  span <- sped_grade_band(schools$grade_low, schools$grade_high)
  by_band <- nrow(published) > 0L
  known <- sum(schools$n_enrolled[!is.na(span)], na.rm = TRUE)
  mixed_share <- if (by_band || known == 0) NA_real_
    else sum(schools$n_enrolled[span %in% "mixed"], na.rm = TRUE) / known
  w <- bands$n_enrolled / sum(bands$n_enrolled)
  pooled <- vector("list", nrow(bands))
  for (i in seq_len(nrow(bands))) {
    b <- bands$grade_band[[i]]
    these <- if (by_band) published[published$grade_band == b, , drop = FALSE]
      else schools[span %in% b, , drop = FALSE]
    pooled[[i]] <- sped_pool(these)
    if (is.na(pooled[[i]]$pct_lo)) {
      return(blank(paste0("no comparison data for band ", b)))
    }
  }
  p <- do.call(rbind, pooled)
  data.frame(pct = if (anyNA(p$pct)) NA_real_ else sum(w * p$pct),
             pct_lo = sum(w * p$pct_lo), pct_hi = sum(w * p$pct_hi),
             method = paste(unique(p$method), collapse = "+"),
             source = if (by_band) "by_band" else "single_band_schools",
             n_bands = nrow(bands), mixed_share = mixed_share,
             share_neither = sum(w * p$share_neither), reason = NA_character_,
             stringsAsFactors = FALSE)
}

.sped_quantile <- function(v, w, p) {
  o <- order(v)
  v <- v[o]
  share <- cumsum(w[o]) / sum(w)
  at <- which(share >= p - 1e-12)[1]
  if (abs(share[at] - p) < 1e-12 && at < length(v)) (v[at] + v[at + 1L]) / 2 else v[at]
}

.sped_percentile <- function(focal, v, w) {
  100 * (sum(w[v < focal]) + 0.5 * sum(w[v == focal])) / sum(w)
}

#' Place a pooled focal group on a distribution of comparison rows
#'
#' The focal group is pooled into one share with \code{sped_pool()} and placed
#' among the comparison rows, each row one point. Quantiles and the percentile
#' come back as ranges: a row known only to rounding or published bounds moves
#' them, and nothing is taken at a midpoint. A row with no count, rate or bounds
#' is excluded and reported, never counted as zero. So is a rate above 100. Focal
#' rows are removed from the comparison set.
#'
#' With \code{focal_bands}, only rows inside one grade band are used, published
#' band rows first, and each band carries the focal group's share of enrollment.
#'
#' @param rows Rows of \code{fetch_sped_share()} for one year.
#' @param focal,comparison As in \code{sped_all_vs_all()}.
#' @param weight "row" counts each row once. "enrollment" weights by enrollment.
#' @param focal_bands Optional data frame: grade_band, n_enrolled.
#' @param min_gap Points the gap must exceed, rounded half up to the nearest 0.5,
#'   to read as above or below the median.
#' @return One-row data frame: focal_pct, focal_lo, focal_hi; comparison_lo and
#'   comparison_hi, the pooled share of the rows used; p25, median and p75, each
#'   _lo and _hi; percentile_lo, percentile_hi; direction (above, below, close or
#'   unknown); inside_middle_half (NA when the ranges overlap a quartile line);
#'   n_used, n_focal_removed, n_no_enrollment, n_no_value, n_impossible, n_mixed;
#'   enrollment_used and coverage, the used share of comparison enrollment; reason.
#' @export
sped_position <- function(rows, focal, comparison, weight = c("row", "enrollment"),
                          focal_bands = NULL, min_gap = 1) {
  weight <- match.arg(weight)
  f <- sped_pool(.sped_take(rows[rows$grade_band == "all", , drop = FALSE], focal))
  out <- data.frame(focal_pct = f$pct, focal_lo = f$pct_lo, focal_hi = f$pct_hi,
                    comparison_lo = NA_real_, comparison_hi = NA_real_,
                    p25_lo = NA_real_, p25_hi = NA_real_, median_lo = NA_real_, median_hi = NA_real_,
                    p75_lo = NA_real_, p75_hi = NA_real_, percentile_lo = NA_real_, percentile_hi = NA_real_,
                    direction = "unknown", inside_middle_half = NA, n_used = 0L, n_focal_removed = 0L,
                    n_no_enrollment = 0L, n_no_value = 0L, n_impossible = 0L, n_mixed = 0L,
                    enrollment_used = NA_real_, coverage = NA_real_, reason = NA_character_,
                    stringsAsFactors = FALSE)
  group <- .sped_take(rows, comparison)
  in_focal <- .sped_key(group) %in% .sped_key(focal)
  out$n_focal_removed <- length(unique(.sped_key(group)[in_focal]))
  group <- group[!in_focal, , drop = FALSE]
  band <- rep("all", nrow(group))
  if (is.null(focal_bands)) {
    group <- group[group$grade_band == "all", , drop = FALSE]
    band <- rep("all", nrow(group))
    shares <- c(all = 1)
  } else {
    bands <- focal_bands[!is.na(focal_bands$n_enrolled) & focal_bands$n_enrolled > 0, , drop = FALSE]
    bad <- setdiff(bands$grade_band, SPED_BANDS)
    if (length(bad)) stop("Unknown grade band: ", paste(bad, collapse = ", "), call. = FALSE)
    if (anyDuplicated(bands$grade_band)) stop("focal_bands repeats a band", call. = FALSE)
    if (!nrow(bands)) {
      out$reason <- "no focal enrollment by band"
      return(out)
    }
    shares <- stats::setNames(bands$n_enrolled / sum(bands$n_enrolled), bands$grade_band)
    published <- group[group$grade_band %in% SPED_BANDS, , drop = FALSE]
    if (nrow(published)) {
      group <- published
      band <- group$grade_band
    } else {
      group <- group[group$grade_band == "all" & !is.na(group$school_id), , drop = FALSE]
      band <- sped_grade_band(group$grade_low, group$grade_high)
      out$n_mixed <- sum(band %in% "mixed")
    }
  }
  whole <- sum(group$n_enrolled, na.rm = TRUE)
  keep_band <- band %in% names(shares)
  group <- group[keep_band, , drop = FALSE]
  band <- band[keep_band]
  e <- group$n_enrolled
  enrolled <- !is.na(e) & e > 0
  out$n_no_enrollment <- sum(!enrolled)
  group <- group[enrolled, , drop = FALSE]
  band <- band[enrolled]
  e <- e[enrolled]
  has_count <- !is.na(group$n_sped)
  lo <- ifelse(has_count, 100 * group$n_sped / e, ifelse(is.na(group$pct_sped_lo), group$pct_sped, group$pct_sped_lo))
  hi <- ifelse(has_count, 100 * group$n_sped / e, ifelse(is.na(group$pct_sped_hi), group$pct_sped, group$pct_sped_hi))
  no_value <- is.na(lo) | is.na(hi)
  impossible <- !no_value & lo > 100
  out$n_no_value <- sum(no_value)
  out$n_impossible <- sum(impossible)
  use <- !no_value & !impossible
  lo <- lo[use]
  hi <- pmin(hi[use], 100)
  e <- e[use]
  band <- band[use]
  out$n_used <- length(e)
  missing_band <- setdiff(names(shares), unique(band))
  if (!length(e) || length(missing_band)) {
    out$reason <- if (!is.null(focal_bands)) paste0("no comparison rows for band ", paste(missing_band, collapse = ", "))
      else "no comparison rows with a value"
    return(out)
  }
  w <- if (weight == "row") rep(1, length(e)) else e
  w <- unname(w * shares[band] / ave(w, band, FUN = sum))
  out$comparison_lo <- 100 * sum(e * lo / 100) / sum(e)
  out$comparison_hi <- 100 * sum(e * hi / 100) / sum(e)
  for (p in c(25, 50, 75)) {
    name <- if (p == 50) "median" else paste0("p", p)
    out[[paste0(name, "_lo")]] <- .sped_quantile(lo, w, p / 100)
    out[[paste0(name, "_hi")]] <- .sped_quantile(hi, w, p / 100)
  }
  out$enrollment_used <- sum(e)
  out$coverage <- if (whole > 0) sum(e) / whole else NA_real_
  if (is.na(f$pct_lo)) {
    out$reason <- "no focal figure"
    return(out)
  }
  out$percentile_lo <- .sped_percentile(f$pct_lo, hi, w)
  out$percentile_hi <- .sped_percentile(f$pct_hi, lo, w)
  half <- function(x) floor(x / 0.5 + 0.5 + 1e-9) * 0.5
  out$direction <- if (half(f$pct_lo - out$median_hi) > min_gap) "above"
    else if (half(out$median_lo - f$pct_hi) > min_gap) "below"
    else if (half(f$pct_hi - out$median_lo) <= min_gap && half(out$median_hi - f$pct_lo) <= min_gap) "close"
    else "unknown"
  out$inside_middle_half <- if (f$pct_lo >= out$p25_hi && f$pct_hi <= out$p75_lo) TRUE
    else if (f$pct_hi < out$p25_lo || f$pct_lo > out$p75_hi) FALSE
    else NA
  out
}
