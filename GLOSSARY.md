# LeetCode DSA Glossary

Domain language for LeetCode practice with terminal workflow and AI coaching.

## Tools

**leetcode-cli**: The clearloop Rust CLI tool (`cargo install leetcode-cli`) for scaffolding, testing, and submitting LeetCode problems from the terminal. Not the stale Node.js skygragon version.

**leetcode-mcp-server**: The jinzcdev MCP server (`npx -y @jinzcdev/leetcode-mcp-server`) that gives AI assistants direct access to LeetCode's GraphQL API — search problems, run code, submit solutions, check stats.

**helix**: Terminal modal editor (`hx` command), configured as the default editor for leetcode-cli. Fast, LSP-aware, no plugins needed.

**MCP (Model Context Protocol)**: The protocol AI assistants (Claude, Codex, OpenCode) use to access external tools. Configured via JSON in each assistant's config directory.

## DSA Concepts

**Zone of proximal development**: The space between what you can solve independently and what you can solve with help. Problems in this zone produce the most learning.

**Spaced repetition**: Revisiting problems at increasing intervals (1 day → 3 days → 7 days → 14 days) to build long-term retention. Unlike Anki flashcards, DSA spaced repetition requires re-solving, not just recalling.

**Pattern recognition**: Identifying that a new problem belongs to a known template (two pointers, sliding window, BFS, etc.). The key skill for interviews.

**Time complexity**: Big O analysis of how runtime scales with input size. Always discuss after solving.

**Space complexity**: Big O analysis of memory usage. Often the difference between an optimal and suboptimal solution.

_Avoid_: Big-O (use "Big O" instead), complexity analysis (use "time/space complexity" to be specific).

## Problem Categories

**Two pointers**: Technique using two indices/pointers moving through an array, often from opposite ends. Use for: sorted array searches, palindrome checks, container-with-most-water.

**Sliding window**: Subset of two pointers where a "window" of elements slides through an array. Use for: substring problems, subarray sums, longest/shortest subsequence.

**BFS/DFS**: Breadth-first and depth-first graph traversal. BFS for shortest path, DFS for exhaustive search.

**Dynamic programming (DP)**: Breaking a problem into overlapping subproblems with optimal substructure. Memoization (top-down) or tabulation (bottom-up).

**Greedy**: Making locally optimal choices at each step. Works when the problem has the greedy-choice property.