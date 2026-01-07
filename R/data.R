#' Charter School Host District Mapping
#'
#' A dataset containing charter schools and their host districts/cities in New Jersey.
#' Charter schools are public schools that operate independently but are accountable to
#' their authorizing districts (host districts).
#'
#' @format A data frame with 137 rows and 6 columns:
#' \describe{
#'   \item{district_id}{Charter school district identifier}
#'   \item{district_name}{Charter school district name}
#'   \item{host_county_id}{County code of the host district}
#'   \item{host_county_name}{County name of the host district}
#'   \item{host_district_id}{Host district identifier}
#'   \item{host_district_name}{Host district name}
#' }
#' @source NJ Department of Education
"charter_city"

#' Newark Address Addendum
#'
#' Additional address data for Newark schools to supplement geocoding.
#' Contains school addresses that were not included in the main school
#' directory or needed corrections for proper geocoding.
#'
#' @format A data frame with 98 rows and 5 columns:
#' \describe{
#'   \item{district_id}{District identifier (Newark district is 3570)}
#'   \item{school_id}{School identifier code}
#'   \item{school_name}{Name of the school}
#'   \item{address}{Full street address with city, state}
#'   \item{in_geocode}{Logical indicating if address is in geocode cache}
#' }
#' @source Manual address corrections for Newark schools
"nwk_address_addendum"

#' Geocoded School Addresses
#'
#' Cached geocoding results for New Jersey school addresses. Contains latitude,
#' longitude, and formatted addresses for schools, primarily Newark addresses.
#'
#' @format A data frame with 2,549 rows and 8 columns:
#' \describe{
#'   \item{lat}{Latitude coordinate}
#'   \item{lng}{Longitude coordinate}
#'   \item{formatted_address}{Standardized address string}
#'   \item{status}{Geocoding status (e.g., "tidygeocoder cascade")}
#'   \item{location_type}{Location type from geocoding service}
#'   \item{error_message}{Error message if geocoding failed}
#'   \item{locations}{Original location string used for geocoding}
#'   \item{input_url}{Input URL for geocoding request}
#' }
#' @source Geocoded using tidygeocoder package
"geocoded"

#' GEPA Fixed-Width File Layout
#'
#' Column layout specification for reading Grade Eight Proficiency Assessment (GEPA)
#' fixed-width format data files.
#'
#' @format A data frame with 486 rows and 10 columns:
#' \describe{
#'   \item{field_start_position}{Starting position of field in fixed-width file}
#'   \item{field_end_position}{Ending position of field in fixed-width file}
#'   \item{field_length}{Length of field in characters}
#'   \item{data_type}{Data type of field (e.g., "Text", "Numeric")}
#'   \item{description}{Description of field}
#'   \item{comments}{Additional comments about field}
#'   \item{valid_values}{Valid values or ranges for field}
#'   \item{spanner1}{First-level column grouping label}
#'   \item{spanner2}{Second-level column grouping label}
#'   \item{final_name}{Final column name to use in parsed data}
#' }
#' @source NJ Department of Education GEPA file specifications
"layout_gepa"

#' GEPA 2005 Fixed-Width File Layout
#'
#' Column layout specification for reading Grade Eight Proficiency Assessment (GEPA)
#' 2005 fixed-width format data files.
#'
#' @format A data frame with 383 rows and 10 columns:
#' \describe{
#'   \item{field_start_position}{Starting position of field in fixed-width file}
#'   \item{field_end_position}{Ending position of field in fixed-width file}
#'   \item{field_length}{Length of field in characters}
#'   \item{data_type}{Data type of field (e.g., "Text", "Numeric")}
#'   \item{description}{Description of field}
#'   \item{comments}{Additional comments about field}
#'   \item{valid_values}{Valid values or ranges for field}
#'   \item{spanner1}{First-level column grouping label}
#'   \item{spanner2}{Second-level column grouping label}
#'   \item{final_name}{Final column name to use in parsed data}
#' }
#' @source NJ Department of Education GEPA 2005 file specifications
"layout_gepa05"

