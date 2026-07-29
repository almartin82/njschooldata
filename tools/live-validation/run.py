#!/usr/bin/env python3
"""Explicit New Jersey live-validation entry point.

No complete NJDOE artifact is admitted to the source-validation manifest, so
there is no bounded artifact request this runner may make. It reports that
coverage limitation without contacting a source or advancing validation time.
"""

from __future__ import annotations

import argparse
import json
import os
import sys


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--execute", action="store_true")
    args = parser.parse_args()
    dispatched = os.environ.get("GITHUB_EVENT_NAME") == "workflow_dispatch"
    if not args.execute and not dispatched:
        print(
            "Refusing live validation without --execute. No request was made.",
            file=sys.stderr,
        )
        return 2

    print(
        json.dumps(
            {
                "reason": (
                    "No complete NJDOE artifact is admitted to this contract; "
                    "manual source acquisition and lineage review are required."
                ),
                "request_budget": 6,
                "request_count": 0,
                "terminal_state": "contract_failure",
                "validation_clock_advanced": False,
            },
            sort_keys=True,
        )
    )
    return 6


if __name__ == "__main__":
    raise SystemExit(main())
