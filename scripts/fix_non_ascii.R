# Fix non-ASCII characters in layout data files
#
# This script addresses R CMD check warnings about non-ASCII characters
# in data objects. Specifically, it replaces ellipsis characters (…)
# encoded as <85> with ASCII equivalent "..."

fix_non_ascii <- function(obj) {
  if (is.data.frame(obj)) {
    for (col in names(obj)) {
      if (is.character(obj[[col]])) {
        # First convert from Windows-1252 (Latin-1) to UTF-8 to handle <85> ellipsis
        obj[[col]] <- iconv(obj[[col]], from = "latin1", to = "UTF-8")
        # Replace Unicode ellipsis (U+2026) with ASCII "..."
        obj[[col]] <- gsub("\u2026", "...", obj[[col]], useBytes = FALSE)
        # Convert any remaining non-ASCII to ASCII
        obj[[col]] <- iconv(obj[[col]], from = "UTF-8", to = "ASCII//TRANSLIT")
      }
    }
  }
  obj
}

# List of layout files to fix
layout_files <- c(
  "gepa_layout", "gepa05_layout", "gepa06_layout",
  "hspa_layout", "hspa04_layout", "hspa05_layout",
  "hspa06_layout", "hspa10_layout",
  "njask04_layout", "njask05_layout",
  "njask06gr3_layout", "njask06gr5_layout",
  "njask07gr3_layout", "njask07gr5_layout"
)

# Process each layout file
for (layout_name in layout_files) {
  file_path <- file.path("data", paste0(layout_name, ".rda"))

  if (file.exists(file_path)) {
    # Load the object
    env <- new.env()
    load(file_path, envir = env)

    # Get object name (should match layout_name)
    obj_name <- ls(env)[1]
    obj <- get(obj_name, envir = env)

    # Fix non-ASCII characters
    obj <- fix_non_ascii(obj)

    # Save back to file
    assign(obj_name, obj)
    save(list = obj_name, file = file_path)

    message("Fixed: ", file_path)
  } else {
    warning("File not found: ", file_path)
  }
}

message("\nDone! Run devtools::check() to verify the fix.")
