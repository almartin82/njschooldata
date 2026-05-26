#' Parse a TGES rank value to an integer
#'
#' @description Through ~2015 a rank is a plain integer (eg "34").  From 2019 on
#' NJ DOE encodes it as "rank|out_of" (eg "33|57", ie 33rd of 57 in the peer
#' group).  This keeps the rank itself; the peer-group size is not retained.
#' Non-numeric markers ("N.R." Not Reported, "N.A." Not Applicable, blanks)
#' become NA.
#'
#' @param x character vector of rank values
#'
#' @return integer vector
#' @keywords internal
parse_rank <- function(x) {
  suppressWarnings(as.integer(sub("[|].*$", "", as.character(x))))
}


#' Build the download URL for a TGES/CSG year
#'
#' @description NJ DOE relocated the guide files under
#' \code{/education/guide/docs/} (and moved the domain from state.nj.us to
#' nj.gov).  2001-2010 ship as \code{{year}_CSG.zip}, 2011-2023 as
#' \code{{year}_TGES.zip}, and 2024 onward as a per-year subfolder containing an
#' irregularly named bundle zip.
#'
#' @param end_year reporting year
#'
#' @return character URL
#' @keywords internal
tges_url_for_year <- function(end_year) {
  end_year <- as.integer(end_year)
  base <- "https://www.nj.gov/education/guide/docs"

  #2024 onward live in a per-year subfolder with non-uniform bundle names
  special_urls <- list(
    "2024" = paste0(base, "/2024/TGES24_Zipped.zip"),
    "2025" = paste0(base, "/2025/TGES2025_Zipped.zip")
  )

  if (as.character(end_year) %in% names(special_urls)) {
    special_urls[[as.character(end_year)]]
  } else if (end_year >= 2011 && end_year <= 2023) {
    paste0(base, "/", end_year, "_TGES.zip")
  } else if (end_year >= 2001 && end_year <= 2010) {
    paste0(base, "/", end_year, "_CSG.zip")
  } else {
    stop(
      "No TGES download is available for end_year ", end_year,
      ". Valid values are 2001-2025.", call. = FALSE
    )
  }
}


#' Get Raw Taxpayer's Guide to Educational Spending
#'
#' @description Downloads and unpacks one year of the NJ DOE Taxpayers' Guide to
#' Educational Spending (TGES; branded the "Comparative Spending Guide" / CSG
#' before 2011).  Each year is published as a single zip.
#'
#' @param end_year a school year.  end_year is the end of the academic year - eg
#' the 2016-17 school year is end_year 2017.  Valid values are 2001-2025.  (NJ DOE
#' links 1999 and 2000 but those downloads 404 on the state site.)
#'
#' @return list of data frames
#' @keywords internal
get_raw_tges <- function(end_year) {
  tges_url <- tges_url_for_year(end_year)

  #download and unzip
  tname <- tempfile(pattern = "tges", tmpdir = tempdir(), fileext = ".zip")
  downloader::download(tges_url, dest = tname, mode = "wb")
  unzip_loc <- paste0(tempfile(pattern = 'subfolder'))
  dir.create(unzip_loc)
  utils::unzip(tname, exdir = unzip_loc)

  #tag csv or xlsx.  Zip members sit under a per-year subfolder
  #(eg "2011_TGES/CSG1.CSV"), so key off the bare file name to keep the
  #tidy_tges_data() lookups (CSG1, VITSTAT_TOTAL, ...) matching.
  tges_files <- utils::unzip(tname, exdir = ".", list = TRUE)
  tges_files$file <- tools::file_path_sans_ext(basename(tges_files$Name))
  tges_files$extension <- tools::file_ext(tges_files$Name)
  tges_files <- tges_files[tges_files$extension != "", , drop = FALSE]
  
  tges_csv <- tges_files %>%
    filter(extension %in% c('CSV', 'csv'))
  tges_excel <- tges_files %>%
    filter(extension %in% c('XLS', 'XLSX', 'xls', 'xlsx'))
  tges_dbf <- tges_files %>%
    filter(extension %in% c('dbf', 'DBF'))
  
  #read csv
  csv_list <- map2(
    .x = tges_csv$Name,
    .y = tges_csv$file,
    .f = function(.x, .y) {
      df <- readr::read_csv(
        file.path(unzip_loc, .x),
        col_types = cols()
      ) %>%
      mutate(
        file_name = .y
      ) %>%
      janitor::clean_names()
      
      df <- clean_cds_fields(df, tges = TRUE)
      
      #state/group average rows carry non-numeric codes; padding NAs them, which
      #is expected, so quiet the "NAs introduced by coercion" coercion warning
      if ('county_code' %in% names(df)) {
        df$county_code <- suppressWarnings(pad_leading(df$county_code, 2))
      }
      if ('district_code' %in% names(df)) {
        df$district_code <- suppressWarnings(pad_leading(df$district_code, 4))
      }
      df
    }
  )
  names(csv_list) <- tges_csv$file %>% toupper()
  
  #read excel
  excel_list <- map2(
    .x = tges_excel$Name,
    .y = tges_excel$file,
    .f = function(.x, .y) {
      #the Total Spending Detail workbooks (Detail_FY##.xlsx, 2024+ bundles) lead
      #with a two-row description/title banner; the real header is on row 3.  Skip
      #the banner so the 12 component columns parse, rather than the banner text.
      skip_rows <- if (grepl('^Detail_FY', .y, ignore.case = TRUE)) 2L else 0L
      df <- readxl::read_excel(
        path = file.path(unzip_loc, .x),
        skip = skip_rows
      ) %>%
      mutate(
        file_name = .y
      ) %>%
      janitor::clean_names()

      df <- clean_cds_fields(df, tges = TRUE)
      df
    }
  )
  names(excel_list) <- tges_excel$file %>% toupper()
  
  #read dbf (1999-2002)
  dbf_list <- map2(
    .x = tges_dbf$Name,
    .y = tges_dbf$file,
    .f = function(.x, .y) {
      df <- foreign::read.dbf(
        file = file.path(unzip_loc, .x),
        as.is = TRUE
        ) %>%
        mutate(
          file_name = .y
        ) %>%
        janitor::clean_names()
      
      df <- clean_cds_fields(df, tges = TRUE)
      df
    }
  )
  names(dbf_list) <- tges_dbf$file %>% toupper()

  all_df <- c(csv_list, excel_list, dbf_list)

  all_df
}


