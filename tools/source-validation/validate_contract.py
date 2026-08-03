#!/usr/bin/env python3
"""Validate standalone source contracts, immutable events, and derived status."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[2]
SCHEMA_DIR = ROOT / "contracts" / "source-validation" / "v1"
CHECKSUM = re.compile(r"^sha256:[0-9a-f]{64}$")
SUCCESS_STATES = {"validated_match", "validated_content_drift"}
TERMINAL_STATES = SUCCESS_STATES | {
    "source_unavailable",
    "contract_failure",
    "tooling_unavailable",
    "request_budget_exceeded",
}
EXECUTION_MODES = {"local", "manual_dispatch"}
FINGERPRINT_CATEGORIES = {
    "endpoint",
    "downloader",
    "parser",
    "normalization",
    "schema",
    "golden",
    "dependency",
    "shared_helper",
}


class ValidationError(Exception):
    """A source-validation artifact violates the v1 contract."""


def canonical_bytes(value: Any) -> bytes:
    return json.dumps(
        value, sort_keys=True, separators=(",", ":"), ensure_ascii=False
    ).encode("utf-8")


def digest(value: Any) -> str:
    return "sha256:" + hashlib.sha256(canonical_bytes(value)).hexdigest()


def event_id(value: dict[str, Any]) -> str:
    return digest({key: child for key, child in value.items() if key != "event_id"})


def parse_utc(value: str) -> datetime:
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except (TypeError, ValueError) as error:
        raise ValidationError(f"invalid UTC completion time: {value!r}") from error
    if parsed.tzinfo is None:
        raise ValidationError(f"completion time lacks UTC offset: {value!r}")
    return parsed.astimezone(timezone.utc)


def _checksum(value: Any, location: str) -> None:
    if not isinstance(value, str) or not CHECKSUM.fullmatch(value):
        raise ValidationError(f"schema violation: malformed checksum at {location}")


def _require_keys(value: dict, required: Iterable[str], location: str) -> None:
    missing = sorted(set(required) - set(value))
    if missing:
        raise ValidationError(f"schema violation: {location} missing {missing}")


def validate_contract(value: dict[str, Any]) -> None:
    _require_keys(
        value,
        (
            "schema_version",
            "contract_id",
            "source_validation_release",
            "category",
            "selectors",
            "execution",
            "fingerprint_inputs",
            "supported_runtimes",
        ),
        "contract",
    )
    if value["schema_version"] != "source-validation-contract/v1":
        raise ValidationError("schema violation: unsupported contract schema")
    execution = value["execution"]
    if execution.get("mode") not in EXECUTION_MODES:
        raise ValidationError("schema violation: unknown execution mode")
    if execution.get("max_in_flight_per_host") != 1:
        raise ValidationError("schema violation: validators require one in-flight request")
    if not isinstance(execution.get("request_budget"), int) or execution["request_budget"] < 1:
        raise ValidationError("schema violation: request_budget must be positive")
    inputs = value["fingerprint_inputs"]
    if set(inputs) != FINGERPRINT_CATEGORIES:
        raise ValidationError("schema violation: fingerprint input categories are incomplete")
    for category, paths in inputs.items():
        if not isinstance(paths, list) or not paths or not all(
            isinstance(path, str) and path for path in paths
        ):
            raise ValidationError(
                f"schema violation: fingerprint {category} inputs must be nonempty"
            )
    names: set[str] = set()
    for selector in value["selectors"]:
        _require_keys(selector, ("name", "required", "multi_value"), "selector")
        if selector["name"] in names:
            raise ValidationError(f"schema violation: duplicate selector {selector['name']}")
        names.add(selector["name"])
    requirements = value.get("required_artifacts", [])
    requirement_ids: set[str] = set()
    for requirement in requirements:
        _require_keys(requirement, ("artifact_id", "selectors"), "required artifact")
        artifact_id = requirement["artifact_id"]
        if not isinstance(artifact_id, str) or not artifact_id:
            raise ValidationError("schema violation: required artifact ID must be nonempty")
        if artifact_id in requirement_ids:
            raise ValidationError(f"schema violation: duplicate required artifact {artifact_id}")
        requirement_ids.add(artifact_id)
        if not isinstance(requirement["selectors"], dict):
            raise ValidationError("schema violation: required artifact selectors must be an object")
        unknown = set(requirement["selectors"]) - names
        if unknown:
            raise ValidationError(
                f"schema violation: required artifact has unknown selectors: {sorted(unknown)}"
            )


def validate_manifest(value: dict[str, Any]) -> None:
    _require_keys(value, ("schema_version", "contract_id", "artifacts"), "manifest")
    if value["schema_version"] != "source-validation-artifact-manifest/v1":
        raise ValidationError("schema violation: unsupported artifact manifest")
    for artifact_value in value["artifacts"]:
        _require_keys(
            artifact_value,
            (
                "artifact_id",
                "source_identity",
                "tier",
                "checksum",
                "byte_length",
                "selectors",
                "storage",
                "lineage",
            ),
            "artifact",
        )
        _checksum(artifact_value["checksum"], "artifact.checksum")
        if artifact_value["tier"] not in {"shipped", "repository_archive"}:
            raise ValidationError("schema violation: unknown artifact tier")
        if not isinstance(artifact_value["byte_length"], int) or artifact_value["byte_length"] < 1:
            raise ValidationError("schema violation: artifact byte_length must be positive")
        lineage = artifact_value["lineage"]
        if lineage.get("kind") == "derived":
            _require_keys(
                lineage,
                (
                    "parent_artifact_id",
                    "recipe",
                    "recipe_version",
                    "table_locator",
                    "row_count",
                    "key_census",
                ),
                "derived lineage",
            )
            _checksum(lineage["key_census"], "lineage.key_census")
        elif lineage.get("kind") != "source":
            raise ValidationError("schema violation: unknown lineage kind")


def _values(value: Any) -> set[str]:
    return {str(item) for item in value} if isinstance(value, list) else {str(value)}


def _coverage_overlaps(left: dict[str, Any], right: dict[str, Any]) -> bool:
    keys = set(left) | set(right)
    return all(
        key not in left
        or key not in right
        or bool(_values(left[key]) & _values(right[key]))
        for key in keys
    )


def _coverage_contains(
    artifact_selectors: dict[str, Any],
    required_selectors: dict[str, Any],
) -> bool:
    return all(
        key in artifact_selectors
        and _values(required_value).issubset(_values(artifact_selectors[key]))
        for key, required_value in required_selectors.items()
    )


def validate_bundle(contract: dict[str, Any], manifest: dict[str, Any]) -> None:
    validate_contract(contract)
    validate_manifest(manifest)
    if contract["contract_id"] != manifest["contract_id"]:
        raise ValidationError("contract and manifest contract_id mismatch")
    selector_names = {selector["name"] for selector in contract["selectors"]}
    identities: set[str] = set()
    artifact_ids = {artifact["artifact_id"] for artifact in manifest["artifacts"]}
    requirements = {
        value["artifact_id"]: value
        for value in contract.get("required_artifacts", [])
    }
    for artifact_value in manifest["artifacts"]:
        identity = artifact_value["artifact_id"]
        if identity in identities:
            raise ValidationError(f"duplicate artifact identity: {identity}")
        identities.add(identity)
        unknown = set(artifact_value["selectors"]) - selector_names
        if unknown:
            raise ValidationError(f"artifact has unknown selectors: {sorted(unknown)}")
        for selector in contract["selectors"]:
            if selector["required"] and selector["name"] not in artifact_value["selectors"]:
                raise ValidationError(
                    f"artifact {artifact_value['artifact_id']} lacks required selector {selector['name']}"
                )
        lineage = artifact_value["lineage"]
        if lineage.get("kind") == "derived" and lineage["parent_artifact_id"] not in artifact_ids:
            raise ValidationError("derived artifact references unknown parent")
    artifacts_by_id = {
        artifact_value["artifact_id"]: artifact_value
        for artifact_value in manifest["artifacts"]
    }
    for artifact_id, requirement in requirements.items():
        artifact_value = artifacts_by_id.get(artifact_id)
        if artifact_value is None:
            raise ValidationError(f"required artifact is absent from manifest: {artifact_id}")
        if artifact_value["tier"] != "shipped":
            raise ValidationError(f"required artifact is not shipped: {artifact_id}")
        if not _coverage_contains(
            artifact_value["selectors"], requirement["selectors"]
        ):
            raise ValidationError(
                f"required artifact selectors are not covered: {artifact_id}"
            )
    shipped = [a for a in manifest["artifacts"] if a["tier"] == "shipped"]
    for index, left in enumerate(shipped):
        for right in shipped[index + 1 :]:
            if (
                _coverage_overlaps(left["selectors"], right["selectors"])
                and not (
                    left["artifact_id"] in requirements
                    and right["artifact_id"] in requirements
                )
            ):
                raise ValidationError(
                    f"overlapping shipped selector coverage: {left['artifact_id']} and {right['artifact_id']}"
                )
    if len(shipped) > 1 and not requirements:
        raise ValidationError(
            "multiple shipped artifacts require explicit required_artifacts"
        )


def required_artifact_ids(
    contract: dict[str, Any], manifest: dict[str, Any]
) -> list[str]:
    """Return the artifact IDs whose evidence jointly makes a contract ready."""
    validate_bundle(contract, manifest)
    declared = contract.get("required_artifacts")
    if declared:
        return sorted(value["artifact_id"] for value in declared)
    shipped = sorted(
        artifact["artifact_id"]
        for artifact in manifest["artifacts"]
        if artifact["tier"] == "shipped"
    )
    return shipped


def validate_event(value: dict[str, Any]) -> None:
    _require_keys(
        value,
        (
            "schema_version",
            "event_id",
            "contract_id",
            "artifact_id",
            "contract_fingerprint",
            "completed_at",
            "terminal_state",
            "execution",
        ),
        "event",
    )
    for field in ("event_id", "contract_fingerprint"):
        _checksum(value[field], f"event.{field}")
    if value["terminal_state"] not in TERMINAL_STATES:
        raise ValidationError("schema violation: unknown terminal state")
    if value["execution"].get("mode") not in EXECUTION_MODES:
        raise ValidationError("schema violation: unknown event execution mode")
    if value["execution"].get("request_count", 0) > value["execution"].get("request_budget", -1):
        raise ValidationError("request budget exceeded without terminal evidence")
    if value["terminal_state"] in SUCCESS_STATES:
        _require_keys(
            value,
            (
                "observed_checksum",
                "snapshot_checksum",
                "final_url",
                "content_type",
                "checks",
            ),
            "successful event",
        )
        _checksum(value["observed_checksum"], "event.observed_checksum")
        _checksum(value["snapshot_checksum"], "event.snapshot_checksum")
        required_checks = {
            "content_complete",
            "requested_identity",
            "production_parse",
            "goldens",
            "invariants",
        }
        if set(value["checks"]) != required_checks or not all(value["checks"].values()):
            raise ValidationError("successful event lacks complete validation checks")
    else:
        failure = value.get("failure")
        if not isinstance(failure, dict) or not failure.get("type") or not failure.get("message"):
            raise ValidationError("failed event requires informative typed evidence")
    if value["event_id"] != event_id(value):
        raise ValidationError("event ID is not content-derived")


def validate_events(
    events: list[dict[str, Any]],
    contract: dict[str, Any],
    manifest: dict[str, Any],
    now: datetime | None = None,
) -> None:
    validate_bundle(contract, manifest)
    now = (now or datetime.now(timezone.utc)).astimezone(timezone.utc)
    artifact_ids = {artifact["artifact_id"] for artifact in manifest["artifacts"]}
    ids = [value.get("event_id") for value in events]
    if len(ids) != len(set(ids)):
        raise ValidationError("duplicate event ID")
    known_ids = set(ids)
    for value in events:
        validate_event(value)
        if value["contract_id"] != contract["contract_id"]:
            raise ValidationError("event references unknown contract")
        if value["artifact_id"] not in artifact_ids:
            raise ValidationError("event references unknown artifact")
        if parse_utc(value["completed_at"]) > now + timedelta(minutes=5):
            raise ValidationError("event completion time is in the future")
        supersedes = value.get("supersedes")
        if supersedes is not None and (
            supersedes not in known_ids or supersedes == value["event_id"]
        ):
            raise ValidationError("correction references unknown superseded event")


def enforce_add_only(
    prior_events: list[dict[str, Any]], candidate_events: list[dict[str, Any]]
) -> None:
    prior = {event["event_id"]: canonical_bytes(event) for event in prior_events}
    candidate = {event["event_id"]: canonical_bytes(event) for event in candidate_events}
    if any(event_id not in candidate or candidate[event_id] != body for event_id, body in prior.items()):
        raise ValidationError("prior events were edited or deleted")


def derive_status(
    events: list[dict[str, Any]],
    current_fingerprint: str,
    now: datetime,
    required_artifact_ids: Iterable[str] | None = None,
) -> dict[str, Any]:
    _checksum(current_fingerprint, "current_fingerprint")
    now = now.astimezone(timezone.utc)
    superseded = {event["supersedes"] for event in events if event.get("supersedes")}
    successful = sorted(
        (
            event
            for event in events
            if event.get("terminal_state") in SUCCESS_STATES
            and event.get("event_id") not in superseded
        ),
        key=lambda value: parse_utc(value["completed_at"]),
    )
    matching = [event for event in successful if event["contract_fingerprint"] == current_fingerprint]
    completed_at = {
        event["event_id"]: parse_utc(event["completed_at"]) for event in successful
    }
    required = sorted(set(required_artifact_ids or []))
    if required:
        required_set = set(required)
        latest_by_artifact: dict[str, dict[str, Any] | None] = dict.fromkeys(
            required
        )
        latest_any_by_artifact: dict[str, dict[str, Any] | None] = dict.fromkeys(
            required
        )
        matched_by_artifact: dict[str, dict[str, Any] | None] = dict.fromkeys(
            required
        )
        for event in successful:
            artifact_id = event["artifact_id"]
            if artifact_id in required_set:
                latest_any_by_artifact[artifact_id] = event
        for event in matching:
            artifact_id = event["artifact_id"]
            if artifact_id not in required_set:
                continue
            latest_by_artifact[artifact_id] = event
            if event["terminal_state"] == "validated_match":
                matched_by_artifact[artifact_id] = event
        missing = sorted(
            artifact_id
            for artifact_id, artifact_event in latest_by_artifact.items()
            if artifact_event is None
        )
        validated = sorted(set(required) - set(missing))
        selected = [
            artifact_event
            for artifact_event in latest_by_artifact.values()
            if artifact_event is not None
        ]
        if missing:
            state = (
                "fingerprint_mismatch"
                if all(latest_any_by_artifact.values())
                else "never_validated"
            )
        elif any(
            now - completed_at[artifact_event["event_id"]] > timedelta(days=90)
            for artifact_event in selected
        ):
            state = "stale_90d"
        else:
            state = "current"
        latest = max(
            selected, key=lambda value: completed_at[value["event_id"]]
        ) if selected else None
        matched_events = [
            artifact_event
            for artifact_event in matched_by_artifact.values()
            if artifact_event is not None
        ]
        latest_match = max(
            matched_events, key=lambda value: completed_at[value["event_id"]]
        ) if matched_events else None
        result = {
            "schema_version": "source-validation-status/v1",
            "state": state,
            "contract_fingerprint": current_fingerprint,
            "contract_validated_at": (
                min(selected, key=lambda value: completed_at[value["event_id"]])[
                    "completed_at"
                ]
                if not missing else None
            ),
            "snapshot_matched_at": (
                min(
                    matched_events,
                    key=lambda value: completed_at[value["event_id"]],
                )["completed_at"]
                if len(matched_events) == len(required) else None
            ),
            "snapshot_checksum": (
                latest_match["snapshot_checksum"] if len(required) == 1 and latest_match else None
            ),
            "latest_observed_checksum": (
                latest["observed_checksum"] if len(required) == 1 and latest else None
            ),
            "active_drift": any(
                event["observed_checksum"] != event["snapshot_checksum"]
                for event in selected
            ),
            "derived_at": now.isoformat().replace("+00:00", "Z"),
            "required_artifact_ids": required,
            "validated_artifact_ids": validated,
            "missing_artifact_ids": missing,
            "artifact_statuses": {
                artifact_id: {
                    "validated_at": (
                        latest_by_artifact[artifact_id]["completed_at"]
                        if latest_by_artifact[artifact_id] else None
                    ),
                    "snapshot_matched_at": (
                        matched_by_artifact[artifact_id]["completed_at"]
                        if matched_by_artifact[artifact_id] else None
                    ),
                    "snapshot_checksum": (
                        latest_by_artifact[artifact_id]["snapshot_checksum"]
                        if latest_by_artifact[artifact_id] else None
                    ),
                    "latest_observed_checksum": (
                        latest_by_artifact[artifact_id]["observed_checksum"]
                        if latest_by_artifact[artifact_id] else None
                    ),
                    "active_drift": bool(
                        latest_by_artifact[artifact_id]
                        and latest_by_artifact[artifact_id]["observed_checksum"]
                        != latest_by_artifact[artifact_id]["snapshot_checksum"]
                    ),
                }
                for artifact_id in required
            },
        }
        return result
    latest_any = successful[-1] if successful else None
    latest = matching[-1] if matching else None
    matched = [event for event in matching if event["terminal_state"] == "validated_match"]
    latest_match = matched[-1] if matched else None
    if latest is None:
        state = "fingerprint_mismatch" if latest_any else "never_validated"
    elif now - parse_utc(latest["completed_at"]) > timedelta(days=90):
        state = "stale_90d"
    else:
        state = "current"
    snapshot_checksum = (
        latest_match["snapshot_checksum"]
        if latest_match
        else (latest["snapshot_checksum"] if latest else None)
    )
    return {
        "schema_version": "source-validation-status/v1",
        "state": state,
        "contract_fingerprint": current_fingerprint,
        "contract_validated_at": latest["completed_at"] if latest else None,
        "snapshot_matched_at": latest_match["completed_at"] if latest_match else None,
        "snapshot_checksum": snapshot_checksum,
        "latest_observed_checksum": latest["observed_checksum"] if latest else None,
        "active_drift": bool(
            latest and latest["observed_checksum"] != latest["snapshot_checksum"]
        ),
        "derived_at": now.isoformat().replace("+00:00", "Z"),
    }


def verify_status(
    status: dict[str, Any],
    events: list[dict[str, Any]],
    fingerprint: str,
    now: datetime,
    required_artifact_ids: Iterable[str] | None = None,
) -> None:
    if canonical_bytes(status) != canonical_bytes(
        derive_status(
            events,
            fingerprint,
            now,
            required_artifact_ids=required_artifact_ids,
        )
    ):
        raise ValidationError("status is stale or hand-edited")


def assess_release(
    prior_lock: dict[str, Any],
    current_lock: dict[str, Any],
    events: list[dict[str, Any]],
    now: datetime,
) -> dict[str, Any]:
    """Recompute the affected-contract release gate from locks and events."""
    # Watched fields describe the DATA under contract: which inputs define the
    # contract, which bytes the manifest claims, and which artifacts are
    # required. The generator's own version is not watched -- retooling is not
    # a data event and must not invalidate validation evidence.
    watched = (
        "contract_fingerprint",
        "artifact_manifest_digest",
        "required_artifact_ids",
    )
    reasons = [
        field for field in watched if prior_lock.get(field) != current_lock.get(field)
    ]
    affected = bool(reasons)
    fingerprint = current_lock.get("contract_fingerprint")
    required = sorted(set(current_lock.get("required_artifact_ids", [])))
    matching = [
        value
        for value in events
        if value.get("terminal_state") in SUCCESS_STATES
        and value.get("contract_fingerprint") == fingerprint
        and now.astimezone(timezone.utc) - parse_utc(value["completed_at"])
        <= timedelta(days=90)
    ]
    matching_ids = {value["artifact_id"] for value in matching}
    status = derive_status(
        events,
        fingerprint,
        now,
        required_artifact_ids=required or None,
    )
    evidence_ready = status["state"] == "current"
    required_matching = [
        value for value in matching
        if not required or value["artifact_id"] in required
    ]
    return {
        "affected": affected,
        "ready": not affected or evidence_ready,
        "reasons": reasons,
        "matching_event_id": (
            required_matching[-1]["event_id"]
            if evidence_ready and required_matching
            else None
        ),
        "matching_artifact_ids": sorted(matching_ids & set(required)),
        "matching_event_ids": (
            [value["event_id"] for value in required_matching]
            if evidence_ready
            else []
        ),
    }


def load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ValidationError(f"cannot read {path}: {error}") from error


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--contract", type=Path, required=True)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--events", type=Path)
    parser.add_argument("--status", type=Path)
    parser.add_argument("--fingerprint")
    parser.add_argument("--as-of")
    args = parser.parse_args()
    contract_value = load_json(args.contract)
    manifest_value = load_json(args.manifest)
    events = (
        [load_json(path) for path in sorted(args.events.glob("*.json"))]
        if args.events
        else []
    )
    now = parse_utc(args.as_of) if args.as_of else datetime.now(timezone.utc)
    validate_events(events, contract_value, manifest_value, now=now)
    if args.status:
        if not args.fingerprint:
            raise ValidationError("--fingerprint is required with --status")
        verify_status(
            load_json(args.status),
            events,
            args.fingerprint,
            now,
            required_artifact_ids=required_artifact_ids(
                contract_value, manifest_value
            ),
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
