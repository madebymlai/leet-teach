#!/usr/bin/env bash
# Unit tests for scripts/leetcode-mcp pure helpers.
# Arrange-Act-Assert, one behavior per test, no logic in test bodies.
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=leetcode-mcp
source "$TESTS_DIR/leetcode-mcp"
# shellcheck source=test-support.sh
source "$TESTS_DIR/test-support.sh"

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

finish
