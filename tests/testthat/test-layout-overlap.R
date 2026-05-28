# test-layout-overlap.R
#
# Regression tests for GitHub issues #47 and #53 — readr::fwf_positions()
# rejected the legacy NJASK/HSPA/GEPA layouts because every layout encodes
# the composite CDS_Code (positions 1-9) AND its decomposed parts
# (County_Code 1-2, District_Code 3-6, School_Code 7-9). Several layouts also
# carry a RECORD_KEY (positions 1-9) that overlaps the same range.
#
# The fix lives in R/fetch_nj_assess.R as two private helpers:
#   - find_redundant_overlaps(layout) -> logical(nrow(layout))
#   - reconstruct_composite_field(df, composite_row, parse_layout) -> df
#
# These tests are FULLY STRUCTURAL — no real legacy assessment data is
# downloaded or parsed. The legacy state.nj.us URLs are 404, and there is no
# archived FWF data in the package (verified during planning). The tests
# prove that the deduplicated layout is parseable, the reconstruction is
# correct, and the on-disk .rda metadata is preserved.

LAYOUTS_WITH_OVERLAP <- c(
  "layout_hspa", "layout_njask",
  "layout_hspa04", "layout_hspa05", "layout_hspa06", "layout_hspa10",
  "layout_njask04", "layout_njask05",
  "layout_njask06gr3", "layout_njask06gr5",
  "layout_njask07gr3", "layout_njask07gr5",
  "layout_njask09", "layout_njask10",
  "layout_gepa", "layout_gepa05", "layout_gepa06"
)

# Pinned overlap-pair counts from the Phase 0 audit. Acts as a regression
# guard — if a future contributor hand-edits a layout, this test surfaces it.
EXPECTED_OVERLAP_PAIRS <- list(
  layout_hspa = 7L,
  layout_njask = 3L,
  layout_hspa04 = 7L,
  layout_hspa05 = 7L,
  layout_hspa06 = 7L,
  layout_hspa10 = 7L,
  layout_njask04 = 3L,
  layout_njask05 = 3L,
  layout_njask06gr3 = 3L,
  layout_njask06gr5 = 7L,
  layout_njask07gr3 = 3L,
  layout_njask07gr5 = 7L,
  layout_njask09 = 3L,
  layout_njask10 = 3L,
  layout_gepa = 3L,
  layout_gepa05 = 3L,
  layout_gepa06 = 3L
)

# Pinned full-layout row counts. Helpful because the fix MUST preserve the
# total column count downstream — process_nj_assess() addresses df by
# positional index into layout.
EXPECTED_LAYOUT_ROWS <- list(
  layout_hspa = 559L, layout_njask = 551L,
  layout_hspa04 = 439L, layout_hspa05 = 463L,
  layout_hspa06 = 511L, layout_hspa10 = 527L,
  layout_njask04 = 362L, layout_njask05 = 435L,
  layout_njask06gr3 = 460L, layout_njask06gr5 = 463L,
  layout_njask07gr3 = 486L, layout_njask07gr5 = 523L,
  layout_njask09 = 524L, layout_njask10 = 524L,
  layout_gepa = 486L, layout_gepa05 = 383L, layout_gepa06 = 461L
)

count_overlap_pairs <- function(layout) {
  n <- nrow(layout)
  if (n < 2) return(0L)
  count <- 0L
  for (i in seq_len(n - 1)) {
    for (j in (i + 1):n) {
      a_s <- layout$field_start_position[i]
      a_e <- layout$field_end_position[i]
      b_s <- layout$field_start_position[j]
      b_e <- layout$field_end_position[j]
      if (a_s <= b_e && b_s <= a_e) count <- count + 1L
    }
  }
  count
}

intervals_strictly_disjoint <- function(layout) {
  if (nrow(layout) < 2) return(TRUE)
  ord <- order(layout$field_start_position)
  s <- layout$field_start_position[ord]
  e <- layout$field_end_position[ord]
  all(e[-length(e)] < s[-1])
}


# -----------------------------------------------------------------------------
# Block A: Layout overlap inventory (regression guard)
# -----------------------------------------------------------------------------

