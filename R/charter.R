#' Identify charter host districts
#'
#' @param df dataframe of NJ school data containing `district_id` column
#'
#' @return df with host district id and name for every matching record
#' @export

id_charter_hosts <- function(df) {
  ensure_that(
    df, 'district_id' %in% names(.) | 'district_code' %in% names(.) ~ 
      "supplied dataframe must contain 'district_id' or 'district_code'"
  )
  
  charter_city_slim <- charter_city %>% select(-district_name)
  
  if ('district_id' %in% names(df)) {
    df_new <- df %>% left_join(charter_city_slim, by = 'district_id')
  } else if ('district_code' %in% names(df)) {
    names(charter_city_slim)[1] <- 'district_code'
    df_new <- df %>% left_join(charter_city_slim, by = 'district_code')
  }

  ensure_that(
    df, nrow(.) == nrow(df_new) ~ 'joining to the charter hosts data set changed the size of your input dataframe.  this could be an issue with the `charter_city` dataframe included in this package.'
  )
  
  return(df_new)
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
      end_year, CDS_Code,
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
  
  ensure_that(
    df, nrow(.) == nrow_before ~ 
      sprintf('calculating percent of total changed the size of the sector_aggs dataframe.\n 
      this suggests duplicate district_id/subgroup/year rows.\n
      offending year / district: %s', nonuniques)
  )
  
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
        as.numeric(district_id) >= 6000
    )
  
  df <- bind_rows(df_modern, df_old)
  
  # group by - host city and summarize
  df <- df %>% 
    group_by(
      end_year, 
      host_county_id, host_county_name,
      host_district_id, host_district_name,
      program_code, program_name, grade_level,
      subgroup
    ) %>%
    summarize(
      n_students = sum(n_students, na.rm = TRUE),
      n_schools = n()
    ) %>%
    ungroup()

  # give psuedo district names and codes and create appropriate boolean flags
  df <- df %>%
    rename(
      county_id = host_county_id,
      county_name = host_county_name
    ) %>%
    mutate(
      CDS_Code = NA_character_,
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


#' Calculate Charter Sector Special Populations Aggregates
#'
#' @param df a tidied enrollment dataframe, eg output of 
#' `fetch_reportcard_special_pop`
#'
#' @return dataframe with charter sector aggregates per host city
#' @export

charter_sector_spec_pop_aggs <- function(df) {
   
   # id hosts 
   df <- id_charter_hosts(df)
   
   # group by - host city and summarize
   df <- df %>% 
      group_by(
         end_year, 
         host_county_id, host_county_name,
         host_district_id, host_district_name,
         subgroup
      ) %>%
      ##################################################
      ##################################################
      ## join enrollment numbers to aggregate percent ##
      ## issue #134
      summarize(
         n_students = sum(n_students, na.rm = TRUE),
         n_schools = n()
      ) %>%
      ungroup()
   
   # give psuedo district names and codes and create appropriate boolean flags
   df <- df %>%
      rename(
         county_id = host_county_id,
         county_name = host_county_name
      ) %>%
      mutate(
         CDS_Code = NA_character_,
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
  # group by - newly modified county_id, district_id and summarize
  df <- df %>% 
    filter(is_district) %>%
    group_by(
      end_year, 
      county_id, district_id,
      program_code, program_name, grade_level,
      subgroup
    ) %>%
    summarize(
      n_students = sum(n_students, na.rm = TRUE),
      n_schools = n(),
      n_charter = sum(is_charter, na.rm = TRUE)
    ) %>%
    ungroup()
  
  # if there are no charters in the host, out of scope for this calc
  df <- df %>%
    filter(n_charter > 0)
  
  # add county_name, district_name by joining to charter_city
  ch_join <- charter_city %>% 
    select(host_district_id, host_district_name, host_county_name) %>%
    rename(
      district_id = host_district_id,
      district_name = host_district_name,
      county_name = host_county_name
    ) %>%
    unique()
  
  df <- df %>%
    left_join(ch_join, by = 'district_id')
  
  # give psuedo district names and codes
  # create appropriate boolean flag
  df <- df %>%
    mutate(
      CDS_Code = NA_character_,
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
  ch_join <- charter_city %>% 
    select(host_district_id, host_district_name, host_county_name) %>%
    rename(
      district_id = host_district_id,
      district_name = host_district_name,
      county_name = host_county_name
    ) %>%
    unique()
  
  df <- df %>%
    left_join(ch_join, by = 'district_id')
  
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
  df <- df %>% 
    filter(county_id == '80' & !district_id=='9999' & school_id == '999')
  
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
      county_id, ,
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
  ch_join <- charter_city %>% 
    select(host_district_id, host_district_name, host_county_name) %>%
    rename(
      district_id = host_district_id,
      district_name = host_district_name,
      county_name = host_county_name
    ) %>%
    unique()
  
  df <- df %>%
    left_join(ch_join, by = 'district_id')
  
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
  df <- df %>% 
    filter(county_id == '80' & !district_id=='9999' & school_id == '999')
  
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
      county_id, ,
      district_id,
      subgroup
    ) %>%
    gcount_aggregate_calcs() %>%
    ungroup()
  
  # if there are no charters in the host, out of scope for this calc
  df <- df %>%
    filter(n_charter_rows > 0)
  
  # add county_name, district_name by joining to charter_city
  ch_join <- charter_city %>% 
    select(host_district_id, host_district_name, host_county_name) %>%
    rename(
      district_id = host_district_id,
      district_name = host_district_name,
      county_name = host_county_name
    ) %>%
    unique()
  
  df <- df %>%
    left_join(ch_join, by = 'district_id')
  
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
    id_charter_hosts() %>%
    # add gened enrollment from report card 
    enrich_rc_enrollment()
  
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
    enrich_rc_enrollment() %>%
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
  ch_join <- charter_city %>% 
    select(host_district_id, host_district_name, host_county_name) %>%
    rename(
      district_id = host_district_id,
      district_name = host_district_name,
      county_name = host_county_name
    ) %>%
    unique()
  
  df <- df %>%
    left_join(ch_join, by = 'district_id')
  
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