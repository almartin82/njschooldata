load_site_build_helpers <- function() {
  script <- package_source_path("site", "build-data.R")
  withr::local_dir(tempdir())
  env <- new.env(parent = globalenv())
  sys.source(script, envir = env)
  env$.build_manifest$rows <- env$.build_manifest$rows[0, , drop = FALSE]
  env$MANIFEST_PATH <- tempfile(fileext = ".json")
  env
}

load_discovery_build_helpers <- function() {
  script <- package_source_path("site", "discovery-build.R")
  withr::local_dir(tempdir())
  env <- new.env(parent = globalenv())
  sys.source(script, envir = env)
  env$.discovery_manifest$rows <-
    env$.discovery_manifest$rows[0, , drop = FALSE]
  env$SW_DIR <- tempfile("discovery-statewide-")
  dir.create(env$SW_DIR, recursive = TRUE)
  env$DISCOVERY_MANIFEST_PATH <- tempfile(fileext = ".json")
  env
}

test_that("strict site coverage fails and writes every missing request", {
  site <- load_site_build_helpers()
  site$manifest_request("enrollment", 2024:2025, required = TRUE)
  site$manifest_request("optional", 2025, required = FALSE)
  site$manifest_record("enrollment", 2024, status = "actual")
  site$manifest_record(
    "enrollment", 2025, status = "source_unavailable", error = "HTTP 503"
  )
  site$manifest_record(
    "optional", 2025, status = "not_published", completed = FALSE
  )

  expect_error(
    site$assert_required_coverage(FALSE),
    "enrollment/2025.*source_unavailable"
  )
  manifest <- jsonlite::fromJSON(site$MANIFEST_PATH)
  expect_equal(nrow(manifest$requests), 3L)
  expect_identical(
    manifest$requests$source_status,
    c("actual", "source_unavailable", "not_published")
  )
})

test_that("partial site coverage requires an explicit opt-in", {
  site <- load_site_build_helpers()
  site$manifest_request("njgpa", 2025, c("ela", "math"), required = TRUE)
  site$manifest_record("njgpa", 2025, "ela", status = "actual")
  site$manifest_record(
    "njgpa", 2025, "math", status = "parse_error", error = "schema changed"
  )

  expect_error(site$assert_required_coverage(FALSE), "njgpa/2025/math")
  expect_false(site$assert_required_coverage(TRUE))
})

test_that("bundle success is recorded only after an artifact exists", {
  script <- readLines(
    package_source_path("site", "build-data.R"), warn = FALSE
  )
  success_line <- grep("ok <- ok [+] 1", script)
  artifact_line <- grep("file[.]exists[(]artifact[)]", script)
  expect_length(success_line, 1L)
  expect_length(artifact_line, 1L)
  expect_gt(success_line, artifact_line)
})

test_that("site fetch failures use explicit sentinels rather than NULL", {
  site <- load_site_build_helpers()
  site$manifest_request("njgpa", 2025, "math")
  value <- suppressWarnings(site$fetch_year_components(
    2025, "math", function(year, component) stop("bad workbook"), "njgpa"
  ))

  expect_s3_class(value, "data.frame")
  row <- site$.build_manifest$rows
  expect_identical(row$source_status, "source_unavailable")
  expect_match(row$error, "bad workbook")
  expect_false(any(vapply(
    list(site$site_source_failure("parse_error", "bad")),
    is.null,
    logical(1)
  )))
})

