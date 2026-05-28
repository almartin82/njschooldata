#' Identify charter host districts
#'
#' Joins NJ school data to the 1:1 \code{charter_city} host map, attaching
#' \code{host_county_id}, \code{host_county_name}, \code{host_district_id} and
#' \code{host_district_name} for every charter record.
#'
#' \strong{Multi-campus charters.} NJ DOE assigns one \code{district_id} per
#' charter and does NOT report charter campuses separately, but a few charters
#' operate campuses in more than one host city under a single \code{district_id}
#' (e.g. M.E.T.S. Charter School, district 6068, which ran a Jersey City campus
#' and later a Newark campus). For those, the \code{charter_host_apportionment}
#' table splits the charter's NJ-reported totals across host cities by a
#' \code{share} fraction that sums to 1.0 per \code{district_id} per
#' \code{end_year}. When a charter has an apportionment entry for the relevant
#' year, its single input row is expanded into one row per host city, the host
#' columns are overwritten from the apportionment table, and \code{share} is set
#' accordingly so downstream aggregations can multiply summed counts by
#' \code{share} before summing. The charter total is preserved exactly.
#'
#' The apportioned host assignment for these charters is an explicit, documented
#' apportionment of real NJ-reported totals (the 50/50 METS split is a
#' PLACEHOLDER), never an NJ-reported campus count. See
#' \code{\link{charter_host_apportionment}}.
#'
#' @param df dataframe of NJ school data containing a \code{district_id} (or
#'   \code{district_code}) column. If an \code{end_year} column is present,
#'   apportionment is applied year-aware; otherwise the apportionment shares are
#'   matched on \code{district_id} alone (use a year column for correct results
#'   when shares vary by year).
#'
#' @return df with host district id/name plus a \code{share} column (1.0 for
#'   single-host charters and non-charters; fractional for apportioned
#'   multi-campus charters) and an \code{is_apportioned} logical flag. Rows for
#'   apportioned charters are duplicated, one per host city.
#' @export

id_charter_hosts <- function(df) {
  if (!('district_id' %in% names(df) | 'district_code' %in% names(df))) {
    stop("supplied dataframe must contain 'district_id' or 'district_code'")
  }

  id_col <- if ('district_id' %in% names(df)) 'district_id' else 'district_code'

  charter_city_slim <- charter_city %>% select(-district_name)
  if (id_col == 'district_code') {
    names(charter_city_slim)[1] <- 'district_code'
  }

  # 1:1 host join (unchanged behavior for single-host charters / non-charters)
  df_new <- df %>% left_join(charter_city_slim, by = id_col)

  # guard the 1:1 join: it must NOT change the row count. Multi-host expansion
  # happens deliberately below, share-weighted, never via this join.
  if (nrow(df) != nrow(df_new)) {
    stop('joining to the charter hosts data set changed the size of your input dataframe.  this could be an issue with the `charter_city` dataframe included in this package.')
  }

  # default share = 1.0 (single host) and not-apportioned
  df_new <- df_new %>%
    mutate(share = 1.0, is_apportioned = FALSE)

  df_new <- apply_charter_apportionment(df_new, id_col = id_col)

  return(df_new)
}


#' Apply multi-campus charter host apportionment
#'
#' Internal helper for \code{\link{id_charter_hosts}}. For charters present in
#' \code{charter_host_apportionment}, expands the single NJ-reported row into one
#' row per host city (year-aware when \code{end_year} is present), overwriting
#' the host columns and setting \code{share}. Rows for charters without an
#' apportionment entry pass through unchanged with \code{share == 1.0}.
#'
#' The expansion is share-preserving: the shares for the rows produced from a
#' single input row always sum to 1.0, so multiplying any summed count by
#' \code{share} before aggregating preserves the charter's total.
#'
#' @param df output of the 1:1 host join, already carrying \code{share == 1.0}
#'   and \code{is_apportioned == FALSE}
#' @param id_col name of the district identifier column (\code{"district_id"} or
#'   \code{"district_code"})
#'
#' @return df with apportioned charters expanded share-weighted
#' @keywords internal

