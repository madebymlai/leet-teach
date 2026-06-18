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

# --- extract_toml_value: session ---

test_extract_session_single_quoted() {
    local content id
    content=$'[cookies]\nsession = \'abc123secret\''
    id=$(extract_toml_value "$content" "session")
    assert_eq "extract session single-quoted" "$id" "abc123secret"
}

test_extract_session_double_quoted() {
    local content id
    content=$'[cookies]\nsession = "abc123secret"'
    id=$(extract_toml_value "$content" "session")
    assert_eq "extract session double-quoted" "$id" "abc123secret"
}

test_extract_session_indented() {
    local content id
    content=$'[cookies]\n  session = \'abc123\''
    id=$(extract_toml_value "$content" "session")
    assert_eq "extract session indented" "$id" "abc123"
}

test_extract_session_empty_returns_empty() {
    local content id
    content=$'[cookies]\nsession = \'\''
    id=$(extract_toml_value "$content" "session")
    assert_eq "extract session empty value" "$id" ""
}

test_extract_session_missing_key_returns_empty() {
    local content id
    content=$'[cookies]\ncsrf = \'abc\''
    id=$(extract_toml_value "$content" "session")
    assert_eq "extract session missing key" "$id" ""
}

# --- extract_toml_value: site ---

test_extract_site_leetcode_com() {
    local content val
    content=$'[cookies]\nsite = \'leetcode.com\''
    val=$(extract_toml_value "$content" "site")
    assert_eq "extract site leetcode.com" "$val" "leetcode.com"
}

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

test_extract_session_single_quoted
test_extract_session_double_quoted
test_extract_session_indented
test_extract_session_empty_returns_empty
test_extract_session_missing_key_returns_empty
test_extract_site_leetcode_com
test_map_site_leetcode_com_to_global
test_map_site_empty_to_global
test_map_site_leetcode_cn_to_cn
test_map_site_cn_to_cn

echo ""
echo "Results: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
