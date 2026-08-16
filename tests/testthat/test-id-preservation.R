# GATE: state-id-preservation
# ==============================================================================
# Native state id preservation alongside federal NCES ids
# ==============================================================================
#
# Policy: nces_dist/nces_sch SUPPLEMENT the native NJ County-District-School
# (CDS) identifiers (county_id, district_id, school_id) - they never replace
# them. This test pins that contract on the real enrollment pipeline
# (attach_nces_ids() -> tidy_enr() -> id_enr_aggs()), the same code fetch_enr()
# runs, so a downstream select()/rename() that drops a native id column fails
# loudly here instead of shipping silently.
#
# Anchors: the same real Newark CDS/NCES pair already pinned in
# test-enrollment-ids.R (county 13, district 3570, school 999/010), read
# straight from the bundled crosswalk
# (inst/extdata/crosswalk/nj_nces_crosswalk.csv). The enrollment counts below
# are synthetic placeholders used only to exercise the tidy pivot mechanics -
# they are not presented as real enrollment and are not the subject of this
# gate (only the id columns are asserted).
# ==============================================================================

# Wide fixture standing in for the output of process_enr(): one district
# aggregate row (school_id "999") and one real school row (school_id "010")
# for Newark, both with a genuine CDS code.
wide_fixture <- data.frame(
  end_year      = c(2024L, 2024L),
  county_id     = c("13", "13"),
  district_id   = c("3570", "3570"),
  school_id     = c("999", "010"),
  county_name   = c("ESSEX", "ESSEX"),
  district_name = c("NEWARK CITY", "NEWARK CITY"),
  school_name   = c("District Total", "School 010"),
  program_code  = c("55", "55"),
  program_name  = c("Total", "Total"),
  grade_level   = c("TOTAL", "TOTAL"),
  row_total     = c(38000, 500),
  white         = c(1000, 50),
  free_lunch    = c(0, 0),
  reduced_lunch = c(0, 0),
  stringsAsFactors = FALSE
)
wide_fixture$cds_code <- paste0(
  wide_fixture$county_id, wide_fixture$district_id, wide_fixture$school_id
)


test_that("native state district/school ids are preserved alongside NCES ids (wide)", {
  wide <- attach_nces_ids(wide_fixture)

  # (a) the federal supplement is present
  expect_true(all(c("nces_dist", "nces_sch") %in% names(wide)))

  # (b) the native NJ CDS ids are STILL present in the same frame
  expect_true(all(c("county_id", "district_id", "school_id") %in% names(wide)))

  dist_row <- wide[wide$school_id == "999", ]
  sch_row  <- wide[wide$school_id == "010", ]

  # native ids are non-empty on both district- and school-grain rows
  expect_false(is.na(dist_row$county_id) || !nzchar(dist_row$county_id))
  expect_false(is.na(dist_row$district_id) || !nzchar(dist_row$district_id))
  expect_false(is.na(sch_row$school_id) || !nzchar(sch_row$school_id))

  # real anchor: Newark Public Schools LEAID + a real Newark school NCESSCH,
  # attached WITHOUT displacing the native county/district/school ids
  expect_equal(dist_row$nces_dist, "3411340")
  expect_equal(dist_row$county_id, "13")
  expect_equal(dist_row$district_id, "3570")

  expect_equal(sch_row$nces_sch, "341134002188")
  expect_equal(sch_row$nces_dist, "3411340")
  expect_equal(sch_row$county_id, "13")
  expect_equal(sch_row$district_id, "3570")
  expect_equal(sch_row$school_id, "010")
})


test_that("native state district/school ids are preserved alongside NCES ids (tidy)", {
  wide <- attach_nces_ids(wide_fixture)
  tidy <- tidy_enr(wide) %>% id_enr_aggs()

  skip_if(nrow(tidy) == 0, "tidy_enr() produced no rows for the fixture")

  # (a) the federal supplement survives the wide -> tidy pivot
  expect_true(all(c("nces_dist", "nces_sch") %in% names(tidy)))

  # (b) the native NJ CDS ids are STILL present in the tidy frame
  expect_true(all(c("county_id", "district_id", "school_id") %in% names(tidy)))

  dist_rows <- tidy[tidy$is_district, ]
  sch_rows  <- tidy[tidy$is_school, ]

  expect_true(nrow(dist_rows) > 0)
  expect_true(nrow(sch_rows) > 0)

  # native ids non-empty on district- and school-grain tidy rows
  expect_true(all(!is.na(dist_rows$district_id) & nzchar(dist_rows$district_id)))
  expect_true(all(!is.na(sch_rows$school_id) & nzchar(sch_rows$school_id)))

  # real anchor round-trips through the pivot: Newark district row still
  # carries its native CDS id alongside its federal LEAID
  newark_dist <- dist_rows[dist_rows$district_id == "3570", ]
  expect_true(nrow(newark_dist) > 0)
  expect_true(all(newark_dist$nces_dist == "3411340"))
  expect_true(all(newark_dist$county_id == "13"))

  # real anchor school row still carries its native school_id alongside its
  # federal NCESSCH
  newark_sch <- sch_rows[sch_rows$school_id == "010", ]
  expect_true(nrow(newark_sch) > 0)
  expect_true(all(newark_sch$nces_sch == "341134002188"))
  expect_true(all(newark_sch$district_id == "3570"))
})


