#!/usr/bin/env Rscript
# =============================================================================
# render-all.R — generate one profiles/{id}.qmd stub per built bundle.
# Each stub sets district_id and includes the shared _district-body.qmd, so
# Quarto produces one static HTML page per district with a proper title + nav.
#
# Usage (run from repo root):
#   Rscript site/render-all.R            # stubs for every bundle in site/_bundles
#   Rscript site/render-all.R 4900 3570  # stubs for specific ids
# Then render with:  cd site && quarto render
# =============================================================================
suppressMessages({ library(dplyr) })

SITE_DIR    <- "site"
BUNDLE_DIR  <- file.path(SITE_DIR, "_bundles")
PROFILE_DIR <- file.path(SITE_DIR, "profiles")
dir.create(PROFILE_DIR, showWarnings = FALSE)

dir_all <- readRDS(file.path(BUNDLE_DIR, "_statewide", "directory.rds"))
name_for <- function(id) {
  nm <- dir_all$district_name[match(id, dir_all$district_id)]
  if (is.na(nm)) id else nm
}
# escape double quotes for YAML title
yaml_q <- function(s) gsub('"', "'", s, fixed = TRUE)

args <- commandArgs(trailingOnly = TRUE)
ids <- if (length(args)) args else {
  f <- list.files(BUNDLE_DIR, pattern = "^[0-9A-Za-z]+\\.rds$", full.names = FALSE)
  sub("\\.rds$", "", f)
}

stub <- function(id) {
  sprintf(
'---
title: "%s"
subtitle: "New Jersey district profile"
---

```{r}
#| include: false
district_id <- "%s"
```

{{< include ../_district-body.qmd >}}
', yaml_q(name_for(id)), id)
}

n <- 0
for (id in ids) {
  writeLines(stub(id), file.path(PROFILE_DIR, paste0(id, ".qmd")))
  n <- n + 1
}
cat(sprintf("wrote %d profile stubs to %s\n", n, PROFILE_DIR))