test_that("Block A: every legacy layout has the expected overlap-pair count", {
  for (nm in LAYOUTS_WITH_OVERLAP) {
    expect_true(exists(nm), info = paste("layout missing:", nm))
    lo <- get(nm)
    expect_equal(
      nrow(lo), EXPECTED_LAYOUT_ROWS[[nm]],
      info = paste(nm, "row count drifted")
    )
    expect_equal(
      count_overlap_pairs(lo), EXPECTED_OVERLAP_PAIRS[[nm]],
      info = paste(nm, "overlap-pair count drifted")
    )
  }
})


# -----------------------------------------------------------------------------
# Block B: Deduplication correctness via find_redundant_overlaps()
# -----------------------------------------------------------------------------

test_that("Block B: find_redundant_overlaps drops CDS_Code, keeps the parts", {
  synth <- data.frame(
    field_start_position = c(1, 1, 3, 7, 10),
    field_end_position   = c(9, 2, 6, 9, 59),
    final_name = c("CDS_Code", "County_Code", "District_Code",
                   "School_Code", "County_Name"),
    stringsAsFactors = FALSE
  )

  redundant <- find_redundant_overlaps(synth)

  expect_type(redundant, "logical")
  expect_length(redundant, 5L)
  expect_equal(redundant, c(TRUE, FALSE, FALSE, FALSE, FALSE))

  parse_layout <- synth[!redundant, ]
  expect_true(intervals_strictly_disjoint(parse_layout))
  expect_equal(nrow(parse_layout), 4L)

  # fwf_positions construction must succeed — this is the exact #47/#53 fix
  expect_no_error(
    readr::fwf_positions(
      start = parse_layout$field_start_position,
      end   = parse_layout$field_end_position,
      col_names = parse_layout$final_name
    )
  )
})

test_that("Block B: find_redundant_overlaps drops BOTH CDS_Code and RECORD_KEY", {
  # Mirrors the layout_hspa / layout_hspa04 / etc. pattern: two composite
  # fields (RECORD_KEY and CDS_Code) both spanning positions 1-9, plus the
  # three components.
  synth <- data.frame(
    field_start_position = c(1, 1, 1, 3, 7, 10),
    field_end_position   = c(9, 9, 2, 6, 9, 59),
    final_name = c("RECORD_KEY", "CDS_Code", "County_Code",
                   "District_Code", "School_Code", "County_Name"),
    stringsAsFactors = FALSE
  )

  redundant <- find_redundant_overlaps(synth)

  expect_length(redundant, 6L)
  expect_equal(redundant, c(TRUE, TRUE, FALSE, FALSE, FALSE, FALSE))

  parse_layout <- synth[!redundant, ]
  expect_true(intervals_strictly_disjoint(parse_layout))
})

test_that("Block B: find_redundant_overlaps is order-independent (gepa05 pattern)", {
  # layout_gepa05 carries County_Code BEFORE CDS_Code. Detection must work
  # positionally, not by row order.
  synth <- data.frame(
    field_start_position = c(1, 1, 3, 7, 10),
    field_end_position   = c(2, 9, 6, 9, 59),
    final_name = c("County_Code", "CDS_Code", "District_Code",
                   "School_Code", "County_Name"),
    stringsAsFactors = FALSE
  )

  redundant <- find_redundant_overlaps(synth)

  expect_length(redundant, 5L)
  expect_equal(redundant, c(FALSE, TRUE, FALSE, FALSE, FALSE))
  expect_true(intervals_strictly_disjoint(synth[!redundant, ]))
})

test_that("Block B: find_redundant_overlaps returns FALSE when no overlaps", {
  clean <- data.frame(
    field_start_position = c(1, 3, 7, 10),
    field_end_position   = c(2, 6, 9, 59),
    final_name = c("County_Code", "District_Code", "School_Code", "County_Name"),
    stringsAsFactors = FALSE
  )

  redundant <- find_redundant_overlaps(clean)

  expect_length(redundant, 4L)
  expect_false(any(redundant))
  expect_true(intervals_strictly_disjoint(clean))
})


# -----------------------------------------------------------------------------
# Block C: Reconstruction correctness via reconstruct_composite_field()
# -----------------------------------------------------------------------------

