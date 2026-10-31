# M166: Give finer results a second oracle

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP2
- **Resolves:** —
- **Surface tier:** internal — tests and in-repo tracking records; no package code or user doc changes
- **Branch/PR:** m166-finer-second-oracle

## Goal

Back each result that the candidate row "Give finer results a second oracle" names with a second oracle type, or record why it owes none.

## Scope

**In:** three new tests. One covers the final fit under a two-element `eval_time`, one covers resample weights with a left-out fold, and one covers the desirability rule by its definitions. One assertion joins the selection-metric test. A source note covers desirability2's help pages. `cairn/ORACLES.md` gains rows for the new oracles and for two assertions already in the suite. It gains one line for each result that owes no oracle of its own, and a D-entry records that rule.

**Out:** the averaging tests hold each censored row out twice, so the median and the mean of `.pred_time` agree there. That gap goes to the parked row "M126 review leftovers on averaging". Pointing the 21 test-file headers at the registry goes to its parked row. No change to package code.

## Acceptance criteria

- [ ] AC1: `test-eval-time.R` gains a test that runs `nested_tune_grid()` at each order of `srv_eval_times()` and at each order's first element alone. For each order, it asserts that `nested_final_fit()` on the two-element run selects the same candidate as on the one-element run. It also asserts that the two fits give the same predictions on the data. It also asserts that the two orders select different candidates.
- [ ] AC2: `test-resample-weights.R` gains a test on the weighted design with one failed fold, and on the same design with one fold scoring NA on one metric. In each case it asserts that a new weight on the left-out fold leaves each affected summary row's `mean`, `std_err` and `n` identical. It also asserts that a new weight on a scored fold changes that row's `mean`.
- [ ] AC3: `test-nested-tune-grid-oracles.R` gains a test on one grid run under a desirability rule. Its expected selection for each fold is computed by explicit code from the definitions in desirability2's help pages, on that fold's inner metrics. The test asserts that each fold's recorded selection equals that candidate. A source note in `cairn/references/` records those definitions and desirability2's version.
- [ ] AC4: the test `"a grid run records the first metric of the set it was given, in either order"` in `test-selection-metric.R` gains one assertion. For each of its two metric sets, the final fit's recorded first metric equals `names(attr(ms, "metrics"))[[1L]]`.
- [ ] AC5: `cairn/ORACLES.md` holds one oracle row for each test that AC1, AC2 and AC3 add. It holds one invariant row for the level exchange that `"nested_final_fit() tunes under the caller's event level"` in `test-event-level.R` asserts. It holds one closed-form row for the first-name assertions of the test that AC4 names. Each row gives id, type, source and its test quoted by name. The memory group counts `nested-resamples-memory/O2` for the size slope.
- [ ] AC6: `cairn/ORACLES.md` carries one line for each of four results. The first is `compute_metrics()` on the run's own and on a new metric set. The others are the averages that only `hand_average()` checks, the racing fold record, and the Bayesian and annealing iteration stage. Each line names the rows that back the result and why it owes no oracle of its own. A new `cairn/DECISIONS.md` entry records the rule that those lines apply. `grep -n 'Give finer results a second oracle' cairn/ORACLES.md` returns no line.
- [ ] AC7: `devtools::test()` reports no failures, and `air format --check .` is clean.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T5
- AC6 → T5
- AC7 → T6

## Tasks

- [x] T1: Final fit under `eval_time`, invariant. In `test-eval-time.R`, after the test at :491, run `nested_tune_grid()` through `memoised()` at `c(0.5, 10)`, `c(10, 0.5)`, `0.5` and `10`. Fit each run with `set.seed(11)` first, as that test does. Compare the selected `dist` and `predict()` on `srv_data()`. Plant: pair each order with the other element's run, and see the test fail.
- [x] T2: Resample weights, invariant. In `test-resample-weights.R`, beside the tests at :172 and :204, build the weighted design with a new weight on the failed fold (`break_fold()`, helper-orchestration.R:532) and on the NA fold (`plant_na`). Compare `collect_metrics()` rows. Plant a defect the fixture can show, such as matching weights to folds by position in `summarize_folds()` (R/nested-results.R:900), see it fail, and restore.
- [x] T3: Desirability, closed-form. Read desirability2 0.2.0's help pages for `select_best_desirability()` and its term functions. Write the source note with its `INDEX.md` line. In `test-nested-tune-grid-oracles.R`, beside the test at :432, reuse that run's rule and fixture. Compute each term's desirability over each fold's candidates, their geometric mean, and the top candidate. Compare with `.selected`. Fold 3 picks apart from the best `rmse`, so the rule shows. Plant: flip one term's direction, and see the test fail.
- [ ] T4: Selection metric. Add the assertion to the test at `test-selection-metric.R:15`. Plant: compare with the set's last name, and see it fail.
- [ ] T5: Registry and decision. Add the AC5 rows and the AC6 lines under the file's quoting rule. Rewrite the selection group's paragraph and the header paragraph that point at the candidate row. Append the D-entry. Re-point `helper-time-budget.R` rows for the new blocks in one pass.
- [ ] T6: Run `devtools::test()` and `air format --check .` clean.

