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
#   Rscript site/build-data.R --allow-partial # explicitly permit missing inputs
#
# Every number traces to a njschooldata fetcher call (CLAUDE.md: no fabrication).
# =============================================================================

suppressMessages({
  description <- file.path(getwd(), "DESCRIPTION")
  if (file.exists(description) &&
      any(grepl("^Package: njschooldata$", readLines(description)))) {
    devtools::load_all(".", quiet = TRUE)
  } else {
    library(njschooldata)
  }
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
MANIFEST_PATH <- file.path(BUNDLE_DIR, "build-manifest.json")
SITE_MANIFEST_ATTR <- "njsd_site_manifest_records"

.build_manifest <- new.env(parent = emptyenv())
.build_manifest$rows <- data.frame(
  domain = character(), end_year = integer(), component = character(),
  required = logical(), requested = logical(), completed = logical(),
  source_status = character(), source_url = character(),
  retrieved_at = character(), digest = character(), warning = character(),
  error = character(), artifact = character(), stringsAsFactors = FALSE
)

# ---- small helpers ----------------------------------------------------------
log_msg <- function(...) cat(format(Sys.time(), "%H:%M:%S"), "|", ..., "\n")
`%||%` <- function(x, y) if (is.null(x)) y else x

site_source_failure <- function(status, error) {
  njschooldata:::new_source_result(
    source_status = status, error = as.character(error)
  )
}

is_site_source_failure <- function(x) {
  inherits(x, "njsd_source_result") &&
    !identical(x$source_status, "actual")
}

safe_bundle_id <- function(x) {
  x <- as.character(x)
  if (length(x) != 1L || is.na(x) || !grepl("^[0-9]{4}$", x)) {
    stop(
      "Unsafe district identifier cannot be used as a bundle filename: ", x,
      call. = FALSE
    )
  }
  x
}

manifest_request <- function(domain, years = NA_integer_, components = NA_character_,
                             required = TRUE) {
  rows <- expand.grid(
    end_year = as.integer(years), component = as.character(components),
    stringsAsFactors = FALSE
  )
  rows$domain <- domain
  rows$required <- required
  rows$requested <- TRUE
  rows$completed <- FALSE
  rows$source_status <- NA_character_
  rows$source_url <- NA_character_
  rows$retrieved_at <- NA_character_
  rows$digest <- NA_character_
  rows$warning <- NA_character_
  rows$error <- NA_character_
  rows$artifact <- NA_character_
  rows <- rows[, names(.build_manifest$rows)]
  .build_manifest$rows <- rbind(.build_manifest$rows, rows)
}

manifest_match <- function(domain, end_year = NULL, component = NULL) {
  rows <- .build_manifest$rows
  keep <- rows$domain == domain
  if (!is.null(end_year)) {
    keep <- keep & ((is.na(rows$end_year) & is.na(end_year)) |
                      rows$end_year == as.integer(end_year))
  }
  if (!is.null(component)) {
    keep <- keep & ((is.na(rows$component) & is.na(component)) |
                      rows$component == as.character(component))
  }
  which(keep)
}

manifest_record <- function(domain, end_year = NULL, component = NULL,
                            status, result = NULL, error = NULL,
                            artifact = NULL, completed = identical(status, "actual")) {
  index <- manifest_match(domain, end_year, component)
  if (!length(index)) {
    manifest_request(domain, end_year %||% NA_integer_, component %||% NA_character_)
    index <- manifest_match(domain, end_year, component)
  }
  .build_manifest$rows$completed[index] <- completed
  .build_manifest$rows$source_status[index] <- status
  if (!is.null(result)) {
    .build_manifest$rows$source_url[index] <- result$source_url
    .build_manifest$rows$retrieved_at[index] <- if (is.null(result$retrieved_at)) {
      NA_character_
    } else format(result$retrieved_at, tz = "UTC", usetz = TRUE)
    .build_manifest$rows$digest[index] <- result$digest
    .build_manifest$rows$warning[index] <- result$warning
    .build_manifest$rows$error[index] <- result$error
  }
  if (!is.null(error)) .build_manifest$rows$error[index] <- error
  if (!is.null(artifact)) .build_manifest$rows$artifact[index] <- artifact
  invisible(index)
}

write_build_manifest <- function() {
  dir.create(dirname(MANIFEST_PATH), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(
    list(
      generated_at = format(Sys.time(), tz = "UTC", usetz = TRUE),
      allow_partial = isTRUE(getOption("njschooldata.site_allow_partial")),
      requests = .build_manifest$rows
    ),
    MANIFEST_PATH,
    pretty = TRUE,
    dataframe = "rows",
    na = "null",
    auto_unbox = TRUE
  )
}

assert_required_coverage <- function(allow_partial = FALSE) {
  write_build_manifest()
  incomplete <- .build_manifest$rows$required & !.build_manifest$rows$completed
  if (any(incomplete) && !isTRUE(allow_partial)) {
    missing <- .build_manifest$rows[incomplete, ]
    stop(
      "Strict statewide build is incomplete for: ",
      paste(
        paste0(
          missing$domain, "/",
          ifelse(is.na(missing$end_year), "current", missing$end_year),
          ifelse(is.na(missing$component), "", paste0("/", missing$component)),
          " [", missing$source_status, "]"
        ),
        collapse = ", "
      ),
      ". See ", MANIFEST_PATH, ".",
      call. = FALSE
    )
  }
  invisible(!any(incomplete))
}

record_fetch_outcome <- function(value, domain, year, component = NULL) {
  row <- njschooldata:::select_source_result_record(value)
  if (nrow(row)) {
    result <- list(
      source_status = row$source_status,
      source_url = row$source_url,
      retrieved_at = row$retrieved_at,
      digest = row$digest,
      warning = row$warning,
      error = row$error
    )
    manifest_record(
      domain, year, component, result$source_status, result = result,
      completed = identical(result$source_status, "actual")
    )
  } else if (is.data.frame(value) && nrow(value) == 0) {
    manifest_record(
      domain, year, component, "parse_error",
      error = "Fetcher returned no rows for a requested source."
    )
  } else {
    manifest_record(domain, year, component, "actual")
  }
}

register_build_requests <- function() {
  absence_supported <- intersect(
    ABSENCE_YEARS,
    njschooldata:::get_source_years("absence")
  )
  absence_gaps <- setdiff(ABSENCE_YEARS, absence_supported)

  manifest_request("directory")
  manifest_request("dfg")
  manifest_request("enrollment", ENR_YEARS)
  manifest_request("graduation", GRAD_YEARS)
  manifest_request("njgpa", NJGPA_YEARS, c("ela", "math"))
  manifest_request("absence", absence_supported)
  if (length(absence_gaps)) {
    manifest_request("absence", absence_gaps, required = FALSE)
  }
  manifest_request("tges", TGES_YEARS)
  manifest_request("tges_composition", max(TGES_YEARS), required = FALSE)
  manifest_request("staff", NA_integer_, "latest")
  manifest_request("staff_candidate", STAFF_YEARS, required = FALSE)
  manifest_request("state_aid", NA_integer_, "latest")
  manifest_request("state_aid_candidate", AID_YEARS, required = FALSE)
}

# Robust multi-year fetch. Failed requests become explicit sentinels and
# manifest rows; they are never represented by ambiguous NULL values.
fetch_years <- function(years, fn, label) {
  out <- map(years, function(y) {
    tryCatch({
      value <- fn(y)
      record_fetch_outcome(value, label, y)
      value
    }, error = function(e) {
      manifest_record(
        label, y, status = njschooldata:::source_status_from_condition(e),
        error = conditionMessage(e)
      )
      warning(sprintf("%s %s failed: %s", label, y, conditionMessage(e)))
      site_source_failure(
        njschooldata:::source_status_from_condition(e), conditionMessage(e)
      )
    })
  })
  ok <- !map_lgl(out, is_site_source_failure)
  log_msg(sprintf("  %s: %d/%d years ok (%s)", label, sum(ok), length(years),
                  paste(years[ok], collapse = ",")))
  bind_rows(out[ok])
}

fetch_year_components <- function(years, components, fn, label) {
  values <- list()
  for (year in years) {
    for (component in components) {
      value <- tryCatch({
        out <- fn(year, component)
        record_fetch_outcome(out, label, year, component)
        out
      }, error = function(e) {
        manifest_record(
          label, year, component,
          njschooldata:::source_status_from_condition(e),
          error = conditionMessage(e)
        )
        warning(sprintf(
          "%s %s/%s failed: %s", label, year, component, conditionMessage(e)
        ))
        site_source_failure(
          njschooldata:::source_status_from_condition(e), conditionMessage(e)
        )
      })
      values[[paste(year, component, sep = "-")]] <- value
    }
  }
  bind_rows(values[!map_lgl(values, is_site_source_failure)])
}

sw_path <- function(name) file.path(SW_DIR, paste0(name, ".rds"))

manifest_domain_index <- function(domains) {
  which(.build_manifest$rows$domain %in% domains)
}

manifest_row_match <- function(records, row) {
  same_year <- (is.na(records$end_year) & is.na(row$end_year)) |
    records$end_year == row$end_year
  same_component <- (is.na(records$component) & is.na(row$component)) |
    records$component == row$component
  which(records$domain == row$domain & same_year & same_component)
}

mark_manifest_cache_failure <- function(index, path, message) {
  .build_manifest$rows$completed[index] <- FALSE
  .build_manifest$rows$source_status[index] <- "source_unavailable"
  .build_manifest$rows$error[index] <- message
  .build_manifest$rows$artifact[index] <- path
}

restore_cached_manifest <- function(cached, path, domains) {
  index <- manifest_domain_index(domains)
  if (!length(index)) return(invisible(FALSE))

  records <- attr(cached, SITE_MANIFEST_ATTR, exact = TRUE)
  required_columns <- c(
    "domain", "end_year", "component", "completed", "source_status",
    "source_url", "retrieved_at", "digest", "warning", "error"
  )
  if (!is.data.frame(records) || !all(required_columns %in% names(records))) {
    mark_manifest_cache_failure(
      index,
      path,
      "Cached artifact lacks source-manifest provenance; rebuild with --refresh."
    )
    return(invisible(FALSE))
  }

  restored_columns <- setdiff(required_columns, c("domain", "end_year", "component"))
  complete <- TRUE
  for (i in index) {
    matched <- manifest_row_match(records, .build_manifest$rows[i, , drop = FALSE])
    if (!length(matched)) {
      complete <- FALSE
      mark_manifest_cache_failure(
        i,
        path,
        "Cached artifact does not cover this source request; rebuild with --refresh."
      )
      next
    }
    for (column in restored_columns) {
      .build_manifest$rows[i, column] <- records[matched[1], column]
    }
    .build_manifest$rows$artifact[i] <- path
  }
  invisible(complete)
}

attach_cached_manifest <- function(value, path, domains) {
  index <- manifest_domain_index(domains)
  if (length(index)) {
    .build_manifest$rows$artifact[index] <- path
    attr(value, SITE_MANIFEST_ATTR) <- .build_manifest$rows[index, , drop = FALSE]
  }
  value
}

cache_or_build <- function(name, builder, refresh = FALSE,
                           records_inside = FALSE,
                           domain = name, manifest_domains = domain) {
  p <- sw_path(name)
  if (!refresh && file.exists(p)) {
    log_msg(sprintf("  [cached] %s", name))
    cached <- readRDS(p)
    restored <- restore_cached_manifest(cached, p, manifest_domains)
    if (!isTRUE(restored)) {
      return(site_source_failure(
        "source_unavailable",
        "Cached artifact lacks valid source-manifest provenance."
      ))
    }
    return(cached)
  }
  log_msg(sprintf("  [build ] %s ...", name))
  obj <- tryCatch(builder(), error = identity)
  if (inherits(obj, "error")) {
    index <- manifest_domain_index(manifest_domains)
    actual <- index[which(.build_manifest$rows$source_status[index] == "actual")]
    pending <- index[is.na(.build_manifest$rows$source_status[index])]
    failed <- setdiff(index, c(actual, pending))
    .build_manifest$rows$completed[index] <- FALSE
    if (length(actual)) {
      .build_manifest$rows$source_status[actual] <- "parse_error"
      .build_manifest$rows$error[actual] <- paste0(
        "Statewide artifact build failed after source retrieval: ",
        conditionMessage(obj)
      )
    }
    if (length(pending)) {
      .build_manifest$rows$source_status[pending] <-
        njschooldata:::source_status_from_condition(obj)
      .build_manifest$rows$error[pending] <- conditionMessage(obj)
    }
    if (length(failed)) {
      missing_error <- is.na(.build_manifest$rows$error[failed]) |
        !nzchar(.build_manifest$rows$error[failed])
      .build_manifest$rows$error[failed[missing_error]] <- paste0(
        "Statewide artifact was not written: ", conditionMessage(obj)
      )
    }
    warning(sprintf("%s build failed: %s", name, conditionMessage(obj)))
    return(site_source_failure(
      njschooldata:::source_status_from_condition(obj), conditionMessage(obj)
    ))
  }
  if (is_site_source_failure(obj)) return(obj)
  if (is.data.frame(obj) && !nrow(obj)) {
    message <- "Statewide builder returned no rows after composition."
    if (isTRUE(records_inside)) {
      manifest_record(
        domain, NA_integer_, status = "parse_error", error = message
      )
    } else {
      record_fetch_outcome(obj, domain, NA_integer_)
    }
    warning(sprintf("%s build failed: %s", name, message))
    return(site_source_failure("parse_error", message))
  }
  if (!records_inside) {
    record_fetch_outcome(obj, domain, NA_integer_)
  }
  obj <- attach_cached_manifest(obj, p, manifest_domains)
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

  dir_all <- cache_or_build(
    "directory", get_district_directory, refresh
  )
  dfg     <- cache_or_build("dfg", function() {
    fetch_dfg() %>% group_by(district_id) %>% summarise(dfg = first(dfg), .groups = "drop")
  }, refresh)

  enr <- cache_or_build("enrollment", function() {
    fetch_years(
      ENR_YEARS,
      function(y) fetch_enr(y, tidy = TRUE, use_cache = TRUE),
      "enrollment"
    ) %>%
      filter(is_district)
  }, refresh, records_inside = TRUE)

  grad <- cache_or_build("grad", function() {
    fetch_years(GRAD_YEARS, function(y) fetch_grad_rate(y), "graduation") %>%
      filter(is_district)
  }, refresh, records_inside = TRUE, domain = "graduation")

  njgpa <- cache_or_build("njgpa", function() {
    fetch_year_components(
      NJGPA_YEARS, c("ela", "math"),
      function(y, subject) fetch_njgpa(y, subject, tidy = TRUE),
      "njgpa"
    ) %>% filter(is_district)
  }, refresh, records_inside = TRUE)

  absence <- cache_or_build("absence", function() {
    supported <- intersect(
      ABSENCE_YEARS,
      njschooldata:::get_source_years("absence")
    )
    gaps <- setdiff(ABSENCE_YEARS, supported)
    for (year in gaps) {
      manifest_record(
        "absence", year,
        status = njschooldata:::source_gap_status("absence", year),
        error = "The source registry marks this school year as not published."
      )
    }
    fetch_years(supported, function(y) fetch_absence(y, level = "district"), "absence") %>%
      filter(is_district)
  }, refresh, records_inside = TRUE)

  # TGES: per-pupil trend from CSG1 (drop group-average rows: district_id "00NA");
  # composition for the latest year via the package helper.
  tges <- cache_or_build("tges", function() {
    pp <- fetch_years(TGES_YEARS, function(y) {
      t <- fetch_tges(y)
      csg1 <- t[["CSG1"]]
      if (is.null(csg1)) {
        stop("TGES response has no CSG1 table.", call. = FALSE)
      }
      csg1
    }, "tges")
    y <- max(TGES_YEARS)
    comp_latest <- tryCatch({
      value <- tges_composition(fetch_tges(y))
      if (is.null(value) || !nrow(value)) {
        stop("TGES composition returned no rows.", call. = FALSE)
      }
      manifest_record("tges_composition", y, status = "actual")
      attr(value, "year") <- y
      value
    }, error = function(e) {
      manifest_record(
        "tges_composition", y,
        status = njschooldata:::source_status_from_condition(e),
        error = conditionMessage(e)
      )
      warning("optional TGES composition failed: ", conditionMessage(e))
      site_source_failure(
        njschooldata:::source_status_from_condition(e), conditionMessage(e)
      )
    })
    list(pp = pp, comp_latest = comp_latest)
  }, refresh, records_inside = TRUE,
  manifest_domains = c("tges", "tges_composition"))

  staff <- cache_or_build("staff", function() {
    failures <- character()
    for (y in STAFF_YEARS) {
      d <- tryCatch(fetch_staff_ratios(y, level = "district"), error = identity)
      if (inherits(d, "error")) {
        failures <- c(failures, conditionMessage(d))
        manifest_record(
          "staff_candidate", y,
          status = njschooldata:::source_status_from_condition(d),
          error = conditionMessage(d)
        )
      } else if (nrow(d) > 0) {
        manifest_record("staff_candidate", y, status = "actual")
        manifest_record("staff", NA_integer_, "latest", status = "actual")
        d$end_year <- y
        return(d)
      } else {
        manifest_record(
          "staff_candidate", y, status = "parse_error",
          error = "Staff fetcher returned no rows."
        )
      }
    }
    manifest_record(
      "staff", NA_integer_, "latest", status = "source_unavailable",
      error = paste(failures, collapse = "; ")
    )
    site_source_failure("source_unavailable", paste(failures, collapse = "; "))
  }, refresh, records_inside = TRUE,
  manifest_domains = c("staff", "staff_candidate"))

  aid <- cache_or_build("aid", function() {
    failures <- character()
    for (y in AID_YEARS) {
      d <- tryCatch(fetch_state_aid(y), error = identity)
      if (inherits(d, "error")) {
        failures <- c(failures, conditionMessage(d))
        manifest_record(
          "state_aid_candidate", y,
          status = njschooldata:::source_status_from_condition(d),
          error = conditionMessage(d)
        )
      } else if (nrow(d) > 0) {
        manifest_record("state_aid_candidate", y, status = "actual")
        manifest_record("state_aid", NA_integer_, "latest", status = "actual")
        return(d %>% filter(is_district))
      } else {
        manifest_record(
          "state_aid_candidate", y, status = "parse_error",
          error = "State-aid fetcher returned no rows."
        )
      }
    }
    manifest_record(
      "state_aid", NA_integer_, "latest", status = "source_unavailable",
      error = paste(failures, collapse = "; ")
    )
    site_source_failure("source_unavailable", paste(failures, collapse = "; "))
  }, refresh, records_inside = TRUE, domain = "state_aid",
  manifest_domains = c("state_aid", "state_aid_candidate"))

  log_msg("STAGE 1 complete")
  list(dir = dir_all, dfg = dfg, enr = enr, grad = grad, njgpa = njgpa,
       absence = absence, tges = tges, staff = staff, aid = aid)
}

# =============================================================================
# STAGE 2: slice one district into a bundle
# =============================================================================
build_bundle <- function(id, sw) {
  id <- safe_bundle_id(id)
  meta_row <- sw$dir %>% filter(district_id == id) %>% slice(1)
  if (nrow(meta_row) == 0) {
    stop("No directory row exists for requested district ", id, ".", call. = FALSE)
  }
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
    if (!is_site_source_failure(sw$tges$comp_latest)) {
      b$tges_comp <- sw$tges$comp_latest %>% filter(district_id == id)
      b$tges_comp_year <- attr(sw$tges$comp_latest, "year")
    }
  }

  # ---- staff ratios (latest) ----
  if (!is_site_source_failure(sw$staff)) {
    b$staff <- sw$staff %>% filter(district_id == id) %>% slice(1)
  }

  # ---- state aid (latest, by category) ----
  if (!is_site_source_failure(sw$aid)) {
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
main <- function(args = commandArgs(trailingOnly = TRUE)) {
  refresh <- "--refresh" %in% args
  allow_partial <- "--allow-partial" %in% args
  args <- setdiff(args, c("--refresh", "--allow-partial"))
  options(njschooldata.site_allow_partial = allow_partial)
  register_build_requests()

sw <- tryCatch(assemble_statewide(refresh = refresh), error = identity)
if (inherits(sw, "error")) {
  pending <- is.na(.build_manifest$rows$source_status)
  .build_manifest$rows$source_status[pending] <- "source_unavailable"
  .build_manifest$rows$error[pending] <- paste0(
    "Not attempted because statewide assembly aborted: ", conditionMessage(sw)
  )
  write_build_manifest()
  stop(
    "Strict statewide build failed. See ", MANIFEST_PATH, ": ",
    conditionMessage(sw), call. = FALSE
  )
}

pending <- is.na(.build_manifest$rows$source_status)
.build_manifest$rows$source_status[pending] <- "not_published"
.build_manifest$rows$warning[pending] <-
  "Optional fallback was not attempted because an earlier candidate succeeded."
write_build_manifest()
assert_required_coverage(allow_partial)

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
targets <- vapply(targets, safe_bundle_id, character(1), USE.NAMES = FALSE)

log_msg("STAGE 2: building", length(targets), "bundles")
manifest_request("bundle", NA_integer_, targets, required = TRUE)
ok <- 0
for (id in targets) {
  built <- tryCatch(build_bundle(id, sw), error = identity)
  artifact <- file.path(BUNDLE_DIR, paste0(id, ".rds"))
  if (!inherits(built, "error") && !is.null(built) && file.exists(artifact)) {
    manifest_record(
      "bundle", NA_integer_, id, status = "actual", artifact = artifact
    )
    ok <- ok + 1
  } else {
    reason <- if (inherits(built, "error")) {
      conditionMessage(built)
    } else {
      "Bundle builder returned without writing an artifact."
    }
    manifest_record(
      "bundle", NA_integer_, id,
      status = if (inherits(built, "njsd_parse_error")) "parse_error" else "source_unavailable",
      error = reason
    )
    warning(sprintf("bundle %s failed: %s", id, reason))
  }
}
write_build_manifest()
log_msg(sprintf("DONE: %d/%d bundles written to %s", ok, length(targets), BUNDLE_DIR))
if (ok != length(targets) && !allow_partial) {
  stop(
    "Strict bundle build failed: ", length(targets) - ok,
    " requested artifact(s) were not written. See ", MANIFEST_PATH, ".",
    call. = FALSE
  )
}
}

if (sys.nframe() == 0L) {
  main()
}
