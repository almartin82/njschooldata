"""Coverage honesty checks for the New Jersey source contract."""

from __future__ import annotations

import json
import os
from pathlib import Path
import subprocess
import shutil
import hashlib

import pytest


PACKAGE_ROOT = Path(__file__).resolve().parents[1]
CONTRACT_ID = "new_jersey_shipped_sources"
SPEC_ROOT = (
    PACKAGE_ROOT
    / "data-raw"
    / "source-validation-spec"
    / CONTRACT_ID
)
CONTRACT_ROOT = (
    PACKAGE_ROOT
    / "inst"
    / "extdata"
    / "source-contract"
    / "contracts"
    / CONTRACT_ID
)


def _read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def test_contract_does_not_overclaim_source_derived_fixture_slices():
    manifest = _read_json(SPEC_ROOT / "artifact-manifest.json")
    coverage = _read_json(SPEC_ROOT / "package-coverage.json")
    installed = _read_json(CONTRACT_ROOT / "artifact-manifest.json")

    assert manifest == installed
    assert len(manifest["artifacts"]) == 9
    for artifact in manifest["artifacts"]:
        assert artifact["lineage"]["kind"] == "source"
        assert artifact["source_identity"]["url"].startswith("https://www.nj.gov/")
        content = (PACKAGE_ROOT / artifact["storage"]["path"]).read_bytes()
        assert len(content) == artifact["byte_length"]
        assert hashlib.sha256(content).hexdigest() == artifact["sha256"]
        assert Path(artifact["storage"]["path"]).name not in coverage["excluded_fixture_slices"]
    assert coverage["state"] == "package_coverage_limited"
    assert coverage["excluded_fixture_slices"]


@pytest.mark.parametrize("flag", [None, "false"])
def test_manual_canary_refuses_before_loading_package(flag, tmp_path):
    runner = PACKAGE_ROOT / "tools" / "run-live-canaries.R"
    environment = os.environ.copy()
    environment.pop("NJSCHOOLDATA_LIVE_TESTS", None)
    if flag is not None:
        environment["NJSCHOOLDATA_LIVE_TESTS"] = flag
    refused = subprocess.run(
        [shutil.which("Rscript") or "Rscript", "--vanilla", str(runner)],
        cwd=tmp_path, env=environment, capture_output=True, text=True, check=False,
    )
    assert refused.returncode != 0
    assert "Live canaries require NJSCHOOLDATA_LIVE_TESTS=true" in refused.stderr
    assert list(tmp_path.iterdir()) == []
