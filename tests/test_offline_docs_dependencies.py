"""Hermetic ownership checks for pkgdown's external documentation assets."""

from __future__ import annotations

import base64
import hashlib
import json
from pathlib import Path
import subprocess


PACKAGE_ROOT = Path(__file__).resolve().parents[1]
DOCS_TOOL_ROOT = PACKAGE_ROOT / "tools" / "docs"
MANIFEST_PATH = DOCS_TOOL_ROOT / "pkgdown-dependencies.json"
ASSET_ROOT = DOCS_TOOL_ROOT / "pkgdown-cache"
BUILD_SCRIPT = DOCS_TOOL_ROOT / "build-offline-docs.R"
PKGDOWN_CONFIG = PACKAGE_ROOT / "_pkgdown.yml"
PKGDOWN_WORKFLOW = PACKAGE_ROOT / ".github" / "workflows" / "pkgdown.yaml"
SOURCE_VALIDATION_DOC = (
    PACKAGE_ROOT / "docs" / "source-validation-new_jersey_shipped_sources.md"
)


def test_pkgdown_dependency_bytes_match_sri_and_license_provenance() -> None:
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    dependencies = manifest["dependencies"]
    assert manifest["schema_version"] == "njschooldata-pkgdown-dependencies/v1"
    assert len(dependencies) == 7

    for dependency in dependencies:
        relative = dependency["path"]
        path = ASSET_ROOT / relative
        assert path.is_file(), relative
        package_relative = f"tools/docs/pkgdown-cache/{relative}"
        ignored = subprocess.run(
            ["git", "check-ignore", "--quiet", "--", package_relative],
            cwd=PACKAGE_ROOT,
            check=False,
        )
        assert ignored.returncode == 1, package_relative

        algorithm, expected = dependency["integrity"].split("-", 1)
        observed = base64.b64encode(
            hashlib.new(algorithm, path.read_bytes()).digest()
        ).decode("ascii")
        assert observed == expected, relative

        assert dependency["license"] in {"MIT", "Apache-2.0"}
        header = path.read_bytes()[:600].decode("utf-8", errors="replace").lower()
        assert "license" in header or "licensed" in header, relative


def test_offline_docs_builder_uses_only_verified_local_dependencies() -> None:
    source = BUILD_SCRIPT.read_text(encoding="utf-8")
    assert "clean_site" not in source
    assert "pkgdown::init_site()" in source
    assert "pkgdown::build_home(preview = FALSE)" in source
    assert "pkgdown::build_reference(" in source
    assert "examples = FALSE" in source
    assert "tools::R_user_dir(\"pkgdown\", \"cache\")" in source
    assert "pkgdown-dependencies.json" in source
    assert "download.file" not in source
    assert "tryCatch" not in source
    assert "http://" not in source
    assert "https://" not in source


def test_offline_docs_builder_preserves_tracked_source_validation_document() -> None:
    source = BUILD_SCRIPT.read_text(encoding="utf-8")
    assert "clean_site" not in source
    assert SOURCE_VALIDATION_DOC.is_file()
    assert SOURCE_VALIDATION_DOC.stat().st_size > 0
    tracked = subprocess.run(
        ["git", "ls-files", "--error-unmatch", "--", str(SOURCE_VALIDATION_DOC)],
        cwd=PACKAGE_ROOT,
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    assert tracked.returncode == 0


def test_home_sidebar_is_local_and_skips_pkgdown_cran_discovery() -> None:
    config = PKGDOWN_CONFIG.read_text(encoding="utf-8")
    assert "html: tools/docs/home-sidebar.html" in config
    sidebar = (DOCS_TOOL_ROOT / "home-sidebar.html").read_text(encoding="utf-8")
    assert "https://github.com/almartin82/njschooldata" in sidebar
    assert "https://cloud.r-project.org" not in sidebar
    workflow = PKGDOWN_WORKFLOW.read_text(encoding="utf-8")
    assert 'source("tools/docs/build-offline-docs.R")' in workflow
