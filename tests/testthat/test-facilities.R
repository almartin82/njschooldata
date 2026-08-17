# There is no connectivity probe here on purpose. The guard this file used to
# open with pinged ONE ArcGIS feature server and skipped all seven category
# tests when it did not answer -- even though six of those categories come from
# www.nj.gov and www.njsda.gov and never touch ArcGIS. It answered "is that one
# host up?" when the question is "did this fetch succeed?". The live fetches
# below declare their own outcome instead: a real NJ DOE transport failure
# arrives as njsd_source_unavailable and njsd_live() skips on it by class.
# Nothing else becomes a skip.

# Every live facilities fetch goes through here so a declared NJ DOE source
# condition (njsd_source_unavailable / njsd_not_published / njsd_not_yet_observed)
# becomes a skip that names the category, and a parse failure or a failed
# expectation does not.
facilities_live <- function(category) {
  njsd_live(
    fetch_facilities(category, use_cache = FALSE),
    paste0('fetch_facilities("', category, '")')
  )
}

shipped_facility_categories <- function() {
  c("inventory", "attributes", "capacity", "projects", "finance",
    "environmental", "closures")
}

test_that("facilities category vocabulary is validated", {
  expect_error(fetch_facilities("not_a_category"), "Invalid category")
  expect_error(fetch_facilities(), "Invalid category")
  expect_error(fetch_facilities("condition"), "not available")
  expect_error(fetch_facilities("capital_needs"), "not available")
  expect_false("gis" %in% facilities_categories())
  expect_setequal(
    facilities_categories(),
    c("inventory", "attributes", "capacity", "condition", "capital_needs",
      "projects", "finance", "environmental", "closures")
  )
})

test_that("every shipped category returns the canonical facilities contract", {
  skip_if_no_live_tests()

  for (category in shipped_facility_categories()) {
    out <- facilities_live(category)
    expect_identical(names(out), facilities_columns(), info = category)
    expect_gt(nrow(out), 0, label = category)
    expect_true(is.character(out$value), info = category)
    expect_true(all(out$category == category), info = category)
    expect_true(all(!is.na(out$vintage) & out$vintage != ""), info = category)
    expect_true(all(!is.na(out$source_agency) & out$source_agency != ""), info = category)
    expect_true(all(!is.na(out$source_type) & out$source_type != ""), info = category)
    expect_true(all(!is.na(out$source_url) & out$source_url != ""), info = category)
  }
})

test_that("blank source values are dropped rather than fabricated", {
  skip_if_no_live_tests()
  out <- dplyr::bind_rows(lapply(shipped_facility_categories(), function(category) {
    facilities_live(category)
  }))
  expect_false(any(is.na(out$value)))
  expect_false(any(out$value %in% c("", "NA", "N/A", "-", "null", "NULL")))
})

test_that("count and money metrics are finite and non-negative", {
  skip_if_no_live_tests()
  out <- dplyr::bind_rows(lapply(shipped_facility_categories(), function(category) {
    facilities_live(category)
  }))
  numeric_metrics <- c(
    "sda_grant_allocation", "n_outlets_tested", "n_outlets_exceeded",
    "total_estimated_project_cost", "added_capacity", "new_construction_sq_ft",
    "renovation_sq_ft", "year_constructed"
  )
  numeric_rows <- out[out$metric %in% numeric_metrics, , drop = FALSE]
  values <- suppressWarnings(as.numeric(numeric_rows$value))
  expect_false(any(is.na(values)))
  expect_true(all(is.finite(values)))
  expect_true(all(values >= 0))
})

test_that("pinned inventory, finance, and environmental values match NJ sources", {
  skip_if_no_live_tests()

  inventory <- facilities_live("inventory")
  attales <- inventory[
    inventory$entity_id == "01-0010-050" &
      inventory$metric == "school_category",
  ]
  expect_gt(nrow(attales), 0)
  # Source: NJDOE NJSLEDS County District School Code List, CDS Codes sheet.
  expect_equal(attales$value[1], "Regular Resident School")

  finance <- facilities_live("finance")
  pleasantville <- finance[
    finance$entity_id == "01-4180" &
      finance$metric == "sda_grant_allocation",
  ]
  expect_gt(nrow(pleasantville), 0)
  # Source: NJDOE FY26 Emergent Capital Maintenance Needs Grants Program
  # DistrictAllocationTable.xlsx, Pleasantville City row.
  expect_equal(as.numeric(pleasantville$value[1]), 1000000)

  env <- facilities_live("environmental")
  atlantic_city <- env[
    env$entity_id == "01-0110" &
      env$metric == "n_outlets_exceeded",
  ]
  expect_gt(nrow(atlantic_city), 0)
  # Source: NJDOE 2024-2025 Lead SOA workbook, District sheet.
  expect_equal(as.numeric(atlantic_city$value[1]), 3)
})