#' TGES name cleaner
#' 
#' @description internal function for converting cryptic variable codes to full name
#' @param x vector of names
#' @param indicator_fields list of key/value variables to convert
#'
#' @return character vector of names

tges_name_cleaner <- function(x, indicator_fields) {
  out <- map_chr(
    names(x),
    function(.x) {
      ifelse(.x %in% names(indicator_fields), indicator_fields[[.x]],.x)
    }
  )
  out
}


#' tidy total spending per pupil
#'
#' @param df total spending data frame, eg CSG1AA_AVGS output from get_raw_tges()
#' @param end_year end year that the report was published
#'
#' @return data frame
#' @keywords internal
tidy_total_spending_per_pupil <- function(df, end_year) {
  
  #masks to break out y1, y2 data
  both_years <- !grepl('11a|21a', names(df))
  year_1 <- grepl('11a', names(df), fixed = TRUE) | both_years
  year_2 <- grepl('21a', names(df), fixed = TRUE) | both_years
  
  #reshape wide to long
  y1_df <- df[, year_1]
  y2_df <- df[, year_2]
  
  #codes from http://www.state.nj.us/education/guide/2017/install.pdf
  indicator_fields <- list(
    "exp" = "Total Expenditures, actual costs",
    "ade" = "Average Daily Enrollment plus Sent Pupils",
    "pp" = "Per Pupil Total Expenditures",
    "rk" = "Per Pupil Rank",
    "boty" = "Budget / Operating type"
  )
  
  #clean up names
  names(y1_df) <- gsub('11a', '', names(y1_df), fixed = TRUE)
  names(y1_df) <- tges_name_cleaner(y1_df, indicator_fields)
  y1_df$end_year <- end_year - 2
  y1_df$calc_type <- 'Actuals'
  y1_df$report_year <- end_year
  
  names(y2_df) <- gsub('21a', '', names(y2_df), fixed = TRUE)
  names(y2_df) <- tges_name_cleaner(y2_df, indicator_fields)
  y2_df$end_year <- end_year - 1
  y2_df$calc_type <- 'Actuals'
  y2_df$report_year <- end_year

  #coerce numeric columns so a "Not Reported" (N.R.) marker in one year doesn't
  #flip that column to character and break the bind_rows type match (eg 2025)
  force_avgs_types <- function(df) {
    num_cols <- c(
      "Total Expenditures, actual costs",
      "Average Daily Enrollment plus Sent Pupils",
      "Per Pupil Total Expenditures",
      "Per Pupil Rank"
    )
    for (nm in intersect(num_cols, names(df))) {
      df[[nm]] <- suppressWarnings(as.numeric(df[[nm]]))
    }
    df
  }
  y1_df <- force_avgs_types(y1_df)
  y2_df <- force_avgs_types(y2_df)

  bind_rows(y1_df, y2_df)
}


