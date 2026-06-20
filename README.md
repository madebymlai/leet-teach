# Leet-Teach

LeetCode practice workspace with AI-assisted coaching. Uses helix editor, leetcode-cli, and MCP server (for Claude/Codex/OpenCode) with the mattpocock teach skill + a custom leetcode coaching skill.

## Quick Start

```bash
cd leet-teach
chmod +x scripts/setup.sh
./scripts/setup.sh
```

This installs and configures:
- **helix** — modal editor with LSP support
- **leetcode-cli** (clearloop) — problem scaffolding, testing, submission
- **leetcode-mcp-server** — AI tools for Claude/Codex/OpenCode (project-local)
- **teach skill** — mattpocock's teaching framework (project-local)
- **leetcode skill** — custom DSA coaching skill

> **MCP is configured project-local.** `setup.sh` writes `.mcp.json`, `opencode.json`,
> and `.codex/config.toml` *inside this folder* — the leetcode MCP server is only active
> for assistants launched from here, never registered globally. Run `claude` / `opencode` /
> `codex` from the project root (and trust the folder when Codex prompts). These generated
> files are git-ignored; `mcp-configs/` holds committed shape references.

## After Setup

1. Log into **leetcode.com in your browser**, then sync the cookie:
   ```bash
   leet sync
   ```
   `leet sync` reads the live `LEETCODE_SESSION` + `csrftoken` straight out of any
   Firefox-family browser (Firefox, LibreWolf, Floorp, Zen, Waterfox, Mullvad, …) —
   Firefox stores cookies unencrypted, so no `browser_cookie3`/Chrome-decryption hassle.
   It scans every profile and picks whichever holds a live LeetCode session.

   The cookie lands in `~/.leetcode/leetcode.toml` (the single source of truth); both
   `leetcode-cli` and the MCP server read from there — no need to edit MCP configs.

   > **Persistent login, honestly.** A LeetCode session can't be made immortal — it
   > goes *stale* every couple of weeks. But as long as you stay logged in in your
   > browser, you never deal with it: `leet test`/`leet submit` detect a stale-cookie
   > rejection and **auto re-sync from the browser and retry**, and the MCP launcher
   > refreshes the cookie each time your assistant starts. Run `leet sync` yourself any
   > time you want to force a refresh. Reusing the browser's own cookie (rather than a
   > fresh CLI login) also means the CLI and browser share one session instead of
   > evicting each other.

2. Pick a problem and start:
   ```bash
   leet pick two-sum    # scaffold problem + open in helix
   leet test 1          # test solution
   leet submit 1        # submit solution
   ```

## Changing the Problem Language

```bash
leet lang              # interactive picker
leet lang rust         # set directly
```

Supported languages: `python`, `rust`, `cpp`, `c`, `java`, `go`. The language is stored in `~/.leetcode/leetcode.toml` and uses helix's naming convention so LSP and leetcode-cli stay consistent. Per-language imports (`inject_before`) and comment style (`comment_leading`) are set automatically.

## Workflow with AI Coach

1. Ask your AI (Claude/Codex/OpenCode) to pick a problem via MCP tools
2. `leetcode pick <id>` scaffolds the code
3. `leetcode edit <id>` opens in helix
4. AI reads your code, gives hints, analyzes complexity
5. `leetcode test <id>` or MCP `run_code` to test
6. `leetcode exec <id>` or MCP `submit_solution` to submit

## Skills

### teach (mattpocock)

Project-local teaching framework. Creates:
- `MISSION.md` — your learning goals
- `learning-records/` — tracked insights
- `lessons/` — interactive HTML lessons
- `reference/` — cheat sheets and glossaries
- `RESOURCES.md` — curated learning sources

### leetcode (custom)

DSA coaching skill. Provides:
- Problem selection based on weak areas
- Progressive hint system (5 levels)
- Complexity analysis after solving
- Pattern recognition across problems
- Spaced repetition suggestions

## Project Structure

```
leet-teach/
├── scripts/                  # Bash workspace tooling (+ *_test.sh unit tests)
│   ├── setup.sh              #   one-command, idempotent setup
│   ├── leet                  #   workflow launcher (pick/edit/test/submit in tmux)
│   ├── leetcode-mcp          #   leetcode MCP server launcher (syncs cookie on start)
│   ├── leet-toml.sh          #   single reader/writer for ~/.leetcode/leetcode.toml
│   ├── leet-cookies.sh       #   pull live session from any Firefox-family browser
│   ├── leet-languages.sh     #   supported-language registry
│   └── leet-mcp.sh           #   project-local MCP registration (single-sourced shapes)
├── mcp-configs/              # Committed MCP shape references (rendered, drift-tested)
│   ├── claude-desktop.json   #   mcpServers shape → project .mcp.json
│   ├── codex.toml            #   [mcp_servers] shape → project .codex/config.toml
│   └── opencode.json         #   mcp shape → project opencode.json
├── skills/
│   └── leetcode/             # Custom leetcode coaching skill (SKILL.md, REFERENCE.md)
├── docs/                     # Design docs / ADRs
├── assets/                   # Static assets
├── lessons/                  # Teaching lessons (teach output; created empty by setup)
├── learning-records/         # Learning progress (teach output)
├── reference/                # Reference docs (teach output)
├── MISSION.md                # Learning mission (committed; teach-managed)
├── RESOURCES.md              # Resource list (committed; teach-managed)
└── GLOSSARY.md               # Term glossary (committed; teach-managed)
```

> Generated at setup but git-ignored, so not shown above: `.mcp.json`,
> `opencode.json`, `.codex/config.toml` (project-local MCP configs).

## Customization

### Change default language
```bash
leet lang rust         # or: leet lang for a picker
```

### Change editor
```toml
[code]
editor = 'hx'  # or vim, nvim, code, etc.
```

### LeetCode China
Change site in both leetcode.toml and MCP configs:
```toml
[cookies]
site = 'leetcode.cn'
```
```json
"LEETCODE_SITE": "cn"
```