# Is a file a real .xlsx (ZIP) rather than an HTTP error / bot page?

`.xlsx` files are ZIP archives and begin with the bytes `PK`
(`0x50 0x4B`). Error pages begin with `<` or are tiny. This guard
prevents a failed download from being cached or parsed as data.

## Usage

``` r
is_valid_xlsx(path)
```

## Arguments

- path:

  File path to check.

## Value

`TRUE` if the file looks like a valid workbook.
