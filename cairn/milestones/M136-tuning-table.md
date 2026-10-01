# M136: README table of supported tuning functions, and shorter table prose

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP3, GP5
- **Resolves:** —
- **Surface tier:** user-facing — the README and `?nested_resamples` are what users read
- **Branch/PR:** m136-tuning-table

## Goal

The README says which tidymodels tuning functions nestedtune supports, and both of its support tables read in a short space.

## Scope

**In:** a second README table of eight tuning functions with their nested counterparts. Short prose under each table. The per-design refusal reasons move from the README to `?nested_resamples`. A NEWS bullet. D-110 records the change.

**Out:** The gate left out the known gaps inside supported tuners. These are desirability selection under racing and annealing, and the non-grid tuners on inner sliding designs. They stay in their candidate rows. The gate declined per-tuner columns on the resampling table. Support for `tidyclust::tune_cluster()` stays in its candidate row, which needs an RR. A test that checks README cells against tests stays in its `[low]` candidate row.

## Acceptance criteria

- [ ] AC1: `README.Rmd` has a "Supported tuning functions" section after the resampling-design prose and before "Learn more:". Its table has three columns: Function, nestedtune function and Supported. It has eight rows: `tune::tune_grid()`, `tune::tune_bayes()`, `tune::fit_resamples()`, `finetune::tune_race_anova()`, `finetune::tune_race_win_loss()`, `finetune::tune_sim_anneal()`, `workflowsets::workflow_map()` and `tidyclust::tune_cluster()`. The first seven rows read `Yes`. In order, they name `nested_tune_grid()`, `nested_tune_bayes()`, `nested_fit_resamples()`, `nested_tune_race_anova()`, `nested_tune_race_win_loss()`, `nested_tune_sim_anneal()` and `nested_workflow_map()`. The `tune_cluster()` row reads `No` and names no nestedtune function.
- [ ] AC2: The prose under that table defines `Yes` and `No`. `Yes` means that nestedtune exports a nested counterpart that does the row's job on a nested design. It also means that the test suite runs that counterpart with `vfold_cv()` in both loops, and that every outer fold completes. The prose says that `nested_fit_resamples()` and `nested_workflow_map()` run no search of their own. `No` means that no nestedtune function does the row's job. For `tune_cluster()`, the prose gives the reason: nothing settles what a nested estimate of a clustering metric means. Each `Yes` row is true at the merge commit. A test in `tests/testthat/` runs the row's nestedtune function on such a design and asserts that every outer fold completed.
- [ ] AC3: The prose says that the resampling table's `Yes` cells were tested through `nested_tune_grid()`. It points to the "Time-series designs" section of `?nested_resamples` for the time-series designs that the other six functions are tested on. It links the "Choosing the inner tuner" article.
- [ ] AC4: The two sections together hold at most 400 words outside their table rows. At commit 10e1e775, the resampling section alone holds 789. The count is the output of `awk '/^## Supported resampling designs/{f=1} /^Learn more:/{f=0} f && !/^\|/' README.Rmd | wc -w` at the merge commit. Every footnote definition that the two tables use sits before "Learn more:", so the count includes it.
- [ ] AC5: The 17 lines that start with `|` in the resampling section are byte-identical to those at 10e1e775. `?nested_resamples` gives the reason for each of the 8 `Refused` cells and the 1 `No` cell of that table. The README prose points there for those reasons. `grep -rn README R/ man/` finds no line that says the README gives the reasons.
- [ ] AC6: `NEWS.md` has a bullet for the new table and the shorter resampling prose. The bullet names no milestone number.
- [ ] AC7: `README.md` is rebuilt from `README.Rmd` with `devtools::build_readme()` and shows no further diff. Every gating prose sweep that `Rscript benchmarks/sweep-prose.R --list-gating` prints is clean. `devtools::document()` leaves no diff, and `devtools::check()` gives 0 errors and 0 warnings.

## Coverage

- AC1 → T3
- AC2 → T3, T4
- AC3 → T3
- AC4 → T1, T3
- AC5 → T1, T2
- AC6 → T5
- AC7 → T2, T5

## Tasks

