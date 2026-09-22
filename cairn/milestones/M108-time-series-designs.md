# M108: Rolling-origin and sliding-window outer designs

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, IP4, GP2
- **Resolves:** —
- **Surface tier:** user-facing — states which outer designs the package supports
- **Branch/PR:** `m108-time-series-designs`

## Goal

The package tests and documents `rolling_origin()` and `sliding_window()` outer designs, which run today with no test and no stated support.

## Scope

**In:** `nested_tune_grid()` and `nested_final_fit()` over `rolling_origin()` and `sliding_window()` outer designs, each with a `rolling_origin()` inner design. `nested_resamples()` building the same designs. `augment()`'s refusal message naming the cause a time-series design has. A D-entry and help text stating the support.

**Out:** `sliding_index()`, `sliding_period()`, and the other five orchestrators over time-series designs. These go to a candidate row added with this plan.

## Acceptance criteria

- [x] AC1: `nested_tune_grid()` runs over an `rsample::nested_cv()` design whose outer and inner resamples are both `rolling_origin()`. Each fold's selection and outer metrics equal those of `reference_nested_loop()` (`tests/testthat/helper-orchestration.R`) on the same design, tested.
- [x] AC2: The AC1 test also passes for a design whose outer resamples are `sliding_window()` and whose inner resamples are `rolling_origin()`.
- [x] AC3: `nested_resamples()` accepts `rolling_origin()` and `sliding_window()` as `outside`, with `rolling_origin()` as `inside`. For both designs, a test asserts that every outer and inner analysis and assessment set matches `rsample::nested_cv()` row for row, as `expect_outer_identical()` and `expect_inner_identical()` check.
- [x] AC4: `nested_final_fit()` on the AC1 result completes, and its `predict()` output equals a reference built in the test. The reference is `tune::tune_grid()`, then the selection rule, then `fit()`. It runs under `fit$tuning_seed` and `fit$fit_seed`. Its inner design is built on the full data from the literal `rolling_origin()` call of the fixture.
- [x] AC5: With `save_pred = TRUE` on the AC1 design, `collect_predictions()` returns one row per outer-assessment row per fold, tested. The AC1 and AC2 designs use `assess = 1`. `augment()` on that result raises `nestedtune_augment_rows`. Where no row is held out twice, the message names the rows no fold held out. It does not name a repeated or Monte Carlo design.
- [x] AC6: A D-entry records support for `rolling_origin()` and `sliding_window()` outer designs under `nested_tune_grid()` and `nested_final_fit()`. The help of `nested_tune_grid()` and `nested_resamples()` names both, and `NEWS.md` describes the support. `devtools::check()` gives 0 errors, 0 warnings, and no note absent from the check of `main` at the branch point.

## Coverage

- AC1 → T1
- AC2 → T1
- AC3 → T2
- AC4 → T3
- AC5 → T4
- AC6 → T5

## Tasks

- [x] T1: Build the two designs as test fixtures with `rsample::nested_cv()`. Set `lookback` on `sliding_window()`, whose default gives a one-row analysis set. Then and write the AC1 and AC2 oracle tests against `reference_nested_loop()`. A mismatch here is a defect to fix, not a test to loosen.
- [x] T2: Run `nested_resamples()` on both designs and write the AC3 split-identity tests. If the constructor refuses either design, lift the refusal only where the D-entry's reasoning covers it.
- [x] T3: Write the AC4 final-fit test and its reference.
- [x] T4: Fit `augment()`'s refusal message (`R/nested-results-collect.R:710`) to the design it refuses, and write the AC5 tests.
- [x] T5: Write the D-entry, the help and `NEWS.md` text, then run `devtools::document()`, the prose sweeps from the verify slot, and `devtools::check()`.

## Work log

- 2026-09-21: created by /milestone-plan. A probe on `main` at `74c0a95` ran `nested_tune_grid()` over a six-fold `rolling_origin()` design to completion.
- 2026-09-21: criteria audit ran in full mode and returned five findings, all fixed above. They were an unnamed oracle, an unset inner design, a split identity the constructor cannot meet, `save_pred` unstated, and a support claim wider than the tests.
- 2026-09-21: plan gate chose a support claim bounded to what is tested over probing every orchestrator and sliding design, because it halves the milestone; falsified by a user report of a failure on a design or orchestrator the claim leaves out.
- 2026-09-21: re-audit in full mode found AC4 silent on seeds and AC5's message wrong for overlapping windows. Both were fixed after the plan commit, with `assess = 1` and a `lookback` note in T1.
- 2026-09-21: implement started on `m108-time-series-designs`. Question gate chose an `augment()` message giving the count and the row numbers, shortened by cli. Test metrics are `rmse` and `mae`, since `rsq` is `NA` on a one-row assessment set.
- 2026-09-21: T1 checkpoint, not checked off. The AC1/AC2 oracle tests pass alone (20 expectations). A planted swap of the two designs fails folds 2 and 3. The full suite is still running.
- 2026-09-21: T1 done. `devtools::test()` finished clean with no failure.
- 2026-09-21: T2 and T3 done in one commit, because the suite run for T2 also read the T3 test. `nested_resamples()` accepted both designs, so no refusal was lifted. Planted defects (inner `skip`, outer `lookback`, a wrong inner design and candidate in the final-fit reference) each failed. Suite clean.
- 2026-09-21: T4 checkpoint, not checked off. `augment()` names the rows no fold held out when none is held out twice. The AC5 tests failed three times before the fix and pass after it. The `augment()` help is updated, and the D-071 draft for T5 is written. The full suite is still running.
- 2026-09-21: T4 done. `devtools::test()` exited 0 with no failure. `document()` and both prose sweeps are clean.
- 2026-09-21: T5 checkpoint, not checked off. The help of `nested_tune_grid()` (a section the other orchestrators inherit) and of `nested_resamples()` names both designs, and `NEWS.md` has two entries. All six gating sweeps are clean. `devtools::check()` on the branch and on `main` at `6f4795a` is still running.
- 2026-09-21: claim audit found that the help, the NEWS entry and D-071 claim a `nested_final_fit()` test on the sliding-window design that did not exist. Minor amendment inside T3: a sliding-window final-fit test is added, sharing its body with the rolling-origin one. The test file passes (133 expectations).
- 2026-09-21: claim audit: 24 claims read, 3 corrected — NEWS.md, R/nested-resamples.R, R/nested-tune-grid.R
- 2026-09-21: T5 done. `devtools::check()` on the final branch tree gives 0 errors, 0 warnings and 0 notes, the same as `main` at `6f4795a`. Status set to review.

