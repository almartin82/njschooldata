#' @title read a zipped excel HS graduate outcome/rate file from the NJ state website
#' 
#' @description
#' \code{get_raw_grate} returns a data frame with NJ HS grad rate
#' @param end_year a school year.  year is the end of the academic year - eg 2006-07
#' school year is year '2007'.  valid values are 1998-2018.
#' @param calc_type c('4 year', '5 year')
#' @export

get_raw_grate <- function(end_year, calc_type = '4 year') {
  
  #xlsx
  if (end_year >= 2013 & calc_type == '4 year') {
    #build url
    basic_suffix <- "/4Year.xlsx"
    num_skip <- 0
    
    if (end_year >= 2018) {
      basic_suffix <- "/4YearGraduation.xlsx"
      num_skip <- 3
    }
  
    grate_url <- paste0(
      "http://www.state.nj.us/education/data/grate/", end_year, basic_suffix
    )
    
    #download
    tname <- tempfile(pattern = "grate", tmpdir = tempdir(), fileext = ".xlsx")
    tdir <- tempdir()
    downloader::download(grate_url, dest = tname, mode = "wb") 

    grate <- readxl::read_excel(tname, na = '-', skip = num_skip)
    names(grate)[names(grate) == 'FOUR_YR_GRAD_RATE'] <- 'grad_rate'
    names(grate)[names(grate) == 'FOUR_YR_ADJ_COHORT_COUNT'] <- 'cohort_count'

    grate$methodology <- 'cohort'
    grate$time_window <- '4 year'
  }
  
  if (end_year >= 2012 & calc_type == '5 year') {
    #build url
    grate_url <- paste0(
      "http://www.state.nj.us/education/data/grate/", end_year + 1, 
      "/4And5YearCohort", substr(end_year, 3, 4), ".xlsx"
    )
    
    #download
    tname <- tempfile(pattern = "grate", tmpdir = tempdir(), fileext = ".xlsx")
    tdir <- tempdir()
    downloader::download(grate_url, dest = tname, mode = "wb") 

    grate <- readxl::read_excel(tname, na = '-')
    grate <- grate[, c(1:6, 8)]
    #nothing is named consistently :(
    mask <- names(grate) %in% c('FIVE_YR_GRAD_RATE', '2012 5 -Year Adj Cohort Grad Rate')
    names(grate)[mask] <- 'grad_rate'    
    grate$methodology <- 'cohort'
    grate$time_window <- '5 year'
  }
  
  
  #2012 and 2011 in the same file?!
  if (end_year %in% c(2012, 2011)) {
    grate_url <- "http://www.state.nj.us/education/data/grate/2012/gradrate.xls"
    tname <- tempfile(pattern = "grate", tmpdir = tempdir(), fileext = ".xls")
    tdir <- tempdir()
    downloader::download(grate_url, dest = tname, mode = "wb") 
    grate <- readxl::read_excel(tname, na = '-')
    
    if (end_year == 2012) {
      grate <- grate[, c(1:7, 8)]
      names(grate)[8] <- 'grad_rate'
    } else if (end_year == 2011) {
      grate <- grate[, c(1:7, 9)]
      names(grate)[8] <- 'grad_rate'
    }
    
    grate$methodology <- 'cohort'
    grate$time_window <- '4 year'
  }
  
  #pre 2010 uses non-cohort methodology
  if (end_year %in% c(1998:2010)) {
    grate_url <- paste0(
      "http://www.state.nj.us/education/data/grd/grd", substr(end_year + 1, 3, 4), "/grd.zip"
    )
    #download and unzip
    tname <- tempfile(pattern = "grate", tmpdir = tempdir(), fileext = ".zip")
    tdir <- tempdir()
    downloader::download(grate_url, dest = tname, mode = "wb") 
    unzip_loc <- paste0(tempfile(pattern = 'subfolder'))
    dir.create(unzip_loc)
    utils::unzip(tname, exdir = unzip_loc)
    
    #read file
    grate_files <- utils::unzip(tname, exdir = ".", list = TRUE)
    
    #extensions changed
    if (end_year >= 2009) {
      grate <- readxl::read_excel(paste0(unzip_loc, '/', grate_files$Name[1]))
    } else {
      grate <- readr::read_csv(file = paste0(unzip_loc, '/', grate_files$Name[1]))
    }
   
    grate$methodology <- 'grad_count'
 
    #clean up
    closeAllConnections()
    unlink(unzip_loc, recursive = TRUE)
    file.remove(tname)
  }
    
  #tag with year and 
  grate$grad_cohort <- end_year
  grate$year_reported <- end_year
  
  return(grate)
}



#' @title process grate
#' 
#' @description does cleanup of the grad rate ('grate') file
#' @param df the output of get_raw_grate
#' @param end_year a school year.  year is the end of the academic year - eg 2006-07
#' school year is year '2007'.  valid values are 1998-2014.
#' @export