test_that("Block C: composite field is reconstructed by concatenating the parts", {
  # Layout fragment matching the standard CDS_Code pattern. parse_layout is
  # the deduplicated layout (CDS_Code dropped); composite_row describes the
  # dropped composite.
  parse_layout <- data.frame(
    field_start_position = c(1, 3, 7),
    field_end_position   = c(2, 6, 9),
    final_name = c("County_Code", "District_Code", "School_Code"),
    stringsAsFactors = FALSE
  )
  composite_row <- data.frame(
    field_start_position = 1,
    field_end_position   = 9,
    final_name = "CDS_Code",
    stringsAsFactors = FALSE
  )

  # Real NJ CDS code — Newark district (county 13, district 3570), Branch
  # Brook School (school 010). Public directory data, not fabricated.
  df_parsed <- data.frame(
    County_Code   = "13",
    District_Code = "3570",
    School_Code   = "010",
    stringsAsFactors = FALSE
  )

  df_out <- reconstruct_composite_field(df_parsed, composite_row, parse_layout)

  expect_true("CDS_Code" %in% names(df_out))
  expect_type(df_out$CDS_Code, "character")
  expect_equal(df_out$CDS_Code, "133570010")
  expect_equal(nchar(df_out$CDS_Code), 9L)
})

test_that("Block C: multi-row reconstruction preserves per-row composition", {
  parse_layout <- data.frame(
    field_start_position = c(1, 3, 7),
    field_end_position   = c(2, 6, 9),
    final_name = c("County_Code", "District_Code", "School_Code"),
    stringsAsFactors = FALSE
  )
  composite_row <- data.frame(
    field_start_position = 1,
    field_end_position   = 9,
    final_name = "CDS_Code",
    stringsAsFactors = FALSE
  )

  # Three real NJ schools in Newark Public Schools (district 3570):
  #   Branch Brook (010), Camden Street (020), Cleveland (030).
  df_parsed <- data.frame(
    County_Code   = c("13", "13", "13"),
    District_Code = c("3570", "3570", "3570"),
    School_Code   = c("010", "020", "030"),
    stringsAsFactors = FALSE
  )

  df_out <- reconstruct_composite_field(df_parsed, composite_row, parse_layout)

  expect_equal(df_out$CDS_Code, c("133570010", "133570020", "133570030"))
  expect_true(all(nchar(df_out$CDS_Code) == 9L))
})

test_that("Block C: NA in any component yields NA composite", {
  parse_layout <- data.frame(
    field_start_position = c(1, 3, 7),
    field_end_position   = c(2, 6, 9),
    final_name = c("County_Code", "District_Code", "School_Code"),
    stringsAsFactors = FALSE
  )
  composite_row <- data.frame(
    field_start_position = 1,
    field_end_position   = 9,
    final_name = "CDS_Code",
    stringsAsFactors = FALSE
  )

  df_parsed <- data.frame(
    County_Code   = c("13", NA_character_, "13"),
    District_Code = c("3570", "3570", NA_character_),
    School_Code   = c("010", "020", "030"),
    stringsAsFactors = FALSE
  )

  df_out <- reconstruct_composite_field(df_parsed, composite_row, parse_layout)

  expect_equal(df_out$CDS_Code, c("133570010", NA_character_, NA_character_))
})

test_that("Block C: reconstruction is also correct for RECORD_KEY", {
  # RECORD_KEY uses the same positions as CDS_Code in 8 layouts — the helper
  # must work for either composite name without special-casing.
  parse_layout <- data.frame(
    field_start_position = c(1, 3, 7),
    field_end_position   = c(2, 6, 9),
    final_name = c("County_Code", "District_Code", "School_Code"),
    stringsAsFactors = FALSE
  )
  composite_row <- data.frame(
    field_start_position = 1,
    field_end_position   = 9,
    final_name = "RECORD_KEY",
    stringsAsFactors = FALSE
  )

  df_parsed <- data.frame(
    County_Code   = "13",
    District_Code = "3570",
    School_Code   = "010",
    stringsAsFactors = FALSE
  )

  df_out <- reconstruct_composite_field(df_parsed, composite_row, parse_layout)

  expect_true("RECORD_KEY" %in% names(df_out))
  expect_equal(df_out$RECORD_KEY, "133570010")
})


# -----------------------------------------------------------------------------
# Block D: End-to-end on every real layout
# -----------------------------------------------------------------------------

