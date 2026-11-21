# test-directory-contract.R -- directory-contract/v1 conformance test.
#
# MASTER COPY: contracts/directory/v1/conformance-test.R
# This file must be BYTE-IDENTICAL in every conforming package. Never edit
# it in-package; change the master copy and re-propagate to all packages.
# Fleet byte identity is checked directly against this master copy.
#
# Runs fully offline against package-owned fixtures and mocked live acquisition at
# tests/testthat/fixtures/directory-contract/snapshot.rds (see
# contracts/directory/v1/fixture-contract.md). A missing fixture FAILS the
# suite; it never skips. Production fetch_directory() is never invoked with its
# real live collaborator by this file. Live validation remains a separate,
# explicit maintainer action.

.dc_schema_version <- "directory-contract/v1"

.dc_roles <- c(
  "superintendent", "assistant_superintendent", "principal",
  "assistant_principal", "business_administrator", "board_president",
  "board_secretary", "board_member", "special_education_director",
  "charter_school_leader", "primary_contact", "other"
)

# How a role was assigned, strongest first. Declare the WEAKEST guarantee that
# holds for every row of that role. "title" is the only value that licenses
# treating the role as the state's own statement about the person, and the only
# one that requires a non-NA title_raw. There is deliberately no "none": every
# row got its role somehow, and naming the weakest real mechanism beats a bucket
# that flattens a state whose own data dictionary names the field into the same
# cell as a state publishing an unlabelled contact and nothing else.
.dc_role_provenance <- c(
  "title", "mixed", "state_dictionary", "declared", "column", "grain"
)

# Above this many titled rows, a role declaring a title-asserting provenance
# must show more than one distinct title. A genuine per-person title field
# always varies at this scale; a synthesized constant is, by construction, the
# same string every time. Below the threshold a uniform value is unremarkable,
# so the rule stays silent there rather than guessing.
.dc_title_constant_min_rows <- 25L

# Provenances that assert the state named this person's job. "mixed" is here
# because its titled rows make exactly the same claim "title" does: the split
# population changes WHICH rows carry a title, never what a carried title has to
# be.
.dc_title_asserting <- c("title", "mixed")

.dc_multi_person_roles <- c("board_member", "other")

.dc_entity_types <- c("state", "intermediate", "district", "school")

.dc_entity_subtypes <- c(
  "charter", "nonpublic", "virtual", "alternative", "regional",
  "career_tech", "special_ed"
)

.dc_source_statuses <- c("ok", "partial", "source_unavailable")

.dc_id_placeholders <- c(
  "", "na", "n/a", "null", "none", "-", "--", "tbd", "unknown", "pending", "0"
)

.dc_person_placeholders <- c(
  "", "na", "n/a", "null", "none", "-", "--", "tbd", "unknown", "pending",
  "vacant", "interim tbd", "open", "position vacant"
)

.dc_entity_cols <- c(
  state = "character", entity_type = "character", entity_subtype = "character",
  district_id = "character", school_id = "character",
  district_name = "character", school_name = "character",
  nces_district_id = "character", nces_school_id = "character",
  parent_district_id = "character", county_name = "character",
  grades_served = "character", address = "character", city = "character",
  zip = "character", phone = "character", website = "character",
  status = "character", is_charter = "logical"
)

.dc_role_cols <- c(
  state = "character", district_id = "character", school_id = "character",
  entity_type = "character", role = "character", title_raw = "character",
  person_name = "character", first_name = "character",
  last_name = "character", email = "character", phone = "character"
)

.dc_iso8601 <- "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(\\.\\d+)?Z$"

.dc_is_placeholder <- function(x, set) {
  !is.na(x) & tolower(trimws(x)) %in% set
}

# A source with no published job title emits title_raw = NA, never one of these.
# A source-declared vacancy is person_name = NA with the row's real title kept,
# so "vacant" is a placeholder here too: it describes the seat, not anyone's job.
.dc_title_placeholders <- c(
  "", "na", "n/a", "null", "none", "-", "--", "tbd", "unknown", "pending",
  "vacant", "position vacant", "open"
)

.dc_title_honorifics <- c(
  "mr", "mrs", "ms", "miss", "mx", "dr", "hon", "rev", "fr", "sr", "prof"
)

# A package whose title_raw is read verbatim from a per-row source field says so
# in its state-owned extension (meta.extensions.<state>):
#
#   title_source_field    named list, role -> the source field each row's title
#                         is read from ("Title"), one per role that carries a
#                         title_raw
#   title_source_headers  optional character vector: every other column header
#                         of the source, so a header string that leaked into the
#                         data can be recognised by name
#
# The declaration is what separates a source that prints a title on every row
# (where the same title on every row, or a lowercase "principal", is simply
# what the state published) from a source with no per-row field where a constant
# was stamped. It never licenses a value that equals the field's own name or one
# of the source's other headers.
.dc_title_norm <- function(x) gsub("[^a-z0-9]", "", tolower(as.character(x)))

.dc_title_source_field <- function(roles, extension) {
  decl <- extension$title_source_field
  if (is.null(decl) || !length(decl)) return(rep(NA_character_, length(roles)))
  vapply(roles, function(ro) {
    value <- decl[[ro]]
    if (is.null(value) || !length(value) || is.na(value[1]) ||
        !nzchar(trimws(as.character(value)[1]))) {
      NA_character_
    } else {
      as.character(value)[1]
    }
  }, character(1), USE.NAMES = FALSE)
}

.dc_title_source_headers <- function(extension) {
  h <- unlist(extension$title_source_headers, use.names = FALSE)
  if (is.null(h)) character() else as.character(h)
}

# TRUE when the values of one role are a single stamped constant, over enough
# rows to be one, and the package has not declared a per-row source field.
.dc_title_is_stamped_constant <- function(values, field_declared) {
  values <- values[!is.na(values)]
  !isTRUE(field_declared) && length(values) > .dc_title_constant_min_rows &&
    length(unique(trimws(values))) == 1L
}