process_grate <- function(df, end_year) {
  #clean up names
  names(df)[names(df) %in% c('COUNTY', 'CO', 'CO NAME', 'CO_NAME', 'County Name')] <- 'county_name'
  names(df)[names(df) %in% c('DISTRICT', 'DIST', 'DIST NAME', 'DIS_NAME', 'District Name')] <- 'district_name'
  names(df)[names(df) %in% c('SCHOOL', 'SCH', 'SCH NAME', 'SCH_NAME', 'School Name')] <- 'school_name'
  
  #oh, man.  in 1998 and 1999 PROG_CODE is program code.  in 2008 PROG_CODE is...
  #actually PROG_NAME
  #guys, seriously.
  if (end_year == 2008) {
    names(df)[names(df) %in% c('PROG_CODE')] <- 'program_name'
  } else {
    names(df)[names(df) %in% c('PROG CODE', 'PROG_CODE')] <- 'program_code'
  }
  names(df)[names(df) %in% c('PROGNAME', 'PROG', 'PROG NAME')] <- 'program_name'
  
  names(df)[names(df) %in% c('COUNTY_CODE', 'CO CODE', 'County', 'County Code')] <- 'county_id'
  names(df)[names(df) %in% c('DISTRICT_CODE', 'DIST CODE', 'District', 'District Code')] <- 'district_id'
  names(df)[names(df) %in% c('SCHOOL_CODE', 'SCH CODE', 'School', 'School Code')] <- 'school_id'
  
  #errata
  names(df)[names(df) %in% c('HISP_MALE')] <- 'hisp_m'  
  names(df)[names(df) %in% c("NAT_AM-F", 'NAT_F', 'NAT_AM_F(NON_HISP)')] <- 'nat_am_f'
  names(df)[names(df) %in% c('NAT_M', 'NAT_AM_M(NON_HISP)')] <- 'nat_am_m'
  
  #oh, 2007...
  names(df)[names(df) %in% c('ROWTOT')] <- 'rowtotal'
  names(df)[names(df) %in% c('WH_M')] <- 'white_m'
  names(df)[names(df) %in% c('WH_F')] <- 'white_f'
  names(df)[names(df) %in% c('BL_M')] <- 'black_m'
  names(df)[names(df) %in% c('BL_F')] <- 'black_f'
  names(df)[names(df) %in% c('ASIAN_M(NON_HISP)')] <- 'asian_m'
  names(df)[names(df) %in% c('ASIAN_F(NON_HISP)')] <- 'asian_f'
  names(df)[names(df) %in% c('HAW_NTV_M(NON_HISP)')] <- 'hwn_nat_m'
  names(df)[names(df) %in% c('HAW_NTV_F(NON_HISP)')] <- 'hwn_nat_f'
  names(df)[names(df) %in% c('2/MORE_RACES_M(NON_HISP)')] <- '2_more_m'
  names(df)[names(df) %in% c('2/MORE_RACES_F(NON_HISP)')] <- '2_more_f'

  names(df)[names(df) %in% c('SUBGROUP', 'Subgroup')] <- 'group'
  names(df)[names(df) %in% c('Four Year Graduation Rate')] <- 'grad_rate'
  names(df)[names(df) %in% c('Four Year Adjusted Cohort Count')] <- 'cohort_count'
  names(df)[names(df) %in% c('Four Year Graduates Count')] <- 'graduated_count'
  
  names(df) <- names(df) %>% tolower()

  numeric_cols <- c("rowtotal", "female", "male",
    "white", "black", "hispanic", "american_indian", 
    "asian", "pacific_islander", "multiracial",
    "white_m", "white_f", "black_m", "black_f", 
    "hisp_m", "hisp_f", "nat_am_m", "nat_am_f", 
    "asian_m", "asian_f", "hwn_nat_m", "hwn_nat_f", 
    "multiracial_m", "multiracial_f", 
    "instate", "outstate",
    "grad_rate", "cohort_count", "graduated_count"
  )
  
  for (i in numeric_cols) {
    if (i %in% names(df)) {
      df[, i] <- df %>% dplyr::select_(i) %>% unlist() %>% as.numeric()
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
  df$school_id <- ifelse(df$school_id == "999.000000", "999", df$school_id)
  df$district_id <- ifelse(df$district_id == "9999.000000", "999", df$district_id)


  if ('grad_rate' %in% names(df)) {
    if (all(df$grad_rate <= 1 | is.na(df$grad_rate))) {
      df$grad_rate <- df$grad_rate * 100
    }
    df$grad_rate <- df$grad_rate / 100 %>% round(2)
  }

  return(df)
}



#' @title tidy grate
#' 
#' @description tidies a processed grate data frame, producing a data frame with consistent
#' headers and values, suitable for longitudinal analysis
#' @param df the output of process_grate
#' @param end_year a school year.  year is the end of the academic year - eg 2006-07
#' school year is year '2007'.  valid values are 1998-2014.
#' @export

tidy_grate <- function(df, end_year) {
  
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
    name_vector <- ifelse(name_vector == 'Schoolwide', 'total_population', name_vector)    
    name_vector <- ifelse(name_vector == 'Districtwide', 'total_population', name_vector)
    name_vector <- ifelse(name_vector == 'Statewide Total', 'total_population', name_vector)
    
    name_vector
  }
  
    
  tidy_new_format <- function(df) {
    df$program_name <- 'Total'
    df$program_code <- NA
    df$group <- 'total_population'
    df$outcome_count <- NA
    df$postgrad_grad <- 'grad'
    
    if ('graduated_count' %in% names(df)) {
      names(df)[names(df) == 'graduated_count'] <- 'num_grad'
    } else {
      df$num_grad <- NA
    }
    
    if ('group' %in% names(df)) {
      df$group <- tolower(df$group)
      df$group <- clean_grate_names(df$group)
    }
    
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
    df$group <- clean_grate_names(df$group)
    
    out <- df
  }
  
  return(out)
}



#' @title fetch grate
#' 
#' @description a consistent interface into the NJ HS graduates data. 
#' @param end_year a school year.  year is the end of the academic year - eg 2006-07
#' school year is year '2007'.  valid values are 1998-2014.
#' @param tidy tidy the response into a data frame with consistent headers?
#' @return a 
#' 
#' @export

fetch_grate <- function(end_year, tidy = TRUE) {
  out <- get_raw_grate(end_year) %>%
    process_grate(., end_year)
  
  if (tidy) out <- out %>% tidy_grate(., end_year)
  
  return(out)
}