apply_charter_apportionment <- function(df, id_col = 'district_id') {

  appt <- charter_host_apportionment
  if (id_col == 'district_code') {
    names(appt)[names(appt) == 'district_id'] <- 'district_code'
  }

  has_year <- 'end_year' %in% names(df)
  appt_ids <- unique(appt[[id_col]])

  # rows that may be apportioned: charter rows whose id is in the table
  is_candidate <- df[[id_col]] %in% appt_ids
  if (!any(is_candidate)) {
    return(df)
  }

  passthrough <- df[!is_candidate, , drop = FALSE]
  candidates  <- df[is_candidate, , drop = FALSE]

  # join key: id (+ end_year when available so shares are year-correct)
  join_by <- id_col
  appt_slim <- appt %>%
    select(
      dplyr::all_of(id_col), end_year,
      host_county_id, host_county_name,
      host_district_id, host_district_name,
      share
    )
  if (has_year) {
    join_by <- c(id_col, 'end_year')
  } else {
    # no year column on input: apportionment shares may vary by year, so we
    # cannot pick a year. Fall back to the unapportioned 1:1 host assignment
    # (share == 1.0) rather than guess a year. This keeps results correct,
    # just unapportioned, for year-less inputs.
    return(df)
  }

  # tag each candidate input row so we can validate share-preservation per row
  candidates <- candidates %>%
    mutate(.appt_row_id = dplyr::row_number())

  # drop the placeholder host columns / share so the apportionment supplies them
  host_cols <- c('host_county_id', 'host_county_name',
                 'host_district_id', 'host_district_name', 'share')
  candidates_base <- candidates %>% select(-dplyr::all_of(host_cols))

  expanded <- candidates_base %>%
    dplyr::inner_join(appt_slim, by = join_by) %>%
    mutate(is_apportioned = TRUE)

  # candidate rows that had NO matching apportionment year keep their original
  # 1:1 host assignment (share == 1.0, is_apportioned == FALSE)
  matched_ids <- unique(expanded$.appt_row_id)
  unmatched <- candidates %>%
    dplyr::filter(!.appt_row_id %in% matched_ids) %>%
    select(-.appt_row_id)

  expanded <- expanded %>% select(-.appt_row_id)

  out <- dplyr::bind_rows(passthrough, unmatched, expanded)

  # share-preservation guard: for every apportioned input row the shares must
  # sum to 1.0. (Computed against the table to avoid carrying the row id out.)
  bad <- appt %>%
    group_by(dplyr::across(dplyr::all_of(join_by))) %>%
    summarize(total_share = sum(share), .groups = 'drop') %>%
    dplyr::filter(abs(total_share - 1.0) > 1e-9)
  if (nrow(bad) > 0) {
    stop('charter_host_apportionment shares do not sum to 1.0 for: ',
         paste(apply(bad, 1, paste, collapse = '/'), collapse = ', '))
  }

  out
}


#' Helper function to return aggregate enrollment columns in correct order
#'
#' @param df aggregate enrollment dataframe
#'
#' @return data.frame
#' @export

agg_enr_column_order <- function(df) {
  df %>%
    select(
      end_year, cds_code,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      program_code, program_name, grade_level,
      subgroup,
      n_students,
      pct_total_enr, 
      n_schools,
      is_state, is_county, 
      is_district, is_charter_sector, is_allpublic,
      is_school, 
      is_subprogram
    )
}

#' Helper function to support calculating pct_total on aggregate enr dataframes
#'
#' @param df aggregate enrollment dataframe
#'
#' @return data.frame
#' @export

