#!/usr/bin/env Rscript
# =============================================================================
# discovery-doc.R — per-district DISCOVERY DOC generator (the story substrate).
# Discovery-doc concept: mine every available longitudinal
# source for one district, pre-compute ranked candidate SIGNALS + full data
# tables, write markdown to site/_discovery/{id}.md. A story subagent reads this.
# Every number is computed from fetched NJ DOE data — nothing fabricated.
#
#   Rscript site/discovery-doc.R 4900            # one district
#   Rscript site/discovery-doc.R 4900 3570 ...   # several
# =============================================================================
suppressMessages({ library(dplyr); library(tidyr); library(purrr) })

SW   <- file.path("site", "_bundles", "_statewide")
OUT  <- file.path("site", "_discovery"); dir.create(OUT, showWarnings = FALSE)
rd   <- function(n) { p <- file.path(SW, paste0(n, ".rds")); if (file.exists(p)) readRDS(p) else NULL }

# ---- load all statewide frames once ----
SWD <- list(
  dir = rd("directory"), dfg = rd("dfg"), enr = rd("enrollment"), grad = rd("grad"),
  njgpa = rd("njgpa"), njsla = rd("njsla"), absence = rd("absence"), tges = rd("tges"),
  staff = rd("staff"), aid = rd("aid"), sat_part = rd("sat_part"), sat_perf = rd("sat_perf"),
  apib = rd("apib"), removals = rd("removals"), police = rd("police"), hib = rd("hib"),
  sped = rd("sped")
)

