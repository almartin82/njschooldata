# Task 09: Fix Documentation Issues

## Problems

1. **Undocumented object**: `nwk_address_addendum`
2. **Data codoc mismatch**: `grad_url_config.Rd` - docs say `url_pattern` but code doesn't have it
3. **Documented arguments not in \usage**:
   - `process_grad_rate.Rd` - has `description` param documented but not in function
   - `rc_year_matcher.Rd` - has `end_year` param documented but not in function

## Solutions

### 1. Document nwk_address_addendum

Add to `R/data.R`:
```r
#' Newark Address Addendum
#'
#' Additional address data for Newark schools to supplement geocoding.
#'
#' @format A data frame with address corrections for Newark schools
#' @source Manual corrections for geocoding
"nwk_address_addendum"
```

### 2. Fix grad_url_config.Rd

Check the actual structure of grad_url_config and update documentation to match.

### 3. Fix process_grad_rate.Rd

Remove `@param description` if not in function signature, or add parameter to function.

### 4. Fix rc_year_matcher.Rd

The function signature is `rc_year_matcher(df)` but docs mention `end_year`.
Looking at the code, `end_year` comes from `df$end_year`, not as a parameter.
Remove `@param end_year` from the roxygen block.

## Files to Modify

1. `R/data.R` - Add nwk_address_addendum documentation
2. `R/url_config.R` - Fix grad_url_config documentation
3. `R/grate.R` - Fix process_grad_rate documentation (if it exists there)
4. `R/util.R` - Fix rc_year_matcher documentation
