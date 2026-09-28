# M124: Averaged out-of-fold predictions

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP2, IP4
- **Resolves:** —
- **Surface tier:** user-facing — it adds an argument to an exported method
- **Branch/PR:** m124-averaged-predictions

## Goal

A user reads one averaged out-of-fold prediction per data row from a nested run through `collect_predictions(summarize = TRUE)`, averaged by tune's rules.

## Scope

**In:** a `summarize` argument on `collect_predictions()` for a `nested_results` and a `nested_results_set`. The average spans every completed fold that held the row out, whatever candidate each fold selected. So the averaged table drops the fold labels and `.config`. The kind of average follows the prediction columns the run saved, which is the kind tune picks from the metric types. One D-entry records the choices. The help page, the example and `NEWS.md` state the argument.

**Out:** `augment()` on a design that holds a row out more than once → M125. Averaging quantile predictions, refused here → a new candidate row. tune 2.1.0 refuses a quantile metric set passed to it, but it runs a quantile model on its default metric and averages those predictions. A check of a port against that average needs a quantile engine such as quantreg in Suggests, which is a dependency change for its own gate. The `parameters` argument is not offered, because each fold predicted with the parameters it selected. The help page says so. A bad `summarize` value gets base R's error, as `collect_metrics()` gives, the stance M092's review took.

## Acceptance criteria

- [ ] AC1: `collect_predictions()` on a `nested_results` takes `summarize`, default `FALSE`. The run under test is `nested_fit_resamples()` over a repeated v-fold outer design with a deterministic engine. Its `summarize = TRUE` table equals `tune::collect_predictions(summarize = TRUE)` on `tune::fit_resamples()` over the same outer splits, workflow and metric set. The comparison covers the outcome, `.row` and every prediction column, after both tables are ordered by `.row`, within testthat's default tolerance. A test asserts this for four runs. They are a regression, a probability classification, a class-only classification, and a censored regression. The censored run's metric set saves `.pred` and `.pred_time`.
- [ ] AC2: The run under test is `nested_tune_grid()` over a repeated v-fold design. For the regression and classification runs, the test asserts that the repeats selected at least two different candidates. The `summarize = TRUE` table equals a base R computation the test writes from `collect_predictions(res)`. Per `.row`, a numeric prediction column is its mean with missing values ignored. Class probabilities are each averaged the same way, then divided by the row's sum of those averages. A `.pred_class` saved beside probabilities becomes the first level, in factor order, among those at the largest averaged probability. A censored run takes the median `.pred_time`. If any `.pred_time` value is missing, that median is missing. Per `.eval_time`, it takes the mean `.pred_survival` and `.weight_censored` with missing values ignored. A test asserts this for a regression, a probability classification and a censored regression.
- [ ] AC3: With class predictions and no probabilities, `.pred_class` is the most frequent class. A tie goes to the first level, in factor order, among the tied classes. A test on predictions edited to plant ties asserts this for both orders of a two-class vote. It also asserts a three-level tie that excludes the first level, and a planted tie between averaged probabilities.
- [ ] AC4: The averaged table has one row per data row that some completed fold held out, ordered by `.row`. Its columns are those of `collect_predictions(res)` in the same order, less the fold-label columns and `.config`. A test asserts this on a repeated v-fold run whose repeats selected different candidates, and on a Monte Carlo run. For the Monte Carlo run, it compares the table's `.row` values with the union of the completed folds' assessment rows.
- [ ] AC5: On a run where some folds failed, `summarize = TRUE` averages over the completed folds and warns exactly once, with class `nestedtune_partial_summary`. A row held out by one failed and one completed fold takes the completed fold's value. A row that only failed folds held out is left out. A test asserts the warning count and class, and both rows.
- [ ] AC6: `collect_predictions()` on a `nested_results_set` takes `summarize` and passes it to each workflow. A test asserts that the set's `summarize = TRUE` table equals each workflow's own averaged table, bound under `wflow_id`.
- [ ] AC7: Under `summarize = TRUE`, a run whose saved predictions carry a `.pred_quantile` column is refused with class `nestedtune_summarize_quantile`. The test edits one completed fold's `.predictions` to carry that column and asserts the class.
- [ ] AC8: The `collect_predictions.nested_results` help page states the rules of AC2 and AC3. It says that the fold labels and `.config` are dropped because each fold selected its own candidate. It says that a saved `.pred_class` is recomputed from the averaged probabilities, whatever a postprocessor set. It says that `parameters` is not offered and that quantile predictions are refused. Its executed example calls `summarize = TRUE` on a repeated design. `NEWS.md` carries a bullet for the argument. `devtools::check()` reports 0 errors, 0 warnings and 0 notes.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T2
- AC4 → T1, T2
- AC5 → T3
- AC6 → T3
- AC7 → T3
- AC8 → T4, T5

## Tasks

