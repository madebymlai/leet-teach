# LeetCode DSA Glossary

The canonical language for this LeetCode DSA workspace: its tools, its coaching method, and the algorithm patterns practised here.

## Tools

**leetcode-cli**:
The clearloop Rust command-line tool (`cargo install leetcode-cli`) for fetching, testing, and submitting problems from the terminal.
_Avoid_: the skygragon Node.js CLI (stale, not this one)

**leetcode-mcp-server**:
The jinzcdev MCP server (`@jinzcdev/leetcode-mcp-server`) that exposes LeetCode's API to the AI coach as callable tools.

**leet**:
This repo's wrapper script that runs leetcode-cli inside a tmux pane (`leet pick|test|submit`) and keeps the session cookie fresh.

**helix**:
The terminal modal editor (`hx`), set as leetcode-cli's default editor.
_Avoid_: Vim, "the IDE"

**MCP (Model Context Protocol)**:
The protocol an AI assistant uses to call external tools such as the leetcode-mcp-server.

## Learning

**Zone of proximal development (ZPD)**:
The band of problems a learner can clear only with light coaching, just past independent reach, where practice produces the most learning.
_Avoid_: difficulty level, comfort zone

**Active recall**:
Producing the pattern, approach, or syntax from memory before seeing any confirmation, rather than recognising it once shown.
_Avoid_: review, re-reading

**Spaced repetition**:
Re-solving a problem at widening intervals to build storage strength. The unit is re-solving the problem, not recalling a fact.
_Avoid_: cramming, drilling

**Storage strength**:
How durably knowledge is retained over time, as opposed to how fast it can be retrieved right now (fluency). Spaced repetition builds it; cramming does not.
_Avoid_: memorisation

**Pattern**:
A reusable solution template that many problems reduce to. In this workspace "pattern" always means this, never an object-oriented design pattern.
_Avoid_: trick, formula

**Pattern recognition**:
Matching an unseen problem to a known pattern. The core interview skill.

## Complexity

**Big O**:
Notation for how a solution's cost grows as input size grows, ignoring constant factors.
_Avoid_: Big-O, order notation

**Time complexity**:
A solution's running time as Big O of the input size.
_Avoid_: speed, "complexity" left unqualified

**Space complexity**:
A solution's extra memory use as Big O of the input size, often the line between an optimal and a suboptimal answer.
_Avoid_: memory cost, "complexity" left unqualified

## Patterns

**Two pointers**:
A scan that walks two indices through a sequence, often inward from opposite ends, to replace a nested loop with one linear pass.
_Avoid_: two-pointer trick

**Sliding window**:
A two pointers variant that keeps a contiguous range whose ends advance to preserve an invariant; used for substring and subarray problems.

**Breadth-first search (BFS)**:
Level-by-level traversal of a graph or tree using a queue; the basis for shortest paths in an unweighted graph.

**Depth-first search (DFS)**:
Traversal that follows one branch to its end before backtracking, via recursion or a stack; the basis for exhaustive search.

**Dynamic programming (DP)**:
Solving a problem by caching and combining solutions to overlapping subproblems that share optimal substructure, either top-down (memoization) or bottom-up (tabulation).
_Avoid_: brute force with a cache

**Greedy**:
Building a solution from locally optimal choices, valid only when the problem has the greedy-choice property.