#' GEPA 2006 Fixed-Width File Layout
#'
#' Column layout specification for reading Grade Eight Proficiency Assessment (GEPA)
#' 2006 fixed-width format data files.
#'
#' @format A data frame with column layout specifications including field positions,
#'   lengths, data types, descriptions, and final column names.
#' @source NJ Department of Education GEPA 2006 file specifications
"layout_gepa06"

#' HSPA Fixed-Width File Layout
#'
#' Column layout specification for reading High School Proficiency Assessment (HSPA)
#' fixed-width format data files.
#'
#' @format A data frame with 559 rows and 10 columns:
#' \describe{
#'   \item{field_start_position}{Starting position of field in fixed-width file}
#'   \item{field_end_position}{Ending position of field in fixed-width file}
#'   \item{field_length}{Length of field in characters}
#'   \item{data_type}{Data type of field (e.g., "Text", "Numeric")}
#'   \item{description}{Description of field}
#'   \item{comments}{Additional comments about field}
#'   \item{valid_values}{Valid values or ranges for field}
#'   \item{spanner1}{First-level column grouping label}
#'   \item{spanner2}{Second-level column grouping label}
#'   \item{final_name}{Final column name to use in parsed data}
#' }
#' @source NJ Department of Education HSPA file specifications
"layout_hspa"

#' HSPA 2004 Fixed-Width File Layout
#'
#' Column layout specification for reading High School Proficiency Assessment (HSPA)
#' 2004 fixed-width format data files.
#'
#' @format A data frame with column layout specifications including field positions,
#'   lengths, data types, descriptions, and final column names.
#' @source NJ Department of Education HSPA 2004 file specifications
"layout_hspa04"

#' HSPA 2005 Fixed-Width File Layout
#'
#' Column layout specification for reading High School Proficiency Assessment (HSPA)
#' 2005 fixed-width format data files.
#'
#' @format A data frame with column layout specifications including field positions,
#'   lengths, data types, descriptions, and final column names.
#' @source NJ Department of Education HSPA 2005 file specifications
"layout_hspa05"

#' HSPA 2006 Fixed-Width File Layout
#'
#' Column layout specification for reading High School Proficiency Assessment (HSPA)
#' 2006 fixed-width format data files.
#'
#' @format A data frame with column layout specifications including field positions,
#'   lengths, data types, descriptions, and final column names.
#' @source NJ Department of Education HSPA 2006 file specifications
"layout_hspa06"

#' HSPA 2010 Fixed-Width File Layout
#'
#' Column layout specification for reading High School Proficiency Assessment (HSPA)
#' 2010 fixed-width format data files.
#'
#' @format A data frame with column layout specifications including field positions,
#'   lengths, data types, descriptions, and final column names.
#' @source NJ Department of Education HSPA 2010 file specifications
"layout_hspa10"

#' NJASK Fixed-Width File Layout
#'
#' Column layout specification for reading New Jersey Assessment of Skills and Knowledge
#' (NJASK) fixed-width format data files.
#'
#' @format A data frame with 551 rows and 10 columns:
#' \describe{
#'   \item{field_start_position}{Starting position of field in fixed-width file}
#'   \item{field_end_position}{Ending position of field in fixed-width file}
#'   \item{field_length}{Length of field in characters}
#'   \item{data_type}{Data type of field (e.g., "Text", "Numeric")}
#'   \item{description}{Description of field}
#'   \item{comments}{Additional comments about field}
#'   \item{valid_values}{Valid values or ranges for field}
#'   \item{spanner1}{First-level column grouping label}
#'   \item{spanner2}{Second-level column grouping label}
#'   \item{final_name}{Final column name to use in parsed data}
#' }
#' @source NJ Department of Education NJASK file specifications
"layout_njask"

#' NJASK 2004 Fixed-Width File Layout
#'
#' Column layout specification for reading New Jersey Assessment of Skills and Knowledge
#' (NJASK) 2004 fixed-width format data files.
#'
#' @format A data frame with column layout specifications including field positions,
#'   lengths, data types, descriptions, and final column names.
#' @source NJ Department of Education NJASK 2004 file specifications
"layout_njask04"

#' NJASK 2005 Fixed-Width File Layout
#'
#' Column layout specification for reading New Jersey Assessment of Skills and Knowledge
#' (NJASK) 2005 fixed-width format data files.
#'
#' @format A data frame with column layout specifications including field positions,
#'   lengths, data types, descriptions, and final column names.
#' @source NJ Department of Education NJASK 2005 file specifications
"layout_njask05"