- [x] T1: Write the AC1 to AC4 tests first, in a new `tests/testthat/test-collect-predictions-summarize.R` with the file-level `skip_heavy_on_cran()` of M118. Use deterministic engines for AC1. Regression takes `fixed_workflow()`. Both classification runs take a `logistic_reg()` workflow, not the ranger `cls_workflow()`, whose per-fold probabilities differ from `fit_resamples()` (criteria audit). Censored takes `srv_workflow()` with `dist` fixed and `srv_set_metrics()`, under `skip_if_no_censored()` (LESSONS M101). Run the tests and record that they fail.
- [x] T2: Add `summarize` to `collect_predictions.nested_results()` in `R/nested-results-collect.R`. Write an internal averaging helper that drops the labels and `.config`, groups by `.row`, and picks its rule from the saved columns. Probabilities take the probability rule, and `.pred_class` alone takes the vote. A numeric `.pred` takes the mean. A list `.pred`, `.pred_time` or `.pred_linear_pred` takes the censored rules. Call no `tune:::` function. Grep the helper's name first (LESSONS M41).
- [x] T3: Write the AC5 to AC7 tests, then the code. Break folds with `break_fold()` for AC5. Pass `summarize` through `stack_set()` in `R/nested-results-set.R` for AC6. Refuse a `.pred_quantile` column for AC7.
- [x] T4: Write the AC8 help text and example, and the `NEWS.md` bullet. Append a D-entry that extends D-054 with the argument. It records the average across selected candidates with `.config` dropped, the choice of rule from saved columns, and the quantile refusal. Run `Rscript benchmarks/sweep-prose.R --plain` and `--roxygen --plain`.
- [ ] T5: Run `devtools::document()`, `devtools::test()`, `devtools::check()` and `pkgdown::check_pkgdown()`.

## Work log

- 2026-09-28: created by /milestone-plan from the `summarize = TRUE` candidate row (M68 Out). The user chose it at the plan gate. No candidate's promotion condition had fired.
- 2026-09-28: criteria audit (full mode, fresh [O] reader) read both drafts and returned 12 findings, each with one fix, all applied before writing. Here it added deterministic engines to AC1 and a censored metric set that saves `.pred_time`. It added tune's missing-value rules, ties by factor order in three cases, and a probability tie. It pinned the column order, made AC5 check the averaged value and the warning count, and documented the quantile refusal. It showed by execution that tune 2.1.0 refuses a quantile metric set.
- 2026-09-28: plan gate chose two milestones over one because one held about 12 criteria; falsified by M125 needing nothing beyond M124's helper.
- 2026-09-28: plan gate chose one row per data row over tune's grouping by candidate, because folds select different candidates; falsified by users needing per-candidate averages.
- 2026-09-28: plan chose the rule from saved columns over the recorded metric set, because a default-metric run records none; falsified by columns contradicting metric types.
- 2026-09-28: plan chose refusing quantile predictions over porting tune's rule, because no quantile run can check it; falsified by tune accepting quantile metrics.
- 2026-09-28: implement started on branch `m124-averaged-predictions`. The question gate was skipped because the plan left no choice open.
- 2026-09-28: T1 done. 14 tests in `test-collect-predictions-summarize.R` all error with `rlib_error_dots_nonempty` naming `summarize`, before any code. Grid seeds 21 (regression) and 25 (classification) give repeats that select two candidates.
- 2026-09-28: T2 done. `average_fold_predictions()` and three rule helpers in `R/nested-results-collect.R`. The AC2 tests now plant one missing value each, because a run's own predictions carry none in `.pred` or `.pred_survival`. Eight planted defects (tie order, renormalization, missing-value handling, `.config` kept, saved class kept) each turn 1 to 4 tests red. Full suite 1077 tests, 0 failing. Both prose sweeps clean.
- 2026-09-28: T3 checkpoint, not yet checked off. AC5 to AC7 tests and code written. Before the code, AC6 errored on `summarize` in the set method's `...` and AC7 raised no `nestedtune_summarize_quantile`. AC5 already passed on T2's helper. The test file passes. The full suite is still running. D-090 is drafted for T4.
- 2026-09-28: T3 done. Full suite 1080 tests, 0 failing. Prose sweep clean.
- 2026-09-28: T4 done. Help section "Averaging across the folds", the `summarize` and `...` params on both pages, a repeated-design example (run: 32 rows for mtcars' 32), a `NEWS.md` bullet, and D-090. `document()` rewrote two Rd files. Both prose sweeps clean.
- 2026-09-28: claim audit (fresh [O] reader) read 63 claims and returned 5. Missing votes now count as a class, as tune counts them, with a test that failed first. A row with all-missing averaged probabilities gets a missing class, tune's first level being the one stated departure, with a test. Three test comments corrected.
- 2026-09-28: amendment gate, Scope Out: the user kept the quantile refusal and chose to correct its reason. tune averages quantile predictions from a default-metric run, so the reason is now the quantreg dependency that a check needs. D-091 supersedes D-090's two false clauses. The candidate row is corrected in place.
- 2026-09-28: the AC7 test planted a `hardhat::quantile_pred`, and `check()` warned that hardhat is undeclared. It now plants a plain column under that name, so Suggests is unchanged.

## Decisions

## Review
