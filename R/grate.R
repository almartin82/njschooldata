#' @title process grate
#'
#' @description does cleanup of the grad rate ('grate') file
#' @param df the output of get_raw_grad_file
#' @param end_year a school year.  year is the end of the academic year - eg 2006-07
#' school year is year '2007'.  valid values are 1998-2018.
#' @export

process_grate <- function(df, end_year) {
  #clean up names
  names(df)[names(df) %in% c('COUNTY', 'CO', 'CO NAME', 'CO_NAME', 'County Name', 'COUNTY_NAME')] <- 'county_name'
  names(df)[names(df) %in% c('DISTRICT', 'DIST', 'DIST NAME', 'DIS_NAME', 'District Name', 'DISTRICT_NAME')] <- 'district_name'
  names(df)[names(df) %in% c('SCHOOL', 'SCH', 'SCH NAME', 'SCH_NAME', 'School Name', 'SCHOOL_NAME')] <- 'school_name'

  #oh, man.  in 1998 and 1999 PROG_CODE is program code.  in 2008 PROG_CODE is...
  #actually PROG_NAME.  guys, seriously.
  if (end_year == 2008) {
    names(df)[names(df) %in% c('PROG_CODE')] <- 'program_name'
  } else {
    names(df)[names(df) %in% c('PROG CODE', 'PROG_CODE')] <- 'program_code'
  }
  names(df)[names(df) %in% c('PROGNAME', 'PROG', 'PROG NAME')] <- 'program_name'

  names(df)[names(df) %in% c('COUNTY_CODE', 'CO CODE', 'County', 'County Code', 'COUNTY_ID', 'Co Code')] <- 'county_id'
  names(df)[names(df) %in% c('DISTRICT_CODE', 'DIST CODE', 'District', 'District Code', 'DISTRICT_ID', 'Dist Code')] <- 'district_id'
  names(df)[names(df) %in% c('SCHOOL_CODE', 'SCH CODE', 'School', 'School Code', 'SCHOOL_CODE')] <- 'school_id'

  #errata
  names(df)[names(df) %in% c('HISP_MALE')] <- 'hispanic_m'
  names(df)[names(df) %in% c("NAT_AM-F", 'NAT_F', 'NAT_AM_F(NON_HISP)')] <- 'native_american_f'
  names(df)[names(df) %in% c('NAT_M', 'NAT_AM_M(NON_HISP)')] <- 'native_american_m'

  #oh, 2007...
  names(df)[names(df) %in% c('ROWTOT')] <- 'rowtotal'
  names(df)[names(df) %in% c('WH_M')] <- 'white_m'
  names(df)[names(df) %in% c('WH_F')] <- 'white_f'
  names(df)[names(df) %in% c('BL_M')] <- 'black_m'
  names(df)[names(df) %in% c('BL_F')] <- 'black_f'
  names(df)[names(df) %in% c('HISP_M', 'HISPANIC_M')] <- 'hispanic_m'
  names(df)[names(df) %in% c('HISP_F', 'HISPANIC_F')] <- 'hispanic_f'
  names(df)[names(df) %in% c('NAT_AM_M')] <- 'native_american_m'
  names(df)[names(df) %in% c('NAT_AM_F')] <- 'native_american_f'
  names(df)[names(df) %in% c('ASIAN_M(NON_HISP)')] <- 'asian_m'
  names(df)[names(df) %in% c('ASIAN_F(NON_HISP)')] <- 'asian_f'
  names(df)[names(df) %in% c('HAW_NTV_M(NON_HISP)', 'HWN_NAT_M')] <- 'pacific_islander_m'
  names(df)[names(df) %in% c('HAW_NTV_F(NON_HISP)', 'HWN_NAT_F')] <- 'pacific_islander_f'
  names(df)[names(df) %in% c('2/MORE_RACES_M(NON_HISP)', '2_MORE_M')] <- 'multiracial_m'
  names(df)[names(df) %in% c('2/MORE_RACES_F(NON_HISP)', '2_MORE_F')] <- 'multiracial_f'

  names(df)[names(df) %in% c('SUBGROUP', 'Subgroup')] <- 'group'
  names(df)[names(df) %in% c(
    'Four Year Graduation Rate',
    '2011 Adjusted Cohort Grad Rate',
    '2012 Adjusted Cohort Grad Rate',
    'FOUR_YR_GRAD_RATE'
  )] <- 'grad_rate'
  names(df)[names(df) %in% c('Four Year Adjusted Cohort Count', 'FOUR_YR_ADJ_COHORT_COUNT')] <- 'cohort_count'
  names(df)[names(df) %in% c('Four Year Graduates Count', 'GRADUATED_COUNT')] <- 'graduated_count'

  names(df) <- names(df) %>% tolower()

  numeric_cols <- c("rowtotal", "female", "male",
    "white", "black", "hispanic", "native_american",
    "asian", "pacific_islander", "multiracial",
    "white_m", "white_f", "black_m", "black_f",
    "hispanic_m", "hispanic_f", "native_american_m", "native_american_F",
    "asian_m", "asian_f", "pacific_islander_m", "pacific_islander_f",
    "multiracial_m", "multiracial_f",
    "instate", "outstate",
    "grad_rate", "cohort_count", "graduated_count"
  )

  for (i in numeric_cols) {
    if (i %in% names(df)) {
      df[, i] <- df %>% dplyr::pull(i) %>% as.numeric()
    }
  }

  #county distr sch codes
  if (end_year <= 2008) {

    #county_id and county_name
    int_matrix <- stringr::str_split_fixed(df$county_name, "-", 2)
    df$county_id <- int_matrix[, 1]
    df$county_name <- int_matrix[, 2]

    #district_id and ditrict_name
    int_matrix <- stringr::str_split_fixed(df$district_name, "-", 2)
    df$district_id <- int_matrix[, 1]
    df$district_name <- int_matrix[, 2]

    #school_id and school_name
    int_matrix <- stringr::str_split_fixed(df$school_name, "-", 2)
    df$school_id <- int_matrix[, 1]
    df$school_name <- int_matrix[, 2]

  }

  #missing program names
  if (end_year %in% c(1998, 1999)) {
    old_codes <- data.frame(
      program_code = c('1', '2', '3', '4', '5', '6', '7', '8', '9'),
      program_name = c(
        '4 Year College', '2 Year College', 'Other College', 'Post-Secondary',
        'Employment', 'Unemployment', 'Other', 'Status Unknown', 'Total'),
      stringsAsFactors = FALSE
    )
    #ugh
    df$program_code <- df$program_code %>% as.character()
    df <- df %>% dplyr::left_join(old_codes, by = 'program_code')
  }

  #clean up values
  if ('program_name' %in% names(df)) {
    df$program_name <- ifelse(df$program_name %in% c('Total', 'TOTAL'), 'Total', df$program_name)
  }

  df <- df %>%
     mutate(school_id = case_when(school_id == "999.000000" ~ "999",
                                  school_id == "888" & end_year == 2019 ~ "999",
                                  TRUE ~ school_id))

  df$district_id <- ifelse(df$district_id == "9999.000000", "999", df$district_id)

  if ('grad_rate' %in% names(df)) {
    if (all(df$grad_rate <= 1 | is.na(df$grad_rate))) {
      df$grad_rate <- df$grad_rate * 100
    }
    df$grad_rate <- df$grad_rate / 100 %>% round(2)
  }

  return(df)
}



