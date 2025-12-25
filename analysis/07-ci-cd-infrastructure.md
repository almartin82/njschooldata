# CI/CD Infrastructure Analysis

## Current State

### Travis CI Configuration

**File**: `.travis.yml`
```yaml
language: c
sudo: required
before_install:
  - curl -OL http://raw.github.com/craigcitro/r-travis/master/scripts/travis-tool.sh
  ...
```

**Status**: DEPRECATED

- Travis CI free tier for open source ended in 2020
- The r-travis scripts are no longer maintained
- `jimhester/covr` GitHub path is outdated (now `r-lib/covr`)

### GitHub Configuration

**Directory**: `.github/`
```
.github/
└── lint.yaml     # Linting configuration only
```

**Missing**:
- `workflows/` directory (no GitHub Actions)
- `ISSUE_TEMPLATE/`
- `PULL_REQUEST_TEMPLATE.md`
- `CODEOWNERS`
- Dependabot configuration

## Required GitHub Actions Workflows

### 1. R CMD check (`R-CMD-check.yaml`)

Standard workflow for R package checking:

```yaml
# .github/workflows/R-CMD-check.yaml
name: R-CMD-check

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

jobs:
  R-CMD-check:
    runs-on: ${{ matrix.config.os }}

    name: ${{ matrix.config.os }} (${{ matrix.config.r }})

    strategy:
      fail-fast: false
      matrix:
        config:
          - {os: macos-latest,   r: 'release'}
          - {os: windows-latest, r: 'release'}
          - {os: ubuntu-latest,  r: 'devel', http-user-agent: 'release'}
          - {os: ubuntu-latest,  r: 'release'}
          - {os: ubuntu-latest,  r: 'oldrel-1'}

    env:
      GITHUB_PAT: ${{ secrets.GITHUB_TOKEN }}
      R_KEEP_PKG_SOURCE: yes

    steps:
      - uses: actions/checkout@v4

      - uses: r-lib/actions/setup-pandoc@v2

      - uses: r-lib/actions/setup-r@v2
        with:
          r-version: ${{ matrix.config.r }}
          http-user-agent: ${{ matrix.config.http-user-agent }}
          use-public-rspm: true

      - uses: r-lib/actions/setup-r-dependencies@v2
        with:
          extra-packages: any::rcmdcheck
          needs: check

      - uses: r-lib/actions/check-r-package@v2
        with:
          upload-snapshots: true
```

### 2. Test Coverage (`test-coverage.yaml`)

```yaml
# .github/workflows/test-coverage.yaml
name: test-coverage

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

jobs:
  test-coverage:
    runs-on: ubuntu-latest
    env:
      GITHUB_PAT: ${{ secrets.GITHUB_TOKEN }}

    steps:
      - uses: actions/checkout@v4

      - uses: r-lib/actions/setup-r@v2
        with:
          use-public-rspm: true

      - uses: r-lib/actions/setup-r-dependencies@v2
        with:
          extra-packages: any::covr
          needs: coverage

      - name: Test coverage
        run: |
          covr::codecov(
            quiet = FALSE,
            clean = FALSE,
            install_path = file.path(Sys.getenv("RUNNER_TEMP"), "package")
          )
        shell: Rscript {0}
```

### 3. pkgdown Site (`pkgdown.yaml`)

```yaml
# .github/workflows/pkgdown.yaml
name: pkgdown

on:
  push:
    branches: [main, master]
  release:
    types: [published]
  workflow_dispatch:

jobs:
  pkgdown:
    runs-on: ubuntu-latest
    concurrency:
      group: pkgdown-${{ github.event_name != 'pull_request' || github.run_id }}
    env:
      GITHUB_PAT: ${{ secrets.GITHUB_TOKEN }}
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4

      - uses: r-lib/actions/setup-pandoc@v2

      - uses: r-lib/actions/setup-r@v2
        with:
          use-public-rspm: true

      - uses: r-lib/actions/setup-r-dependencies@v2
        with:
          extra-packages: any::pkgdown, local::.
          needs: website

      - name: Build site
        run: pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)
        shell: Rscript {0}

      - name: Deploy to GitHub pages
        if: github.event_name != 'pull_request'
        uses: JamesIves/github-pages-deploy-action@v4.5.0
        with:
          clean: false
          branch: gh-pages
          folder: docs
```

### 4. Linting (`lint.yaml`)

```yaml
# .github/workflows/lint.yaml
name: lint

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

jobs:
  lint:
    runs-on: ubuntu-latest
    env:
      GITHUB_PAT: ${{ secrets.GITHUB_TOKEN }}
    steps:
      - uses: actions/checkout@v4

      - uses: r-lib/actions/setup-r@v2
        with:
          use-public-rspm: true

      - uses: r-lib/actions/setup-r-dependencies@v2
        with:
          extra-packages: any::lintr, local::.
          needs: lint

      - name: Lint
        run: lintr::lint_package()
        shell: Rscript {0}
        env:
          LINTR_ERROR_ON_LINT: true
```

