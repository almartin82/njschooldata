# GENERATED TEST HELPER: contracts/directory/v1/multiplicity-builder-test-helper.R
#
# Package tests supply state-shaped A, A, B source rows and a closure that calls
# the package's real directory role builder. Keep package copies byte-identical;
# state-specific setup belongs in the calling test, never in this file.

expect_directory_multiplicity_contract_v1 <- function(
    source_rows,
    build_roles,
    expected_names) {
  testthat::expect_true(
    is.data.frame(source_rows),
    info = "source_rows must be a data.frame"
  )
  testthat::expect_true(
    nrow(source_rows) >= 3L,
    info = "source_rows must contain the literal A, A, B proof rows"
  )
  testthat::expect_true(
    is.function(build_roles),
    info = "build_roles must be a closure over the package's real builder"
  )

  first <- source_rows[1L, , drop = FALSE]
  second <- source_rows[2L, , drop = FALSE]
  rownames(first) <- NULL
  rownames(second) <- NULL
  testthat::expect_identical(
    serialize(first, NULL, version = 2L),
    serialize(second, NULL, version = 2L),
    info = "the first two source rows must be byte-identical"
  )

  testthat::expect_length(expected_names, 2L)
  testthat::expect_false(anyNA(expected_names))
  testthat::expect_identical(
    length(unique(expected_names)),
    2L,
    info = "expected_names must name two distinct people"
  )

  roles <- build_roles(source_rows)
  testthat::expect_true(
    is.data.frame(roles),
    info = "the real builder closure must return a data.frame"
  )
  required <- c("district_id", "school_id", "role", "person_name")
  testthat::expect_true(
    all(required %in% names(roles)),
    info = paste("roles must include", paste(required, collapse = ", "))
  )
  testthat::expect_equal(nrow(roles), 2L)
  testthat::expect_setequal(roles$person_name, expected_names)
  testthat::expect_identical(length(unique(roles$person_name)), 2L)

  key_part <- function(value) {
    ifelse(is.na(value), "\001NA", as.character(value))
  }
  role_key <- paste(
    key_part(roles$district_id),
    key_part(roles$school_id),
    key_part(roles$role),
    sep = "\r"
  )
  testthat::expect_identical(
    length(unique(role_key)),
    1L,
    info = "both distinct people must survive under one role key"
  )
  testthat::expect_false(
    any(roles$role %in% c("board_member", "other")),
    info = "the proof must use a non-exempt role"
  )

  assignment_key <- paste(
    role_key,
    key_part(roles$person_name),
    sep = "\r"
  )
  testthat::expect_identical(
    anyDuplicated(assignment_key),
    0L,
    info = "final roles must not repeat an exact canonical assignment"
  )

  keyed <- roles[
    !is.na(roles$person_name) &
      !(roles$role %in% c("board_member", "other")),
    ,
    drop = FALSE
  ]
  keyed_role <- paste(
    key_part(keyed$district_id),
    key_part(keyed$school_id),
    key_part(keyed$role),
    sep = "\r"
  )
  derived_multiplicity <- as.integer(sum(vapply(
    split(keyed$person_name, keyed_role),
    function(people) length(unique(people)) > 1L,
    logical(1)
  )))
  testthat::expect_identical(derived_multiplicity, 1L)

  invisible(roles)
}
