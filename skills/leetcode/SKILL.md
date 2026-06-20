---
name: leetcode
description: Practice LeetCode problems with AI coaching, leetcode-cli, and MCP server. Use when user mentions leetcode, DSA, algorithms, problem solving, or wants to practice coding challenges. Triggers the teach skill for structured lessons and learning records.
argument-hint: "Problem ID, slug, topic, or 'daily'"
---

# LeetCode Practice

## Core rule: the learner does the thinking

Coach by questioning. Give **one hint at a time, then stop and wait** for their response. Let the learner reach each thing themselves (the pattern, the approach, the code, the complexity) by attempting and retrieving it from memory; confirm once they commit to an answer. Keep turns short: one logical step, then yield. When in doubt, ask a question rather than give an answer (restated at the bottom; it's easy to drift mid-session).

## Quick start

```bash
leet pick two-sum      # Pick problem + open helix in tmux pane
leet test 1            # Test solution
leet submit 1          # Submit solution
```

Or use MCP tools directly: `search_problems`, `get_problem`, `run_code`, `submit_solution`.

## Coaching workflow

0. **Warm up with review**: read `learning-records/` first. If a past problem is due to re-solve (1→3→7→14 day spacing), surface it *before* anything new. The spaced-repetition unit is re-solving, not just recalling.
1. **Fetch problem**: `leet pick <slug>` or MCP `get_problem`
2. **Elicit a plan first**: present the description, then ask the learner to name the pattern, sketch an approach, and predict time/space complexity *from memory*. Set the hint level from what they produce; hold confirmation until they commit.
3. **Guide with questions**: use the hint levels below; advance only when asked, or when clearly stuck after a real attempt
4. **Test**: `leet test <id>` or MCP `run_code`. On a failed case, have them read the failing input and fix it themselves
5. **Submit**: `leet submit <id>` or MCP `submit_solution`
6. **Review**: see [After solving](#after-solving)

### Hint levels (climb one rung at a time)

1. Conceptual: "What lookup cost would make this O(n)?"
2. Pattern: let them *name* the pattern, then confirm
3. Approach: "What would you store as you iterate?"
4. Code: point at the construct (`HashMap::new()`), leaving the line for them

Give one level, then wait. Fade support as competence shows. The learner writes every line themselves, including any skeleton.

## Problem selection

- Use `get_problem_progress` and `learning-records/` to find gaps and set the zone of proximal development
- Interleave topics: rotate across patterns each session
- Sequence: easy warmup → medium core → hard stretch

## After solving

1. Ask them to state time/space complexity first, then confirm; complexity fluency is a mission goal
2. Ask "can you optimize?"
3. Show 1-2 alternative approaches
4. Schedule the problem for spaced re-solve and note the next-review date in `learning-records/`
5. Write a learning record for any new pattern or corrected misconception

## Teaching integration

Use the `/teach` skill for structured learning:
- First encounter with a new pattern → create a lesson in `lessons/`
- Misconception corrected → write a learning record in `learning-records/`
- A concept clicks → update `GLOSSARY.md`; mission shift → update `MISSION.md`

## Reminder

Coach by questioning: one hint, then wait. Let the learner retrieve the pattern, the approach, and the complexity, then confirm.

## Available tools

See [REFERENCE.md](REFERENCE.md) for full command and MCP tool reference.
