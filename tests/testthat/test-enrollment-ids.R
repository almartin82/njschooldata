# ==============================================================================
# Federal NCES id attachment (network-free, uses bundled crosswalk)
# ==============================================================================
#
# NJ enrollment is keyed by the County-District-School (CDS) code. The bundled
# crosswalk maps CDS -> NCES 7-digit LEAID (nces_dist) and 12-digit NCESSCH
# (nces_sch). These tests pin real anchors (the largest NJ districts) and confirm
# unknown ids resolve to NA (never fabricated) and enrollment values are
# untouched by attachment.
# ==============================================================================

test_that("attach_nces_ids maps NJ CDS codes to NCES ids (real anchors)", {
  res <- data.frame(
    county_id   = c("99", "13",   "17",   "31",   "39",   "29",   "13"),
    district_id = c("9999", "3570", "2390", "4010", "1320", "5190", "3570"),
    school_id   = c("999",  "999",  "999",  "999",  "999",  "999",  "010"),
    stringsAsFactors = FALSE
  )
  out <- attach_nces_ids(res)

  expect_true(all(c("nces_dist", "nces_sch") %in% names(out)))

  # Largest NJ districts -> NCES LEAID
  newark <- out[out$county_id == "13" & out$district_id == "3570" &
                  out$school_id == "999", ]
  expect_equal(newark$nces_dist, "3411340")        # Newark Public Schools

  jc <- out[out$county_id == "17" & out$district_id == "2390", ]
  expect_equal(jc$nces_dist, "3407830")            # Jersey City

  paterson <- out[out$county_id == "31" & out$district_id == "4010", ]
  expect_equal(paterson$nces_dist, "3412690")      # Paterson

  elizabeth <- out[out$county_id == "39" & out$district_id == "1320", ]
  expect_equal(elizabeth$nces_dist, "3404590")     # Elizabeth

  toms_river <- out[out$county_id == "29" & out$district_id == "5190", ]
  expect_equal(toms_river$nces_dist, "3416230")    # Toms River Regional

  # A real Newark school -> 12-digit NCESSCH (and inherits the district LEAID)
  school <- out[out$county_id == "13" & out$district_id == "3570" &
                  out$school_id == "010", ]
  expect_equal(school$nces_sch, "341134002188")
  expect_equal(school$nces_dist, "3411340")
  expect_equal(nchar(school$nces_sch), 12L)

  # State aggregate row carries neither id
  state <- out[out$district_id == "9999", ]
  expect_true(is.na(state$nces_dist) && is.na(state$nces_sch))
})


test_that("unknown CDS codes resolve to NA, not a fabricated id", {
  res <- data.frame(
    county_id   = c("88", "88"),
    district_id = c("9990", "9990"),
    school_id   = c("999", "888"),
    stringsAsFactors = FALSE
  )
  out <- attach_nces_ids(res)
  expect_true(all(is.na(out$nces_dist)))
  expect_true(all(is.na(out$nces_sch)))
})


test_that("attach_nces_ids leaves enrollment values byte-identical", {
  res <- data.frame(
    county_id   = c("13", "17"),
    district_id = c("3570", "2390"),
    school_id   = c("999", "999"),
    row_total   = c(38000, 28000),
    white       = c(100, 200),
    stringsAsFactors = FALSE
  )
  out <- attach_nces_ids(res)
  expect_identical(out$row_total, res$row_total)
  expect_identical(out$white, res$white)
})


test_that("bundled crosswalk has well-formed federal ids and no collisions", {
  path <- system.file("extdata", "crosswalk", "nj_nces_crosswalk.csv",
                      package = "njschooldata")
  expect_true(nzchar(path) && file.exists(path))
  x <- utils::read.csv(path, colClasses = "character", stringsAsFactors = FALSE)

  nd <- x$nces_dist[nzchar(x$nces_dist) & !is.na(x$nces_dist)]
  ns <- x$nces_sch[nzchar(x$nces_sch) & !is.na(x$nces_sch)]
  expect_true(all(nchar(nd) == 7))
  expect_true(all(nchar(ns) == 12))
  expect_true(all(c("District", "School") %in% x$entity_level))

  # 1:1: a CDS district maps to exactly one LEAID; a CDS school to one NCESSCH.
  dist <- x[x$entity_level == "District", ]
  d_coll <- aggregate(nces_dist ~ county_id + district_id, dist,
                      function(v) length(unique(v)))
  expect_true(all(d_coll$nces_dist == 1))

  sch <- x[x$entity_level == "School", ]
  s_coll <- aggregate(nces_sch ~ county_id + district_id + school_id, sch,
                      function(v) length(unique(v)))
  expect_true(all(s_coll$nces_sch == 1))
})