# Shapes a title_raw may never take: the source's own column identifier
# ("headname", "super_name"), the label a published data dictionary gives that
# column ("Principal Name", "Superintendent Name (Districts Only)"), or a bare
# honorific ("Dr."). The field label is the subtle one and the reason this
# exists. It is real published text, written by the state, and it reads like
# prose, so it sails past a "did the state write this?" test. But it names the
# COLUMN, not the human in it, so admitting it would leave the synthesis in
# place wearing a more convincing string.
#
# Without a declared source field, a bare lowercase word or anything containing
# an underscore is read as a column identifier. With one (source_field non-NA for
# that row), the value is a column leak only when it equals the declared field's
# own name or one of the declared source headers: a lowercase "principal" copied
# from a per-row Title field is the state's own text and passes.
.dc_rejected_title_shape <- function(x, source_field = NA_character_,
                                     headers = character()) {
  text <- trimws(x)
  source_field <- rep_len(as.character(source_field), length(text))
  out <- rep(NA_character_, length(text))
  known <- !is.na(text)
  label <- known & grepl("\\bnames?\\b", text, perl = TRUE, ignore.case = TRUE)
  out[label] <- "a data-dictionary field label naming the column, not the person in it"
  declared <- !is.na(source_field)
  ident <- known & is.na(out) & !declared &
    (grepl("_", text, fixed = TRUE) | grepl("^[a-z][a-z0-9]*$", text, perl = TRUE))
  out[ident] <- "a bare source column identifier rather than published prose"
  leaked <- known & is.na(out) & declared &
    (.dc_title_norm(text) == .dc_title_norm(source_field) |
       .dc_title_norm(text) %in% .dc_title_norm(headers))
  out[leaked] <- "the source's own column header, not a value read from it"
  hon <- known & is.na(out) &
    tolower(sub("\\.+$", "", text)) %in% .dc_title_honorifics
  out[hon] <- "an honorific, which is a form of address and not a job"
  out
}

# The declared provenance for each role, or NA where the package has not
# declared one. NA is the legacy state, not a claim that nothing attests it.
.dc_declared_provenance <- function(roles, coverage) {
  prov <- coverage$role_provenance
  if (is.null(prov) || !length(prov)) return(rep(NA_character_, length(roles)))
  vapply(roles, function(ro) {
    value <- prov[[ro]]
    if (is.null(value) || !length(value)) NA_character_ else as.character(value)[1]
  }, character(1), USE.NAMES = FALSE)
}

.dc_key <- function(...) {
  parts <- lapply(list(...), function(v) ifelse(is.na(v), "NA", v))
  do.call(paste, c(parts, sep = "\r"))
}

.dc_exact_assignment_duplicate_count <- function(r) {
  if (!nrow(r)) return(0L)
  key <- .dc_key(r$district_id, r$school_id, r$role, r$person_name)
  as.integer(sum(duplicated(key)))
}

.dc_role_multiplicity_count <- function(r) {
  keyed <- r[
    !is.na(r$person_name) & !(r$role %in% .dc_multi_person_roles),
    ,
    drop = FALSE
  ]
  if (!nrow(keyed)) return(0L)
  key <- .dc_key(keyed$district_id, keyed$school_id, keyed$role)
  as.integer(sum(vapply(
    split(keyed$person_name, key),
    function(p) length(unique(p)) > 1,
    logical(1)
  )))
}

.dc_multiplicity_counter_matches <- function(r, reported) {
  identical(as.integer(reported), .dc_role_multiplicity_count(r))
}

.dc_directory_signature_problem <- function(fn) {
  if (!is.function(fn)) return("fetch_directory is not a function")
  if (length(formals(fn)) != 0L) {
    return("fetch_directory must have exactly zero arguments")
  }
  NULL
}

.dc_count_symbol_calls <- function(expr, symbol) {
  if (!is.call(expr)) return(0L)
  here <- as.integer(identical(expr[[1]], as.name(symbol)))
  here + sum(vapply(as.list(expr)[-1], .dc_count_symbol_calls, integer(1), symbol))
}

# Row screening (directory-contract/v2, STANDARD D-b). An adapter that withholds
# a defective source row one row at a time records it twice: the rows as
# attr(result, "rejected_source_rows") and their number as
# meta$quality$rejected_source_row_count. The count is what a consumer reading
# meta sees; without it a directory that quietly lost rows reads as clean.
.dc_screening_tokens <- c("rejected_source_rows", "rejected_source_row_count")

# A package screens rows when any of its functions names either token, as a
# formal, a symbol or a string constant. Read from the code, not the fixture: a
# fixture captured before the package began screening carries neither record
# and would otherwise pass forever.
.dc_function_screens_rows <- function(fn) {
  if (!is.function(fn) || is.primitive(fn)) return(FALSE)
  text <- paste(deparse(fn), collapse = "\n")
  any(vapply(.dc_screening_tokens, grepl, logical(1), x = text, fixed = TRUE))
}

.dc_namespace_screens_rows <- function(ns) {
  for (nm in ls(ns, all.names = TRUE)) {
    if (.dc_function_screens_rows(get0(nm, envir = ns, inherits = FALSE))) {
      return(TRUE)
    }
  }
  FALSE
}

# NULL when the result's rejection record is consistent, else the reason.
.dc_rejection_record_problem <- function(result, screens) {
  count <- result$meta$quality$rejected_source_row_count
  rows <- attr(result, "rejected_source_rows", exact = TRUE)
  if (is.null(count)) {
    if (!is.null(rows)) {
      return(paste("attr(result, \"rejected_source_rows\") is set but",
                   "meta$quality$rejected_source_row_count is absent"))
    }
    if (isTRUE(screens)) {
      return(paste("the package screens source rows but",
                   "meta$quality$rejected_source_row_count is absent; emit it",
                   "on every call (0 when nothing was withheld) and recapture",
                   "the fixture"))
    }
    return(NULL)
  }
  if (!is.numeric(count) || length(count) != 1L || is.na(count) ||
      count < 0 || count != round(count)) {
    return("meta$quality$rejected_source_row_count must be one non-negative integer")
  }
  if (is.null(rows)) {
    if (count > 0) {
      return(paste0("meta$quality$rejected_source_row_count is ", count,
                    " but no attr(result, \"rejected_source_rows\") names the rows"))
    }
    return(NULL)
  }
  if (!is.data.frame(rows)) {
    return("attr(result, \"rejected_source_rows\") must be a data frame")
  }
  if (nrow(rows) != count) {
    return(paste0("meta$quality$rejected_source_row_count is ", count, " but ",
                  "attr(result, \"rejected_source_rows\") holds ", nrow(rows),
                  " rows"))
  }
  NULL
}

