#!/usr/bin/env bash
# Unit tests for scripts/leet-toml.sh pure helpers.
# Arrange-Act-Assert, one behavior per test, no logic in test bodies.
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=leet-toml.sh
source "$TESTS_DIR/leet-toml.sh"
# shellcheck source=test-support.sh
source "$TESTS_DIR/test-support.sh"

# --- toml_get ---

test_toml_get_extracts_single_quoted_value() {
    local content val
    content=$'[cookies]\nsession = \'abc123secret\''
    val=$(toml_get "$content" "session")
    assert_eq "toml_get extracts single-quoted value" "$val" "abc123secret"
}

test_toml_get_extracts_double_quoted_value() {
    local content val
    content=$'[cookies]\nsession = "abc123secret"'
    val=$(toml_get "$content" "session")
    assert_eq "toml_get extracts double-quoted value" "$val" "abc123secret"
}

test_toml_get_tolerates_indentation_and_loose_spacing() {
    local content val
    content=$'[cookies]\n  session   =   \'abc123\''
    val=$(toml_get "$content" "session")
    assert_eq "toml_get tolerates indentation and loose spacing" "$val" "abc123"
}

test_toml_get_empty_value_returns_empty() {
    local content val
    content=$'[cookies]\nsession = \'\''
    val=$(toml_get "$content" "session")
    assert_eq "toml_get empty value returns empty" "$val" ""
}

test_toml_get_missing_key_returns_empty() {
    local content val
    content=$'[cookies]\ncsrf = \'abc\''
    val=$(toml_get "$content" "session")
    assert_eq "toml_get missing key returns empty" "$val" ""
}

test_toml_get_reads_only_the_named_key() {
    local content val
    content=$'[cookies]\ncsrf = \'CSRFTOKEN\'\nsession = \'SESSIONVALUE\''
    val=$(toml_get "$content" "session")
    assert_eq "toml_get reads only the named key (no cross-key bleed)" "$val" "SESSIONVALUE"
}

test_toml_get_returns_first_when_key_repeats() {
    local content val
    content=$'[code]\nlang = \'python3\'\nlang = \'rust\''
    val=$(toml_get "$content" "lang")
    assert_eq "toml_get returns first match when key repeats" "$val" "python3"
}

# --- toml_has ---

test_toml_has_true_for_nonempty_value() {
    local content
    content=$'[cookies]\nsession = \'abc123secret\''
    assert_succeeds "toml_has true for nonempty value" toml_has "$content" "session"
}

test_toml_has_false_for_empty_value() {
    local content
    content=$'[cookies]\nsession = \'\''
    assert_fails "toml_has false for empty value" toml_has "$content" "session"
}

test_toml_has_false_for_missing_key() {
    local content
    content=$'[cookies]\ncsrf = \'abc\''
    assert_fails "toml_has false for missing key" toml_has "$content" "session"
}

test_toml_has_true_for_double_quoted_value() {
    local content
    content=$'[cookies]\nsession = "abc123secret"'
    assert_succeeds "toml_has true for double-quoted value" toml_has "$content" "session"
}

test_toml_has_true_for_indented_key() {
    local content
    content=$'[cookies]\n  session = \'abc\''
    assert_succeeds "toml_has true for indented key" toml_has "$content" "session"
}

# --- toml_set ---

test_toml_set_replaces_single_quoted_value() {
    local content out
    content=$'[cookies]\nsession = \'OLD\''
    out=$(toml_set "$content" session "NEWVAL")
    assert_eq "toml_set replaces single-quoted value" "$(toml_get "$out" session)" "NEWVAL"
}

test_toml_set_preserves_quote_style() {
    local content out
    content=$'[cookies]\nsession = \'OLD\''
    out=$(toml_set "$content" session "NEWVAL")
    assert_eq "toml_set keeps single quotes" "$out" $'[cookies]\nsession = \'NEWVAL\''
}

test_toml_set_only_touches_named_key() {
    local content out
    content=$'[cookies]\ncsrf = \'CSRFOLD\'\nsession = \'SESSOLD\''
    out=$(toml_set "$content" session "SESSNEW")
    assert_eq "toml_set leaves csrf untouched" "$(toml_get "$out" csrf)" "CSRFOLD"
    assert_eq "toml_set updates session only" "$(toml_get "$out" session)" "SESSNEW"
}

