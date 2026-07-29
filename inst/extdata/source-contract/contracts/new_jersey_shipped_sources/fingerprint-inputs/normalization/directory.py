"""Python port of the New Jersey directory-contract/v1 result."""

from __future__ import annotations

from dataclasses import dataclass
import re
from typing import Any

import pandas as pd

from ._r_bridge import call_r_function, localconverter, pandas2ri, ro

__all__ = [
    "DirectoryResult",
    "DirectoryError",
    "DirectoryParseError",
    "DirectoryIntegrityError",
    "validate_assignment_semantics",
    "fetch_directory",
]


class DirectoryError(Exception):
    """Base class for directory contract failures."""


class DirectoryParseError(DirectoryError):
    """The source was fetched but no longer matches the expected structure."""


class DirectoryIntegrityError(DirectoryError):
    """The canonical output would violate directory integrity."""


@dataclass(frozen=True)
class DirectoryResult:
    """Canonical entities, roles, and metadata returned by ``fetch_directory``."""

    entities: pd.DataFrame
    roles: pd.DataFrame
    meta: dict

    def __repr__(self) -> str:  # pragma: no cover - cosmetic
        status = self.meta.get("source_status", "?") if self.meta else "?"
        return (
            f"DirectoryResult(entities={len(self.entities)}, "
            f"roles={len(self.roles)}, source_status={status!r})"
        )


_ARRAY_PATHS = frozenset({
    "sources",
    "coverage.entity_types",
    "coverage.district_roles",
    "coverage.school_roles",
    "quality.unmapped_titles",
})
_MAPPING_PATHS = frozenset({
    "counts.roles_by_role",
    "quality.named_coverage",
})
_NA_SENTINELS = ("NA_character_", "NA_integer_", "NA_real_")


def _is_r_null(value: Any) -> bool:
    return value is None or (ro is not None and value is ro.NULL)


def _unwrap_scalar(value: Any) -> Any:
    if _is_r_null(value):
        return None
    try:
        values = list(value)
    except TypeError:
        return value
    if not values:
        return None
    item = values[0]
    if item is None:
        return None
    if (
        repr(item) in _NA_SENTINELS
        or str(type(item)).endswith("NACharacterType'>")
    ):
        return None
    if hasattr(item, "item"):
        item = item.item()
    return item


def _as_list(value: Any) -> list:
    if _is_r_null(value):
        return []
    items = []
    for item in value:
        if hasattr(item, "item"):
            item = item.item()
        items.append(item)
    return items


def _has_names(value: Any) -> bool:
    names = getattr(value, "names", None)
    return names is not None and not _is_r_null(names)


def _convert_source(value: Any) -> dict:
    if not _has_names(value):
        return {}
    return {
        str(key): _unwrap_scalar(value.rx2(key))
        for key in value.names
    }


def _convert_meta_node(value: Any, path: str) -> Any:
    if _is_r_null(value):
        return None
    if path in _ARRAY_PATHS:
        if path == "sources":
            return [_convert_source(item) for item in value]
        return _as_list(value)
    if path in _MAPPING_PATHS:
        if not _has_names(value):
            return {}
        return {
            str(key): _unwrap_scalar(value.rx2(key))
            for key in value.names
        }
    if _has_names(value):
        converted = {}
        for key in value.names:
            key = str(key)
            child_path = f"{path}.{key}" if path else key
            converted[key] = _convert_meta_node(value.rx2(key), child_path)
        return converted
    return _unwrap_scalar(value)


def _directory_as_meta(value: Any) -> dict:
    converted = _convert_meta_node(value, "")
    return converted if isinstance(converted, dict) else {}


def _is_r_na(value: Any) -> bool:
    value_type = type(value)
    return (
        value_type.__name__.startswith("NA")
        and value_type.__module__.startswith("rpy2")
    )


def _normalise_na(frame: pd.DataFrame) -> pd.DataFrame:
    for column in frame.columns:
        if frame[column].dtype != object:
            continue
        mask = frame[column].map(_is_r_na)
        if mask.any():
            frame.loc[mask, column] = None
    return frame


def _directory_as_frame(value: Any) -> pd.DataFrame:
    if _is_r_null(value):
        return pd.DataFrame()
    if isinstance(value, pd.DataFrame):
        return _normalise_na(value)
    if ro is None or pandas2ri is None or localconverter is None:
        raise ImportError("rpy2 is required to convert an R directory result")
    with localconverter(ro.default_converter + pandas2ri.converter):
        return _normalise_na(pandas2ri.rpy2py(value))


_ASSIGNMENT_KEY_COLUMNS = (
    "district_id",
    "school_id",
    "role",
    "person_name",
)
_DERIVED_NAME_COLUMNS = ("first_name", "last_name")
_AUTHORITATIVE_IDENTITY_COLUMNS = ("email", "phone")
_MULTIPLICITY_EXEMPT_ROLES = frozenset({"board_member", "other"})
_EXTENSION_ID_COLUMN = re.compile(r"^[a-z]{2}_[a-z0-9_]*id$")
_MISSING_KEY_PART = object()


def _is_missing_scalar(value: Any) -> bool:
    if value is None:
        return True
    try:
        return bool(pd.isna(value))
    except (TypeError, ValueError):
        return False


