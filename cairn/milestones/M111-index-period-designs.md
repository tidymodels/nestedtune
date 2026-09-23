# M111: Index-based and period-based sliding outer designs

- **Status:** review
- **Priority:** normal
- **Depends on:** M110
- **Driving RR:** —
- **Principles touched:** IP1, IP4, GP1, GP2
- **Resolves:** —
- **Surface tier:** user-facing — states which outer designs the package supports, and changes an error message
- **Branch/PR:** m111-index-period-designs

## Goal

`sliding_index()` and `sliding_period()` outer designs are tested and documented under the six orchestrators and `nested_final_fit()`.

## Scope

**In:** Two new fixtures in `tests/testthat/helper-orchestration.R`. `make_ts_data()` is `make_reg_data()` plus a `date` column of 90 consecutive days. `ts_index_nested()` has outer `sliding_index(index = date, lookback = 59, assess_stop = 1, step = 10)`. `ts_period_nested()` has outer `sliding_period(index = date, period = "week", lookback = 8)`. Both have inner `rolling_origin(initial = 40, assess = 1, skip = 4)`. The workflow recipe names `x1` to `x4`, so `date` is not a predictor. The six orchestrators and `nested_final_fit()` on both designs. `nested_resamples()` building both. The `augment()` message for a sliding design whose assessment sets overlap, which M108's review left open (R1). A D-entry, the help, and `NEWS.md`.

**Out:** Inner designs other than `rolling_origin()` stay in the candidate row that M110's plan added. Averaged predictions for a design that holds a row out more than once stay in the `summarize = TRUE` candidate row.

## Acceptance criteria

- [x] AC1: `nested_tune_grid()` completes every fold on `ts_index_nested()` and on `ts_period_nested()`, tested. On each design, each fold's `.metrics`, `.selected`, `.tuning_seed` and `.outer_fit_seed` equal those of `reference_nested_loop()` on the same design and seed.
- [x] AC2: The AC1 comparison passes on both designs for `nested_tune_bayes()`, `nested_tune_race_anova()`, `nested_tune_race_win_loss()` and `nested_tune_sim_anneal()`, tested. Each is compared with the reference loop that M110 AC1 names for it. `nested_fit_resamples()` on both designs meets M110 AC2's comparison, tested.
- [x] AC3: `nested_resamples()` accepts `sliding_index()` or `sliding_period()` as `outside`, with `rolling_origin()` as `inside`, tested. For both designs, every outer and inner analysis and assessment set is identical to the one `rsample::nested_cv()` builds from the same arguments. `expect_outer_identical()` and `expect_inner_identical()` make the comparison.
- [x] AC4: `nested_final_fit()` on a `nested_tune_grid()` result over each of the two designs matches the M108 reference under the recorded seeds, tested. That reference is `tune::tune_grid()` over the inner `rolling_origin()` on the full data, then `tune::select_best()`, then `fit()`.
- [x] AC5: `nested_tune_grid()` runs with `save_pred = TRUE` over a `sliding_window(lookback = 59, assess_stop = 11, step = 10)` outer design, whose assessment sets overlap. `augment()` on the result raises class `nestedtune_augment_rows`, tested. Its message states how many rows no fold holds out and how many are held out more than once. It names no repeated or Monte Carlo design.
- [x] AC6: For a `vfold_cv(repeats = 2)` or `mc_cv()` outer design, the `augment()` message still names a repeated or Monte Carlo design, tested. For the M108 rolling-origin and sliding-window results, it still names the rows no fold holds out and no repeated or Monte Carlo design, tested.
- [x] AC7: The time-series paragraph of the `nested_tune_grid()` help and the `nested_resamples()` help name `sliding_index()` and `sliding_period()` as supported designs. The support is for an inner `rolling_origin()`, under every orchestrator and `nested_final_fit()`. `NEWS.md` has an entry. `devtools::check()` gives 0 errors, 0 warnings, and no note absent from the check of the default branch at the branch point.

## Coverage

- AC1 → T1, T2
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T5
- AC6 → T5
- AC7 → T6, T7

## Tasks

