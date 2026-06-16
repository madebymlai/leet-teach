# Leet-Teach

LeetCode practice workspace with AI-assisted coaching. Uses helix editor, leetcode-cli, and MCP server (for Claude/Codex/OpenCode) with the mattpocock teach skill + a custom leetcode coaching skill.

## Quick Start

```bash
cd ~/git/leet-teach
chmod +x scripts/setup.sh
./scripts/setup.sh
```

This installs and configures:
- **helix** — modal editor with LSP support
- **leetcode-cli** (clearloop) — problem scaffolding, testing, submission
- **leetcode-mcp-server** — AI tools for Claude/Codex/OpenCode
- **teach skill** — mattpocock's teaching framework (project-local)
- **leetcode skill** — custom DSA coaching skill

## After Setup

1. Set your LeetCode cookies:
   ```bash
   leetcode data -c
   ```
   Or manually add `LEETCODE_SESSION` to the MCP config files.

2. Set your LeetCode session in MCP configs:
   - `~/.config/claude/claude_desktop_config.json`
   - `~/.codex/mcp.json`
   - `~/.config/opencode/config.json`

3. Pick a problem and start:
   ```bash
   leetcode pick two-sum    # scaffold problem
   leetcode edit 1          # open in helix
   leetcode test 1          # test solution
   leetcode exec 1          # submit solution
   ```

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
├── scripts/
│   └── setup.sh              # One-command setup
├── mcp-configs/              # MCP config templates
│   ├── claude-desktop.json
│   ├── codex.json
│   └── opencode.json
├── .skills/                  # Downloaded skills
│   └── teach/                # mattpocock teach skill
├── skill.yaml                # Leetcode skill definition
├── SKILL.md                  # Leetcode skill instructions
├── lessons/                  # Teaching lessons (generated)
├── learning-records/         # Learning progress (generated)
├── reference/                # Reference docs (generated)
├── MISSION.md                # Learning mission (generated)
├── RESOURCES.md              # Resource list (generated)
├── NOTES.md                  # Scratch notes (generated)
└── GLOSSARY.md               # Term glossary (generated)
```

## Customization

### Change default language
Edit `~/.leetcode/leetcode.toml`:
```toml
[code]
lang = 'rust'  # or python3, cpp, go, java, etc.
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