# ==============================================================================
# Visible role map: NJ Homeroom verbatim titles -> canonical directory roles
# ==============================================================================
#
# directory-contract/v1 separates what the state SAID (title_raw, kept verbatim)
# from what WE interpret (role, drawn from the closed contract vocabulary). This
# file is that interpretation, made visible and ordered.
#
# New Jersey's Homeroom directory is unusual: it pre-categorizes personnel into
# four dedicated source SLOTS, each a distinct pair of columns --
#   * the district Superintendent slot  ("Supt. Title 2")
#   * the district Business Administrator slot ("BA Title2")
#   * the district Special Education coordinator slot ("SEC Title2")
#   * the school Principal slot ("Princ. Title 2")
# The free-text Title 2 within a slot varies (a superintendent may be titled
# "Chief School Administrator" or "Lead of Charter School"; a special-education
# lead may be titled "Director of Student Services" or, unhelpfully, "Assistant
# Superintendent"). Crucially the SAME verbatim string means different things in
# different slots: "Chief School Administrator" is the district chief in the
# Superintendent slot but a small charter's school leader in the Principal slot.
# A single flat title->role table cannot honor that, so the map is SLOT-SCOPED:
# patterns are matched, in order, case-insensitively against the trimmed title
# only within the person's source slot; the FIRST match wins. Assistant/deputy
# patterns precede their base role so, e.g., "Assistant Superintendent" never
# collapses into "superintendent"; special-education patterns precede the bare
# assistant-superintendent pattern in the SEC slot so "Asst. Supt. of Special
# Education" resolves to special_education_director. Any title no pattern places
# becomes role "other" and is counted (never dropped) in
# meta.quality.unmapped_titles. A bare "Vacant" status is mapped to its slot's
# canonical role so a vacant seat reads as (role, title_raw = "Vacant",
# person_name = NA) rather than being misfiled under "other".

NJ_DIRECTORY_SLOTS <- c("district_chief", "business", "special_ed", "principal")

#' Ordered, slot-scoped NJ directory title -> role map
#'
#' @return A tibble with columns `slot` (one of [NJ_DIRECTORY_SLOTS]), `pattern`
#'   (a case-insensitive Perl regex tested against the trimmed title) and `role`
#'   (a canonical directory-contract/v1 role). Within a slot, row order is
#'   significant: first match wins.
#' @keywords internal
#' @noRd
nj_directory_role_map <- function() {
  tibble::tribble(
    ~slot,             ~pattern,                                    ~role,
    # -- district Superintendent slot ---------------------------------------
    "district_chief",  "assistant\\s+superintendent",               "assistant_superintendent",
    "district_chief",  "associate\\s+superintendent",               "assistant_superintendent",
    "district_chief",  "deputy\\s+superintendent",                  "assistant_superintendent",
    "district_chief",  "superintendent",                            "superintendent",
    "district_chief",  "chief\\s+school\\s+administrator",          "superintendent",
    "district_chief",  "lead\\s+of\\s+charter\\s+school",           "superintendent",
    "district_chief",  "lead\\s+person",                            "superintendent",
    "district_chief",  "head\\s+of\\s+school",                      "superintendent",
    "district_chief",  "executive\\s+director",                     "superintendent",
    "district_chief",  "vacant",                                    "superintendent",
    # -- district Business Administrator slot --------------------------------
    "business",        "business\\s+(administrator|manager|official)", "business_administrator",
    "business",        "\\bb\\.?\\s*a\\.?\\b",                       "business_administrator",
    "business",        "chief\\s+financial\\s+officer",             "business_administrator",
    "business",        "school\\s+business",                        "business_administrator",
    "business",        "vacant",                                    "business_administrator",
    # -- district Special Education coordinator slot -------------------------
    "special_ed",      "spec(?:ial)?\\.?\\s*ed",                    "special_education_director",
    "special_ed",      "child\\s+study\\s+team",                    "special_education_director",
    "special_ed",      "special\\s+services",                       "special_education_director",
    "special_ed",      "student\\s+services",                       "special_education_director",
    "special_ed",      "student\\s+personnel",                      "special_education_director",
    "special_ed",      "pupil\\s+(services|personnel)",             "special_education_director",
    "special_ed",      "assistant\\s+superintendent",               "assistant_superintendent",
    "special_ed",      "asst\\.?\\s*supt",                          "assistant_superintendent",
    "special_ed",      "vacant",                                    "special_education_director",
    # -- school Principal slot ----------------------------------------------
    "principal",       "assistant\\s+principal",                    "assistant_principal",
    "principal",       "vice[-\\s]+principal",                      "assistant_principal",
    "principal",       "principal",                                 "principal",
    "principal",       "head\\s+of\\s+school",                      "principal",
    "principal",       "chief\\s+school\\s+administrator",          "principal",
    "principal",       "school\\s+administrator",                   "principal",
    "principal",       "school\\s+director",                        "principal",
    "principal",       "director\\s+of\\s+school",                  "principal",
    "principal",       "school\\s+lead",                            "principal",
    "principal",       "lead\\s+of\\s+charter\\s+school",           "principal",
    "principal",       "vacant",                                    "principal"
  )
}

#' Map a verbatim NJ title to a canonical directory-contract/v1 role
#'
#' Applies [nj_directory_role_map()] within the person's source `slot`. Titles
#' that no pattern places return "other"; they are never dropped and are
#' surfaced in meta.quality by the contract builder.
#'
#' @param title_raw Character vector of verbatim titles (must be non-NA; the
#'   roles contract requires title_raw on every row).
#' @param slot Character vector, recycled to `title_raw`, naming each title's
#'   source slot (one of [NJ_DIRECTORY_SLOTS]).
#' @return Character vector of canonical roles, same length as `title_raw`.
#' @keywords internal
#' @noRd
nj_map_role <- function(title_raw, slot) {
  if (length(slot) == 1L) slot <- rep(slot, length(title_raw))
  stopifnot(length(slot) == length(title_raw))
  if (!all(slot %in% NJ_DIRECTORY_SLOTS)) {
    stop("nj_map_role received an unknown source slot", call. = FALSE)
  }
  map <- nj_directory_role_map()

  vapply(seq_along(title_raw), function(i) {
    t <- title_raw[i]
    if (is.na(t)) {
      stop("directory role map received a missing title_raw", call. = FALSE)
    }
    tl <- tolower(trimws(t))
    rows <- map[map$slot == slot[i], , drop = FALSE]
    for (j in seq_len(nrow(rows))) {
      if (grepl(rows$pattern[j], tl, perl = TRUE)) {
        return(rows$role[j])
      }
    }
    "other"
  }, character(1), USE.NAMES = FALSE)
}
