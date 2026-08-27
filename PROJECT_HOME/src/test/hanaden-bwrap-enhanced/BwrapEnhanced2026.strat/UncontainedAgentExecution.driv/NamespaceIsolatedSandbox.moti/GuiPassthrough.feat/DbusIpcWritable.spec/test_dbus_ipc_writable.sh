#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== DbusIpcWritable ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
RUD="/run/user/$(id -u)"
if [[ ! -S "$RUD/bus" ]]; then
  skip 'no D-Bus session bus on host'
  "$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/true 2>/dev/null; ec=$?
  if [[ $ec -eq 0 ]]; then pass 'sandbox exits 0 without D-Bus (MUST-NOT-FATAL) (C1)'
  else fail "ec=$ec"; fi
else
  out=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'ls -la $XDG_RUNTIME_DIR/bus 2>&1' 2>&1)
  fout=$(echo "$out" | grep -v '^\[SYS-LOG\]')
  if echo "$fout" | grep -q 'bus'; then
    pass 'D-Bus socket bound inside sandbox (C1)'
  else
    fail "dbus: $fout"
  fi
fi

results
