# Build the offline fixture for parse_certificated_modern().
#
# Provenance: every value below is copied VERBATIM from the NJ DOE certificated
# staff workbook "Certificated Staff 2026.xlsx"
# (https://www.nj.gov/education/doedata/cs/, end_year 2026, downloaded
# 2026-08-10). Nothing is invented, rounded, or reshaped -- this script only
# selects a handful of published rows and rewrites them into the same two-row
# header layout the real workbook uses (title row, then column names).
#
# Why the fixture exists: the STATE sheet publishes NO "Co Code" column, so
# every state row's charter status is honestly unknown. That is the code path
# behind 105 of the 141 rows that used to ship a fabricated is_charter = FALSE,
# and it cannot be exercised offline without a real .xlsx. writexl is not a
# hard dependency, so the workbook is generated here once and committed.
#
# Regenerate with: Rscript data-raw/build_certificated_modern_fixture.R
#   (requires writexl and network access to nj.gov)

devtools::load_all(".", quiet = TRUE)

work_dir <- tempfile("cs26_")
dir.create(work_dir)
local_file <- certificated_staff_local_file(2026, work_dir)

sheet_slice <- function(sheet, rows) {
  full <- suppressMessages(readxl::read_excel(local_file$path, sheet = sheet, skip = 1))
  slice <- full[rows, , drop = FALSE]
  body <- as.data.frame(lapply(slice, as.character), stringsAsFactors = FALSE)
  names(body) <- names(slice)
  # Rebuild the workbook's own layout: writexl emits the data frame's names as
  # row 1 (the real file's title row), so the published header names have to
  # ride as the first data row for read_excel(skip = 1) to find them.
  out <- rbind(setNames(as.list(names(slice)), names(slice)), body)
  names(out) <- paste0("Certificated Staff 2026 - ", sheet, " ", seq_along(out))
  out
}

state_rows <- which(
  suppressMessages(
    readxl::read_excel(local_file$path, sheet = "STATE", skip = 1)
  )$Position %in% c("Administrators", "Teacher")
)

district_full <- suppressMessages(
  readxl::read_excel(local_file$path, sheet = "DISTRICT", skip = 1)
)
district_rows <- c(
  which(district_full$`Co Code` == "80")[1:2],   # Academy Charter High School
  which(district_full$`Co Code` == "01")[1:2]    # Absecon Public Schools District
)

dest <- "inst/extdata/test-fixtures/certificated-staff-modern-2026.xlsx"
dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
writexl::write_xlsx(
  list(
    STATE = sheet_slice("STATE", state_rows),
    DISTRICT = sheet_slice("DISTRICT", district_rows)
  ),
  path = dest
)

message("wrote ", dest, " (", file.size(dest), " bytes)")
