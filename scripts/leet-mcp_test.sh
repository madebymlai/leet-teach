#!/usr/bin/env bash
# Unit tests for scripts/leet-mcp.sh — MCP registration cores.
# Arrange-Act-Assert, one behavior per test, no logic in test bodies.
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=leet-mcp.sh
source "$TESTS_DIR/leet-mcp.sh"
# shellcheck source=test-support.sh
source "$TESTS_DIR/test-support.sh"

# Read a value out of a JSON file via a python expression over bound name `d`.
json_get() {
    python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(eval(sys.argv[2]))" "$1" "$2"
}

CMD="/home/u/.local/bin/leetcode-mcp"

# --- mcp_write_json: claude shape ---

test_claude_shape_into_empty() {
    local dir; dir=$(mktemp -d)
    mcp_write_json "$dir/claude.json" claude "$CMD"
    assert_eq "claude type" "$(json_get "$dir/claude.json" "d['mcpServers']['leetcode']['type']")" "stdio"
    assert_eq "claude command" "$(json_get "$dir/claude.json" "d['mcpServers']['leetcode']['command']")" "$CMD"
    rm -rf "$dir"
}

test_opencode_shape_into_empty() {
    local dir; dir=$(mktemp -d)
    mcp_write_json "$dir/opencode.json" opencode "$CMD"
    assert_eq "opencode type" "$(json_get "$dir/opencode.json" "d['mcp']['leetcode']['type']")" "local"
    assert_eq "opencode enabled" "$(json_get "$dir/opencode.json" "d['mcp']['leetcode']['enabled']")" "True"
    assert_eq "opencode command is array" "$(json_get "$dir/opencode.json" "d['mcp']['leetcode']['command'][0]")" "$CMD"
    rm -rf "$dir"
}

test_preserve_other_servers_and_keys() {
    local dir; dir=$(mktemp -d)
    cat > "$dir/claude.json" << 'SEED'
{
  "mcpServers": {
    "other": { "type": "stdio", "command": "/usr/bin/other" }
  },
  "theme": "dark"
}
SEED
    mcp_write_json "$dir/claude.json" claude "$CMD"
    assert_eq "sibling server survives" "$(json_get "$dir/claude.json" "d['mcpServers']['other']['command']")" "/usr/bin/other"
    assert_eq "sibling top-level key survives" "$(json_get "$dir/claude.json" "d['theme']")" "dark"
    assert_eq "leetcode added alongside" "$(json_get "$dir/claude.json" "d['mcpServers']['leetcode']['command']")" "$CMD"
    rm -rf "$dir"
}

test_json_idempotent_twice() {
    local dir; dir=$(mktemp -d)
    mcp_write_json "$dir/opencode.json" opencode "$CMD"
    cp "$dir/opencode.json" "$dir/first"
    mcp_write_json "$dir/opencode.json" opencode "$CMD"
    if cmp -s "$dir/first" "$dir/opencode.json"; then
        assert_eq "json write is idempotent" "identical" "identical"
    else
        assert_eq "json write is idempotent" "differs" "identical"
    fi
    rm -rf "$dir"
}

test_overwrite_stale_leetcode_field() {
    local dir; dir=$(mktemp -d)
    cat > "$dir/claude.json" << 'SEED'
{
  "mcpServers": {
    "leetcode": { "type": "stdio", "command": "/old", "args": ["--legacy"] }
  }
}
SEED
    mcp_write_json "$dir/claude.json" claude "$CMD"
    assert_eq "stale args dropped" "$(json_get "$dir/claude.json" "'args' in d['mcpServers']['leetcode']")" "False"
    assert_eq "command refreshed" "$(json_get "$dir/claude.json" "d['mcpServers']['leetcode']['command']")" "$CMD"
    rm -rf "$dir"
}

