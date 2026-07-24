# ==============================================================================
# directory-contract/v1 builders
# ==============================================================================
#
# Shared, state-agnostic machinery that turns the package's canonical entities
# and roles frames into a conforming snapshot: canonical sorting, and a meta
# block whose counts and quality figures are computed FROM the frames (never
# hand-written, never synthesized). The integrity zeros (missing_id_count,
# placeholder_id_count) are computed honestly here; if either is non-zero the
# package is blocked, and fetch_directory() raises rather than papering over it.
#
# NJ split-name rule (directory-contract/v1 source_vs_normalization):
#   The New Jersey Homeroom directory publishes SPLIT name fields for every
#   person slot (e.g. "Supt First Name" / "Supt Last Name", "Princ First Name"
#   / "Princ Last Name"). We populate first_name / last_name directly from those
#   source-provided split fields and assemble person_name as
#   trimws(paste(first_name, last_name)) when at least one part is present.
#   Assembling a display name from the source's OWN split parts is not synthesis
#   -- it is reconstructing a value the source already carries in two columns.
#   When both parts are absent the seat is a source-declared vacancy
#   (person_name NA, title_raw retained). We never invent a name, and we never
#   split a combined string heuristically.

DC_SCHEMA_VERSION <- "directory-contract/v1"

DC_ROLES <- c(
  "superintendent", "assistant_superintendent", "principal",
  "assistant_principal", "business_administrator", "board_president",
  "board_secretary", "board_member", "special_education_director",
  "charter_school_leader", "primary_contact", "other"
)

DC_ENTITY_TYPES <- c("state", "intermediate", "district", "school")

# Placeholder tokens forbidden as identifiers (case-insensitive, post-trim).
DC_ID_PLACEHOLDERS <- c(
  "", "na", "n/a", "null", "none", "-", "--", "tbd", "unknown", "pending", "0"
)

# Roles that legally carry multiple distinct people on one (district, school)
# key; every other role's collisions are counted in duplicate_key_count.
DC_MULTI_PERSON_ROLES <- c("board_member", "other")

#' Trim leading/trailing whitespace, Unicode-aware
#'
#' Strips ALL leading/trailing whitespace including Unicode spaces (e.g. NBSP,
#' U+00A0) via the PCRE `[\h\v]` class (R >= 3.6). Plain `trimws()` strips only
#' ASCII space, tab, CR, and LF, which the contract's trimming rule and the
#' conformance test's string-hygiene check both reject.
#' @keywords internal
#' @noRd
dc_trim <- function(x) {
  trimws(as.character(x), whitespace = "[\\h\\v]")
}

#' Trim a character vector and convert blanks to NA
#'
#' The contract forbids empty strings anywhere and requires trimmed values.
#' @keywords internal
#' @noRd
dc_blank_to_na <- function(x) {
  if (!is.character(x)) x <- as.character(x)
  x <- dc_trim(x)
  x[!nzchar(x)] <- NA_character_
  x
}

#' Assemble a display name from source-provided split first/last parts
#'
#' Reconstructs person_name from the source's OWN split columns. Not synthesis:
#' the source already carries the two parts; we join them (or return NA when
#' both are absent, i.e. a source-declared vacancy).
#' @keywords internal
#' @noRd
dc_assemble_person_name <- function(first, last) {
  first <- dc_blank_to_na(first)
  last <- dc_blank_to_na(last)
  out <- dc_trim(paste(
    ifelse(is.na(first), "", first),
    ifelse(is.na(last), "", last)
  ))
  out[!nzchar(out)] <- NA_character_
  out
}

#' TRUE for values that are placeholder identifiers
#' @keywords internal
#' @noRd
dc_is_id_placeholder <- function(x) {
  !is.na(x) & tolower(dc_trim(x)) %in% DC_ID_PLACEHOLDERS
}

