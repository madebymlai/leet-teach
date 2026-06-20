# Leet-Teach Context

## Domain Language

- **leet-toml** — `scripts/leet-toml.sh`, the single reader/writer for `~/.leetcode/leetcode.toml` (the single source of truth). Two layers. Pure string helpers (take content, hand it back): `toml_get <content> <key>` (first quoted value, or empty), `toml_has <content> <key>` (present and non-empty), `toml_set <content> <key> <value>` (replace a key's value, preserving quote style). On-disk I/O seam (owns the read/write so no caller hand-rolls a `cat`/`printf` dance): `toml_load <path>` (content, or non-zero if missing), `toml_store <path> <content>` (atomic write via same-dir temp file + `mv`, so a crash can't truncate the file that holds the only copy of the session cookie), and `toml_set_keys <path> <key> <value>...` (read-modify-write several keys in one atomic store, skipping empty values so a missing token never clobbers a stored one — the "don't clobber" rule lives here, not in every caller). Every script sources it instead of hand-rolling a sed/grep regex.
- **cookie sync** — `scripts/leet-cookies.sh`. LeetCode sessions go *stale* (not empty) every couple of weeks; `cookies_sync` reads the live `LEETCODE_SESSION` + `csrftoken` out of any Firefox-family browser (Firefox/LibreWolf/Floorp/Zen/Waterfox/Mullvad) — their `moz_cookies` sqlite is unencrypted, so stdlib `sqlite3` reads it with no `browser_cookie3`/Chrome-decryption dependency — and writes them back in one atomic `toml_set_keys`. It scans every profile (`leet_cookie_roots`) and takes the freshest. Exposed as `leet sync`. `LEET_COOKIE_DBS` overrides discovery (also the test seam).
- **auth-failure retry** — the stale-cookie recovery path. `is_auth_failure` (pure, tested) recognises leetcode-cli's `CookieError`/`ChromeNotLogin` output; `leet test`/`leet submit` run the command and, on that signal, re-sync from the browser and retry once. The MCP launcher can't retry mid-session, so it instead syncs the cookie on startup (opt out with `LEET_MCP_NO_SYNC=1`).
- **edit pane** — The tmux pane `scripts/leet` opens for the helix editor (one per session, tracked in the `@leet_edit_pane` option).
- **edit-pane plan** — A pure mapping from observed pane state to an ordered list of *steps*. `plan_edit` (reuse-or-create + quit-helix-vs-interrupt) and `plan_close` (kill + clear) decide *what* to do; the `apply_step` interpreter is the only code that knows the literal tmux commands (the *how*). The decision is the test surface; tmux stays untested.
- **setup step registry** — `SETUP_STEPS` in `scripts/setup.sh`, one ordered `"label:function"` list that is the single source of truth for which install/configure steps run and in what order (no parallel array + `case` to drift). The `run_steps <out> <entry...>` orchestrator dispatches each function by name, never aborts on a failed step, and collects the failed labels. The orchestrator is the test surface (exercised with fake steps); the install/configure steps themselves stay untested.
- **MCP assistant registry** — `MCP_ASSISTANTS` in `scripts/leet-mcp.sh`, one `"name:kind:live_subpath:template"` row per assistant we register the leetcode MCP server for — the single source of truth for *which* assistants exist and *where* their configs live (no parallel lists in `configure_mcp` and `mcp_emit_templates` to drift). Both consumers iterate it; `mcp_write <kind> <path> <name> <cmd>` dispatches the write by `kind` (`json` → `mcp_write_json`, whose `SHAPES` still owns each JSON entry's shape keyed by name; `toml` → `mcp_write_codex`, the idempotent live merge into `.codex/config.toml`). The codex *template* is rendered separately (`mcp_emit_codex_template`): a human-facing doc file under `mcp-configs/`, intentionally distinct from the live merge. `mcp_write` is the tested seam; `configure_mcp` stays thin registry iteration. Adding an assistant is one registry row (plus a `SHAPES` entry for a new JSON shape).
- **leetcode-cli** — The clearloop Rust CLI tool (`cargo install leetcode-cli`), not the stale skygragon Node.js one
- **leetcode-mcp-server** — The jinzcdev MCP server (`@jinzcdev/leetcode-mcp-server`), gives AI tools direct LeetCode API access
- **helix** — Terminal modal editor (`hx` command), configured as default editor for leetcode-cli
- **MCP** — Model Context Protocol, how AI assistants (Claude/Codex/OpenCode) access LeetCode tools
- **DSA** — Data Structures & Algorithms
- **zone of proximal development** — Problems slightly above current ability, where learning happens best
- **spaced repetition** — Revisiting problems at increasing intervals for long-term retention

## Architecture

```
User → helix (edit code) → files on disk
User → leetcode-cli (pick/test/submit) → LeetCode API
AI   → MCP server (search/run/submit) → LeetCode API
AI   → files on disk (read/write) → user's solution
```

## Key Paths

- LeetCode config: `~/.leetcode/leetcode.toml`
- LeetCode code: `~/.leetcode/code/`
- Helix config: `~/.config/helix/config.toml`
- Claude MCP: `~/.config/claude/claude_desktop_config.json`
- Codex MCP: `~/.codex/mcp.json`
- OpenCode MCP: `~/.config/opencode/config.json`

## Teaching Workflow

1. AI picks problem (via MCP or `leetcode pick`)
2. User reads description, codes in helix
3. AI reviews code, gives progressive hints
4. AI tests (MCP `run_code` or `leetcode test`)
5. AI submits (MCP `submit_solution` or `leetcode exec`)
6. AI analyzes complexity, suggests next problem