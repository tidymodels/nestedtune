# M162: The shared test pool keeps both daemons

**Status:** dropped (2026-10-31, no PR). The plan required at least 5 trials that lose a daemon before any fix, and 40 trials lost none, so the user chose to drop the milestone and park its candidate row.

**Goal:** Find the call that drops a daemon from `test-parallel-identity.R`'s shared 2-daemon pool, and fix it where it sits.

**Outcome:** Nothing merged. The local branch `m162-shared-pool-daemon-loss` (never pushed, tip 2c0b02a7) holds `benchmarks/probe-shared-pool-loss.R`, kept there at the user's choice. Each trial is a fresh R process running `devtools::test()` on the identity file or the whole suite, and a loss is a failure whose srcref is a `shared_daemons(2)` line and whose call reads `mirai::status()$connections`.
- The `--plant` control (one daemon killed 20 s in) read as a loss in 1 of 1 trial, first at :414.
- At the base tree (tests and `R/` as at dd6b5f7b), 0 of 40 trials lost a daemon. File alone at side load 0: 0 of 10 (51-80 s). File alone at side load 16: 0 of 10 (trials 1-5 at 268-306 s, trials 6-10 killed at the 600 s deadline). Whole suite at side load 0: 0 of 10 (366-523 s). Whole suite at side load 8: 0 of 10 (505-683 s). Each whole-suite trial passed 13371 expectations with 0 other failures.
- Side load was R processes that spin on arithmetic. Two suites running at once, each with its own daemons, was not tried.
- The first whole-suite trials deadlocked in the probe itself: the trial process blocked writing to the stdout pipe that `callr::r_bg()` opened and the probe never read. The probe now sends each trial's output to a file.
- No test signals a process other than its own (grep for `pkill`, `pskill`, `kill -`).

**Decisions:** None. The candidate row "Find why the shared pool loses a daemon" holds the result and its promotion condition, parked. It was retitled from "Find why the identity pool loses a daemon", which was over the 40-character title limit.

**Review:** Not reached. Planned 2026-10-25 (full criteria audit, 11 findings taken). Implement ran 2026-10-25 to 2026-10-30 and stopped at the goal-wrong stop. A second implement start on 2026-10-31 found the plan unchanged and routed to `/milestone-plan`, where the user chose to drop and park, and to keep the probe on the local branch.
