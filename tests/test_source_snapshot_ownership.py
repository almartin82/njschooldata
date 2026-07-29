"""Repository ownership checks for New Jersey source-validation inputs."""

from __future__ import annotations

import hashlib
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


def _checksum(path: Path) -> str:
    return "sha256:" + hashlib.sha256(path.read_bytes()).hexdigest()


def _canonical_checksum(value) -> str:
    encoded = json.dumps(
        value, sort_keys=True, separators=(",", ":"), ensure_ascii=False
    ).encode("utf-8")
    return "sha256:" + hashlib.sha256(encoded).hexdigest()


def test_fingerprint_inputs_match_authoritative_package_sources():
    contract = _read_json(SPEC_ROOT / "contract.json")
    lock = _read_json(CONTRACT_ROOT / "release-lock.json")
    payload = []
    mismatches = []

    for category in sorted(contract["fingerprint_inputs"]):
        destination_names = set()
        for relative in sorted(contract["fingerprint_inputs"][category]):
            source = (SPEC_ROOT / relative).resolve()
            source.relative_to(PACKAGE_ROOT)
            destination_name = source.name
            assert destination_name not in destination_names
            destination_names.add(destination_name)
            embedded = (
                CONTRACT_ROOT
                / "fingerprint-inputs"
                / category
                / destination_name
            )
            payload.append(
                {
                    "category": category,
                    "path": relative,
                    "checksum": _checksum(source),
                }
            )
            if not embedded.is_file() or embedded.read_bytes() != source.read_bytes():
                mismatches.append(f"{category}/{relative}")

    assert not mismatches, "stale fingerprint inputs: " + ", ".join(mismatches)
    assert lock["contract_fingerprint"] == _canonical_checksum(payload)


def test_contract_does_not_overclaim_source_derived_fixture_slices():
    manifest = _read_json(SPEC_ROOT / "artifact-manifest.json")
    coverage = _read_json(SPEC_ROOT / "package-coverage.json")
    status = _read_json(CONTRACT_ROOT / "status.json")

    assert manifest["artifacts"] == []
    assert coverage["state"] == "package_coverage_limited"
    assert coverage["excluded_fixture_slices"]
    assert status["state"] == "never_validated"
    assert status["derived_at"] == "1970-01-01T00:00:00Z"
    assert status["contract_validated_at"] is None
    assert status["snapshot_matched_at"] is None


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
