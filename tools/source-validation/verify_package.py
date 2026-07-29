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
    for relative, expected in lock.get("generated_files", {}).items():
        if checksum_file(_package_path(package_root, relative)) != expected:
            raise PackageVerificationError(
                f"generated file hash mismatch: {relative}"
            )

    contract_id = lock.get("contract_id")
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

    for artifact in manifest["artifacts"]:
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
    release_digests = {
        lock["source_validation_release_digest"] for lock in locks.values()
    }
    if len(release_digests) != 1:
        raise PackageVerificationError("source-validation release digest skew")
    return {
        "schema_version": "source-validation-package-verification/v1",
        "source_validation_release": next(iter(releases)),
        "source_validation_release_digest": next(iter(release_digests)),
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
