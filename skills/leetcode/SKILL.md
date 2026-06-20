---
name: leetcode
description: Orchestrate LeetCode DSA practice on top of the /teach skill. Runs the leetcode-cli/MCP problem loop, coaches the solve with progressive hints, and helps the learner discover the syntax and tools a solution needs. Use when the user mentions leetcode, DSA, algorithms, problem solving, or wants to practice coding challenges. Delegates lessons, learning records, and zone-of-proximal-development tracking to /teach.
argument-hint: "Problem ID, slug, topic, or 'daily'"
---

# LeetCode Practice

This skill is an **orchestrator on top of `/teach`**. It owns the *doing*: driving the leetcode-cli/MCP loop, coaching the solve, and helping the learner discover unfamiliar syntax and tools. It does **not** own the knowledge model. Lessons, learning records, the glossary, and the zone-of-proximal-development (ZPD) assessment all live in `/teach`. Read that state to choose what to practise; hand new knowledge back to `/teach` to capture. Never re-implement it here.

## Division of labor

| This skill (leetcode) | /teach |
|---|---|
| Pick a problem at the ZPD, run the solve loop | Maintain the ZPD from learning records |
| Coach the algorithm with progressive hints | Turn an uncovered gap into a lesson |
| Help discover syntax, stdlib, and tools | Record what was learned in `learning-records/` |
| leetcode-cli and MCP mechanics | `GLOSSARY.md`, `MISSION.md`, `lessons/` |

## Quick start

```bash
leet pick two-sum      # Pick problem + open helix in tmux pane
leet test 1            # Test solution
leet submit 1          # Submit solution
```

Or use MCP tools directly: `search_problems`, `get_problem`, `run_code`, `submit_solution`.

## Coaching loop

0. **Pick at the ZPD**: read `learning-records/` to see what the learner can already do, then choose a problem just past their independent reach. Surface anything due to re-solve before new material.
1. **Fetch**: `leet pick <slug>` or MCP `get_problem`
2. **Elicit a plan first**: ask the learner to name the pattern, sketch an approach, and predict time/space complexity from memory. Set the hint level from what they produce; hold confirmation until they commit.
3. **Coach the algorithm**: give one hint at a time, then wait (levels below). Advance only when asked, or when stuck after a real attempt.
4. **Help discover syntax and tools**: see below. This is a separate axis from algorithm hints.
5. **Test**: `leet test <id>` or MCP `run_code`. On a failed case, have them read the failing input and fix it themselves.
6. **Submit**: `leet submit <id>` or MCP `submit_solution`.
7. **Review**: ask them to state time/space complexity first, then confirm; show 1-2 alternatives; hand any new pattern, syntax, or corrected misconception to `/teach`.

### Algorithm hint levels (climb one rung at a time)

1. Conceptual: "What lookup cost would make this O(n)?"
2. Pattern: let them name the pattern, then confirm
3. Approach: "What would you store as you iterate?"

Give one level, then wait. Fade support as competence shows. The learner writes every line themselves.

## Syntax and tool discovery

Don't assume the learner knows the language. When they have the right *idea* but not the *expression* (how to write a hash map in Rust, which stdlib call sorts in place, what the cli or MCP can do), help them **discover** it rather than withhold it: name the tool, point at the signature or doc, show the idiom once. This is knowledge acquisition, not the puzzle, so the "make them retrieve it first" rule does not apply.

Discovered syntax and tools are **stateful knowledge**, so route them through `/teach`:
- in the learner's ZPD and worth practising: ask `/teach` for a lesson in `lessons/`
- a fact or idiom to remember: ask `/teach` to write a learning record, and update `GLOSSARY.md` if it is a new term

This keeps the orchestrator thin: leetcode surfaces the gap, `/teach` captures and teaches it.

## Available tools

See [REFERENCE.md](REFERENCE.md) for full command and MCP tool reference.
