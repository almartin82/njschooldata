# Vendored from state-schooldata contracts/directory/v1/rejected-rows-extension-helper.R
# Superproject commit: 2fe66b3f7fe27e2c689c551d66d4833161b13b78
# Helper v2.4.0-rc.3: explicit typed match shapes for partly identified rows.
# Pure, vendorable builder. Adapters supply native IDs and every affected role.
# No names, padding rules or fallback identifiers are used to manufacture keys.
directory_rejected_rows_extension <- function(rejected, roles_by_entity_type,
                                              quarantined_assignments = list(),
                                              school_ids_statewide_unique = FALSE) {
  required <- c("source_row", "reason", "entity_type", "district_id", "school_id")
  if (!is.data.frame(rejected) || !all(required %in% names(rejected)) ||
      !nrow(rejected)) return(NULL)
  text <- function(x) is.character(x) && all(!is.na(x) & nzchar(trimws(x)))
  native <- function(x) text(x) && all(x == trimws(x)) &&
    !any(tolower(x) %in% c("na", "n/a", "null", "none", "-", "--", "tbd",
                          "unknown", "pending", "0"))
  ids <- rejected$source_row
  if (!is.numeric(ids) || anyNA(ids) || any(!is.finite(ids)) ||
      any(ids < 1 | ids != floor(ids) | ids > .Machine$integer.max) ||
      anyDuplicated(ids) || !text(rejected$reason) ||
      !text(rejected$entity_type) ||
      !all(rejected$entity_type %in% c("state", "intermediate", "district", "school")) ||
      !is.logical(school_ids_statewide_unique) || length(school_ids_statewide_unique) != 1L ||
      is.na(school_ids_statewide_unique)) return(NULL)
  # Only explicit match values select broad shapes. Missing match retains exact rules.
  if (!"match" %in% names(rejected)) rejected$match <- NA_character_
  if (!is.character(rejected$match) && !all(is.na(rejected$match))) return(NULL)
  null_id <- function(x) is.null(x) ||
    (is.atomic(x) && length(x) == 1L && is.na(x))
  shape_valid <- function(key) {
    shape <- key$match
    if (length(shape) != 1L || !text(shape)) return(FALSE)
    switch(shape,
      district_role = identical(key$entity_type, "school") &&
        length(key$district_id) == 1L && native(key$district_id) && null_id(key$school_id),
      local_school_role = identical(key$entity_type, "school") &&
        "district_id" %in% names(key) && null_id(key$district_id) &&
        length(key$school_id) == 1L && native(key$school_id),
      unidentified_district_role = identical(key$entity_type, "district") &&
        "district_id" %in% names(key) && null_id(key$district_id) && null_id(key$school_id),
      statewide_role = key$entity_type %in% c("district", "intermediate") &&
        "district_id" %in% names(key) && null_id(key$district_id) && null_id(key$school_id),
      FALSE)
  }
  school <- rejected$entity_type == "school"
  typed <- !is.na(rejected$match)
  parentless <- school & is.na(rejected$district_id) & school_ids_statewide_unique
  exact <- !typed
  if (any(exact & !parentless) && !native(rejected$district_id[exact & !parentless])) return(NULL)
  if (any(exact & school) && !native(rejected$school_id[exact & school])) return(NULL)
  if (any(!is.na(rejected$school_id[exact & !school]))) return(NULL)
  for (i in which(typed)) {
    if (!shape_valid(as.list(rejected[i, , drop = FALSE]))) return(NULL)
  }
  canonical_roles <- c("superintendent", "assistant_superintendent", "principal",
    "assistant_principal", "business_administrator", "board_president",
    "board_secretary", "board_member", "special_education_director",
    "charter_school_leader", "primary_contact", "other")
  if (!is.list(roles_by_entity_type) || is.null(names(roles_by_entity_type)) ||
      anyDuplicated(names(roles_by_entity_type))) return(NULL)
  for (type in unique(rejected$entity_type)) {
    roles <- roles_by_entity_type[[type]]
    if (!length(roles) || !text(roles) || !all(roles %in% canonical_roles) ||
        anyDuplicated(roles)) return(NULL)
  }
  assignments <- list()
  for (i in seq_len(nrow(rejected))) {
    for (role in roles_by_entity_type[[rejected$entity_type[i]]]) {
      key <- list(entity_type = rejected$entity_type[i],
                  district_id = if (is.na(rejected$district_id[i])) NULL else rejected$district_id[i],
                  school_id = if (is.na(rejected$school_id[i])) NULL else rejected$school_id[i],
                  role = role)
      if (typed[i]) key$match <- rejected$match[i]
      match <- which(vapply(assignments, function(a) {
        fields <- c("entity_type", "district_id", "school_id", "role", "match")
        identical(lapply(fields, function(f) a[[f]]), lapply(fields, function(f) key[[f]]))
      }, logical(1)))
      if (!length(match)) {
        assignments[[length(assignments) + 1L]] <- c(key, list(
          reason = paste0("source row withheld: ", rejected$reason[i]),
          source_rows = list(as.integer(ids[i]))))
      } else {
        j <- match[[1]]
        assignments[[j]]$source_rows <- c(assignments[[j]]$source_rows,
                                         list(as.integer(ids[i])))
        assignments[[j]]$reason <- paste(assignments[[j]]$reason,
                                         rejected$reason[i], sep = "; ")
      }
    }
  }
  if (!is.list(quarantined_assignments) || !is.null(names(quarantined_assignments))) return(NULL)
  for (i in seq_along(quarantined_assignments)) {
    key <- quarantined_assignments[[i]]
    if (!is.list(key) || is.null(names(key)) || "source_rows" %in% names(key) ||
        length(key$entity_type) != 1L || !key$entity_type %in% c("state", "intermediate", "district", "school") ||
        length(key$role) != 1L || !key$role %in% canonical_roles ||
        length(key$reason) != 1L || !text(key$reason)) return(NULL)
    if ("match" %in% names(key)) {
      if (!shape_valid(key)) return(NULL)
      if (null_id(key$district_id)) key["district_id"] <- list(NULL)
      if (null_id(key$school_id)) key["school_id"] <- list(NULL)
      quarantined_assignments[[i]] <- key
      next
    }
    missing_parent <- is.null(key$district_id) ||
      (is.atomic(key$district_id) && length(key$district_id) == 1L && is.na(key$district_id))
    no_parent <- identical(key$entity_type, "school") && "district_id" %in% names(key) &&
      missing_parent && school_ids_statewide_unique
    if (!no_parent && (length(key$district_id) != 1L || !native(key$district_id))) return(NULL)
    if (identical(key$entity_type, "school")) {
      if (length(key$school_id) != 1L || !native(key$school_id)) return(NULL)
    } else if (!is.null(key$school_id)) return(NULL)
    if (no_parent) key["district_id"] <- list(NULL)
    quarantined_assignments[[i]] <- key
  }
  result <- list(schema_version = "rejected-source-rows/v1",
       rejected_rows = lapply(seq_len(nrow(rejected)), function(i) {
         list(source_row = as.integer(ids[i]), reason = rejected$reason[i])
       }), assignments = assignments)
  if (length(quarantined_assignments)) result$quarantined_assignments <- quarantined_assignments
  result
}
