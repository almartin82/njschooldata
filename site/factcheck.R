#!/usr/bin/env Rscript
# factcheck.R — sanity-scan each district's stories against its discovery doc.
# Extracts distinctive numeric tokens (percentages, $ amounts, multi-digit counts)
# from each story's narrative + key_numbers and checks they appear in the discovery
# .md (the real-data substrate). Computed/derived numbers (e.g. a "13-point gap")
# won't always match verbatim, so this is a scan to surface likely hallucinations,
# not a hard gate. Flags stories with the most unmatched numbers for review.
#   Rscript site/factcheck.R 4900 3570 ...   (default: all in _almanac_sample.txt)
suppressMessages(library(jsonlite))

norm <- function(s) gsub(",", "", s)
# distinctive numbers: percentages, dollars, or numbers with >=3 digits or a decimal
extract_nums <- function(txt) {
  txt <- norm(paste(txt, collapse = " "))
  m <- regmatches(txt, gregexpr("\\$?[0-9]+(\\.[0-9]+)?%?", txt))[[1]]
  m <- m[grepl("[.%$]", m) | nchar(gsub("[^0-9]", "", m)) >= 3]   # drop bare 1-2 digit ints
  unique(m)
}

ids <- commandArgs(trailingOnly = TRUE)
if (!length(ids)) ids <- strsplit(readLines("site/_almanac_sample.txt"), " ")[[1]]

total_unmatched <- 0; total_nums <- 0
for (id in ids) {
  sf <- sprintf("site/_stories/%s.json", id); df <- sprintf("site/_discovery/%s.md", id)
  if (!file.exists(sf) || !file.exists(df)) { cat(id, ": missing files\n"); next }
  doc <- norm(paste(readLines(df, warn = FALSE), collapse = " "))
  stories <- fromJSON(sf, simplifyDataFrame = FALSE)
  dist_unmatched <- 0; dist_nums <- 0; flags <- character(0)
  for (s in stories) {
    nums <- extract_nums(c(s$headline, s$narrative_md, unlist(s$key_numbers)))
    miss <- nums[!vapply(nums, function(n) grepl(n, doc, fixed = TRUE), logical(1))]
    dist_nums <- dist_nums + length(nums); dist_unmatched <- dist_unmatched + length(miss)
    if (length(miss) >= 3) flags <- c(flags, sprintf('  [#%s] "%s" — unmatched: %s',
        s$rank, substr(s$headline, 1, 60), paste(miss, collapse = ", ")))
  }
  total_unmatched <- total_unmatched + dist_unmatched; total_nums <- total_nums + dist_nums
  cat(sprintf("%s: %d stories, %d/%d numbers matched the discovery doc%s\n",
      id, length(stories), dist_nums - dist_unmatched, dist_nums,
      if (length(flags)) " — REVIEW:" else ""))
  if (length(flags)) cat(paste(flags, collapse = "\n"), "\n")
}
cat(sprintf("\nTOTAL: %d/%d numbers matched (%.0f%%). Unmatched are often derived (gaps/changes); review high-flag stories.\n",
    total_nums - total_unmatched, total_nums, 100*(total_nums-total_unmatched)/max(total_nums,1)))
