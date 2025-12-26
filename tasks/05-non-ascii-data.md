# Task 05: Fix Non-ASCII Data (WARNING)

## Problem Summary

R CMD check found non-ASCII characters in data objects. Specifically, an ellipsis character (`…`) encoded as `<85>` (Windows-1252 encoding) appears in several layout data files.

## Affected Objects

All of these are fixed-width file layout specifications:

1. `layout_gepa` - `data/gepa_layout.rda`
2. `layout_gepa05` - `data/gepa05_layout.rda`
3. `layout_hspa` - `data/hspa_layout.rda`
4. `layout_hspa04` - `data/hspa04_layout.rda`
5. `layout_hspa05` - `data/hspa05_layout.rda`
6. `layout_hspa06` - `data/hspa06_layout.rda`
7. `layout_hspa10` - `data/hspa10_layout.rda`
8. `layout_njask04` - `data/njask04_layout.rda`
9. `layout_njask05` - `data/njask05_layout.rda`
10. `layout_njask06gr3` - `data/njask06gr3_layout.rda`
11. `layout_njask06gr5` - `data/njask06gr5_layout.rda`
12. `layout_njask07gr3` - `data/njask07gr3_layout.rda`
13. `layout_njask07gr5` - `data/njask07gr5_layout.rda`

## Root Cause

The layout data likely contains column names or descriptions with an ellipsis character (`…`) that was entered in Windows encoding. Common scenarios:

- Column name like `"Proficient..."` or `"Level 1...Level 5"`
- Description text with `"etc..."` or similar

## Solution

### Option 1: Replace with ASCII equivalent (Recommended)

Replace the non-ASCII ellipsis `…` (U+2026 or `<85>`) with three ASCII periods `...`.

```r
# For each affected data file:
load("data/gepa_layout.rda")

# Check which columns contain the problematic character
for (col in names(layout_gepa)) {
  if (any(grepl("\u2026|\x85", layout_gepa[[col]]))) {
    print(paste("Found in column:", col))
  }
}

# Replace the character
layout_gepa <- layout_gepa %>%
  mutate(across(where(is.character), ~gsub("\u2026|\x85", "...", .)))

# Save back
save(layout_gepa, file = "data/gepa_layout.rda")
```

### Option 2: Convert to UTF-8

Ensure all strings are proper UTF-8:

```r
layout_gepa <- layout_gepa %>%
  mutate(across(where(is.character), ~iconv(., to = "UTF-8")))
```

## Implementation Script

Create a script to fix all affected files:

```r
# fix_non_ascii.R

fix_non_ascii <- function(obj) {
  if (is.data.frame(obj)) {
    obj %>%
      mutate(across(where(is.character), ~gsub("\u2026|\x85", "...", .)))
  } else if (is.character(obj)) {
    gsub("\u2026|\x85", "...", obj)
  } else {
    obj
  }
}

layout_files <- c(
  "gepa_layout", "gepa05_layout", "gepa06_layout",
  "hspa_layout", "hspa04_layout", "hspa05_layout",
  "hspa06_layout", "hspa10_layout",
  "njask04_layout", "njask05_layout",
  "njask06gr3_layout", "njask06gr5_layout",
  "njask07gr3_layout", "njask07gr5_layout"
)

for (layout_name in layout_files) {
  file_path <- paste0("data/", layout_name, ".rda")
  if (file.exists(file_path)) {
    load(file_path)
    obj <- get(layout_name)
    obj <- fix_non_ascii(obj)
    assign(layout_name, obj)
    save(list = layout_name, file = file_path)
    message("Fixed: ", layout_name)
  }
}
```

## Files to Modify

All `.rda` files in `data/` directory that contain layout specifications.

## Verification

```r
devtools::check()
# Should not show "found non-ASCII string" warnings

# Or check manually:
tools::checkRdaFiles("data/")
```

## Notes

- The `<85>` encoding suggests the data was originally created on Windows
- Using ASCII `...` is most portable across all systems
- The ellipsis was likely in column descriptions, not affecting functionality
- Make sure to test that layout files still work correctly after modification
