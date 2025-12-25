# Testing Analysis

## Current Test Coverage

### Test File Inventory

| Test File | Lines | Functions Tested |
|-----------|-------|------------------|
| test_enr.R | 592 | get_raw_enr, fetch_enr, enr_aggs, enr_grade_aggs |
| test_charter.R | 263 | charter_sector_*_aggs functions |
| test_grate.R | 181 | fetch_grad_rate, fetch_grad_count |
| test_report_card.R | 254 | get_rc_databases, extract_rc_* |
| test_geo.R | 171 | enrich_school_*, ward_*_aggs |
| test_peer_percentile.R | 123 | *_peer_percentile functions |
| test_msgp.R | 79 | fetch_msgp |
| test_parcc.R | 125 | fetch_parcc, calculate_agg_parcc_prof |
| test_special_pop.R | 78 | fetch_reportcard_special_pop |
| test_fetch_nj_assess.R | 52 | fetch_nj_assess |
| test_sped.R | 33 | fetch_sped |
| test_lookups.R | 29 | district_name_to_id, school_name_to_id |
| test_njask.R | 18 | fetch_njask |
| test_hspa.R | 17 | fetch_hspa |
| test_gepa.R | 17 | fetch_gepa |
| test_process_assess.R | 12 | process_nj_assess |
| test_directory.R | 7 | get_school_directory, get_district_directory |

**Total**: 17 test files, ~2,050 lines of test code

### Estimated Test Coverage

| Category | Exported Functions | Functions with Tests | Coverage |
|----------|-------------------|---------------------|----------|
| Enrollment | 15 | 8 | ~53% |
| Assessment (PARCC) | 10 | 6 | ~60% |
| Assessment (Legacy) | 8 | 5 | ~63% |
| Graduation | 12 | 6 | ~50% |
| Report Card | 15 | 8 | ~53% |
| Charter/Geo | 20 | 12 | ~60% |
| Utilities | 25 | 3 | ~12% |
| **Total** | **155** | **~48** | **~31%** |

## Exported Functions Without Tests

### High Priority (Core API)

| Function | File | Priority |
|----------|------|----------|
| `fetch_tges()` | tges.R | High |
| `fetch_many_tges()` | tges.R | High |
| `tidy_tges_data()` | tges.R | High |
| `get_essa_file()` | essa.R | High |
| `tidy_enr()` | enr.R | High |
| `id_enr_aggs()` | enr.R | High |
| `process_enr()` | enr.R | Medium |
| `get_raw_parcc()` | parcc.R | Medium |
| `get_raw_sla()` | parcc.R | Medium |
| `process_parcc()` | parcc.R | Medium |

### Medium Priority (Utilities)

| Function | File |
|----------|------|
| `trim_whitespace()` | util.R |
| `pad_grade()` | util.R |
| `pad_leading()` | util.R |
| `pad_cds()` | util.R |
| `clean_cds_fields()` | util.R |
| `rc_numeric_cleaner()` | util.R |
| `rc_year_matcher()` | util.R |
| `percentile_rank()` | util.R |
| `trunc2()` | util.R |
| `kill_padformulas()` | util.R |

### Low Priority (Aggregation helpers)

Most `*_column_order` and internal processing functions.

## Test Quality Analysis

### Strengths

1. **Integration Tests**: Tests actually download data from NJ DOE
   ```r
   # test_enr.R:4-10
   test_that("get_raw_enr correctly grabs the 2015 enrollment file", {
     ex_2015 <- get_raw_enr(2015)
     expect_equal(nrow(ex_2015), 26223)
     expect_equal(ncol(ex_2015), 28)
     expect_equal(sum(ex_2015$ROW_TOTAL, na.rm = TRUE), 10954804)
   })
   ```

2. **Historical Validation**: Tests verify specific known values
   ```r
   # test_enr.R:174-233
   # Hand-verified enrollment numbers for Newark Public Schools
   expect_equal(
     nps_2018_total %>% filter(grade_level=='PK') %>% pull(n_students),
     1963
   )
   ```

3. **Multi-Year Testing**: Tests span multiple years
   ```r
   # test_enr.R:103-112
   test_that("all enrollment data can be pulled", {
     enr_all <- map_df(c(2000:2022), fetch_enr)
     expect_is(enr_all, 'data.frame')
   })
   ```

### Weaknesses

1. **No Mocking**: All tests hit live NJ DOE servers
   - Tests are slow
   - Tests can fail due to network issues
   - Tests can break if NJ DOE changes anything
   - Cannot run tests offline

2. **Not testthat 3e**: Still using legacy testthat patterns
   ```r
   # Uses context() - deprecated in testthat 3e
   context("functions in enr")

   # Uses expect_is() - deprecated
   expect_is(fetch_2019, 'data.frame')  # Should be expect_s3_class()
   ```

3. **Missing Edge Case Tests**:
   - No tests for invalid input parameters
   - No tests for network failures
   - No tests for malformed data from NJ DOE
   - No tests for empty/missing data scenarios

4. **No Snapshot Tests**: Would be useful for output format validation

5. **Hardcoded Expected Values**: Many tests will break when new data is added
   ```r
   # This will fail when 2023+ data affects the total
   expect_equal(nrow(enr_all), 727779)
   ```

## testthat 3e Migration

