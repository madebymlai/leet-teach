# Hash-map lookup pattern: applied to two-sum with coaching

The learner implemented the hash-map lookup pattern for Two Sum (problem 1) and got it accepted (0 ms, top 100%). Demonstrated: dict create/insert/lookup/membership, `enumerate` with index+value unpacking, lookup-before-insert ordering, and the O(n) time / O(n) space trade versus the O(n^2) nested-loop brute force.

**Evidence:** working solution submitted to the judge; correctly identified the complement as `target - x`, stored `x -> i`, returned `[seen[complement], i]`. Named the pattern as "hash lookup" (close to the canonical "hash-map lookup pattern").

**Why it matters:** this is the first acquired pattern. It sets the floor for what to teach next: other hash-map family members (Contains Duplicate, First Unique Character, Subarray Sum Equals K) are now in reach, and the next new pattern should sit just above this one (likely two pointers or sliding window, not a second hash-map problem).

**Implications / ZPD signal:** complexity reasoning is partial. The learner first answered "O(1)" (one lookup) before correcting to "O(n)" (whole pass) on prompt. Fluency for *stating* complexity lags the ability to *implement* the pattern. Future sessions should ask for time AND space complexity up front before coding, and treat "O(1) per operation" vs "O(n) overall" as a sub-skill to drill. The enumerate unpacking bug (forgetting `i, x =` and treating the tuple as a scalar) is now corrected but worth re-checking on the next solve.