#' @title tidy grad rate
#'
#' @description tidies a processed grate data frame, producing a data frame with consistent
#' headers and values, suitable for longitudinal analysis
#' @param df the output of process_grad_rate
#' @param end_year a school year.  year is the end of the academic year - eg 2006-07
#' school year is year '2007'.  valid values are 1998-2018.
#' @param methodology one of '4 year' or '5 year'

tidy_grad_rate <- function(df, end_year, methodology = '4 year') {

  grate_col <- function(col_name, nj_df) {
    nj_df <- nj_df %>% as.data.frame(stringsAsFactors = FALSE)

    mask <- grepl(col_name, names(nj_df))
    if (sum(mask) > 1) stop("tidying grate data matched more than one column")

    if (all(mask == FALSE)) {
      out <- rep(NA, nrow(nj_df))
    } else {
      out <- nj_df[, mask, drop = TRUE]
    }
    return(out)
  }


  tidy_old_format <- function(sch_subset) {

    #constants
    constant_df <- data.frame(
      county_id = grate_col('county_id', sch_subset) %>% unique(),
      county_name = grate_col('county_name', sch_subset) %>% unique(),

      district_id = grate_col('district_id', sch_subset) %>% unique(),
      district_name = grate_col('district_name', sch_subset) %>% unique(),

      school_id = grate_col('school_id', sch_subset) %>% unique(),
      school_name = grate_col('school_name', sch_subset) %>% unique(),

      grad_cohort = grate_col('grad_cohort', sch_subset) %>% unique(),
      year_reported = grate_col('year_reported', sch_subset) %>% unique(),
      methodology = grate_col('methodology', sch_subset) %>% unique(),
      time_window = grate_col('time_window', sch_subset) %>% unique(),

      stringsAsFactors = FALSE
    )

    #build composites
    sch_subset$white <- sch_subset %$% add(white_m, white_f)
    sch_subset$black <- sch_subset %$% add(black_m, black_f)
    sch_subset$hispanic <- sch_subset %$% add(hisp_m, hisp_f)
    sch_subset$american_indian <- sch_subset %$% add(nat_am_m, nat_am_f)
    sch_subset$asian <- sch_subset %$% add(asian_m, asian_f)

    #force NA for some subgroups if not present
    sch_subset$hwn_nat_m <- grate_col('hwn_nat_m', sch_subset)
    sch_subset$hwn_nat_f <- grate_col('hwn_nat_f', sch_subset)
    sch_subset$pacific_islander <- sch_subset %$% add(hwn_nat_m, hwn_nat_f)

    sch_subset$multiracial_m <- grate_col('multiracial_m', sch_subset)
    sch_subset$multiracial_f <- grate_col('multiracial_f', sch_subset)
    sch_subset$multiracial <- sch_subset %$% add(multiracial_m, multiracial_f)

    sch_subset$female <- rowSums(
      cbind(
        sch_subset$white_f, sch_subset$black_f, sch_subset$hisp_f,
        sch_subset$nat_am_f, sch_subset$asian_f, sch_subset$hwn_nat_f,
        sch_subset$multiracial_f
      ), na.rm = TRUE)
    sch_subset$male <- rowSums(
      cbind(
        sch_subset$white_m, sch_subset$black_m, sch_subset$hisp_m,
        sch_subset$nat_am_m, sch_subset$asian_m, sch_subset$hwn_nat_m,
        sch_subset$multiracial_m
      ), na.rm = TRUE)

    #force code if missing
    sch_subset$program_code <- grate_col('program_code', sch_subset)

    #rowtotal is actually total population
    names(sch_subset)[names(sch_subset) == 'rowtotal'] <- 'total_population'

    to_tidy <- c(
      "program_name", "program_code",

      "total_population",
      "female", "male",

      "white", "black", "hispanic", "american_indian",
      "asian", "pacific_islander", "multiracial",

      "white_m", "white_f",
      "black_m", "black_f",
      "hisp_m", "hisp_f",
      "nat_am_m", "nat_am_f",
      "asian_m", "asian_f",
      "hwn_nat_m", "hwn_nat_f",
      "multiracial_m", "multiracial_f",

      "instate", "outstate"
    )
    col_mask <- names(sch_subset) %in% to_tidy
    row_mask <- sch_subset$program_name == 'Total'

    sch_to_tidy <- sch_subset[, col_mask]
    #reorder
    sch_to_tidy <- sch_to_tidy[to_tidy]

    sch_programs <- sch_to_tidy[!row_mask,]
    sch_total <- sch_to_tidy[row_mask, ]
    #sometimes (thanks MCVS HEALTH OCCUP CENT) there is no TOTAL field
    if (nrow(sch_total) == 0) {
      print('no TOTAL row for:')
      paste(constant_df$district_name, constant_df$school_name) %>% print()
      sch_total <- colSums(sch_programs[, 3:26]) %>%
        t() %>%
        as.data.frame(stringsAsFactors = FALSE)
      sch_total$program_name <- 'Total'
      sch_total$program_code <- NA
      sch_total$instate <- NA
      sch_total$outstate <- NA
      #reorder
      sch_total <- sch_total[to_tidy]
      sch_to_tidy <- rbind(sch_to_tidy, sch_total)
    }

    old_tidy_list <- list()

    #all the subgroups
    for (j in to_tidy[3:26]) {
      to_pivot <- sch_to_tidy[ , c(to_tidy[1:2], j)]
      sub_long <- reshape2::melt(to_pivot, id.vars = c('program_name', 'program_code'))
      sub_long$variable <- as.character(sub_long$variable)
      names(sub_long)[names(sub_long) == 'variable'] <- 'group'
      names(sub_long)[names(sub_long) == 'value'] <- 'outcome_count'

      sub_long$num_grad <- sub_long[sub_long$program_name == 'Total', 'outcome_count']
      sub_long$postgrad_grad <- ifelse(sub_long$program_name == 'Total', 'grad', 'postgrad')
      sub_long$level <- ifelse(constant_df$school_id == '999', 'D', 'S')
      sub_long$grad_rate <- NA
      sub_long$cohort_count <- NA

      old_tidy_list[[j]] <- cbind(constant_df, sub_long)
    }

    out <- dplyr::rbind_all(old_tidy_list)

    return(out)
  }


  clean_grate_names <- function(name_vector) {

    name_vector <- ifelse(name_vector == 'American Indian', 'american_indian', name_vector)
    name_vector <- ifelse(name_vector == 'Native Hawaiian', 'pacific_islander', name_vector)
    name_vector <- ifelse(name_vector == 'Two or More Races', 'multiracial', name_vector)
    name_vector <- ifelse(name_vector == 'Limited English Proficiency', 'lep', name_vector)
    name_vector <- ifelse(
      name_vector == 'Economically Disadvantaged', 'economically_disadvantaged', name_vector
    )
    name_vector <- ifelse(name_vector == 'Students with Disability', 'iep', name_vector)
    name_vector <- ifelse(name_vector == 'Schoolwide', 'total population', name_vector)
    name_vector <- ifelse(name_vector == 'Districtwide', 'total population', name_vector)
    name_vector <- ifelse(name_vector == 'Statewide Total', 'total population', name_vector)

    name_vector
  }


  tidy_new_format <- function(df) {
    names(df)[names(df) %in% c(
      '2012 5 -year adj cohort grad rate',
      "cohort 2015 5 year graduation rate",
      "cohort 2016 5 year graduation rate",
      'class of 2017 5-year graduation rate',
      "cohort 2018 5-year graduation rate"
    )] <- 'grad_rate'

    if (class(df$grad_rate) == "character") {
       df$grad_rate <- as.numeric(df$grad_rate) / 100
    }

    if (!'cohort_count' %in% names(df)) {
      df$cohort_count <- NA_integer_
    }
    if (!'program_name' %in% names(df)) {
      df$program_name <- 'Total'
      df$program_code <- NA
      df$outcome_count <- NA
      df$postgrad_grad <- 'grad'
    }

    if (!'graduated_count' %in% names(df)) {
      df$graduated_count <- NA
    }

    if (!'group' %in% names(df)) {
      df$group <- 'total population'
    }
    df$group <- tolower(df$group)

    return(df)
  }

  #old method (pre-cohort)
  if (end_year < 2011) {
    #iterate over the sch/district totals
    df$iter_key <- paste0(df$county_id, '@', df$district_id, '@', df$school_id)
    sch_list <- list()

    for (i in df$iter_key %>% unique()) {
      this_sch <- df %>% dplyr::filter(iter_key == i)
      sch_list[[i]] <- tidy_old_format(this_sch)
    }

    out <- dplyr::rbind_all(sch_list)
  #cohort 2011-2012 didn't report subgroups method (different file structure)
  } else if (end_year %in%  c(2011, 2012)) {
    out <- tidy_new_format(df)
  #2013 shifted to long format
  } else if (end_year >= 2013) {
    # 5 year doesn't have group
    if (methodology == '5 year') {
      df <- tidy_new_format(df)
    }
    df$group <- tolower(df$group)
    df$group <- clean_grate_names(df$group)
    out <- df
  }

  # 2018 and 2019 silly row
  out <- out %>% filter(!county_id == 'end of worksheet')

  out$group <- grad_file_group_cleanup(out$group)
  out <- out %>%
    rename(subgroup = group)

  return(out)
}


