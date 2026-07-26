# Download and validate a registered NJ DOE source

Downloads are written to a temporary file, validated, and then
atomically promoted into an optional cache path. Transport failures and
artifact/parser failures have distinct source statuses.

## Usage

``` r
download_source(
  url,
  source_type,
  cache_path = NULL,
  timeout = 60,
  retries = 2L,
  allowed_hosts = source_host_allowlist(),
  allow_http = FALSE,
  request_fn = .default_source_request,
  sleep_fn = Sys.sleep
)
```

## Arguments

- url:

  HTTPS source URL.

- source_type:

  One of \`xlsx\`, \`xls\`, \`zip\`, \`csv\`, \`text\`, \`json\`, or
  \`html\`.

- cache_path:

  Optional validated artifact cache path.

- timeout:

  Bounded request timeout in seconds.

- retries:

  Number of retries after the initial transient failure.

- allowed_hosts:

  Explicit host allowlist, defaulting to registered hosts.

- allow_http:

  Permit plaintext HTTP for a narrowly scoped historical source. Active
  sources should leave this \`FALSE\`.

- request_fn:

  Injectable request implementation for offline tests.

- sleep_fn:

  Injectable retry delay implementation.

## Value

An \`njsd_source_result\` whose data is the validated local path.
