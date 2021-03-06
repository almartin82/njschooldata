% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/parcc.R
\name{fetch_parcc}
\alias{fetch_parcc}
\title{gets and cleans up a PARCC data file file}
\usage{
fetch_parcc(end_year, grade_or_subj, subj, tidy = FALSE)
}
\arguments{
\item{end_year}{a school year.  end_year is the end of the academic year - eg 2014-15
school year is end_year 2015.  valid values are 2015-2017}

\item{grade_or_subj}{grade level (eg 8) OR math subject code (eg ALG1, GEO, ALG2)}

\item{subj}{PARCC subject. c('ela' or 'math')}

\item{tidy}{clean up the data frame to make it more compatible with 
NJASK naming conventions and do some additional calculations?  default is FALSE.}
}
\description{
\code{fetch_parcc} is a wrapper around \code{get_raw_parcc} and
\code{process_parcc} that gets a parcc file and performs any cleanup.
}
