# njschooldata
a simple interface for accessing NJ DOE school data in R

> It is often said that 80% of data analysis is spent on the process of cleaning and preparing the data (Dasu and Johnson 2003). Data preparation is not just a first step, but must be
repeated many over the course of analysis as new problems come to light or new data is
collected. -[@hadley](http://vita.had.co.nz/papers/tidy-data.pdf)

The State of NJ has been posting raw, fixed width text files with all the assessment results for NJ schools/districts for well over a decade now.  **That's great!**

Unfortunately, those files are a bit of a pain to work with, especially if you're trying to work with multiple grades, or multiple years of data.  Layouts change; file paths aren't consistent, etc.

There are also Excel files posted with all the data, but they aren't much better - for instance, for NJASK data (the assessment used until the transition to PARCC), for every year / grade combination there are on the order of 5 worksheets/tabs per file... a copy/paste nightmare of epic proportions.

`njschooldata` attempts to simplify the task of working with NJ education data by providing a concise and consistent interface for reading state files into R.  We make heavy use of the [tidyverse](https://www.tidyverse.org/) and aim to create a consistent, pipeable interface into NJ state education data.

# Points of Interest

* For any year/grade combination from 2015-2017, a call to `fetch_parcc(end_year, grade_or_subj, subj)` will return relevant statewide PARCC data.  `fetch_all_parcc()` will return data for all years, all grades, all subjects.

* For any year/grade combination from 2004-2014 (before the transition to PARCC/Common Core), a call to `fetch_nj_assess(end_year, grade)` will return the desired data frame as it appears on the state site, and `fetch_nj_assess(end_year, grade, tidy=TRUE)` will return a cleaned up version suitable for longitudinal data analysis.

# Installation

```R
library("devtools")
devtools::install_github("almartin82/njschooldata")
library(njschooldata)
```

# Usage

## Common Core / PARCC era (2015-present)

read in the 2015 grade 7 PARCC ELA data file:
```R
fetch_parcc(end_year = 2015, grade_or_subj = 7, subj = 'ela')
```

read in the 2016 grade 4 PARCC Math data file:
```R
fetch_parcc(end_year = 2016, grade_or_subj = 4, subj = 'math')
```

read in the 2017 HS Algebra data file:
```R
fetch_parcc(end_year = 2017, grade_or_subj = 'ALG1', subj = 'math')
```

## Pre-Common Core / NJASK era (2004-2014)

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

read in the 2014 HS cohort graduation rate data file (NJ has charmingly named this 'grate'):
```R
fetch_grate(end_year = 2014, tidy = TRUE)
```

read in the 2002 HS graduate data file :
```R
fetch_grate(end_year = 2002, tidy = TRUE)
```

# Contributing

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

Contributions are welcome!

Comments?  Questions?  Problem?  Want to contribute to development?  File an [issue](https://github.com/almartin82/njschooldata/issues) or send me an [email](mailto:almartin@gmail.com). 


# Coverage
Anytime a year is passed as a parameter for assessment data, it referrs to the 'end_year' -- ie, the `2014-15` school year is `2015`.

PARCC data runs from 2015-present and covers grades 3-11 in ELA and grades 3-8 and subjects 'ALG1', 'GEO', 'ALG2' in Math.

NJASK data runs from 2004-2014, roughly (there were a number of revisions to the assessment program, so grade coverage depends on the year.  Look at [valid call](https://github.com/almartin82/njschooldata/blob/928992aebb7ab0c4fa0012079611de2a26f73d6a/R/fetch_nj_assess.R#L9) for the gory details.)


# Longitudinal Analysis

The flat files provided by the state are a bit painful to work with.  The layout isn't consistent across years or assessments, making longitudinal analysis a pain.  Here's what the first 50 columns of the 2014 NJASK data file look like:

```R
  [1] "CDS_Code"                                                                              
  [2] "County_Code/DFG/Aggregation_Code"                                                      
  [3] "District_Code"                                                                         
  [4] "School_Code"                                                                           
  [5] "County_Name"                                                                           
  [6] "District_Name"                                                                         
  [7] "School_Name"                                                                           
  [8] "DFG"                                                                                   
  [9] "Special_Needs"                                                                         
 [10] "TOTAL_POPULATION_Number_Enrolled_ELA"                                                  
 [11] "TOTAL_POPULATION_LANGUAGE_ARTS_Number_Not_Present"                                     
 [12] "TOTAL_POPULATION_LANGUAGE_ARTS_Number_of_Voids"                                        
 [13] "TOTAL_POPULATION_LANGUAGE_ARTS_Number_APA"                                             
 [14] "TOTAL_POPULATION_LANGUAGE_ARTS_Number_of_Valid_Scale_Scores"                           
 [15] "TOTAL_POPULATION_LANGUAGE_ARTS_Partially_Proficient_Percentage"                        
 [16] "TOTAL_POPULATION_LANGUAGE_ARTS_Proficient_Percentage"                                  
 [17] "TOTAL_POPULATION_LANGUAGE_ARTS_Advanced_Proficient_Percentage"                         
 [18] "TOTAL_POPULATION_LANGUAGE_ARTS_Scale_Score_Mean"                                       
 [19] "TOTAL_POPULATION_MATHEMATICS_Number_Enrolled_Math"                                   
 [20] "TOTAL_POPULATION_MATHEMATICS_Number_Not_Present"                                       
 [21] "TOTAL_POPULATION_MATHEMATICS_Number_of_Voids"                                        
 [22] "TOTAL_POPULATION_MATHEMATICS_Number_APA"                                               
 [23] "TOTAL_POPULATION_MATHEMATICS_Number_of_Valid_Scale_Scores"                             
 [24] "TOTAL_POPULATION_MATHEMATICS_Partially_Proficient_Percentage"                          
 [25] "TOTAL_POPULATION_MATHEMATICS_Proficient_Percentage"                                    
 [26] "TOTAL_POPULATION_MATHEMATICS_Advanced_Proficient_Percentage"                           
 [27] "TOTAL_POPULATION_MATHEMATICS_Scale_Score_Mean"                                         
 [28] "TOTAL_POPULATION_SCIENCE_Number_Enrolled_Science"                                      
 [29] "TOTAL_POPULATION_SCIENCE_Number_Not_Present"                                           
 [30] "TOTAL_POPULATION_SCIENCE_Number_of_Voids"                                              
 [31] "TOTAL_POPULATION_SCIENCE_Number_APA"                                                   
 [32] "TOTAL_POPULATION_SCIENCE_Number_of_Valid_Scale_Scores"                                 
 [33] "TOTAL_POPULATION_SCIENCE_Partially_Proficient_Percentage"                              
 [34] "TOTAL_POPULATION_SCIENCE_Proficient_Percentage"                                        
 [35] "TOTAL_POPULATION_SCIENCE_Advanced_Proficient_Percentage"                               
 [36] "TOTAL_POPULATION_SCIENCE_Scale_Score_Mean"                                             
 [37] "GENERAL_EDUCATION_Number_Enrolled_ELA"                                                 
 [38] "GENERAL_EDUCATION_LANGUAGE_ARTS_Number_Not_Present"                                    
 [39] "GENERAL_EDUCATION_LANGUAGE_ARTS_Number_of_Voids"                                       
 [40] "GENERAL_EDUCATION_LANGUAGE_ARTS_Number_APA"                                            
 [41] "GENERAL_EDUCATION_LANGUAGE_ARTS_Number_of_Valid_Scale_Scores"                          
 [42] "GENERAL_EDUCATION_LANGUAGE_ARTS_Partially_Proficient_Percentage"                       
 [43] "GENERAL_EDUCATION_LANGUAGE_ARTS_Proficient_Percentage"                                 
 [44] "GENERAL_EDUCATION_LANGUAGE_ARTS_Advanced_Proficient_Percentage"
 [45] "GENERAL_EDUCATION_LANGUAGE_ARTS_Scale_Score_Mean"                                      
 [46] "GENERAL_EDUCATION_MATHEMATICS_Number_Enrolled_Math"                                    
 [47] "GENERAL_EDUCATION_MATHEMATICS_Number_Not_Present"                                      
 [48] "GENERAL_EDUCATION_MATHEMATICS_Number_of_Voids"                                         
 [49] "GENERAL_EDUCATION_MATHEMATICS_Number_APA"                                          
 [50] "GENERAL_EDUCATION_MATHEMATICS_Number_of_Valid_Scale_Scores"    
```
(and on and on and on, for a grand total of 551 columns.)  Aside from the virtue of one row per school, there's not a lot to be said about this format - it violates multiple [tidy data](http://vita.had.co.nz/papers/tidy-data.pdf) principles.

`fetch_nj_assess` has a parameter `tidy` that will return a processed version of the assessment results designed to facilitate longitudinal data analysis.  Instead of 500+ columns, a consistent data frame structure is returned.  Instead of using column headers for values, subgroup and test name data are stored as variables.  This makes the resulting data frame considerably longer (69,960 rows vs 1,160 rows for a recent NJASK example), but _significantly_ easier to work with.  

Here's an example of a tidied NJASK data file:

```R
  assess_name testing_year grade county_code district_code school_code district_name
1       NJASK         2011     5          ST            NA          NA              
2       NJASK         2011     5          NS            NA          NA              
3       NJASK         2011     5          SN            NA          NA              
4       NJASK         2011     5          25           100          NA   ASBURY PARK
5       NJASK         2011     5          25           100          40   ASBURY PARK
6       NJASK         2011     5          01           110          NA ATLANTIC CITY
         school_name dfg special_needs         subgroup    assessment number_enrolled
1                     NA            NA total_population language_arts          103759
2                     NA            NA total_population language_arts           83778
3                     NA            NA total_population language_arts           19981
4                     NA            NA total_population language_arts             155
5 BRADLEY ELEMENTARY  NA            NA total_population language_arts              32
6                     NA            NA total_population language_arts             439
  number_not_present number_of_voids number_of_valid_classifications number_apa
1                164          103759                              NA        893
2                113           83778                              NA        696
3                 51           19981                              NA        197
4                  0             155                              NA          0
5                  0              32                              NA          0
6                  1             439                              NA          2
  number_valid_scale_scores partially_proficient proficient advanced_proficient
1                    102320                 39.1       54.8                 6.1
2                     82708                 32.7       60.0                 7.3
3                     19612                 65.9       33.1                 1.0
4                       154                 83.8       16.2                 0.0
5                        31                 80.6       19.4                 0.0
6                       433                 58.4       40.6                 0.9
  scale_score_mean
1            205.0
2            209.3
3            186.8
4            174.7
5            180.8
6            190.9
```