.dc_with_namespace_binding <- function(name, value, code) {
  ns <- asNamespace(.dc_pkg)
  if (!exists(name, envir = ns, inherits = FALSE)) {
    stop("directory-contract: missing internal collaborator ", name)
  }
  old <- get(name, envir = ns, inherits = FALSE)
  was_locked <- bindingIsLocked(name, ns)
  if (was_locked) unlockBinding(name, ns)
  assign(name, value, envir = ns)
  on.exit({
    assign(name, old, envir = ns)
    if (was_locked) lockBinding(name, ns)
  }, add = TRUE)
  force(code)
}

.dc_mock_result <- function(marker, retrieved_at, source_status = "ok") {
  empty_roles <- as.data.frame(
    setNames(lapply(.dc_role_cols, function(type) character(0)), names(.dc_role_cols)),
    stringsAsFactors = FALSE
  )
  empty_roles$phone <- character(0)
  entities <- data.frame(
    state = .dc_state,
    entity_type = "district",
    entity_subtype = NA_character_,
    district_id = paste0("MOCK-", marker),
    school_id = NA_character_,
    district_name = paste("Mock district", marker),
    school_name = NA_character_,
    nces_district_id = NA_character_,
    nces_school_id = NA_character_,
    parent_district_id = NA_character_,
    county_name = NA_character_,
    grades_served = NA_character_,
    address = NA_character_,
    city = NA_character_,
    zip = NA_character_,
    phone = NA_character_,
    website = NA_character_,
    status = "active",
    is_charter = NA,
    stringsAsFactors = FALSE
  )
  list(
    entities = entities,
    roles = empty_roles,
    meta = list(
      schema_version = .dc_schema_version,
      state = .dc_state,
      retrieved_at = retrieved_at,
      source_status = source_status,
      sources = list(list(
        name = "test-only live collaborator",
        url = "https://example.invalid/current-attempt",
        retrieved_at = retrieved_at,
        status = "ok"
      )),
      id_scheme = "test-only mock identifier",
      coverage = list(
        entity_types = "district",
        district_roles = character(0),
        school_roles = character(0),
        org_only = TRUE,
        principal_only = FALSE,
        notes = "Synthetic mock used only by the offline contract test."
      ),
      counts = list(
        entities_total = 1L,
        districts = 1L,
        schools = 0L,
        roles_total = 0L,
        roles_by_role = list()
      ),
      quality = list(
        named_coverage = list(),
        missing_id_count = 0L,
        placeholder_id_count = 0L,
        duplicate_key_count = 0L,
        unmapped_title_count = 0L,
        unmapped_titles = character(0)
      )
    )
  )
}

.dc_declared_miss <- function(retrieved_at) {
  result <- .dc_mock_result("MISS", retrieved_at, "source_unavailable")
  result$entities <- result$entities[0, , drop = FALSE]
  result$meta$sources[[1]]$retrieved_at <- NULL
  result$meta$sources[[1]]$status <- "failed"
  result$meta$counts$entities_total <- 0L
  result$meta$counts$districts <- 0L
  result
}

.dc_col_type_ok <- function(df, col, type) {
  if (type == "character") is.character(df[[col]]) else is.logical(df[[col]])
}

# Resolve the package under test in EVERY harness context.
#
# testthat::testing_package() is populated only when the harness sets it, which
# happens under devtools::test() and R CMD check. Under a bare
# testthat::test_dir() or test_file() it returns "", and the whole gate then
# degraded silently rather than erroring cleanly: asNamespace("") threw, and
# .dc_state collapsed to "" so that every state assertion below compared the
# real state code against "", while the two extension-prefix greps relaxed from
# "^de_[a-z0-9_]+$" to "^_[a-z0-9_]+$". Bare runs reported failures that were
# not real, which makes a real failure indistinguishable from a harness
# artifact.
#
# Fall back to the DESCRIPTION shipped with the sources, covering the same
# three contexts as the package-root discovery in
# ctschooldata/tests/testthat/test-readme-vignette-parity.R. If neither route
# names the package, stop. This gate must never skip and must never assert
# against an empty state code: a scope that collapses to nothing passes green
# and reads as clean to the next person.
.dc_resolve_pkg <- function() {
  harness <- testthat::testing_package()
  if (nzchar(harness)) return(harness)

  # testthat::test_path() ABORTS rather than returning when it cannot locate a
  # test directory, so each candidate is computed defensively. A candidate that
  # cannot be computed is skipped, never allowed to pre-empt the explicit,
  # diagnosable failure at the bottom of this function with a bare
  # "Can't find tests/testthat" from deep inside testthat.
  .safe <- function(expr) tryCatch(expr, error = function(e) character(0))
  candidates <- c(
    .safe(testthat::test_path("..", "..")),                              # devtools::test(), test_dir()
    .safe(Sys.glob(testthat::test_path("..", "..", "00_pkg_src", "*"))), # R CMD check
    file.path(getwd(), "..", ".."),
    getwd()
  )
  for (p in candidates) {
    dcf <- file.path(p, "DESCRIPTION")
    if (!file.exists(dcf)) next
    nm <- tryCatch(
      unname(read.dcf(dcf, fields = "Package")[1, 1]),
      error = function(e) NA_character_
    )
    if (!is.na(nm) && nzchar(nm)) return(nm)
  }

  stop(
    "directory-contract: cannot resolve the package under test. ",
    "testthat::testing_package() returned \"\" and no DESCRIPTION carrying a ",
    "Package field was found from getwd() = ", getwd(), ". Refusing to run: ",
    "an unresolved package name empties .dc_state and relaxes every ",
    "state-anchored assertion in this file."
  )
}

.dc_pkg <- .dc_resolve_pkg()
.dc_state <- substr(.dc_pkg, 1, 2)

test_that("directory-contract: package under test resolves in this harness context", {
  expect_true(nzchar(.dc_pkg))
  expect_match(.dc_pkg, "^[a-z]{2}schooldata$")
  expect_identical(nchar(.dc_state), 2L)
  expect_true(isNamespace(asNamespace(.dc_pkg)))
})

