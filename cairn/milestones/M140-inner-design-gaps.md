# M140: Inner-design gaps under the other functions

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, GP2
- **Resolves:** —
- **Surface tier:** user-facing, because the help pages and NEWS state which designs each exported function is tested on
- **Branch/PR:** m140-inner-design-gaps

## Goal

The inner-design gaps that M120 and M121 left are tested and documented.

## Scope

**In:** Final fits of the four other tuners on the inner sliding-window and sliding-index designs. `nested_workflow_map()` with each of those tuners on the inner sliding-period design. Every function on the `"sliding-window / sliding-window"` pair of `TS_SLIDING_PAIRS`. One grid test on that pair whose tuning range comes from the data's row count. With it, a broken step that re-points the inner splits at the outer window fails a test. The help, NEWS and a D-entry that state the new tested set.

**Out:** Every function but `nested_resamples()` and grid on the other eight pairs, and any inner design other than `rolling_origin()` and the three sliding designs. Both stay in the rewritten inner-design candidate row. The racers on the sliding-index / sliding-window pair, which `check_race_burn_in()` refuses because it builds 2 inner resamples per fold. That refusal is already tested and documented, so no new test is planned.

## Acceptance criteria

- [ ] AC1: Eight tests pass under `devtools::test()`, one for each pair of a tuner and a fixture. The tuners are `nested_tune_bayes()`, `nested_tune_race_anova()`, `nested_tune_race_win_loss()` and `nested_tune_sim_anneal()`. The fixtures are the inner sliding-window and inner sliding-index entries of `TS_INNER_DESIGNS`, each with an outer `rolling_origin()`. Each test calls `nested_final_fit()` on the tuner's result. The reference final fit runs by hand from the fixture's literal inner call on the full data. These must be identical in the two fits: the two seeds, the inner `in_id` and `out_id` values, and the inner split class. The selected parameters and the predictions on the full data must also be identical.
- [ ] AC2: Four tests pass under `devtools::test()`, one for each `fn` value: `"nested_tune_bayes"`, `"nested_tune_race_anova"`, `"nested_tune_race_win_loss"` and `"nested_tune_sim_anneal"`. Each test runs `nested_workflow_map()` over `wset_two()` on the inner sliding-period fixture of `TS_INNER_DESIGNS`. The reference is `hand_call()` for each workflow and `fn`, under the same seed. For each workflow, `.tuning_seed`, `.outer_fit_seed`, `.metrics` and `.selected` must be identical to the reference.
- [ ] AC3: Seven tests pass under `devtools::test()` on the `"sliding-window / sliding-window"` pair of `TS_SLIDING_PAIRS`. Four tests run the tuners of AC1, and each matches its reference loop on `.tuning_seed`, `.outer_fit_seed`, and each fold's `.metrics` and `.selected`. One test runs `nested_fit_resamples()`, which matches `tune::fit_resamples()` on each fold's estimate of each metric. That reference runs on the pair's outer design, built on its own. One test runs `nested_workflow_map()` with its default `fn`, which matches `hand_call()` for each workflow of `wset_two()`. One test runs `nested_final_fit()` on the pair's `nested_tune_grid()` result, which matches a reference final fit as AC1 defines it.
- [ ] AC4: On the same pair, a test runs `nested_tune_grid()` with `grid = 5`, `stoch_workflow()` and a `min_n` range that `dials::get_n_frac_range()` finalizes over `FINALIZE_FRAC`. Oracle O1 is analytic, from `dials::get_n_frac_range()`. Every `min_n` candidate of a fold lies inside `floor(n * FINALIZE_FRAC)`, where `n` is the row count of that fold's outer analysis set. The test also asserts that this upper bound is below the bound of the whole frame. Oracle O2 is a live reference: the same call on `ts_pair_reference()`'s `rsample::nested_cv()` design, under the same seed. After its inner rows are asserted identical, each fold's `.inner_metrics`, `.metrics` and `.selected` are identical to the reference.
- [ ] AC5: Three passages state which function is tested on which design: the "Time-series designs" section of `?nested_resamples`, the time-series paragraphs of the "Nested designs" section of `?nested_tune_grid`, and the time-series bullets of `NEWS.md`. Some sentences say that a function, or a map `fn`, is tested or not tested on a design. Each such sentence agrees with the test files. Each function, map `fn` and design that AC1 to AC3 add is stated in each passage. AC4 adds no new claim, because grid is already stated as tested on all nine pairs. The procedure is a reading of every sentence of the three passages against the test files. After `devtools::document()`, the reading also covers each help page that inherits the "Nested designs" section.

## Coverage

