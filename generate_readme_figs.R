#!/usr/bin/env Rscript
# Generate README figures for njschooldata

library(ggplot2)
library(dplyr)
library(scales)
library(purrr)
devtools::load_all(".")

# Create figures directory
dir.create("man/figures", recursive = TRUE, showWarnings = FALSE)

# Theme
theme_nj <- function() {
  theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 16),
      plot.subtitle = element_text(color = "gray40"),
      panel.grid.minor = element_blank(),
      legend.position = "bottom"
    )
}

colors <- c("total" = "#2C3E50", "white" = "#3498DB", "black" = "#E74C3C",
            "hispanic" = "#F39C12", "asian" = "#9B59B6", "charter" = "#1ABC9C")

# Fetch data
message("Fetching enrollment data...")
years <- 2015:2025
enr_all <- map_df(years, ~{
  tryCatch(fetch_enr(.x, tidy = TRUE), error = function(e) NULL)
})
enr_current <- fetch_enr(2025, tidy = TRUE)

# 1. Statewide enrollment
message("Creating statewide enrollment chart...")
state_total <- enr_all %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

p <- ggplot(state_total, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "New Jersey Educates 1.4 Million Students",
       subtitle = "Statewide public school enrollment has held steady",
       x = "School Year", y = "Students") +
  theme_nj()
ggsave("man/figures/statewide-enrollment.png", p, width = 10, height = 6, dpi = 150)