test_malformed_json_clean_fail() {
    local dir; dir=$(mktemp -d)
    printf '{ this is not json' > "$dir/claude.json"
    cp "$dir/claude.json" "$dir/orig"
    local err
    err=$(mcp_write_json "$dir/claude.json" claude "$CMD" 2>&1 1>/dev/null) || true
    assert_fails "malformed json exits non-zero" mcp_write_json "$dir/claude.json" claude "$CMD"
    case "$err" in *"not valid JSON"*) assert_eq "message names the problem" "ok" "ok" ;;
                   *) assert_eq "message names the problem" "$err" "contains 'not valid JSON'" ;; esac
    case "$err" in *Traceback*) assert_eq "no python traceback" "traceback shown" "no traceback" ;;
                   *) assert_eq "no python traceback" "ok" "ok" ;; esac
    if cmp -s "$dir/orig" "$dir/claude.json"; then assert_eq "file left unchanged" "same" "same"
    else assert_eq "file left unchanged" "clobbered" "same"; fi
    rm -rf "$dir"
}

# --- mcp_codex_table: TOML fragment (the single-sourced codex body) ---

test_codex_table_fragment_exact() {
    local expected
    expected=$(printf '[mcp_servers.leetcode]\ncommand = "%s"\n' "$CMD")
    assert_eq "codex table fragment" "$(mcp_codex_table "$CMD")" "$expected"
}

# --- mcp_write_codex: live TOML writer (delete-then-append, idempotent) ---

test_codex_idempotent_preserve_other() {
    local dir; dir=$(mktemp -d)
    cat > "$dir/config.toml" << 'SEED'
[mcp_servers.other]
command = "/usr/bin/other"

[mcp_servers.leetcode]
command = "/old/leetcode-mcp"
SEED
    mcp_write_codex "$dir/config.toml" "$CMD"
    cp "$dir/config.toml" "$dir/first"
    mcp_write_codex "$dir/config.toml" "$CMD"
    assert_eq "other server survives" "$(grep -c '^\[mcp_servers.other\]' "$dir/config.toml")" "1"
    assert_eq "leetcode table appears once" "$(grep -c '^\[mcp_servers.leetcode\]' "$dir/config.toml")" "1"
    assert_eq "new command recorded once" "$(grep -c "command = \"$CMD\"" "$dir/config.toml")" "1"
    if cmp -s "$dir/first" "$dir/config.toml"; then assert_eq "codex write idempotent" "same" "same"
    else assert_eq "codex write idempotent" "differs" "same"; fi
    rm -rf "$dir"
}

test_codex_prefix_safety() {
    local dir; dir=$(mktemp -d)
    cat > "$dir/config.toml" << 'SEED'
[mcp_servers.leetcodex]
command = "/usr/bin/leetcodex"
SEED
    mcp_write_codex "$dir/config.toml" "$CMD"
    assert_eq "leetcodex sibling survives" "$(grep -c '^\[mcp_servers.leetcodex\]' "$dir/config.toml")" "1"
    assert_eq "leetcodex command intact" "$(grep -c 'command = "/usr/bin/leetcodex"' "$dir/config.toml")" "1"
    assert_eq "our leetcode table added" "$(grep -c '^\[mcp_servers.leetcode\]' "$dir/config.toml")" "1"
    rm -rf "$dir"
}

# --- mcp_write: kind dispatch (json → mcp_write_json, toml → mcp_write_codex) ---

test_mcp_write_dispatches_json_to_claude_shape() {
    local dir; dir=$(mktemp -d)
    mcp_write json "$dir/claude.json" claude "$CMD"
    assert_eq "mcp_write json → claude command" \
        "$(json_get "$dir/claude.json" "d['mcpServers']['leetcode']['command']")" "$CMD"
    rm -rf "$dir"
}

test_mcp_write_dispatches_toml_to_codex_table() {
    local dir; dir=$(mktemp -d)
    mcp_write toml "$dir/config.toml" codex "$CMD"
    assert_eq "mcp_write toml → leetcode table present" \
        "$(grep -c '^\[mcp_servers.leetcode\]' "$dir/config.toml")" "1"
    assert_eq "mcp_write toml → command recorded" \
        "$(grep -c "command = \"$CMD\"" "$dir/config.toml")" "1"
    rm -rf "$dir"
}

