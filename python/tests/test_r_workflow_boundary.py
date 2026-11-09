"""The hosted R check must run behind the same fail-closed boundary as Python."""

from pathlib import Path


def test_r_check_runs_inside_no_egress_boundary():
    root = Path(__file__).resolve().parents[2]
    workflow = (root / ".github/workflows/R-CMD-check.yaml").read_text()
    assert "runs-on: ubuntu-latest" in workflow
    assert "sudo apt-get install -y bubblewrap" in workflow
    assert "sudo apparmor_parser -r /etc/apparmor.d/bwrap" in workflow
    step = workflow.split("- name: Check package inside the no-egress boundary", 1)[1]
    step = step.split("- name:", 1)[0]
    assert "tools/ci/run_no_egress.sh -- Rscript" in step
    assert "rcmdcheck::rcmdcheck(" in step
    assert 'error_on = "error"' in step
    assert '"--no-manual"' in step and '"--no-build-vignettes"' in step
    assert "NJSCHOOLDATA_LIVE_TESTS: \"false\"" in workflow