#' NJASK 2006 Grade 3 Fixed-Width File Layout
#'
#' Column layout specification for reading New Jersey Assessment of Skills and Knowledge
#' (NJASK) 2006 Grade 3 fixed-width format data files.
#'
#' @format A data frame with column layout specifications including field positions,
#'   lengths, data types, descriptions, and final column names.
#' @source NJ Department of Education NJASK 2006 Grade 3 file specifications
"layout_njask06gr3"

#' NJASK 2006 Grade 5 Fixed-Width File Layout
#'
#' Column layout specification for reading New Jersey Assessment of Skills and Knowledge
#' (NJASK) 2006 Grade 5 fixed-width format data files.
#'
#' @format A data frame with column layout specifications including field positions,
#'   lengths, data types, descriptions, and final column names.
#' @source NJ Department of Education NJASK 2006 Grade 5 file specifications
"layout_njask06gr5"

#' NJASK 2007 Grade 3 Fixed-Width File Layout
#'
#' Column layout specification for reading New Jersey Assessment of Skills and Knowledge
#' (NJASK) 2007 Grade 3 fixed-width format data files.
#'
#' @format A data frame with column layout specifications including field positions,
#'   lengths, data types, descriptions, and final column names.
#' @source NJ Department of Education NJASK 2007 Grade 3 file specifications
"layout_njask07gr3"

#' NJASK 2007 Grade 5 Fixed-Width File Layout
#'
#' Column layout specification for reading New Jersey Assessment of Skills and Knowledge
#' (NJASK) 2007 Grade 5 fixed-width format data files.
#'
#' @format A data frame with column layout specifications including field positions,
#'   lengths, data types, descriptions, and final column names.
#' @source NJ Department of Education NJASK 2007 Grade 5 file specifications
"layout_njask07gr5"

#' NJASK 2009 Fixed-Width File Layout
#'
#' Column layout specification for reading New Jersey Assessment of Skills and Knowledge
#' (NJASK) 2009 fixed-width format data files.
#'
#' @format A data frame with column layout specifications including field positions,
#'   lengths, data types, descriptions, and final column names.
#' @source NJ Department of Education NJASK 2009 file specifications
"layout_njask09"

#' NJASK 2010 Fixed-Width File Layout
#'
#' Column layout specification for reading New Jersey Assessment of Skills and Knowledge
#' (NJASK) 2010 fixed-width format data files.
#'
#' @format A data frame with 524 rows and 10 columns:
#' \describe{
#'   \item{field_start_position}{Starting position of field in fixed-width file}
#'   \item{field_end_position}{Ending position of field in fixed-width file}
#'   \item{field_length}{Length of field in characters}
#'   \item{data_type}{Data type of field (e.g., "Text", "Numeric")}
#'   \item{description}{Description of field}
#'   \item{comments}{Additional comments about field}
#'   \item{valid_values}{Valid values or ranges for field}
#'   \item{spanner1}{First-level column grouping label}
#'   \item{spanner2}{Second-level column grouping label}
#'   \item{final_name}{Final column name to use in parsed data}
#' }
#' @source NJ Department of Education NJASK 2010 file specifications
"layout_njask10"

#' NJ Program Codes
#'
#' Program codes used by the New Jersey Department of Education for student enrollment
#' reporting. Includes grade levels, special education programs, and other educational
#' programs.
#'
#' @format A data frame with 682 rows and 3 columns:
#' \describe{
#'   \item{end_year}{School year ending year}
#'   \item{program_code}{Two-digit program code}
#'   \item{program_name}{Program name or description}
#' }
#' @source NJ Department of Education
"prog_codes"

#' Special Education District Lookup Map
#'
#' Mapping of county names to district names and district IDs for New Jersey school
#' districts. Used for matching special education data to districts.
#'
#' @format A data frame with 578 rows and 3 columns:
#' \describe{
#'   \item{county_name}{County name}
#'   \item{district_name}{District name}
#'   \item{district_id}{District identifier code}
#' }
#' @source NJ Department of Education
"sped_lookup_map"
