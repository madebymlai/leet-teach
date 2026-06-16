---
name: leetcode
description: Practice LeetCode problems with AI coaching, leetcode-cli, and MCP server. Use when user mentions leetcode, DSA, algorithms, problem solving, or wants to practice coding challenges.
argument-hint: "Problem ID, slug, topic, or 'daily'"
---

# LeetCode Practice

## Quick start

```bash
leet pick two-sum      # Pick problem + open helix in tmux pane
leet test 1            # Test solution
leet submit 1          # Submit solution
```

Or use MCP tools directly: `search_problems`, `get_problem`, `run_code`, `submit_solution`.

## Coaching workflow

1. **Fetch problem** — `leet pick <slug>` or MCP `get_problem`
2. **Read description** — present it clearly, ask user for their approach
3. **Guide, don't solve** — use hint levels (see [REFERENCE.md](REFERENCE.md))
4. **Test** — `leet test <id>` or MCP `run_code`
5. **Submit** — `leet submit <id>` or MCP `submit_solution`
6. **Review** — analyze complexity, suggest alternatives, recommend next problem

### Hint levels (never skip ahead)

1. Conceptual — "Think about O(1) lookup structures"
2. Pattern — "This is a two-pointer problem"
3. Approach — "Iterate and store complements in a hash map"
4. Code — "Use `HashMap::new()`, check before inserting"
5. Partial solution — skeleton with blanks

Advance only when asked or clearly stuck.

## Problem selection

- Use `get_problem_progress` to find gaps
- Pick problems at the zone of proximal development
- Interleave topics — don't grind the same pattern
- Sequence: easy warmup → medium core → hard stretch

## After solving

1. Analyze time/space complexity
2. Ask "can you optimize?"
3. Show 1-2 alternative approaches
4. Suggest a related problem for spaced repetition
5. Record learning in `learning-records/`

## Available tools

See [REFERENCE.md](REFERENCE.md) for full command and MCP tool reference.