### Changes Required

1. **Remove `context()` calls** (deprecated)
   ```r
   # Before
   context("functions in enr")

   # After - just remove the line
   ```

2. **Replace deprecated expectations**
   ```r
   # Before
   expect_is(df, 'data.frame')

   # After
   expect_s3_class(df, 'data.frame')
   # Or for tibbles
   expect_s3_class(df, 'tbl_df')
   ```

3. **Add to DESCRIPTION**
   ```
   Config/testthat/edition: 3
   ```

4. **Update testthat.R** (if needed)
   ```r
   library(testthat)
   library(njschooldata)

   test_check("njschooldata")
   ```

## Mocking Strategy

### Recommended Package: httptest

For testing web requests without hitting live servers.

```r
# Setup in tests/testthat/helper.R
library(httptest)

# Capture responses once
httptest::capture_requests({
  fetch_enr(2023)
})

# Tests use captured responses
with_mock_api({
  test_that("fetch_enr returns expected structure", {
    result <- fetch_enr(2023)
    expect_s3_class(result, "data.frame")
    expect_true("county_id" %in% names(result))
  })
})
```

### Alternative: webmockr

```r
library(webmockr)

webmockr::enable()

stub_request("get", "https://www.nj.gov/education/doedata/enr/enr23/enrollment_2223.zip") %>%
  to_return(body = readBin("fixtures/enrollment_2223.zip", "raw", n = 1e6))
```

## Recommended Test Structure

```
tests/
├── testthat/
│   ├── helper.R                    # Test utilities, mocking setup
│   ├── setup.R                     # Run before all tests
│   │
│   ├── test-enrollment.R           # fetch_enr, related functions
│   ├── test-enrollment-process.R   # process_enr, clean_* functions
│   ├── test-enrollment-tidy.R      # tidy_enr, enr_aggs
│   │
│   ├── test-assessment-parcc.R     # fetch_parcc, NJSLA
│   ├── test-assessment-legacy.R    # fetch_njask, hspa, gepa
│   │
│   ├── test-graduation-rate.R      # fetch_grad_rate
│   ├── test-graduation-count.R     # fetch_grad_count
│   │
│   ├── test-aggregations.R         # All *_aggs functions
│   ├── test-utilities.R            # util.R functions
│   ├── test-validation.R           # Input validation (new)
│   │
│   └── fixtures/                   # Mock data files
│       ├── enrollment_2023.zip
│       ├── parcc_ela_2019.xlsx
│       └── graduation_2020.xlsx
│
└── testthat.R
```

## New Tests to Add

### 1. Input Validation Tests
```r
test_that("fetch_enr validates end_year parameter", {
  expect_error(fetch_enr("2020"), "end_year must be numeric")
  expect_error(fetch_enr(1990), "end_year must be between")
  expect_error(fetch_enr(2030), "end_year must be between")
  expect_error(fetch_enr(c(2020, 2021)), "end_year must be a single value")
})
```

### 2. Edge Case Tests
```r
test_that("fetch_enr handles missing data gracefully", {
  # Mock a response with missing columns
  with_mock_api({
    result <- fetch_enr(2020)
    expect_true(all(c("county_id", "district_id") %in% names(result)))
  })
})
```

### 3. Output Structure Tests
```r
test_that("fetch_enr output has consistent structure", {
  result <- fetch_enr(2022)

  required_cols <- c(
    "end_year", "CDS_Code", "county_id", "county_name",
    "district_id", "district_name", "school_id", "school_name",
    "row_total"
  )

  expect_true(all(required_cols %in% names(result)))
  expect_type(result$end_year, "double")
  expect_type(result$county_id, "character")
})
```

### 4. Snapshot Tests
```r
test_that("fetch_enr output format is stable", {
  skip_if_not_installed("vdiffr")

  result <- fetch_enr(2022) %>% head(10)
  expect_snapshot(result)
})
```

## Test Performance

### Current Issues
- Full test suite takes 10+ minutes (network-bound)
- Tests cannot run in parallel (shared network state)
- CI runs are slow and flaky

### Recommendations
1. Add mocking for 90% of tests
2. Keep 1-2 "smoke tests" per function that hit live API
3. Mark live tests with `skip_on_cran()` and `skip_on_ci()`
4. Add `test-live-api.R` for manual verification

```r
# test-live-api.R
test_that("live API smoke test: enrollment", {
  skip_on_cran()
  skip_on_ci()
  skip_if_offline()

  result <- fetch_enr(2023)
  expect_s3_class(result, "data.frame")
  expect_gt(nrow(result), 20000)
})
```

## Summary

| Aspect | Current State | Target State |
|--------|--------------|--------------|
| Coverage | ~31% | >70% |
| testthat version | Legacy | 3e edition |
| Mocking | None | httptest for web calls |
| Edge cases | Minimal | Comprehensive |
| Performance | 10+ min | <1 min (mocked) |
| CI reliability | Flaky | Stable |

## Priority Actions

1. **Critical**: Add httptest dependency and mock fixtures
2. **High**: Migrate to testthat 3e edition
3. **High**: Add input validation tests for all exported functions
4. **Medium**: Add tests for untested exported functions
5. **Medium**: Add snapshot tests for output stability
6. **Low**: Separate live API tests from unit tests