agg_enr_pct_total <- function(df) {
  df_totals <- df %>% 
    filter(subgroup == 'total_enrollment') %>%
    select(end_year, district_id, program_code, n_students) %>%
    rename(row_total = n_students)
  
  # this calculation shouldn't generate duplicate rows
  nrow_before = nrow(df)
  nonuniques <- df %>%
    mutate(
      hash = paste(end_year, district_id, program_code, sep = '_')
    ) %>%
    pull(hash) %>%
    tabyl() %>% 
    arrange(-n) %>% 
    filter(n > 1)
  
  # join totals back to enable calculation of percentages
  df <- df %>%
    left_join(df_totals, by = c('end_year', 'district_id', 'program_code')) %>%
    mutate(
      'pct_total_enr' = n_students / row_total
    ) %>%
    select(-row_total)

  if (nrow(df) != nrow_before) {
    stop(sprintf('calculating percent of total changed the size of the sector_aggs dataframe.\n
      this suggests duplicate district_id/subgroup/year rows.\n
      offending year / district: %s', nonuniques))
  }

  df
}


#' Calculate Charter Sector Enrollment Aggregates
#'
#' @param df a tidied enrollment dataframe, eg output of `fetch_enr`
#'
#' @return dataframe with charter sector aggregates per host city
#' @export

charter_sector_enr_aggs <- function(df) {
   
   # id hosts 
   df <- id_charter_hosts(df)
   
   # charters are reported twice, one per school one per district
   # take the district level only, in the hopes that NJ will 
   # someday fix this and report charter campuses
   df_modern <- df %>% 
      filter(
         end_year >= 2010 & 
            county_id == 80 & 
            !district_id=='9999' & 
            school_id == '999'
      )
   df_old <- df %>%
      filter(
         end_year < 2010 &
            !district_id == '9999' &
            school_id == '999' &
            district_id >= "6000"
      )
   
   df <- bind_rows(df_modern, df_old)

   # group by - host city and summarize.
   # multi-campus charters are share-weighted: each apportioned charter
   # contributes share * n_students to each host city, so the charter total is
   # preserved exactly across host cities (e.g. METS 1000 -> 500 Jersey City +
   # 500 Newark). single-host charters and non-charters have share == 1.0.
   # n_schools is likewise share-weighted (fractional school-equivalents per
   # host city) so the sum across hosts equals the unapportioned school count.
   df <- df %>%
      group_by(
         end_year,
         host_county_id, host_county_name,
         host_district_id, host_district_name,
         program_code, program_name, grade_level,
         subgroup
      ) %>%
      summarize(
         n_students = sum(n_students * share, na.rm = TRUE),
         n_schools = sum(share, na.rm = TRUE)
      ) %>%
      ungroup()
   
   # give psuedo district names and codes and create appropriate boolean flags
   df <- df %>%
      rename(
         county_id = host_county_id,
         county_name = host_county_name
      ) %>%
      mutate(
         cds_code = NA_character_,
         district_id = paste0(host_district_id, 'C'),
         district_name = paste0(host_district_name, ' Charters'),
         school_id = '999C',
         school_name = 'Charter Sector Total',
         is_state = FALSE,
         is_county = FALSE,
         is_citywide = FALSE,
         is_district = FALSE,
         is_charter_sector = TRUE,
         is_allpublic = FALSE,
         is_school = FALSE,
         is_subprogram = !program_code == '55'
      ) %>%
      select(-host_district_id, -host_district_name)
   
   # calculate percent
   df <- agg_enr_pct_total(df)
   
   # column order and return
   agg_enr_column_order(df)
}



#' Calculate All Public Enrollment Aggregates
#'
#' @param df 
#'
#' @param df a tidied enrollment dataframe, eg output of `fetch_enr`
#'
#' @return dataframe with all public school option aggregates for any charter host city
#' @export

allpublic_enr_aggs <- function(df) {
  df <- df %>% ungroup()
  
  # id hosts 
  df <- id_charter_hosts(df)
  
  # if charter, make host_district_id the district id
  df <- df %>%
    mutate(
      is_charter = !is.na(host_district_id),
      county_id = ifelse(!is.na(host_county_id), host_county_id, county_id),
      district_id = ifelse(!is.na(host_district_id), host_district_id, district_id)
    )
  
  # take only district level rows (not school)
  # group by - newly modified county_id, district_id and summarize.
  # multi-campus charters are share-weighted into each host district so the
  # charter total is preserved across host cities; single-host charters and
  # non-charters have share == 1.0. n_schools is share-weighted likewise.
  df <- df %>%
    filter(is_district) %>%
    group_by(
      end_year,
      county_id, district_id,
      program_code, program_name, grade_level,
      subgroup
    ) %>%
    summarize(
      n_students = sum(n_students * share, na.rm = TRUE),
      n_schools = sum(share, na.rm = TRUE),
      n_charter = sum(is_charter, na.rm = TRUE)
    ) %>%
    ungroup()
  
  # if there are no charters in the host, out of scope for this calc
  df <- df %>%
    filter(n_charter > 0)
  
  # add county_name, district_name by joining to charter_city
  # join by both county_id and district_id to handle districts with same ID

  # in different counties (e.g., Franklin Township in Gloucester vs Somerset)
  ch_join <- charter_city %>%
    select(host_county_id, host_district_id, host_district_name, host_county_name) %>%
    rename(
      county_id = host_county_id,
      district_id = host_district_id,
      district_name = host_district_name,
      county_name = host_county_name
    ) %>%
    unique()

  df <- df %>%
    left_join(ch_join, by = c('county_id', 'district_id'))
  
  # give psuedo district names and codes
  # create appropriate boolean flag
  df <- df %>%
    mutate(
      cds_code = NA_character_,
      district_id = paste0(district_id, 'A'),
      district_name = paste0(district_name, ' All Public'),
      school_id = '999A',
      school_name = 'All Public Total',
      is_state = FALSE,
      is_county = FALSE,
      is_citywide = FALSE,
      is_district = FALSE,
      is_charter_sector = FALSE,
      is_allpublic = TRUE,
      is_school = FALSE,
      is_subprogram = !program_code == '55'
    ) 
  
  # calculate percent
  df <- agg_enr_pct_total(df)
  
  # column order and return
  agg_enr_column_order(df)  
}


#' Calculate Charter Sector PARCC aggregates
#'
#' @param df tidied PARCC dataframe, eg output of fetch_parcc
#'
#' @return df containing charter sector aggregate PARCC performance
#' @export

charter_sector_parcc_aggs <- function(df) {
  
  # id hosts 
  df <- id_charter_hosts(df) %>%
    mutate(
      is_charter = !is.na(host_district_id)
    )
  
  # charters are reported twice, one per school one per district
  # take the district level only, in the hopes that NJ will 
  # someday fix this and report charter campuses
  df <- df %>% 
    filter(county_id == '80' & !district_id=='9999' & is.na(school_id))
  
  # dfg isn't particularly meaningful and some charters are in the 
  # ND not determined bucket
  df <- df %>% mutate(dfg = NA)
  
  # group by - host city and summarize
  df <- df %>% 
    group_by(
      testing_year, 
      assess_name, test_name,
      host_county_id, host_county_name,
      host_district_id, host_district_name,
      dfg,
      grade, 
      subgroup, subgroup_type
    ) %>%
    parcc_aggregate_calcs() %>%
    ungroup()
  
  # give psuedo district names and codes and create appropriate boolean flags
  df <- df %>%
    rename(
      county_id = host_county_id,
      county_name = host_county_name
    ) %>%
    mutate(
      district_id = paste0(host_district_id, 'C'),
      district_name = paste0(host_district_name, ' Charters'),
      school_id = '999C',
      school_name = 'Charter Sector Total',
      is_state = FALSE,
      is_dfg = FALSE,
      is_district = FALSE,
      is_charter = FALSE,
      is_school = FALSE,      
      is_charter_sector = TRUE,
      is_allpublic = FALSE
    ) %>%
    select(-host_district_id, -host_district_name)
  
  # organize and return
  parcc_column_order(df) 
}


#' Calculate All Public Options PARCC Aggregates
#'
#' @param df tidied PARCC dataframe, eg output of fetch_parcc
#'
#' @return df containing all public option aggregates by district
#' @export

allpublic_parcc_aggs <- function(df) {

  # id hosts 
  df <- id_charter_hosts(df)
  
  # if charter, make host_district_id the district id
  df <- df %>%
    mutate(
      county_id = ifelse(!is.na(host_county_id), host_county_id, county_id),
      district_id = ifelse(!is.na(host_district_id), host_district_id, district_id)
    )
  
  # only district rows
  df <- df %>% filter(is_district)
  
  # dfg isn't particularly meaningful and some charters are in the 
  # ND not determined bucket
  df <- df %>% mutate(dfg = NA)
  
  # group by - newly modified county_id, district_id and summarize
  df <- df %>%
    group_by(
      testing_year,
      assess_name, test_name,
      county_id,
      district_id,
      dfg,
      grade,
      subgroup, subgroup_type
    ) %>%
    parcc_aggregate_calcs() %>%
    ungroup()
  
  # if there are no charters in the host, out of scope for this calc
  df <- df %>%
    filter(n_charter_rows > 0)
  
  # add county_name, district_name by joining to charter_city
  # join by both county_id and district_id to handle districts with same ID

  # in different counties (e.g., Franklin Township in Gloucester vs Somerset)
  ch_join <- charter_city %>%
    select(host_county_id, host_district_id, host_district_name, host_county_name) %>%
    rename(
      county_id = host_county_id,
      district_id = host_district_id,
      district_name = host_district_name,
      county_name = host_county_name
    ) %>%
    unique()

  df <- df %>%
    left_join(ch_join, by = c('county_id', 'district_id'))
  
  # give psuedo district names and codes
  # create appropriate boolean flag
  df <- df %>%
    mutate(
      district_id = paste0(district_id, 'A'),
      district_name = paste0(district_name, ' All Public'),
      school_id = '999A',
      school_name = 'All Public Total',
      is_state = FALSE,
      is_dfg = FALSE,
      is_district = FALSE,
      is_charter = FALSE,
      is_school = FALSE,  
      is_charter_sector = FALSE,
      is_allpublic = TRUE
    ) 
  
  # organize and return
  parcc_column_order(df) 
}


#' Calculate Charter Sector Grad Rate aggregates
#'
#' @param df tidied grate dataframe, eg output of fetch_grate
#'
#' @return df containing charter sector aggregate grad rate
#' @export

charter_sector_grate_aggs <- function(df) {

  # id hosts
  df <- id_charter_hosts(df)

  # charters are reported twice, one per school one per district
  # take the district level only, in the hopes that NJ will
  # someday fix this and report charter campuses
  # Note: school_id '999' was used pre-2021, '888' is used in 2021+ data
  df <- df %>%
    filter(county_id == '80' & !district_id=='9999' & school_id %in% c('888', '999'))
  
  # group by - host city and summarize
  df <- df %>% 
    group_by(
      end_year, 
      host_county_id, host_county_name,
      host_district_id, host_district_name,
      subgroup, methodology
    ) %>%
    grate_aggregate_calcs() %>%
    ungroup()
  
  # give psuedo district names and codes and create appropriate boolean flags
  df <- df %>%
    rename(
      county_id = host_county_id,
      county_name = host_county_name
    ) %>%
    mutate(
      district_id = paste0(host_district_id, 'C'),
      district_name = paste0(host_district_name, ' Charters'),
      school_id = '999C',
      school_name = 'Charter Sector Total',
      is_state = FALSE,
      is_district = FALSE,
      is_charter = FALSE,
      is_school = FALSE,      
      is_charter_sector = TRUE,
      is_allpublic = FALSE
    ) %>%
    select(-host_district_id, -host_district_name)
  
  # organize and return
  grate_column_order(df)
}


#'  Calculate All Public Grad Rate aggregates
#'
#' @param df tidied grate dataframe, eg output of fetch_grate
#'
#' @return df containing allpublic aggregate grad rate
#' @export

allpublic_grate_aggs <- function(df) {
  
  # id hosts 
  df <- id_charter_hosts(df)
  
  # if charter, make host_district_id the district id
  df <- df %>%
    mutate(
      county_id = ifelse(!is.na(host_county_id), host_county_id, county_id),
      district_id = ifelse(!is.na(host_district_id), host_district_id, district_id)
    )
  
  # only district rows
  df <- df %>% filter(is_district)
  
  # group by - newly modified county_id, district_id and summarize
  df <- df %>%
    group_by(
      end_year, 
      county_id,
      district_id,
      subgroup, 
      methodology
    ) %>%
    grate_aggregate_calcs() %>%
    ungroup()
  
  # if there are no charters in the host, out of scope for this calc
  df <- df %>%
    filter(n_charter_rows > 0)
  
  # add county_name, district_name by joining to charter_city
  # join by both county_id and district_id to handle districts with same ID

  # in different counties (e.g., Franklin Township in Gloucester vs Somerset)
  ch_join <- charter_city %>%
    select(host_county_id, host_district_id, host_district_name, host_county_name) %>%
    rename(
      county_id = host_county_id,
      district_id = host_district_id,
      district_name = host_district_name,
      county_name = host_county_name
    ) %>%
    unique()

  df <- df %>%
    left_join(ch_join, by = c('county_id', 'district_id'))
  
  # give psuedo district names and codes
  # create appropriate boolean flag
  df <- df %>%
    mutate(
      district_id = paste0(district_id, 'A'),
      district_name = paste0(district_name, ' All Public'),
      school_id = '999A',
      school_name = 'All Public Total',
      is_state = FALSE,
      is_dfg = FALSE,
      is_district = FALSE,
      is_charter = FALSE,
      is_school = FALSE,  
      is_charter_sector = FALSE,
      is_allpublic = TRUE
    ) 
  
  # organize and return
  grate_column_order(df) 
}


#' Calculate Charter Sector Grad Count aggregates
#'
#' @param df tidied grad count dataframe, eg output of fetch_grad_count
#'
#' @return df containing charter sector aggregate grad count
#' @export

charter_sector_gcount_aggs <- function(df) {

  # id hosts
  df <- id_charter_hosts(df)

  # charters are reported twice, one per school one per district
  # take the district level only, in the hopes that NJ will
  # someday fix this and report charter campuses
  # Note: school_id '999' was used pre-2021, '888' is used in 2021+ data
  df <- df %>%
    filter(county_id == '80' & !district_id=='9999' & school_id %in% c('888', '999'))
  
  # group by - host city and summarize
  df <- df %>% 
    group_by(
      end_year, 
      host_county_id, host_county_name,
      host_district_id, host_district_name,
      subgroup
    ) %>%
    gcount_aggregate_calcs() %>%
    ungroup()
  
  # give psuedo district names and codes and create appropriate boolean flags
  df <- df %>%
    rename(
      county_id = host_county_id,
      county_name = host_county_name
    ) %>%
    mutate(
      district_id = paste0(host_district_id, 'C'),
      district_name = paste0(host_district_name, ' Charters'),
      school_id = '999C',
      school_name = 'Charter Sector Total',
      is_state = FALSE,
      is_district = FALSE,
      is_charter = FALSE,
      is_school = FALSE,      
      is_charter_sector = TRUE,
      is_allpublic = FALSE
    ) %>%
    select(-host_district_id, -host_district_name)
  
  # organize and return
  gcount_column_order(df)
}


#' Calculate Charter Sector Grad Count aggregates
#'
#' @param df tidied grad count dataframe, eg output of fetch_grad_count
#'
#' @return df containing charter sector aggregate grad count
#' @export

allpublic_gcount_aggs <- function(df) {
  
  df <- df %>% ungroup()
  
  # id hosts 
  df <- id_charter_hosts(df)
  
  # if charter, make host_district_id the district id
  df <- df %>%
    mutate(
      county_id = ifelse(!is.na(host_county_id), host_county_id, county_id),
      district_id = ifelse(!is.na(host_district_id), host_district_id, district_id)
    )
  
  # only district rows
  df <- df %>% filter(is_district)
  
  # group by - newly modified county_id, district_id and summarize
  df <- df %>%
    group_by(
      end_year, 
      county_id,
      district_id,
      subgroup
    ) %>%
    gcount_aggregate_calcs() %>%
    ungroup()
  
  # if there are no charters in the host, out of scope for this calc
  df <- df %>%
    filter(n_charter_rows > 0)
  
  # add county_name, district_name by joining to charter_city
  # join by both county_id and district_id to handle districts with same ID

  # in different counties (e.g., Franklin Township in Gloucester vs Somerset)
  ch_join <- charter_city %>%
    select(host_county_id, host_district_id, host_district_name, host_county_name) %>%
    rename(
      county_id = host_county_id,
      district_id = host_district_id,
      district_name = host_district_name,
      county_name = host_county_name
    ) %>%
    unique()

  df <- df %>%
    left_join(ch_join, by = c('county_id', 'district_id'))
  
  # give psuedo district names and codes
  # create appropriate boolean flag
  df <- df %>%
    mutate(
      district_id = paste0(district_id, 'A'),
      district_name = paste0(district_name, ' All Public'),
      school_id = '999A',
      school_name = 'All Public Total',
      is_state = FALSE,
      is_dfg = FALSE,
      is_district = FALSE,
      is_charter = FALSE,
      is_school = FALSE,  
      is_charter_sector = FALSE,
      is_allpublic = TRUE
    ) 
  
  # organize and return
  gcount_column_order(df) 
}



#' Calculate Charter Sector Special Populations Aggregates
#'
#' @param df a tidied enrollment dataframe, eg output of 
#' `fetch_reportcard_special_pop`
#'
#' @return dataframe with charter sector aggregates per host city
#' @export
charter_sector_spec_pop_aggs <- function(df) {
  
  df <- df %>%
    id_charter_hosts()
  
  df <- df %>%
    mutate(is_charter = !is.na(host_district_id)) %>%
    filter(school_id != '999') %>%
    group_by(
      end_year, 
      host_county_id, host_county_name,
      host_district_id, host_district_name,
      subgroup
    ) %>%
    spec_pop_aggregate_calcs()
  
  # give psuedo district names and codes and create appropriate boolean flags
  df <- df %>%
    rename(
      county_id = host_county_id,
      county_name = host_county_name
    ) %>%
    mutate(
      district_id = paste0(host_district_id, 'C'),
      district_name = paste0(host_district_name, " Charters"),
      school_id = '999C',
      school_name = 'Charter Sector Total',
      is_district = FALSE,
      is_charter_sector = TRUE,
      is_allpublic = FALSE,
      is_school = FALSE
    ) %>%
    select(-host_district_id, -host_district_name)
  
  # column order and return
  df %>%
    agg_spec_pop_column_order() %>%
    return()
}


#' Calculate All City Special Populations aggregates
#'
#' @param df tidied grad count dataframe, eg output of 
#' `fetch_reportcard_special_pop``
#'
#' @return df with all city aggregates per host city
#' @export
allpublic_spec_pop_aggs <- function(df) {
  df <- df %>% 
    id_charter_hosts() %>%
    # if charter, make host_district_id the district_id
    mutate(
      is_charter = !is.na(host_district_id),
      district_id = ifelse(!is.na(host_district_id), host_district_id, district_id)
    )
  
  # take only district level rows (not school)
  # group by - newly modified county_id, district_id and summarize
  df <- df %>% 
    filter(district_id != '999') %>%
    group_by(
      end_year, 
      district_id,
      subgroup
    ) %>%
    spec_pop_aggregate_calcs() %>%
    ungroup()
  
  # if there are no charters in the host, out of scope for this calc
  df <- df %>%
    filter(n_charter_rows > 0)
  
  # add county_name, district_name by joining to charter_city
  # join by both county_id and district_id to handle districts with same ID

  # in different counties (e.g., Franklin Township in Gloucester vs Somerset)
  ch_join <- charter_city %>%
    select(host_county_id, host_district_id, host_district_name, host_county_name) %>%
    rename(
      county_id = host_county_id,
      district_id = host_district_id,
      district_name = host_district_name,
      county_name = host_county_name
    ) %>%
    unique()

  df <- df %>%
    left_join(ch_join, by = c('county_id', 'district_id'))
  
  # give psuedo district names and codes
  # create appropriate boolean flag
  df <- df %>%
    mutate(
      district_id = paste0(district_id, 'A'),
      district_name = paste0(district_name, ' All Public'),
      school_id = '999A',
      school_name = 'All Public Total',
      is_district = FALSE,
      is_charter_sector = FALSE,
      is_allpublic = TRUE,
      is_school = FALSE
    ) 
  
  # column order and return
  agg_spec_pop_column_order(df) %>%
    return()
}

#' Calculate Charter Sector SPED Aggregates
#'
#' @param df a tidied district special education dataframe, 
#' e.g. output of `fetch_sped`
#'
#' @return dataframe with charter sector aggregates per host city
#' @export
charter_sector_sped_aggs <- function(df) {
   
   # id hosts 
   df <- id_charter_hosts(df)
   
   # group by - host city and summarize
   df <- df %>% 
      mutate(is_charter = !is.na(host_district_id)) %>%
      group_by(
         end_year, 
         host_county_id, host_county_name,
         host_district_id, host_district_name
      ) %>%
      sped_aggregate_calcs() %>%
      ungroup()
   
   # give psuedo district names and codes and create appropriate boolean flags
   df <- df %>%
      rename(
         county_id = host_county_id,
         county_name = host_county_name
      ) %>%
      mutate(
         district_id = paste0(host_district_id, 'C'),
         district_name = paste0(host_district_name, " Charters"),
         school_id = '999C',
         school_name = 'Charter Sector Total',
         is_district = FALSE,
         is_charter_sector = TRUE,
         is_allpublic = FALSE,
         is_school = FALSE
      ) %>%
      select(-host_district_id, -host_district_name)
   
   # column order and return
   agg_sped_column_order(df) %>%
      return()
}


#' Calculate Charter Sector SPED aggregates
#'
#' @param df tidied grad count dataframe, eg output of fetch_sped
#'
#' @return df containing charter sector aggregate sped
#' @export
allpublic_sped_aggs <- function(df) {
   df <- df %>% ungroup()
   
   # id hosts 
   df <- id_charter_hosts(df)
   
   # if charter, make host_district_id the district id
   df <- df %>%
      mutate(
         is_charter = !is.na(host_district_id),
         district_id = ifelse(!is.na(host_district_id), host_district_id, district_id)
      )
   
   # take only district level rows (not school)
   # group by - newly modified county_id, district_id and summarize
   df <- df %>% 
      group_by(
         end_year, 
         district_id
      ) %>%
      sped_aggregate_calcs() %>%
      ungroup()
   
   # if there are no charters in the host, out of scope for this calc
   df <- df %>%
      filter(n_charter_rows > 0)
   
   # add county_name, district_name by joining to charter_city
   # join by both county_id and district_id to handle districts with same ID
   # in different counties (e.g., Franklin Township in Gloucester vs Somerset)
   ch_join <- charter_city %>%
      select(host_county_id, host_district_id, host_district_name, host_county_name) %>%
      rename(
         county_id = host_county_id,
         district_id = host_district_id,
         district_name = host_district_name,
         county_name = host_county_name
      ) %>%
      unique()

   df <- df %>%
      left_join(ch_join, by = c('county_id', 'district_id'))
   
   # give psuedo district names and codes
   # create appropriate boolean flag
   df <- df %>%
      mutate(
         district_id = paste0(district_id, 'A'),
         district_name = paste0(district_name, ' All Public'),
         school_id = '999A',
         school_name = 'All Public Total',
         is_district = FALSE,
         is_charter_sector = FALSE,
         is_allpublic = TRUE,
         is_school = FALSE
      ) 
   
   # column order and return
   agg_sped_column_order(df) %>%
      return()
}


#' Calculate Charter Sector postsecondary matriculation aggregates
#'
#' @param df tidied matriculation dataframe, eg output of 
#' enrich_matric_counts
#'
#' @return df containing charter sector matriculation aggregates
#' @export
charter_sector_matric_aggs <- function(df) {

  # id hosts
  df <- id_charter_hosts(df)

  # charters are reported twice, one per school one per district
  # take the district level only, in the hopes that NJ will
  # someday fix this and report charter campuses
  # Note: school_id '999' was used pre-2021, '888' is used in 2021+ data
  df <- df %>%
    filter(county_id == '80' & !district_id=='9999' & school_id %in% c('888', '999'))
  
  # group by - host city and summarize
  df <- df %>% 
    # 0s are reported as 0 -- distinct from NA
    # these are then schools w/ grad counts but no matric rates
    filter(!is.na(enroll_any)) %>%
    group_by(
      end_year, 
      host_county_id, host_county_name,
      host_district_id, host_district_name,
      is_16mo, subgroup
    ) %>%
    matric_aggregate_calcs() %>%
    ungroup()
  
  # give psuedo district names and codes and create appropriate boolean flags
  df <- df %>%
    rename(
      county_id = host_county_id,
      county_name = host_county_name
    ) %>%
    mutate(
      district_id = paste0(host_district_id, 'C'),
      district_name = paste0(host_district_name, ' Charters'),
      school_id = '999C',
      school_name = 'Charter Sector Total',
      is_state = FALSE,
      is_district = FALSE,
      is_charter = FALSE,
      is_school = FALSE,      
      is_charter_sector = TRUE,
      is_allpublic = FALSE
    ) %>%
    select(-host_district_id, -host_district_name)
  
  # organize and return
  matric_column_order(df)
}


#' Calculate All Public matriculation aggregates
#'
#' @param df tidied postsecondary matriculation dataframe, eg output 
#' of enrich_matric_counts()
#'
#' @return df containing all-public sector postsecondary matriculation rates
#' @export
allpublic_matric_aggs <- function(df) {
  
  df <- df %>% ungroup()
  
  # id hosts 
  df <- id_charter_hosts(df)
  
  # if charter, make host_district_id the district id
  df <- df %>%
    mutate(
      county_id = ifelse(!is.na(host_county_id), host_county_id, county_id),
      district_id = ifelse(!is.na(host_district_id), host_district_id, district_id)
    )
  
  # only district rows
  df <- df %>% filter(is_district)
  
  # group by - newly modified county_id, district_id and summarize
  agg_df <- df %>%
    # 0s are reported as 0 -- distinct from NA
    filter(!is.na(enroll_any)) %>%
    group_by(
      end_year, 
      county_id,
      district_id,
      is_16mo, subgroup
    ) %>%
    matric_aggregate_calcs() %>%
    ungroup()
  
  # if there are no charters in the host, out of scope for this calc
  agg_df <- agg_df %>%
    filter(n_charter_rows > 0)
  
  # add county_name, district_name by joining to charter_city
  # join by both county_id and district_id to handle districts with same ID
  # in different counties (e.g., Franklin Township in Gloucester vs Somerset)
  ch_join <- charter_city %>%
    select(host_county_id, host_district_id, host_district_name, host_county_name) %>%
    rename(
      county_id = host_county_id,
      district_id = host_district_id,
      district_name = host_district_name,
      county_name = host_county_name
    ) %>%
    unique()

  agg_df <- agg_df %>%
    left_join(ch_join, by = c('county_id', 'district_id'))
  
  # give psuedo district names and codes
  # create appropriate boolean flag
  agg_df <- agg_df %>%
    mutate(
      district_id = paste0(district_id, 'A'),
      district_name = paste0(district_name, ' All Public'),
      school_id = '999A',
      school_name = 'All Public Total',
      is_state = FALSE,
      is_dfg = FALSE,
      is_district = FALSE,
      is_charter = FALSE,
      is_school = FALSE,  
      is_charter_sector = FALSE,
      is_allpublic = TRUE
    ) 
  
  # organize and return
  matric_column_order(agg_df) 
}
