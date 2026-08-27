#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
# Architecture: SandboxExecEngine.arch -- end-to-end exec engine verification
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== SandboxExecEngine ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT

# SEE-001: bwrap-enhanced replaces shell via exec and executes command payload
out=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- echo "EXEC_ENGINE_OK" 2>&1)
fout=$(echo "$out" | grep -v '^\[SYS-LOG\]')
if [[ "$fout" == *"EXEC_ENGINE_OK"* ]]; then
  pass "exec_sandbox launches and executes command payload (SEE-001)"
else
  fail "exec_sandbox failed to execute payload (SEE-001): $fout"
fi

# SEE-002: Exit code preservation through inner payload
declare -i ec=0
set +e
"$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'exit 42' >/dev/null 2>&1
ec=$?
set -e
if [[ "$ec" -eq 42 ]]; then
  pass "inner bash payload preserves command exit code (SEE-002)"
else
  fail "expected exit code 42, got $ec (SEE-002)"
fi

# SEE-003: Memory-backed identity injection (/etc/passwd)
pout=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- getent passwd sandbox-user 2>&1 | grep -v '^\[SYS-LOG\]' || true)
if [[ -n "$pout" ]]; then
  pass "FD here-string identity injection verified (SEE-003)"
else
  fail "virtual user identity missing from /etc/passwd (SEE-003)"
fi

results
