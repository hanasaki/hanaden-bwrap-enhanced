#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== XdgVarsSet ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
out=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/bash -c 'env | grep XDG' 2>&1)
fout=$(echo "$out" | grep -v '^\[SYS-LOG\]')
# Code SST: bwrap-enhanced sets XDG_DATA_HOME, XDG_STATE_HOME, XDG_DATA_DIRS
# XDG_RUNTIME_DIR is NOT set by bwrap-enhanced (no --tmpfs /run/user for user
if echo "$fout" | grep -q 'XDG_DATA_HOME='; then
  pass 'XDG_DATA_HOME set (C1 -- code SST)'
else
  fail "XDG_DATA_HOME missing: $fout"
fi
if echo "$fout" | grep -q 'XDG_STATE_HOME='; then
  pass 'XDG_STATE_HOME set (C2 -- code SST)'
else
  fail "XDG_STATE_HOME missing: $fout"
fi
if echo "$fout" | grep -q 'XDG_DATA_DIRS='; then
  pass 'XDG_DATA_DIRS set (C3 -- code SST)'
else
  fail "XDG_DATA_DIRS missing: $fout"
fi
# XDG_RUNTIME_DIR is set by GUI passthrough flags (--enable-wayland etc.) not by default
if echo "$fout" | grep -q 'XDG_RUNTIME_DIR='; then
  pass 'XDG_RUNTIME_DIR set (C4 -- optional, set by --enable-wayland/dbus)'
else
  skip 'XDG_RUNTIME_DIR not set without GUI flags (expected per code SST L476-490)'
fi

results
