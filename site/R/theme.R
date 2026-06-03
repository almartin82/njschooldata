# Shared ggplot theme + palettes for the NJ District Profiles site.
# Extracted from the package vignettes (newark-fiscal-brief.Rmd, nj-enrollment-insights.Rmd)
# so every profile page renders with one consistent look.

suppressMessages({
  library(ggplot2)
})

#' Consistent minimal theme for all profile charts.
theme_nj <- function(base_size = 13) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title    = element_text(face = "bold", size = base_size + 3),
      plot.subtitle = element_text(color = "gray40"),
      plot.caption  = element_text(color = "gray55", size = base_size - 4),
      panel.grid.minor = element_blank(),
      legend.position  = "bottom",
      legend.title     = element_blank()
    )
}

# Core brand palette ----------------------------------------------------------
nj_navy   <- "#16356B"  # primary / "this district"
nj_gold   <- "#C8A14B"
nj_teal   <- "#16A085"
nj_red    <- "#B83227"
nj_orange <- "#E67E22"
nj_purple <- "#9B59B6"
peer_gray <- "gray70"   # peer-group reference

# Demographic subgroup palette (matches tidy-enrollment subgroup names) --------
demographic_colors <- c(
  "total_enrollment" = "#2C3E50",
  "white"            = "#3498DB",
  "black"            = "#E74C3C",
  "hispanic"         = "#F39C12",
  "asian"            = "#9B59B6",
  "multiracial"      = "#27AE60",
  "native_american"  = "#7F8C8D",
  "pacific_islander" = "#1ABC9C",
  "econ_disadv"      = "#E67E22",
  "special_ed"       = "#34495E",
  "lep"              = "#16A085"
)

# Human-readable labels for subgroup codes -----------------------------------
subgroup_labels <- c(
  "total_enrollment" = "Total",
  "white"            = "White",
  "black"            = "Black",
  "hispanic"         = "Hispanic",
  "asian"            = "Asian",
  "multiracial"      = "Two or more races",
  "native_american"  = "Native American",
  "pacific_islander" = "Pacific Islander",
  "econ_disadv"      = "Economically disadvantaged",
  "special_ed"       = "Students with disabilities",
  "lep"              = "English learners",
  "male"             = "Male",
  "female"           = "Female"
)

# "this district vs peer" 2-color scale --------------------------------------
focus_vs_peer <- c("This district" = nj_navy, "Peer group" = peer_gray)
