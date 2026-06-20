#!/usr/bin/env bash
# Unit tests for scripts/leet pure helpers.
# Arrange-Act-Assert, one behavior per test, no logic in test bodies.
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=leet
source "$TESTS_DIR/leet"
# shellcheck source=test-support.sh
source "$TESTS_DIR/test-support.sh"

# --- parse_problem_id ---

test_parse_problem_id_extracts_first_bracketed_id() {
    local output id
    output='[1] Two Sum    Easy
[2] Add Two Numbers    Medium'
    id=$(parse_problem_id "$output")
    assert_eq "parse_problem_id extracts first [N]" "$id" "1"
}

test_parse_problem_id_fails_without_bracketed_id() {
    local output
    output='Picked! Two Sum (Easy)'
    assert_fails "parse_problem_id fails without [N]" parse_problem_id "$output"
}

# Note: the session-cookie presence check (formerly session_is_set) now lives in
# scripts/leet-toml.sh as toml_has and is covered by leet-toml_test.sh.

# --- pick_args (pure: arg → leetcode pick arguments) ---

test_pick_args_numeric_passes_bare_id() {
    local out
    out=$(pick_args 1)
    assert_eq "pick_args numeric → bare id" "$out" "1"
}

test_pick_args_slug_uses_dash_n() {
    local out
    out=$(pick_args two-sum)
    assert_eq "pick_args slug → -n slug" "$out" $'-n\ntwo-sum'
}

# --- plan_edit (pure: pane state → ordered edit steps) ---

test_plan_edit_no_live_pane_creates() {
    local out
    out=$(plan_edit no "" 1)
    assert_eq "plan_edit no live pane → create" "$out" "create 1"
}

test_plan_edit_live_helix_quits_then_edits() {
    local out
    out=$(plan_edit yes hx 1)
    assert_eq "plan_edit live helix → quit-editor then edit" "$out" $'quit-editor\nedit 1'
}

test_plan_edit_live_other_interrupts_then_edits() {
    local out
    out=$(plan_edit yes bash 1)
    assert_eq "plan_edit live non-editor → interrupt then edit" "$out" $'interrupt\nedit 1'
}

# --- plan_close (pure: pane state → ordered teardown steps) ---

test_plan_close_live_pane_kills_then_unsets() {
    local out
    out=$(plan_close yes yes)
    assert_eq "plan_close live pane → kill then unset" "$out" $'kill\nunset'
}

test_plan_close_dead_but_stored_only_unsets() {
    local out
    out=$(plan_close no yes)
    assert_eq "plan_close dead but stored → unset only" "$out" "unset"
}

test_plan_close_no_stored_id_is_empty() {
    local out
    out=$(plan_close no no)
    assert_eq "plan_close no stored id → empty plan" "$out" ""
}

# --- plan_lang_change (pure: content + helix name → new content, or fail) ---

test_plan_lang_change_sets_the_chosen_language() {
    local content out
    content=$'[code]\nlang = \'python3\'\ninject_before = []\neditor = \'hx\''
    out=$(plan_lang_change "$content" rust)
    assert_eq "plan_lang_change sets lang" "$(toml_get "$out" lang)" "rust"
}

test_plan_lang_change_carries_comment_leading_for_the_language() {
    local content out
    content=$'[code]\nlang = \'python3\'\ncomment_leading = "#"\ninject_before = []'
    out=$(plan_lang_change "$content" cpp)
    assert_eq "plan_lang_change carries comment_leading" "$(toml_get "$out" comment_leading)" "//"
}

test_plan_lang_change_rejects_unsupported_language() {
    local content
    content=$'[code]\nlang = \'python3\''
    assert_fails "plan_lang_change rejects unsupported" plan_lang_change "$content" kotlin
}

test_plan_lang_change_preserves_unrelated_lines() {
    local content out
    content=$'[code]\nlang = \'python3\'\ninject_before = []\neditor = \'hx\'\n[cookies]\nsession = \'abc\''
    out=$(plan_lang_change "$content" rust)
    assert_eq "plan_lang_change preserves editor" "$(toml_get "$out" editor)" "hx"
    assert_eq "plan_lang_change preserves session" "$(toml_get "$out" session)" "abc"
}

# --- do_lang (integration: real read→plan→write through the LEETCODE_TOML seam) ---

test_do_lang_writes_chosen_language_to_the_toml() {
    local tmp; tmp=$(mktemp)
    printf '%s\n' $'# leet-teach-config\n[code]\nlang = \'python3\'\ninject_before = []\ncomment_leading = "#"' > "$tmp"
    require_leetcode() { :; }                               # guard: never probe the real CLI
    LEETCODE_TOML="$tmp" do_lang rust >/dev/null
    assert_eq "do_lang writes chosen lang to the toml" "$(toml_get "$(cat "$tmp")" lang)" "rust"
    assert_eq "do_lang writes the language's comment_leading" "$(toml_get "$(cat "$tmp")" comment_leading)" "//"
    rm -f "$tmp"
}

# --- do_pick wiring (effect seam: collaborators stubbed) ---
# Verifies the pick→parse→edit thread without touching the real CLI or tmux.

test_do_pick_shapes_args_and_threads_id_to_pane_edit() {
    local argfile edited_id=""
    argfile=$(mktemp)
    require_leetcode() { :; }
    leetcode() { printf '[42] Two Sum    Easy\n'; }        # guard: never the real CLI
    # leet_pick_output runs inside $(...), so record args to a file, not a variable.
    leet_pick_output() { printf '%s' "$*" > "$argfile"; printf '[42] Two Sum    Easy\n'; }
    pane_edit() { edited_id="$1"; }
    do_pick two-sum >/dev/null
    assert_eq "do_pick shapes slug args via pick_args" "$(cat "$argfile")" "-n two-sum"
    assert_eq "do_pick threads parsed id into pane_edit" "$edited_id" "42"
    rm -f "$argfile"
}

# --- run ---

test_parse_problem_id_extracts_first_bracketed_id
test_parse_problem_id_fails_without_bracketed_id
test_pick_args_numeric_passes_bare_id
test_pick_args_slug_uses_dash_n
test_plan_edit_no_live_pane_creates
test_plan_edit_live_helix_quits_then_edits
test_plan_edit_live_other_interrupts_then_edits
test_plan_close_live_pane_kills_then_unsets
test_plan_close_dead_but_stored_only_unsets
test_plan_close_no_stored_id_is_empty
test_plan_lang_change_sets_the_chosen_language
test_plan_lang_change_carries_comment_leading_for_the_language
test_plan_lang_change_rejects_unsupported_language
test_plan_lang_change_preserves_unrelated_lines
test_do_lang_writes_chosen_language_to_the_toml
test_do_pick_shapes_args_and_threads_id_to_pane_edit

finish