# ==============================================================================
# Composite identifiers: a part the source never published leaves the composite
# MISSING, never the literal characters "NA"
# ==============================================================================
#
# paste0() renders NA as the two characters "NA", so paste0(NA, "3570") is the
# string "NA3570": a plausible-looking id that joins to nothing and reads as
# data. That is the same fabrication as sprintf("%03d", NA) producing "0NA",
# reached by a different route. The literals pinned below are fixed strings, not
# values derived from the code under test, so restoring the bare paste0() turns
# them red.
# ==============================================================================

test_that("na_composite_id() blanks a composite whose parts are not all published", {
  # a real published CDS pair survives byte-for-byte, leading zeros intact
  expect_identical(
    na_composite_id(paste0("13", "3570"), "13", "3570"),
    "133570"
  )
  expect_identical(
    na_composite_id(paste0("13", "3570", "010"), "13", "3570", "010"),
    "133570010"
  )

  # a missing part yields NA -- NOT "NA3570", not "133570", not ""
  expect_identical(
    na_composite_id(paste0(NA_character_, "3570"), NA_character_, "3570"),
    NA_character_
  )
  expect_identical(
    na_composite_id(paste0("13", NA_character_), "13", NA_character_),
    NA_character_
  )

  # a blank source cell is equally unpublished
  expect_identical(na_composite_id(paste0("", "3570"), "", "3570"), NA_character_)
  expect_identical(na_composite_id(paste0("13", "  "), "13", "  "), NA_character_)

  # vectorised, and a length-1 published sentinel recycles without blanking
  parts_county <- c("13", NA_character_, "80")
  parts_district <- c("3570", "3570", "0010")
  expect_identical(
    na_composite_id(
      paste0(parts_county, parts_district, "999"),
      parts_county, parts_district
    ),
    c("133570999", NA_character_, "800010999")
  )
})


test_that("pad_leading() pads published digits only and never invents an id", {
  # digits-only ids pad, and an already-wide id is untouched
  expect_identical(pad_leading("13", 4), "0013")
  expect_identical(pad_leading("3570", 4), "3570")

  # R reads E as scientific notation: as.integer("49E000") is 49. The published
  # id must survive verbatim.
  expect_identical(pad_leading("49E000", 4), "49E000")

  # NA stays NA -- not "00NA", not "NA"
  expect_identical(pad_leading(NA_character_, 4), NA_character_)

  # NJDOE's own "N.A." placeholder is not a number and is not padded into one
  expect_identical(pad_leading("N.A.", 4), "N.A.")

  # a blank cell is left blank, never padded into "0000"
  expect_identical(pad_leading("", 4), "")
})


test_that("get_dfg_districts() never emits a peer-group key built from a missing code", {
  # Stands in for fetch_dfg(): two real NJDOE DFG-A districts (Newark 13/3570,
  # Camden City 07/0680) plus one row whose county code the workbook did not
  # publish. No values are asserted here beyond the identifiers.
  fake_dfg <- data.frame(
    county_id     = c("13", "07", NA_character_),
    county_name   = c("ESSEX", "CAMDEN", "UNKNOWN"),
    district_id   = c("3570", "0680", "1234"),
    district_name = c("NEWARK CITY", "CAMDEN CITY", "UNPUBLISHED COUNTY"),
    dfg           = c("A", "A", "A"),
    stringsAsFactors = FALSE
  )

  testthat::local_mocked_bindings(
    fetch_dfg = function(revision = 2000) fake_dfg,
    .package = "njschooldata"
  )

  ids <- get_dfg_districts("A")

  expect_identical(sort(ids), c("070680", "133570"))
  expect_false(any(grepl("NA", ids, fixed = TRUE)))
  expect_false(any(is.na(ids)))
})


test_that("fetch_spr_science_grade() leaves an unparseable grade token missing", {
  # Stands in for fetch_spr_data(): three NJSLA science grade rows as published
  # (5, 8, 11) plus one row whose grade cell is not a grade at all. Every
  # percentage is NA -- this fixture exercises the grade-token normalization
  # only and asserts nothing about science results.
  fake_sheet <- data.frame(
    end_year        = rep(2022L, 4),
    county_id       = rep("13", 4),
    county_name     = rep("ESSEX", 4),
    district_id     = rep("3570", 4),
    district_name   = rep("NEWARK CITY", 4),
    school_id       = rep("010", 4),
    school_name     = rep("School 010", 4),
    subgroup        = rep("total population", 4),
    grade           = c("Grade 5", "Grade 8", "11", "Districtwide"),
    percent_level_1 = rep(NA_character_, 4),
    percent_level_2 = rep(NA_character_, 4),
    percent_level_3 = rep(NA_character_, 4),
    percent_level_4 = rep(NA_character_, 4),
    is_state        = rep(FALSE, 4),
    is_county       = rep(FALSE, 4),
    is_district     = rep(FALSE, 4),
    is_school       = rep(TRUE, 4),
    is_charter      = rep(FALSE, 4),
    is_charter_sector = rep(FALSE, 4),
    is_allpublic    = rep(FALSE, 4),
    stringsAsFactors = FALSE
  )

  testthat::local_mocked_bindings(
    fetch_spr_data = function(...) fake_sheet,
    .package = "njschooldata"
  )

  out <- fetch_spr_science_grade(2022, level = "school")

  # published grades normalize to the project-standard two-character labels
  expect_identical(out$grade_level[1:3], c("05", "08", "11"))

  # the unparseable token is MISSING -- not the string "NA", not "0NA", not "00"
  expect_true(is.na(out$grade_level[4]))
  expect_identical(out$grade_level[4], NA_character_)
})
