#!/usr/bin/env bash
# leet-mcp.sh — single source of truth for MCP "leetcode" server registration.
#
# Each assistant's entry shape is declared exactly once (the SHAPES registry for
# JSON assistants; mcp_codex_table for codex). Both the live config write and the
# committed mcp-configs/ templates are rendered from these same cores, so the two
# can never drift. Sourced by setup.sh; pure cores are covered by leet-mcp_test.sh.

LEET_MCP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEET_MCP_CONFIGS_DIR="$(cd "$LEET_MCP_DIR/.." && pwd)/mcp-configs"

# The launcher path recorded in the committed templates: the tilde (documentation)
# form, vs the absolute path the live writers record. The tilde is meant to stay
# literal here (it is documentation, not a path we resolve).
# shellcheck disable=SC2088
LEET_MCP_TEMPLATE_CMD='~/.local/bin/leetcode-mcp'

# Back up <path> to <path>.bak exactly once: skip if the file is absent, and
# never overwrite an existing .bak (so re-runs can't clobber the pristine copy).
mcp_backup_once() {
    local path="$1"
    [ -f "$path" ] || return 0
    [ -f "$path.bak" ] && return 0
    cp "$path" "$path.bak"
}

# Merge the leetcode entry for <assistant> into the JSON config at <path>,
# preserving any other servers. <cmd> is the launcher command to record.
mcp_write_json() {
    local path="$1" assistant="$2" cmd="$3"
    LEET_MCP_PATH="$path" LEET_MCP_ASSISTANT="$assistant" LEET_MCP_CMD="$cmd" python3 << 'PY'
import json, os, sys
path = os.environ['LEET_MCP_PATH']
assistant = os.environ['LEET_MCP_ASSISTANT']
cmd = os.environ['LEET_MCP_CMD']

SHAPES = {
    "claude":   ("mcpServers", lambda c: {"type": "stdio", "command": c}),
    "opencode": ("mcp",        lambda c: {"type": "local", "enabled": True, "command": [c]}),
}
top, build = SHAPES[assistant]

cfg = {}
if os.path.exists(path):
    with open(path) as f:
        try:
            cfg = json.load(f)
        except json.JSONDecodeError:
            sys.stderr.write(
                "%s is not valid JSON; fix or remove it, then re-run.\n" % path)
            sys.exit(1)
cfg.setdefault(top, {})["leetcode"] = build(cmd)
with open(path, 'w') as f:
    json.dump(cfg, f, indent=2)
PY
}

# The single-sourced codex TOML table body (no surrounding comment — callers own
# their own comment). <cmd> is the launcher command to record.
mcp_codex_table() {
    local cmd="$1"
    printf '[mcp_servers.leetcode]\ncommand = "%s"\n' "$cmd"
}

# Merge the leetcode table into the codex TOML config at <path>: drop any prior
# [mcp_servers.leetcode] table (and its sub-tables), then append a fresh one.
# Idempotent. Anchors are exact so a sibling like [mcp_servers.leetcodex] is safe.
mcp_write_codex() {
    local path="$1" cmd="$2"
    if [ -f "$path" ]; then
        # Strip our managed block: the marker comment, the leetcode table and any
        # sub-tables. Buffer kept lines and emit up to the last non-blank one so
        # trailing blanks never accumulate across runs (keeps it byte-idempotent).
        awk '
            /^# leet-teach: leetcode MCP server/ { next }
            /^\[mcp_servers\.leetcode\]/ { skip=1; next }
            /^\[mcp_servers\.leetcode\./ { skip=1; next }
            skip && /^\[/ { skip=0 }
            skip { next }
            { lines[++n] = $0; if ($0 ~ /[^[:space:]]/) last = n }
            END { for (i = 1; i <= last; i++) print lines[i] }
        ' "$path" > "$path.tmp" && mv "$path.tmp" "$path"
    fi
    {
        printf '\n# leet-teach: leetcode MCP server (reads session from ~/.leetcode/leetcode.toml)\n'
        mcp_codex_table "$cmd"
    } >> "$path"
}

# Render the three committed mcp-configs/ templates from the same cores as the
# live writers, using the tilde command. <dir> defaults to the repo's mcp-configs.
# Because templates are rendered (not hand-written), leet-mcp_test.sh can assert
# committed == rendered and catch any drift.
mcp_emit_templates() {
    local dir="${1:-$LEET_MCP_CONFIGS_DIR}"
    local tilde="$LEET_MCP_TEMPLATE_CMD"
    rm -f "$dir/claude-desktop.json"
    mcp_write_json "$dir/claude-desktop.json" claude "$tilde"
    rm -f "$dir/opencode.json"
    mcp_write_json "$dir/opencode.json" opencode "$tilde"
    {
        printf '# Project-local: .codex/config.toml in your project root (trust the folder when codex prompts).\n'
        printf '# The launcher reads the session from ~/.leetcode/leetcode.toml at runtime.\n'
        printf '\n'
        mcp_codex_table "$tilde"
    } > "$dir/codex.toml"
}

# Executed directly (dev only): regenerate the committed templates. Sourced (the
# normal case, from setup.sh and the tests): expose the functions, do nothing.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        --emit-templates) mcp_emit_templates ;;
        *) echo "usage: leet-mcp.sh --emit-templates" >&2; exit 2 ;;
    esac
fi
