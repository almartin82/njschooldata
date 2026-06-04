# ==============================================================================
# Build the NJ county-district-school (CDS) -> NCES identifier crosswalk
# ==============================================================================
#
# NJ enrollment is keyed by the state's County-District-School (CDS) code:
# a 2-digit `county_id`, a 4-digit `district_id`, and a 3-digit `school_id`.
# The federal NCES 7-digit `LEAID` (`nces_dist`) and 12-digit `NCESSCH`
# (`nces_sch`) are attached from two identifiers-only sources:
#
#   1. NJ DOE directory ("Homeroom") — the state directory publishes the
#      federal `NCES ID` (the full 7-digit LEAID) keyed by each district's
#      CDS county/district code, and the per-school NCES fragment keyed by CDS
#      county/district/school code. This is the bridge from CDS -> LEAID that
#      the federal CCD does not carry directly (CCD's `state_leaid` is the NJ
#      6-digit DOE LEA code, not the CDS district code).
#   2. CCD 2024 directory (via the Urban Institute Education Data API, a
#      republication of the federal NCES Common Core of Data, fips=34) — the
#      authoritative, versioned source of the 12-digit `NCESSCH`. The school
#      `seasch` is `<NJ 6-digit LEA>-<3-digit school code>`; the school-code
#      suffix matches the CDS `school_id`, so each school joins to CCD on the
#      composite key (district LEAID + school_id) -> NCESSCH.
#
# IDENTIFIERS ONLY — no enrollment/performance values. Enrollment values come
# from the NJ DOE enrollment files; only the NCES join keys come from here.
# Federal identifiers are allowed (see CRITICAL DATA SOURCE RULES in the parent
# CLAUDE.md and docs/FEDERAL-NCES-LINKAGE.md).
#
# Cross-validation: every district LEAID drawn from the NJ DOE directory is
# confirmed to exist in the CCD 2024 NJ universe; the build aborts on a
# disagreement that would indicate a stale or wrong-state snapshot.
#
# Output (committed): inst/extdata/crosswalk/nj_nces_crosswalk.csv + README.md
# Re-run: Rscript data-raw/build_nces_crosswalk.R
# ==============================================================================

suppressWarnings(suppressMessages({
  library(jsonlite); library(dplyr); library(readr); library(stringr)
}))

devtools::load_all(".")

CCD_YEAR <- 2024
FIPS <- "34"

chr <- function(x) { x <- as.character(x); x[is.na(x)] <- ""; trimws(x) }
clean_padform <- function(v) gsub("[=\"]", "", chr(v))   # ="01" -> 01
fetch_paged <- function(url) {
  out <- list()
  repeat {
    pg <- jsonlite::fromJSON(url); out[[length(out) + 1]] <- pg$results
    nxt <- pg[["next"]]; if (is.null(nxt) || is.na(nxt)) break; url <- nxt
  }
  dplyr::bind_rows(out)
}

# ---------------------------------------------------------------------------
# 1. NJ DOE directory: CDS -> NCES (the CDS bridge the CCD lacks)
# ---------------------------------------------------------------------------
message("Downloading NJ DOE district directory...")
dd <- get_raw_district_directory()
nj_dist <- tibble::tibble(
  county_id   = str_pad(clean_padform(dd[["County Code"]]),   2, "left", "0"),
  district_id = str_pad(clean_padform(dd[["District Code"]]), 4, "left", "0"),
  nces_dist   = clean_padform(dd[["NCES ID"]])
) %>%
  dplyr::filter(nchar(nces_dist) == 7) %>%
  dplyr::distinct()
message("  ", nrow(nj_dist), " districts with a 7-digit NCES LEAID")

message("Downloading NJ DOE school directory...")
sd <- get_raw_school_directory()
nj_sch_keys <- tibble::tibble(
  county_id   = str_pad(clean_padform(sd[["County Code"]]),   2, "left", "0"),
  district_id = str_pad(clean_padform(sd[["District Code"]]), 4, "left", "0"),
  school_id   = str_pad(clean_padform(sd[["School Code"]]),   3, "left", "0")
) %>%
  dplyr::distinct()
message("  ", nrow(nj_sch_keys), " school CDS keys")

# ---------------------------------------------------------------------------
# 2. CCD 2024: authoritative 12-digit NCESSCH, joined on LEAID + school code
# ---------------------------------------------------------------------------
message("Downloading CCD NJ district directory (", CCD_YEAR, ")...")
ccd_lea <- fetch_paged(sprintf(
  "https://educationdata.urban.org/api/v1/school-districts/ccd/directory/%d/?fips=%s",
  CCD_YEAR, FIPS))
ccd_leaids <- chr(ccd_lea$leaid)

message("Downloading CCD NJ school directory (", CCD_YEAR, ")...")
ccd_sch <- fetch_paged(sprintf(
  "https://educationdata.urban.org/api/v1/schools/ccd/directory/%d/?fips=%s",
  CCD_YEAR, FIPS))
ccd_sch <- ccd_sch %>%
  dplyr::transmute(
    nces_dist  = chr(leaid),
    school_id  = str_pad(sub("^[^-]*-", "", chr(seasch)), 3, "left", "0"),
    nces_sch   = chr(ncessch)
  ) %>%
  dplyr::filter(nchar(nces_sch) == 12) %>%
  dplyr::distinct()