.dc_fixture_path <- testthat::test_path(
  "fixtures", "directory-contract", "snapshot.rds"
)

test_that("directory-contract: fixture exists (missing fixture fails, never skips)", {
  expect_true(
    file.exists(.dc_fixture_path),
    info = "Capture a fixture per contracts/directory/v1/fixture-contract.md"
  )
})

.dc_snap <- if (file.exists(.dc_fixture_path)) readRDS(.dc_fixture_path) else NULL

test_that("directory-contract: constructed assignment and multiplicity semantics", {
  role_rows <- function(role, person_name) {
    data.frame(
      district_id = rep("D1", length(person_name)),
      school_id = rep("S1", length(person_name)),
      role = rep(role, length(person_name)),
      person_name = person_name,
      stringsAsFactors = FALSE
    )
  }

  exact_repeat <- role_rows("principal", c("Alex Principal", "Alex Principal"))
  distinct_people <- role_rows("assistant_principal", c("Avery One", "Blake Two"))
  vacancy_plus_named <- role_rows("principal", c(NA_character_, "Casey Named"))
  exempt_people <- rbind(
    role_rows("board_member", c("Devon Board", "Emery Board")),
    role_rows("other", c("Frankie Other", "Gray Other"))
  )
  exempt_repeat <- role_rows("board_member", c("Devon Board", "Devon Board"))

  expect_identical(.dc_exact_assignment_duplicate_count(exact_repeat), 1L)
  expect_identical(.dc_role_multiplicity_count(exact_repeat), 0L)
  expect_identical(.dc_exact_assignment_duplicate_count(distinct_people), 0L)
  expect_identical(.dc_role_multiplicity_count(distinct_people), 1L)
  expect_identical(.dc_role_multiplicity_count(vacancy_plus_named), 0L)
  expect_identical(.dc_role_multiplicity_count(exempt_people), 0L)
  expect_identical(.dc_exact_assignment_duplicate_count(exempt_repeat), 1L)
  expect_true(.dc_multiplicity_counter_matches(distinct_people, 1L))
  expect_false(.dc_multiplicity_counter_matches(distinct_people, 0L))
  expect_false(.dc_multiplicity_counter_matches(distinct_people, 2L))
})

test_that("directory-contract: constructed live-only signature semantics", {
  expect_identical(.dc_directory_signature_problem(function() NULL), NULL)
  expect_true(grepl(
    "zero arguments",
    .dc_directory_signature_problem(function(source = "live") NULL),
    fixed = TRUE
  ))
  expect_true(grepl(
    "zero arguments",
    .dc_directory_signature_problem(function(source = "package") NULL),
    fixed = TRUE
  ))
  expect_true(grepl(
    "zero arguments",
    .dc_directory_signature_problem(function(max_age_days = NULL) NULL),
    fixed = TRUE
  ))
  expect_true(grepl(
    "zero arguments",
    .dc_directory_signature_problem(function(refresh = FALSE) NULL),
    fixed = TRUE
  ))
  expect_true(grepl(
    "zero arguments",
    .dc_directory_signature_problem(function(use_cache = FALSE) NULL),
    fixed = TRUE
  ))
  expect_true(grepl(
    "zero arguments",
    .dc_directory_signature_problem(function(end_year = NULL) NULL),
    fixed = TRUE
  ))
  expect_true(grepl(
    "zero arguments",
    .dc_directory_signature_problem(function(tidy = TRUE) NULL),
    fixed = TRUE
  ))
  expect_true(grepl(
    "zero arguments",
    .dc_directory_signature_problem(function(...) NULL),
    fixed = TRUE
  ))
  expect_true(grepl(
    "not a function",
    .dc_directory_signature_problem(NULL),
    fixed = TRUE
  ))
})

test_that("directory-contract: constructed row-screening record semantics", {
  screened <- function(count, rows) {
    result <- list(meta = list(quality = list(rejected_source_row_count = count)))
    if (!is.null(rows)) attr(result, "rejected_source_rows") <- rows
    result
  }
  two_rows <- data.frame(reason = c("invalid_id", "missing_name"),
                         stringsAsFactors = FALSE)
  no_count <- list(meta = list(quality = list()))
  rows_no_count <- no_count
  attr(rows_no_count, "rejected_source_rows") <- two_rows

  expect_identical(.dc_rejection_record_problem(screened(0L, NULL), TRUE), NULL)
  expect_identical(.dc_rejection_record_problem(screened(2L, two_rows), TRUE), NULL)
  expect_identical(.dc_rejection_record_problem(no_count, FALSE), NULL)
  expect_false(is.null(.dc_rejection_record_problem(no_count, TRUE)))
  expect_false(is.null(.dc_rejection_record_problem(rows_no_count, FALSE)))
  expect_false(is.null(.dc_rejection_record_problem(screened(3L, two_rows), TRUE)))
  expect_false(is.null(.dc_rejection_record_problem(screened(1L, NULL), TRUE)))
  expect_false(is.null(.dc_rejection_record_problem(screened(-1L, NULL), TRUE)))

  expect_true(.dc_function_screens_rows(function(x) {
    attr(x, "rejected_source_rows") <- data.frame()
    x
  }))
  expect_true(.dc_function_screens_rows(function(rejected_source_row_count = NULL) NULL))
  expect_false(.dc_function_screens_rows(function(x) x))
  expect_false(.dc_function_screens_rows(sum))
})

