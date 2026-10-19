# M149: Three arguments from tidymodels: verbose on the map, a wide inner table, one workflow's plot

**Status:** done (2026-10-18, PR #166 https://github.com/tidymodels/nestedtune/pull/166)

**Goal:** The three argument gaps that M148's review proposed are closed in the tidymodels shape, and each argument default that differs from its counterpart has a verdict.

**Outcome:** Three arguments, each placed where tidymodels places it.
- `nested_workflow_map(object, fn, verbose = FALSE, ...)`, in `workflow_map()`'s order. `check_map_verbose()` refuses a non-flag as `nestedtune_bad_verbose`, with a naming hint when the call did not name `verbose`. `log_map_start()` and `log_map_end()` write `i of n tuning|resampling: id` lines through `cli::cli_inform()`. A workflow that errors gets no finish line.
- `collect_inner_metrics(x, ..., type = c("long", "wide"))` on a run and on a set. It reuses `check_metrics_type()` and `pivot_metrics_wide()`. Fold 1 is tested against `tune::collect_metrics(type = "wide")` (`test-collect-inner-metrics-wide.R`, skipped on CRAN).
- `autoplot.nested_results_set(..., id = NULL)`. An id goes through `match_set_id()`, then the single-run method inside `for_workflow()`.
- `references/export-surface-review.md` marks the three rows `added`, adds rows for the new differences, and gives 7 default verdicts, all `kept`. NEWS has one entry, which also says an unnamed third argument now lands in `verbose`.

**Decisions:** milestone-local: `verbose` is taken by position, third, which narrows M71's name-matching rule to the arguments after `fn` and `verbose`. No D-entry.

**Review:** The criteria audit (full) returned 11 findings and the claim audit 2 corrections, all fixed. Review pass 1 verified AC1 to AC5. `devtools::check()` gave 0 errors, 0 warnings, 0 notes. The three lenses reported 24 findings: 17 fixed in `581fc633`, including errors on the `id` path that now name the workflow, the naming hint now shown only for an unnamed `verbose`, corrected `type` help, a CRAN skip on the oracle file, and a NEWS note on the refusal class. 7 were rejected with reasons, and none was sent to a candidate row. The first CI wait reached its limit, and the resumed review merged with 16 checks passed. The candidate row "Argument gaps beside tidymodels" graduated. One lesson was captured on `check()` in a git worktree.