# ---- helpers ----
num <- function(x) suppressWarnings(as.numeric(gsub("[,%$]", "", as.character(x))))
pctile <- function(v, peers) { peers <- peers[is.finite(peers)]; if (!is.finite(v) || length(peers) < 5) return(NA_real_); round(100 * mean(peers <= v, na.rm = TRUE)) }
ordsuf <- function(n) { if (is.na(n)) return(""); if (n %% 100 %in% 11:13) "th" else c("th","st","nd","rd","th","th","th","th","th","th")[(n %% 10) + 1] }
cmft <- function(x) ifelse(is.na(x), "n/a", formatC(round(x), format = "d", big.mark = ","))
pc <- function(x, d = 1) ifelse(is.na(x), "n/a", paste0(formatC(x, format = "f", digits = d), "%"))
dol <- function(x) ifelse(is.na(x), "n/a", paste0("$", formatC(round(x), format = "d", big.mark = ",")))
md_table <- function(df) {
  if (is.null(df) || !nrow(df)) return("_no data_\n")
  hdr <- paste0("| ", paste(names(df), collapse = " | "), " |")
  sep <- paste0("| ", paste(rep("---", ncol(df)), collapse = " | "), " |")
  rows <- apply(df, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |"))
  paste0(hdr, "\n", sep, "\n", paste(rows, collapse = "\n"), "\n")
}

build_discovery <- function(id) {
  meta <- SWD$dir %>% filter(district_id == id) %>% slice(1)
  if (!nrow(meta)) { warning("no directory row ", id); return(invisible(NULL)) }
  dfg <- SWD$dfg$dfg[match(id, SWD$dfg$district_id)]
  is_charter <- isTRUE(meta$is_charter) || meta$county_id == "80"
  peers <- if (!is.na(dfg)) SWD$dfg$district_id[which(SWD$dfg$dfg == dfg)] else SWD$dfg$district_id
  n_peers <- length(unique(peers))
  SIG <- character(0)        # ranked candidate findings
  TAB <- character(0)        # data-table sections
  DAT <- list(meta = list(district_id = id, district_name = meta$district_name,
              county = tools::toTitleCase(tolower(meta$county_name)), dfg = dfg,
              is_charter = is_charter, n_peers = n_peers,
              superintendent = meta$superintendent_name, website = meta$website))
  add_sig <- function(...) { v <- do.call(paste0, list(...)); SIG[[length(SIG) + 1]] <<- v[[1]] }
  add_tab <- function(title, body) TAB[[length(TAB) + 1]] <<- paste0("### ", title, "\n\n", body)

  # ---------- ENROLLMENT ----------
  e <- SWD$enr %>% filter(district_id == id)
  et <- e %>% filter(subgroup == "total_enrollment", grade_level == "TOTAL") %>%
    arrange(end_year) %>% transmute(year = end_year, students = round(n_students))
  if (nrow(et)) {
    et <- et %>% mutate(yoy = students - lag(students), yoy_pct = round(100*(students/lag(students)-1),1))
    cur <- tail(et, 1); pk <- et[which.max(et$students), ]; tr <- et[which.min(et$students), ]
    ly <- max(et$year)
    peer_enr <- SWD$enr %>% filter(subgroup=="total_enrollment", grade_level=="TOTAL", end_year==ly, district_id %in% peers)
    pr <- pctile(cur$students, peer_enr$n_students)
    add_sig("ENROLLMENT now ", cmft(cur$students), " (", cur$year, "); peak ", cmft(pk$students), " (", pk$year,
            "), trough ", cmft(tr$students), " (", tr$year, "). Change since first year (", et$year[1], "): ",
            cmft(cur$students-et$students[1]), " (", pc(100*(cur$students/et$students[1]-1)), ").",
            if (cur$year==tr$year) " *Currently at its lowest on record.*" else if (cur$year==pk$year) " *Currently at its peak.*" else "")
    # COVID delta
    if (all(c(2019,2022) %in% et$year)) {
      d <- et$students[et$year==2022]-et$students[et$year==2019]
      add_sig("COVID enrollment change 2019->2022: ", cmft(d), " (", pc(100*(d/et$students[et$year==2019])), ").")
    }
    DAT$enr_total <- et
    add_tab("Enrollment (total)", md_table(et))
  }
  # demographics
  dem <- e %>% filter(subgroup %in% c("white","black","hispanic","asian","multiracial","native_american","pacific_islander"),
                      grade_level=="TOTAL") %>% arrange(end_year)
  if (nrow(dem)) {
    wide <- dem %>% mutate(pct=round(100*pct,1)) %>% select(end_year, subgroup, pct) %>%
      pivot_wider(names_from=subgroup, values_from=pct) %>% arrange(end_year)
    yrs <- range(dem$end_year)
    sh <- dem %>% group_by(subgroup) %>% summarise(first=100*pct[which.min(end_year)], last=100*pct[which.max(end_year)], .groups="drop") %>%
      mutate(shift=round(last-first,1)) %>% arrange(desc(abs(shift)))
    top <- sh %>% slice(1)
    add_sig("DEMOGRAPHIC shift ", yrs[1], "-", yrs[2], ": largest change is ", top$subgroup, " (",
            pc(top$first), " -> ", pc(top$last), ", ", sprintf("%+.1f", top$shift), "pp). ",
            paste(sprintf("%s %+.1fpp", sh$subgroup[1:min(3,nrow(sh))], sh$shift[1:min(3,nrow(sh))]), collapse="; "), ".")
    DAT$demographics <- wide; DAT$dem_long <- dem %>% mutate(pct=100*pct)
    add_tab("Demographic share (%) by year", md_table(wide))
  }
  sp <- e %>% filter(subgroup %in% c("lep","free_reduced_lunch","econ_disadv"), grade_level=="TOTAL") %>%
    arrange(end_year) %>% mutate(pct=round(100*pct,1)) %>% select(end_year, subgroup, students=n_students, pct)
  if (nrow(sp)) add_tab("Special populations (LEP, FRL)", md_table(sp %>% mutate(students=round(students))))

  # ---------- GRADUATION ----------
  g <- SWD$grad %>% filter(district_id==id, methodology=="4 year")
  gt_lab <- intersect(c("total","total_population","districtwide"), unique(tolower(g$subgroup)))[1]
  if (!is.na(gt_lab) && nrow(g)) {
    gt <- g %>% filter(tolower(subgroup)==gt_lab) %>% arrange(end_year) %>%
      transmute(year=end_year, grad_rate=round(100*grad_rate,1), cohort=cohort_count)
    if (nrow(gt)) {
      ly <- max(gt$year); val <- gt$grad_rate[gt$year==ly]
      peer <- SWD$grad %>% filter(methodology=="4 year", end_year==ly, tolower(subgroup)==gt_lab, district_id %in% peers)
      pr <- pctile(val/100, peer$grad_rate); pmed <- round(100*median(peer$grad_rate, na.rm=TRUE),1)
      add_sig("GRADUATION (4yr) ", pc(val), " in ", ly, " — ", pr, ordsuf(pr), " percentile among ", n_peers,
              " DFG ", dfg, " peers (peer median ", pc(pmed), ").")
      # subgroup gaps latest year
      gl <- g %>% filter(end_year==ly) %>% mutate(grad_rate=round(100*grad_rate,1)) %>%
        select(subgroup, grad_rate, cohort=cohort_count) %>% arrange(desc(grad_rate))
      bw <- gl %>% filter(tolower(subgroup) %in% c("white","black"))
      if (nrow(bw)==2) add_sig("GRAD subgroup gap ", ly, ": white ", pc(bw$grad_rate[tolower(bw$subgroup)=="white"]),
                               " vs black ", pc(bw$grad_rate[tolower(bw$subgroup)=="black"]), ".")
      DAT$grad_total <- gt; DAT$grad_peer_median <- pmed
      add_tab("Graduation rate 4yr (total)", md_table(gt))
      DAT$grad_subgroups <- gl
      add_tab(paste0("Graduation by subgroup (", ly, ")"), md_table(gl))
    }
  }

  # ---------- ASSESSMENT: NJGPA (HS) ----------
  np <- SWD$njgpa %>% filter(district_id==id)
  npl <- intersect(c("total students","total","all students"), unique(tolower(np$subgroup)))[1]
  if (!is.na(npl) && nrow(np)) {
    nt <- np %>% filter(tolower(subgroup)==npl) %>% arrange(testing_year, test_name) %>%
      transmute(year=testing_year, test=test_name, prof_above=round(num(proficient_above),1), valid=number_of_valid_scale_scores)
    if (nrow(nt)) { add_sig("NJGPA (HS) latest: ", paste(sprintf("%s %s", nt$test[nt$year==max(nt$year)], pc(nt$prof_above[nt$year==max(nt$year)])), collapse=", "), ".")
      DAT$njgpa <- nt
      add_tab("NJGPA high-school proficiency (% proficient+)", md_table(nt)) }
    # subgroup gaps latest
    nly <- max(np$testing_year)
    ng <- np %>% filter(testing_year==nly, test_name=="ela") %>% mutate(prof=round(num(proficient_above),1)) %>%
      filter(!is.na(prof)) %>% select(subgroup, prof) %>% arrange(desc(prof))
    if (nrow(ng) > 3) add_tab(paste0("NJGPA ELA by subgroup (", nly, ")"), md_table(ng))
  }
  # NJSLA grades 3-8 (elementary/middle proficiency)
  if (!is.null(SWD$njsla) && nrow(SWD$njsla)) {
    ns <- SWD$njsla %>% filter(district_id==id)
    nsl <- intersect(c("total_population","total students","total","all students"), unique(tolower(ns$subgroup)))[1]
    wcol <- intersect("number_of_valid_scale_scores", names(ns)); wname <- if (length(wcol)) wcol[1] else NA
    ns$p <- num(ns$proficient_above); ns$w <- if (!is.na(wname)) num(ns[[wname]]) else 1
    ns$w[!is.finite(ns$w)] <- 0
    if (!is.na(nsl) && nrow(ns)) {
      base <- ns %>% filter(tolower(subgroup)==nsl)
      trend <- base %>% filter(is.finite(p)) %>% group_by(testing_year, test_name) %>%
        summarise(prof=round(weighted.mean(p, w, na.rm=TRUE),1), .groups="drop") %>% arrange(testing_year, test_name)
      if (nrow(trend)) {
        DAT$njsla_trend <- trend
        ela <- trend %>% filter(test_name=="ela"); mat <- trend %>% filter(test_name=="math")
        if (nrow(ela)) { ly <- max(ela$testing_year)
          add_sig("NJSLA grades 3-8 in ", ly, ": ", pc(ela$prof[ela$testing_year==ly]), " proficient in ELA",
                  if (nrow(mat) && ly %in% mat$testing_year) paste0(", ", pc(mat$prof[mat$testing_year==ly]), " in math") else "", ".")
          if (all(c(2019,2022) %in% ela$testing_year))
            add_sig("NJSLA ELA grades 3-8 COVID change 2019->2022: ", sprintf("%+.1f", ela$prof[ela$testing_year==2022]-ela$prof[ela$testing_year==2019]), "pp",
                    if (max(ela$testing_year)>2022) paste0("; by ", max(ela$testing_year), " at ", pc(ela$prof[ela$testing_year==max(ela$testing_year)])) else "", ".")
        }
        add_tab("NJSLA grades 3-8 proficiency (% proficient+, enrollment-weighted across grades)", md_table(trend))
      }
      gly <- max(ns$testing_year)
      gg <- ns %>% filter(testing_year==gly, test_name=="ela", is.finite(p)) %>% group_by(subgroup) %>%
        summarise(prof=round(weighted.mean(p, w, na.rm=TRUE),1), .groups="drop") %>% arrange(desc(prof))
      if (nrow(gg) > 3) { DAT$njsla_gap <- gg; DAT$njsla_gap_year <- gly
        add_tab(paste0("NJSLA ELA proficiency by subgroup (", gly, ", grades 3-8)"), md_table(gg)) }
    }
  }

  # ---------- ABSENCE ----------
  ab <- SWD$absence %>% filter(district_id==id)
  abl <- intersect(c("total students","total","districtwide","all students"), unique(tolower(ab$subgroup)))[1]
  if (!is.na(abl) && nrow(ab)) {
    at <- ab %>% filter(tolower(subgroup)==abl) %>% arrange(end_year) %>%
      transmute(year=end_year, chronic_pct=round(num(chronically_absent_rate),1))
    if (nrow(at)) {
      ly <- max(at$year); v <- at$chronic_pct[at$year==ly]
      peer <- SWD$absence %>% filter(end_year==ly, tolower(subgroup)==abl, district_id %in% peers) %>% mutate(r=num(chronically_absent_rate))
      pr <- pctile(v, peer$r); pmed <- round(median(peer$r, na.rm=TRUE),1)
      add_sig("CHRONIC ABSENTEEISM ", pc(v), " in ", ly, " (peer median ", pc(pmed), "); ",
              if (all(c(2019,ly) %in% at$year)) paste0("vs ", pc(at$chronic_pct[at$year==2019]), " pre-COVID (2019).") else "")
      DAT$absence <- at; DAT$absence_peer_median <- pmed
      add_tab("Chronic absenteeism (% chronically absent)", md_table(at))
    }
  }

  # ---------- DISCIPLINE / CLIMATE ----------
  if (!is.null(SWD$removals)) {
    rm <- SWD$removals %>% filter(district_id==id) %>% arrange(end_year) %>%
      transmute(year=end_year, oss_pct=num(outof_school_pct), susp_pct=num(any_susp_pct),
                arrests=num(arrest_count), expulsions=num(expulsion_count), days_missed=num(school_days_missed_oss))
    if (nrow(rm)) { ly <- max(rm$year)
      add_sig("DISCIPLINE ", ly, ": out-of-school suspension rate ", pc(rm$oss_pct[rm$year==ly]),
              ", ", cmft(rm$arrests[rm$year==ly]), " arrests, ", cmft(rm$days_missed[rm$year==ly]), " school-days missed to OSS.")
      DAT$discipline <- rm
      add_tab("Disciplinary removals", md_table(rm)) }
  }
  if (!is.null(SWD$police)) {
    po <- SWD$police %>% filter(district_id==id) %>% arrange(end_year) %>%
      transmute(year=end_year, violence, weapons, vandalism, substances, hib, other=other_incidents)
    if (nrow(po)) { DAT$police <- po; add_tab("Police notifications (incident counts)", md_table(po)) }
  }
  if (!is.null(SWD$hib)) {
    hb <- SWD$hib %>% filter(district_id==id) %>% group_by(end_year) %>%
      summarise(alleged=sum(num(hib_alleged),na.rm=TRUE), confirmed=sum(num(hib_confirmed),na.rm=TRUE), .groups="drop") %>% arrange(end_year)
    if (nrow(hb)) { DAT$hib <- hb; add_tab("HIB (harassment/intimidation/bullying) investigations", md_table(hb)) }
  }

  # ---------- COLLEGE READINESS ----------
  prefer_dist <- function(df) df %>% mutate(.p = ifelse(is_district, 0L, 1L)) %>%
    group_by(end_year) %>% slice_min(.p, n=1, with_ties=FALSE) %>% ungroup() %>% select(-.p) %>% arrange(end_year)
  if (!is.null(SWD$sat_part)) {
    s <- SWD$sat_part %>% filter(district_id==id) %>% prefer_dist() %>%
      transmute(year=end_year, sat_part=num(sat_participation), state_sat=num(state_sat))
    if (nrow(s) && any(is.finite(s$sat_part))) { DAT$sat <- s; add_tab("SAT participation (% of grade)", md_table(s)) }
  }
  if (!is.null(SWD$apib)) {
    a <- SWD$apib %>% filter(district_id==id) %>% prefer_dist() %>%
      transmute(year=end_year, apib_coursework=num(apib_coursework_school), apib_exam=num(apib_exam_school),
                ap3_ib4=num(ap3_ib4_school), state_ap3_ib4=num(ap3_ib4_state), dual=num(dual_enrollment_school))
    if (nrow(a) && any(is.finite(a$ap3_ib4))) { ly <- max(a$year)
      add_sig("AP/IB ", ly, ": ", pc(a$ap3_ib4[a$year==ly]), " of students scored 3+/4+ on an AP/IB exam (state ", pc(a$state_ap3_ib4[a$year==ly]), ").")
      DAT$apib <- a
      add_tab("AP/IB & dual enrollment (% of students)", md_table(a)) }
  }

  # ---------- SPECIAL ED ----------
  if (!is.null(SWD$sped)) {
    sd <- SWD$sped %>% filter(district_id==id)
    if (nrow(sd)) add_tab("Special education (raw rows; inspect for classification rate)",
                          md_table(head(sd %>% select(any_of(c("end_year","district_id","subgroup","grade_level","n_students","pct","program","count"))), 30)))
  }

  # ---------- SPENDING (TGES) ----------
  if (!is_charter && !is.null(SWD$tges$pp)) {
    pp <- SWD$tges$pp %>% filter(district_id==id, grepl("actual", tolower(calc_type))) %>%
      group_by(end_year) %>% slice_max(report_year, n=1, with_ties=FALSE) %>% ungroup() %>% arrange(end_year) %>%
      transmute(year=end_year, per_pupil=`Per Pupil costs`, rank=`District rank`, ade=`Enrollment (ADE)`)
    if (nrow(pp)) { ly <- max(pp$year); v <- pp$per_pupil[pp$year==ly]
      peer <- SWD$tges$pp %>% filter(grepl("actual", tolower(calc_type)), end_year==ly, district_id %in% peers, district_id!="00NA")
      pr <- pctile(v, peer$`Per Pupil costs`); pmed <- median(peer$`Per Pupil costs`, na.rm=TRUE)
      add_sig("SPENDING per-pupil ", dol(v), " (", ly, ") — ", pr, ordsuf(pr), " percentile among DFG ", dfg,
              " peers (peer median ", dol(pmed), "). Change since ", pp$year[1], ": ", pc(100*(v/pp$per_pupil[1]-1)), ".")
      DAT$spend_pp <- pp; DAT$spend_peer_median <- pmed
      add_tab("Per-pupil spending (TGES actuals)", md_table(pp)) }
    if (!is.null(SWD$tges$comp_latest)) {
      cmp <- SWD$tges$comp_latest %>% filter(district_id==id) %>% filter(end_year==max(end_year)) %>% slice(1)
      if (nrow(cmp)) {
        shares <- cmp %>% select(ends_with("_share")) %>% mutate(across(everything(), ~round(100*num(.),1)))
        DAT$spend_comp <- shares; DAT$spend_comp_year <- cmp$end_year
        add_tab(paste0("Spending composition shares (", cmp$end_year, ")"), md_table(shares))
      }
    }
  }

  # ---------- STAFF ----------
  if (!is.null(SWD$staff)) {
    st <- SWD$staff %>% filter(district_id==id) %>% slice(1) %>%
      select(any_of(c("end_year","student_teacher_district","student_admin_district","student_counselor_district","student_nurse_district")))
    if (nrow(st)) add_tab("Staffing ratios", md_table(st))
  }

  # ---------- assemble ----------
  hdr <- paste0(
    "# Discovery doc: ", meta$district_name, "\n\n",
    "- **district_id:** ", id, " · **county:** ", tools::toTitleCase(tolower(meta$county_name)),
    " · **DFG:** ", ifelse(is.na(dfg), "none (charter/special)", dfg),
    " · **type:** ", ifelse(is_charter, "charter", "traditional"), "\n",
    "- **peer group:** ", n_peers, " districts in DFG ", ifelse(is.na(dfg),"(all)",dfg),
    " · **superintendent:** ", ifelse(is.na(meta$superintendent_name),"n/a",meta$superintendent_name),
    " · **website:** ", ifelse(is.na(meta$website),"n/a",meta$website), "\n\n",
    "_All figures computed from NJ DOE data via the njschooldata package. Every number below is real; cite exact values in stories. Peer comparisons use District Factor Group (DFG)._\n"
  )
  sig_md <- paste0("\n## SIGNALS — ranked candidate findings\n\n",
                   paste(sprintf("%d. %s", seq_along(SIG), SIG), collapse = "\n"), "\n")
  tab_md <- paste0("\n## DATA TABLES (longitudinal, all categories)\n\n", paste(TAB, collapse = "\n\n"))
  writeLines(paste0(hdr, sig_md, tab_md), file.path(OUT, paste0(id, ".md")))
  DAT$signals <- SIG
  saveRDS(DAT, file.path(OUT, paste0(id, ".rds")))
  cat("wrote", file.path(OUT, paste0(id, ".md")), "(", length(SIG), "signals,", length(TAB), "tables )\n")
  invisible(NULL)
}

ids <- commandArgs(trailingOnly = TRUE)
if (!length(ids)) ids <- "4900"
for (id in ids) tryCatch(build_discovery(id), error=function(e) warning(id, ": ", conditionMessage(e)))
