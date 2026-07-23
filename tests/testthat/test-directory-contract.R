# test-directory-contract.R -- directory-contract/v1 conformance test.
#
# MASTER COPY: contracts/directory/v1/conformance-test.R
# This file must be BYTE-IDENTICAL in every conforming package. Never edit
# it in-package; change the master copy and re-propagate to all packages.
# The sha256 of this file is pinned in contracts/directory/v1/ledger.yaml.
#
# Runs fully offline against the package-owned fixture at
# tests/testthat/fixtures/directory-contract/snapshot.rds (see
# contracts/directory/v1/fixture-contract.md). A missing fixture FAILS the
# suite; it never skips. Fixture staleness is guarded by the separate,
# package-authored test-directory-live.R (skip_if_offline).

.dc_schema_version <- "directory-contract/v1"

.dc_roles <- c(
  "superintendent", "assistant_superintendent", "principal",
  "assistant_principal", "business_administrator", "board_president",
  "board_secretary", "board_member", "special_education_director",
  "charter_school_leader", "primary_contact", "other"
)

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

.dc_key <- function(...) {
  parts <- lapply(list(...), function(v) ifelse(is.na(v), "NA", v))
  do.call(paste, c(parts, sep = "\r"))
}

.dc_col_type_ok <- function(df, col, type) {
  if (type == "character") is.character(df[[col]]) else is.logical(df[[col]])
}

.dc_pkg <- testthat::testing_package()
.dc_state <- substr(.dc_pkg, 1, 2)

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

test_that("directory-contract: top-level shape", {
  skip_if(is.null(.dc_snap), "fixture missing (already failed above)")
  expect_true(is.list(.dc_snap))
  expect_true(setequal(names(.dc_snap), c("entities", "roles", "meta")))
  expect_true(is.data.frame(.dc_snap$entities))
  expect_true(is.data.frame(.dc_snap$roles))
  expect_true(is.list(.dc_snap$meta) && !is.data.frame(.dc_snap$meta))
})

test_that("directory-contract: fetch_directory() has the uniform zero-argument signature", {
  fn <- get0("fetch_directory", envir = asNamespace(.dc_pkg))
  expect_true(is.function(fn))
  expect_identical(length(formals(fn)), 0L)
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
      expect_true(all(vv == trimws(vv)), info = paste("untrimmed value in", col))
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
  expect_false(any(is.na(r$title_raw)))
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
  rkey <- .dc_key(r$district_id, r$school_id, r$role, r$person_name)
  expect_false(any(duplicated(rkey)),
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
  multi_ok <- c("board_member", "other")
  keyed <- r[!is.na(r$person_name) & !(r$role %in% multi_ok), , drop = FALSE]
  if (nrow(keyed)) {
    k <- .dc_key(keyed$district_id, keyed$school_id, keyed$role)
    dupes <- sum(vapply(split(keyed$person_name, k),
                        function(p) length(unique(p)) > 1, logical(1)))
  } else {
    dupes <- 0L
  }
  expect_identical(as.integer(q$duplicate_key_count), as.integer(dupes))
  nc <- q$named_coverage
  expect_true(setequal(names(nc), unique(r$role)))
  for (ro in names(nc)) {
    expected <- round(mean(!is.na(r$person_name[r$role == ro])), 4)
    expect_true(abs(as.numeric(nc[[ro]]) - expected) < 5e-5,
      info = paste("named_coverage mismatch for", ro))
  }
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
