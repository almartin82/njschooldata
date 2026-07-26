load_site_security <- function() {
  env <- new.env(parent = globalenv())
  sys.source(package_source_path("site", "R", "security.R"),
             envir = env)
  env
}

test_that("source-provided markup is rendered as text", {
  security <- load_site_security()
  name <- '<script>alert("owned")</script> District'
  rendered <- sprintf('<a href="4900.html">%s</a>', security$html_escape(name))

  expect_false(grepl("<script", rendered, fixed = TRUE))
  expect_match(rendered, "&lt;script&gt;", fixed = TRUE)
  expect_match(rendered, "&quot;owned&quot;", fixed = TRUE)
})

test_that("website URLs and generated filenames use narrow allowlists", {
  security <- load_site_security()
  expect_identical(
    security$safe_http_url("https://district.example/schools"),
    "https://district.example/schools"
  )
  expect_true(is.na(security$safe_http_url("javascript:alert(1)")))
  expect_true(is.na(security$safe_http_url("data:text/html,<script>")))
  expect_error(security$safe_profile_id("../../escaped"), "Unsafe")
  expect_identical(security$safe_profile_href("4900"), "4900.html")
})

test_that("YAML titles are encoded as a single scalar", {
  security <- load_site_security()
  title <- security$yaml_scalar("District\nunsafe: true")
  expect_identical(length(title), 1L)
  expect_match(title, "\\\\n")
  expect_true(startsWith(title, '"') && endsWith(title, '"'))
})

test_that("escape FALSE is used only after source display fields are escaped", {
  index <- readLines(
    package_source_path("site", "index.qmd"), warn = FALSE
  )
  expect_true(any(grepl("datatable[(]disp, escape = FALSE", index)))
  expect_true(any(grepl("html_escape[(]district_name[)]", index)))
  expect_true(any(grepl("County = html_escape[(]county[)]", index)))

  almanac <- readLines(
    package_source_path("site", "_almanac-body.qmd"), warn = FALSE
  )
  intro <- grep("things the data says about", almanac, fixed = TRUE)
  expect_length(intro, 1L)
  expect_true(any(grepl(
    "html_escape[(]m[$]district_name[)]",
    almanac[seq.int(intro, min(length(almanac), intro + 2L))]
  )))
  expect_true(any(grepl(
    "html_escape[(]s[$]narrative_md[)]", almanac
  )))
})

test_that("story markdown cannot inject raw HTML", {
  security <- load_site_security()
  narrative <- 'Finding: **important** <img src=x onerror="alert(1)">'
  rendered <- security$html_escape(narrative)

  expect_match(rendered, "**important**", fixed = TRUE)
  expect_false(grepl("<img", rendered, fixed = TRUE))
  expect_match(rendered, "&lt;img", fixed = TRUE)
})

test_that("discovery markdown escapes source markup and validates filenames", {
  root <- package_source_path()
  withr::local_dir(root)
  discovery <- new.env(parent = globalenv())
  sys.source(file.path(root, "site", "discovery-doc.R"), envir = discovery)

  rendered <- discovery$md_table(data.frame(
    district_name = '<script>alert("owned")</script>|District'
  ))
  expect_false(grepl("<script", rendered, fixed = TRUE))
  expect_match(rendered, "&lt;script&gt;", fixed = TRUE)
  expect_match(rendered, "&#124;", fixed = TRUE)
  expect_error(discovery$build_discovery("../../4900"), "Unsafe district")
})