test_toml_set_tolerates_indentation() {
    local content out
    content=$'[cookies]\n  session   =   \'OLD\''
    out=$(toml_set "$content" session "NEWVAL")
    assert_eq "toml_set tolerates indentation/spacing" "$(toml_get "$out" session)" "NEWVAL"
}

test_toml_set_handles_jwt_with_dots_and_dashes() {
    local content out jwt
    jwt='eyJ0eXAi.abc-_DEF.sig123'
    content=$'[cookies]\nsession = \'OLD\''
    out=$(toml_set "$content" session "$jwt")
    assert_eq "toml_set handles JWT punctuation" "$(toml_get "$out" session)" "$jwt"
}

test_toml_set_absent_key_unchanged() {
    local content out
    content=$'[cookies]\ncsrf = \'abc\''
    out=$(toml_set "$content" session "NEWVAL")
    assert_eq "toml_set leaves content unchanged when key absent" "$out" "$content"
}

# --- toml_path ---

test_toml_path_defaults_to_home_leetcode() {
    local out
    out=$(LEETCODE_TOML='' toml_path)
    assert_eq "toml_path defaults to ~/.leetcode/leetcode.toml" "$out" "$HOME/.leetcode/leetcode.toml"
}

test_toml_path_honors_env_override() {
    local out
    out=$(LEETCODE_TOML=/tmp/custom.toml toml_path)
    assert_eq "toml_path honors LEETCODE_TOML override" "$out" "/tmp/custom.toml"
}

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
    assert_succeeds "apply_lang replaces inject_before" grep -q 'inject_before = \[\]' <<< "$updated"
}

test_apply_lang_adds_comment_leading_if_missing() {
    local content updated
    content=$'[code]\nlang = \'python3\'\neditor = \'hx\''
    updated=$(apply_lang_to_toml "$content" "rust" "[]" "//")
    assert_succeeds "apply_lang adds comment_leading" grep -q 'comment_leading = "//"' <<< "$updated"
}

test_apply_lang_replaces_existing_comment_leading() {
    local content updated
    content=$'[code]\ncomment_leading = "#"\nlang = \'python3\''
    updated=$(apply_lang_to_toml "$content" "rust" "[]" "//")
    assert_succeeds "apply_lang replaces comment_leading" grep -q 'comment_leading = "//"' <<< "$updated"
}

test_apply_lang_preserves_other_lines() {
    local content updated
    content=$'[code]\nlang = \'python3\'\neditor = \'hx\'\n[cookies]\nsession = \'abc\''
    updated=$(apply_lang_to_toml "$content" "rust" "[]" "//")
    assert_succeeds "apply_lang preserves editor" grep -q "editor = 'hx'" <<< "$updated"
    assert_succeeds "apply_lang preserves session" grep -q "session = 'abc'" <<< "$updated"
}

test_apply_lang_no_duplicate_comment_leading_on_reswitch() {
    local content updated count
    content=$'[code]\nlang = \'rust\'\ncomment_leading = "//"\neditor = \'hx\''
    updated=$(apply_lang_to_toml "$content" "cpp" '[]' "//")
    count=$(echo "$updated" | grep -c 'comment_leading')
    assert_eq "no duplicate comment_leading on re-switch" "$count" "1"
}

# --- toml_store (atomic write to disk) ---

test_toml_store_round_trips_with_trailing_newline() {
    local tmp content; tmp=$(mktemp)
    content=$'[code]\nlang = \'rust\''
    toml_store "$tmp" "$content"
    assert_succeeds "toml_store writes content with a single trailing newline" \
        diff <(printf '%s\n' "$content") "$tmp"
    rm -f "$tmp"
}

test_toml_store_leaves_no_temp_file_behind() {
    local dir strays; dir=$(mktemp -d)
    toml_store "$dir/leetcode.toml" $'[code]\nlang = \'c\''
    strays=$(find "$dir" -name 'leetcode.toml.*' | wc -l)
    assert_eq "toml_store cleans up its temp sibling (atomic rename)" "$strays" "0"
    rm -rf "$dir"
}

