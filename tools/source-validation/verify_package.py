#!/usr/bin/env python3
"""Verify package-local source-validation locks and artifact bytes."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any


class PackageVerificationError(Exception):
    """A package-local source-validation asset is missing or has drifted."""


class StaleCaptureError(PackageVerificationError):
    """A captured fingerprint input no longer matches the file it came from.

    Distinct from ordinary drift because the remedy is different. A generated
    file whose hash moved is a tampered or hand-edited artifact and wants
    restoring. A stale capture means the package's real source moved on and the
    contract now describes a superseded document -- which may be a missing
    regeneration, or may be a source change that must block a release until
    fresh live evidence exists. Both FAIL; only a reader can say which.
    """


class MissingCaptureProvenanceError(PackageVerificationError):
    """The lock records no capture provenance, so freshness cannot be checked.

    Not a pass. A lock written before capture provenance existed knows only its
    own copies, and re-hashing a copy against itself proves nothing about the
    source it was taken from.
    """


def canonical_bytes(value: Any) -> bytes:
    return json.dumps(
        value, sort_keys=True, separators=(",", ":"), ensure_ascii=False
    ).encode("utf-8")


def checksum_bytes(value: bytes) -> str:
    return "sha256:" + hashlib.sha256(value).hexdigest()


def checksum_file(path: Path) -> str:
    try:
        return checksum_bytes(path.read_bytes())
    except OSError as error:
        raise PackageVerificationError(f"cannot read {path}: {error}") from error


def read_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise PackageVerificationError(f"cannot read {path}: {error}") from error


def _package_path(package_root: Path, relative: str) -> Path:
    candidate = (package_root / relative).resolve()
    root = package_root.resolve()
    if not candidate.is_relative_to(root):
        raise PackageVerificationError(f"path escapes package root: {relative}")
    return candidate


def _verify_destinations(
    package_root: Path,
    lock: dict[str, Any],
    generated: dict[str, Any],
    contract_id: Any,
) -> None:
    """A recorded destination must resolve to the generated files it claims.

    `generate.py` treats these two values as sticky: with no explicit flag it
    reads them back out of this lock and writes there. Nothing checked they
    still point at anything, so a lock naming a stray or deleted directory kept
    verifying green and kept steering the next regeneration into it.
    """
    expectations = (
        (
            "python_destination",
            [f"source_validation_{contract_id}_generated.py"],
        ),
        ("validator_destination", ["validate_contract.py", "verify_package.py"]),
    )
    for key, names in expectations:
        recorded = lock.get(key)
        if not isinstance(recorded, str) or not recorded:
            raise PackageVerificationError(
                f"release lock records no usable {key}: {recorded!r}"
            )
        destination = _package_path(package_root, recorded)
        if not destination.is_dir():
            raise PackageVerificationError(
                f"{key} does not exist under the package root: {recorded}"
            )
        for name in names:
            relative = f"{recorded.rstrip('/')}/{name}"
            if not (package_root / relative).is_file():
                raise PackageVerificationError(
                    f"{key} holds no {name}: {relative} is missing"
                )
            if relative not in generated:
                raise PackageVerificationError(
                    f"{key} is not where the lock tracks {name}: {relative} is "
                    "absent from generated_files"
                )


def _verify_capture_freshness(
    package_root: Path,
    lock: dict[str, Any],
    generated: dict[str, Any],
    contract_id: Any,
) -> None:
    """Re-hash the LIVE source of every captured fingerprint input.

    Everything else here re-hashes the captured copies against the lock, so a
    copy and its lock entry agree with each other forever. Editing the real
    parser and skipping the regeneration left the contract describing a
    superseded document with verification still green (tn, reproduced in az).
    """
    sources = lock.get("fingerprint_sources")
    if not isinstance(sources, dict) or not sources:
        raise MissingCaptureProvenanceError(
            "release lock records no fingerprint capture provenance, so the "
            "captured inputs cannot be checked against the files they were "
            "copied from; regenerate the contract to record it"
        )
    capture_prefix = (
        "inst/extdata/source-contract/contracts/"
        f"{contract_id}/fingerprint-inputs/"
    )
    generated_captures = {
        relative for relative in generated if relative.startswith(capture_prefix)
    }
    provenance_captures = set(sources)
    if provenance_captures != generated_captures:
        missing = sorted(generated_captures - provenance_captures)
        unexpected = sorted(provenance_captures - generated_captures)
        details = []
        if missing:
            details.append(f"missing provenance for {missing}")
        if unexpected:
            details.append(f"provenance for ungenerated inputs {unexpected}")
        raise MissingCaptureProvenanceError(
            "fingerprint capture provenance must exactly match generated "
            f"fingerprint inputs: {'; '.join(details)}"
        )
    for captured, record in sorted(sources.items()):
        source_path = record.get("source_path") if isinstance(record, dict) else None
        expected = record.get("source_checksum") if isinstance(record, dict) else None
        if (
            not isinstance(source_path, str)
            or not source_path
            or not isinstance(expected, str)
            or not expected
        ):
            raise PackageVerificationError(
                f"invalid capture provenance for {captured}: {record!r}"
            )
        live = _package_path(package_root, source_path)
        if not live.is_file():
            raise StaleCaptureError(
                f"fingerprint source no longer exists: {source_path} (captured "
                f"as {captured})"
            )
        if checksum_file(live) != expected:
            raise StaleCaptureError(
                f"fingerprint source has changed since capture: {source_path} "
                f"(captured as {captured}); the contract describes a superseded "
                "document"
            )


def _verify_lock(
    package_root: Path,
    lock_path: Path,
    expected_release: str | None,
) -> dict[str, Any]:
    lock = read_json(lock_path)
    if lock.get("schema_version") != "source-validation-release-lock/v1":
        raise PackageVerificationError("invalid package-local source-validation lock")
    if expected_release and lock.get("source_validation_release") != expected_release:
        raise PackageVerificationError("source-validation release drift")
    test_ids = lock.get("expected_test_ids")
    if (
        not isinstance(test_ids, list)
        or not test_ids
        or len(test_ids) != len(set(test_ids))
        or not all(
            isinstance(test_id, str)
            and test_id.startswith("SV-")
            and test_id[3:].isdigit()
            for test_id in test_ids
        )
    ):
        raise PackageVerificationError("invalid package-local expected test IDs")
    generated = lock.get("generated_files", {})
    for relative, expected in generated.items():
        if checksum_file(_package_path(package_root, relative)) != expected:
            raise PackageVerificationError(
                f"generated file hash mismatch: {relative}"
            )

    contract_id = lock.get("contract_id")
    _verify_destinations(package_root, lock, generated, contract_id)
    _verify_capture_freshness(package_root, lock, generated, contract_id)
    manifest_path = lock_path.parent / "artifact-manifest.json"
    manifest = read_json(manifest_path)
    if checksum_bytes(canonical_bytes(manifest)) != lock.get(
        "artifact_manifest_digest"
    ):
        raise PackageVerificationError("artifact manifest digest mismatch")
    runtime_path = lock_path.parent / "runtime-metadata.json"
    if checksum_bytes(canonical_bytes(read_json(runtime_path))) != lock.get(
        "runtime_metadata_digest"
    ):
        raise PackageVerificationError("runtime metadata digest mismatch")

    artifacts = manifest.get("artifacts")
    if not isinstance(artifacts, list):
        raise PackageVerificationError("invalid package-local artifact manifest")
    artifact_ids = [
        artifact.get("artifact_id")
        for artifact in artifacts
        if isinstance(artifact, dict)
    ]
    if (
        len(artifact_ids) != len(artifacts)
        or any(
            not isinstance(artifact_id, str) or not artifact_id
            for artifact_id in artifact_ids
        )
        or len(artifact_ids) != len(set(artifact_ids))
    ):
        raise PackageVerificationError("invalid package-local artifact IDs")
    required = lock.get("required_artifact_ids", [])
    if len(required) != len(set(required)) or not set(required).issubset(
        set(artifact_ids)
    ):
        raise PackageVerificationError(
            "required artifact IDs are not a distinct subset of the manifest"
        )

    for artifact in artifacts:
        if (
            artifact["tier"] != "shipped"
            and artifact["storage"]["backend"] not in {"git", "git_lfs"}
        ):
            continue
        artifact_path = _package_path(package_root, artifact["storage"]["path"])
        if not artifact_path.is_file():
            raise PackageVerificationError(
                f"artifact missing: {contract_id}/{artifact['artifact_id']}"
            )
        if artifact_path.stat().st_size != artifact["byte_length"]:
            raise PackageVerificationError(
                f"artifact length mismatch: {contract_id}/{artifact['artifact_id']}"
            )
        if checksum_file(artifact_path) != artifact["checksum"]:
            raise PackageVerificationError(
                f"artifact checksum mismatch: {contract_id}/{artifact['artifact_id']}"
            )
    return lock


def verify_package(
    package_root: Path,
    expected_release: str | None = None,
) -> dict[str, Any]:
    registry_path = (
        package_root / "inst" / "extdata" / "source-contract" / "registry.json"
    )
    registry = read_json(registry_path)
    if registry.get("schema_version") != "source-validation-contract-registry/v1":
        raise PackageVerificationError("invalid package-local contract registry")
    contracts = registry.get("contracts")
    if not isinstance(contracts, dict) or not contracts:
        raise PackageVerificationError("invalid package-local contract registry")
    locks = {
        contract_id: _verify_lock(
            package_root,
            _package_path(package_root, entry["lock"]),
            expected_release,
        )
        for contract_id, entry in sorted(contracts.items())
    }
    releases = {lock["source_validation_release"] for lock in locks.values()}
    if len(releases) != 1:
        raise PackageVerificationError("source-validation release skew")
    return {
        "schema_version": "source-validation-package-verification/v1",
        "source_validation_release": next(iter(releases)),
        "contracts": locks,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--package-root", type=Path, required=True)
    parser.add_argument("--expected-release")
    args = parser.parse_args()
    print(
        json.dumps(
            verify_package(args.package_root, args.expected_release),
            sort_keys=True,
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