test_that("directory-contract: constructed title-source semantics", {
  ext <- list(title_source_field = list(principal = "Title",
                                        superintendent = "Title"),
              title_source_headers = c("Admin Name", "Phone"))
  rolevec <- c("principal", "principal", "board_member")

  # The declaration is read per role; an undeclared role or a blank value is NA.
  expect_identical(.dc_title_source_field(rolevec, ext),
                   c("Title", "Title", NA_character_))
  expect_identical(.dc_title_source_field("principal", list()), NA_character_)
  expect_identical(
    .dc_title_source_field("principal", list(title_source_field = list(principal = " "))),
    NA_character_)

  # Verbatim lowercase text from a declared per-row field passes; the same text
  # with no declaration is still read as a column identifier.
  expect_true(is.na(.dc_rejected_title_shape("principal", "Title")))
  expect_false(is.na(.dc_rejected_title_shape("principal", NA_character_)))
  expect_false(is.na(.dc_rejected_title_shape("super_name", NA_character_)))
  expect_true(is.na(.dc_rejected_title_shape("super_name", "Title")))

  # A declared source still rejects the field's own name, any declared header,
  # a field label and an honorific.
  expect_false(is.na(.dc_rejected_title_shape("title", "Title")))
  expect_false(is.na(.dc_rejected_title_shape("TITLE", "Title")))
  expect_false(is.na(.dc_rejected_title_shape("phone", "Title", c("Admin Name", "Phone"))))
  expect_false(is.na(.dc_rejected_title_shape("Principal Name", "Title")))
  expect_false(is.na(.dc_rejected_title_shape("Dr.", "Title")))

  # One constant over many rows is a stamp unless a per-row field is declared.
  stamped <- rep("SUPERINTENDENT", .dc_title_constant_min_rows + 1L)
  expect_true(.dc_title_is_stamped_constant(stamped, FALSE))
  expect_false(.dc_title_is_stamped_constant(stamped, TRUE))
  expect_false(.dc_title_is_stamped_constant(c(stamped, "Interim Superintendent"), FALSE))
  expect_false(.dc_title_is_stamped_constant(stamped[1:5], FALSE))
})

test_that("directory-contract: top-level shape", {
  skip_if(is.null(.dc_snap), "fixture missing (already failed above)")
  expect_true(is.list(.dc_snap))
  expect_true(setequal(names(.dc_snap), c("entities", "roles", "meta")))
  expect_true(is.data.frame(.dc_snap$entities))
  expect_true(is.data.frame(.dc_snap$roles))
  expect_true(is.list(.dc_snap$meta) && !is.data.frame(.dc_snap$meta))
})

test_that("directory-contract: fetch_directory() has exactly zero arguments", {
  fn <- get0("fetch_directory", envir = asNamespace(.dc_pkg))
  expect_true(is.function(fn))
  expect_identical(length(formals(fn)), 0L)
  expect_identical(
    .dc_directory_signature_problem(fn),
    NULL,
    info = .dc_directory_signature_problem(fn)
  )
})

test_that("directory-contract: public path delegates once to the live collaborator", {
  fn <- get0("fetch_directory", envir = asNamespace(.dc_pkg))
  acquire <- get0("directory_live_acquire", envir = asNamespace(.dc_pkg))
  expect_true(is.function(acquire))
  expect_identical(length(formals(acquire)), 0L)
  expect_identical(.dc_count_symbol_calls(body(fn), "directory_live_acquire"), 1L)
})

test_that("directory-contract: every call reflects a fresh collaborator result", {
  fn <- get0("fetch_directory", envir = asNamespace(.dc_pkg))
  calls <- 0L
  responses <- list(
    .dc_mock_result("FIRST", "2026-08-01T10:00:00Z"),
    .dc_mock_result("SECOND", "2026-08-01T10:00:01Z")
  )
  acquire <- function() {
    calls <<- calls + 1L
    responses[[calls]]
  }
  .dc_with_namespace_binding("directory_live_acquire", acquire, {
    first <- fn()
    second <- fn()
  })
  expect_identical(calls, 2L)
  expect_identical(first$entities$district_id, "MOCK-FIRST")
  expect_identical(second$entities$district_id, "MOCK-SECOND")
  expect_identical(first$meta$retrieved_at, "2026-08-01T10:00:00Z")
  expect_identical(second$meta$retrieved_at, "2026-08-01T10:00:01Z")
  expect_identical(
    second$meta$sources[[1]]$retrieved_at,
    "2026-08-01T10:00:01Z"
  )
})

test_that("directory-contract: a failed attempt cannot reuse prior success", {
  fn <- get0("fetch_directory", envir = asNamespace(.dc_pkg))
  calls <- 0L
  responses <- list(
    .dc_mock_result("SUCCESS", "2026-08-01T10:01:00Z"),
    .dc_declared_miss("2026-08-01T10:01:01Z")
  )
  acquire <- function() {
    calls <<- calls + 1L
    responses[[calls]]
  }
  .dc_with_namespace_binding("directory_live_acquire", acquire, {
    first <- fn()
    failed <- fn()
  })
  expect_identical(calls, 2L)
  expect_identical(first$meta$source_status, "ok")
  expect_identical(failed$meta$source_status, "source_unavailable")
  expect_identical(nrow(failed$entities), 0L)
  expect_identical(nrow(failed$roles), 0L)
  expect_identical(failed$meta$retrieved_at, "2026-08-01T10:01:01Z")
  expect_null(failed$meta$sources[[1]]$retrieved_at)
})

test_that("directory-contract: partial means a current-attempt portion succeeded", {
  fn <- get0("fetch_directory", envir = asNamespace(.dc_pkg))
  partial <- .dc_mock_result(
    "PARTIAL",
    "2026-08-01T10:02:00Z",
    source_status = "partial"
  )
  partial$meta$sources[[2]] <- list(
    name = "test-only failed portion",
    url = "https://example.invalid/failed-portion",
    retrieved_at = NULL,
    status = "failed"
  )
  .dc_with_namespace_binding("directory_live_acquire", function() partial, {
    result <- fn()
  })
  expect_identical(result$meta$source_status, "partial")
  expect_identical(nrow(result$entities), 1L)
  expect_identical(
    result$meta$sources[[1]]$retrieved_at,
    "2026-08-01T10:02:00Z"
  )
  expect_null(result$meta$sources[[2]]$retrieved_at)
})

test_that("directory-contract: entities columns, types, and extension rule", {
  skip_if(is.null(.dc_snap), "fixture missing")
  e <- .dc_snap$entities
  expect_true(all(names(.dc_entity_cols) %in% names(e)))
  for (col in names(.dc_entity_cols)) {
    expect_true(
      .dc_col_type_ok(e, col, .dc_entity_cols[[col]]),
      info = paste("entities column type:", col)
    )
  }
  extras <- setdiff(names(e), names(.dc_entity_cols))
  bad <- extras[!grepl(paste0("^", .dc_state, "_[a-z0-9_]+$"), extras)]
  expect_identical(bad, character(0),
    info = paste("nonconforming extension columns:", paste(bad, collapse = ", ")))
})