test_that("cached partial builds retain per-request source status", {
  site <- load_site_build_helpers()
  site$SW_DIR <- tempfile("site-statewide-")
  dir.create(site$SW_DIR, recursive = TRUE)
  site$manifest_request("njgpa", 2025, c("ela", "math"))

  built <- site$cache_or_build(
    "njgpa-contract",
    function() {
      site$manifest_record("njgpa", 2025, "ela", status = "actual")
      site$manifest_record(
        "njgpa", 2025, "math", status = "parse_error",
        error = "fixture schema changed"
      )
      data.frame(subject = "ela", value = 1)
    },
    refresh = TRUE,
    records_inside = TRUE,
    domain = "njgpa"
  )
  expect_s3_class(built, "data.frame")

  site$.build_manifest$rows <- site$.build_manifest$rows[0, , drop = FALSE]
  site$manifest_request("njgpa", 2025, c("ela", "math"))
  reused <- site$cache_or_build(
    "njgpa-contract",
    function() stop("cache should have been reused"),
    domain = "njgpa"
  )

  expect_s3_class(reused, "data.frame")
  expect_identical(
    site$.build_manifest$rows$source_status,
    c("actual", "parse_error")
  )
  expect_error(site$assert_required_coverage(FALSE), "njgpa/2025/math")
})

test_that("legacy aggregate caches without provenance are not trusted", {
  site <- load_site_build_helpers()
  site$SW_DIR <- tempfile("site-statewide-")
  dir.create(site$SW_DIR, recursive = TRUE)
  site$manifest_request("enrollment", 2025)
  saveRDS(data.frame(end_year = 2025), site$sw_path("enrollment-contract"))

  restored <- site$cache_or_build(
    "enrollment-contract",
    function() stop("cache should have been reused"),
    domain = "enrollment"
  )

  expect_true(site$is_site_source_failure(restored))
  row <- site$.build_manifest$rows
  expect_false(row$completed)
  expect_identical(row$source_status, "source_unavailable")
  expect_match(row$error, "lacks source-manifest provenance")
  expect_error(site$assert_required_coverage(FALSE), "enrollment/2025")
})

test_that("partial site builds cannot consume incompletely proven caches", {
  site <- load_site_build_helpers()
  site$SW_DIR <- tempfile("site-statewide-")
  dir.create(site$SW_DIR, recursive = TRUE)
  site$manifest_request("njgpa", 2025, c("ela", "math"))

  cached <- data.frame(subject = "ela", value = 1)
  attr(cached, site$SITE_MANIFEST_ATTR) <- data.frame(
    domain = "njgpa",
    end_year = 2025L,
    component = "ela",
    completed = TRUE,
    source_status = "actual",
    source_url = "https://www.nj.gov/ela.xlsx",
    retrieved_at = "2026-01-01 UTC",
    digest = "fixture",
    warning = NA_character_,
    error = NA_character_
  )
  saveRDS(cached, site$sw_path("njgpa-contract"))

  restored <- site$cache_or_build(
    "njgpa-contract",
    function() stop("cache should have been reused"),
    domain = "njgpa"
  )

  expect_true(site$is_site_source_failure(restored))
  expect_identical(
    site$.build_manifest$rows$source_status,
    c("actual", "source_unavailable")
  )
  expect_false(site$assert_required_coverage(TRUE))
})

test_that("aggregate parse failures supersede successful source retrieval", {
  site <- load_site_build_helpers()
  site$SW_DIR <- tempfile("site-statewide-")
  dir.create(site$SW_DIR, recursive = TRUE)
  site$manifest_request("enrollment", 2025)

  value <- suppressWarnings(site$cache_or_build(
    "enrollment-contract",
    function() {
      site$manifest_record("enrollment", 2025, status = "actual")
      stop("unexpected statewide schema")
    },
    refresh = TRUE,
    records_inside = TRUE,
    domain = "enrollment"
  ))

  expect_true(site$is_site_source_failure(value))
  row <- site$.build_manifest$rows
  expect_false(row$completed)
  expect_identical(row$source_status, "parse_error")
  expect_match(row$error, "failed after source retrieval.*unexpected statewide schema")
  expect_error(site$assert_required_coverage(FALSE), "enrollment/2025.*parse_error")
})