## Additional Configuration Files

### `.Rbuildignore`

Create/update to exclude non-package files:

```
^.*\.Rproj$
^\.Rproj\.user$
^\.github$
^\.travis\.yml$
^codecov\.yml$
^_pkgdown\.yml$
^docs$
^pkgdown$
^analysis$
^data-raw$
^README\.Rmd$
^LICENSE\.md$
^\.lintr$
^\.vscode$
^\.devcontainer$
```

### `codecov.yml`

For coverage reporting configuration:

```yaml
codecov:
  require_ci_to_pass: yes

coverage:
  precision: 2
  round: down
  range: "60...100"

parsers:
  gcov:
    branch_detection:
      conditional: yes
      loop: yes
      method: no
      macro: no

comment:
  layout: "reach,diff,flags,files,footer"
  behavior: default
  require_changes: no
```

### `_pkgdown.yml`

(See documentation analysis for full config)

### `.lintr`

Linting configuration:

```
linters: linters_with_defaults(
    line_length_linter(120),
    object_name_linter(styles = c("snake_case", "symbols")),
    commented_code_linter = NULL
  )
encoding: "UTF-8"
```

## Branch Protection Recommendations

Configure in GitHub repository settings:

### Main/Master Branch
- [x] Require pull request reviews before merging
- [x] Require status checks to pass before merging
  - Required checks: `R-CMD-check`
- [x] Require branches to be up to date before merging
- [x] Require conversation resolution before merging
- [ ] Require signed commits (optional)
- [x] Do not allow bypassing the above settings

## Release Automation

### Suggested Release Workflow

```yaml
# .github/workflows/release.yaml
name: Create Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          generate_release_notes: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Version Bumping

Consider using `usethis::use_version()` workflow:
```r
# For development
usethis::use_version("dev")

# For release
usethis::use_version("minor")  # or "major" or "patch"
```

## Dependabot Configuration

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

## Issue and PR Templates

### Bug Report Template
```yaml
# .github/ISSUE_TEMPLATE/bug_report.yml
name: Bug Report
description: File a bug report
title: "[Bug]: "
labels: ["bug", "triage"]
body:
  - type: markdown
    attributes:
      value: |
        Thanks for taking the time to fill out this bug report!
  - type: textarea
    id: what-happened
    attributes:
      label: What happened?
      description: Also tell us, what did you expect to happen?
    validations:
      required: true
  - type: textarea
    id: reproduce
    attributes:
      label: Steps to reproduce
      description: Minimal code to reproduce the issue
      render: r
    validations:
      required: true
  - type: input
    id: version
    attributes:
      label: Package version
      description: Output of `packageVersion("njschooldata")`
    validations:
      required: true
  - type: input
    id: r-version
    attributes:
      label: R version
      description: Output of `R.version.string`
    validations:
      required: true
```

### Feature Request Template
```yaml
# .github/ISSUE_TEMPLATE/feature_request.yml
name: Feature Request
description: Suggest an idea for this project
title: "[Feature]: "
labels: ["enhancement"]
body:
  - type: textarea
    id: description
    attributes:
      label: Describe the feature
      description: A clear description of the feature you'd like
    validations:
      required: true
  - type: textarea
    id: use-case
    attributes:
      label: Use case
      description: How would this feature help you?
    validations:
      required: true
```

## Migration Checklist

### Phase 1: Remove Travis CI
- [ ] Delete `.travis.yml`
- [ ] Remove Travis badge from README

### Phase 2: Add GitHub Actions
- [ ] Create `.github/workflows/` directory
- [ ] Add `R-CMD-check.yaml`
- [ ] Add `test-coverage.yaml`
- [ ] Add `pkgdown.yaml`
- [ ] Update README with new badges

### Phase 3: Additional Configuration
- [ ] Create/update `.Rbuildignore`
- [ ] Add `codecov.yml`
- [ ] Add `_pkgdown.yml`
- [ ] Configure branch protection
- [ ] Add issue/PR templates

### Phase 4: Verify
- [ ] Push changes, verify workflows run
- [ ] Check R CMD check passes
- [ ] Verify coverage reporting works
- [ ] Confirm pkgdown site deploys

## Expected Workflow Behavior

After implementation:

1. **On every push/PR to main**:
   - R CMD check runs on multiple OS/R versions
   - Code coverage is calculated and reported
   - Linting checks run

2. **On release tag**:
   - All above checks run
   - GitHub Release is created
   - pkgdown site is updated

3. **Weekly**:
   - Dependabot checks for GitHub Actions updates

## Resource Limits and Considerations

### GitHub Actions Free Tier
- 2,000 minutes/month for private repos
- Unlimited for public repos
- This package is public, so no concerns

### Test Duration
Current tests hit live NJ DOE servers and are slow (~10+ minutes).
With mocking, tests should complete in <2 minutes.

Consider adding timeout:
```yaml
- uses: r-lib/actions/check-r-package@v2
  with:
    upload-snapshots: true
  timeout-minutes: 20
```
