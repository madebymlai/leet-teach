#!/usr/bin/env bash
# Unit tests for scripts/leet-languages.sh pure helpers.
# Arrange-Act-Assert, one behavior per test, no logic in test bodies.
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=leet-languages.sh
source "$TESTS_DIR/leet-languages.sh"
# shellcheck source=test-support.sh
source "$TESTS_DIR/test-support.sh"

# --- lang_info ---

# lang_info prints "lang<TAB>inject_before<TAB>comment_leading"; callers parse the record.

test_lang_info_python_maps_to_python3() {
    local lang inject comment
    IFS=$'\t' read -r lang inject comment <<< "$(lang_info python)"
    assert_eq "python lang" "$lang" "python3"
    assert_eq "python comment_leading" "$comment" "#"
}

test_lang_info_python_has_typing_imports() {
    local lang inject comment
    IFS=$'\t' read -r lang inject comment <<< "$(lang_info python)"
    assert_eq "python inject_before" "$inject" '["from typing import List, Optional, Dict, Set, Tuple"]'
}

test_lang_info_rust_has_empty_inject() {
    local lang inject comment
    IFS=$'\t' read -r lang inject comment <<< "$(lang_info rust)"
    assert_eq "rust lang" "$lang" "rust"
    assert_eq "rust inject_before" "$inject" "[]"
    assert_eq "rust comment_leading" "$comment" "//"
}

test_lang_info_cpp_has_stl_includes() {
    local lang inject comment
    IFS=$'\t' read -r lang inject comment <<< "$(lang_info cpp)"
    assert_eq "cpp lang" "$lang" "cpp"
    assert_eq "cpp comment_leading" "$comment" "//"
}

test_lang_info_go_has_empty_inject() {
    local lang inject comment
    IFS=$'\t' read -r lang inject comment <<< "$(lang_info go)"
    assert_eq "go lang" "$lang" "go"
    assert_eq "go inject_before" "$inject" "[]"
}

test_lang_info_unsupported_fails() {
    assert_fails "unsupported language fails" lang_info kotlin
}

# --- run ---

test_lang_info_python_maps_to_python3
test_lang_info_python_has_typing_imports
test_lang_info_rust_has_empty_inject
test_lang_info_cpp_has_stl_includes
test_lang_info_go_has_empty_inject
test_lang_info_unsupported_fails

finish
