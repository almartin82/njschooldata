#!/usr/bin/env Rscript
# =============================================================================
# build-data.R  —  NJ District Profiles data build (FETCH ONCE, SLICE MANY)
# =============================================================================
# Two stages, cleanly separated so the expensive network step runs once:
#
#   1. assemble_statewide()  — fetch every category across a year range ONCE
#      (one call returns ALL districts), write combined frames to
#      site/_bundles/_statewide/<category>.rds. Skipped if already cached.
#
#   2. build_bundle(id)      — read the statewide frames, slice to one district,
#      attach DFG + peer percentiles, write site/_bundles/<district_id>.rds.
#
# Usage:
#   Rscript site/build-data.R                 # diverse-5 proof set
#   Rscript site/build-data.R all             # all ~600 districts
#   Rscript site/build-data.R 4900 3570       # specific district_ids
#   Rscript site/build-data.R --refresh ...   # force re-fetch statewide
#
# Every number traces to a njschooldata fetcher call (CLAUDE.md: no fabrication).
# =============================================================================

suppressMessages({
  devtools::load_all(".", quiet = TRUE)
  library(dplyr)
  library(tidyr)
  library(purrr)
})
options(timeout = max(900, getOption("timeout")))
njsd_cache_enable(TRUE)

# ---- config -----------------------------------------------------------------
SITE_DIR     <- "site"
BUNDLE_DIR   <- file.path(SITE_DIR, "_bundles")
SW_DIR       <- file.path(BUNDLE_DIR, "_statewide")
dir.create(SW_DIR, recursive = TRUE, showWarnings = FALSE)

ENR_YEARS     <- 2015:2026
GRAD_YEARS    <- 2013:2025
NJGPA_YEARS   <- 2022:2025
ABSENCE_YEARS <- 2019:2024
TGES_YEARS    <- 2016:2025
STAFF_YEARS   <- c(2024, 2023)   # try latest first
AID_YEARS     <- c(2024, 2023)

# ---- small helpers ----------------------------------------------------------
log_msg <- function(...) cat(format(Sys.time(), "%H:%M:%S"), "|", ..., "\n")

# robust multi-year fetch: bind_rows over years, dropping (with a warning) any
# year that errors. NEVER swallows silently (CLAUDE.md Rule 4).
fetch_years <- function(years, fn, label) {
  out <- map(years, function(y) {
    tryCatch(fn(y), error = function(e) {
      warning(sprintf("%s %s failed: %s", label, y, conditionMessage(e)))
      NULL
    })
  })
  ok <- !map_lgl(out, is.null)
  log_msg(sprintf("  %s: %d/%d years ok (%s)", label, sum(ok), length(years),
                  paste(years[ok], collapse = ",")))
  bind_rows(out[ok])
}

sw_path <- function(name) file.path(SW_DIR, paste0(name, ".rds"))

cache_or_build <- function(name, builder, refresh = FALSE) {
  p <- sw_path(name)
  if (!refresh && file.exists(p)) {
    log_msg(sprintf("  [cached] %s", name)); return(readRDS(p))
  }
  log_msg(sprintf("  [build ] %s ...", name))
  obj <- builder()
  saveRDS(obj, p)
  obj
}

# percentile of a district's value within a peer vector (higher value -> higher
# percentile). Returns 0-100 or NA. Transparent; replaces guesswork on helper args.
pctile_within <- function(value, peer_values) {
  peer_values <- peer_values[is.finite(peer_values)]
  if (is.na(value) || length(peer_values) < 5) return(NA_real_)
  round(100 * mean(peer_values <= value, na.rm = TRUE), 0)
}