test_that("bundle filenames accept only canonical district identifiers", {
  site <- load_site_build_helpers()
  expect_identical(site$safe_bundle_id("4900"), "4900")
  expect_error(site$safe_bundle_id("../../4900"), "Unsafe district identifier")
  expect_error(site$safe_bundle_id("4900.yml"), "Unsafe district identifier")
})

test_that("discovery builds are strict and manifest-backed", {
  source <- paste(readLines(
    package_source_path("site", "discovery-build.R"), warn = FALSE
  ), collapse = "\n")

  expect_match(source, "--allow-partial", fixed = TRUE)
  expect_match(source, "discovery-build-manifest[.]json")
  expect_match(source, "new_source_result")
  expect_match(source, "if [(]sys[.]nframe[(][)] == 0L[)]")
  expect_false(grepl("error\\s*=\\s*function\\s*\\([^)]*\\)\\s*\\{?[^}]*NULL",
                     source, perl = TRUE))
})

test_that("discovery year failures are explicit and strict caches are not written", {
  discovery <- load_discovery_build_helpers()
  value <- suppressWarnings(discovery$cache_or_build(
    "contract",
    function() discovery$years_bind(
      2024:2025,
      function(year) {
        if (year == 2025) stop("HTTP 503")
        data.frame(end_year = year, value = 1)
      },
      "contract"
    ),
    refresh = TRUE,
    allow_partial = FALSE
  ))

  expect_true(discovery$is_discovery_failure(value))
  expect_false(file.exists(discovery$sw_path("contract")))
  expect_identical(
    discovery$.discovery_manifest$rows$source_status,
    c("actual", "source_unavailable")
  )
  expect_error(
    discovery$assert_discovery_coverage(FALSE),
    "contract/2025.*source_unavailable"
  )
})

test_that("partial discovery caches require opt-in and retain provenance", {
  discovery <- load_discovery_build_helpers()
  value <- suppressWarnings(discovery$cache_or_build(
    "contract",
    function() discovery$years_bind(
      2024:2025,
      function(year) {
        if (year == 2025) stop("schema changed")
        data.frame(end_year = year, value = 1)
      },
      "contract"
    ),
    refresh = TRUE,
    allow_partial = TRUE
  ))

  expect_s3_class(value, "data.frame")
  expect_true(file.exists(discovery$sw_path("contract")))
  expect_identical(
    attr(value, discovery$DISCOVERY_MANIFEST_ATTR)$source_status,
    c("actual", "source_unavailable")
  )
  expect_false(discovery$assert_discovery_coverage(TRUE))
  manifest <- jsonlite::fromJSON(discovery$DISCOVERY_MANIFEST_PATH)
  expect_true(manifest$allow_partial)
})

test_that("discovery rejects malformed cached provenance", {
  discovery <- load_discovery_build_helpers()
  value <- data.frame(end_year = 2025L)
  attr(value, discovery$DISCOVERY_MANIFEST_ATTR) <- data.frame(
    domain = "contract", completed = TRUE
  )
  saveRDS(value, discovery$sw_path("contract"))

  restored <- discovery$cache_or_build(
    "contract", function() stop("cache should have been reused")
  )
  expect_true(discovery$is_discovery_failure(restored))
  expect_identical(
    discovery$.discovery_manifest$rows$source_status,
    "source_unavailable"
  )
})

test_that("empty discovery categories are parser failures", {
  discovery <- load_discovery_build_helpers()
  value <- discovery$cache_or_build(
    "contract", function() data.frame(), refresh = TRUE,
    allow_partial = FALSE
  )

  expect_true(discovery$is_discovery_failure(value))
  expect_false(file.exists(discovery$sw_path("contract")))
  expect_identical(
    discovery$.discovery_manifest$rows$source_status,
    "parse_error"
  )
})

