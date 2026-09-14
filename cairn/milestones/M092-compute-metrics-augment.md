<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M092: A nested run answers compute_metrics() and augment()

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP2, IP3
- **Resolves:** —
- **Surface tier:** user-facing — the milestone adds exported S3 methods on two tune generics
- **Branch/PR:** m092-compute-metrics-augment

## Goal

A user scores the saved out-of-fold predictions of a nested run with a new metric set, and joins them onto the data rows, through two tune generics.

## Scope

**In:** `compute_metrics()` and `augment()` methods for `nested_results` and for `nested_results_set`. Both read the `.predictions` column that a run keeps under `save_pred = TRUE`. The help pages, the examples, the `_pkgdown.yml` reference entries and a `NEWS.md` bullet are in scope.

**Out:**
- `conf_mat_resampled()`. tune 2.1.0 defines it as a plain function that checks `inherits(x, "tune_results")`, so no method can reach it. A candidate row holds it until tune makes it a generic.
- Averaging the predictions of a row that the outer design holds out more than once, as tune's `augment()` does. `augment()` refuses such a design here. The standing `summarize = TRUE` candidate row holds the averaging, because it needs an oracle against tune's averaging of class probabilities.
- A new metric that also drives the inner selection. The candidate row on separating the selecting metric from the scoring metric holds it.
- Resample weights from tune 2.1.0 (`add_resample_weights()`). A candidate row holds them.
- `int_pctl()`. The inference candidate row holds it.

## Acceptance criteria

- [x] AC1: Take a `nested_results` run with `save_pred = TRUE`. Given the metric set and the `event_level` that the run recorded, `compute_metrics()` returns a table identical to `collect_metrics()` on that run. This holds for `summarize = TRUE` and for `summarize = FALSE`. A test asserts it on a regression fixture, a classification fixture run with `event_level = "second"`, and a censored-regression fixture.
- [x] AC2: Give `compute_metrics()` a metric set that the run did not use. For each completed fold, the estimates equal that metric set applied by hand with yardstick to the rows of the fold in `collect_predictions()`. With `summarize = TRUE`, the mean, `n` and `std_err` equal the values computed by hand from the per-fold estimates. A fold that scores `NA` is left out. A test asserts both on a repeated-design fixture in which one fold scores `NA`. The test runs once with a numeric metric set and once with a class-probability metric set. Neither set shares a metric with the set of the run.
- [x] AC3: `compute_metrics()` on a `nested_results` refuses four inputs. A run without saved predictions gets class `nestedtune_column_not_saved`. A `metrics` that is not a metric set gets class `nestedtune_bad_metrics`. A metric set that needs a prediction type the run did not save gets class `nestedtune_metric_type_not_saved`. The probe is a class metric on a run that saved only probabilities. Non-empty `...` gets class `rlib_error_dots_nonempty`. A run with some failed folds warns with class `nestedtune_partial_summary`. A run with no completed fold errors with class `nestedtune_no_completed_folds`. A test fires each condition and asserts its class.
- [x] AC4: Take a `nested_results` whose outer design holds out every data row exactly once. `augment()` returns one row per data row, in the row order of the data. It joins on the prediction columns of the entry for that row in `collect_predictions()`, without the outcome, `.row` and `.config`. A test asserts this for a v-fold design from `nested_resamples()`, a v-fold design from `rsample::nested_cv()`, and a grouped v-fold design.
- [x] AC5: `augment()` refuses an outer design that holds out some data row other than exactly once, with class `nestedtune_augment_rows`. The test uses a repeated v-fold design and a Monte Carlo design. A run without saved predictions gets class `nestedtune_column_not_saved`. A run with no completed fold errors with class `nestedtune_no_completed_folds`. On a run with some failed folds, `augment()` returns the rows those folds held out with missing prediction values and warns with class `nestedtune_partial_summary`. A test asserts each of these.
- [x] AC6: On a `nested_results_set`, `compute_metrics()` and `augment()` stack the result of the same call on each `x$result[[i]]`. The `wflow_id` column comes first. A test asserts row-for-row equality on a set of two workflows.
- [x] AC7: The help page of `compute_metrics.nested_results()` states that the method does not redo the inner selection. Every fold keeps the parameters it selected under the metric of the run. The help page of `augment.nested_results()` states that the predictions come from the outer fits on held-out rows, and not from the final model. The example on each page runs under `devtools::run_examples()`. `NEWS.md` names both methods. `devtools::check()` returns 0 errors and 0 warnings. Every gating prose sweep that `Rscript benchmarks/sweep-prose.R --list-gating` prints passes.

