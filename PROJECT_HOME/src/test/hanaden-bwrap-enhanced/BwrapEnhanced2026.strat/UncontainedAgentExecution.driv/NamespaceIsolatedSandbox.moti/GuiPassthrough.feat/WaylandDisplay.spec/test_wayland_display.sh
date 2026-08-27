#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== WaylandDisplay ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
RUD="/run/user/$(id -u)"
WSOCK="$RUD/wayland-0"
if [[ ! -S "$WSOCK" ]]; then
  skip 'SKIP: no Wayland socket on host'
  "$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/true 2>/dev/null; ec=$?
  if [[ $ec -eq 0 ]]; then pass 'sandbox exits 0 without Wayland (MUST-NOT-FATAL) (C1)'
  else fail "sandbox FAILed without Wayland: ec=$ec"; fi
else
  out=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'ls $XDG_RUNTIME_DIR/wayland-0 2>&1' 2>&1)
  fout=$(echo "$out" | grep -v '^\[SYS-LOG\]')
  if echo "$fout" | grep -q 'wayland-0'; then
    pass 'Wayland socket bound inside sandbox (C1)'
  else
    fail "Wayland socket missing: $fout"
  fi
fi

results