def _key_part(value: Any) -> Any:
    if _is_missing_scalar(value):
        return _MISSING_KEY_PART
    if hasattr(value, "item"):
        value = value.item()
    return value


def _normalised_person_name(value: Any) -> str | None:
    if _is_missing_scalar(value):
        return None
    normalised = str(value).strip()
    return normalised or None


def _identity_value(value: Any) -> Any:
    if _is_missing_scalar(value):
        return None
    if hasattr(value, "item"):
        value = value.item()
    return value


def _format_key(key: tuple[Any, ...]) -> str:
    return repr(
        tuple(
            None if part is _MISSING_KEY_PART else part
            for part in key
        )
    )


def validate_assignment_semantics(
    roles: pd.DataFrame, duplicate_key_count: Any
) -> int:
    """Validate assignment uniqueness, conflicts, and role multiplicity."""
    if not isinstance(roles, pd.DataFrame):
        raise DirectoryIntegrityError("roles must be a pandas DataFrame")

    if roles.empty:
        derived_count = 0
    else:
        missing_columns = [
            column
            for column in _ASSIGNMENT_KEY_COLUMNS
            if column not in roles
        ]
        if missing_columns:
            raise DirectoryIntegrityError(
                "roles missing assignment key columns: "
                + ", ".join(missing_columns)
            )

        derived_name_columns = [
            column
            for column in _DERIVED_NAME_COLUMNS
            if column in roles
        ]
        authoritative_columns = [
            column
            for column in _AUTHORITATIVE_IDENTITY_COLUMNS
            if column in roles
        ]
        authoritative_columns.extend(
            column
            for column in roles
            if _EXTENSION_ID_COLUMN.fullmatch(str(column))
            and column not in authoritative_columns
        )

        assignments: dict[tuple[Any, ...], list[int]] = {}
        occupants: dict[tuple[Any, ...], set[str]] = {}

        for position, (_, row) in enumerate(roles.iterrows()):
            person_key = _normalised_person_name(row["person_name"])
            assignment_key = (
                _key_part(row["district_id"]),
                _key_part(row["school_id"]),
                _key_part(row["role"]),
                (
                    person_key
                    if person_key is not None
                    else _MISSING_KEY_PART
                ),
            )
            assignments.setdefault(assignment_key, []).append(position)

            role = _key_part(row["role"])
            if (
                person_key is None
                or role in _MULTIPLICITY_EXEMPT_ROLES
            ):
                continue
            role_key = (
                _key_part(row["district_id"]),
                _key_part(row["school_id"]),
                role,
            )
            occupants.setdefault(role_key, set()).add(person_key)

        for assignment_key, indices in assignments.items():
            if len(indices) < 2:
                continue
            person_key = assignment_key[-1]
            if person_key is not _MISSING_KEY_PART:
                derived_conflict = any(
                    len({
                        value
                        for position in indices
                        if (
                            value := _identity_value(
                                roles.iloc[position][column]
                            )
                        ) is not None
                    }) > 1
                    for column in derived_name_columns
                )
                authoritative_conflict = any(
                    len({
                        _identity_value(
                            roles.iloc[position][column]
                        )
                        for position in indices
                    }) > 1
                    for column in authoritative_columns
                )
                if derived_conflict or authoritative_conflict:
                    raise DirectoryIntegrityError(
                        "same normalized-name assignment has conflicting "
                        "identity evidence at "
                        f"{_format_key(assignment_key)}; source review "
                        "required before either person is collapsed"
                    )
            raise DirectoryIntegrityError(
                "exact canonical assignment repeated in finalized roles at "
                f"{_format_key(assignment_key)}"
            )

        derived_count = sum(
            len(named_people) > 1
            for named_people in occupants.values()
        )

    if (
        isinstance(duplicate_key_count, bool)
        or not isinstance(duplicate_key_count, int)
        or duplicate_key_count != derived_count
    ):
        raise DirectoryIntegrityError(
            "duplicate_key_count mismatch: "
            f"reported {duplicate_key_count!r}, derived {derived_count} "
            "from finalized roles"
        )
    return derived_count


def _build_directory_result(r_result: Any) -> DirectoryResult:
    result = DirectoryResult(
        entities=_directory_as_frame(r_result.rx2("entities")),
        roles=_directory_as_frame(r_result.rx2("roles")),
        meta=_directory_as_meta(r_result.rx2("meta")),
    )
    try:
        duplicate_key_count = result.meta["quality"]["duplicate_key_count"]
    except (KeyError, TypeError) as exc:
        raise DirectoryIntegrityError(
            "meta.quality.duplicate_key_count is required for "
            "assignment validation"
        ) from exc
    validate_assignment_semantics(result.roles, duplicate_key_count)
    return result


def fetch_directory() -> DirectoryResult:
    """Return the canonical New Jersey directory through the R bridge."""
    try:
        r_result = call_r_function("fetch_directory")
    except Exception as exc:
        message = str(exc)
        if "directory_parse_error" in message:
            raise DirectoryParseError(message) from exc
        if "directory_integrity_error" in message:
            raise DirectoryIntegrityError(message) from exc
        raise
    return _build_directory_result(r_result)
