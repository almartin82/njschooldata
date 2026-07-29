#!/usr/bin/env python3
"""Block releases without current exact New Jersey source evidence."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
CONTRACT = "new_jersey_shipped_sources"
STATUS = (
    ROOT
    / "inst"
    / "extdata"
    / "source-contract"
    / "contracts"
    / CONTRACT
    / "status.json"
)


def main() -> int:
    verification = subprocess.run(
        [
            sys.executable,
            str(ROOT / "tools/source-validation/verify_package.py"),
            "--package-root",
            str(ROOT),
            "--expected-release",
            "source-validation-v1.0.0-rc.4",
        ],
        check=False,
    )
    if verification.returncode:
        return verification.returncode

    status = json.loads(STATUS.read_text(encoding="utf-8"))
    if status.get("state") != "current":
        print(
            f"release blocked: {CONTRACT} source validation is "
            f"{status.get('state', 'unknown')}; exact successful evidence "
            "from the prior 90 elapsed days is required",
            file=sys.stderr,
        )
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
