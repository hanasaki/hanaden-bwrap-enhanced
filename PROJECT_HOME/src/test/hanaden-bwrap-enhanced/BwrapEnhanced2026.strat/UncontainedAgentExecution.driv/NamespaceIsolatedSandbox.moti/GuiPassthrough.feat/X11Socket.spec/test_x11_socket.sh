#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== X11Socket ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
if [[ -z "$DISPLAY" ]]; then
  skip 'SKIP: no X11 display on host'
  "$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/true 2>/dev/null; ec=$?
  if [[ $ec -eq 0 ]]; then pass 'sandbox exits 0 without X11 (MUST-NOT-FATAL) (C1)'
  else fail "sandbox FAILed: ec=$ec"; fi
else
  out=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'ls /tmp/.X11-unix/ 2>&1' 2>&1)
  fout=$(echo "$out" | grep -v '^\[SYS-LOG\]')
  if echo "$fout" | grep -qE 'X[0-9]'; then
    pass 'X11 socket bound inside sandbox (C1)'
  else
    fail "X11 socket missing: $fout"
  fi
fi

results