#' tidy Total Spending Detail
#'
#' @description Cleans the Total Spending Detail workbooks (\code{Detail_FY##.xlsx})
#' that ship inside the 2024+ TGES bundles.  These break a district's
#' \emph{Total Spending Per Pupil} into the six components that, summed, equal the
#' published per-pupil total: General Current Expense, Capital Outlay, Grants &
#' Entitlements, Food Services, Debt Service on locally issued bonds, and Debt
#' Service on School Development Authority (SDA) bonds.
#'
#' Unlike the budget indicators (CSG1-15), the per-pupil amounts here are divided
#' by \emph{daily enrollment plus sent pupils}, not resident enrollment, so they
#' are only directly comparable to CSG1's budgetary per-pupil cost for districts
#' that educate all of their own pupils.  \code{tges_excluded_costs()} carries the
#' enrollment denominator through and flags sending districts for this reason.
#'
#' The data year is taken from the \code{FY##} token in the file name (the 2025
#' guide ships \code{Detail_FY24} = end_year 2024 and \code{Detail_FY23} =
#' end_year 2023), not from the report \code{end_year}.
#'
#' @param df a raw Total Spending Detail data frame from \code{get_raw_tges()}
#'   (read with the two-row banner skipped, so column names are the row-3 headers)
#' @param end_year the report year the bundle was published under (used as
#'   \code{report_year}; the row's \code{end_year} comes from the file name)
#'
#' @return long, tidy data frame
#' @keywords internal
tidy_total_spending_detail <- function(df, end_year) {

  #data year comes from the FY token in the file name (Detail_FY24 -> 2024), not
  #the report year.  Fall back to report end_year - 1 if the token is missing.
  data_end_year <- end_year - 1L
  if ('file_name' %in% names(df)) {
    fy <- suppressWarnings(as.integer(sub('^.*FY', '', df$file_name[1])))
    if (!is.na(fy)) data_end_year <- 2000L + fy
  }

  rename_map <- c(
    general_current_expense_per_pupil                            = 'general_current_expense_pp',
    total_capital_outlay_per_pupil                               = 'capital_outlay_pp',
    total_grants_entitlements_per_pupil                          = 'grants_entitlements_pp',
    total_food_services_per_pupil                                = 'food_services_pp',
    debt_service_on_locally_issued_bonds_per_pupil               = 'debt_service_local_pp',
    debt_service_on_school_development_authority_bonds_per_pupil  = 'debt_service_sda_pp',
    total_spending                                               = 'total_spending',
    daily_enrollment_plus_sent_pupils                            = 'enrollment_plus_sent',
    calculated_per_pupil_amount                                  = 'total_spending_pp'
  )
  for (old in names(rename_map)) {
    if (old %in% names(df)) names(df)[names(df) == old] <- rename_map[[old]]
  }

  num_cols <- c('general_current_expense_pp', 'capital_outlay_pp',
                'grants_entitlements_pp', 'food_services_pp',
                'debt_service_local_pp', 'debt_service_sda_pp',
                'total_spending', 'enrollment_plus_sent', 'total_spending_pp')
  for (nm in intersect(num_cols, names(df))) {
    df[[nm]] <- suppressWarnings(as.numeric(df[[nm]]))
  }

  if ('district_code' %in% names(df)) {
    df$district_code <- suppressWarnings(pad_leading(df$district_code, 4))
  }

  df$end_year    <- data_end_year
  df$calc_type   <- 'Actuals'
  df$report_year <- end_year

  lead <- intersect(
    c('county_name', 'district_code', 'district_name', 'end_year', 'calc_type',
      'report_year', 'general_current_expense_pp', 'capital_outlay_pp',
      'grants_entitlements_pp', 'food_services_pp', 'debt_service_local_pp',
      'debt_service_sda_pp', 'total_spending_pp', 'total_spending',
      'enrollment_plus_sent'),
    names(df)
  )
  df[, c(lead, setdiff(names(df), lead)), drop = FALSE]
}