# --- toml_load (read from disk) ---

test_toml_load_returns_file_content() {
    local tmp out; tmp=$(mktemp)
    printf '%s\n' $'[code]\nlang = \'go\'' > "$tmp"
    out=$(toml_load "$tmp")
    assert_eq "toml_load returns the file content" "$out" $'[code]\nlang = \'go\''
    rm -f "$tmp"
}

test_toml_load_fails_on_missing_file() {
    local dir; dir=$(mktemp -d)
    assert_fails "toml_load fails on a missing file" toml_load "$dir/nope.toml"
    rm -rf "$dir"
}

# --- toml_set_keys (read-modify-write multiple keys atomically) ---

test_toml_set_keys_sets_a_single_key_through_disk() {
    local tmp; tmp=$(mktemp)
    printf '%s\n' $'[cookies]\nsession = \'OLD\'' > "$tmp"
    toml_set_keys "$tmp" session NEWVAL
    assert_eq "toml_set_keys writes one key back to disk" \
        "$(toml_get "$(cat "$tmp")" session)" "NEWVAL"
    rm -f "$tmp"
}

test_toml_set_keys_sets_multiple_keys_in_one_call() {
    local tmp content; tmp=$(mktemp)
    printf '%s\n' $'[cookies]\nsession = \'OLDS\'\ncsrf = \'OLDC\'\nsite = \'leetcode.com\'' > "$tmp"
    toml_set_keys "$tmp" session NEWS csrf NEWC site leetcode.cn
    content=$(cat "$tmp")
    assert_eq "toml_set_keys sets session" "$(toml_get "$content" session)" "NEWS"
    assert_eq "toml_set_keys sets csrf" "$(toml_get "$content" csrf)" "NEWC"
    assert_eq "toml_set_keys sets site" "$(toml_get "$content" site)" "leetcode.cn"
    rm -f "$tmp"
}

test_toml_set_keys_skips_empty_values() {
    local tmp content; tmp=$(mktemp)
    printf '%s\n' $'[cookies]\nsession = \'OLDS\'\ncsrf = \'KEEPC\'' > "$tmp"
    toml_set_keys "$tmp" session NEWS csrf ""
    content=$(cat "$tmp")
    assert_eq "toml_set_keys refreshes session" "$(toml_get "$content" session)" "NEWS"
    assert_eq "toml_set_keys skips empty value (no clobber)" "$(toml_get "$content" csrf)" "KEEPC"
    rm -f "$tmp"
}

# --- run ---

test_toml_get_extracts_single_quoted_value
test_toml_get_extracts_double_quoted_value
test_toml_get_tolerates_indentation_and_loose_spacing
test_toml_get_empty_value_returns_empty
test_toml_get_missing_key_returns_empty
test_toml_get_reads_only_the_named_key
test_toml_get_returns_first_when_key_repeats
test_toml_has_true_for_nonempty_value
test_toml_has_false_for_empty_value
test_toml_has_false_for_missing_key
test_toml_has_true_for_double_quoted_value
test_toml_has_true_for_indented_key
test_toml_set_replaces_single_quoted_value
test_toml_set_preserves_quote_style
test_toml_set_only_touches_named_key
test_toml_set_tolerates_indentation
test_toml_set_handles_jwt_with_dots_and_dashes
test_toml_set_absent_key_unchanged
test_toml_path_defaults_to_home_leetcode
test_toml_path_honors_env_override
test_apply_lang_replaces_lang_line
test_apply_lang_replaces_inject_before
test_apply_lang_adds_comment_leading_if_missing
test_apply_lang_replaces_existing_comment_leading
test_apply_lang_preserves_other_lines
test_apply_lang_no_duplicate_comment_leading_on_reswitch
test_toml_store_round_trips_with_trailing_newline
test_toml_store_leaves_no_temp_file_behind
test_toml_load_returns_file_content
test_toml_load_fails_on_missing_file
test_toml_set_keys_sets_a_single_key_through_disk
test_toml_set_keys_sets_multiple_keys_in_one_call
test_toml_set_keys_skips_empty_values

finish