## Work log

- 2026-10-31: created by /milestone-plan.
- 2026-10-31: tier check: not run — work named at the question set.
- 2026-10-31: idea vet: gap — compute_metrics() on its own and on a new metric set, the hand_average() cases and the racing fold record run the code their group's two oracle types already run, on other inputs, and the test rule forbids repeating a check across inputs on one code path; reading taken: record each as owing no oracle of its own, under the set's record-and-explain answer. gap — the final fit under event_level and the selection metric already carry a second-type assertion that the registry does not list; reading taken: register it rather than add a test. No flaw.
- 2026-10-31: question set: what to work on — the candidate row "Give finer results a second oracle"; a result with no cheap second type — record it in `cairn/ORACLES.md` with its reason, under a new D-entry. No permission, file or access was asked.
- 2026-10-31: lessons used: 2026-10-31 (M164) a plant must be one the fixture can show; 2026-10-31 (M164) `info =` takes a character value; 2026-10-31 (M163) registry upkeep; 2026-10-22 (M152) re-point time-budget rows once; 2026-09-16 (M101) skip helpers; 2026-07-27 (M12) memoised fixtures and RNG state.
- 2026-10-31: collision check: absorbs in full the candidate row "Give finer results a second oracle". D-121 is related, not colliding, and the new D-entry extends it. Inbox: 1 open issue (#91, held by a parked row), 0 open PRs, no overlap. Investigation: two Haiku Explore searches over the nine results' tests and code.
- 2026-10-31: criteria audit (reduced mode, internal tier; fresh Opus reader): AC1-AC5 and AC7 no finding. AC6: "names that candidate row as the home of a result" rested on judgment; narrowed to a grep that returns no line.
- 2026-10-31: plan gate chose records over new tests for the four results that share a code path with their group's two types, because the test rule forbids a check repeated across inputs on one path; falsified by one of them running a branch that no listed oracle runs.
- 2026-10-31: plan gate chose a weight-change invariant for left-out folds over a comparison with `tune::fit_resamples()`, because tune ignores the weights or errors when a fold is missing (tune#1197); falsified by a tune release that drops a missing fold and keeps the weights.
- 2026-10-31: plan gate chose a two-element-against-one-element invariant for the final fit under `eval_time` over the IPCW Brier score written out for the final fit's tuning run, because the invariant reuses fixtures and the closed form already backs the runs; falsified by the final fit reading `eval_time` by a route that the invariant cannot reach.
- 2026-10-31: plan gate chose one milestone over two, because three tests, one assertion and the registry edit fit two sessions; falsified by the plan-owned body passing the cap or T1-T5 not fitting two sessions.
- 2026-10-31: T1: added "a final fit at a multi-element `eval_time` is the final fit at its first element" to `test-eval-time.R` (5 expectations, file green under `NESTEDTUNE_FULL_SUITE=true`). Plant: pairing each order with the other element's run failed 4 of 5 expectations (lognormal against weibull), reverted. Header comment names the test beside the run form.
- 2026-10-31: T2: added "a new weight on the fold a summary row leaves out leaves that row unchanged" to `test-resample-weights.R` (6 expectations, file green), and moved `plant_na()` to file level for both tests. A first draft set the left-out weight to 9 and differed in the 16th digit, because tune divides each weight by the total; the new weight now doubles the total, so the stored weights halve exactly. Plant: dividing the weighted sum by every fold's weight failed the NA case (0.196 against 0.392), reverted. The failed-fold case cannot show that plant, since a failed fold has no per-fold row.
- 2026-10-31: T3: added "the desirability rule picks the candidate its definition names in the fold's inner metrics" to `test-nested-tune-grid-oracles.R:493` (10 expectations, green), on the same rule, grid and seed 20 as the desirability2 test, memoised. Source note `cairn/references/desirability2-select-best.md` with its INDEX line. The page's minimization formula prints "data = low", a typo; the note takes `.comp_min`'s body. The test asserts one top candidate per fold, since the pages leave the tie order unstated. Plant: `df2` maximized in the expected pick failed folds 2 and 3, reverted. The lint hook's remaining hits on the note are cairn's provenance tokens and minus signs.