test_that("Block D: every legacy layout deduplicates to a parseable spec", {
  for (nm in LAYOUTS_WITH_OVERLAP) {
    lo <- get(nm)
    redundant <- find_redundant_overlaps(lo)
    parse_layout <- lo[!redundant, ]

    expect_true(
      intervals_strictly_disjoint(parse_layout),
      info = paste(nm, "still has overlaps after dedup")
    )

    # The direct reproduction-fixed assertion for #47/#53
    expect_no_error(
      readr::fwf_positions(
        start = parse_layout$field_start_position,
        end   = parse_layout$field_end_position,
        col_names = parse_layout$final_name
      ),
      message = paste("fwf_positions failed for", nm)
    )
  }
})

test_that("Block D: every layout drops exactly the redundant composite rows", {
  # The expected dropped composites (per Phase 0 audit):
  #   - layouts with RECORD_KEY: drop both RECORD_KEY and CDS_Code (2 rows)
  #   - layouts without RECORD_KEY: drop only CDS_Code (1 row)
  expected_drop_names <- list(
    layout_hspa        = c("RECORD_KEY", "CDS_Code"),
    layout_njask       = "CDS_Code",
    layout_hspa04      = c("RECORD_KEY", "CDS_Code"),
    layout_hspa05      = c("RECORD_KEY", "CDS_Code"),
    layout_hspa06      = c("RECORD_KEY", "CDS_Code"),
    layout_hspa10      = c("RECORD_KEY", "CDS_Code"),
    layout_njask04     = "CDS_Code",
    layout_njask05     = "CDS_Code",
    layout_njask06gr3  = "CDS_Code",
    layout_njask06gr5  = c("RECORD_KEY", "CDS_Code"),
    layout_njask07gr3  = "CDS_Code",
    layout_njask07gr5  = c("RECORD_KEY", "CDS_Code"),
    layout_njask09     = "CDS_Code",
    layout_njask10     = "CDS_Code",
    layout_gepa        = "CDS_Code",
    layout_gepa05      = "CDS_Code",
    layout_gepa06      = "CDS_Code"
  )

  for (nm in names(expected_drop_names)) {
    lo <- get(nm)
    redundant <- find_redundant_overlaps(lo)
    expect_setequal(
      sort(lo$final_name[redundant]),
      sort(expected_drop_names[[nm]])
    )
  }
})


# -----------------------------------------------------------------------------
# Block E: Layout .rda integrity — on-disk objects are byte-unchanged
# -----------------------------------------------------------------------------

test_that("Block E: layout objects are not mutated by the dedup helpers", {
  for (nm in LAYOUTS_WITH_OVERLAP) {
    lo_before <- get(nm)
    digest_before <- digest::digest(lo_before)

    # Exercise both helpers as common_fwf_req() would
    redundant <- find_redundant_overlaps(lo_before)
    parse_layout <- lo_before[!redundant, ]
    # Construct a dummy single-row df with one column per parse_layout row
    dummy_df <- as.data.frame(
      matrix("00", nrow = 1, ncol = nrow(parse_layout)),
      stringsAsFactors = FALSE
    )
    names(dummy_df) <- parse_layout$final_name
    for (i in which(redundant)) {
      dummy_df <- reconstruct_composite_field(
        dummy_df, lo_before[i, , drop = FALSE], parse_layout
      )
    }

    digest_after <- digest::digest(get(nm))
    expect_identical(
      digest_before, digest_after,
      info = paste(nm, "was mutated")
    )
  }
})


# -----------------------------------------------------------------------------
# Block F: Pre-existing tests still skip cleanly (regression guard)
# -----------------------------------------------------------------------------

test_that("Block F: valid_call regression — unrelated path still works", {
  # Sanity check: the fix touches only common_fwf_req(). Other internal
  # helpers must still behave identically.
  expect_true(valid_call(2014, 8))
  expect_false(valid_call(2014, 12))
  expect_true(valid_call(2007, 8))
  expect_false(valid_call(2005, 5))
})

test_that("Block F: nj_coltype_parser regression — sibling helper unchanged", {
  expect_equal(nj_coltype_parser(c("Text", "Integer", "Decimal")), "cid")
})
