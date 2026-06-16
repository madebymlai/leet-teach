# Leet-Teach Context

## Domain Language

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