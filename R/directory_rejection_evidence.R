# Map only validated source components to the canonical CDS identifiers. The
# ordinal indexes the combined rejected frame, so separate files cannot collide.
nj_directory_rejected_extension <- function(rejected, spr = FALSE,
                                            quarantined_assignments = list()) {
  required <- c("level", "county_code", "district_code", "school_code", "reason")
  if (!is.data.frame(rejected) || !nrow(rejected) ||
      !all(required %in% names(rejected)) ||
      !all(rejected$level %in% c("district", "school"))) return(NULL)
  valid <- function(x, n) !is.na(x) & grepl(paste0("^[0-9]{", n, "}$"), x)
  parent <- valid(rejected$county_code, 2) & valid(rejected$district_code, 4)
  school <- rejected$level == "school"
  numbered <- valid(rejected$school_code, 3)
  # Canonical school_id includes county and district. A local three-digit
  # number cannot match that key via local_school_role (which compares whole
  # school_id values), so a parentless school must keep the honest hold.
  if (any(school & !parent)) return(NULL)
  mapped <- data.frame(
    source_row = seq_len(nrow(rejected)), reason = rejected$reason,
    entity_type = rejected$level,
    district_id = ifelse(parent, paste0(rejected$county_code, rejected$district_code), NA_character_),
    school_id = ifelse(school & parent & numbered,
      paste0(rejected$county_code, rejected$district_code, rejected$school_code), NA_character_),
    match = ifelse(school & !numbered, "district_role",
      ifelse(!school & !parent, "statewide_role", NA_character_)),
    stringsAsFactors = FALSE
  )
  # A rejected district may also occur in another source row. There is no
  # stable non-CDS account key proving its absence: use statewide_role.
  map <- nj_directory_role_map()
  roles <- list(
    district = unique(c(map$role[map$slot != "principal"], "other")),
    school = unique(c(map$role[map$slot == "principal"], "other"))
  )
  if (spr) roles <- list(district = "superintendent", school = "principal")
  extension <- directory_rejected_rows_extension(mapped, roles,
    quarantined_assignments = quarantined_assignments)
  if (is.null(extension) || !spr) return(extension)
  # Every SPR school row also supplies a district superintendent. Keep one
  # rejected_rows entry per source row while covering both assignment tiers.
  mapped$entity_type <- "district"
  mapped$school_id <- NA_character_
  mapped$match <- ifelse(parent, NA_character_, "statewide_role")
  districts <- directory_rejected_rows_extension(mapped, roles)
  if (is.null(districts)) return(NULL)
  extension$assignments <- c(extension$assignments, districts$assignments)
  extension
}

nj_directory_add_rejection_evidence <- function(meta, rejected, spr = FALSE) {
  old <- meta$extensions[["nj"]]
  quarantine <- list()
  if (!is.null(old)) {
    if (!identical(old$schema_version, "assignment-quarantine/v1")) return(meta)
    quarantine <- old$assignments
  }
  extension <- nj_directory_rejected_extension(rejected, spr, quarantine)
  if (!is.null(extension)) {
    if (!is.null(old)) {
      old$schema_version <- NULL
      old$assignments <- NULL
      extension <- c(extension, old)
    }
    meta$extensions[["nj"]] <- extension
  }
  meta
}