# =============================================================================
# STAGE 1: assemble statewide frames
# =============================================================================
assemble_statewide <- function(refresh = FALSE) {
  log_msg("STAGE 1: assembling statewide frames")

  dir_all <- cache_or_build("directory", function() fetch_directory("district"), refresh)
  dfg     <- cache_or_build("dfg", function() {
    fetch_dfg() %>% group_by(district_id) %>% summarise(dfg = first(dfg), .groups = "drop")
  }, refresh)

  enr <- cache_or_build("enrollment", function() {
    fetch_years(ENR_YEARS, function(y) fetch_enr(y, tidy = TRUE, use_cache = TRUE), "enr") %>%
      filter(is_district)
  }, refresh)

  grad <- cache_or_build("grad", function() {
    fetch_years(GRAD_YEARS, function(y) fetch_grad_rate(y), "grad") %>%
      filter(is_district)
  }, refresh)

  njgpa <- cache_or_build("njgpa", function() {
    fetch_years(NJGPA_YEARS, function(y) {
      bind_rows(
        tryCatch(fetch_njgpa(y, "ela",  tidy = TRUE), error = function(e) NULL),
        tryCatch(fetch_njgpa(y, "math", tidy = TRUE), error = function(e) NULL)
      )
    }, "njgpa") %>% filter(is_district)
  }, refresh)

  absence <- cache_or_build("absence", function() {
    fetch_years(ABSENCE_YEARS, function(y) fetch_absence(y, level = "district"), "absence") %>%
      filter(is_district)
  }, refresh)

  # TGES: per-pupil trend from CSG1 (drop group-average rows: district_id "00NA");
  # composition for the latest year via the package helper.
  tges <- cache_or_build("tges", function() {
    pp <- fetch_years(TGES_YEARS, function(y) {
      t <- fetch_tges(y)
      csg1 <- t[["CSG1"]]
      if (is.null(csg1)) return(NULL)
      csg1
    }, "tges_csg1")
    comp_latest <- NULL
    for (y in rev(TGES_YEARS)) {
      comp_latest <- tryCatch(tges_composition(fetch_tges(y)), error = function(e) NULL)
      if (!is.null(comp_latest)) { attr(comp_latest, "year") <- y; break }
    }
    list(pp = pp, comp_latest = comp_latest)
  }, refresh)

  staff <- cache_or_build("staff", function() {
    for (y in STAFF_YEARS) {
      d <- tryCatch(fetch_staff_ratios(y, level = "district"), error = function(e) NULL)
      if (!is.null(d) && nrow(d) > 0) { d$end_year <- y; return(d) }
    }
    NULL
  }, refresh)

  aid <- cache_or_build("aid", function() {
    for (y in AID_YEARS) {
      d <- tryCatch(fetch_state_aid(y), error = function(e) NULL)
      if (!is.null(d) && nrow(d) > 0) return(d %>% filter(is_district))
    }
    NULL
  }, refresh)

  log_msg("STAGE 1 complete")
  list(dir = dir_all, dfg = dfg, enr = enr, grad = grad, njgpa = njgpa,
       absence = absence, tges = tges, staff = staff, aid = aid)
}

