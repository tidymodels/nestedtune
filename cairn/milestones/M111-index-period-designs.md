# M111: Index-based and period-based sliding outer designs

- **Status:** in-progress
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

- [ ] AC1: `nested_tune_grid()` completes every fold on `ts_index_nested()` and on `ts_period_nested()`, tested. On each design, each fold's `.metrics`, `.selected`, `.tuning_seed` and `.outer_fit_seed` equal those of `reference_nested_loop()` on the same design and seed.
- [ ] AC2: The AC1 comparison passes on both designs for `nested_tune_bayes()`, `nested_tune_race_anova()`, `nested_tune_race_win_loss()` and `nested_tune_sim_anneal()`, tested. Each is compared with the reference loop that M110 AC1 names for it. `nested_fit_resamples()` on both designs meets M110 AC2's comparison, tested.
- [ ] AC3: `nested_resamples()` accepts `sliding_index()` or `sliding_period()` as `outside`, with `rolling_origin()` as `inside`, tested. For both designs, every outer and inner analysis and assessment set is identical to the one `rsample::nested_cv()` builds from the same arguments. `expect_outer_identical()` and `expect_inner_identical()` make the comparison.
- [ ] AC4: `nested_final_fit()` on a `nested_tune_grid()` result over each of the two designs matches the M108 reference under the recorded seeds, tested. That reference is `tune::tune_grid()` over the inner `rolling_origin()` on the full data, then `tune::select_best()`, then `fit()`.
- [ ] AC5: `nested_tune_grid()` runs with `save_pred = TRUE` over a `sliding_window(lookback = 59, assess_stop = 11, step = 10)` outer design, whose assessment sets overlap. `augment()` on the result raises class `nestedtune_augment_rows`, tested. Its message states how many rows no fold holds out and how many are held out more than once. It names no repeated or Monte Carlo design.
- [ ] AC6: For a `vfold_cv(repeats = 2)` or `mc_cv()` outer design, the `augment()` message still names a repeated or Monte Carlo design, tested. For the M108 rolling-origin and sliding-window results, it still names the rows no fold holds out and no repeated or Monte Carlo design, tested.
- [ ] AC7: The time-series paragraph of the `nested_tune_grid()` help and the `nested_resamples()` help name `sliding_index()` and `sliding_period()` as supported designs. The support is for an inner `rolling_origin()`, under every orchestrator and `nested_final_fit()`. `NEWS.md` has an entry. `devtools::check()` gives 0 errors, 0 warnings, and no note absent from the check of the default branch at the branch point.

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
- [ ] T6: Time `test-time-series-designs.R` alone and the whole suite in parallel. Compare both with the CI step caps in `cairn/PROFILE.md`. Record the figures in the work log.
- [ ] T7: Write the D-entry extending M110's entry to the two designs and the new message. Write the help and `NEWS.md` text. Run `devtools::document()`, the prose sweeps from the verify slot, and `devtools::check()`.

## Work log

- 2026-09-22: created by /milestone-plan with M110. A probe on `main` at `dad72ce` ran `nested_tune_grid()` to completion on both fixtures. `sliding_period(period = "week")` errors inside `nested_cv()` at the default `lookback`. At `lookback` 7 or less, a racer refuses a fold with 2 or fewer inner resamples. At `lookback = 8` the design has 5 folds with 4 or 5 inner resamples each.
- 2026-09-22: criteria audit findings on M111 were the unstated `sliding_period()` arguments and a message change that needed code. Also a test property stated as a promise, and a final-fit claim tested on one design of two. All were fixed before the gate.
- 2026-09-22: plan gate chose all six orchestrators on the new designs over `nested_tune_grid()` alone, because the help then states one rule for four designs. Falsified by the added runs pushing a CI leg past its step cap.
- 2026-09-22: implement started on branch `m111-index-period-designs`. Question gate: the time-series `augment()` wording covers all four time-series split classes, `rolling_origin()` included, over the three sliding ones alone. The new designs join `TS_DESIGNS`, so the four time-series files run them, over one new file.
- 2026-09-22: minor amendment: T2's wording now says the AC2 tests reach the new designs through `TS_DESIGNS` in the four files. T3 and T4 landed in the same edit to `test-time-series-designs.R`, so T1 to T4 share one checkpoint.
- 2026-09-22: T1-T4 done. `make_ts_data()`, `ts_index_nested()`, `ts_period_nested()` and a `TS_DATA` lookup in the helper. Grid, split and final-fit tests loop over the two designs. The four files pass alone: designs 29 s, bayes 113 s, race 50 s, anneal 30 s wall.
- 2026-09-22: T5 done. `check_held_out_once()` gives a time-series split class (`TIME_SERIES_SPLITS`) its own overlap text. The AC5 test fails on 3 assertions with the old message restored. The `augment()` help paragraph rides in this commit, as it sits in the same file. Full suite clean, 535 s wall locally.

## Decisions

## Review
