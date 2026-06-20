#!/usr/bin/env bash
# leet-config.sh — the "managed config block" seam: write or append a leet-teach-owned
# block into a config file exactly once, idempotently, backing up any pre-existing file.
#
# Two shapes, one backup policy:
#   write_managed_block   leet-teach owns the whole file (helix config, leetcode.toml):
#                         skip if already marked, else back up and overwrite atomically.
#   append_managed_block  contribute a snippet to the user's file (tmux.conf):
#                         skip if the sentinel is already present, else append.
#   backup_once           the single backup policy: copy to .bak once, never clobbering
#                         the pristine original. mcp_backup_once delegates here.
#
# Each block's bytes live in a caller-supplied render function (emits content on stdout),
# so the configure_* steps in setup.sh keep only their content; the marker check, backup,
# and write concentrate here. Silent (returns 0=written, 1=skipped); callers own messaging.
# Pure file I/O, no dependencies. Sourced by setup.sh and leet-mcp.sh; covered by
# leet-config_test.sh.

# backup_once <path> — copy <path> to <path>.bak: skip if <path> is absent, and never
# overwrite an existing .bak (so re-runs can't clobber the pristine copy).
backup_once() {
    [ -f "$1" ] || return 0
    [ -f "$1.bak" ] && return 0
    cp "$1" "$1.bak"
}

# write_managed_block <path> <marker> <render_fn> — leet-teach owns the whole file.
# <render_fn> emits the file body (which must contain <marker>) on stdout. Skips and
# returns 1 when <path> already contains <marker> (leaving it untouched); otherwise
# writes the body and returns 0.
write_managed_block() {
    local path="$1" marker="$2" render="$3" content
    grep -qF "$marker" "$path" 2>/dev/null && return 1
    content=$("$render")
    backup_once "$path"
    printf '%s\n' "$content" > "$path"
}

# append_managed_block <path> <sentinel> <render_fn> — contribute a snippet to the
# user's file. <render_fn> emits the snippet (which must contain <sentinel>) on stdout.
# Skips and returns 1 when <path> already contains <sentinel>; otherwise appends the
# snippet (creating <path> if absent) and returns 0.
append_managed_block() {
    local path="$1" sentinel="$2" render="$3"
    grep -qF "$sentinel" "$path" 2>/dev/null && return 1
    "$render" >> "$path"
}