#' grad file group cleanup
#'
#' @param group column of group (subgroup) data from NJ grad file
#'
#' @return  column cleaned up subgroup

grad_file_group_cleanup <- function(group) {
  case_when(
    group %in% c('american indian or alaska native', 'american_indian') ~ 'american indian',
    group %in% c('black or african american') ~ 'black',
    group %in% c('economically_disadvantaged',
                 'economically disadvantaged students') ~ 'economically disadvantaged',
    group %in% c('english learners', 'limited_english_proficiency') ~ 'limited english proficiency',
    group %in% c('two or more race', 'two_or_more_races', 'two or more races') ~ 'multiracial',
    group %in% c('native hawaiian or pacific islander', 'pacific_islander', 'native_hawaiian') ~ 'pacific islander',
    group %in% c('asian, native hawaiian, or pacific islander') ~ 'asian', # 2019 groups a and pi together?!
    group %in% c('students with disabilities', 'students_with_disability') ~ 'students with disability',
    group %in% c('districtwide', 'schoolwide',
                 'statewide total', 'statewide_total', 'statewide',
                 'total_population') ~ 'total population',
    # c('homeless students', 'homeless')
    # c('students in foster care', 'foster care')
    # c('migrant students')

    TRUE ~ group
  )
}

#' Get a raw graduation file from the NJ website
#'
#' @param end_year end of the academic year - eg 2006-07 is 2007.
#' valid values are 1998-present.
#' @param methodology one of c('4 year', '5 year')
#'
#' @return data.frame with raw data from state file
#' @export

