#!/usr/bin/env bats
# (c) 2026-* Frederick Bloom -- test_provision_home_dir.bats -- Hanaden AI
# SPEC: Provision.feat/HomeDir -- virtual user home directory creation
# REF:  SCOPE-very-narrow.md ### provision -- CREATES: HOME
#
# Default: ROOT/home/VIRTUAL_USER_NAME
# Custom:  --host-real-home-parent PATH  --virtual-user-name NAME
# ==============================================================================

setup() {
    _test_dir="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    _project_home="$(cd "${_test_dir}/../../../../../.." && pwd)"
    SCRIPT="${_project_home}/src/main/hanaden-bwrap-enhanced/bwrap-enhanced.sh"
    WORK="$(mktemp -d)"
}
teardown() {
    rm -rf "$WORK"
}

@test "PROV-HOME-001: default home parent is ROOT/home" {
    local root="${WORK}/vroot"
    bash "$SCRIPT" provision \
        --host-real-root "$root" \
        --virtual-user-name sandbox_user
    [ -d "${root}/home/sandbox_user" ]
}

@test "PROV-HOME-002: default virtual-user-name is sandbox_user" {
    local root="${WORK}/vroot"
    bash "$SCRIPT" provision \
        --host-real-root "$root"
    [ -d "${root}/home/sandbox_user" ]
}

@test "PROV-HOME-003: custom --virtual-user-name creates correct subdir" {
    local root="${WORK}/vroot"
    bash "$SCRIPT" provision \
        --host-real-root "$root" \
        --virtual-user-name devuser
    [ -d "${root}/home/devuser" ]
}

@test "PROV-HOME-004: custom --virtual-user-name does NOT create sandbox_user" {
    local root="${WORK}/vroot"
    bash "$SCRIPT" provision \
        --host-real-root "$root" \
        --virtual-user-name devuser
    [ ! -e "${root}/home/sandbox_user" ]
}

@test "PROV-HOME-005: custom --host-real-home-parent creates home there" {
    local root="${WORK}/vroot"
    local home_parent="${WORK}/custom-homes"
    bash "$SCRIPT" provision \
        --host-real-root "$root" \
        --host-real-home-parent "$home_parent" \
        --virtual-user-name devuser
    [ -d "${home_parent}/devuser" ]
}

@test "PROV-HOME-006: custom --host-real-home-parent does NOT create home under ROOT/home" {
    local root="${WORK}/vroot"
    local home_parent="${WORK}/custom-homes"
    bash "$SCRIPT" provision \
        --host-real-root "$root" \
        --host-real-home-parent "$home_parent" \
        --virtual-user-name devuser
    [ ! -e "${root}/home/devuser" ]
}

@test "PROV-HOME-007: home dir is a directory (not a file or symlink)" {
    local root="${WORK}/vroot"
    bash "$SCRIPT" provision \
        --host-real-root "$root" \
        --virtual-user-name testuser
    local home="${root}/home/testuser"
    [ -d "$home" ]
    [ ! -L "$home" ]
}

@test "PROV-HOME-008: --host-real-home-parent inside ROOT is supported (default case)" {
    # The most common pattern: home parent IS inside the root
    local root="${WORK}/vroot"
    bash "$SCRIPT" provision \
        --host-real-root "$root" \
        --host-real-home-parent "${root}/home" \
        --virtual-user-name myuser
    [ -d "${root}/home/myuser" ]
}
