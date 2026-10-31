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
- [x] T4: Selection metric. Add the assertion to the test at `test-selection-metric.R:15`. Plant: compare with the set's last name, and see it fail.
- [x] T5: Registry and decision. Add the AC5 rows and the AC6 lines under the file's quoting rule. Rewrite the selection group's paragraph and the header paragraph that point at the candidate row. Append the D-entry. Re-point `helper-time-budget.R` rows for the new blocks in one pass.
- [x] T6: Run `devtools::test()` and `air format --check .` clean.

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
- 2026-10-31: T4: the grid test in `test-selection-metric.R` now also compares the final fit's `first_metric` with `names(attr(ms, "metrics"))[[1L]]`; file green (8 tests). Plant: the set's second name failed both metric sets ("mae" against "rmse"), reverted. Header comment names the added comparison.
- 2026-10-31: T5: `cairn/ORACLES.md` gained five rows (`nested-tune-grid-oracles/O8`, `selection-metric/O1`, `eval-time/O4`, `event-level/O3`, `resample-weights/O3`), the memory group's slope line, the four D-123 lines (compute_metrics, averages, racing record, and the iteration-stage sentence in the Bayesian and annealing groups), and rewrites of the header and selection-group paragraphs. `grep -n 'Give finer results a second oracle' cairn/ORACLES.md` returns no line. D-123 appended to `cairn/DECISIONS.md`. `helper-time-budget.R` holds no row for the four test files changed, so nothing was re-pointed. The averages line names the two-repeat median gap and its parked row.
- 2026-10-31: T6: `air format --check .` clean; `devtools::test()` under `NESTEDTUNE_FULL_SUITE=true`, run alone: 1162 tests, 0 failed, 0 errors, 0 skipped.
- 2026-10-31: claim audit: not owed — internal tier
- 2026-10-31: implement done; status review.
- 2026-10-31: review pass 1: four of the D-123 records rest on a false premise (Review section, findings marked "at the stop"); stopped for the user, since the repair changes what the plan promised.
- 2026-10-31: stop answer: the user chose "Build two cheap tests": a sums-to-one invariant for renormalized probabilities, and a censored average on a design holding rows out three times, checked against tune; the other one-type parts recorded as such, the event-level row dropped and M152's header restored, D-123 narrowed, the uncovered parts on a new candidate row.
- 2026-10-31: amendment routed: AC5 — the event-level exchange row reverses M152 (diff-bug #3, ripple #1); the two new tests need rows.
- 2026-10-31: amendment routed: AC6 — the averages, compute_metrics and racing lines rest on a false premise (diff-bug #1, #5, #6; blame-history #2, #3).
- 2026-10-31: re-audit: AC5 (reduced) — "holds no row for the exchange" rested on judgment; replaced by `grep -n 'event-level/O3'` returning no line.
- 2026-10-31: re-audit: AC6 (reduced) — "each part that rests on one type" had no listing procedure; the parts were named in the criterion.
- 2026-10-31: re-audit: AC7 (reduced) — nothing. The wording then gained a `hand_average()` assertion on the three-repeat run, so the median has a closed-form check beside tune's.
- 2026-10-31: re-audit: AC5 (reduced) — nothing.
- 2026-10-31: re-audit: AC6 (reduced) — "the rows that reach it" and "parts that rest on one type" are still decided by judgment; suggested crediting rows by the line's own naming and naming the one-type parts outright. Second line for AC6, so the wording goes to the user.
- 2026-10-31: re-audit: AC7 (reduced) — nothing.
- 2026-10-31: T7 (pending the amendment's write): `test-collect-predictions-summarize.R` gained "a renormalized probability average sums to one in every row" and "a censored average over three repeats takes the median time, as tune does"; `repeated_pair()` and `fixed_pair()` take `repeats` (default 2, injected so the stored call stays literal). File green, 34 tests. Plants in `R/nested-results-collect.R`: `mean_by` for `.pred_time` failed the three-repeat test (2 expectations) and the missing-median test; no renormalization failed the sums test and the hand renormalization test; both reverted, `git diff -- R/` empty.
- 2026-10-31: review return 1: fix-now findings to carry in the implement pass: diff-bug #4 (show the failed-fold weights case failing), #8, #12; blame-history #6, #9; prior-review #2, #3, #5; ripple #6.

## Decisions

## Review

- spawned: diff-bug, blame-history, prior-review, ripple
- cairn_validate: all checks passed, 18 advisory warnings (references staleness).
- diff-bug #1: the averages line says U1 backs the `hand_average()`-only cases because they run the same branches, but U1's fixtures need no renormalization and hold each row out twice, so a mean in place of the median passes U1 and U2 — at the stop.
- diff-bug #2: the AC4 assertion follows from three assertions already in the test, and its plant edited the expected value — reject, planned change (AC4 names that assertion).
- diff-bug #3: `event-level/O3` reverses M152, which removed that record because the sens/spec exchange is yardstick's arithmetic, and the file header still says so — at the stop.
- diff-bug #4: the failed-fold case of the weights test was never shown failing — fix now (plant a missing renormalization over the stored weights, which the failed case can show).
- diff-bug #5: the compute_metrics line holds for the numeric and class-probability branches, but U2 never reaches the survival branch, so a new set on a censored run rests on U1 alone — at the stop.
- diff-bug #6: the racing line is true to the code, but no check of a second type reaches the eliminated candidates' rows — at the stop.
- diff-bug #7: O8 follows `.comp_min`'s body, not the page's printed formula — reject, false (the row cites the note, which records the typo and the reading taken).
- diff-bug #8: the source note leaves out that `geomean()` returns 0 when a term is 0, so exact ties are the only exposure — fix now (one sentence in the note).
- diff-bug #9: the desirability test's closing guard repeats the existing test's guard on the same run — reject, false (it compares the new test's own definition-based picks with rmse's, which the existing guard does not).
- diff-bug #10: the eval_time test's last assertion repeats the existing test's — reject, planned change (AC1 names it, and it keeps the comparisons from passing on a fixture where both orders pick alike).
- diff-bug #11: the weights test's "doubles the total" comment is near worked arithmetic — reject, false (it states why the comparison can be exact, which the code cannot show).
- diff-bug #12: the ORACLES header says the five rows are for tests written after `576c3d19`, but two register assertions in older tests — fix now (reword).
- blame-history #1: D-123 contradicts D-121's clause that an average or rescoring owes two types — reject, false (the groups still hold two types; D-123 is about finer inputs), but the wording is redone with the stop's answer.
- blame-history #2: D-123 rests on the test rule against repeated checks, which does not speak to oracle counts — at the stop (D-123 is rewritten with the answer).
- blame-history #3: the averages line fails for the censored median — at the stop (same as diff-bug #1).
- blame-history #4: the slope is credited to O2, which checks sizes, not the slope — reject, false (every size the lean slope is computed from is within 2% of `analytic_size()`; the line is reworded under prior-review #3).
- blame-history #5: race O3 compares with the same tune call the code makes — reject, false (O3 calls it on an independent re-run of the race).
- blame-history #6: ORACLES:14 says each waived result "owes none" while the iteration stage keeps one type — fix now (reword).
- blame-history #7: the new weights Source paragraph sits under the "every-fold case only" qualifier — reject, false (the qualifier ends its own paragraph; the new one follows a blank comment line).
- blame-history #8: test-eval-time.R's "and in its final-fit form by" now appears twice — reject, false (each route, live and invariant, has its own final-fit test).
- blame-history #9: test-selection-metric.R's header names tune's reading as "the oracle" before the closed-form check — fix now (name both).
- blame-history #10: the candidate row still reads "started M166" — reject, planned change (step 9 hygiene graduates it).
- prior-review #1: the event-level heading says 2 types while listing an invariant row — at the stop (depends on the O3 answer).
- prior-review #2: the resample-weights heading says 2 types while listing an invariant row — fix now (3 types).
- prior-review #3: the memory slope line repeats a row of its own group — fix now (a group sentence in place of the bullet).
- prior-review #4: the eval_time and weights tests have no source comment directly above them — reject, false (both files keep their sources in the header block, where the new paragraphs went).
- prior-review #5: the iteration-stage paragraph still cites an unrecorded plan gate of 2026-09-01 — fix now (cite D-123).
- prior-review #6: the desirability test tells its pick from rmse's only across folds — reject, false (fold 3 differs, and the plant failed folds 2 and 3).
- prior-review #7: the failed and NA weight cases' values rest on O1, the new test checking invariance only — reject, planned change (AC2 names the invariant as the second type).
- ripple #1: the event-level header contradicts `event-level/O3` — at the stop (same as diff-bug #3).
- ripple #2: GP2 states no exception for D-123 — reject, false (GP2 is a guiding principle traded with stated justification, as D-121 did).
- ripple #3: the per-file list omits `selection-metric/O1` — reject, false (the list is of records at `576c3d19`).
- ripple #4: the candidate row still lists the results — reject, planned change (graduated at step 9).
- ripple #5: the new rows carry no "(found by reading)" mark — reject, false (rows added after `576c3d19` name their test in the row, as M164's do).
- ripple #6: D-123 cites "the testing rule" without naming it — fix now (name the plugin's "What gets a test" rule, if the rule stays).
