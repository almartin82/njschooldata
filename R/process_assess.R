#' @title process a nj assessment file 
#' 
#' @description
#' \code{process_njask} does cleanup of the raw assessment file, primarily ensuring that 
#' columns tagged as 'one implied' are displayed correctly#' 
#' @param df a raw NJASK, HSPA, or GEPA data frame (eg output of \code{get_raw_njask})
#' @param layout which layout file to use to determine which columns are one implied 
#' decimal.
#' @export

process_nj_assess <- function(df, layout) {
  #build a mask
  mask <- layout$comments == 'One implied decimal'
    
  #keep the names to put back in the same order
  all_names <- names(df)
  
  #make sure df is data frame (not dplyr data frame) so that normal subsetting
  df <- as.data.frame(df)

  #get name of last column and kill \n characters
  last_col <- names(df)[ncol(df)]
  df[, last_col] <- gsub('\n', '', df[, last_col], fixed = TRUE)
      
  #put some columns aside
  ignore <- df[, !mask]
  
  implied_decimal_fix <- function(x) {
    #strip out anything that's not a number.
    x <- as.numeric(gsub("[^\\d]+", "", x, perl=TRUE))
    x / 10
  }

  #process the columns that have an implied decimal
  processed <- df[, mask] %>%
    dplyr::mutate_each(
      dplyr::funs(implied_decimal_fix)  
    )
  
  #put back together 
  final <- cbind(ignore, processed)
  
  #reorder and return
  final %>%
    dplyr::select(
      one_of(names(df))
    )
}
