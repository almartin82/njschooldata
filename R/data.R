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

#' Multi-Campus Charter Host-City Apportionment
#'
#' A year-aware companion to \code{\link{charter_city}} that splits the
#' NJ-reported totals of multi-campus charter schools across their host cities.
#' NJ DOE assigns one \code{district_id} per charter and does NOT report charter
#' campuses separately, but a few charters operate campuses in more than one host
#' city under a single \code{district_id}. For those, attributing 100% of the
#' charter's enrollment to one host city (as the 1:1 \code{charter_city} map
#' would) overstates that city's charter sector and erases the other host city.
#'
#' Each row gives the fraction (\code{share}) of a charter's NJ-reported totals
#' attributed to one host city in one year. Shares sum to 1.0 per
#' \code{district_id} per \code{end_year}. Single-city charters need NO entry
#' here (their implicit share is 1.0 via \code{charter_city});
#' \code{\link{id_charter_hosts}} only expands charters that appear in this
#' table. Downstream charter-sector and all-public aggregations multiply summed
#' counts by \code{share} before summing, so the charter's total is preserved
#' exactly across host cities.
#'
#' \strong{This is apportionment of real data, not fabrication.} The charter
#' TOTAL enrollment is REAL NJ DOE data; only its allocation across host cities
#' is an explicit, documented apportionment, used because NJ does not report
#' campuses separately. A 0.5/0.5 split is an explicit PLACEHOLDER (see
#' \code{share_basis}), never an NJ-reported campus count. No campus-level
#' enrollment numbers are invented.
#'
#' Currently the only entry is M.E.T.S. Charter School (district 6068), which ran
#' a Jersey City campus and opened a Newark campus in 2017: through 2017 it is
#' 100% Jersey City; from 2018 it is a documented 50/50 Jersey City / Newark
#' placeholder. KIPP TEAM Academy / KIPP Paterson (district 7325) was
#' investigated as a candidate but NOT added: the NJ DOE directory shows district
#' 7325 in Newark only, with no Paterson campus reporting under that
#' \code{district_id}, so no verifiable share exists.
#'
#' @format A data frame with 8 columns:
#' \describe{
#'   \item{district_id}{Charter school district identifier (matches \code{charter_city$district_id})}
#'   \item{end_year}{School year ending year the share applies to (integer)}
#'   \item{host_county_id}{County code of the host district}
#'   \item{host_county_name}{County name of the host district}
#'   \item{host_district_id}{Host district identifier}
#'   \item{host_district_name}{Host district name}
#'   \item{share}{Fraction of the charter's NJ-reported totals attributed to this host city; sums to 1.0 per district_id per end_year}
#'   \item{share_basis}{Documented provenance of the share (e.g. single-campus year vs PLACEHOLDER split)}
#' }
#' @seealso \code{\link{charter_city}}, \code{\link{id_charter_hosts}}
#' @source NJ Department of Education enrollment files and school directory;
#'   host-city allocation is an explicit documented apportionment (see Details).
"charter_host_apportionment"

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

#' Subgroup Standardization Crosswalk
#'
#' Maps the cleaned subgroup labels emitted by the three in-package subgroup
#' cleaners (\code{clean_spr_subgroups}, \code{tidy_parcc_subgroup},
#' \code{clean_6yr_grad_subgroups}) onto a single shared \code{subgroup_std}
#' vocabulary. This lets code that consumes different source families filter on
#' one common set of tokens. It is a non-breaking add-on: the source-specific
#' \code{subgroup} values are unchanged, and \code{subgroup_std} is attached
#' alongside them by \code{\link{add_subgroup_std}} /
#' \code{\link{standardize_subgroup}}.
#'
#' Every \code{raw_value} is traced directly from the output of the three
#' cleaners (not hand-invented). Labels with no standard equivalent (for
#' example special-education accommodation flags or PARCC grade breakdowns) are
#' listed with \code{subgroup_std = NA} so coverage is fully documented.
#'
#' @format A data frame with 4 columns:
#' \describe{
#'   \item{raw_value}{Cleaned subgroup label emitted by a cleaner}
#'   \item{vocab_family}{Source cleaner family: one of \code{"spr"},
#'     \code{"parcc"}, \code{"grad6yr"}}
#'   \item{subgroup_std}{Standard subgroup token, or \code{NA} when the label
#'     has no standard equivalent}
#'   \item{dimension}{Conceptual dimension: one of \code{"total"},
#'     \code{"econ"}, \code{"disability"}, \code{"el"}, \code{"race"},
#'     \code{"gender"}, or \code{NA} for labels with no standard equivalent}
#' }
#' @seealso \code{\link{standardize_subgroup}}, \code{\link{add_subgroup_std}}
#' @source Derived from the in-package subgroup cleaners; rebuild with
#'   \code{data-raw/build_subgroup_crosswalk.R}
"subgroup_crosswalk"

#' Era Break Metadata
#'
#' A documented metadata table of New Jersey assessment, attendance,
#' graduation, and economically disadvantaged definition break years. These
#' rows identify years where trend code should segment or flag results rather
#' than drawing a continuous line across a regime change or COVID disruption.
#'
#' The \code{break_set} values align to the package's metric registry era
#' groups. \code{scale_break} and \code{definition_change} rows start a new
#' \code{\link{tag_era}} era. \code{covid_gap} rows are flagged as break years
#' but do not start a new scale era.
#'
#' @format A data frame with 11 rows and 6 columns:
#' \describe{
#'   \item{break_set}{Metric family key, such as \code{"njsla"},
#'     \code{"grad"}, \code{"attendance"}, or \code{"econ_disadv"}}
#'   \item{break_year}{School year ending year for the break}
#'   \item{break_type}{Break type: one of \code{"scale_break"},
#'     \code{"covid_gap"}, or \code{"definition_change"}}
#'   \item{label}{Short human-readable break label}
#'   \item{comparable_prior}{Logical flag indicating whether the prior-year
#'     value is comparable across the break; \code{NA} for COVID gap rows where
#'     comparability is not a scale question}
#'   \item{notes}{Public-record justification for the break}
#' }
#' @seealso \code{\link{get_era_breaks}}, \code{\link{tag_era}},
#'   \code{\link{assert_no_break_span}}
#' @source NJDOE and NJDA public assessment, school-performance, graduation,
#'   attendance, school-meals, and ASSA guidance; rebuild with
#'   \code{data-raw/build_era_breaks.R}
"era_breaks"