get_raw_grad_file <- function(end_year, methodology = '4 year') {

  if (end_year < 1998 | end_year > 2019) {
    stop('year not yet supported')
  }

  ########## 4 year ##########
   if (methodology == '4 year') {
      # before cohort grad rate
      if (end_year <= 2010) {
         grd_constant <- "https://www.state.nj.us/education/data/grd/grd"
         grate_file <- paste0(grd_constant, substr(end_year + 1, 3, 4), "/grd.zip") %>%
            unzipper()

         if (grepl('.csv', tolower(grate_file))) {
            df <- read_csv(grate_file)
         } else if (grepl('.xls', tolower(grate_file))) {
            df <- readxl::read_xls(grate_file)
         }

      # 2011 is insane, no other way to describe it
      } else if (end_year == 2011) {
         grate_url <- 'https://www.state.nj.us/education/data/grate/2012/gradrate.xls'
         grate_file <- tempfile(fileext = ".xls")
         httr::GET(url = grate_url, httr::write_disk(grate_file))
         df <- readxl::read_excel(grate_file)

         grate_indices <- c(1:7, 9)
         df <- df[, grate_indices] %>%
            mutate(
               'GRADUATED_COUNT' = NA_integer_
            )

      # 2012 they transition the format but post it in a weird location
      } else if (end_year == 2012) {
         grate_url <- 'https://www.state.nj.us/education/data/grate/2012/grd.xls'
         grate_file <- tempfile(fileext = ".xls")
         httr::GET(url = grate_url, httr::write_disk(grate_file))
         df <- readxl::read_excel(grate_file)

      # 2013 on is the cohort grad rate era
      } else if (end_year >= 2013 & end_year <= 2018) {
         #build url
         basic_suffix <- "/4Year.xlsx"
         num_skip <- 0

         if (end_year >= 2018) {
            basic_suffix <- "/4YearGraduation.xlsx"
            num_skip <- 3
         }

         grate_url <- paste0("http://www.state.nj.us/education/data/grate/", end_year, basic_suffix)
         grate_file <- tempfile(fileext = ".xlsx")
         httr::GET(url = grate_url, httr::write_disk(grate_file))
         df <- readxl::read_excel(grate_file, skip = num_skip)

      } else { # if year == 2019
         # new location!
         grate_url <- "https://www.nj.gov/education/schoolperformance/grad/data/ACGR2019_Cohort%202019%204-Year%20Adjusted%20Cohort%20Graduation%20Rates%20by%20Student%20Group.xlsx"
         num_skip <- 3
         grate_file <- tempfile(fileext = ".xlsx")
         httr::GET(url = grate_url, httr::write_disk(grate_file))
         df <- readxl::read_excel(grate_file, skip = num_skip)
      }

   ########## 5 year ##########
   } else if (methodology == '5 year') {

      if (end_year < 2012) {
         stop(paste0('5 year grad rate not available for ending year ', end_year))

      }  else if (end_year <= 2014) {
         #build url
         grate_url <- paste0(
            "http://www.state.nj.us/education/data/grate/", end_year + 1,
            "/4And5YearCohort", substr(end_year, 3, 4), ".xlsx"
         )
         num_skip <- 0

      } else if (end_year == 2015) {
         grate_url <- 'https://www.state.nj.us/education/data/grate/2016/4And5YearCohort14.xlsx'
         num_skip <- 0

      } else if (end_year == 2016) {
         grate_url <- 'https://www.state.nj.us/education/data/grate/2017/4And5YearCohort.xlsx'
         num_skip <- 0

      } else if (end_year == 2017) {
         grate_url <- paste0(
            "http://www.state.nj.us/education/data/grate/", end_year + 1,
            "/4and5YearGraduationRates.xlsx"
         )
         num_skip <- 3

      } else { # if (end_year == 2018) {
         grate_url <- "https://www.nj.gov/education/schoolperformance/grad/data/ACGR2019_Cohort%202018%204-Year%20and%205-Year%20Adjusted%20Cohort%20Graduation%20Rates.xlsx"
         num_skip <- 3
      }

      grate_file <- tempfile(fileext = ".xlsx")
      httr::GET(url = grate_url, httr::write_disk(grate_file))
      df <- readxl::read_excel(grate_file, skip = num_skip)
   } else {
      stop(paste0("invalid methodology: ", methodology))
   }

  df$end_year <- end_year

  df
}