test_that("post-filter empty discovery aggregates cannot pass on slice success", {
  discovery <- load_discovery_build_helpers()
  value <- discovery$cache_or_build(
    "contract",
    function() {
      discovery$years_bind(
        2024:2025,
        function(year) data.frame(end_year = year, is_district = FALSE),
        "contract"
      ) |>
        dplyr::filter(is_district)
    },
    refresh = TRUE,
    allow_partial = FALSE
  )

  expect_true(discovery$is_discovery_failure(value))
  expect_false(file.exists(discovery$sw_path("contract")))
  expect_identical(
    tail(discovery$.discovery_manifest$rows$source_status, 1),
    "parse_error"
  )
})

test_that("post-filter empty statewide aggregates cannot be cached", {
  site <- load_site_build_helpers()
  site$SW_DIR <- tempfile("site-statewide-")
  dir.create(site$SW_DIR, recursive = TRUE)
  site$manifest_request("enrollment", 2025)

  value <- suppressWarnings(site$cache_or_build(
    "enrollment-contract",
    function() {
      site$manifest_record("enrollment", 2025, status = "actual")
      data.frame()
    },
    refresh = TRUE,
    records_inside = TRUE,
    domain = "enrollment"
  ))

  expect_true(site$is_site_source_failure(value))
  expect_false(file.exists(site$sw_path("enrollment-contract")))
  aggregate <- tail(site$.build_manifest$rows, 1)
  expect_identical(aggregate$source_status, "parse_error")
  expect_false(aggregate$completed)
})

profile_retained_fixture <- function() {
  readRDS(package_source_path('inst','extdata','test-fixtures','profile-sections','retained-spr.rds'))
}

profile_fixture_statewide <- function(site) {
  original <- profile_retained_fixture()
  sw <- list(njsla=dplyr::bind_rows(original[grepl('^(njsla|math)_',names(original))]))
  for (name in c('discipline','hib','police','teacher_exp','staff_retention','staff_demo')) {
    sw[[name]] <- dplyr::bind_rows(lapply(2022:2025,function(y) {
      site$profile_spr_year(original[[paste(name,y,sep='_')]],y,name)
    }))
  }
  sw
}

test_that('new required profile sources cannot silently disappear', {
  site <- load_site_build_helpers()
  site$register_build_requests()
  required <- c('njsla','discipline','hib','police','teacher_exp','staff_retention','staff_demo')
  expect_true(all(required %in% site$.build_manifest$rows$domain))
  expect_true(all(site$.build_manifest$rows$required[site$.build_manifest$rows$domain %in% required]))
  site$manifest_record('discipline',2025,status='parse_error',error='source read failed')
  expect_error(site$assert_required_coverage(FALSE),'discipline/2025.*parse_error')
})

test_that('source-token numeric conversion preserves suppression and sub-one-percent values', {
  site <- load_site_build_helpers()
  expect_equal(site$spr_pct_numeric(c('63.2%','2,959','*','N','','0%','0.71%')),
               c(63.2,2959,NA,NA,NA,0,0.71))
  env <- new.env()
  sys.source(package_source_path('site','R','bundle.R'),env)
  expect_equal(env$as_pct_scale(c(0.71,0,NA)),c(0.71,0,NA))
  expect_equal(env$as_pct_scale(c(.005,NA),multiplier=100),c(.5,NA))
  expect_equal(env$fmt_int(32098.5),"32,098.5")
})

