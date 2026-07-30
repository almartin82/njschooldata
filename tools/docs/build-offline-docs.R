#!/usr/bin/env Rscript

if (!identical(tolower(Sys.getenv("NJSCHOOLDATA_LIVE_TESTS", "false")), "false")) {
  stop("Offline documentation requires NJSCHOOLDATA_LIVE_TESTS=false.")
}

package_root <- normalizePath(".", mustWork = TRUE)
description <- read.dcf(file.path(package_root, "DESCRIPTION"))
stopifnot(
  identical(unname(description[1, "Package"]), "njschooldata"),
  identical(normalizePath(getwd(), mustWork = TRUE), package_root)
)
tool_root <- file.path(package_root, "tools", "docs")
python <- Sys.which("python3")
stopifnot(nzchar(python))

seed_output <- system2(
  python,
  c(
    file.path(tool_root, "seed-pkgdown-cache.py"),
    "--manifest", file.path(tool_root, "pkgdown-dependencies.json"),
    "--asset-root", file.path(tool_root, "pkgdown-cache"),
    "--cache-root", tools::R_user_dir("pkgdown", "cache")
  ),
  stdout = TRUE,
  stderr = TRUE
)
cat(seed_output, sep = "\n")
seed_status <- attr(seed_output, "status")
stopifnot(
  is.null(seed_status) || identical(seed_status, 0L),
  any(seed_output == "pkgdown-dependency-cache-seeded=7")
)

pkgdown::init_site()
pkgdown::build_home(preview = FALSE)
pkgdown::build_reference(
  lazy = FALSE,
  examples = FALSE,
  preview = FALSE,
  devel = FALSE
)

required <- c(
  file.path("docs", "index.html"),
  file.path("docs", "reference", "index.html")
)
reference_pages <- setdiff(
  list.files(
    file.path("docs", "reference"),
    pattern = "\\.html$",
    full.names = TRUE
  ),
  file.path("docs", "reference", "index.html")
)
stopifnot(
  all(file.exists(required)),
  all(file.info(required)$size > 0),
  length(reference_pages) > 0L,
  all(file.info(reference_pages)$size > 0)
)
cat(
  "nj-offline-docs=passed dependencies=7 home=1 reference_index=1 ",
  "reference_pages=", length(reference_pages), "\n",
  sep = ""
)
