"""Keep every pytest run away from the real shared cache (generated; see scripts/sync-pytest-cache-guard.py).

Imported by tests/conftest.py. At import time, before any test imports rpy2 or starts R,
it points every cache surface of njschooldata at a throwaway directory:

  R_USER_CACHE_DIR / XDG_CACHE_HOME   rappdirs::user_cache_dir() in R, so the shared
                                      state-schooldata store (processed-v1, historical-assets-v1)
                                      and the package's legacy user_cache_dir both land there
  (no package-specific variable)

THE SOURCE STORE IS PINNED, NOT REDIRECTED. historical-assets-v1 holds publisher bytes
addressed by sha256 and verified on read; a test cannot plant a fake entry under a real key,
and many offline tests legitimately read it. Because R_USER_CACHE_DIR moves, the store's
default location would move with it (to an empty directory), so when the caller has not set
STATE_SCHOOLDATA_HISTORICAL_ROOT it is pinned to the real store's location. Only the
processed store and the legacy per-package cache, which hold derived results a test could
poison, are redirected and guarded.

SCOPING OF THE GUARD. Other sessions on this Mac use the real cache concurrently, so
"anything under the real cache changed" would be flaky. The snapshot (path, mtime, size)
covers only what this package owns: <real>/state-schooldata/processed-v1/njschooldata and the
legacy <real>/njschooldata. A write there during the run fails the session.
"""
import os
import shutil
import sys
import tempfile
from pathlib import Path

PACKAGE = "njschooldata"
CACHE_VARS = []


def real_cache_root():
    """The cache root R would use if nothing were redirected (computed before we redirect)."""
    explicit = os.environ.get("R_USER_CACHE_DIR")
    if explicit:
        return Path(explicit)
    if sys.platform == "darwin":
        return Path.home() / "Library" / "Caches"
    return Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache")


def owned_paths(root):
    return [root / "state-schooldata" / "processed-v1" / PACKAGE, root / PACKAGE]


def snapshot(paths):
    seen = {}
    for base in paths:
        if not base.exists():
            continue
        for p in base.rglob("*"):
            try:
                st = p.stat()
            except OSError:
                continue
            seen[str(p)] = (st.st_mtime_ns, st.st_size)
    return seen


REAL_ROOT = real_cache_root()
OWNED = owned_paths(REAL_ROOT)
BEFORE = snapshot(OWNED)
SCRATCH = Path(tempfile.mkdtemp(prefix=PACKAGE + "-pytest-cache-"))

if not os.environ.get("STATE_SCHOOLDATA_HISTORICAL_ROOT"):
    os.environ["STATE_SCHOOLDATA_HISTORICAL_ROOT"] = str(REAL_ROOT / "state-schooldata" / "historical-assets-v1")
os.environ["R_USER_CACHE_DIR"] = str(SCRATCH / "user-cache")
os.environ["XDG_CACHE_HOME"] = str(SCRATCH / "xdg-cache")
for _name in CACHE_VARS:
    # A value the caller already exported wins (CI, a developer); the guard test then
    # fails if that value points into the real cache.
    os.environ.setdefault(_name, str(SCRATCH / _name.lower()))


def real_cache_changes():
    after = snapshot(OWNED)
    return sorted(
        path for path in set(BEFORE) | set(after) if BEFORE.get(path) != after.get(path)
    )


def pytest_sessionfinish(session, exitstatus):
    changed = real_cache_changes()
    shutil.rmtree(SCRATCH, ignore_errors=True)
    if changed:
        sys.stderr.write(
            "\nCACHE GUARD: this pytest run changed the real cache for %s:\n  %s\n"
            % (PACKAGE, "\n  ".join(changed[:20]))
        )
        session.exitstatus = 1
