#!/usr/bin/env bash
# leet-mcp.sh — single source of truth for MCP "leetcode" server registration.
#
# The set of assistants lives once in the MCP_ASSISTANTS registry; both consumers
# (configure_mcp's live write and mcp_emit_templates' committed templates) iterate it,
# and mcp_write dispatches by kind. Each entry's *shape* is declared exactly once too
# (the SHAPES registry for JSON assistants; mcp_codex_table for codex). Live writes and
# templates render from these same cores, so the two can never drift. Sourced by
# setup.sh; the registry and pure cores are covered by leet-mcp_test.sh.

LEET_MCP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEET_MCP_CONFIGS_DIR="$(cd "$LEET_MCP_DIR/.." && pwd)/mcp-configs"
# shellcheck source=leet-config.sh
source "$LEET_MCP_DIR/leet-config.sh"   # backup_once (the single backup policy)

# The launcher path recorded in the committed templates: the tilde (documentation)
# form, vs the absolute path the live writers record. The tilde is meant to stay
# literal here (it is documentation, not a path we resolve).
# shellcheck disable=SC2088
LEET_MCP_TEMPLATE_CMD='~/.local/bin/leetcode-mcp'

# MCP_ASSISTANTS — the single registry of assistants we register the leetcode MCP
# server for: one "name:kind:live_subpath:template" row each. Single source of truth
# (no parallel lists in configure_mcp and mcp_emit_templates to drift out of sync).
#   name         passed to the writers; for json it keys the JSON shape (SHAPES)
#   kind         json | toml — dispatches mcp_write to the right writer
#   live_subpath where configure_mcp writes, relative to the project dir
#   template     the committed mcp-configs/ file name the renderer emits
# shellcheck disable=SC2034  # consumed by setup.sh and mcp_emit_templates after sourcing
MCP_ASSISTANTS=(
    "claude:json:.mcp.json:claude-desktop.json"
    "opencode:json:opencode.json:opencode.json"
    "codex:toml:.codex/config.toml:codex.toml"
)

# Back up <path> to <path>.bak exactly once. Delegates to the single backup policy in
# leet-config.sh (backup_once) so every caller in the project shares one behaviour.
mcp_backup_once() {
    backup_once "$1"
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

# mcp_write <kind> <path> <name> <cmd> — dispatch one assistant's live registration
# write by kind: json → mcp_write_json (shape keyed by <name>), toml → mcp_write_codex.
# The decision lives here, tested directly; configure_mcp stays thin registry iteration.
mcp_write() {
    local kind="$1" path="$2" name="$3" cmd="$4"
    case "$kind" in
        json) mcp_write_json "$path" "$name" "$cmd" ;;
        toml) mcp_write_codex "$path" "$cmd" ;;
        *)    echo "mcp_write: unknown kind '$kind'" >&2; return 1 ;;
    esac
}

# mcp_emit_codex_template <path> <cmd> — render the standalone, documented codex
# template (a human-facing file under mcp-configs/). Distinct from mcp_write_codex,
# which merges the table into a live .codex/config.toml: this writes a fresh file
# with the documentation header, so the two codex outputs intentionally differ.
mcp_emit_codex_template() {
    local path="$1" cmd="$2"
    {
        printf '# Project-local: .codex/config.toml in your project root (trust the folder when codex prompts).\n'
        printf '# The launcher reads the session from ~/.leetcode/leetcode.toml at runtime.\n'
        printf '\n'
        mcp_codex_table "$cmd"
    } > "$path"
}

# Render the committed mcp-configs/ templates from the same cores as the live writers,
# using the tilde command. <dir> defaults to the repo's mcp-configs. Iterates the one
# MCP_ASSISTANTS registry; json templates go through mcp_write_json (identical to the
# live write), the toml template through mcp_emit_codex_template. Because templates are
# rendered (not hand-written), leet-mcp_test.sh asserts committed == rendered.
mcp_emit_templates() {
    local dir="${1:-$LEET_MCP_CONFIGS_DIR}" tilde="$LEET_MCP_TEMPLATE_CMD"
    local row name kind tmpl
    for row in "${MCP_ASSISTANTS[@]}"; do
        IFS=: read -r name kind _ tmpl <<< "$row"
        rm -f "$dir/$tmpl"
        case "$kind" in
            json) mcp_write_json "$dir/$tmpl" "$name" "$tilde" ;;
            toml) mcp_emit_codex_template "$dir/$tmpl" "$tilde" ;;
        esac
    done
}

# Executed directly (dev only): regenerate the committed templates. Sourced (the
# normal case, from setup.sh and the tests): expose the functions, do nothing.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        --emit-templates) mcp_emit_templates ;;
        *) echo "usage: leet-mcp.sh --emit-templates" >&2; exit 2 ;;
    esac
fi