## Coverage

- AC1 → T1
- AC2 → T1
- AC3 → T1
- AC4 → T2
- AC5 → T2
- AC6 → T3
- AC7 → T4

## Tasks

- [x] T1: Write the AC1-AC3 tests first in a new `tests/testthat/test-compute-metrics.R`, then add `compute_metrics.nested_results()` in `R/nested-results-collect.R`. Group the stacked predictions by the recorded fold labels, not by `id` alone, because tune's own method merges repeats. Score each fold with the metric set through yardstick, and build the per-fold shape of `per_fold_metrics()` (`R/nested-results.R`) so that `summarize_folds()` gives the summary. Do not call tune's dotted internals such as `.estimate_metrics()`, because an exported dotted symbol carries no stability promise (LESSONS, M28). Read `tune:::compute_metrics.tune_results()` for the metric-type rule and the survival path through `.pred`.
- [x] T2: Write the AC4-AC5 tests first, then add `augment.nested_results()`. Count how often each data row is held out from the `splits` column, the failed folds included, before any join. Join on `.row` against the data of the first split. Refuse before the join with `nestedtune_augment_rows` when a count is not 1. Read `tune:::augment.tune_results()` and `merge_pred()` for the columns tune drops.
- [x] T3: Write the AC6 test first, then add the two set methods in `R/nested-results-set.R` through `stack_set()`.
- [x] T4: Write the help pages and the examples, add both methods to `_pkgdown.yml`, and add the `NEWS.md` bullet. Run `devtools::document()`, `devtools::run_examples()`, every gating prose sweep and `devtools::check()`.

## Work log

- 2026-09-13: created by /milestone-plan, from the question of whether any features are missing. A comparison of the exports against tune 2.1.0, finetune 1.3.0 and workflowsets 1.1.1 found these two readers, `conf_mat_resampled()` and resample weights without a record.
- 2026-09-13: criteria audit ran in full mode (fresh [O] reader). It returned 10 findings. It found that a bootstrap outer design is refused at entry, so AC5 uses a Monte Carlo design. It added `event_level` to AC1 and the repeated, NA-fold and class-probability probes to AC2. It named the classes in AC3, and added the dropped columns and a grouped design to AC4. It added the no-completed-fold case to AC5. It also scoped AC7 to each page. The repeated-design choice went to the gate.
- 2026-09-13: plan gate chose that `augment()` refuses a design that holds a row out other than once, over averaging the repeated predictions as tune does. The averaging needs an oracle for class probabilities, which the standing `summarize = TRUE` row prices. Falsified by a user who needs `augment()` on a repeated or Monte Carlo design.
- 2026-09-13: plan gate chose a candidate row for `conf_mat_resampled()` over a nestedtune function of the same name. That function hides tune's version when both packages are attached. Falsified by tune declining to make the function a generic while users ask for the nested version.
- 2026-09-13: /milestone-implement started. The branch m092-compute-metrics-augment was cut from origin/main at 3761f45.
- 2026-09-13: T1 done. `compute_metrics.nested_results()` scores each completed row of `.predictions` on its own through the metric set and reuses `per_fold_metrics()` and `summarize_folds()`. `tune::compute_metrics` is re-exported. Two planted defects (event level ignored, repeats pooled by `id`) turned the new tests red. Two guard tests gained lines: the method table in test-nested-tune-bayes-oracles.R and the collect-site regex in test-suite-hygiene.R. Full suite before those fixes: 2 failures, both those guards; the three files pass after.
- 2026-09-13: correction to the T1 line: test-suite-hygiene.R did not change. The new test file stopped using the `x[] <-` form its collect-site regex flags.
- 2026-09-13: T2 done. `augment.nested_results()` counts hold-outs over every fold's split, refuses a count other than 1, and places each fold's `.pred*` columns by `.row` after the outcome. Two planted defects (placing by position, skipping the count) turned the new tests red. The Bayesian method table gained an `augment` line. Full suite: 9980 passed, 0 failed. Both prose sweeps clean.
- 2026-09-13: T3 done. The two set methods call the element method through `stack_set()`. The tests sit in test-nested-workflow-map-readers.R beside the other set readers and reuse its `bind_by_id()` oracle. A planted defect (the set method dropping `summarize`) turned one test red. Full suite: 9995 passed, 0 failed. Both prose sweeps clean.
- 2026-09-13: T4 done. Help pages for both methods, the set page updated from six functions to eight, two `_pkgdown.yml` rows, and a NEWS bullet. Two tests added for documented claims: augment() on a censored run, and the set refusal when a workflow kept no `.predictions`. `run_examples()` ran clean, `check_pkgdown()` found no problems, and all six gating prose sweeps are clean. `devtools::check()`: 0 errors, 0 warnings, 1 NOTE for a top-level `Rplots.pdf` that `run_examples()` wrote this session, since removed.
- 2026-09-13: claim audit: 46 claims read, 6 corrected — R/nested-results-collect.R, tests/testthat/test-compute-metrics.R, tests/testthat/test-augment.R, tests/testthat/test-nested-tune-bayes-oracles.R
- 2026-09-13: the six corrections are comment-only and came after `devtools::check()`. The re-read by the same reader found all six hold. Document gave no new diff, the six sweeps stayed clean, and the three touched test files passed (247 expectations). Status set to review.

