#!/usr/bin/env bash
# Run a command inside a no-egress boundary, without root.
#
# GENERATED FILE -- do not edit in a package.
# Source: scripts/ci-workflows/templates/run_no_egress.sh in the state-schooldata
# superproject. Regenerate with `python3 scripts/ci-workflows/render.py`.
# This file is byte-identical in every package; nothing here is per-state.
#
# The boundary is a rootless bubblewrap network namespace: the job gets
# loopback and nothing else. This replaces an earlier implementation that
# used `sudo iptables` to REJECT on the host's global OUTPUT chain, which
# needed root and, on a shared runner, would have cut off every other repo.
# Here the isolation is scoped to this process tree and the host is untouched.
#
# The script re-execs itself inside the namespace, then proves the boundary
# with three independent sentinels (Python sockets, R connections, curl)
# before running any real work. A sentinel that reaches the network is a
# hard failure: the boundary is not in force and the run must not continue.
#
# Requires bubblewrap. On Ubuntu 24.04 it also needs an AppArmor profile
# granting /usr/bin/bwrap the `userns` permission, otherwise the catch-all
# unprivileged_userns profile denies CAP_NET_ADMIN inside the namespace.
#
# This script is a BOUNDARY, not a test runner. It never decides what to run.
# The caller names the command; the workflow's `run:` block is where a reader
# can see what executes. Seven packages (la ms nd ok or ut wa) once baked a
# specific Rscript/pytest line in here, which hid the real work from the
# workflow and made the same file mean seven different things.
set -euo pipefail

# --- derive the package prefix from the repo, never hardcoded --------------
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
pkg_name="$(basename "$repo_root")"
PREFIX="$(printf '%s' "$pkg_name" | tr '[:lower:]-' '[:upper:]_')"

if [[ "${1:-}" == "--" ]]; then shift; fi

if [[ "${1:-}" != "--__inside_boundary" ]]; then
  if [[ "$#" -eq 0 ]]; then
    echo "usage: run_no_egress.sh -- command [args ...]" >&2
    exit 64
  fi
  if ! command -v bwrap >/dev/null 2>&1; then
    echo "no-egress requires bubblewrap (apt-get install bubblewrap)" >&2
    exit 69
  fi
  exec bwrap --unshare-net --dev-bind / / --proc /proc -- \
    bash "$0" --__inside_boundary "$@"
fi
shift

# --- prove the boundary is real -------------------------------------------
# Each sentinel uses a different network stack. If ANY reaches the wire the
# boundary is not in force, and a suite that "passed offline" would be lying.
if python3 -c 'import socket; socket.create_connection(("example.com", 443), 3)' 2>/dev/null; then
  echo "no-egress: Python sentinel reached the network" >&2; exit 70
fi
if command -v Rscript >/dev/null 2>&1; then
  if Rscript -e 'con <- url("https://example.com"); open(con); close(con)' >/dev/null 2>&1; then
    echo "no-egress: R sentinel reached the network" >&2; exit 70
  fi
fi
if curl --fail --max-time 3 https://example.com >/dev/null 2>&1; then
  echo "no-egress: curl sentinel reached the network" >&2; exit 70
fi
# Loopback must survive: the suites bind localhost.
if ! python3 -c 'import socket
s = socket.socket(); s.bind(("127.0.0.1", 0)); s.listen(1)' 2>/dev/null; then
  echo "no-egress: loopback unavailable inside the boundary" >&2; exit 71
fi

# --- declare the boundary to the suites ------------------------------------
# These are facts about the environment, not test selection. <PKG>_OFFLINE is
# the name 19 packages already read to choose bundled data over a live fetch;
# exporting it is what lets an offline suite pass honestly rather than fail at
# a socket. Inherited opt-in gates must also be cleared: a shared runner can
# otherwise turn an ordinary push/PR guard into an acquisition attempt.
# RIDE is Rhode Island's legacy opt-in namespace; SCHOOLDATA is shared.
live_prefixes=("$PREFIX" "SCHOOLDATA" "RIDE")
# Legacy tests use short, underscored, or private source-matrix prefixes.
if [[ "$PREFIX" =~ ^[A-Z]{2}SCHOOLDATA$ ]]; then
  live_prefixes+=("${PREFIX%SCHOOLDATA}" "${PREFIX%SCHOOLDATA}_SCHOOLDATA"
                  "E2_${PREFIX%SCHOOLDATA}")
fi
# Keep category-specific gates declared by workflow discovery off too. The
# boundary regression checks every declared live_env name against this list.
for gate in ALLOW_LIVE RUN_LIVE RUN_LIVE_TESTS LIVE_TESTS TEST_LIVE LIVE_VALIDATION \
  RUN_LIVE_VALIDATION RUN_ABSENCE_REDISCOVERY RUN_FACILITIES_LIVE \
  RUN_LEGACY_PIPELINE_LIVE RUN_ABSENCE_GAP_TESTS RUN_SOURCE_MATRIX; do
  for live_prefix in "${live_prefixes[@]}"; do
    unset "${live_prefix}_${gate}"
  done
done
export "${PREFIX}_EGRESS_BOUNDARY"=1
export "${PREFIX}_OFFLINE"=true

# The cache dir is deliberately NOT set here. Each package's testthat helper
# already creates a per-PID throwaway cache root and only defaults it "when
# nothing already set it", so a value exported here WINS and silently replaces
# a stronger isolation with a weaker one. azschooldata's
# test-cache-isolation.R asserts the resolved dir contains the PID, and an
# earlier version of this script broke it by doing exactly that.

exec "$@"
