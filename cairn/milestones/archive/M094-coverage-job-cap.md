# M094: The coverage job runs under a 30-minute cap

**Status:** done (2026-09-14, PR #107 https://github.com/tidymodels/nestedtune/pull/107)

**Goal:** The `test-coverage` job cap goes from 20 to 30 minutes, the step cap `R-CMD-check.yaml` gives its non-windows legs.

**Outcome:** `.github/workflows/test-coverage.yaml` sets `timeout-minutes: 30` on its one job. Its comment keeps the hang rationale. It gives the "Test coverage" step range on the runs of 2026-09-12 to 2026-09-14: 11.9 to 18.7 minutes. Those times come from each attempt's record in the GitHub jobs API. It names attempt 1 of run 34880462437, which the 20-minute cap ended after its tests had finished. `R-CMD-check.yaml` no longer states the coverage cap figure. `benchmarks/test-time-budget.R` points at the workflow files for the caps and states no figure. On PR #107 the `test-coverage` job ran 16m41s.

**Decisions:** none. The plan gate chose a 30-minute cap over skipping slow test files under covr, and 30 over 25 minutes. The step nearing 30 minutes on the default branch falsifies the first choice. So does a hang that costs a review because 30 minutes let it run.

**Review:** both criteria verified. `devtools::check()` gave 0 errors, 0 warnings and 0 notes, and the six gating sweeps were clean. `devtools::document()` regroups the `importFrom` lines of `NAMESPACE` on the default branch too. That drift is older than this milestone and went to a candidate row. The three lenses reported 11 findings, and five were fixed at the gate. The fixes removed a stale "caps its own job at 20" from `R-CMD-check.yaml`. They replaced the plan's 19.5-minute figure, which did not reproduce. They tied the "not hung" claim to one run and fixed two wording slips in the budget script. Five findings were rejected with reasons. The rejected findings named the median-of-three timing rule, the steps after the tests, and a claim older than the branch. The other two named stale task line anchors and the removed M12 attribution. One finding was noted: no D-entry covers CI caps. The CI-timing LESSONS line was extended.