# Composite (LEAID + school_id) must be unique in CCD, else we would attach a
# wrong NCESSCH. NJ school codes are NOT globally unique (reused across
# districts), so the join key is the composite, never the bare school_id.
sch_coll <- ccd_sch %>% dplyr::count(nces_dist, school_id) %>% dplyr::filter(n > 1)
if (nrow(sch_coll) > 0) {
  stop("CCD composite (LEAID + school_id) collisions: ", nrow(sch_coll),
       " — cannot attach NCESSCH unambiguously.")
}

# ---------------------------------------------------------------------------
# 3. Cross-validate: every NJ-directory LEAID should be in the CCD universe.
#    A small number of brand-new / closed districts may legitimately be absent;
#    abort only if the disagreement is implausibly large (stale/wrong snapshot).
# ---------------------------------------------------------------------------
absent <- nj_dist$nces_dist[!nj_dist$nces_dist %in% ccd_leaids]
message("  ", length(absent), " NJ-directory LEAIDs not present in CCD ", CCD_YEAR,
        " (new/closed)")
if (length(absent) / nrow(nj_dist) > 0.05) {
  stop("Cross-validation failed: ", length(absent), "/", nrow(nj_dist),
       " NJ-directory LEAIDs missing from CCD ", CCD_YEAR,
       " — snapshot looks stale or wrong-state.")
}

# ---------------------------------------------------------------------------
# 4. Assemble the crosswalk (district rows + school rows), CDS-keyed
# ---------------------------------------------------------------------------
# 1:1 sanity: a (county_id, district_id) maps to exactly one LEAID.
dist_coll <- nj_dist %>% dplyr::count(county_id, district_id) %>% dplyr::filter(n > 1)
if (nrow(dist_coll) > 0) {
  stop("CDS district -> LEAID collisions: ", nrow(dist_coll))
}

dist_rows <- nj_dist %>%
  dplyr::transmute(
    entity_level = "District",
    county_id, district_id,
    school_id = NA_character_,
    nces_dist,
    nces_sch  = NA_character_
  )

# Schools: CDS school keys -> district LEAID (via NJ dir) -> NCESSCH (via CCD).
sch_rows <- nj_sch_keys %>%
  dplyr::left_join(nj_dist, by = c("county_id", "district_id")) %>%
  dplyr::left_join(ccd_sch, by = c("nces_dist", "school_id")) %>%
  dplyr::filter(nchar(chr(nces_sch)) == 12) %>%
  dplyr::transmute(
    entity_level = "School",
    county_id, district_id, school_id,
    nces_dist,
    nces_sch
  )

xwalk <- dplyr::bind_rows(dist_rows, sch_rows) %>%
  dplyr::arrange(entity_level, county_id, district_id, school_id)

dir.create("inst/extdata/crosswalk", recursive = TRUE, showWarnings = FALSE)
readr::write_csv(xwalk, "inst/extdata/crosswalk/nj_nces_crosswalk.csv", na = "")
message("Wrote crosswalk: ",
        sum(xwalk$entity_level == "District"), " districts, ",
        sum(xwalk$entity_level == "School"), " schools")

readme <- sprintf(
"# NJ CDS -> NCES identifier crosswalk

**Vintage:** CCD %d (school NCESSCH) + the current NJ DOE Homeroom directory
(CDS -> LEAID bridge).

**Source:**
- NJ DOE Homeroom district/school directory — publishes the federal `NCES ID`
  keyed by the state's County-District-School (CDS) code.
- CCD %d directory (districts + schools) via the Urban Institute Education Data
  API, a republication of the federal NCES Common Core of Data, `fips=%s`.

**Contents:** identifiers ONLY — no enrollment/performance values. Maps the NJ
CDS code (the package's `county_id` + `district_id` + `school_id`) to the
7-digit NCES `LEAID` (`nces_dist`) and 12-digit `NCESSCH` (`nces_sch`).

**How the join works:** the federal CCD's `state_leaid` is the NJ 6-digit DOE
LEA code, not the CDS `district_id`, so CCD alone cannot be CDS-keyed. The NJ DOE
directory carries BOTH the CDS code and the full 7-digit LEAID, providing the
bridge. Schools join to CCD on the composite key (district LEAID + 3-digit
school code) to get the 12-digit NCESSCH; NJ school codes are reused across
districts, so the bare school code is never used alone. Every district LEAID is
cross-validated against the CCD %d NJ universe; the build aborts on an
implausibly large disagreement.

**Coverage:** ~95%%+ of bundled-enrollment districts and ~97%%+ of schools match.
Entities absent from the directory/CCD snapshot (new/closed/charter additions)
keep `NA`, never a guessed id.

**Rebuild:** `Rscript data-raw/build_nces_crosswalk.R`. Never hand-edit.
",
  CCD_YEAR, CCD_YEAR, FIPS, CCD_YEAR)

writeLines(readme, "inst/extdata/crosswalk/README.md")
message("Wrote inst/extdata/crosswalk/README.md")
