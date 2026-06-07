#!/usr/bin/env Rscript
# =============================================================================
# discovery-build.R — EXTEND the statewide cache with richer categories so the
# per-district discovery doc can mine the full data surface. Idempotent: skips
# categories already cached in site/_bundles/_statewide/. Run after build-data.R.
#   Rscript site/discovery-build.R            # build missing
#   Rscript site/discovery-build.R --refresh  # refetch all extras
# =============================================================================
suppressMessages({
  devtools::load_all(".", quiet = TRUE)
  library(dplyr); library(purrr)
})
options(timeout = max(1200, getOption("timeout")))
njsd_cache_enable(TRUE)

SW_DIR <- file.path("site", "_bundles", "_statewide")
dir.create(SW_DIR, recursive = TRUE, showWarnings = FALSE)
log_msg <- function(...) cat(format(Sys.time(), "%H:%M:%S"), "|", ..., "\n")
sw_path <- function(n) file.path(SW_DIR, paste0(n, ".rds"))
cache_or_build <- function(name, builder, refresh = FALSE) {
  p <- sw_path(name)
  if (!refresh && file.exists(p)) { log_msg("[cached]", name); return(invisible(readRDS(p))) }
  log_msg("[build ]", name, "...")
  obj <- tryCatch(builder(), error = function(e) { warning(name, " failed: ", conditionMessage(e)); NULL })
  saveRDS(obj, p); invisible(obj)
}
years_bind <- function(years, fn, label) {
  out <- map(years, function(y) tryCatch(fn(y), error = function(e) {
    warning(sprintf("%s %s: %s", label, y, conditionMessage(e))); NULL }))
  ok <- !map_lgl(out, is.null)
  log_msg(sprintf("  %s: %d/%d yrs (%s)", label, sum(ok), length(years), paste(years[ok], collapse=",")))
  bind_rows(out[ok])
}

args <- commandArgs(trailingOnly = TRUE); refresh <- "--refresh" %in% args

# --- College readiness: SAT participation+performance, AP/IB ---
cache_or_build("sat_part", function()
  years_bind(2018:2024, function(y) fetch_sat_participation(y), "sat_part"), refresh)
cache_or_build("sat_perf", function()
  years_bind(2018:2024, function(y) fetch_sat_performance(y), "sat_perf"), refresh)
cache_or_build("apib", function()
  years_bind(2018:2024, function(y) fetch_ap_participation(y), "apib"), refresh)

# --- Climate / discipline (district-level; reads cached SPR workbooks) ---
cache_or_build("removals", function()
  years_bind(2019:2024, function(y) fetch_disciplinary_removals(y, level = "district"), "removals") %>%
    filter(is_district), refresh)
cache_or_build("police", function()
  years_bind(2019:2024, function(y) fetch_police_notifications(y, level = "district"), "police") %>%
    filter(is_district), refresh)
cache_or_build("hib", function()
  years_bind(2019:2024, function(y) fetch_hib_investigations(y, level = "district"), "hib") %>%
    filter(is_district), refresh)

# --- Special education ---
cache_or_build("sped", function()
  years_bind(2017:2024, function(y) fetch_sped(y), "sped"), refresh)

# --- Assessment: NJSLA grades 3-8 ELA+Math (pre-COVID 2017-19 + recovery 2022-24) ---
# NOTE: fetch_parcc(end_year, grade, subj) — grade is a 2-digit string, NOT "ELA03".
cache_or_build("njsla", function() {
  grid <- expand.grid(year = c(2017,2018,2019,2022,2023,2024),
                      grade = sprintf("%02d", 3:8),
                      subj = c("ela","math"), stringsAsFactors = FALSE)
  out <- pmap(grid, function(year, grade, subj)
    tryCatch(fetch_parcc(year, grade, subj, tidy = TRUE), error = function(e) NULL))
  ok <- !map_lgl(out, is.null)
  log_msg(sprintf("  njsla: %d/%d grade-year-subj ok", sum(ok), nrow(grid)))
  res <- bind_rows(out[ok])
  if (nrow(res) && "is_district" %in% names(res)) res <- filter(res, is_district)
  res
}, refresh)

log_msg("discovery-build complete")
