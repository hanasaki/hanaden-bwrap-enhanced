#!/bin/bash
source "/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/test/hanaden-bwrap-enhanced/shared/env.sh"
source "/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/test/hanaden-bwrap-enhanced/shared/assert.sh"
echo "=== BwrapMinimalSmoke ==="

EPHEMERAL=$(mktemp -d /tmp/bwrap-smoke-XXXXXX)
mkdir -p "$EPHEMERAL/home/sandbox-user"
trap "rm -rf '$EPHEMERAL'" EXIT

# C1: minimal sandbox launches and exits 0
"/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh" \
  --clear-env \
  --host-real-root / \
  --host-real-home-parent "$EPHEMERAL/home" \
  -- /bin/true
ec=$?
if [[ $ec -eq 0 ]]; then
  pass "minimal sandbox exits 0 (C1)"
else
  fail "minimal sandbox exits $ec (GATE-BLOCKER: all Phase 1-3 blocked)"
  results
  exit 1
fi

# C2: sandbox-user home writable
"/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh" \
  --clear-env \
  --host-real-root / \
  --host-real-home-parent "$EPHEMERAL/home" \
  -- /bin/bash -c 'touch /home/sandbox-user/smoke-test && echo ok'
ec=$?
[[ $ec -eq 0 ]] && pass "home writable inside sandbox (C2)" || fail "home not writable (C2, exit=$ec)"

# C3: /etc/passwd present inside sandbox
out=$("/homes/home-local/hanasaki/home-remote/home-remote-nfs/data/Bloom-Frederick/dev-projects-local/hanaden-bwrap-enhanced/PROJECT_HOME/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh" \
  --clear-env \
  --host-real-root / \
  --host-real-home-parent "$EPHEMERAL/home" \
  -- /bin/bash -c 'cat /etc/passwd | grep sandbox-user' 2>&1)
if echo "$out" | grep -q sandbox-user; then
  pass "sandbox-user in /etc/passwd (C3): $(echo "$out" | grep sandbox-user)"
else
  fail "sandbox-user missing from /etc/passwd (C3) | got: $out"
fi

results