- AC1 → T1, T2
- AC2 → T3
- AC3 → T1, T4
- AC4 → T5
- AC5 → T7

## Tasks

- [ ] T1: Give `reference_final_fit()` in `tests/testthat/helper-orchestration.R` an `inner_design` argument, as `reference_bayes_final_fit()` and `reference_race_final_fit()` have. Its seeds then come from the recorded seeds, not from the final fit's own.
- [ ] T2: Add the AC1 tests, in a new file so that no one file runs alone for long (the M110 lesson). Use the skip guards that the M101 lesson names. Plant a defect in `nested_final_fit()` that keeps the split class but changes the splits. For example, rebuild the inner design on the data less its last row. Show each test red, then remove the plant.
- [ ] T3: Add the AC2 tests to `tests/testthat/test-time-series-inner-other.R`. Pass the arguments that `wset_map_args(fn)` gives.
- [ ] T4: Add the AC3 tests in a new `tests/testthat/test-time-series-pairs-other.R`. Give the window/window pair's literal inner call to the final-fit reference from `TS_INNER_DESIGNS[["sliding-window"]]$inner`.
- [ ] T5: Add the AC4 test to the same file. Move `frac_min_n()` and `FINALIZE_FRAC` from `test-nested-tune-finalize.R` to a helper, because the new file needs them. Guard the test with `skip_if_no_engines(stochastic = TRUE)` and `skip_if_not_installed("dials")`. Replace `analysis_framed_inner()` with a function that returns its inner rset unchanged, and show the test red. Remove the plant.
- [ ] T6: Record in one work-log line that two plants differ. M121 planted a no-op index remap, which leaves whole-data indices on the analysis frame, and every grid test failed. The audit replaced all of `analysis_framed_inner()` with the identity, and the grid tests stayed green. The T8 D-entry says that M121's tests catch a broken index remap but not a skipped re-pointing, and that AC4 closes that gap.
- [ ] T7: Rewrite the three AC5 passages. Amend the two `NEWS.md` bullets that contradict the new tests. One says the final fits are tested "on the sliding-period design alone". The other says the other functions "are not tested on these pairs". Run `devtools::document()` and both prose sweeps.
- [ ] T8: Write one D-entry. It supersedes D-085's rejection of these final fits, and the D-087 and D-088 clause that leaves the other functions unclaimed on the pairs. It gives the reason the pair tests are kept although D-075 and D-079 say the outer design reaches neither the tuner nor the final fit: they bound the help's claim to what a test runs (D-071). The plan commit already rewrote the inner-design candidate row to hold the Out remainder.
- [ ] T9: Time each new or extended test file serially. Queue a long one in `Config/testthat/start-first`. Record the figures in one work-log line. Run the commands of the `verify` slot in `cairn/PROFILE.md`.

## Work log

- 2026-10-01: created by /milestone-plan from the ROADMAP candidate on inner designs. The full criteria audit returned seven findings. Five were fixed before the gate. AC5 names each function and `fn` per design, reads in both directions, and covers `NEWS.md`. The final-fit probe sits in the product, and T1 adds the reference argument. The D-entry reason went to T8. The finding that a no-op re-pointing passes every pair test went to the gate and became AC4.
- 2026-10-01: plan gate chose one pair for the other functions over all nine. Nine pairs add about 330 s of serial test time, and the macOS check step took 26 of 30 min (run 36914677651). Falsified by a function failing on a pair other than window/window where it passes on window/window.
- 2026-10-01: plan gate chose the four map tuners on the inner sliding-period design alone over all three inner designs. Each tuner's run on all three is already tested directly. Falsified by a map run with a tuner failing on an inner design where the tuner alone passes.
- 2026-10-01: plan gate chose to add the eight final-fit tests over keeping M120's rejection. The help then states no exception for the final fit on inner sliding designs. Falsified by nothing in the code: the choice is about the claim, and it costs about 27 s of serial test time.
- 2026-10-01: AC4 and AC5 changed at the gate and went back to the same fresh reader for the full audit questions. The plan was committed before its result, which the next line records. The pair's outer analysis sets hold 60 of 90 rows. So `min_n` finalizes to 6 to 30 there, and to 9 to 45 on the whole frame (by execution).
- 2026-10-01: the second audit pass (full mode, AC4 and AC5) found AC4 satisfiable by execution, with both oracles and the T5 plant going red. It returned four findings, all fixed. T6 no longer calls M121's claim false, because M121 planted a different defect. AC5 names the "Nested designs" section and its inherited copies, and exempts AC4. AC4 pins `grid = 5` and asserts the bound gap. T5 names its skip guards.

## Decisions

## Review