## Decisions

- 2026-09-13 (implement gate): `compute_metrics.nested_results()` defaults `event_level` to the level the run recorded, not to tune's `"first"`. A run made with `"second"` is scored with `"second"` again unless the caller says otherwise.
- 2026-09-13 (implement gate): `augment.nested_results()` joins the prediction columns only and adds no `.resid` column. AC4 stays as written.
- 2026-09-13 (implement gate): the metric-type refusal reads the prediction columns the run saved, not the recorded metric set. A run that used tune's default metric set records none.

## Review

Sync: origin/main is at 3761f45, the commit the branch was cut from, so no merge was needed. Evidence below is from 2026-09-13 on branch head ae50ab5.

- AC1 evidence: in test-compute-metrics.R, tests 1, 2 and 4 assert that `compute_metrics()` is identical to `collect_metrics()`. Each test covers `summarize` TRUE and FALSE. The fixtures are regression, classification with a recorded `event_level = "second"`, and censored regression. Test 3 asserts that the default level is the recorded level. All 14 tests in the file pass, with 0 failed and 0 skipped.
- AC2 evidence: test-compute-metrics.R tests 5 and 6 use a repeated v-fold fixture (`id`, `id2`) with fold 4 emptied to NA. Test 5 uses `mae` and `rsq_trad`, and test 6 uses `mn_log_loss` and `brier_class`. Each test asserts that the set shares no metric with the run. Per-fold estimates equal yardstick applied by hand, and only the NA fold scores NA. The summary `mean`, `n` (5) and `std_err` equal the hand values. Both tests pass.
- AC3 evidence: test-compute-metrics.R tests 7, 8, 9, 11, 13 and 14 fire each condition and assert its class. The classes are `nestedtune_column_not_saved`, `nestedtune_bad_metrics` (three bad inputs) and `nestedtune_metric_type_not_saved`. The last one uses `accuracy` on a run that saved only probabilities, with `mn_log_loss` as the passing control. The others are `rlib_error_dots_nonempty`, the warning `nestedtune_partial_summary` and `nestedtune_no_completed_folds`. All pass.
- AC4 evidence: test-augment.R tests 1, 2 and 3 cover a v-fold design from `nested_resamples()`, a v-fold design from `rsample::nested_cv()` and a grouped v-fold design. Each asserts one row per data row, the outcome once and equal to the data, and no `.row`, `.config`, `id` or `id2`. Each also asserts identity with a table built by hand from the data and `collect_predictions()` matched on `.row`. All 11 tests in the file pass, with 0 failed and 0 skipped.
- AC5 evidence: test-augment.R test 6 asserts `nestedtune_augment_rows` on a repeated v-fold design and on a Monte Carlo design. Tests 7 and 8 assert `nestedtune_column_not_saved` and `nestedtune_no_completed_folds`. Test 9 breaks fold 2 and asserts the warning `nestedtune_partial_summary`. It also asserts that the NA rows of `.pred` are exactly the rows fold 2 held out, with one row per data row. All pass.
- AC6 evidence: test-nested-workflow-map-readers.R, the test "compute_metrics() and augment() on a set are bind_rows() of each workflow's call under wflow_id", runs on a set of two workflows. It checks `compute_metrics()` with `summarize` TRUE and FALSE, and `augment()`. For each it asserts `wflow_id` first and identity with `bind_by_id()`, the stack of each `x$result[[i]]` call. It also asserts `2 * nrow(d)` rows from `augment()`. It passes, and so does the set dots refusal test. The file has 0 failed tests.
- AC7 evidence: man/compute_metrics.nested_results.Rd says "The inner selection is not run again. Every fold keeps the parameters it" selected. man/augment.nested_results.Rd says the predictions come from the outer fits on held-out rows and "are not predictions from the final model". `devtools::run_examples()` exited 0 and ran both pages' examples. The NEWS.md bullet names `compute_metrics()` and `augment()`. `devtools::check()` gave 0 errors, 0 warnings and 0 notes in 6m 57s. All six commands from `--list-gating` exited 0 and printed "clean".

