# Python syntax gaps surfaced during two-sum attempt

During the first two-sum solve attempt (problem 1), the learner wrote code revealing these gaps in Python fundamentals — not algorithmic gaps, but the expression layer:

- Called a list as a function: `nums()` instead of `len(nums)`.
- Placed a working variable in the class body (`return_list = List[int]`) expecting it to be visible inside the method. Did not distinguish class scope from method scope.
- Treated the type annotation `List[int]` as if it were an instance/value rather than a type hint.

**Why it matters:** these block every LeetCode solve in Python regardless of pattern. They are prerequisites, not the puzzle. A reference doc (`reference/python-leetcode-syntax.html`) and lesson 0001 cover them inline. Future sessions can assume the *concepts* need not be re-taught, but should verify the learner can *produce* `len()`, in-method declaration, and `[]` vs `List[int]` from memory before raising difficulty.

**Implications:** before introducing dict comprehension, enumerate, or nested-data-structure problems, confirm these three are fluent.
