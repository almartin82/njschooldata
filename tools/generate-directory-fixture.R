#!/usr/bin/env Rscript

# Regenerate the minimal Homeroom directory fixture from a previously retrieved
# statewide directory bundle. Values are copied from the state-derived bundle;
# fields that were not retained by the bundle are left blank, never invented.

args <- commandArgs(trailingOnly = TRUE)
repo <- normalizePath(if (length(args)) args[[1]] else ".", mustWork = TRUE)
source_path <- file.path(repo, "site", "_bundles", "_statewide", "directory.rds")
fixture_dir <- file.path(
  repo, "inst", "extdata", "test-fixtures", "source-adapters"
)
dir.create(fixture_dir, recursive = TRUE, showWarnings = FALSE)

directory <- readRDS(source_path)
district <- directory[directory$entity_type == "district", , drop = FALSE][1, ]

raw <- data.frame(
  `County Code` = district$county_id,
  `County Name` = district$county_name,
  `District Code` = district$district_id,
  `District Name` = district$district_name,
  `Supt Title` = district$superintendent_title,
  `Supt First Name` = district$superintendent_first_name,
  `Supt Last Name` = district$superintendent_last_name,
  `Supt Title 2` = district$superintendent_role,
  `Supt E Mail` = district$superintendent_email,
  `BA First Name` = NA_character_,
  `BA Last Name` = NA_character_,
  `BA Email` = district$ba_email,
  `BA Title2` = district$ba_role,
  Address1 = district$address,
  Address2 = district$address2,
  City = district$city,
  State = district$state,
  Zip = district$zip,
  `Mailing Address1` = district$mailing_address,
  `Mailing Address2` = district$mailing_address2,
  `Mailing Address3` = district$mailing_address3,
  `Mailing City` = district$mailing_city,
  `Mailing State` = district$mailing_state,
  `Mailing Zip` = district$mailing_zip,
  Phone = district$phone,
  Website = district$website,
  `HIB First Name` = NA_character_,
  `HIB Last Name` = NA_character_,
  `HIB Title2` = district$hib_role,
  `State Testing Coor First Name` = NA_character_,
  `State Testing Coor Last Name` = NA_character_,
  `School Safety Specialist First Name` = NA_character_,
  `School Safety Specialist Last Name` = NA_character_,
  `Chrt Sch Code` = district$charter_school_code,
  `NCES ID` = district$nces_id,
  check.names = FALSE
)

fixture_path <- file.path(fixture_dir, "directory-district.csv")
writeLines(
  c(
    "NJDOE Homeroom district directory adapter fixture",
    "Minimal rows retained for deterministic parser tests",
    "See provenance.json"
  ),
  fixture_path
)
utils::write.table(
  raw, fixture_path, sep = ",", row.names = FALSE, col.names = TRUE,
  quote = TRUE, na = "", append = TRUE
)

digest_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}
provenance_path <- file.path(fixture_dir, "provenance.json")
provenance <- jsonlite::fromJSON(provenance_path, simplifyVector = FALSE)
provenance$directory <- list(
  source_url = "https://homeroom5.doe.nj.gov/directory/districtDL.php",
  source_sha256 = digest_file(source_path),
  fixture = basename(fixture_path),
  fixture_sha256 = digest_file(fixture_path),
  retrieval = "state-derived statewide directory bundle",
  extraction = "one observed district row; unretained raw fields left blank"
)
jsonlite::write_json(
  provenance, provenance_path, pretty = TRUE, auto_unbox = TRUE
)
