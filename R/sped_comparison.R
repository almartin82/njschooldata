# Two comparisons of special education share between a focal set of schools and
# a comparison set. Generated from contracts/sped-comparison/v1; do not hand-edit.
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
