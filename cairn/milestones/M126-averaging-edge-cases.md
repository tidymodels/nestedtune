# M126: Edge cases of averaged predictions

- **Status:** in-progress
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP2, GP3, GP4
- **Resolves:** —
- **Surface tier:** user-facing — it changes what two exported readers refuse and how fast they average
- **Branch/PR:** m126-averaging-edge-cases

## Goal

`collect_predictions(summarize = TRUE)` and `augment()` refuse by name three saved-prediction shapes their shared average misreads, and on a benchmark table the average runs in at most a quarter of its M124 time.

## Scope

**In:** the averaging edge cases in the ROADMAP candidate row this milestone absorbs. M124's review left O1, O2, O5 to O7 and S2 there, and M125's left O1, O8 and O9. `collect_predictions(summarize = TRUE)` runs the row-match check `augment()` and `compute_metrics()` run. `average_fold_predictions()` refuses a table with no single factor outcome beside a saved class, or with two factor outcomes, and a censored `.pred` entry lacking `.eval_time`. A NULL censored `.pred` entry is left out of its row's average. `augment()` checks name collisions before it averages. The averaging is rewritten with grouped sums, checked against a frozen copy of the M124 code by a benchmark script. The untested paths the row lists get tests. One D-entry extends D-090. The help pages and `NEWS.md` state the changes.

**Out:** `collect_predictions(summarize = FALSE)` keeps its output and runs no new check (plan gate). Averaging quantile predictions stays refused, in its own candidate row (D-091). Two shapes still average without renormalizing. One is a probability-only run whose outcome column was removed, where no saved column names the probability columns. The other is an outcome whose levels do not match the saved `.pred_*` names. T5 records both as one `DESIGN.md` Known issues entry. Checking that `summarize` is one `TRUE` or `FALSE` stays rejected (M124 review O4).

## Acceptance criteria

- [ ] AC1: `collect_predictions(summarize = TRUE)` refuses a run with class `nestedtune_collect_predictions_predictions` when a completed fold's saved `.row` column does not match its held-out rows. A match holds each row the fold held out exactly once, and no other row. The message names the fold. A test plants each of the five `row_mismatch_cases` from `helper-predictions.R` in one fold of a `nested_results`. It asserts the class and the fold label in the message. A test plants one case in one workflow of a `nested_results_set` and asserts the class. A test asserts that `collect_predictions(summarize = FALSE)` on the same planted run returns the per-fold table without a condition.
- [ ] AC2: Two readers average: `collect_predictions(summarize = TRUE)`, and `augment()` on a design holding some row out more than once. Both refuse three shapes of saved predictions with class `nestedtune_summarize_columns`. Here an outcome column is a column that is not `.pred*`, `.row`, `.config`, `.case_weights`, `.iter`, `.eval_time` or a fold label. Shape one has two or more factor outcome columns. Shape two has a saved `.pred_class` and no factor outcome column. Shape three has a censored `.pred` entry that is not NULL and has no `.eval_time` column. Tests plant each shape and assert the class from both readers. The existing oracle tests in `test-collect-predictions-summarize.R` and `test-augment.R` pass unchanged. So the regression, classification and censored runs they cover are not refused.
- [ ] AC3: In a censored run's averaged `.pred`, a NULL entry is left out of its row's average. A row whose every entry is NULL holds NULL. A table whose every `.pred` entry is NULL averages without error to NULL entries. Tests plant three runs. A row with one NULL entry is compared with a base R average of its non-NULL entries. A row whose every entry is NULL, beside rows that have entries, is asserted NULL. A table whose every entry is NULL is asserted all NULL.
- [ ] AC4: A data column named like a prediction column is refused with class `nestedtune_collect_name_collision`. On a design holding some row out more than once, `augment()` raises this refusal before any averaging refusal. One test plants that collision together with a saved `.pred_quantile` column, and another plants it together with AC2's shape two. Both assert the collision class.
- [ ] AC5: Tests assert four paths the M124 and M125 reviews found untested. `collect_predictions(summarize = TRUE)` and `augment()` on a `nested_results_set` whose workflow saved `.pred_quantile` refuse with class `nestedtune_summarize_quantile`. A planted `.pred_linear_pred` column averages to each row's mean with missing values ignored, compared with a base R average. A row whose probabilities average to a tie, where one fold's probability is missing, takes the first tied level. On a repeated censored design with a failed fold, `augment()` gives NULL in `.pred` for a row only failed folds held out.
- [ ] AC6: `benchmarks/averaging-speed.R` builds three stacked tables in which each of 33,334 data rows is held out by 3 folds. The first has 10 class probabilities and a class, the second a class alone, the third a censored `.pred` and `.pred_time`. On each table, the branch's `average_fold_predictions()` output agrees with a frozen copy of the M124 code held in the script. Agreement is `all.equal(tolerance = 1e-12)` on numeric columns and `identical()` on factor columns. On the first table, the branch's median of five runs is at most one quarter of the frozen copy's. The script's output is logged in the work log.
- [ ] AC7: The `collect_predictions.nested_results` help page, in "Averaging across the folds", states the AC1 and AC2 refusals and the AC3 NULL rule. The `NEWS.md` bullet for `summarize` states them too. The "Designs and folds refused" section of the `augment.nested_results` help page states the AC2 refusal, and that the name collision is checked before averaging. `devtools::test()` passes, `devtools::check()` reports 0 errors, 0 warnings and 0 notes, and every command `Rscript benchmarks/sweep-prose.R --list-gating` prints runs clean.
- [ ] AC8: The `collect_predictions.nested_results` and `augment.nested_results` help pages state that a metric computed on averaged predictions describes an average of several fitted models, not the tuning procedure. So it is not the nested estimate. Both pages name `collect_metrics()` for that estimate.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T3
- AC3 → T1, T3
- AC4 → T1, T3
- AC5 → T1
- AC6 → T4
- AC7 → T5, T6
- AC8 → T5

