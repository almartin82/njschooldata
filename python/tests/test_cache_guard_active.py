"""The workflow's Python-only suite must load its shared cache guard."""

import os
from pathlib import Path

import _cache_isolation_guard as guard


def test_workflow_suite_redirects_package_caches():
    real_root = guard.REAL_ROOT.resolve()
    for key in ("R_USER_CACHE_DIR", "XDG_CACHE_HOME"):
        redirected = Path(os.environ[key]).resolve()
        assert redirected != real_root
        assert real_root not in redirected.parents
    assert guard.real_cache_changes() == []