test_that("directory-contract: roles columns, types, and extension rule", {
  skip_if(is.null(.dc_snap), "fixture missing")
  r <- .dc_snap$roles
  expect_true(all(names(.dc_role_cols) %in% names(r)))
  for (col in names(.dc_role_cols)) {
    expect_true(
      .dc_col_type_ok(r, col, .dc_role_cols[[col]]),
      info = paste("roles column type:", col)
    )
  }
  extras <- setdiff(names(r), names(.dc_role_cols))
  bad <- extras[!grepl(paste0("^", .dc_state, "_[a-z0-9_]+$"), extras)]
  expect_identical(bad, character(0),
    info = paste("nonconforming extension columns:", paste(bad, collapse = ", ")))
})

test_that("directory-contract: string hygiene (no empty strings, values trimmed, UTF-8 valid)", {
  skip_if(is.null(.dc_snap), "fixture missing")
  for (tbl in list(.dc_snap$entities, .dc_snap$roles)) {
    for (col in names(tbl)) {
      v <- tbl[[col]]
      if (!is.character(v)) next
      vv <- v[!is.na(v)]
      expect_false(any(vv == ""), info = paste("empty string in", col))
      expect_true(all(vv == trimws(vv, whitespace = "[\\h\\v]")), info = paste("untrimmed value in", col))
      expect_false(any(is.na(validUTF8(vv))) || any(!validUTF8(vv)),
        info = paste("invalid UTF-8 in", col))
    }
  }
})

test_that("directory-contract: identity rules (native ids everywhere, no placeholders, no synthesis)", {
  skip_if(is.null(.dc_snap), "fixture missing")
  e <- .dc_snap$entities
  r <- .dc_snap$roles
  expect_false(any(is.na(e$district_id)))
  expect_false(any(.dc_is_placeholder(e$district_id, .dc_id_placeholders)))
  expect_false(any(is.na(r$district_id)))
  expect_false(any(.dc_is_placeholder(r$district_id, .dc_id_placeholders)))
  expect_false(any(.dc_is_placeholder(e$school_id, .dc_id_placeholders)))
  expect_false(any(.dc_is_placeholder(r$school_id, .dc_id_placeholders)))
  is_school_e <- e$entity_type == "school"
  expect_false(any(is.na(e$school_id[is_school_e])),
    info = "school entity rows require school_id")
  expect_false(any(is.na(e$school_name[is_school_e])),
    info = "school entity rows require school_name")
  expect_true(all(is.na(e$school_id[!is_school_e])),
    info = "non-school entity rows must have NA school_id")
  is_school_r <- r$entity_type == "school"
  expect_false(any(is.na(r$school_id[is_school_r])),
    info = "school-grain role rows require school_id")
  expect_true(all(is.na(r$school_id[!is_school_r])),
    info = "non-school role rows must have NA school_id")
})

test_that("directory-contract: vocabulary", {
  skip_if(is.null(.dc_snap), "fixture missing")
  e <- .dc_snap$entities
  r <- .dc_snap$roles
  expect_true(all(e$entity_type %in% .dc_entity_types))
  expect_true(all(is.na(e$entity_subtype) | e$entity_subtype %in% .dc_entity_subtypes))
  expect_true(all(r$entity_type %in% .dc_entity_types))
  expect_true(all(r$role %in% .dc_roles))
  expect_identical(unique(e$state), if (nrow(e)) .dc_state else character(0))
  expect_identical(unique(r$state), if (nrow(r)) .dc_state else character(0))
})

test_that("directory-contract: roles required fields and vacancy semantics", {
  skip_if(is.null(.dc_snap), "fixture missing")
  r <- .dc_snap$roles
  # title_raw is the state's verbatim title or it is NA, and which one applies
  # is not the package's free choice: it is fixed by the role's declared
  # provenance, in BOTH directions.
  #
  #   role_provenance == "title"  <=>  title_raw is non-NA
  #
  # Requiring a non-NA title unconditionally is what pushed sources with no
  # job-title field into synthesizing one, which validated cleanly here and was
  # then read downstream as the state's own attestation of a person's job.
  # Merely allowing NA would not have fixed it: a package could keep the
  # synthesized string and declare "grain" beside it, and the row would still
  # assert a title nobody published. Roles carrying no declaration stay on the
  # legacy rule, so a package that has not migrated keeps passing.
  declared <- .dc_declared_provenance(r$role, .dc_snap$meta$coverage)
  legacy <- is.na(declared)
  asserts <- !legacy & declared %in% .dc_title_asserting
  by_title <- !legacy & declared == "title"
  by_mixed <- !legacy & declared == "mixed"
  by_other <- !legacy & !(declared %in% .dc_title_asserting)
  expect_false(any(legacy & is.na(r$title_raw)),
    info = "a role with no declared role_provenance must carry a title_raw")
  expect_false(any(by_title & is.na(r$title_raw)),
    info = "role_provenance 'title' claims the state named this job, so title_raw must be present")
  expect_false(any(by_other & !is.na(r$title_raw)),
    info = paste("a role_provenance other than 'title' or 'mixed' says the source",
                 "publishes no per-person job title, so title_raw must be NA; a",
                 "grain label, a column name and a data-dictionary field label are",
                 "all not titles"))
  # A title that IS present under "mixed" makes the same claim it would under
  # "title", so it faces the identical placeholder and shape regime. The softer
  # part of "mixed" is which rows carry a title, never what a carried title may
  # be.
  expect_false(any(asserts & .dc_is_placeholder(r$title_raw, .dc_title_placeholders)),
    info = "a placeholder is not a job title; a source publishing none emits title_raw = NA")
  title_ext <- .dc_snap$meta$extensions[[.dc_state]]
  title_field <- .dc_title_source_field(r$role, title_ext)
  shape <- .dc_rejected_title_shape(r$title_raw, title_field,
                                    .dc_title_source_headers(title_ext))
  expect_false(any(asserts & !is.na(shape)),
    info = paste("title_raw is", paste(unique(stats::na.omit(shape[asserts])), collapse = "; ")))

  # "mixed" must actually be mixed. A role titled throughout has to say "title"
  # and face the constant rule undiluted; a role titled nowhere has to say which
  # weak signal it was really inferred from. Without both halves "mixed" is just
  # a softer label over the same unattested claim.
  for (ro in unique(r$role[by_mixed])) {
    rows <- r$role == ro
    expect_true(any(!is.na(r$title_raw[rows])),
      info = paste0("role '", ro, "' declares role_provenance 'mixed' but carries ",
                    "no title_raw at all; that role was inferred, not mixed"))
    expect_true(any(is.na(r$title_raw[rows])),
      info = paste0("role '", ro, "' declares role_provenance 'mixed' but every ",
                    "row carries a title_raw; 'mixed' is not a gentler spelling ",
                    "of 'title'"))
  }

  # The aggregate rules. The per-row checks above ask whether each string LOOKS
  # like a job title, and cannot see the failure that motivated them: one
  # constant standing in for thousands of different people's jobs looks
  # perfectly ordinary one row at a time.
  sole_title <- list()
  for (ro in unique(r$role[asserts])) {
    rows <- r$role == ro & !is.na(r$title_raw)
    vals <- unique(trimws(r$title_raw[rows]))
    expect_false(.dc_title_is_stamped_constant(
        r$title_raw[rows], !is.na(.dc_title_source_field(ro, title_ext))),
      info = paste0("role '", ro, "' declares a title-asserting role_provenance on ",
                    sum(rows), " rows that all carry the identical title_raw '",
                    vals[1], "'; a published per-person job title varies across ",
                    "that many people unless the package declares the per-row ",
                    "source field in meta.extensions.<state>$title_source_field"))
    if (length(vals) == 1L) sole_title[[vals[1]]] <- c(sole_title[[vals[1]]], ro)
  }
  for (val in names(sole_title)) {
    expect_false(length(sole_title[[val]]) > 1L,
      info = paste0("title_raw '", val, "' is the only title carried by roles ",
                    paste(sole_title[[val]], collapse = ", "), ", which are ",
                    "different jobs; one string cannot be the state's statement ",
                    "of all of them"))
  }
  expect_false(any(.dc_is_placeholder(r$person_name, .dc_person_placeholders)),
    info = "vacancies are person_name = NA, never placeholder strings")
})

