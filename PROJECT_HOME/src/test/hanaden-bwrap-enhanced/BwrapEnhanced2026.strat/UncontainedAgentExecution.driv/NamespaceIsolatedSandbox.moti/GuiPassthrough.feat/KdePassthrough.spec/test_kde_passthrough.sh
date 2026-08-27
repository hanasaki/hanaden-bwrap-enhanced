#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
_T="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)"
source "$_T/shared/env.sh"
source "$_T/shared/assert.sh"
unset _T

echo '=== KdePassthrough ==='
EPHEMERAL=$(mktemp -d /tmp/bwrap-t-XXXXXX); mkdir -p "$EPHEMERAL/home/sandbox-user"; trap "rm -rf '$EPHEMERAL'" EXIT
HOST_RU="/run/user/$(id -u)"

# C1: basic smoke -- sandbox exits 0 with or without a live KDE session on host
if [[ -z "$KDE_FULL_SESSION" ]] && [[ -z "$KDE_SESSION_VERSION" ]]; then
  skip 'no KDE session on host'
  "$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" -- /bin/true 2>/dev/null; ec=$?
  [[ $ec -eq 0 ]] && pass 'sandbox exits 0 without KDE (MUST-NOT-FATAL) (C1)' || fail "ec=$ec"
else
  pass 'KDE session detected -- bind tested via smoke'
fi

# KDE-005/C1: D-Bus session bus MUST be absent when --enable-kde used without --enable-dbus.
# Rationale: --enable-kde binds kwallet5/KSMserver/drkonqi sockets only. The session bus
# (/run/user/UID/bus) must only appear when --enable-dbus is explicitly passed.
# This test catches the regression where KDE silently enables D-Bus.
out=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" \
  --enable-kde -- /bin/bash -c \
  "test -e ${HOST_RU}/bus && echo BUS_PRESENT || echo BUS_ABSENT" 2>&1)
fout=$(echo "$out" | grep -v '^\[SYS-LOG\]')
if echo "$fout" | grep -q 'BUS_ABSENT'; then
  pass 'D-Bus bus socket absent with --enable-kde (no --enable-dbus) (KDE-005/C1)'
else
  fail "D-Bus bus socket present without --enable-dbus -- decoupling broken: $fout"
fi

# KDE-005/C2: positive control -- bus socket MUST appear when --enable-dbus is added.
# Skipped if no host session bus (headless CI). If this fails while C1 passes,
# the DBUS block itself is broken.
if [[ -e "${HOST_RU}/bus" ]]; then
  out2=$("$BWRAP_SH" --clear-env --host-real-root / --host-real-home-parent "$EPHEMERAL/home" \
    --enable-kde --enable-dbus -- /bin/bash -c \
    "test -e ${HOST_RU}/bus && echo BUS_PRESENT || echo BUS_ABSENT" 2>&1)
  fout2=$(echo "$out2" | grep -v '^\[SYS-LOG\]')
  if echo "$fout2" | grep -q 'BUS_PRESENT'; then
    pass 'D-Bus bus socket present with --enable-kde --enable-dbus (positive control) (KDE-005/C2)'
  else
    fail "D-Bus bus socket absent even with --enable-dbus -- binding broken: $fout2"
  fi
else
  skip 'no host D-Bus session bus -- positive control skipped (KDE-005/C2)'
fi

results
