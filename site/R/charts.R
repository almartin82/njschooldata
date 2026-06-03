# Reusable chart builders for profile pages. All return a ggplot; all use theme_nj().

suppressMessages({ library(ggplot2); library(scales); library(dplyr) })

#' Single-series trend line over end_year.
#' value_fmt: "comma" | "dollar" | "pct"
chart_trend <- function(df, x, y, title, subtitle = NULL, ylab = NULL,
                        value_fmt = "comma", color = nj_navy,
                        peer_value = NULL, peer_label = "Peer median") {
  fmt <- switch(value_fmt, dollar = label_dollar(), pct = label_number(suffix = "%"), label_comma())
  p <- ggplot(df, aes(x = .data[[x]], y = .data[[y]])) +
    geom_line(linewidth = 1.4, color = color) +
    geom_point(size = 2.6, color = color)
  if (!is.null(peer_value) && is.finite(peer_value)) {
    p <- p + geom_hline(yintercept = peer_value, linetype = "dashed", color = peer_gray) +
      annotate("text", x = max(df[[x]], na.rm = TRUE), y = peer_value,
               label = peer_label, hjust = 1, vjust = -0.5, color = "gray45", size = 3.2)
  }
  p + scale_y_continuous(labels = fmt, limits = c(0, NA)) +
    scale_x_continuous(breaks = scales::breaks_pretty()) +
    labs(title = title, subtitle = subtitle, x = NULL, y = ylab) +
    theme_nj()
}

#' Stacked-area composition of demographic shares over time.
chart_demographics <- function(df, title, subtitle = NULL) {
  ggplot(df, aes(x = end_year, y = n_students, fill = subgroup)) +
    geom_area(position = "fill", alpha = 0.9) +
    scale_y_continuous(labels = label_percent()) +
    scale_x_continuous(breaks = scales::breaks_pretty()) +
    scale_fill_manual(values = demographic_colors, labels = subgroup_labels,
                      na.value = "gray70") +
    labs(title = title, subtitle = subtitle, x = NULL, y = "Share of enrollment") +
    theme_nj()
}

#' Per-pupil spending composition (one latest year) as a labelled bar of shares.
chart_composition <- function(comp_row, title, subtitle = NULL) {
  cats <- c(classroom = "Classroom instruction", support_services = "Support services",
            administration = "Administration", plant_ops = "Plant operations",
            food_service = "Food service", extracurricular = "Extracurricular",
            equipment = "Equipment")
  vals <- vapply(names(cats), function(k) {
    v <- comp_row[[paste0(k, "_share")]]; if (is.null(v) || length(v) == 0) NA_real_ else v[1]
  }, numeric(1))
  d <- tibble(cat = unname(cats), share = as_pct_scale(vals)) %>%
    filter(is.finite(share)) %>% arrange(share) %>%
    mutate(cat = factor(cat, levels = cat))
  ggplot(d, aes(x = cat, y = share)) +
    geom_col(fill = nj_navy) + coord_flip() +
    geom_text(aes(label = label_number(suffix = "%", accuracy = 0.1)(share)), hjust = -0.1, size = 3.4) +
    scale_y_continuous(labels = label_number(suffix = "%"), expand = expansion(mult = c(0, 0.18))) +
    labs(title = title, subtitle = subtitle, x = NULL, y = "Share of per-pupil spending") +
    theme_nj()
}

#' Horizontal bar of latest grade-level distribution.
chart_grades <- function(df, title, subtitle = NULL) {
  ord <- c("PK","K","01","02","03","04","05","06","07","08","09","10","11","12")
  df <- df %>% mutate(grade_level = factor(grade_level, levels = ord)) %>% filter(!is.na(grade_level))
  ggplot(df, aes(x = grade_level, y = n_students)) +
    geom_col(fill = nj_teal) +
    scale_y_continuous(labels = label_comma()) +
    labs(title = title, subtitle = subtitle, x = "Grade", y = "Students") +
    theme_nj()
}

#' This-district vs peer-median bar for a single metric.
chart_vs_peer <- function(value, peer_median, title, subtitle = NULL,
                          value_fmt = "pct", district_label = "This district") {
  fmt <- switch(value_fmt, dollar = label_dollar(), pct = label_number(suffix = "%"), label_comma())
  d <- tibble(who = factor(c(district_label, "Peer median"),
                           levels = c(district_label, "Peer median")),
              val = c(value, peer_median))
  ggplot(d, aes(x = who, y = val, fill = who)) +
    geom_col(width = 0.6) +
    geom_text(aes(label = fmt(val)), vjust = -0.4, size = 4) +
    scale_fill_manual(values = setNames(c(nj_navy, peer_gray), c(district_label, "Peer median"))) +
    scale_y_continuous(labels = fmt, limits = c(0, NA)) +
    labs(title = title, subtitle = subtitle, x = NULL, y = NULL) +
    theme_nj() + theme(legend.position = "none")
}