test_that("directory-contract: dedup rules", {
  skip_if(is.null(.dc_snap), "fixture missing")
  e <- .dc_snap$entities
  r <- .dc_snap$roles
  ekey <- .dc_key(e$entity_type, e$district_id, e$school_id)
  expect_false(any(duplicated(ekey)),
    info = "entities must be unique on (entity_type, district_id, school_id)")
  expect_identical(.dc_exact_assignment_duplicate_count(r), 0L,
    info = "roles must be unique on (district_id, school_id, role, person_name)")
})

test_that("directory-contract: referential integrity roles -> entities", {
  skip_if(is.null(.dc_snap), "fixture missing")
  e <- .dc_snap$entities
  r <- .dc_snap$roles
  ekey <- .dc_key(e$entity_type, e$district_id, e$school_id)
  rref <- .dc_key(r$entity_type, r$district_id, r$school_id)
  missing <- unique(rref[!(rref %in% ekey)])
  expect_identical(missing, character(0),
    info = "every roles row must reference an existing entities row")
})

test_that("directory-contract: canonical sort", {
  skip_if(is.null(.dc_snap), "fixture missing")
  e <- .dc_snap$entities
  r <- .dc_snap$roles
  if (nrow(e)) {
    eo <- order(match(e$entity_type, .dc_entity_types), e$district_id,
                e$school_id, method = "radix", na.last = FALSE)
    expect_identical(eo, seq_len(nrow(e)), info = "entities not canonically sorted")
  }
  if (nrow(r)) {
    ro <- order(r$district_id, r$school_id, match(r$role, .dc_roles),
                r$person_name, method = "radix", na.last = FALSE)
    expect_identical(ro, seq_len(nrow(r)), info = "roles not canonically sorted")
  }
})

test_that("directory-contract: meta completeness and version pin", {
  skip_if(is.null(.dc_snap), "fixture missing")
  m <- .dc_snap$meta
  expect_true(all(c("schema_version", "state", "retrieved_at", "source_status",
                    "sources", "id_scheme", "coverage", "counts", "quality")
                  %in% names(m)))
  expect_identical(m$schema_version, .dc_schema_version)
  expect_identical(m$state, .dc_state)
  expect_true(is.character(m$retrieved_at) && grepl(.dc_iso8601, m$retrieved_at))
  expect_true(m$source_status %in% .dc_source_statuses)
  expect_true(is.character(m$id_scheme) && nzchar(m$id_scheme))
  expect_true(is.list(m$sources) && length(m$sources) >= 1)
  for (s in m$sources) {
    expect_true(is.character(s$name) && nzchar(s$name))
    expect_true(is.character(s$url) && nzchar(s$url))
    expect_true(is.null(s$retrieved_at) || is.na(s$retrieved_at[1]) ||
                grepl(.dc_iso8601, s$retrieved_at))
  }
})

