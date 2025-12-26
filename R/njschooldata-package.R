#' @keywords internal
"_PACKAGE"

# Suppress R CMD check notes for NSE variables used in dplyr/tidyr pipelines
utils::globalVariables(c(
  # Column names with special characters (from enrollment data)
  "% of Total Salaries",
  "%English Learners", "%Free Lunch", "%Homeless", "%Migrant", "%Military", "%Reduced Lunch",
  "Cost as a percentage of the Total Budgetary Cost Per Pupil",
  "Pre-K Halfday", "Ungraded",
  # Package data objects
  "charter_city", "sped_lookup_map", "nwk_address_addendum", "geocoded_cached",
  "layout_gepa", "layout_gepa05", "layout_gepa06",
"layout_hspa", "layout_hspa04", "layout_hspa05", "layout_hspa06", "layout_hspa10",
  "layout_njask", "layout_njask04", "layout_njask05", "layout_njask06gr3",
  "layout_njask06gr5", "layout_njask07gr3", "layout_njask07gr5", "layout_njask09", "layout_njask10",
  # General variables used in NSE
  "Name", "cds", "denom", "extension", "num", "round_1", "temp_id",
  "count_proficient_dummy", "count_scale_dummy",
  # SGP/growth variables
  "ela_sgp", "la_sgp", "m_sgp", "math_sgp", "median_sgp", "student_growth",
  "district_median", "school_median", "state_median", "school_mean", "met_target",
  # Peer percentile variables
  "proficiency_percentile", "proficient_above.x", "proficient_above.y", "proficient_diff",
  "proficient_group_size", "proficient_rank",
  "scale_group_size", "scale_rank", "scale_score_diff",
  "scale_score_mean.x", "scale_score_mean.y", "scale_score_percentile",
  "statewide_proficient_percentile", "statewide_scale_percentile",
  # Enrollment variables
  "enr_2013", "n_charter",
  # DFG variables
  "x1990_dfg", "x2000_dfg"
))

## usethis namespace: start
#' @import dplyr
#' @import tidyr
#' @import purrr
#' @importFrom magrittr %>%
#' @importFrom stringr str_sub str_detect str_replace str_extract str_c str_trim str_to_lower str_to_upper str_pad str_replace_all
#' @importFrom readr read_csv read_fwf fwf_widths fwf_cols cols col_character col_double col_integer
#' @importFrom rlang .data := sym enquo !!
#' @importFrom stats na.omit setNames
#' @importFrom utils head tail data download.file object.size
#' @importFrom janitor tabyl clean_names compare_df_cols compare_df_cols_same
#' @importFrom magrittr extract2 use_series multiply_by add %$%
## usethis namespace: end
NULL