test_that('retained district SPR rows keep exact grade rates, years and unavailable counts', {
  site <- load_site_build_helpers()
  sw <- profile_fixture_statewide(site)
  b <- site$profile_deeper_sections(sw,'3570',c('3570','4900'))
  own <- b$njsla_latest %>% dplyr::filter(series=='District',subject=='ELA',grade_test=='Grade 3')
  expect_equal(own$end_year,2025)
  expect_equal(own$proficiency_rate,27.6)
  expect_true(is.na(own$valid_scores))
  expect_equal(b$teacher_exp$teacher_avg_years_exp_district,9.6)
  expect_equal(b$teacher_exp$percentage_of_out_of_field_teachers,4.4)
  expect_equal(b$police$violence,7)
  expect_equal(b$police$hib,13)
  expect_true(any(is.na(b$hib$hib_confirmed)))
  # Every historical row stays in its own request year; 2024 long-form
  # names are normalized without inventing a subgroup or rescaling rates.
  source <- profile_retained_fixture()$discipline_2024
  source <- source[source$district_id=='3570' & source$student_group_grade=='Districtwide',]
  row <- b$discipline[b$discipline$end_year==2024 & b$discipline$profile_district_total %in% TRUE,]
  expect_equal(row$any_susp_pct,site$spr_pct_numeric(source$percent_students_any_suspension))
  expect_equal(sort(unique(b$discipline$end_year)),2022:2025)
  expect_equal(b$discipline$any_susp_pct[b$discipline$end_year==2025 & b$discipline$profile_district_total],.95)
  expect_error(site$profile_deeper_sections(replace(sw,'njsla',list(dplyr::bind_rows(sw$njsla,sw$njsla[1,]))),'3570',character()),'Duplicate profile')
})

test_that('paired gaps preserve independently missing sides and discontinuous years', {
  site <- load_site_build_helpers()
  sw <- profile_fixture_statewide(site)
  b <- site$profile_assessment(sw$njsla,'3570',character())
  expect_equal(b$njsla_gaps$gap,b$njsla_gaps$rate_a-b$njsla_gaps$rate_b)
  g <- b$njsla_gaps
  expect_true(any(!is.finite(g$gap)))
  d <- sw$njsla[sw$njsla$end_year!=2023,]
  z <- site$profile_assessment(d,'3570',character())$njsla_trend
  expect_true(all(z$segment[z$end_year==2024]>z$segment[z$end_year==2022]))
  expect_identical(site$profile_deeper_sections(sw,'1234',character()),list())
})

test_that('actual suppressed rows and absent domains render notices without charts', {
  site <- load_site_build_helpers()
  sw <- profile_fixture_statewide(site)
  source_gaps <- site$profile_assessment(sw$njsla,'3570',character())$njsla_gaps
  source_gaps <- source_gaps[!is.finite(source_gaps$gap),]
  expect_gt(nrow(source_gaps),0)
  env <- new.env(parent=globalenv())
  sys.source(package_source_path('site','R','bundle.R'),env)
  env$b <- list(njsla_latest=NULL,njsla_gaps=source_gaps,discipline=NULL)
  env$chart_grade_proficiency <- env$chart_gap <- function(...) stop('Chart must not run')
  lines <- readLines(package_source_path('site','_district-body.qmd'),warn=FALSE)
  chunk <- function(name) {
    start <- which(startsWith(lines,paste0('```{r ',name,',')))
    finish <- which(seq_along(lines)>start & lines=='```')[1]
    parse(text=lines[seq.int(start+1,finish-1)])
  }
  expect_match(paste(capture.output(eval(chunk('njsla-latest'),env)),collapse=' '),'not available')
  expect_match(paste(capture.output(eval(chunk('njsla-gaps'),env)),collapse=' '),'Not enough unsuppressed data')
  expect_match(paste(capture.output(eval(chunk('discipline'),env)),collapse=' '),'not available')
})

profile_template_chunk <- function(name) {
  lines <- readLines(package_source_path('site', '_district-body.qmd'), warn = FALSE)
  start <- which(startsWith(lines, paste0('```{r ', name, ',')))
  finish <- which(seq_along(lines) > start & lines == '```')[1]
  parse(text = lines[seq.int(start + 1, finish - 1)])
}

test_that('a genuine total-only assessment slice omits unavailable paired gaps', {
  site <- load_site_build_helpers()
  sw <- profile_fixture_statewide(site)
  totals <- sw$njsla[tolower(sw$njsla$subgroup) == 'total population', ]
  b <- site$profile_assessment(totals, '3570', character())
  expect_gt(nrow(b$njsla_latest), 0)
  expect_null(b$njsla_gaps)
})