test_that("directory-contract: coverage declaration consistency", {
  skip_if(is.null(.dc_snap), "fixture missing")
  m <- .dc_snap$meta
  e <- .dc_snap$entities
  r <- .dc_snap$roles
  cov <- m$coverage
  expect_true(all(c("entity_types", "district_roles", "school_roles",
                    "org_only", "principal_only") %in% names(cov)))
  expect_true(is.character(cov$entity_types) || length(cov$entity_types) == 0)
  expect_true(all(cov$entity_types %in% .dc_entity_types))
  expect_true(all(cov$district_roles %in% .dc_roles))
  expect_true(all(cov$school_roles %in% .dc_roles))
  expect_false(any(duplicated(cov$district_roles)))
  expect_false(any(duplicated(cov$school_roles)))
  expect_true(setequal(unique(e$entity_type), cov$entity_types) || nrow(e) == 0)
  district_grain <- r$entity_type != "school"
  expect_true(all(unique(r$role[district_grain]) %in% cov$district_roles),
    info = "district-grain roles present must be declared in coverage.district_roles")
  expect_true(all(unique(r$role[!district_grain]) %in% cov$school_roles),
    info = "school-grain roles present must be declared in coverage.school_roles")
  expect_true(is.logical(cov$org_only) && length(cov$org_only) == 1)
  expect_true(is.logical(cov$principal_only) && length(cov$principal_only) == 1)
  # role_provenance is optional (packages predating it keep validating) but it
  # is never partial: declare any and you declare one per provided role, from
  # the closed vocabulary. A half-filled map would let a role with an NA title
  # slip through on a neighbouring role's declaration.
  if (!is.null(cov$role_provenance) && length(cov$role_provenance)) {
    prov <- cov$role_provenance
    expect_true(all(names(prov) %in% .dc_roles),
      info = "coverage.role_provenance keys must be canonical roles")
    expect_true(all(vapply(prov, function(v) as.character(v)[1], character(1))
                    %in% .dc_role_provenance),
      info = paste("coverage.role_provenance values must be one of",
                   paste(.dc_role_provenance, collapse = ", ")))
    provided <- union(cov$district_roles, cov$school_roles)
    expect_true(all(provided %in% names(prov)),
      info = paste("coverage.role_provenance is declared but omits provided role(s):",
                   paste(setdiff(provided, names(prov)), collapse = ", ")))
  }
  # A declared title source is never a way to excuse a title the source does not
  # print: it names real roles that assert a title, each with a non-empty field.
  decl <- m$extensions[[.dc_state]]$title_source_field
  if (!is.null(decl) && length(decl)) {
    expect_true(all(names(decl) %in% .dc_roles),
      info = "extensions title_source_field keys must be canonical roles")
    expect_true(all(vapply(decl, function(v) {
      length(v) == 1L && !is.na(v) && nzchar(trimws(as.character(v)))
    }, logical(1))),
      info = "extensions title_source_field values must each name one source field")
    decl_prov <- .dc_declared_provenance(names(decl), cov)
    expect_true(all(decl_prov %in% .dc_title_asserting),
      info = paste("title_source_field may only be declared for roles whose",
                   "role_provenance is 'title' or 'mixed'"))
  }
  if (isTRUE(cov$org_only)) {
    expect_identical(nrow(r), 0L)
    expect_identical(length(cov$district_roles), 0L)
    expect_identical(length(cov$school_roles), 0L)
  }
})

test_that("directory-contract: counts match the tables exactly", {
  skip_if(is.null(.dc_snap), "fixture missing")
  m <- .dc_snap$meta
  e <- .dc_snap$entities
  r <- .dc_snap$roles
  cnt <- m$counts
  expect_true(all(c("entities_total", "districts", "schools", "roles_total",
                    "roles_by_role") %in% names(cnt)))
  expect_identical(as.integer(cnt$entities_total), nrow(e))
  expect_identical(as.integer(cnt$districts), sum(e$entity_type == "district"))
  expect_identical(as.integer(cnt$schools), sum(e$entity_type == "school"))
  expect_identical(as.integer(cnt$roles_total), nrow(r))
  rbr <- cnt$roles_by_role
  expect_true(setequal(names(rbr), unique(r$role)))
  for (ro in names(rbr)) {
    expect_identical(as.integer(rbr[[ro]]), sum(r$role == ro),
      info = paste("roles_by_role mismatch for", ro))
  }
})

test_that("directory-contract: quality invariants (integrity zeros are non-waivable)", {
  skip_if(is.null(.dc_snap), "fixture missing")
  m <- .dc_snap$meta
  r <- .dc_snap$roles
  q <- m$quality
  expect_true(all(c("named_coverage", "missing_id_count", "placeholder_id_count",
                    "duplicate_key_count", "unmapped_title_count",
                    "unmapped_titles") %in% names(q)))
  expect_identical(as.integer(q$missing_id_count), 0L)
  expect_identical(as.integer(q$placeholder_id_count), 0L)
  expect_identical(as.integer(q$unmapped_title_count), sum(r$role == "other"))
  expect_true(is.character(q$unmapped_titles) || length(q$unmapped_titles) == 0)
  expect_identical(
    as.character(q$unmapped_titles),
    sort(unique(r$title_raw[r$role == "other"]), method = "radix")
  )
  expect_identical(
    .dc_role_multiplicity_count(r),
    as.integer(q$duplicate_key_count)
  )
  nc <- q$named_coverage
  expect_true(setequal(names(nc), unique(r$role)))
  for (ro in names(nc)) {
    expected <- round(mean(!is.na(r$person_name[r$role == ro])), 4)
    expect_true(abs(as.numeric(nc[[ro]]) - expected) < 5e-5,
      info = paste("named_coverage mismatch for", ro))
  }
})

test_that("directory-contract: a row-screening package publishes quality.rejected_source_row_count", {
  skip_if(is.null(.dc_snap), "fixture missing")
  screens <- .dc_namespace_screens_rows(asNamespace(.dc_pkg))
  problem <- .dc_rejection_record_problem(.dc_snap, screens)
  expect_identical(problem, NULL, info = problem)
})

test_that("directory-contract: declared miss and non-empty guarantees", {
  skip_if(is.null(.dc_snap), "fixture missing")
  m <- .dc_snap$meta
  e <- .dc_snap$entities
  if (m$source_status == "source_unavailable") {
    expect_identical(nrow(e), 0L)
    expect_identical(nrow(.dc_snap$roles), 0L)
  } else {
    expect_true(sum(e$entity_type == "district") >= 1,
      info = "a live source must yield at least one district entity")
  }
})

test_that("directory-contract: meta JSON serialization (empty arrays are [], never null)", {
  skip_if(is.null(.dc_snap), "fixture missing")
  m <- .dc_snap$meta
  json <- jsonlite::toJSON(m, dataframe = "rows", auto_unbox = TRUE,
                           na = "null", null = "null")
  p <- jsonlite::fromJSON(json, simplifyVector = FALSE)
  expect_true(is.list(p$sources), info = "sources must serialize as an array")
  expect_true(is.list(p$coverage$entity_types),
    info = "coverage.entity_types must serialize as an array (use character(0), not NULL)")
  expect_true(is.list(p$coverage$district_roles),
    info = "coverage.district_roles must serialize as an array (use character(0), not NULL)")
  expect_true(is.list(p$coverage$school_roles),
    info = "coverage.school_roles must serialize as an array (use character(0), not NULL)")
  expect_true(is.list(p$quality$unmapped_titles),
    info = "quality.unmapped_titles must serialize as an array (use character(0), not NULL)")
  expect_identical(p$schema_version, .dc_schema_version)
})
