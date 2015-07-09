# njschooldata
a simple interface for accessing NJ DOE school data in R

[![Build Status](https://travis-ci.org/almartin82/njschooldata.png?branch=master)](https://travis-ci.org/almartin82/njschooldata) [![Coverage Status](https://coveralls.io/repos/almartin82/njschooldata/badge.svg?branch=master)](https://coveralls.io/r/almartin82/njschooldata?branch=master)

The State of NJ has been posting raw, fixed width text files with all the assessment results for NJ schools/districts for about a decade now.  **That's great!**

Unfortunately, those files are a bit of a pain to work with, especially if you're trying to work with multiple grades, or multiple years of data.  Layouts change; file paths aren't consistent, etc.

There are also Excel files posted with all the data, but they aren't much better - for every year / grade combination (~70) there are on the order of 5 worksheets/tabs per file... a copy/paste nightmare of epic proportions.

Fortunately, there's a new R library, [`readr`] (https://github.com/hadley/readr) (written by [Hadley Wickham](https://github.com/hadley)) for working with fixed width files that makes this process much, much easier.

`njschooldata` attempts to simplify the task of working with NJ education data by providing a simple, consistent interface for reading state files into R. For any year/grade combination from 2004-onward, a simple call to `fetch_nj_assess(end_year, grade)` will return the desired data frame.

# Installation

```R
library("devtools")
devtools::install_github("almartin82/njschooldata")
library(njschooldata)
```

# Usage

read in the 2010 grade 5 NJASK data file:
```R
fetch_nj_assess(end_year = 2010, grade = 5)
```

read in the 2007 High School Proficiency Assessment (HSPA) data file:
```R
fetch_nj_assess(end_year = 2007, grade = 11)
```

read in the 2005 state enrollment data file:
```R
fetch_enr(end_year = 2005)
```

# Coverage
Anytime a year is passed as a parameter for assessment data, it referrs to the 'end_year' -- ie, the `2014-15` school year is `2015`.

NJASK data runs from 2004-2014, roughly (there were a number of revisions to the assessment program, so grade coverage depends on the year.  Look at [valid call](https://github.com/almartin82/njschooldata/blob/928992aebb7ab0c4fa0012079611de2a26f73d6a/R/fetch_nj_assess.R#L9) for the gory details.)


# Contributing

Comments?  Questions?  Problem?  Want to contribute to development?  File an [issue](https://github.com/almartin82/njschooldata/issues) or send me an [email]('mailto:almartin@gmail.com'). 
