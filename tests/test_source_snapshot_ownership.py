"""Coverage honesty checks for the New Jersey source contract."""

from __future__ import annotations

import json
import os
from pathlib import Path
import subprocess
import sys


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

    assert manifest["artifacts"] == []
    assert installed["artifacts"] == []
    assert coverage["state"] == "package_coverage_limited"
    assert coverage["excluded_fixture_slices"]


def test_explicit_live_entry_point_makes_no_request_without_artifacts():
    runner = PACKAGE_ROOT / "tools" / "live-validation" / "run.py"
    refused = subprocess.run(
        [sys.executable, str(runner)],
        capture_output=True,
        text=True,
        check=False,
    )
    assert refused.returncode == 2
    assert "No request was made" in refused.stderr

    environment = os.environ.copy()
    environment["GITHUB_EVENT_NAME"] = "workflow_dispatch"
    dispatched = subprocess.run(
        [sys.executable, str(runner)],
        capture_output=True,
        text=True,
        check=False,
        env=environment,
    )
    assert dispatched.returncode == 6
    result = json.loads(dispatched.stdout)
    assert result["request_count"] == 0
    assert result["validation_clock_advanced"] is False
