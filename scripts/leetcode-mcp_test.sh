#!/usr/bin/env bash
# Unit tests for scripts/leetcode-mcp pure helpers.
# Arrange-Act-Assert, one behavior per test, no logic in test bodies.
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=leetcode-mcp
source "$TESTS_DIR/leetcode-mcp"

pass=0
fail=0

assert_eq() {
    local name="$1" actual="$2" expected="$3"
    if [ "$actual" = "$expected" ]; then
        echo "PASS: $name"
        pass=$((pass + 1))
    else
        echo "FAIL: $name -- got '$actual', expected '$expected'"
        fail=$((fail + 1))
    fi
}

assert_succeeds() {
    local name="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        echo "PASS: $name"
        pass=$((pass + 1))
    else
        echo "FAIL: $name should succeed"
        fail=$((fail + 1))
    fi
}

assert_fails() {
    local name="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        echo "FAIL: $name should fail"
        fail=$((fail + 1))
    else
        echo "PASS: $name"
        pass=$((pass + 1))
    fi
}

# Note: reading values out of leetcode.toml (formerly extract_toml_value) now lives in
# scripts/leet-toml.sh and is covered by leet-toml_test.sh. This file tests only map_site.

# --- map_site ---

test_map_site_leetcode_com_to_global() {
    local result
    result=$(map_site "leetcode.com")
    assert_eq "map leetcode.com -> global" "$result" "global"
}

test_map_site_empty_to_global() {
    local result
    result=$(map_site "")
    assert_eq "map empty -> global" "$result" "global"
}

test_map_site_leetcode_cn_to_cn() {
    local result
    result=$(map_site "leetcode.cn")
    assert_eq "map leetcode.cn -> cn" "$result" "cn"
}

test_map_site_cn_to_cn() {
    local result
    result=$(map_site "cn")
    assert_eq "map cn -> cn" "$result" "cn"
}

# --- run ---

test_map_site_leetcode_com_to_global
test_map_site_empty_to_global
test_map_site_leetcode_cn_to_cn
test_map_site_cn_to_cn

echo ""
echo "Results: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
