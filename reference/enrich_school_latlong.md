# Enrich School Data with Lat / Long

Enrich School Data with Lat / Long

## Usage

``` r
enrich_school_latlong(df, use_cache = TRUE, api_key = "")
```

## Arguments

- df:

  dataframe to be enriched

- use_cache:

  if TRUE (the default), reads cached school info / lat lng from the
  bundled \`geocoded_cached\` dataset and does not hit a geocoding
  service. Set FALSE to geocode live via tidygeocoder.

- api_key:

  optional Google Maps API key. When supplied (and \`use_cache=FALSE\`),
  a Google geocoding pass is added to the cascade. When empty, geocoding
  uses only the keyless US Census + OpenStreetMap cascade.

## Value

dataframe enriched with lat lng

## Note

Live geocoding (\`use_cache=FALSE\`) requires the tidygeocoder package.
Install with: \`install.packages('tidygeocoder')\`. It uses the keyless
US Census geocoder with an OpenStreetMap (Nominatim) fallback, so no API
key is needed.
