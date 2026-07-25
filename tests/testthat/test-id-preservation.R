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
