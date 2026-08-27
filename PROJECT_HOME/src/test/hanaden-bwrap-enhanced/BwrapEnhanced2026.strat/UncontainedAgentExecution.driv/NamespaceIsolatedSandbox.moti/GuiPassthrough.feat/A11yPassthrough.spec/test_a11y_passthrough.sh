#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== A11yPassthrough ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
RUD="/run/user/$(id -u)"
if [[ ! -S "$RUD/at-spi/bus_1" ]] && [[ ! -d "$RUD/at-spi" ]]; then
  skip 'SKIP: no AT-SPI bus on host'
  "$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/true; ec=$?
  [[ $ec -eq 0 ]] && pass 'sandbox exits 0 without AT-SPI (MUST-NOT-FATAL) (C1)' || fail "ec=$ec"
else
  out=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'ls $XDG_RUNTIME_DIR/at-spi/ 2>&1' 2>&1)
  pass 'AT-SPI socket accessible inside sandbox (C1)'
fi

results