test_mcp_write_rejects_unknown_kind() {
    local dir; dir=$(mktemp -d)
    assert_fails "mcp_write rejects an unknown kind" \
        mcp_write yaml "$dir/x" claude "$CMD"
    rm -rf "$dir"
}

# --- MCP_ASSISTANTS: the single registry both consumers iterate ---

test_registry_is_non_empty() {
    assert_succeeds "MCP_ASSISTANTS is non-empty" test "${#MCP_ASSISTANTS[@]}" -gt 0
}

test_registry_rows_well_formed() {
    local row name kind live tmpl bad=""
    for row in "${MCP_ASSISTANTS[@]}"; do
        IFS=: read -r name kind live tmpl <<< "$row"
        [ -n "$name" ] && [ -n "$kind" ] && [ -n "$live" ] && [ -n "$tmpl" ] || bad="$bad [$row:fields]"
        case "$kind" in json|toml) ;; *) bad="$bad [$row:kind]" ;; esac
    done
    assert_eq "every MCP_ASSISTANTS row is name:kind(json|toml):live:template" "$bad" ""
}

test_every_json_row_registers_through_mcp_write() {
    local dir row name kind live tmpl
    dir=$(mktemp -d)
    for row in "${MCP_ASSISTANTS[@]}"; do
        IFS=: read -r name kind live tmpl <<< "$row"
        [ "$kind" = json ] || continue
        mcp_write json "$dir/$name.json" "$name" "$CMD"
        assert_eq "json row '$name' registers a leetcode entry (name has a shape)" \
            "$(json_get "$dir/$name.json" "'leetcode' in d[list(d)[0]]")" "True"
    done
    rm -rf "$dir"
}

# --- drift guard: committed templates must equal the renderer output ---

test_templates_match_renderer() {
    local dir; dir=$(mktemp -d)
    mcp_emit_templates "$dir"
    local f
    for f in claude-desktop.json opencode.json codex.toml; do
        if cmp -s "$dir/$f" "$LEET_MCP_CONFIGS_DIR/$f"; then
            assert_eq "template $f matches renderer" "match" "match"
        else
            assert_eq "template $f matches renderer" "drift" "match"
        fi
    done
    rm -rf "$dir"
}

# --- mcp_backup_once: back up a config once, never clobber the pristine copy ---

test_backup_once_no_clobber() {
    local dir; dir=$(mktemp -d)
    printf 'ORIGINAL\n' > "$dir/cfg"
    mcp_backup_once "$dir/cfg"
    printf 'MODIFIED\n' > "$dir/cfg"
    mcp_backup_once "$dir/cfg"
    assert_eq "backup keeps the pristine original" "$(cat "$dir/cfg.bak")" "ORIGINAL"
    rm -rf "$dir"
}

test_backup_skips_missing_file() {
    local dir; dir=$(mktemp -d)
    mcp_backup_once "$dir/absent"
    if [ -e "$dir/absent.bak" ]; then assert_eq "no backup for missing file" "created" "none"
    else assert_eq "no backup for missing file" "none" "none"; fi
    rm -rf "$dir"
}

# --- run ---

test_claude_shape_into_empty
test_opencode_shape_into_empty
test_preserve_other_servers_and_keys
test_json_idempotent_twice
test_overwrite_stale_leetcode_field
test_malformed_json_clean_fail
test_codex_table_fragment_exact
test_codex_idempotent_preserve_other
test_codex_prefix_safety
test_mcp_write_dispatches_json_to_claude_shape
test_mcp_write_dispatches_toml_to_codex_table
test_mcp_write_rejects_unknown_kind
test_registry_is_non_empty
test_registry_rows_well_formed
test_every_json_row_registers_through_mcp_write
test_templates_match_renderer
test_backup_once_no_clobber
test_backup_skips_missing_file

finish
