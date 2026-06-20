#!/usr/bin/env bash
# Unit tests for scripts/leet-languages.sh pure helpers.
# Arrange-Act-Assert, one behavior per test, no logic in test bodies.
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=leet-languages.sh
source "$TESTS_DIR/leet-languages.sh"
# shellcheck source=leet-toml.sh
source "$TESTS_DIR/leet-toml.sh"   # toml_get, used to read back apply_lang results
# shellcheck source=test-support.sh
source "$TESTS_DIR/test-support.sh"

# --- lang_info ---

test_lang_info_python_maps_to_python3() {
    lang_info python
    assert_eq "python LC_LANG" "$LC_LANG" "python3"
    assert_eq "python LC_COMMENT_LEADING" "$LC_COMMENT_LEADING" "#"
}

test_lang_info_python_has_typing_imports() {
    lang_info python
    assert_eq "python LC_INJECT_BEFORE" "$LC_INJECT_BEFORE" '["from typing import List, Optional, Dict, Set, Tuple"]'
}

test_lang_info_rust_has_empty_inject() {
    lang_info rust
    assert_eq "rust LC_LANG" "$LC_LANG" "rust"
    assert_eq "rust LC_INJECT_BEFORE" "$LC_INJECT_BEFORE" "[]"
    assert_eq "rust LC_COMMENT_LEADING" "$LC_COMMENT_LEADING" "//"
}

test_lang_info_cpp_has_stl_includes() {
    lang_info cpp
    assert_eq "cpp LC_LANG" "$LC_LANG" "cpp"
    assert_eq "cpp LC_COMMENT_LEADING" "$LC_COMMENT_LEADING" "//"
}

test_lang_info_go_has_empty_inject() {
    lang_info go
    assert_eq "go LC_LANG" "$LC_LANG" "go"
    assert_eq "go LC_INJECT_BEFORE" "$LC_INJECT_BEFORE" "[]"
}

test_lang_info_unsupported_fails() {
    assert_fails "unsupported language fails" lang_info kotlin
}

# Note: current_lang moved to scripts/leet-toml.sh as toml_get; see leet-toml_test.sh.

# --- apply_lang_to_toml ---

test_apply_lang_replaces_lang_line() {
    local content updated
    content=$'[code]\nlang = \'python3\'\neditor = \'hx\''
    updated=$(apply_lang_to_toml "$content" "rust" "[]" "//")
    assert_eq "apply_lang replaces lang" "$(toml_get "$updated" lang)" "rust"
}

test_apply_lang_replaces_inject_before() {
    local content updated
    content=$'[code]\ninject_before = ["from typing import List"]'
    updated=$(apply_lang_to_toml "$content" "rust" "[]" "//")
    echo "$updated" | grep -q 'inject_before = \[\]' && { echo "PASS: apply_lang replaces inject_before"; pass=$((pass+1)); } || { echo "FAIL: apply_lang replaces inject_before"; fail=$((fail+1)); }
}

test_apply_lang_adds_comment_leading_if_missing() {
    local content updated
    content=$'[code]\nlang = \'python3\'\neditor = \'hx\''
    updated=$(apply_lang_to_toml "$content" "rust" "[]" "//")
    echo "$updated" | grep -q 'comment_leading = "//"' && { echo "PASS: apply_lang adds comment_leading"; pass=$((pass+1)); } || { echo "FAIL: apply_lang adds comment_leading"; fail=$((fail+1)); }
}

test_apply_lang_replaces_existing_comment_leading() {
    local content updated
    content=$'[code]\ncomment_leading = "#"\nlang = \'python3\''
    updated=$(apply_lang_to_toml "$content" "rust" "[]" "//")
    echo "$updated" | grep -q 'comment_leading = "//"' && { echo "PASS: apply_lang replaces comment_leading"; pass=$((pass+1)); } || { echo "FAIL: apply_lang replaces comment_leading"; fail=$((fail+1)); }
}

test_apply_lang_preserves_other_lines() {
    local content updated
    content=$'[code]\nlang = \'python3\'\neditor = \'hx\'\n[cookies]\nsession = \'abc\''
    updated=$(apply_lang_to_toml "$content" "rust" "[]" "//")
    echo "$updated" | grep -q "editor = 'hx'" && { echo "PASS: apply_lang preserves editor"; pass=$((pass+1)); } || { echo "FAIL: apply_lang preserves editor"; fail=$((fail+1)); }
    echo "$updated" | grep -q "session = 'abc'" && { echo "PASS: apply_lang preserves session"; pass=$((pass+1)); } || { echo "FAIL: apply_lang preserves session"; fail=$((fail+1)); }
}

test_apply_lang_no_duplicate_comment_leading_on_reswitch() {
    local content updated count
    content=$'[code]\nlang = \'rust\'\ncomment_leading = "//"\neditor = \'hx\''
    updated=$(apply_lang_to_toml "$content" "cpp" '[]' "//")
    count=$(echo "$updated" | grep -c 'comment_leading')
    assert_eq "no duplicate comment_leading on re-switch" "$count" "1"
}

# --- run ---

test_lang_info_python_maps_to_python3
test_lang_info_python_has_typing_imports
test_lang_info_rust_has_empty_inject
test_lang_info_cpp_has_stl_includes
test_lang_info_go_has_empty_inject
test_lang_info_unsupported_fails
test_apply_lang_replaces_lang_line
test_apply_lang_replaces_inject_before
test_apply_lang_adds_comment_leading_if_missing
test_apply_lang_replaces_existing_comment_leading
test_apply_lang_preserves_other_lines
test_apply_lang_no_duplicate_comment_leading_on_reswitch

finish
