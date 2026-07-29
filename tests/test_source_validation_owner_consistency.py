"""Git ownership checks for New Jersey source-validation outputs."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import subprocess


PACKAGE_ROOT = Path(__file__).resolve().parents[1]
CONTRACT_ID = "new_jersey_shipped_sources"
CONTRACT_ROOT = (
    PACKAGE_ROOT
    / "inst"
    / "extdata"
    / "source-contract"
    / "contracts"
    / CONTRACT_ID
)
GENERATED_DOCUMENT = (
    "docs/source-validation-new_jersey_shipped_sources.md"
)


def _read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def _git(*arguments: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *arguments],
        cwd=PACKAGE_ROOT,
        capture_output=True,
        text=True,
        check=False,
    )


def test_release_lock_owned_generated_document_is_tracked() -> None:
    release_lock = _read_json(CONTRACT_ROOT / "release-lock.json")
    expected_checksum = release_lock["generated_files"].get(
        GENERATED_DOCUMENT
    )
    assert expected_checksum is not None, (
        "release lock does not own generated document: "
        f"{GENERATED_DOCUMENT}"
    )

    tracked = _git("ls-files", "--error-unmatch", "--", GENERATED_DOCUMENT)
    assert tracked.returncode == 0, (
        "release-lock generated document is not tracked: "
        f"{GENERATED_DOCUMENT}"
    )

    document = PACKAGE_ROOT / GENERATED_DOCUMENT
    assert document.is_file(), (
        "tracked release-lock generated document is missing: "
        f"{GENERATED_DOCUMENT}"
    )
    actual_checksum = (
        "sha256:" + hashlib.sha256(document.read_bytes()).hexdigest()
    )
    assert actual_checksum == expected_checksum


def test_only_release_lock_generated_document_is_unignored_under_docs() -> None:
    generated_document = _git(
        "check-ignore", "--quiet", "--", GENERATED_DOCUMENT
    )
    assert generated_document.returncode == 1, (
        "release-lock generated document remains ignored: "
        f"{GENERATED_DOCUMENT}"
    )

    unrelated_output = "docs/reference/pkgdown-output.html"
    unrelated = _git("check-ignore", "--quiet", "--", unrelated_output)
    assert unrelated.returncode == 0, (
        "unrelated pkgdown output is no longer ignored: "
        f"{unrelated_output}"
    )
