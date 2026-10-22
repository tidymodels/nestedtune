# M152: The suite drops tests that repeat a shared path, cannot fail, or test a dependency

**Status:** done (2026-10-22, PR #169 https://github.com/tidymodels/nestedtune/pull/169)

**Goal:** Remove the test blocks and expectation lines that the "What gets a test" floor calls superfluous, outside the time-series files.

**Outcome:** 99 test blocks removed and 47 trimmed (15309 to 13367 expectations), tests only; no `R/`, help, NEWS, README or vignette change.
- (a) BC6's `param_info` block, BC11 and BC15 in `test-parallel-identity.R` are one `nested_tune_bayes()` run setting all three; a mutation setting each formal to its default in both `.args` lists of `dispatch_folds()` fails it.
- (b) The racer loops run the ANOVA racer, except where a block reads each racer's registry entry: the deterministic oracle, both package checks, the shared-check table, the desirability refusal and BC12.
- (c) Seed-identity checks that `nested_loop()`'s restore makes unable to fail went; grid-checks :467, which starts with no seed, stays.
- (d) RNG, final-fit, model-spec, compat, reader, print, plot and parallel blocks that repeat a covered path went; the model-spec forwarding block now asserts each method's wrapped workflow.
- (e) Weaker expectations after exact ones went. (f) Dependency checks went; where a block also held the package's own part (D-010, D-014, the set's `rank_results()`/`fit_best()`), a registry or class check keeps it.
- `benchmarks/prune-ledger-5feebda2-4f13334f.csv` lists each removed or changed block with its category and cover; the block and line-coverage tables of both trees sit beside it. `R/` coverage unchanged (6352 lines, 128 uncovered).
- Serial suite total, one side-by-side pass: 1094.2 s to 1007.5 s.

**Decisions:** none. AC5's bar went from 100 s to 60 s at the user's choice when the planned cuts measured 71.7 s; the 2026-10-21 review notes behind the unnamed candidates were lost and re-derived by three read-only surveys.

**Review:** Four-lens fan-out, 42 findings: 19 fixed (BC12, the desirability refusal and the shared-check table back on both racers per D-079; registry checks for D-010, D-014 and the set refusal; the benchmark constant; drift guards; comments and ledger references), 19 rejected with reasons, 4 to the new row "Clear two leftovers of the test prune". `devtools::check()` 0/0/1 (a worktree `.git` note). The coverage job's first CI attempt stalled installing packages and passed on rerun. No candidate graduated. "Fix the M079 review leftovers" was unparked: M152 priced suite time again, and the interrupt failure it names cost this review a coverage re-run. One lesson added.