#' tidy common/generic budget indicator data frame
#'
#' @param df indicator data frame, eg output of get_raw_tges() 
#' indicators 1-15
#' @param end_year end year that the report was published
#' @param indicator character, indicator name
#'
#' @return long, tidy data frame
#' @keywords internal
tidy_generic_budget_indicator <- function(df, end_year, indicator) {
  
  df$indicator <- indicator
  
  #for 1999 through 2003 y1, y2, y3 changed per-year
  if (end_year <= 2003) {
    df <- year_variable_converter(df, end_year)
  }
  
  #masks to break out y1, y2, y3 data
  if (end_year >= 2011) {
    all_years <- !grepl('[[:alpha:]][1,2,3]+[[:digit:]]|sb[a,b,c]+[[:digit:]]', names(df))
    year_1 <- grepl('[[:alpha:]]1+[[:digit:]]|sba+[[:digit:]]', names(df)) | all_years
    year_2 <- grepl('[[:alpha:]]2+[[:digit:]]|sbb+[[:digit:]]', names(df)) | all_years
    year_3 <- grepl('[[:alpha:]]3+[[:digit:]]|sbc+[[:digit:]]', names(df)) | all_years
  #headers slightly different for comparative guide years.  The 2001-2002 DBF
  #files label rank "rk0X" rather than "rank0X", so match both or the rank column
  #is dropped.
  } else if (end_year < 2011) {
    all_years <- grepl('group|county_name|district_name|district_code|file_name|indicator', names(df))
    year_1 <- grepl('pp01|rank01|rk01|pct01|pct201', names(df)) | all_years
    year_2 <- grepl('pp02|rank02|rk02|pct02|pct202', names(df)) | all_years
    year_3 <- grepl('pp03|rank03|rk03|pct03|pct203', names(df)) | all_years
  }
  
  #pre-2011 files store the salaries-% as pct20X alongside the budget-% pct0X;
  #map pct2X -> sbX so the two stay distinct (mirroring the 2011+ pct/sb split).
  #2011+ "pct2X" is a YEAR-2 budget %, not a salaries %, so leave it untouched.
  #Masks above were computed on the original names, so renaming here is safe.
  if (end_year < 2011) names(df) <- gsub('pct2', 'sb', names(df))

  #reshape wide to long
  y1_df <- df[, year_1 & !grepl('sbb|sbc', names(df))]
  y2_df <- df[, year_2]
  y3_df <- df[, year_3]
  
  indicator_fields <- list(
    #tges
    "pp" = "Per Pupil costs",
    "rk" = "District rank",
    "e" = "Enrollment (ADE)",
    "pct" = "Cost as a percentage of the Total Budgetary Cost Per Pupil",
    "sb" = "Cost as a percentage of Total Salaries and Benefits"  
  )
  
  #force types to resolve bind_row conflicts when all NA.  Coercion warnings are
  #expected: "N.R."/"N.A." missing markers become NA, and ranks may arrive in the
  #"rank|out_of" format (2019+), so parse_rank() keeps the rank integer.
  force_indicator_types <- function(df) {
    if ('pp' %in% names(df)) df$pp <- suppressWarnings(as.numeric(df$pp))
    if ('rk' %in% names(df)) df$rk <- parse_rank(df$rk)
    if ('pct' %in% names(df)) df$pct <- suppressWarnings(as.numeric(df$pct))
    if ('sb' %in% names(df)) df$sb <- suppressWarnings(as.numeric(df$sb))

    df
  }
  
  #clean up names
  names(y1_df) <- gsub('[[:digit:]]', '', names(y1_df))
  names(y1_df) <- gsub('sba', 'sb', names(y1_df))
  names(y1_df) <- gsub('a$', '', names(y1_df))
  names(y1_df) <- gsub('rank', 'rk', names(y1_df), fixed = TRUE)
  y1_df <- force_indicator_types(y1_df)
  names(y1_df) <- tges_name_cleaner(y1_df, indicator_fields)
  y1_df$end_year <- end_year - 2
  y1_df$calc_type <- 'Actuals'
  y1_df$report_year <- end_year

  names(y2_df) <- gsub('[[:digit:]]', '', names(y2_df))
  names(y2_df) <- gsub('sbb', 'sb', names(y2_df))
  names(y2_df) <- gsub('a$', '', names(y2_df))
  names(y2_df) <- gsub('rank', 'rk', names(y2_df), fixed = TRUE)
  y2_df <- force_indicator_types(y2_df)
  names(y2_df) <- tges_name_cleaner(y2_df, indicator_fields)
  y2_df$end_year <- end_year - 1
  y2_df$calc_type <- 'Actuals'
  y2_df$report_year <- end_year

  names(y3_df) <- gsub('[[:digit:]]', '', names(y3_df))
  names(y3_df) <- gsub('sbc', 'sb', names(y3_df))
  names(y3_df) <- gsub('a$', '', names(y3_df))
  names(y3_df) <- gsub('rank', 'rk', names(y3_df), fixed = TRUE)
  y3_df <- force_indicator_types(y3_df)
  names(y3_df) <- tges_name_cleaner(y3_df, indicator_fields)
  y3_df$end_year <- end_year
  y3_df$calc_type <- 'Budgeted'
  y3_df$report_year <- end_year
  
  bind_rows(y1_df, y2_df, y3_df)
}