#' Identify enrollment aggregation levels
#'
#' @param df enrollment dataframe, output of tidy_enr
#'
#' @return data.frame with boolean aggregation flags
#' @export

id_grad_aggs <- function(df) {
  df %>%
    mutate(
      is_state = district_id == '9999' & county_id == '99',
      is_county = district_id == '9999' & !county_id =='99',
      is_district = school_id %in% c('997', '999') & !is_state,
      is_charter_sector = FALSE,
      is_allpublic = FALSE,
      is_school = !school_id %in% c('997', '999') & !is_state,
      is_charter = county_id == '80'
    ) %>%
      return()
}


#' Get NJ graduation count data
#'
#' @param end_year end of the academic year - eg 2006-07 is 2007.
#' valid values are 1998-present.
#'
#' @return dataframe with the number of graduates per school and district

get_grad_count <- function(end_year) {
   if (end_year < 2012 | end_year > 2019)
      stop(paste0(end_year, " not yet supported."))

  df <- get_raw_grad_file(end_year)

  df %>%
    process_grate(end_year)
}


#' Process Grad Count Data
#'
#' @param df output of get_grad_count
#' @param end_year end of the academic year
#'
#' @return dataframe with composite subgroups like black (black_m + black_f)

process_grad_count <- function(df, end_year) {

  if (end_year <= 2010) {
    sg <- function(cols) {
      cols_exist <- map_lgl(cols, ~.x %in% names(df)) %>% all()
      ifelse(cols_exist, paste(cols, collapse = ' + '), 'NA')
    }

    possible_m <- c(
      'white_m', 'black_m', 'hispanic_m',
      'asian_m', 'native_american_m', 'pacific_islander_m', 'multiracial_m'
    )
    valid_m <- possible_m[possible_m %in% names(df)]
    valid_m <- paste(valid_m, collapse = '+')

    possible_f <- c(
      'white_f', 'black_f', 'hispanic_f',
      'asian_f', 'native_american_f', 'pacific_islander_f', 'multiracial_f'
    )
    valid_f <- possible_f[possible_f %in% names(df)]
    valid_f <- paste(valid_f, collapse = '+')

    out <- df %>%
      group_by(
        end_year,
        county_id, county_name,
        district_id, district_name,
        school_id, school_name
      ) %>%
      filter(program_name == 'Total') %>%
      mutate(
        male = !!rlang::parse_expr(valid_m),
        female = !!rlang::parse_expr(valid_f),

        white = !!rlang::parse_expr(sg(c('white_m', 'white_f'))),
        black = !!rlang::parse_expr(sg(c('black_m', 'black_f'))),
        hispanic = !!rlang::parse_expr(sg(c('hispanic_m', 'hispanic_f'))),
        asian = !!rlang::parse_expr(sg(c('asian_m', 'asian_f'))),
        native_american = !!rlang::parse_expr(sg(c('native_american_m', 'native_american_f'))),
        pacific_islander = !!rlang::parse_expr(sg(c('pacific_islander_m', 'pacific_islander_f'))),
        multiracial =  !!rlang::parse_expr(sg(c('multiracial_m', 'multiracial_f')))
      ) %>%
      rename(
        row_total = rowtotal
      )

    if ('instate' %in% names(out)) out <- out %>% select(-instate)
    if ('outstate' %in% names(out)) out <- out %>% select(-outstate)

  } else {
    out <- df
  }

  out
}


