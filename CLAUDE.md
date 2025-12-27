# CLAUDE.md

## Project Overview
R package for fetching and processing New Jersey school data from the NJ Department of Education.

## Commit Guidelines
- Do NOT include Claude's name, "Co-Authored-By", or any AI attribution in commit messages
- Keep commit messages concise and focused on the changes made

## Slash Commands
- `/deploy` - Full deployment pipeline: security review, tests, linter, build, deploy
- `/security-review` - Security audit of the package

## Testing
Run tests with: `devtools::test()` or `Rscript -e "devtools::test()"`

**Note:** Tests are disabled in CI/CD due to NJ DOE network dependencies. Run locally before deploying.

## Caching
Session caching is enabled by default to avoid hitting NJ DOE bot protection:
- `njsd_cache_info()` - view cache status
- `njsd_cache_clear()` - clear cache
- `njsd_cache_enable(FALSE)` - disable caching

The cache validates responses and will NOT cache network errors or bot protection pages.