#' year variable converter
#'
#' @description for the 1999-2003 tges files, the 'year' of the data
#' was encoded in the variable names
#' @param df a tges indicator data frame published between 1999 and 2003
#' @param end_year year published
#'
#' @return data frame that conforms to 2004-2009 style
#' @keywords internal
year_variable_converter <- function(df, end_year) {
  old_id <- end_year - 1
  old_ids <- c(old_id-2, old_id-1, old_id)
  old_ids <- str_sub(old_ids, 3, 4)
  on <- names(df)
  on[grepl(old_ids[3], on)] <- gsub(
    pattern = old_ids[3],
    replacement = '03',
    x = on[grepl(old_ids[3], on)]
  )
  on[grepl(old_ids[2], on)] <- gsub(
    pattern = old_ids[2],
    replacement = '02',
    x = on[grepl(old_ids[2], on)]
  )
  on[grepl(old_ids[1], on)] <- gsub(
    pattern = old_ids[1],
    replacement = '01',
    x = on[grepl(old_ids[1], on)]
  )  
  names(df) <- on

  df
}

#' tidy generic personnel indicator data frame
#'
#' @param df personnel data frame, eg output of get_raw_tges() 
#' indicators 16-19
#' @param end_year end year that the report was published
#' @param indicator character, indicator name
#'
#' @return long, tidy data frame
#' @keywords internal
tidy_generic_personnel <- function(df, end_year, indicator) {

  df$indicator <- indicator

  #2003 personnel files label the two ranks rk{yy}_{col} (eg rk01_6 ratio rank,
  #rk01_8 salary rank).  Both collapse to "rk_" once digits are stripped, so
  #relabel them first: within each year the lowest column index is the ratio rank
  #(rk), the next is the salary rank (rksal).
  legacy_rk <- grepl('^rk[0-9]+_[0-9]+$', names(df))
  if (any(legacy_rk)) {
    nm <- names(df)
    yy <- sub('^rk([0-9]+)_[0-9]+$', '\\1', nm[legacy_rk])
    idx <- as.integer(sub('^rk[0-9]+_([0-9]+)$', '\\1', nm[legacy_rk]))
    sel_all <- which(legacy_rk)
    for (y in unique(yy)) {
      sel <- sel_all[yy == y][order(idx[yy == y])]
      nm[sel] <- paste0(c('rk', rep('rksal', length(sel) - 1L)), y)
    }
    names(df) <- nm
  }

  #for 1999 through 2003 y1, y2, y3 changed per-year
  if (end_year <= 2003) {
    df <- year_variable_converter(df, end_year)
  }
  
  #masks to break out y1, y2 data
  if (end_year >= 2011) {
    #2011+ codes are {var}{00|01}{table#}, eg "strat0016" (year 00) /
    #"strat0116" (year 01).  Anchor the year to the two digits right after the
    #variable name so the trailing table number (eg "16") is not mistaken for the
    #other year - grepl('01', 'strat0016') would wrongly match both.
    yr <- sub('^[[:alpha:]]+(00|01)[[:digit:]]*$', '\\1', names(df))
    all_years <- !(yr %in% c('00', '01'))
    year_1 <- (yr == '00') | all_years
    year_2 <- (yr == '01') | all_years
  } else if (end_year < 2011) {
    #CSG-era files are inconsistent across tables: CSG16-18 suffix the two years
    #02/03 while CSG19 uses 01/02.  Derive the two year tokens from the data
    #columns (the two digits right after the variable name) instead of hardcoding
    #them, so every table splits correctly.
    tok <- sub('^[[:alpha:]]+([0-9]{2}).*$', '\\1', names(df))
    has_tok <- grepl('^[0-9]{2}$', tok)
    yrs <- sort(unique(tok[has_tok]))
    y1tok <- yrs[1]
    y2tok <- yrs[length(yrs)]
    all_years <- !has_tok
    year_1 <- (tok == y1tok) | all_years
    year_2 <- (tok == y2tok) | all_years
  }

  indicator_fields <- list(
    'strat' = 'Student/Teacher ratio',
    'rk' = 'Ratio Rank',
    'salt' = 'Teacher Salary',
    'rksal' = 'Salary Rank',
    'ssrat' = 'Student/Special Service ratio',
    'sals' = 'Special Service Salary',
    'sarat' = 'Student/Administrator ratio',
    'salam' = 'Administrator Salary',
    'farat' = 'Faculty/Administrator ratio',
    #cges
    'rrk' = 'Ratio Rank',
    'srk' = 'Salary Rank',
    'sala' = 'Administrator Salary',
    #CSG14 modified
    "pctsalary" = "% of Total Salaries"
  )
  
  #reshape wide to long
  y1_df <- df[, year_1]
  y2_df <- df[, year_2]

  #coerce values: ranks via parse_rank() (handles the 2019+ "rank|out_of"
  #format), every other non-id column to numeric.  Operates on the bare codes
  #(strat, rk, salt, rksal, ...) before they are relabeled.
  coerce_personnel <- function(df) {
    rank_codes <- intersect(c('rk', 'rksal', 'rrk', 'srk'), names(df))
    for (nm in rank_codes) df[[nm]] <- parse_rank(df[[nm]])
    id_codes <- c('group', 'county_name', 'district_code', 'district_name',
                  'file_name', 'indicator')
    num_codes <- setdiff(names(df), c(id_codes, rank_codes))
    for (nm in num_codes) df[[nm]] <- suppressWarnings(as.numeric(df[[nm]]))
    df
  }

  #clean up names
  names(y1_df) <- gsub('[[:digit:]]', '', names(y1_df))
  y1_df <- coerce_personnel(y1_df)
  y1_df$end_year <- end_year - 1
  y1_df$report_year <- end_year
  names(y1_df) <- tges_name_cleaner(y1_df, indicator_fields)

  #clean up names
  names(y2_df) <- gsub('[[:digit:]]', '', names(y2_df))
  y2_df <- coerce_personnel(y2_df)
  y2_df$end_year <- end_year
  y2_df$report_year <- end_year
  names(y2_df) <- tges_name_cleaner(y2_df, indicator_fields)

  bind_rows(y1_df, y2_df)
}