test_that("pinned NJSDA project values match active project pages", {
  skip_if_no_live_tests()

  capacity <- facilities_live("capacity")
  bridgeton_capacity <- capacity[
    capacity$entity_id == "11-0540-020" &
      capacity$metric == "added_capacity",
  ]
  expect_gt(nrow(bridgeton_capacity), 0)
  # Source: NJSDA Bridgeton Senior H.S. active project page.
  expect_equal(as.numeric(bridgeton_capacity$value[1]), 326)

  attrs <- facilities_live("attributes")
  bridgeton_year <- attrs[
    attrs$entity_id == "11-0540-020" &
      attrs$metric == "year_constructed",
  ]
  expect_gt(nrow(bridgeton_year), 0)
  expect_equal(as.numeric(bridgeton_year$value[1]), 1952)

  projects <- facilities_live("projects")
  bridgeton_cost <- projects[
    projects$entity_id == "11-0540-020" &
      projects$metric == "total_estimated_project_cost",
  ]
  expect_gt(nrow(bridgeton_cost), 0)
  expect_equal(as.numeric(bridgeton_cost$value[1]), 87200000)
})

test_that("entity levels reflect source grain and NCES ids attach only on CDS rows", {
  skip_if_no_live_tests()

  expect_true(all(facilities_live("inventory")$entity_level == "school"))
  expect_true(all(facilities_live("projects")$entity_level == "project"))
  expect_true(all(facilities_live("capacity")$entity_level == "project"))
  expect_true(all(facilities_live("finance")$entity_level == "district"))
  expect_true(all(facilities_live("environmental")$entity_level %in% c("district", "school")))
  expect_true(all(facilities_live("closures")$entity_level == "school"))

  inventory <- facilities_live("inventory")
  attales <- inventory[inventory$entity_id == "01-0010-050", ]
  expect_true(any(attales$nces_dist == "3400660", na.rm = TRUE))
  expect_true(any(!is.na(attales$nces_sch)))

  projects <- facilities_live("projects")
  expect_true(all(is.na(projects$nces_dist)))
  expect_true(all(is.na(projects$nces_sch)))
})

test_that("fetch_facility_gis supports data-frame and sf modes", {
  skip_if_no_live_tests()

  # Left unguarded: get_raw_facilities_arcgis() reaches NJGIN through
  # httr::stop_for_status(), which raises an httr condition rather than one of
  # the package's njsd_* source classes. Inventing a skip for it would be
  # guessing, so an NJGIN outage fails this opt-in live test instead.
  df <- fetch_facility_gis("school_points", sf = FALSE, use_cache = FALSE)
  expect_s3_class(df, "data.frame")
  expect_true(all(c("latitude", "longitude", "wkt", "source_url") %in% names(df)))
  expect_gt(nrow(df), 0)
  expect_true(any(df$entity_id == "04-1344-00S"))

  if (requireNamespace("sf", quietly = TRUE)) {
    pts <- fetch_facility_gis("school_points", sf = TRUE, use_cache = FALSE)
    expect_s3_class(pts, "sf")
    expect_gt(nrow(pts), 0)
  }

  expect_error(fetch_facility_gis("bogus"), "Invalid layer")
})

test_that("get_available_facilities lists shipped categories and source vintages", {
  av <- get_available_facilities()
  expect_true(all(c("category", "source", "source_agency", "source_type", "source_url", "vintage") %in% names(av)))
  expect_setequal(unique(av$category), shipped_facility_categories())
  expect_false("gis" %in% av$category)
  expect_true(all(!is.na(av$vintage) & av$vintage != ""))
  expect_true(all(!is.na(av$source_agency) & av$source_agency != ""))
})
