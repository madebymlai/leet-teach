#!/usr/bin/env bash
# Unit tests for scripts/leet-config.sh — the managed config block seam.
# Arrange-Act-Assert, one behavior per test, no logic in test bodies. The configure_*
# steps in setup.sh stay untested (effectful); this seam is where the policy is tested.
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=leet-config.sh
source "$TESTS_DIR/leet-config.sh"
# shellcheck source=test-support.sh
source "$TESTS_DIR/test-support.sh"

# --- backup_once: one backup policy, never clobber the pristine copy ---

test_backup_once_copies_existing_file() {
    local dir; dir=$(mktemp -d)
    printf 'ORIGINAL\n' > "$dir/cfg"
    backup_once "$dir/cfg"
    assert_eq "backup_once copies the file to .bak" "$(cat "$dir/cfg.bak")" "ORIGINAL"
    rm -rf "$dir"
}

test_backup_once_never_clobbers_existing_bak() {
    local dir; dir=$(mktemp -d)
    printf 'ORIGINAL\n' > "$dir/cfg"
    backup_once "$dir/cfg"
    printf 'MODIFIED\n' > "$dir/cfg"
    backup_once "$dir/cfg"
    assert_eq "backup_once keeps the pristine original across re-runs" "$(cat "$dir/cfg.bak")" "ORIGINAL"
    rm -rf "$dir"
}

test_backup_once_skips_missing_file() {
    local dir; dir=$(mktemp -d)
    backup_once "$dir/absent"
    assert_eq "backup_once makes no .bak for a missing file" \
        "$([ -e "$dir/absent.bak" ] && echo created || echo none)" "none"
    rm -rf "$dir"
}

# --- write_managed_block: own-the-file (marker check → backup → overwrite) ---

# A render fixture: emits a small marked file body on stdout (no I/O of its own).
_render_fixture() { printf '%s\n' "# leet-teach-config" "key = 1"; }

test_write_managed_block_writes_to_absent_file() {
    local dir; dir=$(mktemp -d)
    write_managed_block "$dir/cfg" "# leet-teach-config" _render_fixture
    assert_eq "write_managed_block writes the rendered content" \
        "$(cat "$dir/cfg")" "$(_render_fixture)"
    rm -rf "$dir"
}

test_write_managed_block_skips_when_already_marked() {
    local dir; dir=$(mktemp -d)
    printf '%s\n' "# leet-teach-config" "existing = true" > "$dir/cfg"
    assert_fails "write_managed_block reports a skip when already marked" \
        write_managed_block "$dir/cfg" "# leet-teach-config" _render_fixture
    assert_eq "write_managed_block leaves a managed file untouched" \
        "$(cat "$dir/cfg")" "$(printf '%s\n' '# leet-teach-config' 'existing = true')"
    rm -rf "$dir"
}

test_write_managed_block_backs_up_preexisting_unmarked_file() {
    local dir; dir=$(mktemp -d)
    printf 'USER CONTENT\n' > "$dir/cfg"
    write_managed_block "$dir/cfg" "# leet-teach-config" _render_fixture
    assert_eq "write_managed_block backs up the pre-existing file" \
        "$(cat "$dir/cfg.bak")" "USER CONTENT"
    assert_eq "write_managed_block overwrites with the rendered body" \
        "$(cat "$dir/cfg")" "$(_render_fixture)"
    rm -rf "$dir"
}

# --- append_managed_block: snippet into the user's file (sentinel check → append) ---

# A render fixture for a snippet: a leading blank line, a comment, and a setting.
_render_snippet() { printf '%s\n' "" "# leet-teach: snippet" "set -g mouse on"; }

test_append_managed_block_appends_when_sentinel_absent() {
    local dir; dir=$(mktemp -d)
    append_managed_block "$dir/conf" "set -g mouse on" _render_snippet
    assert_eq "append_managed_block writes the snippet to a new file" \
        "$(cat "$dir/conf")" "$(_render_snippet)"
    rm -rf "$dir"
}

test_append_managed_block_skips_when_sentinel_present() {
    local dir; dir=$(mktemp -d)
    printf '%s\n' "# user tmux" "set -g mouse on" > "$dir/conf"
    assert_fails "append_managed_block reports a skip when the sentinel is present" \
        append_managed_block "$dir/conf" "set -g mouse on" _render_snippet
    assert_eq "append_managed_block leaves a file with the sentinel unchanged" \
        "$(cat "$dir/conf")" "$(printf '%s\n' '# user tmux' 'set -g mouse on')"
    rm -rf "$dir"
}

test_append_managed_block_preserves_existing_user_content() {
    local dir; dir=$(mktemp -d)
    printf '%s\n' "# my tmux config" "set -g history-limit 50000" > "$dir/conf"
    append_managed_block "$dir/conf" "set -g mouse on" _render_snippet
    assert_eq "append_managed_block keeps the user's prior content" \
        "$(head -2 "$dir/conf")" "$(printf '%s\n' '# my tmux config' 'set -g history-limit 50000')"
    assert_eq "append_managed_block adds the snippet after it" \
        "$(grep -c 'set -g mouse on' "$dir/conf")" "1"
    rm -rf "$dir"
}

# --- run ---

test_backup_once_copies_existing_file
test_backup_once_never_clobbers_existing_bak
test_backup_once_skips_missing_file
test_write_managed_block_writes_to_absent_file
test_write_managed_block_skips_when_already_marked
test_write_managed_block_backs_up_preexisting_unmarked_file
test_append_managed_block_appends_when_sentinel_absent
test_append_managed_block_skips_when_sentinel_present
test_append_managed_block_preserves_existing_user_content

finish
