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
  
  nrow_before = nrow(df)
  df <- df %>%
    left_join(df_totals, by = c('end_year', 'district_id', 'program_code')) %>%
    mutate(
      'pct_total_enr' = n_students / row_total
    ) %>%
    select(-row_total)
  
  ensure_that(
    df, nrow(.) == nrow_before ~ 'calculating percent of total changed the size of the sector_aggs dataframe. this suggests duplicate district_id/subgroup/year rows'
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
      n_students = sum(n_students),
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
  # id hosts 
  df <- id_charter_hosts(df)
  
  # if charter, make host_district_id the district id
  df <- df %>%
    mutate(
      is_charter = !is.na(host_district_id),
      county_id = ifelse(!is.na(host_county_id), host_county_id, county_id),
      district_id = ifelse(!is.na(host_district_id), host_district_id, district_id)
    )
  
  # group by - newly modified county_id, district_id and summarize
  df <- df %>% 
    group_by(
      end_year, 
      county_id, district_id,
      program_code, program_name, grade_level,
      subgroup
    ) %>%
    summarize(
      n_students = sum(n_students),
      n_schools = n(),
      n_charter = sum(is_charter)
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