test_that('both suspension measures retain source rates and same-year peer medians in the chart', {
  site <- load_site_build_helpers()
  sw <- profile_fixture_statewide(site)
  b <- site$profile_deeper_sections(sw, '3570', c('0010', '4900'))
  env <- new.env(parent = globalenv())
  sys.source(package_source_path('site', 'R', 'bundle.R'), env)
  sys.source(package_source_path('site', 'R', 'theme.R'), env)
  env$b <- b
  env$kable <- knitr::kable
  env$label_number <- scales::label_number
  printed <- list()
  env$print <- function(x, ...) printed[[length(printed) + 1L]] <<- x
  capture.output(eval(profile_template_chunk('discipline'), env))
  plot <- printed[[length(printed)]]
  expect_s3_class(plot, 'ggplot')
  expect_setequal(unique(plot$data$metric), c('any_susp_pct', 'outof_school_pct'))
  own <- plot$data[plot$data$series == 'District', ]
  for (metric in c('any_susp_pct', 'outof_school_pct')) {
    source <- b$discipline[b$discipline$profile_district_total %in% TRUE, ]
    actual <- own[own$metric == metric, ]
    expect_equal(actual$value, source[[metric]][match(actual$end_year, source$end_year)])
    peer <- plot$data[plot$data$series == 'Peer median' & plot$data$metric == metric, ]
    expect_gt(nrow(peer), 0)
    expect_equal(peer$value, b$discipline_peer[[metric]][match(peer$end_year, b$discipline_peer$end_year)])
  }
  expect_match(paste(printed[[1]], collapse = '\n'), 'outof_school_pct')
})

test_that('missing discipline years break both district and peer chart lines', {
  site <- load_site_build_helpers()
  sw <- profile_fixture_statewide(site)
  sw$discipline <- sw$discipline[sw$discipline$end_year != 2023, ]
  b <- site$profile_deeper_sections(sw, '3570', c('0010', '4900'))
  env <- new.env(parent = globalenv())
  sys.source(package_source_path('site', 'R', 'bundle.R'), env)
  sys.source(package_source_path('site', 'R', 'theme.R'), env)
  env$b <- b
  env$kable <- knitr::kable
  env$label_number <- scales::label_number
  plot <- NULL
  env$print <- function(x, ...) if (inherits(x, 'ggplot')) plot <<- x
  capture.output(eval(profile_template_chunk('discipline'), env))
  d <- plot$data
  expect_gt(nrow(d), 0)
  for (series in c('District', 'Peer median')) for (metric in c('any_susp_pct', 'outof_school_pct')) {
    z <- d[d$series == series & d$metric == metric, ]
    expect_gt(z$segment[z$end_year == 2024], z$segment[z$end_year == 2022])
  }
})

test_that('an independently unavailable HIB confirmed count retains its published investigation total', {
  site <- load_site_build_helpers()
  b <- site$profile_deeper_sections(profile_fixture_statewide(site), '3570', character())
  b$hib <- b$hib[is.na(b$hib$hib_confirmed) & is.finite(b$hib$total_hib_investigations), ]
  expect_gt(nrow(b$hib), 0)
  env <- new.env(parent = globalenv())
  sys.source(package_source_path('site', 'R', 'bundle.R'), env)
  env$b <- b
  env$kable <- knitr::kable
  printed <- NULL
  env$print <- function(x, ...) printed <<- x
  out <- capture.output(eval(profile_template_chunk('hib'), env))
  expect_false(any(grepl('not available', out)))
  expect_s3_class(printed, 'knitr_kable')
  expect_match(paste(printed, collapse = '\n'), 'No Identified Nature')
  expect_match(paste(printed, collapse = '\n'), as.character(b$hib$total_hib_investigations))
  expect_true(all(is.na(b$hib$hib_confirmed)))
})
