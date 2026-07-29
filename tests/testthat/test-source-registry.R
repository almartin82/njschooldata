test_that("the source registry owns verified boundary and skipped years", {
  expect_equal(get_valid_years("enrollment"), 1999:2026)
  expect_equal(get_available_years(), 1999:2026)

  parcc <- get_valid_years("parcc")
  expect_equal(max(parcc), 2025)
  expect_false(any(c(2020, 2021) %in% parcc))
  expect_true(all(c(2015, 2019, 2022, 2025) %in% parcc))

  expect_equal(get_valid_years("grate_4yr"), 2011:2025)
  expect_equal(get_valid_years("grate_6yr"), 2021:2025)
  expect_equal(get_valid_years("access"), 2022:2025)
  expect_equal(get_valid_years("sped"), 2015:2025)
  expect_equal(get_valid_years("sped_placement"), 2020:2025)
  expect_equal(get_valid_years("state_aid"), 2019:2027)
  expect_equal(get_valid_years("finance"), 2001:2026)
  expect_equal(get_valid_years("report_card"), 2012:2019)
  expect_equal(get_valid_years("dfg"), c(1990L, 2000L))
  expect_equal(get_source_years("grad_count", capability = "raw"), 1998:2025)
  expect_equal(get_source_years("grad_count", capability = "tidy"), 2012:2025)
})

test_that("aliases, validation, availability helpers, and resolvers agree", {
  expect_identical(resolve_data_family("enr"), "enrollment")
  expect_identical(resolve_data_family("njsla"), "parcc")
  expect_silent(validate_end_year(1999, "enrollment"))
  expect_error(validate_end_year(2020, "parcc"), "COVID")
  expect_error(validate_end_year(2021, "parcc"), "Start Strong")
  expect_error(validate_end_year(2011, "report_card"), "removed")
  expect_identical(source_gap_status("report_card", 2011), "not_published")

  expect_true(all(get_available_ell_years() == get_source_years("ell")))
  expect_true(all(get_available_finance_years() == get_source_years("finance")))

  expect_match(resolve_source_url("enrollment", end_year = 1999)[1], "enr99")
  expect_match(resolve_source_url("parcc", end_year = 2025, grade = 4, subject = "ela"),
               "2024-25")
  expect_match(resolve_source_url("spr", end_year = 2025, level = "district"),
               "Database_DistrictStateDetail[.]xlsx$")
  expect_identical(get_access_url(2025), resolve_source_url("access", 2025))
  expect_identical(
    get_spr_6yr_grad_url(2025, "district"),
    resolve_source_url("grate_6yr", 2025, level = "district")
  )
  expect_identical(get_valid_sped_years(), get_source_years("sped"))
  expect_identical(
    get_valid_sped_placement_years(),
    get_source_years("sped_placement")
  )
  aid_urls <- resolve_source_url("state_aid", 2027)
  expect_named(aid_urls, c("direct", "archive"))
  expect_match(aid_urls[["direct"]], "2627/FY27_GBM_District_Details[.]xlsx$")
  expect_match(aid_urls[["archive"]], "zippedfiles/2627[.]zip$")

  report_card_urls <- resolve_source_url("report_card", 2019)
  expect_named(report_card_urls, c("school", "district"))
  expect_match(report_card_urls[["school"]], "Database_SchoolDetail[.]xlsx$")
  expect_match(report_card_urls[["district"]],
               "Database_DistrictStateDetail[.]xlsx$")
  expect_match(resolve_source_url("dfg", revision = 2000), "DFG2000[.]xlsx$")

  expect_identical(
    resolve_source_url("directory", level = "school"),
    "https://homeroom4.doe.nj.gov/public/publicschools/download/"
  )
  expect_identical(
    resolve_source_url("directory", level = "district"),
    "https://homeroom4.doe.nj.gov/public/districtpublicschools/download/"
  )
  expect_identical(
    resolve_source_url("directory_spr"),
    "https://www.nj.gov/education/spr/data/202425/schools.json"
  )
})

test_that("raw and tidy capability differences are explicit", {
  registry <- get_source_registry()
  expect_true(all(c("raw_years", "tidy_years", "skipped_years", "source_type") %in%
                    names(registry$grad_count)))
  expect_false(1998 %in% registry$grad_count$tidy_years)
  expect_true(1998 %in% registry$grad_count$raw_years)
})

test_that("registered sources define the host allowlist", {
  hosts <- source_host_allowlist()
  expect_true("www.nj.gov" %in% hosts)
  expect_true("homeroom4.doe.nj.gov" %in% hosts)
  expect_false("homeroom5.doe.nj.gov" %in% hosts)
  expect_true("services2.arcgis.com" %in% hosts)
  expect_true("www.njsda.gov" %in% hosts)
  expect_true("web.archive.org" %in% hosts)
  expect_false("example.com" %in% hosts)

  legacy_note <- get_source_registry()$njask$historical_note
  expect_match(legacy_note, "HTTPS Wayback")
  expect_match(legacy_note, "no direct plaintext request")
})

test_that("README coverage agrees with the registry boundaries", {
  readme <- paste(readLines(
    package_source_path("README.md"), warn = FALSE
  ), collapse = "\n")
  expect_match(readme, "Enrollment.*1999-2026")
  expect_match(readme, "2015-2019 and 2022-2025")
  expect_match(readme, "Graduation.*2011-2025")
})

test_that("authority functions have exactly one top-level definition", {
  r_files <- list.files(package_source_path("R"),
                        pattern = "[.]R$", full.names = TRUE)
  definitions <- unlist(lapply(r_files, readLines, warn = FALSE), use.names = FALSE)

  for (name in c("get_valid_years", "get_school_directory_url",
                 "get_district_directory_url", "get_directory_spr_url")) {
    pattern <- paste0("^", name, "\\s*<-\\s*function\\s*\\(")
    expect_equal(sum(grepl(pattern, definitions)), 1L, info = name)
  }
})

test_that("legacy directory front doors delegate to the registered adapter", {
  calls <- character()
  local_mocked_bindings(
    .directory_source_result = function(level) {
      calls <<- c(calls, level)
      row <- data.frame(
        `County Code` = "07", `District Code` = "3570",
        Address1 = "2 Cedar St", City = "Newark", State = "NJ",
        Zip = "07102", Extra = "preserved", check.names = FALSE
      )
      if (level == "school") row$`School Code` <- "010"
      new_source_result(data = row, source_status = "actual")
    },
    .package = "njschooldata"
  )

  school <- get_school_directory()
  district <- get_district_directory()
  expect_identical(school$cds_code, "073570010")
  expect_identical(district$cds_code, "073570999")
  expect_identical(district$address, "2 Cedar St, Newark, NJ 07102")
  expect_identical(district$extra, "preserved")
  expect_identical(calls, c("school", "district"))

  legacy_source <- paste(readLines(
    package_source_path("R", "fetch_directory.R"), warn = FALSE
  ), collapse = "\n")
  expect_false(grepl("homeroom4[.]doe[.]state[.]nj[.]us", legacy_source))
})

test_that("migrated production fetchers do not bypass the source adapter", {
  for (path in c(
    "R/fetch_directory.R", "R/dfg.R", "R/report_card.R", "R/sped.R"
  )) {
    source <- paste(readLines(package_source_path(path), warn = FALSE),
                    collapse = "\n")
    expect_false(
      grepl(
        "(utils::)?download[.]file\\s*\\(|httr::GET\\s*\\(",
        source
      ),
      info = path
    )
  }
})