#' Tidy Budgeted vs Actual Fund Balance
#'
#' @param df general fund vs actual used data frame, eg CSG20 
#' output from get_raw_tges()
#' @param end_year end year that the report was published
#'
#' @return data frame
#' @keywords internal
tidy_budgeted_vs_actual_fund_balance <- function(df, end_year) {

  #goofy column names from 99-2010  
  if (end_year <= 2010) {
    names(df)[5:8] <- c('de120', 'de220', 'de320', 'de420')
  }
  
  df$indicator <- 'Budgeted General Fund Balance vs. Actual'
  
  y1_df <- df[, c('group', 'county_name', 'district_code', 'district_name',
                   'de120', 'de220', 'file_name', 'indicator')]
  y2_df <- df[, c('group', 'county_name', 'district_code', 'district_name',
                   'de320', 'de420', 'file_name', 'indicator')]
  
  indicator_fields <- list(
    'de120' = 'Budgeted General Fund Balance',
    'de220' = 'Actual',
    'de320' = 'Budgeted General Fund Balance',
    'de420' = 'Actual'
  )
  
  y1_df$end_year <- end_year - 2
  y1_df$report_year <- end_year
  names(y1_df) <- tges_name_cleaner(y1_df, indicator_fields)
  
  y2_df$end_year <- end_year - 1
  y2_df$report_year <- end_year
  names(y2_df) <- tges_name_cleaner(y2_df, indicator_fields)
  
  bind_rows(y1_df, y2_df)
}


#' Tidy Excess Unreserved General Fund 
#'
#' @param df excess unreserved general fund data frame, eg CSG21 
#' output from get_raw_tges()
#' @param end_year end year that the report was published
#'
#' @return data frame
#' @keywords internal
tidy_excess_unreserved_general_fund <- function(df, end_year) {
  
  #goofy column names from 99-2010  
  if (end_year <= 2010) {
    names(df)[5:7] <- c('ex121', 'ex221', 'ex331')
  }
  
  df$indicator <- 'Excess Unreserved General Fund Balances'
  
  #reshape
  y1_df <- df[, c('group', 'county_name', 'district_code', 'district_name',
                  'ex121', 'file_name', 'indicator')]
  y2_df <- df[, c('group', 'county_name', 'district_code', 'district_name',
                  'ex221', 'file_name', 'indicator')]
  
  indicator_fields <- list(
    'ex121' = 'Actual Excess',
    'ex221' = 'Actual Excess'
  )
  
  y1_df$end_year <- end_year - 2
  y1_df$report_year <- end_year
  names(y1_df) <- tges_name_cleaner(y1_df, indicator_fields)
  
  y2_df$end_year <- end_year - 1
  y2_df$report_year <- end_year
  names(y2_df) <- tges_name_cleaner(y2_df, indicator_fields)
  
  bind_rows(y1_df, y2_df)
}


#' Tidy Vital Statistics
#'
#' @param df vital statistics data frame, eg VITSTAT_TOTAL 
#' output from get_raw_tges()
#' @param end_year end year that the report was published
#'
#' @return data frame
#' @export

