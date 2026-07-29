# New Jersey official source endpoints

The package-owned source registry in `R/source_registry.R` is the authority for
New Jersey Department of Education endpoint families and supported periods.
The source-adapter provenance ledger at
`inst/extdata/test-fixtures/source-adapters/provenance.json` pins the official
NJDOE URL and full-source checksum used for each checked-in parser fixture.

Those fixtures are deliberately small source-derived slices, not complete
upstream artifacts. Their parent bytes are not checked in, so this contract
uses the slices only as deterministic goldens and claims no shipped artifact
coverage. Live validation is manual-only and has never been run for this
contract.
