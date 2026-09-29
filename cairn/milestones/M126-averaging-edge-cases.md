# M126: Edge cases of averaged predictions

- **Status:** review
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

- [x] AC1: `collect_predictions(summarize = TRUE)` refuses a run with class `nestedtune_collect_predictions_predictions` when a completed fold's saved `.row` column does not match its held-out rows. A match holds each row the fold held out exactly once, and no other row. The message names the fold. A test plants each of the five `row_mismatch_cases` from `helper-predictions.R` in one fold of a `nested_results`. It asserts the class and the fold label in the message. A test plants one case in one workflow of a `nested_results_set` and asserts the class. A test asserts that `collect_predictions(summarize = FALSE)` on the same planted run returns the per-fold table without a condition.
- [x] AC2: Two readers average: `collect_predictions(summarize = TRUE)`, and `augment()` on a design holding some row out more than once. Both refuse three shapes of saved predictions with class `nestedtune_summarize_columns`. Here an outcome column is a column that is not `.pred*`, `.row`, `.config`, `.case_weights`, `.iter`, `.eval_time` or a fold label. Shape one has two or more factor outcome columns. Shape two has a saved `.pred_class` and no factor outcome column. Shape three has a censored `.pred` entry that is not NULL and has no `.eval_time` column. Tests plant each shape and assert the class from both readers. The existing oracle tests in `test-collect-predictions-summarize.R` and `test-augment.R` pass unchanged. So the regression, classification and censored runs they cover are not refused.
- [x] AC3: In a censored run's averaged `.pred`, a NULL entry is left out of its row's average. A row whose every entry is NULL holds NULL. A table whose every `.pred` entry is NULL averages without error to NULL entries. Tests plant three runs. A row with one NULL entry is compared with a base R average of its non-NULL entries. A row whose every entry is NULL, beside rows that have entries, is asserted NULL. A table whose every entry is NULL is asserted all NULL.
- [x] AC4: A data column named like a prediction column is refused with class `nestedtune_collect_name_collision`. On a design holding some row out more than once, `augment()` raises this refusal before any averaging refusal. One test plants that collision together with a saved `.pred_quantile` column, and another plants it together with AC2's shape two. Both assert the collision class.
- [x] AC5: Tests assert four paths the M124 and M125 reviews found untested. `collect_predictions(summarize = TRUE)` and `augment()` on a `nested_results_set` whose workflow saved `.pred_quantile` refuse with class `nestedtune_summarize_quantile`. A planted `.pred_linear_pred` column averages to each row's mean with missing values ignored, compared with a base R average. A row whose probabilities average to a tie, where one fold's probability is missing, takes the first tied level. On a repeated censored design with a failed fold, `augment()` gives NULL in `.pred` for a row only failed folds held out.
- [x] AC6: `benchmarks/averaging-speed.R` builds three stacked tables in which each of 33,334 data rows is held out by 3 folds. The first has 10 class probabilities and a class, the second a class alone, the third a censored `.pred` and `.pred_time`. On each table, the branch's `average_fold_predictions()` output agrees with a frozen copy of the M124 code held in the script. Agreement is `all.equal(tolerance = 1e-12)` on numeric columns and `identical()` on factor columns. On the first table, the branch's median of five runs is at most one quarter of the frozen copy's. The script's output is logged in the work log.
- [x] AC7: The `collect_predictions.nested_results` help page, in "Averaging across the folds", states the AC1 and AC2 refusals and the AC3 NULL rule. The `NEWS.md` bullet for `summarize` states them too. The "Designs and folds refused" section of the `augment.nested_results` help page states the AC2 refusal, and that the name collision is checked before averaging. `devtools::test()` passes, `devtools::check()` reports 0 errors, 0 warnings and 0 notes, and every command `Rscript benchmarks/sweep-prose.R --list-gating` prints runs clean.
- [x] AC8: The `collect_predictions.nested_results` and `augment.nested_results` help pages state that a metric computed on averaged predictions describes an average of several fitted models, not the tuning procedure. So it is not the nested estimate. Both pages name `collect_metrics()` for that estimate.

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
- [x] T4: Write `benchmarks/averaging-speed.R`. Its frozen M124 copy includes `class_from_probs()`, `class_by_vote()` and `average_survival()`. Run it for the baseline. Rewrite the per-row averages with grouped sums (`rowsum()` or `vctrs` grouping) across the numeric, probability, vote and survival paths. Re-run T1's tests and the script, and log the medians.
- [x] T5: Append a D-entry that extends D-090 with the AC1 check, the AC2 refusal and the AC3 NULL rule. It states that the NULL rule has one oracle, because it decides only which entries enter an average that M124 checked against two. Add the `DESIGN.md` Known issues entry named in Out. Add the AC8 sentence to both help pages. Update the help section, the `augment.nested_results` refusal section, and the `summarize` bullet in `NEWS.md`. Run the prose sweeps.
- [x] T6: Run `devtools::document()`, `devtools::test()`, `devtools::check()` and `pkgdown::check_pkgdown()`.

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
- 2026-09-28: T4 baseline, `Rscript benchmarks/averaging-speed.R` on R 4.6.1 aarch64-apple-darwin23, 100,002 stacked rows per table, before the rewrite: probabilities agree TRUE, frozen 0.795 s, branch 0.815 s; class agree TRUE, 0.028 s and 0.028 s; censored agree TRUE, 1.155 s and 1.322 s.
- 2026-09-28: T4 done. `mean_by()` averages with `rowsum()`, all probability columns in one matrix call, `median_by()` takes one sort, `class_from_probs()` uses `max.col()`, and `average_survival()` uses `list_unchop()` and `vec_chop()`. The first rewrite called `rowsum()` once per column and reached a ratio of 0.202. Script output after: probabilities agree TRUE, frozen 0.771 s, branch 0.044 s, ratio 0.057; class agree TRUE, 0.028 s and 0.028 s, ratio 1.000; censored agree TRUE, 1.143 s and 0.470 s, ratio 0.411. The summarize, augment and time-series test files pass.
- 2026-09-28: T5 done. D-094 extends D-090 and D-092's order of refusals. `DESIGN.md` Known issues gains the two unrefused shapes. The `collect_predictions` help states the AC1 and AC2 refusals, the NULL rule and the AC8 sentence, the `augment` help states the AC2 refusal, the collision order and the AC8 sentence, and the `NEWS.md` bullet states them. `devtools::document()` rewrote the two Rd files, and all six gating prose sweeps print clean.
- 2026-09-28: correction to the T5 line: the manual sweep loop passed `--roxygen --spans` and `--roxygen --plain` as one zsh word each, so those two sweeps did not run. The full `devtools::test()` run (13,150 passed, 4 failed) caught them in `test-sweep-prose.R`: two semicolons in the new help list and a sentence with five code spans. Fixed, and each gating command now runs clean, invoked through `bash -c`.
- 2026-09-28: claim audit: 65 claims read, 2 corrected — NEWS.md (the row-check wording now says exactly the rows each once, and "two or more" factor outcome columns). Also tightened, not counted: the `mean_by()` timing comment names the probability table, and the `median_by()` comment states its last-bit difference from `stats::median()` on even groups.
- 2026-09-28: T6 done. `devtools::document()` is current, `pkgdown::check_pkgdown()` finds no problems, and `devtools::check()` at `85aaa2de` gives 0 errors, 0 warnings and 0 notes, its test run included. Status set to review.
- 2026-09-28: review return 1 (defect): AC6 fails. `benchmarks/averaging-speed.R` deals folds so one fold can hold a row more than once, and 25,971 of 33,334 rows are not held out by 3 folds. Fix the fold assignment so each row is in each of the 3 folds once, re-run the script, and log its output. AC1 to AC5, AC7, AC8 and the gate pass (Review section). Status back to in-progress.
- 2026-09-28: review return 1 fixed. `benchmarks/averaging-speed.R` now stacks the 3 folds one after another, each holding every row once in its own random order, and stops unless every row is held out by 3 distinct folds. That guard stops on the old dealing (7,363 of 33,334 rows). Script output on R 4.6.1 aarch64-apple-darwin23: 33,334 of 33,334 rows held out by 3 distinct folds. Probabilities agree TRUE, frozen 0.559 s, branch 0.030 s, ratio 0.054. Class agree TRUE, 0.018 s and 0.018 s, ratio 1.000. Censored agree TRUE, 0.784 s and 0.359 s, ratio 0.458. No `R/` file changed. Status set to review.
- 2026-09-28: review gate, pass 2: the user chose to fix findings 1, 2, 5, 9, 10 and 11 on the branch before approval (Review section). Findings 3, 4 and 8 went to one candidate row. After the fix, `mean_by()` equals `mean()` on 2,000 random groups, and the benchmark ratio is 0.090.

