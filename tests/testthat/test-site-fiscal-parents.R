# Real retained DOE parents, no network or generated observations.
nj287_site <- function() {
  script <- package_source_path('site', 'build-data.R')
  withr::local_dir(tempdir())
  env <- new.env(parent = globalenv())
  sys.source(script, env)
  env
}

nj287_fiscal <- function() {
  root <- system.file('extdata', 'test-fixtures', 'profile-sections', package='njschooldata')
  provenance <- jsonlite::read_json(file.path(root,'fiscal-provenance.json'))
  for (a in provenance) {
    p <- file.path(root,a$file)
    stopifnot(file.info(p)$size == a$bytes,
      digest::digest(file=p,algo='sha256',serialize=FALSE) == a$sha256)
  }
  raw <- readr::read_csv(file.path(root,'VITSTAT_TOTAL-2025.csv'),show_col_types=FALSE) %>%
    janitor::clean_names() %>% clean_cds_fields(tges=TRUE) %>% cds_codes_to_ids()
  raw$district_id <- pad_leading(raw$district_id,4)
  aid <- .parse_state_aid_workbook(file.path(root,'FY27_GBM_District_Details.xlsx'),2027)
  local_mocked_bindings(
    get_raw_tges_result=function(...) new_source_result(data=list(VITSTAT_TOTAL=raw),source_status='actual'),
    get_raw_state_aid_result=function(...) new_source_result(data=aid,source_status='actual'),
    .package='njschooldata')
  list(tges_revenue=tges_revenue_mix(fetch_tges(2025)) %>%
    dplyr::select(district_id,district_name,end_year,dplyr::ends_with('_share')),
    aid=fetch_state_aid(2027),sped=fetch_sped(2025))
}

nj287_chunk <- function(name) {
  lines <- readLines(package_source_path('site','_district-body.qmd'))
  start <- which(startsWith(lines,paste0('```{r ',name,',')))
  finish <- which(seq_along(lines)>start & lines=='```')[1]
  parse(text=lines[seq.int(start+1,finish-1)])
}

test_that('verified fiscal parents reach profiles with exact native values and dates', {
  local_nj_offline_transport()
  sw <- nj287_fiscal()
  site <- nj287_site()
  b <- site$profile_deeper_sections(sw,'3570',character())
  expect_equal(nrow(sw$tges_revenue),659)
  expect_equal(nrow(sw$aid),6912)
  expect_equal(as.integer(table(sw$aid$is_aid_category)),c(2304L,4608L))
  expect_equal(nrow(sw$sped),656)
  expect_equal(b$tges_revenue$end_year,2024)
  expect_equal(b$tges_revenue$state_share,.801)
  expect_equal(b$tges_revenue$local_share,.096)
  expect_equal(b$tges_revenue$federal_share,.1)
  expect_equal(nrow(b$aid_categories),8)
  expect_true(all(b$aid_categories$end_year==2027))
  expect_true(all(b$aid_categories$is_aid_category))
  expect_equal(b$aid_categories$amount[b$aid_categories$aid_category=='equalization_aid'],1261166058)
  expect_equal(b$aid_categories$amount[b$aid_categories$aid_category=='special_education_aid'],74826421)
  expect_equal(b$sped$sped_num,6795)
  expect_equal(b$sped$gened_num,44264)
  expect_equal(b$sped$sped_rate,15.35)
  site$.build_manifest$rows <- site$.build_manifest$rows[0,]
  site$register_build_requests()
  rows <- site$.build_manifest$rows
  expect_equal(rows$end_year[rows$domain=='tges_revenue'],2025)
  expect_equal(rows$end_year[rows$domain=='sped'],2025)
  expect_equal(site$AID_YEARS,2027L)
})

test_that('fiscal sections print source tables and populated charts with honest absence guards', {
  local_nj_offline_transport()
  site <- nj287_site()
  sw <- nj287_fiscal()
  env <- new.env(parent=globalenv())
  for (name in c('bundle.R','theme.R','security.R')) sys.source(package_source_path('site','R',name),env)
  env$b <- site$profile_deeper_sections(sw,'3570',character())
  env$m <- list(is_charter=FALSE)
  env$kable <- knitr::kable
  env$label_percent <- scales::label_percent
  env$label_dollar <- scales::label_dollar
  printed <- list()
  env$print <- function(x,...) printed[[length(printed)+1L]] <<- x
  for (chunk in c('tges-revenue','aid-categories','sped-classification')) {
    printed <- list()
    capture.output(eval(nj287_chunk(chunk),env))
    expect_s3_class(printed[[1]],'knitr_kable')
    if (chunk != 'sped-classification') {
      expect_s3_class(printed[[2]],'ggplot')
      expect_gt(nrow(ggplot2::ggplot_build(printed[[2]])$data[[1]]),0)
    }
  }
  env$b <- list()
  for (chunk in c('tges-revenue','aid-categories','sped-classification')) {
    printed <- list()
    out <- capture.output(eval(nj287_chunk(chunk),env))
    expect_match(paste(out,collapse=' '),'not available')
    expect_length(printed,0)
  }
  env$b <- site$profile_deeper_sections(sw,'3570',character())
  env$m$is_charter <- TRUE
  printed <- list()
  expect_match(paste(capture.output(eval(nj287_chunk('tges-revenue'),env)),collapse=' '),'not available')
  expect_length(printed,0)
})

test_that('profiles use numeric comparisons without code-written interpretive sentences', {
  local_nj_offline_transport()
  for (chunk in c('spend-peer','grad-peer')) {
    code <- paste(deparse(nj287_chunk(chunk)),collapse=' ')
    expect_match(code,'kable',fixed=TRUE)
    expect_false(grepl('peer_phrase|sprintf|glue|paste',code))
  }
  template <- paste(readLines(package_source_path('site','_district-body.qmd')),collapse='\n')
  expect_match(template,'tges_revenue_mix(fetch_tges(2025))',fixed=TRUE)
  expect_match(template,'sped="fetch_sped"',fixed=TRUE)
  expect_match(template,'School Year 2023-24',fixed=TRUE)
  expect_false(grepl('tidy = FALSE',template,fixed=TRUE))
})


test_that('normalized 2022 discipline totals retain the published Newark suspension counts', {
  local_nj_offline_transport()
  site <- nj287_site()
  d <- readRDS(package_source_path('inst','extdata','test-fixtures','profile-sections','retained-spr.rds'))$discipline_2022
  # Current fetchers retain a compatibility column for this dimensionless sheet.
  d$student_group_grade <- NA_character_
  sw <- list(discipline=site$profile_spr_year(d,2022,'discipline'))
  b <- site$profile_deeper_sections(sw,'3570',character())
  expect_true(b$discipline$profile_district_total)
  expect_equal(b$discipline$end_year,2022)
  expect_equal(b$discipline$any_susp_count,878)
  expect_equal(b$discipline$any_susp_pct,2.1)
  expect_equal(b$discipline$outof_school_count,730)
})
