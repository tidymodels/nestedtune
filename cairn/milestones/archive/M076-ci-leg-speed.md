# M076: The two slow check legs run their check step under the cap the other three use

**Status:** done (2026-09-09, PR #86 https://github.com/tidymodels/nestedtune/pull/86)

**Goal:** Rebalance the parallel test run so the windows and devel `check-r-package` steps earn the 30-minute cap the other three legs carry.

**Outcome:** Devel's step cap came back to 30 and windows alone keeps 40 — `.github/workflows/R-CMD-check.yaml`'s expression is now `matrix.config.os == 'windows-latest' && 40 || 30`. Three attempts on branch head `3b313dd` (run 34287906467, five legs green each time) gave step medians of windows 25.3, devel 20.8, macOS 19.3, oldrel-1 17.6, ubuntu release 19.0. Both test-suite levers M74 left unpriced were implemented, measured and reverted: `benchmarks/test-timing-parallel.md` records four arms at four workers, the branch point at a 198.0 s median against the 194.4 s makespan floor its own per-file occupancy implies, so re-ordering has no idle worker time to recover; re-ordering measured 202.8 s on non-overlapping ranges, and the two split arms bought nothing while adding a daemon-pool start per file. `benchmarks/profile-tests-parallel.R` is the new measurement mode, reading per-file wall clock from `HangTraceReporter`'s stderr stamps because a testthat result's `real` column is near zero under parallel files. Package code, tests and DESCRIPTION are byte-identical to the branch point.

**Decisions:** none cross-cutting. Milestone-local: caps follow the measurement, rather than the measurement being made to reach a target cap.

**Review:** three-lens fan-out plus one gate finding; 16 findings, none a criterion failure and none in package code. Twelve fixed on the branch — an unresolvable measurement sha, a wrong worker-package-load claim, a missing re-ordering caveat, the profiler's worker-count guard, the overstated split conclusions, a stale cap sentence, two PROFILE clauses. Three rejected: a Coverage mapping the validator accepts, a five-byte figure in append-only history, a headroom observation AC2 forces. One deferred to the M74 remainders row — duplicate per-run count printing copied from the serial profiler.