- [x] T1: Add `make_ts_data()`, `ts_index_nested()` and `ts_period_nested()` to `tests/testthat/helper-orchestration.R`. Build them with `rsample::nested_cv()`, with the literal inner call the final fit re-runs.
- [x] T2: Write the AC1 tests in `tests/testthat/test-time-series-designs.R`, using the reference loops as M110 does. The AC2 tests come from adding both designs to `TS_DESIGNS`, which the four `test-time-series-*.R` files loop over.
- [x] T3: Write the AC3 split-identity tests.
- [x] T4: Write the AC4 final-fit tests, using M108's `expect_final_matches_reference()`.
- [x] T5: Fit the message in `check_held_out_once()` (`R/nested-results-collect.R:700-733`) to a sliding design that holds rows out more than once. Decide the design from the outer split class, and keep today's text for other designs. Write the AC5 and AC6 tests. The AC6 repeated and Monte Carlo case extends `tests/testthat/test-augment.R:150-163`.
- [x] T6: Time `test-time-series-designs.R` alone and the whole suite in parallel. Compare both with the CI step caps in `cairn/PROFILE.md`. Record the figures in the work log.
- [x] T7: Write the D-entry extending M110's entry to the two designs and the new message. Write the help and `NEWS.md` text. Run `devtools::document()`, the prose sweeps from the verify slot, and `devtools::check()`.

## Work log

- 2026-09-22: created by /milestone-plan with M110. A probe on `main` at `dad72ce` ran `nested_tune_grid()` to completion on both fixtures. `sliding_period(period = "week")` errors inside `nested_cv()` at the default `lookback`. At `lookback` 7 or less, a racer refuses a fold with 2 or fewer inner resamples. At `lookback = 8` the design has 5 folds with 4 or 5 inner resamples each.
- 2026-09-22: criteria audit findings on M111 were the unstated `sliding_period()` arguments and a message change that needed code. Also a test property stated as a promise, and a final-fit claim tested on one design of two. All were fixed before the gate.
- 2026-09-22: plan gate chose all six orchestrators on the new designs over `nested_tune_grid()` alone, because the help then states one rule for four designs. Falsified by the added runs pushing a CI leg past its step cap.
- 2026-09-22: implement started on branch `m111-index-period-designs`. Question gate: the time-series `augment()` wording covers all four time-series split classes, `rolling_origin()` included, over the three sliding ones alone. The new designs join `TS_DESIGNS`, so the four time-series files run them, over one new file.
- 2026-09-22: minor amendment: T2's wording now says the AC2 tests reach the new designs through `TS_DESIGNS` in the four files. T3 and T4 landed in the same edit to `test-time-series-designs.R`, so T1 to T4 share one checkpoint.
- 2026-09-22: T1-T4 done. `make_ts_data()`, `ts_index_nested()`, `ts_period_nested()` and a `TS_DATA` lookup in the helper. Grid, split and final-fit tests loop over the two designs. The four files pass alone: designs 29 s, bayes 113 s, race 50 s, anneal 30 s wall.
- 2026-09-22: T5 done. `check_held_out_once()` gives a time-series split class (`TIME_SERIES_SPLITS`) its own overlap text. The AC5 test fails on 3 assertions with the old message restored. The `augment()` help paragraph rides in this commit, as it sits in the same file. Full suite clean, 535 s wall locally.
- 2026-09-22: T6 figures. Whole suite locally, two workers: 476 s on `main` at `d6fca8c`, 535 s on the branch at `5c5a9b5` (+12.4%). The four time-series files alone: designs 29 s, bayes 113 s, race 50 s, anneal 30 s. M110's merge run 35801023421, ubuntu release: the check step took 28.8 min, of which `testthat.R` took 21.8 min. Scaled by +12.4%, the tests add about 2.7 min, and the step reaches about 31.5 min against its 30 min cap. The plan gate's falsifier is estimated to fire.
- 2026-09-22: cut the Bayesian final-fit tests on the two new designs (18 s alone). No criterion asks for them, and the grid and fit_resamples final fits back the help claim. The Bayes file is now 94 s alone. T7 help, `NEWS.md` and D-076 drafted and swept clean, carried in this checkpoint unticked. The step-cap choice goes to a mini gate.
- 2026-09-22: blocked. Mini gate chose making the suite faster first, over narrowing AC2 and AC7 to three functions or raising the ubuntu step cap. Blocker: a suite-speed milestone, to be planned from the "CI check steps near their caps" candidate row. It must make room for about 2.3 min more tests under the ubuntu release step's 30 min cap. When it is done, merge `main`, rerun T6, then finish T7.
- 2026-09-22: blocked, recorded on `main`. The branch `m111-index-period-designs` holds T1 to T5 and the full work log. The added tests put the ubuntu release check step at about 31 min against its 30 min cap, and a mini gate chose a suite-speed milestone first.
- 2026-09-23: resumed, blocker cleared. M112 merged as `d6cbee6`, and the four legs other than macOS skip the vignettes. Merged `main` into the branch. The branch's drafted D-entry became D-078, because M112 took D-076 and D-077 on `main`. Status set to in-progress.
- 2026-09-23: T6 rerun after the merge at `1f84c8e`. Locally, two workers: the whole suite passed in 500 s, and `test-time-series-designs.R` alone took 32 s. On PR #126 (run 35817157833, the `main` tests without M111's), the ubuntu release check step took 24.5 min, of which `testthat.R` took 22.3. Scaled by the +12.4% measured at T6 before the block, the tests add about 2.8 min, so the step is estimated at about 27.3 min against its 30 min cap. The PR run at review gives the measured figure.
- 2026-09-23: T7 drafts checked against AC7. `devtools::document()` left no diff. All six prose sweeps and `check_pkgdown()` are clean.
- claim audit: 33 claims read, 9 corrected — NEWS.md, test-time-series-bayes.R, test-time-series-anneal.R, test-time-series-race.R, test-time-series-designs.R, helper-orchestration.R
- 2026-09-23: T7 done. `devtools::check()` at `f0484d4` gave 0 errors, 0 warnings and 0 notes. The branch point `main` also gave 0 notes, at M112's review. The later audit corrections change only comments and NEWS.md. Status set to review.
- 2026-09-23: gate fixes F1, F4, F6, F7 and F9 landed at `e301e9d`. `devtools::test()` then ran 1004 tests with 0 failed, 0 errors and 0 skipped.
- step-7 approval: m111-index-period-designs approved for merge

