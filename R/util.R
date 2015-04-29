#' @title trim_whitespace
#' @description trims whitespace
#' @param x string or vector of strings
#' @export

trim_whitespace <- function (x) gsub("^\\s+|\\s+$", "", x)