#' Tidy Grad Count
#'
#' @param df output of process_grad_count
#' @param end_year end of the academic year - eg 2006-07 is 2007.
#' valid values are 1998-present.
#'
#' @return data.frame with number of graduates

tidy_grad_count <- function(df, end_year) {

  if (end_year <= 2010) {
    # invariant cols
    invariants <- c(
      'end_year',
      'county_id', 'county_name',
      'district_id', 'district_name',
      'school_id', 'school_name'
    )

    # cols to tidy
    to_tidy <- c(
      'male',
      'female',
      'white',
      'black',
      'hispanic',
      'asian',
      'native_american',
      'pacific_islander',
      'multiracial',
      'white_m',
      'white_f',
      'black_m',
      'black_f',
      'hispanic_m',
      'hispanic_f',
      'asian_m',
      'asian_f',
      'native_american_m',
      'native_american_f',
      'pacific_islander_m',
      'pacific_islander_f',
      'multiracial_m',
      'multiracial_f'
    )

    # limit to cols in df
    to_tidy <- to_tidy[to_tidy %in% names(df)]

    # iterate over cols to tidy, do calculations
    tidy_subgroups <- map_df(
      to_tidy,
      function(.x) {
        df %>%
          rename(n_students = .x) %>%
          select(one_of(invariants, 'n_students', 'row_total')) %>%
          mutate(
            'subgroup' = .x,
            'pct' = n_students / row_total
          ) %>%
          select(one_of(invariants, 'subgroup', 'n_students', 'pct'))
      }
    )

    # also extract row total as a "subgroup"
    tidy_total_enr <- df %>%
      select(one_of(invariants, 'row_total')) %>%
      mutate(
        'n_students' = row_total,
        'subgroup' = case_when(
          school_id == '999' ~ 'statewide_total',
          school_id == '997' ~ 'districtwide',
          TRUE ~ 'schoolwide'
        ),
        'pct' = n_students / row_total
      ) %>%
      select(one_of(invariants, 'subgroup', 'n_students', 'pct'))

    # put it all together in a long data frame
    out <- bind_rows(tidy_subgroups, tidy_total_enr) %>%
      rename(
        graduated_count = n_students
      )

  } else if (end_year == 2011) {
    out <- df %>% mutate(subgroup = 'total population')
  } else if (end_year >= 2012) {

    df$group <- grad_file_group_cleanup(tolower(df$group))

    out <- df %>%
      mutate(group = gsub(' ', '_', tolower(group))) %>%
      rename(subgroup = group)
  }

  # 2018 silly row
  out <- out %>% filter(!county_id == 'end of worksheet')

  out$subgroup <- grad_file_group_cleanup(out$subgroup)

  return(out)
}