## Decisions

## Review

Evidence gathered 2026-09-28 at `73a4fc23`, the branch current with `origin/main` (`cc74e2a5`), R 4.6.1 aarch64-apple-darwin23. `devtools::test()`: 0 failed, 0 warnings, 0 skipped, 13,154 passed.

- AC1: pass. `test-collect-predictions-summarize.R` loops over the five `row_mismatch_cases`, planting each in fold 2 of a `nested_results`. Each asserts class `nestedtune_collect_predictions_predictions` and the call `collect_predictions`. It asserts the fold 2 label in the message and no other fold label. It asserts that `summarize = FALSE` returns a tibble with no condition. The set test plants `"repeated"` in one workflow and asserts the class, and the per-fold call raises no condition. All pass in the suite run above.
- AC2: pass. `expect_shape_refused()` calls both readers on one planted run. It asserts class `nestedtune_summarize_columns` and each reader's own call name. Shape one adds a copy of the factor outcome. Shape two removes the outcome in one plant and turns it into text in another. Shape three drops `.eval_time` from one censored entry. The fixtures hold every row out twice, so `augment()` averages. The oracle tests that existed before the branch are unchanged in the diff and pass.
- AC3: pass. Three plants on the censored fixture. One NULL entry in a row held out twice gives the base R mean of the kept entry, per `.eval_time`, by `hand_survival()`. A row whose two entries are NULL holds NULL, and every other row holds a data frame. A table whose every entry is NULL gives NULL for each held-out row, with no error.
- AC4: pass. Two tests in `test-augment.R` on a design that holds rows out twice. The first plants a `.pred` data column beside a saved `.pred_quantile` column. The second first shows that a `.pred_class` beside a numeric outcome is refused with `nestedtune_summarize_columns`, then adds the `.pred` data column. Both assert `nestedtune_collect_name_collision`.
- AC5: pass. A set whose first workflow saved `.pred_quantile` is refused with `nestedtune_summarize_quantile` by both readers. A planted `.pred_linear_pred` with missing values equals `tapply(mean, na.rm = TRUE)` per row, with no missing result. A 0.5 and 0.5 tie with one missing probability, in either fold order, takes the first level. On a repeated censored design with two failed folds, the rows only those folds held out are exactly the NULL `.pred` rows.
- AC6: fail. `Rscript benchmarks/averaging-speed.R` printed: probabilities agree TRUE, frozen 0.771 s, branch 0.045 s, ratio 0.058. Class agree TRUE, 0.029 s and 0.030 s. Censored agree TRUE, 1.151 s and 0.471 s. Agreement, tolerance and the median of five meet the criterion. The tables do not. The script shuffles `rep(seq_len(33334), 3)` and deals folds 1, 2, 3 in turn. So each row is held out 3 times, but not always by 3 folds. With seed 126, 7,363 rows are held out by 3 folds and 22,190 by 2 folds. One fold holds each of the other 3,781 rows 3 times. A fold that holds a row twice is a shape tune does not produce, and AC1 refuses it.
- AC7: pass. The "Averaging across the folds" section of the `collect_predictions.nested_results` Rd states the row check and its class. It states the three shapes, their class and the NULL rule. The `NEWS.md` `summarize` bullet states all three. The "Designs and folds refused" section of the `augment.nested_results` Rd states the shape refusal. It says the collision comes "before either refusal of the average". `devtools::test()` passed as above. `devtools::check()` gave 0 errors, 0 warnings and 0 notes in 11 min 5 s. All six commands `--list-gating` prints print clean, each run through `bash -c`.
- AC8: pass. Both Rd files say a metric on the averages "describes an average of several fitted models, not the tuning procedure". Both say "it is not the nested estimate". Both name `collect_metrics()` for that estimate.