Consistency gate:
- `cairn_validate.py` exited 0. Every check passes, with 18 references-staleness advisories that are not gate failures. No DESIGN.md principle changed, so `cairn_impact` does not apply.
- `devtools::document()` needs roxygen2 8.1.0 and the installed version is 8.0.0, so it refused. Run with roxygen2 8.1.0 from CRAN in a scratch library, it left man/ unchanged. It rewrote NAMESPACE with grouped `importFrom()` lines. `parseNamespaceFile()` shows the same imports in both files, so only the layout differs. The NAMESPACE on main has the same one-per-line layout. The rewrite was reverted.
- `pkgdown::check_pkgdown()` found no problems. README.Rmd did not change, and no new top-level file was added. NEWS.md has the bullet and names no milestone. `check()` and the six gating sweeps are clean, as in AC7.

Independent review (three fresh reviewers):
- Blame-history reviewer: no findings. The `frames` argument added to `per_fold_metrics()` keeps its old callers, and the set methods go through `stack_set()`.
- Prior-review reviewer: no findings. The name-clash refusal, the `bind_rows()` oracles and the recorded `event_level` default agree with M65, M44, M35 and M49. The one inline PR comment in the repo is on an unrelated workflow file.
- Diff-bug reviewer: seven findings and two notes, ranked below. None shows an acceptance criterion failing.
  1. `augment()` gives a silent NA to a row missing from a completed fold's `.predictions`, where tune's `merge_pred()` warns. One case is a recipe step that drops rows at predict time. The reviewer confirmed it by deleting one saved row.
  2. The help page says rows of failed folds "hold `NA` in every prediction column". On a censored run `.pred` is a list column, and those entries are `NULL`. The reviewer confirmed it on the survival fixture.
  3. A `.row` repeated inside the saved predictions overwrites without a check. The reviewer confirmed it by planting a repeat.
  4. The set test does not pass `event_level`. A set method that dropped it still passes.
  5. The re-export, the two methods, the `event_level` default and the refusal of repeated designs have no DECISIONS.md entry. Earlier methods on tune generics each had one.
  6. The AC2 class-probability test runs at the first level. A method that scored a new metric set at the wrong level still passes.
  7. `summarize = NA`, `summarize = "no"` and a missing `metrics` give base R errors with no class. This matches `collect_metrics.nested_results()`.
  - Note: the order of `augment()` prediction columns can differ from tune's order for a censored run that saved both `.pred` and `.pred_time`.
  - Note: the prediction-type check reads only the first completed fold.
