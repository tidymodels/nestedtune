# M159: The snapshot naming is tested where it runs, the hygiene header describes its file, and the interrupt block withstands its failure's cause

**Status:** done (2026-10-24, PR #176 https://github.com/tidymodels/nestedtune/pull/176)

**Goal:** Close the three suite findings M079's review left (5, 8, 9) and the `test-parallel-interrupt.R` failure that the same review found inside the parallel suite.

**Outcome:** Test code only.
- Finding 5: the `test-suite-hygiene.R` block "a daemon snapshot names each record by the pid it holds" takes its snapshots through `daemon_state_snapshot()`, with `collect_bounded()` rebound by `rlang::local_bindings()` (testthat's `local_mocked_bindings()` searches only the namespace).
- Finding 9: that file's header names its four checks. Finding 8 (a 5 s explicit-seed Bayes run) closed at the plan with no code change, at the user's choice.
- The interrupt failure: a suite started with `&` from a non-interactive shell inherits SIGINT ignored, so no signal reaches R. Load is not the cause. The block "an interrupted run leaves no fold executing" now sends itself one SIGINT with `tools::pskill()` before dispatch and skips with "this process ignores SIGINT, so no interrupt can reach it" when none arrives in 5 s. The shell writes a `sent` file before `kill -INT`, and a signal never sent fails with its own message. Ledger: a 5 s deadline-poll row.
- Evidence: 3 quiet full runs and 2 foreground side-by-side pairs, with the block passing in all 7 runs. A run started with `&` skipped it.

**Decisions:** milestone-local only. The plan's cause (a signal lost under load) and its resend loop were refuted and removed. AC3 was amended to the probe-then-skip at two user stops, the second replacing a command that did not run. None promoted.

**Review:** Four-lens fan-out, one pass, no return. 32 findings: 16 fixed (a redundant markers check, an incorrect `system2()` comment, message wording, stale one-poll comments, the `m15-sent` name, the M152 and M15 lessons), 15 rejected (one `edge`: `pskill()`'s unchecked return), 1 noted. 4 pre-existing items went to the new row "Tidy the interrupt block's leftovers". `check()` 0/0/0 on the final tree. CI green on PR #176. Three local tracking commits after `a7db88c1` were not pushed, so CI would not restart, and this summary carries them. Row "Fix the M079 review leftovers" graduated. Row "Find why the identity pool loses a daemon" added at T5. The M152 lesson was corrected and the M15 lesson extended. None retired or unparked.