#' Fetch Grad Counts
#'
#' @param end_year end of the academic year - eg 2006-07 is 2007.
#' valid values are 1998-present.
#'
#' @return dataframe with grad counts
#' @export

fetch_grad_count <- function(end_year) {
    df <- get_grad_count(end_year) %>%
      process_grad_count(end_year)

    df <- tidy_grad_count(df, end_year)

    df <- id_grad_aggs(df)

    possible_cols <- c(
      'end_year',
      'county_id', 'county_name',
      'district_id', 'district_name',
      'school_id', 'school_name',
      'subgroup',
      'cohort_count', 'graduated_count',
      'is_state',
      'is_county',
      'is_district',
      'is_charter_sector',
      'is_allpublic',
      'is_school',
      'is_charter'
    )

    df <- df %>%
      select(one_of(possible_cols))

    return(df)
}


#' Get NJ graduation rate data
#'
#' @param end_year end of the academic year - 2011-2012 is 2012
#' valid values are 2011-present.
#'
#' @return dataframe with the number of graduates per school and district
#' @export

get_grad_rate <- function(end_year, methodology) {
  if (end_year < 2011 | end_year > 2019) {
    stop('year not yet supported')
  }

  df <- get_raw_grad_file(end_year, methodology) %>%
    mutate(
      'methodology' = methodology
    )

  df %>%
    process_grate(end_year)
}