#' ISO8601 UTC timestamp
#' @keywords internal
#' @noRd
dc_iso8601 <- function(t = Sys.time()) {
  format(as.POSIXct(t, tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}

#' Canonically sort the entities frame (radix, locale-independent)
#'
#' Order: entity_type by vocabulary order, then district_id, then school_id
#' with NA sorting first.
#' @keywords internal
#' @noRd
dc_sort_entities <- function(e) {
  if (nrow(e) == 0L) return(e)
  o <- order(
    match(e$entity_type, DC_ENTITY_TYPES),
    e$district_id,
    e$school_id,
    method = "radix", na.last = FALSE
  )
  e[o, , drop = FALSE]
}

#' Canonically sort the roles frame (radix, locale-independent)
#'
#' Order: district_id, school_id (NA first), role by vocabulary order,
#' person_name (NA first).
#' @keywords internal
#' @noRd
dc_sort_roles <- function(r) {
  if (nrow(r) == 0L) return(r)
  o <- order(
    r$district_id,
    r$school_id,
    match(r$role, DC_ROLES),
    r$person_name,
    method = "radix", na.last = FALSE
  )
  r[o, , drop = FALSE]
}

#' Count identifier defects across both frames (must be zero to conform)
#' @keywords internal
#' @noRd
dc_missing_id_count <- function(entities, roles) {
  e <- entities
  r <- roles
  is_school_e <- e$entity_type == "school"
  sum(
    is.na(e$district_id),
    is.na(r$district_id),
    is.na(e$school_id[is_school_e]),
    is.na(r$school_id[r$entity_type == "school"])
  )
}

#' @keywords internal
#' @noRd
dc_placeholder_id_count <- function(entities, roles) {
  sum(
    dc_is_id_placeholder(entities$district_id),
    dc_is_id_placeholder(entities$school_id),
    dc_is_id_placeholder(roles$district_id),
    dc_is_id_placeholder(roles$school_id)
  )
}

#' Duplicate-key count outside the legally-multi-person roles
#' @keywords internal
#' @noRd
dc_duplicate_key_count <- function(roles) {
  keyed <- roles[
    !is.na(roles$person_name) & !(roles$role %in% DC_MULTI_PERSON_ROLES),
    , drop = FALSE
  ]
  if (nrow(keyed) == 0L) return(0L)
  k <- paste(keyed$district_id, keyed$school_id, keyed$role, sep = "\r")
  sum(vapply(
    split(keyed$person_name, k),
    function(p) length(unique(p)) > 1L,
    logical(1)
  ))
}

#' Per-role named-coverage shares, rounded to 4 decimals
#' @keywords internal
#' @noRd
dc_named_coverage <- function(roles) {
  present <- unique(roles$role)
  out <- lapply(present, function(ro) {
    round(mean(!is.na(roles$person_name[roles$role == ro])), 4)
  })
  stats::setNames(out, present)
}

#' Per-role row counts
#' @keywords internal
#' @noRd
dc_roles_by_role <- function(roles) {
  present <- unique(roles$role)
  out <- lapply(present, function(ro) sum(roles$role == ro))
  stats::setNames(out, present)
}

#' Build the conforming meta block from the frames
#'
#' Counts and quality are computed here from `entities`/`roles`; the caller
#' supplies only source-descriptive fields (state, sources, id_scheme,
#' coverage, source_status). Empty arrays are emitted as character(0) wrapped
#' in I() so they serialize as JSON [] (never null) and never auto-unbox.
#'
#' @keywords internal
#' @noRd
dc_build_meta <- function(entities, roles, state, sources, id_scheme,
                          coverage, source_status, retrieved_at) {
  present_roles <- unique(roles$role)
  unmapped <- sort(unique(roles$title_raw[roles$role == "other"]),
                   method = "radix")

  # entity_types actually present, in vocabulary order
  present_types <- DC_ENTITY_TYPES[DC_ENTITY_TYPES %in% unique(entities$entity_type)]

  coverage_out <- list(
    entity_types   = I(as.character(present_types)),
    district_roles = I(as.character(coverage$district_roles)),
    school_roles   = I(as.character(coverage$school_roles)),
    org_only       = isTRUE(coverage$org_only),
    principal_only = isTRUE(coverage$principal_only),
    notes          = if (is.null(coverage$notes)) NA_character_ else
      as.character(coverage$notes)
  )

  counts_out <- list(
    entities_total = nrow(entities),
    districts      = sum(entities$entity_type == "district"),
    schools        = sum(entities$entity_type == "school"),
    roles_total    = nrow(roles),
    roles_by_role  = dc_roles_by_role(roles)
  )

  quality_out <- list(
    named_coverage      = dc_named_coverage(roles),
    missing_id_count    = dc_missing_id_count(entities, roles),
    placeholder_id_count = dc_placeholder_id_count(entities, roles),
    duplicate_key_count = dc_duplicate_key_count(roles),
    unmapped_title_count = sum(roles$role == "other"),
    unmapped_titles     = I(as.character(unmapped))
  )

  list(
    schema_version = DC_SCHEMA_VERSION,
    state          = state,
    retrieved_at   = retrieved_at,
    source_status  = source_status,
    sources        = sources,
    id_scheme      = id_scheme,
    coverage       = coverage_out,
    counts         = counts_out,
    quality        = quality_out
  )
}
