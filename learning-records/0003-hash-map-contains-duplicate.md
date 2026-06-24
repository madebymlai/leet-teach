# Hash-map lookup pattern: second application (Contains Duplicate)

The learner applied the hash-map lookup pattern to Contains Duplicate (problem 217) independently after one coached example (Two Sum). Submitted and accepted (15 ms, 37.1 MB). Named the pattern as "hash lookup" and stated both complexities correctly (O(n) time, O(n) space) after the per-op/whole-solution prompt that was needed last time.

**Evidence:** chose `value in seen` as the membership check (correct question), keyed the dict by value, returned True/False on the first match. Correctly identified that `enumerate` is unnecessary when only the value is needed - but chose to keep it in the submitted version as a deliberate "imperfect first version" lesson.

**Key insight surfaced:** the learner initially keyed the dict by index (`seen[index] = value`) and the test cases passed by coincidence - on `[1,2,3,1]` the value `1` happened to match index `1`. This is the "keyed by the wrong thing" failure mode: `value in seen` tested "is this value an index?" instead of "is this value a value?" Lesson 0001 now has a "Choosing the key and the value" section addressing this generically.

**Implications / ZPD signal:**
- Pattern transfer is happening: same shape, different complement, without re-teaching. Next hash-map family member (e.g. First Unique Character, Subarray Sum Equals K) is in reach.
- The "which one is the key" decision is a sub-skill that needed coaching once and should be checked on the next solve.
- The per-op vs whole-solution complexity confusion recurred but resolved faster than in two-sum. Continue asking for both time AND space up front.
- The learner recognizes when their code can be simplified but accepts imperfection in a first pass - healthy posture for interview timing. Do not over-coach simplification until the pattern is fluent.
