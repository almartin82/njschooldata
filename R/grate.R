#' @title read a zipped excel HS graduate rate file from the NJ state website
#' 
#' @description
#' \code{get_raw_grate} returns a data frame with NJ HS grad rate
#' @param end_year a school year.  year is the end of the academic year - eg 2006-07
#' school year is year '2007'.  valid values are 1998-2014.
#' @param calc_type c('4 year', '5 year').  5 year only available for 2012 and 2013 
#' as of 8/26/15
#' @export

get_raw_grate <- function(end_year, calc_type = '4 year') {
  
  #xlsx
  if (end_year >= 2013 & calc_type == '4 year') {
    #build url
    grate_url <- paste0(
      "http://www.state.nj.us/education/data/grate/", end_year, "/4Year.xlsx"
    )
    
    #download
    tname <- tempfile(pattern = "grate", tmpdir = tempdir(), fileext = ".xlsx")
    tdir <- tempdir()
    downloader::download(grate_url, dest = tname, mode = "wb") 

    grate <- readxl::read_excel(tname, na = '-')
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
      grate <- readxl::read_excel(paste0(unzip_loc, '\\', grate_files$Name[1]))
    } else {
      grate <- readr::read_csv(file = paste0(unzip_loc, '\\', grate_files$Name[1]))
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
  names(df)[names(df) %in% c('COUNTY', 'CO', 'CO NAME', 'CO_NAME')] <- 'county_name'
  names(df)[names(df) %in% c('DISTRICT', 'DIST', 'DIST NAME', 'DIS_NAME')] <- 'district_name'
  names(df)[names(df) %in% c('SCHOOL', 'SCH', 'SCH NAME', 'SCH_NAME')] <- 'school_name'
  names(df)[names(df) %in% c('PROG_CODE', 'PROG CODE')] <- 'program_code'
  names(df)[names(df) %in% c('PROGNAME', 'PROG', 'PROG NAME')] <- 'program_name'
  
  names(df)[names(df) %in% c('COUNTY_CODE', 'CO CODE', 'County')] <- 'county_id'
  names(df)[names(df) %in% c('DISTRICT_CODE', 'DIST CODE', 'District')] <- 'district_id'
  names(df)[names(df) %in% c('SCHOOL_CODE', 'SCH CODE', 'School')] <- 'school_id'
  
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
  
  names(df) <- names(df) %>% tolower()


  numeric_cols <- c("rowtotal", "female", "male",
    "white", "black", "hispanic", "american_indian", 
    "asian", "pacific_islander", "multiracial",
    "white_m", "white_f", "black_m", "black_f", 
    "hisp_m", "hisp_f", "nat_am_m", "nat_am_f", 
    "asian_m", "asian_f", "hwn_nat_m", "hwn_nat_f", 
    "multiracial_m", "multiracial_f", 
    "instate", "outstate"
  )
  
  for (i in numeric_cols) {
    if (i %in% names(df)) {
      df[, i] <- df %>% dplyr::select_(i) %>% unlist() %>% as.numeric()
    }
  }
  
  #county distr sch codes
  if (end_year <= 2010) {
    
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
  
  df_coltypes <- sapply(df, class) %>% unname()

  for (i in 1:ncol(df)) {
    if (df_coltypes[i] == 'character') {
      df[, i] <- sapply(df[, i], trimws, which = 'both')
    }
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


  return(df)
}













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
      sub_long$grad_rate <- NA
     
      old_tidy_list[[j]] <- cbind(constant_df, sub_long) 
    }
    
    out <- dplyr::rbind_all(old_tidy_list)
    
    return(out)
  }


  if (end_year < 2011) {
    #iterate over the sch/district totals
    df$iter_key <- paste0(df$county_id, '@', df$district_id, '@', df$school_id)
    sch_list <- list()
    
    for (i in df$iter_key %>% unique()) {
      this_sch <- df %>% dplyr::filter(iter_key == i)
      sch_list[[i]] <- tidy_old_format(this_sch)
    }
      
    out <- dplyr::rbind_all(sch_list)
  }
    
  return(out)
}





scratch <- function() {
  
#[1] "MERCER C0UNTY VOCATIONAL | MCVS HEALTH OCCUP CENT"
#[1] "NEW BRUNSWICK CITY | NEW BRUNSWICK HIGH"
#[1] "NEW BRUNSWICK CITY | DISTRICT TOTAL"
#[1] "SUSSEX COUNTY VOCATIONAL | SUSSEX CTY TECH EVE"  
  
  #testing 
  foo <- hs_list[[2013]] %>% process_grate(., 2013) %>% tidy_grate(., 2013)
  foo <- hs_list[[1999]] %>% process_grate(., 1999) %>% tidy_grate(., 1999)
  
  
  sch_subset <- process_grate(hs_list[[2003]], 2003) %>% filter(school_name == 'ATLANTIC CITY HIGH') %>% as.data.frame()

    
  hs_list <- list()
  for (i in c(1998:2014)) {
    hs_list[[i]] <- get_raw_grate(i)
  }

  
  clean_hs_list <- list()
  for (i in c(1998:2014)) {
    print(i)
    clean_hs_list[[i]] <- process_grate(hs_list[[i]], i) %>% tidy_grate(., i)
  }

    
  for (i in c(1998:2014)) {
    print(i)
    foo <- process_grate(hs_list[[i]], i) 
    
    all_names <- names(foo)
    
    #print(names(hs_list[[i]]))
    clean_names <- c(
      "county_id", "county_name", 
      "district_id", "district_name", 
      "school_id", "school_name", 
      "level", 
      "grad_cohort", "year_reported", "methodology", "time_window",
      "program_name", "program_code", 
      "white_m", "white_f", 
      "black_m", "black_f", 
      "hisp_m", "hisp_f", 
      "nat_am_m", "nat_am_f", 
      "asian_m", "asian_f", 
      "hwn_nat_m", "hwn_nat_f",
      "2_more_m", "2_more_f", 
      "rowtotal", 
      "instate", "outstate", 
      "subgroup",
      "grad_rate", "cohort_count", "graduated_count"
    )

    all_names[!all_names %in% clean_names] %>% print()
  }


}


