# LeetCode Skill Reference

## leetcode-cli commands

```bash
leetcode pick <id|slug|name>    # Fetch and scaffold a problem
leetcode list                    # List problems (filter by difficulty, tag)
leetcode edit <id>               # Open problem in $EDITOR (helix)
leetcode test <id>               # Test solution against LeetCode API
leetcode exec <id>               # Submit solution
leetcode stat                     # Show submission stats
```

## leet helper (tmux)

```bash
leet pick <slug>     # Pick problem + open helix in tmux split pane
leet edit <id>       # Open problem in tmux split pane
leet test <id>       # Test solution in current pane
leet submit <id>     # Submit solution in current pane
```

The `leet` script creates a tmux pane named `leet-edit` on the right side. Target it with:
```bash
tmux send-keys -t leet-edit ':w' Enter
```

## leetcode-mcp-server tools

### Problems
- `get_daily_challenge` — today's daily problem
- `get_problem(titleSlug)` — full problem description, constraints, examples
- `search_problems(tags, difficulty, searchKeywords, limit)` — find problems by topic

### Submissions
- `run_code(titleSlug, lang, typedCode)` — run code on LeetCode judge (auth required)
- `submit_solution(titleSlug, lang, typedCode)` — submit to LeetCode (auth required)

### User data
- `get_user_profile(username)` — profile info
- `get_problem_progress()` — what you've solved (auth required)
- `get_recent_ac_submissions(username, limit)` — recent accepted submissions
- `list_problem_solutions(questionSlug)` — community solutions

## Language config

Default language is set in `~/.leetcode/leetcode.toml`:
```toml
[code]
lang = 'python3'  # python3, rust, cpp, java, dart, c, go
editor = 'helix'
```

## File locations

- Solution files: `~/.leetcode/code/`
- LeetCode config: `~/.leetcode/leetcode.toml`
- Helix config: `~/.config/helix/config.toml`
- MCP configs: `~/.config/claude/`, `~/.codex/`, `~/.config/opencode/`

## Auth setup

LeetCode session cookie is needed for both leetcode-cli and MCP:
```bash
leetcode data -c    # interactive cookie setup for leetcode-cli
```

For MCP, set `LEETCODE_SESSION` in the MCP config JSON files.