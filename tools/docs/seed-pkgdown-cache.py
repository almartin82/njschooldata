#!/usr/bin/env python3
"""Verify committed pkgdown dependency bytes and seed an isolated R cache."""

from __future__ import annotations

import argparse
import base64
import hashlib
import json
from pathlib import Path
import shutil


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--asset-root", type=Path, required=True)
    parser.add_argument("--cache-root", type=Path, required=True)
    args = parser.parse_args()

    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    if manifest.get("schema_version") != "njschooldata-pkgdown-dependencies/v1":
        raise ValueError("invalid pkgdown dependency manifest")
    dependencies = manifest.get("dependencies")
    if not isinstance(dependencies, list) or not dependencies:
        raise ValueError("pkgdown dependency manifest is empty")

    for dependency in dependencies:
        relative = Path(dependency["path"])
        if relative.is_absolute() or ".." in relative.parts:
            raise ValueError(f"unsafe pkgdown dependency path: {relative}")
        source = args.asset_root / relative
        body = source.read_bytes()
        algorithm, expected = dependency["integrity"].split("-", 1)
        observed = base64.b64encode(
            hashlib.new(algorithm, body).digest()
        ).decode("ascii")
        if observed != expected:
            raise ValueError(f"SRI mismatch for {relative}")
        header = body[:600].decode("utf-8", errors="replace").lower()
        if "license" not in header and "licensed" not in header:
            raise ValueError(f"missing license header for {relative}")

        destination = args.cache_root / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, destination)

    print(f"pkgdown-dependency-cache-seeded={len(dependencies)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
