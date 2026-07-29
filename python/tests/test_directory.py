"""Mocked-only tests for directory-contract/v1 Python parity."""

import inspect

import pandas as pd
import pytest


def test_fetch_directory_is_exported_with_zero_arguments():
    import njschooldata

    assert "fetch_directory" in njschooldata.__all__
    assert list(inspect.signature(njschooldata.fetch_directory).parameters) == []


def test_fetch_directory_uses_bare_mocked_bridge_and_validates_assignments(
    monkeypatch,
):
    import njschooldata.directory as directory

    entities = pd.DataFrame({"entity_type": ["school"]})
    roles = pd.DataFrame([
        {
            "district_id": "133570",
            "school_id": "133570001",
            "role": "principal",
            "person_name": "Alex Exact",
        },
        {
            "district_id": "133570",
            "school_id": "133570001",
            "role": "principal",
            "person_name": "Blake Distinct",
        },
    ])
    meta = {"quality": {"duplicate_key_count": 1}}

    class FakeRResult:
        def rx2(self, name):
            return {"entities": entities, "roles": roles, "meta": meta}[name]

    calls = []

    def fake_call(name, *args, **kwargs):
        calls.append((name, args, kwargs))
        return FakeRResult()

    monkeypatch.setattr(directory, "call_r_function", fake_call)
    monkeypatch.setattr(directory, "_directory_as_frame", lambda value: value)
    monkeypatch.setattr(directory, "_directory_as_meta", lambda value: value)

    result = directory.fetch_directory()

    assert isinstance(result, directory.DirectoryResult)
    assert result.roles["person_name"].tolist() == [
        "Alex Exact",
        "Blake Distinct",
    ]
    assert calls == [("fetch_directory", (), {})]


def test_fetch_directory_rejects_repeated_assignment_from_mocked_bridge(
    monkeypatch,
):
    import njschooldata.directory as directory

    repeated = pd.DataFrame([
        {
            "district_id": "133570",
            "school_id": "133570001",
            "role": "principal",
            "person_name": "Alex Exact",
        },
        {
            "district_id": "133570",
            "school_id": "133570001",
            "role": "principal",
            "person_name": "Alex Exact",
        },
    ])

    class FakeRResult:
        def rx2(self, name):
            return {
                "entities": pd.DataFrame(),
                "roles": repeated,
                "meta": {"quality": {"duplicate_key_count": 0}},
            }[name]

    monkeypatch.setattr(
        directory,
        "call_r_function",
        lambda name: FakeRResult(),
    )
    monkeypatch.setattr(directory, "_directory_as_frame", lambda value: value)
    monkeypatch.setattr(directory, "_directory_as_meta", lambda value: value)

    with pytest.raises(
        directory.DirectoryIntegrityError,
        match="exact canonical assignment",
    ):
        directory.fetch_directory()