- [x] T1: Shorten the resampling prose in `README.Rmd` (lines 80-175 at 10e1e775). Keep the 17 table lines as they are. Cut the `Yes` paragraph to about 50 words. Replace the per-design reasons and the extra refusal rules with one pointer to `?nested_resamples`. Move the reason for the inner `validation_set()` `No` cell to the help. Drop the Untested paragraph, because no cell reads Untested and D-095 keeps the rule. Keep the `[^validation]` footnote before "Learn more:".
- [x] T2: In the "Differences from rsample" section of `R/nested-resamples.R` (lines 29-72), state the reason for each `Refused` cell and for the inner `validation_set()` `No` cell. Replace the sentence at line 43 that says the README gives the reasons. Point the comment at `R/checks.R:1232` at `?nested_resamples`. Run `devtools::document()`.
- [x] T3: Add the "Supported tuning functions" section, its table and its prose to `README.Rmd`, per AC1-AC3. Check the word count with the AC4 command.
- [x] T4: For each `Yes` row, find the test that runs the row's function with `vfold_cv()` in both loops and asserts that every fold completed. Record each one as a file:line in the work log. `test-nested-workflow-map-oracles.R:47-48` shows completion only through identity with a reference run. Add a direct `all(.completed)` assertion there.
- [ ] T5: Add the NEWS bullet. Run `devtools::build_readme()`, every gating prose sweep, `devtools::document()` and `devtools::check()`.

## Work log

- 2026-09-30: created by /milestone-plan.
- 2026-09-30: criteria audit, full mode, two rounds by a fresh Opus reader. Round 1 found 7 issues and round 2 found 7 more. The main ones: the `Yes` definition was wrong for the two rows that run no search, and the 350-word limit needed named cuts. Also: footnotes escaped the word count, and the help still said the README gives the reasons. Each issue had one clear fix, applied here.
- 2026-09-30: plan gate chose a separate tuning table over per-tuner columns on the resampling table. Per-tuner columns add about 180 cells, most of them Untested. Falsified by users who need per-tuner design support in the README.
- 2026-09-30: plan gate chose eight rows over ten (adding `last_fit()` and `fit_best()`) and over six (search functions only). Falsified by a reader who looks for `last_fit()` in the table and misses `nested_final_fit()`.
- 2026-09-30: plan gate left the known gaps inside supported tuners off the README. The help pages hold them, and each README claim needs upkeep as a gap closes. Falsified by a user surprised by one of the gaps.
- 2026-09-30: plan set the word limit at 400 over 350. The parts that stay already hold about 274 words in today's wording. Falsified by a draft that is still hard to scan at 400 words.
- 2026-09-30: implement started on branch m136-tuning-table. Question gate skipped, because the plan left nothing open.
- 2026-09-30: T1 done. The resampling section is 197 words by the AC4 command, down from 789. Its 17 table lines match 10e1e775, and the plain sweep is clean.
- 2026-09-30: T2 done. `?nested_resamples` now names both outer bootstrap designs and gives the reason for each of the six loo, apparent and permutations cells. It also gives why an inner `validation_set()` fails, read from a run of `inside = validation_set()`. The README sentence and the `R/checks.R` comment now point to the help. `grep -rn README R/ man/` is empty, and both plain sweeps are clean.
- 2026-09-30: T3 done. The "Supported tuning functions" section sits before "Learn more:" with the eight AC1 rows. The two sections hold 351 words by the AC4 command, and the plain sweep is clean.
- 2026-09-30: T4 done. Tests with `vfold_cv()` in both loops that assert every outer fold completed: grid `test-nested-tune-finalize.R:222`, Bayesian `test-nested-tune-bayes-oracles.R:202`, fit_resamples `test-nested-fit-resamples-oracles.R:83`, both racers `test-nested-tune-race-oracles.R:77` (from :116, `det_nested()`), annealing `test-nested-tune-sim-anneal-oracles.R:82` (from :129, `det_nested()`), workflow map `test-nested-workflow-map-oracles.R:48` (new direct assertion). Full suite 14084 expectations, 0 failed.
- 2026-09-30: claim audit: 24 claims read, 3 corrected — README.Rmd, R/nested-resamples.R, NEWS.md, tests/testthat/test-nested-workflow-map-oracles.R. The fixes: the tuners article link, the pointer to the split rules, and the bootstrap sentence about `nested_cv()`. The same reader re-read all three as true. Its finding outside the diff, the "only warns here" error text, went to a candidate row.
- 2026-09-30: T5 in progress. NEWS bullet added, README rebuilt, `document()` run, all six gating sweeps clean at 361 words. `devtools::check()` still running at this checkpoint.

## Decisions

## Review
