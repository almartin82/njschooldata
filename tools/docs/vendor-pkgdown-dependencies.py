#!/usr/bin/env python3
"""Vendor pkgdown's SRI-pinned external dependencies from a verified cache."""

from __future__ import annotations

import argparse
import base64
import hashlib
import json
from pathlib import Path
import shutil


DEPENDENCIES = (
    {
        "path": "headroom/0.11.0/headroom.min.js",
        "url": "https://cdnjs.cloudflare.com/ajax/libs/headroom/0.11.0/headroom.min.js",
        "integrity": "sha256-AsUX4SJE1+yuDu5+mAVzJbuYNPHj/WroHuZ8Ir/CkE0=",
        "license": "MIT",
    },
    {
        "path": "headroom/0.11.0/jQuery.headroom.min.js",
        "url": "https://cdnjs.cloudflare.com/ajax/libs/headroom/0.11.0/jQuery.headroom.min.js",
        "integrity": "sha256-ZX/yNShbjqsohH1k95liqY9Gd8uOiE1S4vZc+9KQ1K4=",
        "license": "MIT",
    },
    {
        "path": "bootstrap-toc/1.0.1/bootstrap-toc.min.js",
        "url": "https://cdn.jsdelivr.net/gh/afeld/bootstrap-toc@v1.0.1/dist/bootstrap-toc.min.js",
        "integrity": "sha256-4veVQbu7//Lk5TSmc7YV48MxtMy98e26cf5MrgZYnwo=",
        "license": "MIT",
    },
    {
        "path": "clipboard.js/2.0.11/clipboard.min.js",
        "url": "https://cdnjs.cloudflare.com/ajax/libs/clipboard.js/2.0.11/clipboard.min.js",
        "integrity": "sha512-7O5pXpc0oCRrxk8RUfDYFgn0nO1t+jLuIOQdOMRp4APB7uZ4vSjspzp5y6YDtDs4VzUSTbWzBFZ/LKJhnyFOKw==",
        "license": "MIT",
    },
    {
        "path": "search/1.0.0/fuse.min.js",
        "url": "https://cdnjs.cloudflare.com/ajax/libs/fuse.js/6.4.6/fuse.min.js",
        "integrity": "sha512-KnvCNMwWBGCfxdOtUpEtYgoM59HHgjHnsVGSxxgz7QH1DYeURk+am9p3J+gsOevfE29DV0V+/Dd52ykTKxN5fA==",
        "license": "Apache-2.0",
    },
    {
        "path": "search/1.0.0/autocomplete.jquery.min.js",
        "url": "https://cdnjs.cloudflare.com/ajax/libs/autocomplete.js/0.38.0/autocomplete.jquery.min.js",
        "integrity": "sha512-GU9ayf+66Xx2TmpxqJpliWbT5PiGYxpaG8rfnBEk1LL8l1KGkRShhngwdXK1UgqhAzWpZHSiYPc09/NwDQIGyg==",
        "license": "MIT",
    },
    {
        "path": "search/1.0.0/mark.min.js",
        "url": "https://cdnjs.cloudflare.com/ajax/libs/mark.js/8.11.1/mark.min.js",
        "integrity": "sha512-5CYOlHXGh6QpOFA/TeTylKLWfB3ftPsde7AnmhuitiTX4K5SqCLBeKro6sPS8ilsz1Q4NRx3v8Ko2IBiszzdww==",
        "license": "MIT",
    },
)


def _verify(path: Path, dependency: dict[str, str]) -> None:
    algorithm, expected = dependency["integrity"].split("-", 1)
    body = path.read_bytes()
    observed = base64.b64encode(hashlib.new(algorithm, body).digest()).decode()
    if observed != expected:
        raise ValueError(f"SRI mismatch for {dependency['path']}")
    header = body[:600].decode("utf-8", errors="replace").lower()
    if "license" not in header and "licensed" not in header:
        raise ValueError(f"missing license header for {dependency['path']}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-cache", type=Path, required=True)
    parser.add_argument("--destination", type=Path, required=True)
    args = parser.parse_args()

    asset_root = args.destination / "pkgdown-cache"
    for dependency in DEPENDENCIES:
        source = args.source_cache / dependency["path"]
        _verify(source, dependency)
        destination = asset_root / dependency["path"]
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, destination)
        _verify(destination, dependency)

    manifest = {
        "schema_version": "njschooldata-pkgdown-dependencies/v1",
        "authority": (
            "pkgdown external_dependencies URL and SRI metadata; license "
            "provenance is retained in each verified asset header"
        ),
        "dependencies": list(DEPENDENCIES),
    }
    args.destination.mkdir(parents=True, exist_ok=True)
    (args.destination / "pkgdown-dependencies.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(f"vendored-pkgdown-dependencies={len(DEPENDENCIES)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
