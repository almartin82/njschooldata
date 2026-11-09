"""Guard: no pytest run may touch the real shared cache owned by njschooldata.

The redirect and the session-end check live in tests/_cache_isolation_guard.py (imported by
conftest.py). The snapshot is scoped to paths this package owns, because other sessions use
the rest of the real cache concurrently.
"""
import os
from pathlib import Path

import _cache_isolation_guard as guard


def _under(path, root):
    path, root = Path(path).resolve(), Path(root).resolve()
    return path == root or root in path.parents


def test_cache_surfaces_are_redirected_off_the_real_cache():
    names = ["R_USER_CACHE_DIR", "XDG_CACHE_HOME"]
    names += list(guard.CACHE_VARS)
    for name in names:
        value = os.environ.get(name)
        assert value, name + " is not set"
        assert not _under(value, guard.REAL_ROOT), name + " points into the real cache: " + value


def test_real_cache_owned_by_this_package_is_unchanged_so_far():
    assert guard.real_cache_changes() == []