#' Process Grad Rate
#'
#' @param description to the extent that fetch_grad_rate needs its own custom
#' logic above and beyond the generic process_grate, it will live here
#' @param df output of get_grad_rate
#' @param end_year ending academic year
#' @param methodology one of c('4 year', '5 year')
#'
#' @return dataframe with normalized grad rate variables

process_grad_rate <- function(df, end_year, methodology) {
  # just a stub for now
  df
}


#' Fetch Grad Rate
#'
#' @param end_year end of the academic year - eg 2006-07 is 2007.
#' valid values are 2011-present.
#'
#' @return dataframe with grad rate
#' @export

fetch_grad_rate <- function(end_year, methodology = '4 year') {
  df <- get_grad_rate(end_year, methodology) %>%
    process_grad_rate(end_year)

  df <- tidy_grad_rate(df, end_year, methodology)

  df <- id_grad_aggs(df)

  df <- df %>%
    select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      subgroup,
      grad_rate,
      cohort_count, graduated_count,
      methodology,
      is_state,
      is_county,
      is_district,
      is_school,
      is_charter,
      is_charter_sector,
      is_allpublic
    )

  return(df)
}


#' Grad Rate column order
#'
#' @param df processed grad rate df
#'
#' @return df in correct order
#' @export

grate_column_order <- function(df) {
  df %>%
    select(
      end_year,
      county_id, county_name,
      district_id, district_name,
      school_id, school_name,
      subgroup,
      cohort_count,
      graduated_count,
      grad_rate,
      methodology,
      is_state,
      is_district,
      is_school,
      is_charter,
      is_charter_sector,
      is_allpublic
    )
}


#' Grad Count column order
#'
#' @param df processsed grad count df
#'
#' @return df in correct order
#' @export

gcount_column_order <- function(df) {
  df %>%
    select(one_of(
      'end_year',
      'county_id', 'county_name',
      'district_id', 'district_name',
      'school_id', 'school_name',
      'subgroup',
      'cohort_count',
      'graduated_count',
      'is_state',
      'is_district',
      'is_school',
      'is_charter',
      'is_charter_sector',
      'is_allpublic'
    ))
}
