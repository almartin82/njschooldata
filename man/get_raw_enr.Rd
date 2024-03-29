% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/enr.R
\name{get_raw_enr}
\alias{get_raw_enr}
\title{read a zipped excel fall enrollment file from the NJ state website}
\usage{
get_raw_enr(end_year)
}
\arguments{
\item{end_year}{a school year.  year is the end of the academic year - eg 2006-07
school year is year '2007'.  valid values are 2000-2023.}
}
\description{
\code{get_raw_enr} returns a data frame with a year's worth of fall school and 
grade level enrollment data.
}