tidy_vitstat <- function(df, end_year) {
  
  df$end_year <- end_year - 1
  
  indicator_fields <- list(
    'pp3vv' = 'Total Spending Per Pupil',
    'stpct01vv' = 'Revenue: State %',
    'ltpct01vv' = 'Revenue: Local %',
    'fdpct01vv' = 'Revenue: Federal %',
    'tupct01vv' = 'Revenue: Tuition %',
    'fbpct01vv' = 'Revenue: Free balance %',
    'otpct01vv' = 'Revenue: Other %',
    'strat01vv' = 'Student / Teacher ratio',
    'ssrat01vv' = 'Student / Special Service ratio',
    'sarat01vv' = 'Student / Administrator ratio',
    'pctsevv' = 'Percent Special Education Students'
  )
  names(df) <- tges_name_cleaner(df, indicator_fields)

  #coerce the reported metrics to numeric (N.A. markers -> NA); ids stay as-is
  metric_cols <- intersect(unlist(indicator_fields, use.names = FALSE), names(df))
  for (nm in metric_cols) df[[nm]] <- suppressWarnings(as.numeric(df[[nm]]))

  df
}


#' Tidy Budgetary Per Pupil data frame
#'
#' @param df indicator data frame, eg output of get_raw_tges()
#' @param end_year end year that the report was published
#'
#' @return data.frame

tidy_budgetary_per_pupil_cost <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Budgetary Per Pupil Cost')
}


#' Tidy Total Classroom Instruction data frame
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @keywords internal
tidy_total_classroom_instruction <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Total Classroom Instruction')
}


#' Tidy Classroom Salaries and Benefits
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @keywords internal

tidy_classroom_salaries_benefits <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Classroom Salaries & Benefits')
}


#' Tidy Classroom General Supplies and Textbooks
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @keywords internal

tidy_classroom_general_supplies <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Classroom General Supplies and Textbooks')
}


#' Tidy Classroom Purchased Services and Other
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @keywords internal

tidy_classroom_purchased_services <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Classroom Purchased Services and Other')
}


#' Tidy Total Support Services
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @keywords internal

tidy_total_support_services <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Total Support Services')
}


#' Tidy Support Services Salaries
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @keywords internal

tidy_support_services_salaries <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Support Services Salaries + Benefits')
}


#' Tidy Administrative Costs
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @keywords internal

tidy_administrative_costs <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Total Administrative Costs per Pupil')
}


#' Tidy Legal Services
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @keywords internal

tidy_legal_services <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Legal Services per Pupil')
}


#' Tidy Administrative Salaries and Benefits
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @keywords internal

tidy_admin_salaries <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Salaries + Benefits for Administration')
}


#' Tidy Plant Operations and Maintenance
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @keywords internal

tidy_plant_operations_maintenance <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Operations and Maintenance of Plant')
}


#' Tidy Plant Operations and Maintenance - Salaries and Benefits
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @keywords internal

tidy_plant_operations_maintenance_salaries <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Salaries + Benefits - Operations/Maintenance of Plant')
}


#' Tidy Food Service Costs
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @keywords internal

tidy_food_service <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Food Service Cost per Pupil + Benefits')
}


#' Tidy Extracurricular Costs
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @keywords internal

tidy_extracurricular <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Extracurricular Costs per Pupil + Benefits')
}


#' Tidy Personal Services and Benefits Costs
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @keywords internal

tidy_personal_services_benefits <- function(df, end_year) {
  #CSG14 IS DIFFERENT: it reports employee benefits as a share of total salaries
  #(a fraction, eg 0.31), not a dollar per-pupil cost, but it has the same 3-year
  #wide layout as the budget indicators (pp114/pp214/pp314, or pct98/99/00 in the
  #early percentage-era files).  Reshape it with the 3-year budget tidier, then
  #relabel the single value column to reflect that it is a salary share.
  out <- tidy_generic_budget_indicator(df, end_year, 'Personal Services - Employee Benefits')
  value_cols <- c('Per Pupil costs',
                  'Cost as a percentage of the Total Budgetary Cost Per Pupil')
  names(out)[names(out) %in% value_cols] <- '% of Total Salaries'
  out
}


#' Tidy Equipment Costs
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @keywords internal

tidy_equipment <- function(df, end_year) {
  tidy_generic_budget_indicator(df, end_year, 'Total Equipment Cost per Pupil')
}


#' Tidy Ratio of Students to Teachers
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @keywords internal

tidy_ratio_students_to_teachers <- function(df, end_year) {
  tidy_generic_personnel(df, end_year, 'Ratio of Students to Teachers, Median Salary')
}


#' Tidy Ratio of Students to Special Service
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @keywords internal

tidy_ratio_students_to_special_service <- function(df, end_year) {
  tidy_generic_personnel(df, end_year, 'Ratio of Students to Special Service, Median Salary')  
}