# =============================================================================
# STAGE 2: slice one district into a bundle
# =============================================================================
build_bundle <- function(id, sw) {
  meta_row <- sw$dir %>% filter(district_id == id) %>% slice(1)
  if (nrow(meta_row) == 0) { warning("no directory row for ", id); return(invisible(NULL)) }
  dfg_code <- sw$dfg$dfg[match(id, sw$dfg$district_id)]
  is_charter <- isTRUE(meta_row$is_charter) || meta_row$county_id == "80"

  # peer set = same DFG (fall back to all districts if no DFG, e.g. charters/voc)
  peers <- if (!is.na(dfg_code)) sw$dfg$district_id[sw$dfg$dfg %in% dfg_code] else sw$dfg$district_id

  b <- list(
    id = id,
    meta = list(
      district_id   = id,
      district_name = meta_row$district_name,
      county_id     = meta_row$county_id,
      county_name   = meta_row$county_name,
      dfg           = dfg_code,
      is_charter    = is_charter,
      city          = meta_row$city,
      website       = meta_row$website,
      superintendent= meta_row$superintendent_name,
      n_peers       = length(unique(peers))
    )
  )

  # ---- enrollment ----
  e <- sw$enr %>% filter(district_id == id)
  b$enr_total <- e %>% filter(subgroup == "total_enrollment", grade_level == "TOTAL") %>%
    arrange(end_year) %>% select(end_year, n_students)
  latest_yr <- suppressWarnings(max(b$enr_total$end_year))
  b$enr_latest_year <- if (is.finite(latest_yr)) latest_yr else NA
  race_sg <- c("white","black","hispanic","asian","multiracial","native_american","pacific_islander")
  b$enr_race <- e %>% filter(subgroup %in% race_sg, grade_level == "TOTAL") %>%
    arrange(end_year) %>% select(end_year, subgroup, n_students, pct)
  b$enr_grades <- e %>% filter(subgroup == "total_enrollment", end_year == b$enr_latest_year,
                               !grade_level %in% c("TOTAL")) %>%
    select(grade_level, n_students)
  b$enr_special <- e %>% filter(subgroup %in% c("econ_disadv","free_reduced_lunch","lep","special_ed"),
                                grade_level == "TOTAL") %>%
    arrange(end_year) %>% select(end_year, subgroup, n_students, pct)

  # ---- graduation (district total) ----
  g_all <- sw$grad %>% filter(district_id == id)
  total_lab <- intersect(c("total","total_population","districtwide","schoolwide"),
                         unique(tolower(g_all$subgroup)))[1]
  b$grad_subgroup_label <- total_lab
  b$grad_trend <- g_all %>% filter(tolower(subgroup) == total_lab, methodology == "4 year") %>%
    arrange(end_year) %>% select(end_year, grad_rate, cohort_count)
  b$grad_subgroups_latest <- {
    ly <- suppressWarnings(max(g_all$end_year[g_all$methodology == "4 year"]))
    g_all %>% filter(methodology == "4 year", end_year == ly) %>%
      select(subgroup, grad_rate, cohort_count)
  }
  # peer percentile on latest 4yr total grad rate
  b$grad_peer <- local({
    ly <- suppressWarnings(max(sw$grad$end_year[sw$grad$methodology == "4 year"]))
    peer_df <- sw$grad %>% filter(methodology == "4 year", end_year == ly,
                                  tolower(subgroup) == total_lab, district_id %in% peers)
    val <- peer_df$grad_rate[peer_df$district_id == id]
    list(year = ly, value = if (length(val)) val[1] else NA_real_,
         pctile = pctile_within(if (length(val)) val[1] else NA_real_, peer_df$grad_rate),
         peer_median = median(peer_df$grad_rate, na.rm = TRUE))
  })

  # ---- assessment: NJGPA (HS) proficient_above, total subgroup ----
  np <- sw$njgpa %>% filter(district_id == id)
  np_total_lab <- intersect(c("total students","total","all students"),
                            unique(tolower(np$subgroup)))[1]
  b$njgpa_total_label <- np_total_lab
  b$njgpa_trend <- np %>% filter(tolower(subgroup) == np_total_lab) %>%
    arrange(testing_year, test_name) %>%
    select(testing_year, test_name, proficient_above, number_of_valid_scale_scores)

  # ---- chronic absenteeism (district, total) ----
  ab <- sw$absence %>% filter(district_id == id)
  ab_total_lab <- intersect(c("total students","total","all students","districtwide"),
                            unique(tolower(ab$subgroup)))[1]
  b$absence_total_label <- ab_total_lab
  b$absence_trend <- ab %>% filter(tolower(subgroup) == ab_total_lab) %>%
    arrange(end_year) %>% select(end_year, chronically_absent_rate)
  b$absence_peer <- local({
    ly <- suppressWarnings(max(sw$absence$end_year))
    peer_df <- sw$absence %>% filter(end_year == ly, tolower(subgroup) == ab_total_lab,
                                     district_id %in% peers)
    val <- peer_df$chronically_absent_rate[peer_df$district_id == id]
    list(year = ly, value = if (length(val)) val[1] else NA_real_,
         peer_median = median(peer_df$chronically_absent_rate, na.rm = TRUE))
  })

  # ---- spending (TGES) — skip fiscal for charters (no district fiscal data) ----
  if (!is_charter && !is.null(sw$tges$pp)) {
    pp <- sw$tges$pp %>% filter(district_id == id)
    # Actuals per-pupil trend, dedupe by end_year keep latest report_year
    b$tges_pp <- pp %>%
      filter(grepl("actual", tolower(calc_type))) %>%
      group_by(end_year) %>% slice_max(report_year, n = 1, with_ties = FALSE) %>%
      ungroup() %>% arrange(end_year) %>%
      transmute(end_year, per_pupil = `Per Pupil costs`, rank = `District rank`,
                enrollment_ade = `Enrollment (ADE)`)
    b$tges_pp_peer <- local({
      ly <- suppressWarnings(max(b$tges_pp$end_year))
      peer_pp <- sw$tges$pp %>% filter(grepl("actual", tolower(calc_type)),
                                       end_year == ly, district_id %in% peers,
                                       district_id != "00NA")
      val <- b$tges_pp$per_pupil[b$tges_pp$end_year == ly]
      list(year = ly, value = if (length(val)) val[1] else NA_real_,
           pctile = pctile_within(if (length(val)) val[1] else NA_real_, peer_pp$`Per Pupil costs`),
           peer_median = median(peer_pp$`Per Pupil costs`, na.rm = TRUE))
    })
    if (!is.null(sw$tges$comp_latest)) {
      b$tges_comp <- sw$tges$comp_latest %>% filter(district_id == id)
      b$tges_comp_year <- attr(sw$tges$comp_latest, "year")
    }
  }

  # ---- staff ratios (latest) ----
  if (!is.null(sw$staff)) {
    b$staff <- sw$staff %>% filter(district_id == id) %>% slice(1)
  }

  # ---- state aid (latest, by category) ----
  if (!is.null(sw$aid)) {
    b$aid <- sw$aid %>% filter(district_id == id) %>%
      select(any_of(c("aid_category","amount","end_year")))
  }

  out <- file.path(BUNDLE_DIR, paste0(id, ".rds"))
  saveRDS(b, out)
  invisible(b)
}

