# Story chart menu: render functions keyed by chart_id, driven by a district's
# discovery .rds (DAT list). A story subagent picks a chart_id per story; the
# almanac template calls render_story_chart() to place it inline.
# Self-contained almanac chart aesthetic (theme_almanac, defined below).

suppressMessages({ library(ggplot2); library(dplyr); library(scales); library(tidyr) })

# Almanac chart identity (self-contained; indigo/violet on cool near-white).
.paper <- "#f7f7f6"; .ink <- "#11131a"; .rule <- "#d9d9d4"; .gray <- "#5f6672"
.sec  <- "#3730a3"   # indigo  (primary / "this district")
.acc  <- "#7c3aed"   # violet  (highlight / second series)
.pos  <- "#15803d"   # green
.neg  <- "#b91c1c"   # red

theme_almanac <- function(base_size = 13) {
  theme_minimal(base_size = base_size) %+replace% theme(
    plot.background  = element_rect(fill = .paper, color = NA),
    panel.background = element_rect(fill = .paper, color = NA),
    panel.grid.major.y = element_line(color = .rule, linewidth = 0.35),
    panel.grid.major.x = element_blank(), panel.grid.minor = element_blank(),
    axis.text  = element_text(color = .gray, size = rel(0.85), family = "mono"),
    axis.title = element_text(color = .ink, size = rel(0.9)),
    plot.title = element_text(color = .ink, face = "bold", size = rel(1.25), hjust = 0, margin = margin(b = 4)),
    plot.subtitle = element_text(color = .gray, size = rel(0.95), hjust = 0, margin = margin(b = 9)),
    plot.caption  = element_text(color = .gray, size = rel(0.78), hjust = 1, margin = margin(t = 12)),
    legend.position = "bottom", legend.title = element_blank(),
    legend.text = element_text(color = .gray, size = rel(0.8)),
    plot.margin = margin(t = 12, r = 26, b = 8, l = 12), panel.border = element_blank()
  )
}

.peer_line <- function(y, lab = "Peer median")
  list(geom_hline(yintercept = y, linetype = "dashed", color = .gray, linewidth = 0.5),
       annotate("text", x = Inf, y = y, label = lab, hjust = 1.02, vjust = -0.5, color = .gray, size = 3))

.race_pal <- c(white="#3730a3", black="#7c3aed", hispanic="#0891b2", asian="#b45309",
               multiracial="#15803d", native_american="#9aa0ac", pacific_islander="#be185d")
.race_lab <- c(white="White", black="Black", hispanic="Hispanic", asian="Asian",
               multiracial="Two or more", native_american="Native American", pacific_islander="Pacific Islander")

