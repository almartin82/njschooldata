# Reference: pkgdown / GitHub Pages

> **Load this when:** configuring or debugging the pkgdown deploy, adding/editing
> reference sections in `_pkgdown.yml`, or enabling Pages on a fresh repo.

Site: https://almartin82.github.io/njschooldata/

## Setup

- GitHub Action (`.github/workflows/pkgdown.yml`) builds on push to master
- Deploys to `gh-pages` branch automatically
- `docs/` is gitignored on master (build artifacts only — do not hand-edit or
  commit it)

## Configuration

- `_pkgdown.yml` — site config, reference sections, articles
- All exported functions must be listed in reference sections (use
  `matches(".*")` as catch-all)
- Vignettes in `vignettes/` appear as articles

## To enable on a new repo

1. Add workflow file and `_pkgdown.yml`
2. Push to master
3. Enable GitHub Pages via API or Settings:
   ```bash
   gh api repos/OWNER/REPO/pages -X POST --input - <<EOF
   {"build_type": "legacy", "source": {"branch": "gh-pages", "path": "/"}}
   EOF
   ```