## Decisions

## Review

- Suite (2026-09-23, head `d9e5614`): `devtools::test()` ran 1003 tests with 0 failed, 0 errors and 0 skipped. The per-test results were saved, and every test named below ran its expectations.
- AC1: "a sliding-index design matches a hand-rolled reference loop" (10 expectations) and "a sliding-period design ..." (14) pass. `expect_ts_matches_reference()` checks `.completed`, then `.tuning_seed` and `.outer_fit_seed` as whole vectors, and `.metrics` and `.selected` per fold against `reference_nested_loop()` at seed 20.
- AC2: on both new designs, the reference-loop tests for `nested_tune_bayes()`, `tune_race_anova`, `tune_race_win_loss` and `nested_tune_sim_anneal()` pass, with 10 to 14 expectations each. So do "nested_fit_resamples() matches fit_resamples() on a sliding-index design" (15) and "... sliding-period design" (23), which compare each fold's rmse and mae with `tune::fit_resamples()` on the outer splits.
- AC3: "sliding-index splits match rsample::nested_cv()" (42) and "sliding-period splits ..." (74) pass. Each checks that `nested_resamples()` returns a `nested_resamples` whose first split has the design's class, then runs `expect_outer_identical()` and `expect_inner_identical()` against `rsample::nested_cv()`.
- AC4: "the final fit on a sliding-index design matches a hand-rolled reference" and "... sliding-period design ..." pass. Each checks the split class, then runs M108's `expect_final_matches_reference()` on a `nested_tune_grid()` result.
- AC5: "augment() on an overlapping sliding-window result counts both kinds of row" (8) passes. It runs `nested_tune_grid()` with `save_pred = TRUE` over `sliding_window(lookback = 59, assess_stop = 11, step = 10)`. It asserts class `nestedtune_augment_rows` and the text "holds out 69 rows never and 1 row more than once.". It also asserts "time-series design", and no "repeated" or "Monte Carlo".
- AC6: "an outer design holding a row out other than once is refused with nestedtune_augment_rows" (`test-augment.R`, 8) passes on `vfold_cv(repeats = 2)` and `mc_cv()`. It asserts "Monte Carlo" in the message and no "time-series". The two tests "augment() refuses a rolling-origin result ..." (8) and "... sliding-window result ..." (9) pass. They assert the never-held rows by number, and no "repeated" or "Monte Carlo".
- AC7: `man/nested_tune_grid.Rd:170` (the time-series paragraph) and `man/nested_resamples.Rd:57` name `rsample::sliding_index()` and `rsample::sliding_period()` beside the two M108 designs. Both state support with an inner `rsample::rolling_origin()`, with every orchestrator and `nested_final_fit()` tested. `NEWS.md:26-31` has the entry. `devtools::check()` at `d9e5614` gave 0 errors, 0 warnings and 0 notes in 13m 2s. The branch point `main` gave 0 notes at M112's review, so no note is new.
- Gate (head `d9e5614`): `cairn_validate` exit 0. `cairn_impact` reports no changed principle. `devtools::document()` left no diff. `pkgdown::check_pkgdown()` found no problems. All six gating prose sweeps exit 0. README is untouched. No new top-level files.
- Reviewers: [S] blame-history, 0 findings. [S] prior-review, 0 findings: the diff settles M108's R1 and keeps D-075's corrected wording. [O] diff-bug, 9 findings, none failing a criterion, ranked:
  - F1: `TIME_SERIES_SPLITS` lists four classes, but only `sliding_window_split` reaches the new message in a test. A misspelled or dropped `rof_split`, `sliding_index_split` or `sliding_period_split` passes every test.
  - F2: only the first outer split's class is read, so a hand-built rset of plain `rsplit` objects gets the repeated or Monte Carlo text. rsample's constructors never mix classes, and D-078 records the rule.
  - F3: the `sliding_index()` fixture gives the same splits as the sliding-window one, because the dates are 90 consecutive days. Index gaps and repeated dates are untested. The Scope fixes this data.
  - F4: the help and NEWS say `nested_final_fit()` is tested on all four designs. On the two new designs, only grid and fit_resamples results are final-fit tested.
  - F5: the Bayesian final-fit skip on the new designs rests on the final fit not reading `date`. The grid and fit_resamples final-fit tests cover that.
  - F6: the oracle records in the `test-time-series-designs.R` header still count M108's tests and M108's criteria.
  - F7: line 3 of `test-time-series-anneal.R` and of `test-time-series-race.R` is 108 characters, left unwrapped by the claim-audit edit.
  - F8: the non-overlap `augment()` path is untested on the two new designs. AC6 does not ask for it.
  - F9: the new message's "one that does not reach every row predicts it not at all" reads as though another design caused the missing rows.
- Triage at the gate (user chose "Fix 5, then merge"):
  - F1 fixed now. A new test checks that `TIME_SERIES_SPLITS` equals the four `TS_SPLIT_CLASS` values, which each design's fixture test checks against a real split. A planted `rof_splitX` fails that test alone.
  - F4 fixed now. The help and NEWS now say `nested_final_fit()` is tested on all four designs for `nested_tune_grid()` and `nested_fit_resamples()` results.
  - F6 fixed now. The header oracle records name the four tests per oracle and both milestones' criteria.
  - F7 fixed now. The two header lines are rewrapped.
  - F9 fixed now. The message now reads "An overlapping time-series design predicts some rows several times and others not at all."
  - Rejected: F2, because D-078 records the first-split rule and rsample never mixes classes. F3, because the Scope fixes the data. F5, because the grid and fit_resamples final-fit tests cover `date`. F8, because AC6 does not ask for it.
  - After the fixes, `test-time-series-designs.R` passes 26 of 26, `document()` rewrote the six help pages, and all six prose sweeps pass.