#' Tidy Ratio of Students to Administrators
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @keywords internal

tidy_ratio_students_to_administrators <- function(df, end_year) {
  tidy_generic_personnel(df, end_year, 'Ratio of Students to Administrators, Median Salary')
}


#' Tidy Ratio of Faculty to Administrators
#'
#' @inheritParams tidy_budgetary_per_pupil_cost
#'
#' @return data.frame
#' @keywords internal

tidy_ratio_faculty_to_administrators <- function(df, end_year) {
  tidy_generic_personnel(df, end_year, 'Ratio of Faculty to Administrators')
}


#' Tidy list of TGES data frames
#'
#' @param list_of_dfs list of TGES data frames, eg output of
#' get_raw_tges(). Current valid values are 2001 to 2025.
#' @param end_year year that the report was published
#'
#' @return list of cleaned (wide to long, tidy) dataframes
#' @export

tidy_tges_data <- function(list_of_dfs, end_year) {
  
  #which function cleans which indicator?
  tges_cleaners = list(
    "CSG1AA_AVGS" = 'tidy_total_spending_per_pupil',
    "CSG1" = "tidy_budgetary_per_pupil_cost",
    "CSG2" = "tidy_total_classroom_instruction",
    "CSG3" = "tidy_classroom_salaries_benefits",
    "CSG4" = "tidy_classroom_general_supplies",
    "CSG5" = "tidy_classroom_purchased_services",
    "CSG6" = "tidy_total_support_services",
    "CSG7" = "tidy_support_services_salaries",
    "CSG8" = "tidy_administrative_costs",
    "CSG8A" = "tidy_legal_services",
    "CSG9" = "tidy_admin_salaries",
    "CSG10" = "tidy_plant_operations_maintenance",
    "CSG11" = "tidy_plant_operations_maintenance_salaries",
    "CSG12" = "tidy_food_service",
    "CSG13" = "tidy_extracurricular",
    "CSG14" = "tidy_personal_services_benefits",
    "CSG15" = "tidy_equipment",
    "CSG16" = "tidy_ratio_students_to_teachers",
    "CSG17" = "tidy_ratio_students_to_special_service",
    "CSG18" = "tidy_ratio_students_to_administrators",
    "CSG19" = "tidy_ratio_faculty_to_administrators",
    "CSG20" = "tidy_budgeted_vs_actual_fund_balance",
    "CSG21" = "tidy_excess_unreserved_general_fund",
    "VITSTAT_TOTAL" = "tidy_vitstat"
  )
  
  #apply a cleaning function if known
  out <- map2(
    .x = list_of_dfs, 
    .y = names(list_of_dfs), 
    .f = function(.x, .y) {
      #look up the table name and see if we know how to clean it
      cleaning_function <- tges_cleaners %>% extract2(.y)
      #Total Spending Detail tables are year-stamped (DETAIL_FY24, DETAIL_FY23,
      #...), so match them by prefix rather than enumerating every year.
      if (is.null(cleaning_function) && grepl('^DETAIL_FY', .y)) {
        cleaning_function <- 'tidy_total_spending_detail'
      }
      if (!is.null(cleaning_function)) {
        out <- do.call(cleaning_function, list(.x, end_year))
        
        #1999 data has decimal issues
        if (end_year == 1999) {
          if ('% of Total Salaries' %in% names(out)) {
            out <- out %>%
              mutate(
                `% of Total Salaries` = `% of Total Salaries` / 100
              )
          }
          if ('Cost as a percentage of the Total Budgetary Cost Per Pupil' %in% names(out)) {
            out <- out %>%
              mutate(
                `Cost as a percentage of the Total Budgetary Cost Per Pupil` = `Cost as a percentage of the Total Budgetary Cost Per Pupil` / 100
              )
          }
        }
      #if not, just return it as is
      } else {
        out <- .x
      }
      
      out
    })
  
  out
}


#' Fetch Cleaned Taxpayer's Guide to Educational Spending
#'
#' @inheritParams get_raw_tges
#'
#' @return list of data frames
#' @export

fetch_tges <- function(end_year) {
  get_raw_tges(end_year) %>%
    tidy_tges_data(end_year)
}


#' Fetch Multiple Cleaned Taxpayer's Guides to Educational Spending
#'
#' @param end_year_vector vector of years.  Current valid values
#' are 2001 to 2025.
#'
#' @return list of lists of data frames
#' @export

fetch_many_tges <- function(end_year_vector) {
  all_tges <- map(
    .x = end_year_vector,
    .f = function(.x) {
      print(.x)
      fetch_tges(.x)
    }
  )
  
  names(all_tges) <- end_year_vector
  
  all_tges
}