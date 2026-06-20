# Leet-Teach Context

## Domain Language

- **leet-toml** — `scripts/leet-toml.sh`, the single reader for `~/.leetcode/leetcode.toml` (the single source of truth). Exposes `toml_get <content> <key>` (first quoted value, or empty) and `toml_has <content> <key>` (present and non-empty). Every script sources it instead of hand-rolling a sed/grep regex.
- **edit pane** — The tmux pane `scripts/leet` opens for the helix editor (one per session, tracked in the `@leet_edit_pane` option).
- **edit-pane plan** — A pure mapping from observed pane state to an ordered list of *steps*. `plan_edit` (reuse-or-create + quit-helix-vs-interrupt) and `plan_close` (kill + clear) decide *what* to do; the `apply_step` interpreter is the only code that knows the literal tmux commands (the *how*). The decision is the test surface; tmux stays untested.
- **setup step registry** — `SETUP_STEPS` in `scripts/setup.sh`, one ordered `"label:function"` list that is the single source of truth for which install/configure steps run and in what order (no parallel array + `case` to drift). The `run_steps <out> <entry...>` orchestrator dispatches each function by name, never aborts on a failed step, and collects the failed labels. The orchestrator is the test surface (exercised with fake steps); the install/configure steps themselves stay untested.
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