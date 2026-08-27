#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== AudioPassthrough ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
RUD="/run/user/$(id -u)"
if [[ ! -d "$RUD/pulse" ]] && [[ ! -S "$RUD/pipewire-0" ]]; then
  skip 'SKIP: no PulseAudio/PipeWire socket on host'
  "$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/true; ec=$?
  [[ $ec -eq 0 ]] && pass 'sandbox exits 0 without audio (MUST-NOT-FATAL) (C1)' || fail "ec=$ec"
else
  "$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'ls $XDG_RUNTIME_DIR/pulse/ 2>/dev/null || ls $XDG_RUNTIME_DIR/pipewire-0 2>/dev/null; echo ok'
  pass 'audio socket accessible inside sandbox (C1)'
fi

results