# ---- chart menu (each returns ggplot or NULL) -------------------------------
CHARTS <- list(

  enr_trend = function(d) { x<-d$enr_total; if(is.null(x)||!nrow(x)) return(NULL)
    ggplot(x, aes(year, students)) + geom_line(linewidth=1.3, color=.sec) + geom_point(size=2.3, color=.sec) +
      scale_y_continuous(labels=comma, limits=c(0,NA)) + scale_x_continuous(breaks=breaks_pretty()) +
      labs(title="Total enrollment", x=NULL, y="Students") + theme_almanac() },

  demographics_area = function(d) { x<-d$dem_long; if(is.null(x)||!nrow(x)) return(NULL)
    ggplot(x, aes(end_year, pct, fill=subgroup)) + geom_area(position="fill", alpha=.92) +
      scale_y_continuous(labels=percent_format(scale=1)) + scale_x_continuous(breaks=breaks_pretty()) +
      scale_fill_manual(values=.race_pal, labels=.race_lab, na.value="gray70") +
      labs(title="Enrollment by race/ethnicity", subtitle="Share of students", x=NULL, y=NULL) +
      theme_almanac() },

  grad_trend = function(d) { x<-d$grad_total; if(is.null(x)||!nrow(x)) return(NULL)
    g<-ggplot(x, aes(year, grad_rate)) + geom_line(linewidth=1.3, color=.pos) + geom_point(size=2.3, color=.pos)
    if(!is.null(d$grad_peer_median)) g<-g+.peer_line(d$grad_peer_median)
    g + scale_y_continuous(labels=number_format(suffix="%"), limits=c(0,100)) + scale_x_continuous(breaks=breaks_pretty()) +
      labs(title="Four-year graduation rate", x=NULL, y=NULL) + theme_almanac() },

  grad_subgroups = function(d) { x<-d$grad_subgroups; if(is.null(x)||!nrow(x)) return(NULL)
    keep<-c("white","black","hispanic","asian","economically disadvantaged","students with disabilities","multilingual learners","total")
    x<-x %>% filter(tolower(subgroup) %in% keep, !is.na(grad_rate)) %>%
      mutate(subgroup=tools::toTitleCase(subgroup), hl=tolower(subgroup)=="total") %>% arrange(grad_rate) %>%
      mutate(subgroup=factor(subgroup, levels=subgroup))
    if(!nrow(x)) return(NULL)
    ggplot(x, aes(grad_rate, subgroup, fill=hl)) + geom_col(width=.7) +
      geom_text(aes(label=number(grad_rate,suffix="%")), hjust=-0.1, size=3.2, color=.gray) +
      scale_fill_manual(values=c(`TRUE`=.sec, `FALSE`=.acc), guide="none") +
      scale_x_continuous(labels=number_format(suffix="%"), limits=c(0,105), expand=expansion(mult=c(0,.05))) +
      labs(title="Graduation rate by student group", subtitle="Most recent cohort", x=NULL, y=NULL) + theme_almanac() },

  njsla_trend = function(d) { x<-d$njsla_trend; if(is.null(x)||!nrow(x)) return(NULL)
    ggplot(x, aes(testing_year, prof, color=test_name)) + geom_line(linewidth=1.2) + geom_point(size=2.2) +
      scale_color_manual(values=c(ela=.sec, math=.acc), labels=c(ela="ELA", math="Math"), na.value=.gray) +
      scale_y_continuous(labels=number_format(suffix="%"), limits=c(0,100)) + scale_x_continuous(breaks=breaks_pretty()) +
      labs(title="Elementary & middle proficiency (NJSLA)", subtitle="% proficient and above, grades 3-8", x=NULL, y=NULL) + theme_almanac() },

  njsla_gap = function(d) { x<-d$njsla_gap; if(is.null(x)||!nrow(x)) return(NULL)
    relab<-c(white="White", black="Black", hispanic="Hispanic", asian="Asian", ed="Economically disadvantaged",
             special_education="Students with disabilities", `multilingual learners`="Multilingual learners",
             `current - ml`="Multilingual learners", total_population="All students")
    x<-x %>% filter(tolower(subgroup) %in% names(relab), is.finite(prof)) %>%
      mutate(lab=relab[tolower(subgroup)], hl=tolower(subgroup)=="total_population") %>%
      filter(!is.na(lab)) %>% distinct(lab,.keep_all=TRUE) %>% arrange(prof) %>%
      mutate(subgroup=factor(lab, levels=lab))
    if(!nrow(x)) return(NULL)
    ggplot(x, aes(prof, subgroup, fill=hl)) + geom_col(width=.7) +
      geom_text(aes(label=number(prof,suffix="%")), hjust=-0.1, size=3.2, color=.gray) +
      scale_fill_manual(values=c(`TRUE`=.sec, `FALSE`=.acc), guide="none") +
      scale_x_continuous(labels=number_format(suffix="%"), limits=c(0,max(x$prof)*1.12), expand=expansion(mult=c(0,.05))) +
      labs(title="Grades 3-8 ELA proficiency by student group", x=NULL, y=NULL) + theme_almanac() },

  njgpa_trend = function(d) { x<-d$njgpa; if(is.null(x)||!nrow(x)) return(NULL)
    ggplot(x, aes(year, prof_above, color=test)) + geom_line(linewidth=1.2) + geom_point(size=2.2) +
      scale_color_manual(values=c(ela=.sec, math=.acc), labels=c(ela="ELA", math="Math"), na.value=.gray) +
      scale_y_continuous(labels=number_format(suffix="%"), limits=c(0,100)) + scale_x_continuous(breaks=breaks_pretty()) +
      labs(title="High-school proficiency (NJGPA)", subtitle="% proficient and above", x=NULL, y=NULL) + theme_almanac() },

  absence_trend = function(d) { x<-d$absence; if(is.null(x)||!nrow(x)) return(NULL)
    g<-ggplot(x, aes(year, chronic_pct)) + geom_line(linewidth=1.3, color=.acc) + geom_point(size=2.3, color=.acc)
    if(!is.null(d$absence_peer_median)) g<-g+.peer_line(d$absence_peer_median)
    g + scale_y_continuous(labels=number_format(suffix="%"), limits=c(0,NA)) + scale_x_continuous(breaks=breaks_pretty()) +
      labs(title="Chronic absenteeism", subtitle="% of students chronically absent", x=NULL, y=NULL) + theme_almanac() },

  apib_trend = function(d) { x<-d$apib; if(is.null(x)||!nrow(x)) return(NULL)
    xl<-x %>% select(year, District=ap3_ib4, State=state_ap3_ib4) %>% pivot_longer(-year)
    ggplot(xl, aes(year, value, color=name)) + geom_line(linewidth=1.2) + geom_point(size=2.2) +
      scale_color_manual(values=c(District=.acc, State=.gray)) +
      scale_y_continuous(labels=number_format(suffix="%"), limits=c(0,NA)) + scale_x_continuous(breaks=breaks_pretty()) +
      labs(title="AP/IB success", subtitle="% of students scoring 3+/4+ on an AP/IB exam", x=NULL, y=NULL) + theme_almanac() },

  discipline_trend = function(d) { x<-d$discipline; if(is.null(x)||!nrow(x)) return(NULL)
    ggplot(x, aes(year, oss_pct)) + geom_col(fill=.acc, width=.65) +
      scale_y_continuous(labels=number_format(suffix="%"), limits=c(0,NA)) + scale_x_continuous(breaks=breaks_pretty()) +
      labs(title="Out-of-school suspension rate", x=NULL, y=NULL) + theme_almanac() },

  spend_trend = function(d) { x<-d$spend_pp; if(is.null(x)||!nrow(x)) return(NULL)
    g<-ggplot(x, aes(year, per_pupil)) + geom_line(linewidth=1.3, color=.sec) + geom_point(size=2.3, color=.sec)
    if(!is.null(d$spend_peer_median)) g<-g+.peer_line(d$spend_peer_median)
    g + scale_y_continuous(labels=dollar_format(), limits=c(0,NA)) + scale_x_continuous(breaks=breaks_pretty()) +
      labs(title="Per-pupil spending", subtitle="TGES actuals", x=NULL, y=NULL) + theme_almanac() },

  spend_composition = function(d) { x<-d$spend_comp; if(is.null(x)||!nrow(x)) return(NULL)
    lab<-c(classroom_share="Classroom", support_services_share="Support services", administration_share="Administration",
           plant_ops_share="Plant ops", food_service_share="Food service", extracurricular_share="Extracurricular", equipment_share="Equipment")
    xl<-tibble(cat=names(x), val=as.numeric(x[1,])) %>% filter(cat %in% names(lab), is.finite(val)) %>%
      mutate(cat=factor(lab[cat], levels=lab[cat][order(val)]))
    if(!nrow(xl)) return(NULL)
    ggplot(xl, aes(val, cat)) + geom_col(fill=.sec, width=.7) +
      geom_text(aes(label=number(val,accuracy=.1,suffix="%")), hjust=-0.1, size=3.1, color=.gray) +
      scale_x_continuous(labels=number_format(suffix="%"), expand=expansion(mult=c(0,.14))) +
      labs(title="Where each per-pupil dollar goes", x=NULL, y=NULL) + theme_almanac() },

  sat_trend = function(d) { x<-d$sat; if(is.null(x)||!nrow(x)) return(NULL)
    xl<-x %>% select(year, District=sat_part, State=state_sat) %>% pivot_longer(-year) %>% filter(is.finite(value))
    if(!nrow(xl)) return(NULL)
    ggplot(xl, aes(year, value, color=name)) + geom_line(linewidth=1.2) + geom_point(size=2.2) +
      scale_color_manual(values=c(District=.sec, State=.gray)) +
      scale_y_continuous(labels=number_format(suffix="%"), limits=c(0,NA)) + scale_x_continuous(breaks=breaks_pretty()) +
      labs(title="SAT participation", x=NULL, y=NULL) + theme_almanac() },

  hib_trend = function(d) { x<-d$hib; if(is.null(x)||!nrow(x)) return(NULL)
    xl<-x %>% pivot_longer(c(alleged,confirmed))
    ggplot(xl, aes(end_year, value, color=name)) + geom_line(linewidth=1.2) + geom_point(size=2.2) +
      scale_color_manual(values=c(alleged=.gray, confirmed=.acc)) +
      scale_y_continuous(limits=c(0,NA)) + scale_x_continuous(breaks=breaks_pretty()) +
      labs(title="HIB investigations", subtitle="Alleged vs confirmed", x=NULL, y=NULL) + theme_almanac() }
)

chart_menu_ids <- function() names(CHARTS)

#' Render a story chart by id; returns the ggplot (or NULL if unavailable/unknown).
#' Adds a consistent source caption (data-journalism "receipts" convention).
render_story_chart <- function(d, chart_id) {
  if (is.null(chart_id) || !chart_id %in% names(CHARTS)) return(NULL)
  out <- tryCatch(CHARTS[[chart_id]](d), error = function(e) NULL)
  if (is.null(out)) return(NULL)
  out + labs(caption = "Source: NJ Dept. of Education, via the njschooldata package")
}
