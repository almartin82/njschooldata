# Stable schemas for the SPR convenience fetchers. These normalize structure
# only: unpublished cells are typed NA, and text tokens are never parsed here.
spr_schema_finish <- function(df, schema, end_year, with_subgroup_std = FALSE) {
  had_rows <- nrow(df) > 0L
  df <- filter_spr_to_year(df, end_year)
  if (had_rows && nrow(df) == 0L) {
    stop("No ", schema, " rows are labelled for end_year ", end_year,
         "; the sheet's school_year labels were not recognized", call. = FALSE)
  }
  df$school_year <- NULL
  aliases <- switch(schema,
    days_absent = .spr_absence_aliases,
    disciplinary_removals = .spr_discipline_aliases,
    violence_vandalism_hib = .spr_incident_aliases,
    staff_ratios = c(.spr_specialist_aliases, spr_staff_ratio_aliases(df)),
    teacher_experience = .spr_teacher_aliases,
    sat_performance = c(average_score_district = "district_avg",
                        average_score_state = "state_avg"),
    dropout_rates = c(
      school_rate = if (any(df$is_school, na.rm = TRUE)) "dropout_school" else "dropout_district",
      state_rate = "dropout_state"
    ),
    character())
  df <- spr_rename_published(df, aliases)
  types <- .spr_output_schemas[[schema]]
  if (is.null(types)) stop("Unknown output schema: ", schema, call. = FALSE)
  optional <- c("value_status", "n_students")
  # Detail fields are optional only for disciplinary removals; subgroup is a
  # required dimension in other fetchers.
  if (schema == "disciplinary_removals") {
    omit <- c(setdiff(optional, names(df)),
              if (!with_subgroup_std) c("subgroup", "subgroup_std", "grade_level"))
    types <- types[!names(types) %in% omit]
  } else {
    types <- types[!names(types) %in% setdiff(c("value_status", "n_students"), names(df))]
  }
  unexpected <- setdiff(names(df), names(types))
  if (length(unexpected)) {
    stop("Undeclared columns in ", schema, ": ", paste(unexpected, collapse = ", "),
         call. = FALSE)
  }
  for (nm in names(types)) {
    type <- types[[nm]]
    if (!nm %in% names(df)) {
      df[[nm]] <- switch(type, character = rep(NA_character_, nrow(df)),
                        numeric = rep(NA_real_, nrow(df)),
                        integer = rep(NA_integer_, nrow(df)),
                        logical = rep(NA, nrow(df)))
    } else {
      if (type %in% c("numeric", "integer") && is.character(df[[nm]]) &&
          any(!is.na(df[[nm]]))) {
        stop("Unexpected published text in numeric field ", nm, call. = FALSE)
      }
      if (type == "integer" && is.numeric(df[[nm]]) &&
          any(df[[nm]] != trunc(df[[nm]]), na.rm = TRUE)) {
        stop("Noninteger published value in integer field ", nm, call. = FALSE)
      }
      df[[nm]] <- switch(type, character = as.character(df[[nm]]),
                        numeric = as.numeric(df[[nm]]),
                        integer = as.integer(df[[nm]]),
                        logical = as.logical(df[[nm]]))
    }
  }
  df[, names(types), drop = FALSE]
}

spr_rename_published <- function(df, aliases) {
  for (old in names(aliases)) {
    new <- aliases[[old]]
    if (!old %in% names(df)) next
    if (new %in% names(df)) {
      if (!identical(as.character(df[[old]]), as.character(df[[new]]))) {
        stop("Conflicting published fields: ", old, " and ", new, call. = FALSE)
      }
      df[[old]] <- NULL
    } else {
      names(df)[names(df) == old] <- new
    }
  }
  df
}

.spr_discipline_aliases <- c(
  number_students_in_school_suspension = "in_school_count",
  percent_students_in_school_suspension = "in_school_pct",
  number_students_outof_school_suspension = "outof_school_count",
  percent_students_outof_school_suspension = "outof_school_pct",
  number_students_any_suspension = "any_susp_count",
  percent_students_any_suspension = "any_susp_pct",
  number_stu_removalto_other_edu_prog = "removal_count",
  percent_stu_removalto_other_edu_prog = "removal_pct",
  number_students_expulsions = "expulsion_count",
  percent_students_expulsions = "expulsion_pct"
)

.spr_incident_aliases <- c(
  hib = "harassment_intimidation_bullying_hib",
  incidents_per_100_students = "incidents_per_100_students_enrolled"
)

.spr_specialist_aliases <- c(
  school_psychologists_school = "school_psychologists",
  school_social_workers_school = "school_social_workers",
  student_assistance_coordinators_school = "student_assistance_coordinators",
  school_safety_specialists_school = "school_safety_specialists"
)

.spr_teacher_aliases <- c(
  number_of_out_of_field_teachers_district = "number_of_out_of_field_teachers",
  percentage_of_out_of_field_teachers_district = "percentage_of_out_of_field_teachers"
)

spr_staff_ratio_aliases <- function(df) {
  # These labels are on NJDOE's StudentToStaffRatios sheet: the numerator
  # is students, including the explicit district comparison columns.
  entity <- if ("teacher_ratio_district" %in% names(df)) "school" else "district"
  c(teacher_ratio = paste0("student_teacher_", entity),
    administrators_ratio = paste0("student_admin_", entity),
    teacher_ratio_district = "student_teacher_district",
    administrators_ratio_district = "student_admin_district",
    librarian_media_specialists_ratio_district = "student_librarian_district",
    nurses_ratio_district = "student_nurse_district",
    counselors_ratio_district = "student_counselor_district",
    child_study_team_ratio_district = "student_child_study_district")
}

ap_participation_2017_wide <- function(df, level) {
  categories <- c(
    StudentsEnrolledInOneOrMoreAPorIBCourse = "apib_course",
    StudentsTakingInOneOrMoreAPorIBExam = "apib_exam",
    StudentsWithOneOrMoreExamsWithAScoreOfAtLest3AP4IBExams = "ap_3_ib_4",
    StudentsEnrolledInOneOrMoreDualEnrollmentCourse = "dual"
  )
  if (any(!df$report_category %in% names(categories))) {
    stop("Unrecognized published AP/IB report category", call. = FALSE)
  }
  df$report_category <- unname(categories[df$report_category])
  entity <- paste0(level, "_percent")
  df <- tidyr::pivot_wider(df, names_from = "report_category",
                           values_from = dplyr::all_of(c(entity, "state_percent")),
                           names_glue = "{report_category}___{.value}")
  for (category in unname(categories)) {
    names(df)[names(df) == paste0(category, "___", entity)] <- paste0(category, "_", level)
    names(df)[names(df) == paste0(category, "___state_percent")] <- paste0(category, "_state")
  }
  df
}

.spr_absence_aliases <- c(
  x_0_percent_absences = "absent_0_pctdays",
  x_0_percent_to_6_9_percent_absences = "absent_gt0_to_6_9_pctdays",
  x_7_percent_to_9_9_percent_absences = "absent_7_0_to_9_9_pctdays",
  x_10_percent_to_12_9_percent_absences = "absent_10_0_to_12_9_pctdays",
  x_13_percent_to_19_9_percent_absences = "absent_13_0_to_19_9_pctdays",
  x_20_percent_or_higher = "absent_20_pctplusdays"
)