# =============================================================================
# MAIN
# =============================================================================
args <- commandArgs(trailingOnly = TRUE)
refresh <- "--refresh" %in% args
args <- setdiff(args, "--refresh")

sw <- assemble_statewide(refresh = refresh)

# pick targets
if (length(args) == 0) {
  # diverse-5 proof set, selected programmatically from real data
  somsd <- "4900"; newark <- "3570"
  millburn <- sw$dir %>% filter(grepl("MILLBURN", toupper(district_name), useBytes = TRUE)) %>%
    slice(1) %>% pull(district_id)
  charter <- sw$dir %>% filter(county_id == "80") %>% slice(1) %>% pull(district_id)
  tiny <- sw$enr %>% filter(subgroup == "total_enrollment", grade_level == "TOTAL",
                            end_year == max(end_year), n_students > 50,
                            county_id != "80", county_id != "21", !is_charter) %>%
    slice_min(n_students, n = 1, with_ties = FALSE) %>% pull(district_id)
  targets <- unique(c(somsd, newark, millburn, charter, tiny))
  log_msg("diverse-5 targets:", paste(targets, collapse = ", "))
} else if (identical(args, "all")) {
  targets <- sw$dir %>% pull(district_id) %>% unique()
  log_msg("ALL targets:", length(targets), "districts")
} else {
  targets <- args
}

log_msg("STAGE 2: building", length(targets), "bundles")
ok <- 0
for (id in targets) {
  tryCatch({ build_bundle(id, sw); ok <- ok + 1 },
           error = function(e) warning(sprintf("bundle %s failed: %s", id, conditionMessage(e))))
}
log_msg(sprintf("DONE: %d/%d bundles written to %s", ok, length(targets), BUNDLE_DIR))
