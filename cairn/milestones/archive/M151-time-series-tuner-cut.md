# M151: The four other tuners are tested on one inner sliding design, and the help claims only what the tests run

**Status:** done (2026-10-22, PR #168 https://github.com/tidymodels/nestedtune/pull/168)

**Goal:** Cut the suite time that the inner-design tuner matrix costs. The help and `NEWS.md` then name a function and design as tested only where a test runs them.

**Outcome:** 31 test blocks deleted, no test added, no code in `R/` changed except roxygen text.
- `test-time-series-inner-bayes-anneal.R` and `test-time-series-inner-race.R` deleted whole (24 blocks) and dropped from `Config/testthat/start-first`. Each of the four non-grid tuners keeps its inner sliding run on the sliding-window pair in `test-time-series-pairs-other.R`.
- `test-time-series-inner-other.R` lost the four map blocks with a tuner `fn`; `test-nested-workflow-map-oracles.R` still tests `fn` routing.
- `test-time-series-designs.R` lost the grid final fit on the three sliding outer designs; the final fit reads the data, not the outer splits (D-075), and the Bayesian sliding-window final fit stays (D-080).
- The `Time-series designs` section of `?nested_resamples` and three `NEWS.md` bullets name only tested combinations and say the four tuners are untested under an outer `rolling_origin()` with an inner sliding design.
- In CI run 39525408946 the deleted blocks took 15.3% to 16.4% of block time per leg. `R/` line coverage unchanged (6352 lines, 128 uncovered).

**Decisions:** D-118 supersedes the clauses of D-080, D-085, D-112 and D-113 that the cut changes and narrows D-071. AC4 was amended at implement from a 450 s local drop to the CI share, because back-to-back local runs measured machine state.

**Review:** Four-lens fan-out, 22 findings: 11 fixed (D-118 wording, the help's lead sentence, stale test comments, a work-log correction), 11 rejected with reasons, none to a candidate row. `devtools::check()` 0/0/0. One local `devtools::test()` run started right after `check()` in the same shell failed unexplained; two later runs and all 17 PR checks passed. The first CI wait reached its limit and the resumed review merged. The "Inner designs M140 leaves out" row was widened at T4 and stays parked. The M51 timing lesson was extended.