Gate: `cairn_validate.py` exits 0 and all checks pass. It prints 19 advisory warnings: the 8-criterion split tripwire and 18 references staleness notices. `devtools::document()` leaves no diff. `pkgdown::check_pkgdown()` finds no problems. `NEWS.md` has the entry. The one new top-level path, `benchmarks/`, is already in `.Rbuildignore`. README is not touched. No `DESIGN.md` principle changed, so `cairn_impact.py` is skipped.

Result: AC6 fails, so status returns to in-progress before the independent review.

### Pass 2

Evidence gathered 2026-09-28 at `91b33de9`, the branch current with `origin/main` (`cc74e2a5`), R 4.6.1 aarch64-apple-darwin23. Since `73a4fc23`, only `benchmarks/averaging-speed.R` and this file changed. `devtools::test()`: 0 failed, 0 warnings, 0 skipped, 13,154 passed.

- AC1: pass. The tests the pass 1 line names are unchanged and pass in the suite run above.
- AC2: pass. The tests the pass 1 line names are unchanged and pass in the suite run above. The oracle tests that existed before the branch are unchanged in the diff and pass.
- AC3: pass. The three plants the pass 1 line names are unchanged and pass in the suite run above.
- AC4: pass. The two `test-augment.R` tests the pass 1 line names are unchanged and pass in the suite run above.
- AC5: pass. The four tests the pass 1 line names are unchanged and pass in the suite run above.
- AC6: pass. The script now stacks 3 folds, each a random order of all 33,334 data rows. It stops unless every row is held out by 3 distinct folds. It printed 33,334 of 33,334 rows held out by 3 distinct folds, 100,002 stacked rows per table. The three tables are 10 probabilities with a class, a class alone, and a censored `.pred` with `.pred_time`. Agreement uses `all.equal(tolerance = 1e-12)` on double columns and the survival entries, `identical()` otherwise. Output: probabilities agree TRUE, frozen 0.787 s, branch 0.042 s, ratio 0.053. Class agree TRUE, 0.025 s and 0.026 s. Censored agree TRUE, 1.103 s and 0.472 s. Each time is the median of five runs, and 0.053 is under 0.25. The implement-side run is in the work log.
- AC7: pass. The two Rd sections and the `NEWS.md` `summarize` bullet, read again at `91b33de9`, state what the pass 1 line names. `devtools::test()` passed as above. `devtools::check()` gave 0 errors, 0 warnings and 0 notes. All six commands `--list-gating` prints exit 0 and print clean, each run through `bash -c`.
- AC8: pass. Both Rd files, read again at `91b33de9`, hold the three phrases the pass 1 line quotes.

