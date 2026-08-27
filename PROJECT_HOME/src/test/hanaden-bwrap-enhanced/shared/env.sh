#!/bin/bash
# (c) 2026-* Frederick Bloom -- All Rights Reserved -- Hanaden AI
# Relocatable: all paths derived from this file's location via BASH_SOURCE.
export SHARED="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export TEST_ROOT="$(dirname "$SHARED")"
# TEST_ROOT = .../PROJECT_HOME/src/test/hanaden-bwrap-enhanced
# WS (workspace root) is 4 levels above TEST_ROOT:
#   hanaden-bwrap-enhanced/PROJECT_HOME/src/test/hanaden-bwrap-enhanced
#   -> /src/test -> /src -> /PROJECT_HOME -> /hanaden-bwrap-enhanced
export WS="$(cd "$TEST_ROOT/../../../.." && pwd)"
export BWRAP_SH="$WS/PROJECT_HOME/boot/bwrap-enhanced.sh"
export HOST_ROOT="/"
export VIRTUAL_USER="sandbox-user"