## Tasks

- [x] T1: Write the AC1 to AC5 tests first, in `tests/testthat/test-collect-predictions-summarize.R` and `test-augment.R`, reusing `helper-predictions.R`. Run them and record which fail. The AC5 tests cover existing behavior, so record the ones that pass at once.
- [x] T2: Call `check_predictions_rows()` from `collect_predictions.nested_results()` when `summarize` is `TRUE` (`R/nested-results-collect.R:306`), adding `"collect_predictions"` to its `verb` choices at `:1005`. Confirm the set method re-signals it naming the workflow.
- [x] T3: In `average_fold_predictions()` (`:342`) and `average_survival()` (`:462`), add the AC2 refusal and the AC3 NULL rule. The refusal takes a `verb` and words its message per reader, as `check_no_quantile()` does. In `augment.nested_results()` (`:909`), move the collision check ahead of `check_no_quantile()` and the averaging, reading the prediction column names from the saved tables.
- [ ] T4: Write `benchmarks/averaging-speed.R`. Its frozen M124 copy includes `class_from_probs()`, `class_by_vote()` and `average_survival()`. Run it for the baseline. Rewrite the per-row averages with grouped sums (`rowsum()` or `vctrs` grouping) across the numeric, probability, vote and survival paths. Re-run T1's tests and the script, and log the medians.
- [ ] T5: Append a D-entry that extends D-090 with the AC1 check, the AC2 refusal and the AC3 NULL rule. It states that the NULL rule has one oracle, because it decides only which entries enter an average that M124 checked against two. Add the `DESIGN.md` Known issues entry named in Out. Add the AC8 sentence to both help pages. Update the help section, the `augment.nested_results` refusal section, and the `summarize` bullet in `NEWS.md`. Run the prose sweeps.
- [ ] T6: Run `devtools::document()`, `devtools::test()`, `devtools::check()` and `pkgdown::check_pkgdown()`.

## Work log

- 2026-09-28: created by /milestone-plan, absorbing the `[high]` averaging edge-case candidate row.
- 2026-09-28: criteria audit (full mode, fresh [O] reader) returned 9 findings. Fixed at the gate: AC6 agreement uses a 1e-12 tolerance, not `identical()`, because grouped sums differ from `mean()` by up to 5.6e-17. AC6 tables hold each row out 3 times and cover the vote and survival paths. The Goal names three shapes and one benchmark table. AC1 plants all five row-mismatch cases and asserts the fold label. AC3 names its three plants, AC4 adds a shape-two plant, and AC7 binds the `augment()` help. T4's frozen copy names its helpers, and Out adds the level-mismatch shape. Put to the gate: the one-oracle NULL rule.
- 2026-09-28: plan gate chose the grouped-sum speed rewrite inside M126 over a separate milestone, because it rewrites the same function the checks change. Falsified by the rewrite failing AC6's agreement on a table tune can produce.
- 2026-09-28: plan gate chose the row check under `summarize = TRUE` only over every call, because the per-fold table then stays as it is. Falsified by a user report of a per-fold table with mismatched rows misleading an analysis.
- 2026-09-28: plan gate chose named refusals for the three shapes over documenting the silent average, the stance `check_predictions_rows()` takes toward edited objects. Falsified by tune producing one of the shapes from a real run.
- 2026-09-28: plan gate chose one oracle for the NULL rule over adding tune's average as a second. Falsified by tune's average of a planted NULL entry differing from the base R one.
- 2026-09-28: user asked, before implementation, for a help warning against scoring averaged predictions as the nested estimate. AC8 added, mapped to T5.
- 2026-09-28: criteria audit of AC8 (full mode, fresh [O] reader). The first draft said such a score can be better than one model's and backed it with an RMSE test. On the `fixed_workflow` fixture the averaged RMSE fell below `collect_metrics()`'s on seed 41 but not on 2 of seeds 1 to 20, so the direction is not fixed. AC8 now states only that the score describes an average of fitted models, and needs no numeric test.
- 2026-09-28: T1 done. The new tests fail as expected: the five AC1 mismatch cases and the set case, the four AC2 plants, two of the three AC3 plants (the NULL row gets a 0-row tibble, the all-NULL table raises vctrs' internal error), and both AC4 tests (the quantile refusal and no refusal come first). The first AC3 plant and all four AC5 tests pass at once, as they cover existing behavior. The AC5 censored test first failed because edition 3's `expect_warning()` returns the warning, not the value, which the test now avoids.
- 2026-09-28: T2 done. `collect_predictions(summarize = TRUE)` runs `check_predictions_rows()` before the quantile check, and the six AC1 tests pass, the set case included.
- 2026-09-28: T3 done. `check_average_columns()` refuses the three shapes with `nestedtune_summarize_columns`, reading factor outcomes through the new `factor_outcomes()`. `average_survival()` gives NULL to a row with no entries and returns early when every entry is NULL. `augment()` reads the collision off the saved tables' names before the quantile check and the average. Both test files pass.

## Decisions

## Review