Gate: `cairn_validate.py` exits 0, with advisory warnings for the split tripwire and 18 references staleness notices. `devtools::document()` leaves no diff. `pkgdown::check_pkgdown()` finds no problems. `NEWS.md` has the entry. The new path `benchmarks/averaging-speed.R` sits under `benchmarks/`, already in `.Rbuildignore`. README is not touched. No `DESIGN.md` principle changed, so `cairn_impact.py` is skipped.

Independent review, three fresh readers on `git diff main..HEAD`. The prior-review reader found no regression of an earlier review finding and no real PR threads on the touched files. The blame-history reader found no regression. It noted two limits the plan accepted: the two unrefused shapes in Known issues, and the last-bit rounding of the grouped sums. The diff-bug reader reported 13 findings, ranked:

1. `mean_by()` (`R/nested-results-collect.R:446`) sums with `rowsum()` and skips the second pass `mean()` takes. Probabilities with equal true means can round 1 ulp apart, so `max.col()` gives the tie to the wrong level. Reproduced here: `.pred_a = c(0.6, 0.4, 0.2)`, `.pred_b = 0.2`, `.pred_c = c(0.2, 0.4, 0.6)` gives a 0.39999999999999996669 and c 0.40000000000000007772, class c. `mean()` gives both 0.40000000000000002220, and M124 gave class a. The help says a tie goes to the first level.
2. The AC5 tie test uses 0.5 values, exact in binary, so it cannot see finding 1.
3. The benchmark's agreement never reaches the even-group median or a missing `.pred_time`, and its censored entries share one `.eval_time` set with no NULL entry.
4. A censored row whose entries are 0-row tibbles now holds NULL, where M124 gave a 0-row tibble. The help names only NULL entries.
5. `mean_by()` takes `n` and never uses it, so an empty group shortens its output with no error. No current caller makes one.
6. The grouped sums overflow to `Inf` for values near 1e308, where `mean()` does not.
7. The AC6 agreement ran only on aarch64 macOS, where `long double` equals `double`. On x86_64 `mean()` sums in 80 bits, so the gap can be larger.
8. `collect_predictions()` warns about a partial run before it refuses a bad shape, so the order of warning and refusal differs by reader and by check.
9. The row-check message says `collect_predictions()` needs exact rows, but names neither `summarize = TRUE` nor the per-fold table as the way out.
10. The `NEWS.md` `augment()` bullet does not name the new shape refusal or the collision order. AC7 binds only the `summarize` bullet.
11. The outcome-column paragraph says "not outcome columns either" twice. `NEWS.md` lines 13 and 14 run past 80 characters. The NEWS bullet leaves out "that is not NULL" for shape three.
12. `factor_outcomes()` and `outcome_column()` each hard-code the same list of non-outcome columns.
13. AC6 was unticked with a fail line. Pass 2 above records its new evidence.

Triage at the gate, 2026-09-28, the user choosing to fix first:
- Finding 1: fix now. `mean_by()` adds `mean()`'s second pass, skipped where the first estimate is not finite.
- Finding 2: fix now. A new test plants `.pred_event = c(0.05, 0.35)` and `.pred_other = c(0.2, 0.2)`. It fails on the code before the fix, with class other, and passes after it.
- Finding 5: fix now. `mean_by()` fills each group `1:n` and gives `NaN` to a group with no rows.
- Finding 9: fix now. Under `collect_predictions`, the message names `summarize = TRUE` and points to `summarize = FALSE`, and the AC1 tests assert that.
- Findings 10 and 11: fix now, in `NEWS.md` and the roxygen paragraph.
- Findings 3, 4 and 8: follow-up, one ROADMAP candidate row.
- Finding 6: rejected. Predictions near 1e308 do not occur.
- Finding 7: rejected. It is an untested platform, and the fix narrows the gap there.
- Finding 12: rejected. `outcome_column()` held the list before the branch, and the two lists agree.
- Finding 13: no change needed. Pass 2 re-verified AC6.