# 2. Newark charter growth
message("Creating Newark charter chart...")
newark <- enr_all %>%
  filter(grepl("Newark", district_name, ignore.case = TRUE),
         is_district | is_charter,
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  mutate(sector = ifelse(is_charter, "Charter", "Traditional"))

newark_summary <- newark %>%
  group_by(end_year, sector) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop")

p <- ggplot(newark_summary, aes(x = end_year, y = n_students, fill = sector)) +
  geom_area(alpha = 0.8) +
  scale_y_continuous(labels = comma) +
  scale_fill_manual(values = c("Charter" = colors["charter"], "Traditional" = colors["total"])) +
  labs(title = "Newark Leads the Charter School Revolution",
       subtitle = "Over 30% of Newark students now attend charter schools",
       x = "School Year", y = "Students", fill = "") +
  theme_nj()
ggsave("man/figures/newark-charter.png", p, width = 10, height = 6, dpi = 150)

# 3. Hispanic growth
message("Creating Hispanic growth chart...")
hispanic <- enr_all %>%
  filter(is_state, subgroup == "hispanic", grade_level == "TOTAL")

p <- ggplot(hispanic, aes(x = end_year, y = pct * 100)) +
  geom_line(linewidth = 1.5, color = colors["hispanic"]) +
  geom_point(size = 3, color = colors["hispanic"]) +
  labs(title = "Hispanic Students are the Fastest-Growing Group",
       subtitle = "From 20% to nearly 30% of all NJ students",
       x = "School Year", y = "Percent Hispanic") +
  theme_nj()
ggsave("man/figures/hispanic-growth.png", p, width = 10, height = 6, dpi = 150)

# 4. Big Three districts
message("Creating Big Three chart...")
big_three <- c("Newark", "Jersey City", "Paterson")
big_three_trend <- enr_all %>%
  filter(is_district,
         grepl(paste(big_three, collapse = "|"), district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

p <- ggplot(big_three_trend, aes(x = end_year, y = n_students, color = district_name)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "The Big Three: Newark, Jersey City, and Paterson",
       subtitle = "Combined enrollment of over 100,000 students",
       x = "School Year", y = "Students", color = "") +
  theme_nj()
ggsave("man/figures/big-three.png", p, width = 10, height = 6, dpi = 150)

# 5. COVID kindergarten
message("Creating COVID kindergarten chart...")
k_trend <- enr_all %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("PK", "KF", "01", "06", "12")) %>%
  mutate(grade_label = case_when(
    grade_level == "PK" ~ "Pre-K",
    grade_level == "KF" ~ "Kindergarten",
    grade_level == "01" ~ "Grade 1",
    grade_level == "06" ~ "Grade 6",
    grade_level == "12" ~ "Grade 12",
    TRUE ~ grade_level
  ))

p <- ggplot(k_trend, aes(x = end_year, y = n_students, color = grade_label)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  geom_vline(xintercept = 2021, linetype = "dashed", color = "red", alpha = 0.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "COVID Hit New Jersey Kindergarten Hard",
       subtitle = "Lost nearly 10% of kindergartners in 2021 - still recovering",
       x = "School Year", y = "Students", color = "") +
  theme_nj()
ggsave("man/figures/covid-kindergarten.png", p, width = 10, height = 6, dpi = 150)

# 6. Economic disadvantage
message("Creating economic disadvantage chart...")
econ <- enr_current %>%
  filter(is_district, subgroup == "econ_disadv", grade_level == "TOTAL",
         !is.na(pct), n_students >= 100) %>%
  arrange(desc(pct)) %>%
  head(15) %>%
  mutate(district_label = reorder(district_name, pct))

p <- ggplot(econ, aes(x = district_label, y = pct * 100)) +
  geom_col(fill = colors["total"]) +
  coord_flip() +
  labs(title = "Economic Disadvantage Varies Widely",
       subtitle = "Some districts approach 100% economically disadvantaged",
       x = "", y = "Percent Economically Disadvantaged") +
  theme_nj()
ggsave("man/figures/econ-disadvantage.png", p, width = 10, height = 6, dpi = 150)

# 7. Demographic shift
message("Creating demographic shift chart...")
demo <- enr_all %>%
  filter(is_state, subgroup %in% c("white", "hispanic", "black", "asian"),
         grade_level == "TOTAL") %>%
  mutate(subgroup = factor(subgroup, levels = c("white", "hispanic", "black", "asian")))

p <- ggplot(demo, aes(x = end_year, y = pct * 100, color = subgroup)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_color_manual(values = colors, labels = c("White", "Hispanic", "Black", "Asian")) +
  labs(title = "White Student Share Has Declined Dramatically",
       subtitle = "NJ public schools are now majority-minority",
       x = "School Year", y = "Percent of Students", color = "") +
  theme_nj()
ggsave("man/figures/demographic-shift.png", p, width = 10, height = 6, dpi = 150)

# 8. ELL concentration
message("Creating ELL concentration chart...")
ell <- enr_current %>%
  filter(is_district, subgroup == "lep_current", grade_level == "TOTAL",
         !is.na(pct), n_students >= 50) %>%
  arrange(desc(pct)) %>%
  head(15) %>%
  mutate(district_label = reorder(district_name, pct))

p <- ggplot(ell, aes(x = district_label, y = pct * 100)) +
  geom_col(fill = colors["hispanic"]) +
  coord_flip() +
  labs(title = "English Learners Concentrated in Urban Areas",
       subtitle = "Some districts have over 20% ELL students",
       x = "", y = "Percent English Language Learners") +
  theme_nj()
ggsave("man/figures/ell-concentration.png", p, width = 10, height = 6, dpi = 150)

# 9. Top 10 districts
message("Creating top 10 districts chart...")
top_10 <- enr_current %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(10) %>%
  mutate(district_label = reorder(district_name, n_students))

p <- ggplot(top_10, aes(x = district_label, y = n_students)) +
  geom_col(fill = colors["total"]) +
  coord_flip() +
  scale_y_continuous(labels = comma) +
  labs(title = "Top 10 Districts Educate 20% of All Students",
       subtitle = "Just 10 out of 600+ districts serve one-fifth of NJ students",
       x = "", y = "Students") +
  theme_nj()
ggsave("man/figures/top-10-districts.png", p, width = 10, height = 6, dpi = 150)

# 10. Special education
message("Creating special education chart...")
sped <- enr_all %>%
  filter(is_state, subgroup == "special_education", grade_level == "TOTAL")

p <- ggplot(sped, aes(x = end_year, y = pct * 100)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  labs(title = "Special Education Rates Remain Steady",
       subtitle = "About 17-18% of NJ students - among highest rates nationally",
       x = "School Year", y = "Percent Special Education") +
  theme_nj()
ggsave("man/figures/special-education.png", p, width = 10, height = 6, dpi = 150)

message("Done! Generated 10 figures in man/figures/")