## Decisions

## Review

Evidence gathered 2026-09-21 on `m108-time-series-designs` at `93f3e4c`, with `origin/main` at `6f4795a`, the branch point (no sync merge needed).

- AC1: `test-time-series-designs.R` run alone gives 133 expectations, 0 failed, 0 skipped. The test "a rolling-origin design matches a hand-rolled reference loop" has 10 expectations. It runs `nested_tune_grid()` on `ts_rolling_nested()`, a `rsample::nested_cv()` design with `rolling_origin()` outer and inner. It compares each fold's `.metrics`, `.selected` and seeds with `reference_nested_loop()` by `expect_identical()`.
- AC2: in the same run, "a sliding-window design matches a hand-rolled reference loop" passes its 10 expectations. It uses `ts_sliding_nested()`, a `sliding_window()` outer design with a `rolling_origin()` inner design, and makes the same comparison as AC1.
- AC3: in the same run, "rolling-origin splits match rsample::nested_cv()" (54 expectations) and "sliding-window splits match rsample::nested_cv()" (42 expectations) pass. Each builds the design with `nested_resamples()` and compares it to the fixture by `expect_outer_identical()` and `expect_inner_identical()`.
- AC4: in the same run, "the final fit on a rolling-origin design matches a hand-rolled reference" passes 3 expectations. It calls `nested_final_fit()` on the AC1 run (seed 20). The reference runs `tune::tune_grid()`, `tune::select_best()` on `rmse`, and `fit()` under `final$tuning_seed` and `final$fit_seed`. Its inner design is the fixture's literal `rolling_origin()` call on the full data. The test asserts identical inner splits, an identical selection and identical `predict()` output. The sliding-window version also passes 3 expectations.
- AC5: both fixtures use `assess = 1` (`helper-orchestration.R`). In the same run, "collect_predictions() returns each outer-assessment row once per fold" passes 4 expectations. It runs the AC1 design with `save_pred = TRUE` and matches each fold's `.row` values to that fold's `rsample::complement()`. "augment() refuses a rolling-origin result and names the rows never held out" passes 7 expectations. It asserts class `nestedtune_augment_rows`, a message naming the 87 rows by count, first three and last two, and no "repeated" or "Monte Carlo" text.
- AC6: D-071 in `cairn/DECISIONS.md` records the support. `man/nested_tune_grid.Rd` and `man/nested_resamples.Rd` each name `rolling_origin()` and `sliding_window()`. `NEWS.md` has two entries for the change. `devtools::check()` on the branch gives Status OK with 0 errors, 0 warnings and 0 notes, and its tests pass. With no note on the branch, no note is absent from the `main` check at `6f4795a`.

Consistency gate:
- `cairn_validate.py` exits 0. All checks pass, with 18 references-staleness advisories that predate this branch.
- No `DESIGN.md` principle changed, so `cairn_impact.py` is skipped.
- `devtools::document()` gives no diff. `pkgdown::check_pkgdown()` finds no problems. README files are untouched. No new top-level file.
- The six gating prose sweeps from `--list-gating` each exit 0.

Independent review: three fresh reviewers. The blame-history reviewer found nothing. The prior-review reviewer found no prior finding the diff contradicts. The diff reviewer found no criterion failing and ranked 11 findings, listed here with dispositions set at the merge gate:
- R1: an overlapping `sliding_window()` design (for example `assess_stop = 3, step = 1`) holds rows out twice, so `augment()` still names a repeated or Monte Carlo design as the cause. The help, NEWS and D-071 limit the new message to designs with no row held out twice.
- R2: no test runs `augment()` on a `sliding_window()` result, though its help says that design is refused.
- R3: the new refusal test does not assert the condition call, as `test-augment.R` does for the old branch.
- R4: the two final-fit tests give identical fits, because the final fit re-runs only the inner design. The sliding-window test shows that the result is accepted, not a separate number.
- R5: the final-fit test uses a deterministic workflow, so it cannot detect a final fit that ignores its seeds.
- R6: each new result has one oracle type (live reference), against the DESIGN convention of two. No new computation was added.
- R7: with `assess = 1`, the prediction test checks one row per fold, so it cannot catch a reordering inside a fold.
- R8: `[augment()][augment.nested_results]` in `R/nested-tune-grid.R:112` renders without code font in five help pages.
- R9: the final-fit tests call `nested_tune_grid()` without `memoised()`, which adds two full nested runs per suite run.
- R10: the new message says "exactly once" and then "No outer fold holds out 87 rows". The reviewer judged it accurate.
- R11: the old branch still prints "holds out 0 rows never" when no row is left out. This predates the branch.
