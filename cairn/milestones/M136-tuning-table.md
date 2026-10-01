# M136: README table of supported tuning functions, and shorter table prose

- **Status:** review
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

- [x] AC1: `README.Rmd` has a "Supported tuning functions" section after the resampling-design prose and before "Learn more:". Its table has three columns: Function, nestedtune function and Supported. It has eight rows: `tune::tune_grid()`, `tune::tune_bayes()`, `tune::fit_resamples()`, `finetune::tune_race_anova()`, `finetune::tune_race_win_loss()`, `finetune::tune_sim_anneal()`, `workflowsets::workflow_map()` and `tidyclust::tune_cluster()`. The first seven rows read `Yes`. In order, they name `nested_tune_grid()`, `nested_tune_bayes()`, `nested_fit_resamples()`, `nested_tune_race_anova()`, `nested_tune_race_win_loss()`, `nested_tune_sim_anneal()` and `nested_workflow_map()`. The `tune_cluster()` row reads `No` and names no nestedtune function.
- [x] AC2: The prose under that table defines `Yes` and `No`. `Yes` means that nestedtune exports a nested counterpart that does the row's job on a nested design. It also means that the test suite runs that counterpart with `vfold_cv()` in both loops, and that every outer fold completes. The prose says that `nested_fit_resamples()` and `nested_workflow_map()` run no search of their own. `No` means that no nestedtune function does the row's job. For `tune_cluster()`, the prose gives the reason: nothing settles what a nested estimate of a clustering metric means. Each `Yes` row is true at the merge commit. A test in `tests/testthat/` runs the row's nestedtune function on such a design and asserts that every outer fold completed.
- [x] AC3: The prose says that the resampling table's `Yes` cells were tested through `nested_tune_grid()`. It points to the "Time-series designs" section of `?nested_resamples` for the time-series designs that the other six functions are tested on. It links the "Choosing the inner tuner" article.
- [x] AC4: The two sections together hold at most 400 words outside their table rows. At commit 10e1e775, the resampling section alone holds 789. The count is the output of `awk '/^## Supported resampling designs/{f=1} /^Learn more:/{f=0} f && !/^\|/' README.Rmd | wc -w` at the merge commit. Every footnote definition that the two tables use sits before "Learn more:", so the count includes it.
- [x] AC5: The 17 lines that start with `|` in the resampling section are byte-identical to those at 10e1e775. `?nested_resamples` gives the reason for each of the 8 `Refused` cells and the 1 `No` cell of that table. The README prose points there for those reasons. `grep -rn README R/ man/` finds no line that says the README gives the reasons.
- [x] AC6: `NEWS.md` has a bullet for the new table and the shorter resampling prose. The bullet names no milestone number.
- [x] AC7: `README.md` is rebuilt from `README.Rmd` with `devtools::build_readme()` and shows no further diff. Every gating prose sweep that `Rscript benchmarks/sweep-prose.R --list-gating` prints is clean. `devtools::document()` leaves no diff, and `devtools::check()` gives 0 errors and 0 warnings.

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
- [x] T5: Add the NEWS bullet. Run `devtools::build_readme()`, every gating prose sweep, `devtools::document()` and `devtools::check()`.

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
- 2026-09-30: discovered sub-task under T5. The claim audit's outside-diff finding was first a candidate row, which put ROADMAP at its 60-line cap. It is fixed here instead, because the bootstrap error hint contradicted the corrected help sentence. Both hints now read "builds this design, with a warning at most", from a run where `nested_cv()` warned for `bootstraps()` but not for a `group_bootstraps()` call. `test-design-support.R` asserts the text, NEWS says so, and the candidate row is removed. Affected tests: 2033 expectations, 0 failed.
- 2026-09-30: first `devtools::check()`: 0 errors, 0 warnings, 0 notes, on the tree before the claim-audit fixes. Rerunning on the final tree.
- 2026-09-30: the claim reader re-read the hint fix: hint, NEWS sentence and test TRUE, the `R/checks.R` comment IMPRECISE. The comment now names the rset case, and the test also matches the `nested_resamples()` hint. `test-design-support.R`: 755 expectations, 0 failed.
- 2026-09-30: T5 done. Second `devtools::check()`: 0 errors, 0 warnings, 0 notes, on the tree after the hint fix and before the last comment and test edit. `document()` leaves no diff. Status set to review.
- 2026-09-30: review started. AC1 to AC6 verified with fresh evidence. AC7 waits on `devtools::check()`, and the three reviewers are still running.

## Decisions

## Review

Evidence gathered 2026-09-30 on `m136-tuning-table` at cb871a02, level with `origin/main` (10e1e775 is an ancestor, no merge needed).

- AC1: `README.Rmd` puts "## Supported tuning functions" at line 122, after "## Supported resampling designs" (line 80) and before "Learn more:" (line 155). The table has the three named columns and the eight named rows in order. The first seven read `Yes` and name the seven nestedtune functions in the stated order, each one an `export()` line in `NAMESPACE`. The `tidyclust::tune_cluster()` row reads `No` with an empty nestedtune cell.
- AC2: The prose under the table defines `Yes` as an exported nested counterpart that does the row's job. It adds that the suite runs it with `vfold_cv()` in both loops and that every outer fold completes. It says that `nested_fit_resamples()` and `nested_workflow_map()` run no search of their own. It defines `No` and gives the clustering-metric reason for `tune_cluster()`. Each `Yes` row has a test on a design with `vfold_cv()` in both loops that asserts `all(.completed)`. I read each cited line. Grid: `test-nested-tune-finalize.R:222`. Bayesian: `test-nested-tune-bayes-oracles.R:202`. fit_resamples: `test-nested-fit-resamples-oracles.R:83`. Both racers: `test-nested-tune-race-oracles.R:77` through `det_nested()`. Annealing: `test-nested-tune-sim-anneal-oracles.R:82` through `det_nested()`. Workflow map: `test-nested-workflow-map-oracles.R:48` through `final_nested()`. Those six files ran fresh: 904 expectations, 0 failed, 0 skipped, 0 errors.
- AC3: The last README paragraph says that the resampling table's Yes cells were tested through `nested_tune_grid()`. It points to the "Time-series designs" section of `?nested_resamples`, at `man/nested_resamples.Rd:102`. That section names the designs that each of the other six functions is tested on. It links "Choosing the inner tuner" at `articles/tuners.html`, the title of `vignettes/tuners.Rmd`, which `_pkgdown.yml` lists.
- AC4: The AC4 `awk` command over `README.Rmd` gives 361 words, under the 400 limit. The same command over the resampling section at 10e1e775 gives 789, as the criterion states. The one footnote definition, `[^validation]` at line 115, sits before "Learn more:" at line 155, so the count includes it.
- AC5: The 17 lines that start with `|` in the resampling section of `README.Rmd` and of `git show 10e1e775:README.Rmd` compare equal by `cmp`. The table has 8 `Refused` cells and 1 `No` cell. The "Differences from rsample" section of `R/nested-resamples.R` gives a reason for each. Outer `bootstraps()` and `group_bootstraps()` can put one row in both inner sets. Outer `loo_cv()` holds out one row, outer `apparent()` scores on its training rows, and outer `permutations()` has no assessment set. As the inner loop, tune refuses `loo_cv()` and `permutations()` and reports no results for `apparent()`. An inner `validation_set()` takes a split rather than a data frame. The README prose points to that section for each Refused and No cell. `grep -rn README R/ man/` prints nothing.
- AC6: The branch adds one `NEWS.md` bullet at the top of the development section. It names the second table of eight tuning functions and says that the prose under the resampling table is shorter. `grep -n 'M[0-9]\{3\}' NEWS.md` prints nothing.
- AC7: `devtools::build_readme()` rebuilt `README.md` with no diff. All six commands that `--list-gating` prints exit 0 and report clean. `devtools::document()` leaves no diff. `devtools::check()` at cb871a02 gives 0 errors, 0 warnings and 0 notes in 8m 33s.

Consistency gate: `cairn_validate.py` exits 0, with 18 references-staleness advisories that this branch did not touch. `DESIGN.md` is not in the diff, so no principle-impact report is due. `pkgdown::check_pkgdown()` finds no problems. The NEWS entry, `document()`, README and `check()` rows are covered under AC6 and AC7. The diff adds no top-level file.

Independent review: three fresh reviewers. An Opus reviewer read the diff, a Sonnet reviewer read history and blame, and a Sonnet reviewer read past reviews. The PR-comment probe found human comments only on PR #30, which touched none of these files. No finding shows an acceptance criterion failing, so none returns the milestone. Findings, merged across reviewers, with the proposed disposition:

- F1 (history): `cairn/DESIGN.md:159` says that rsample "only warns" about an outer bootstrap. This branch shows that rsample builds `group_bootstraps()` with no warning. Proposed: fix now, corrected in place.
- F2 (all three): the README says that `?nested_resamples` gives the rules that refuse a single split. The racers' refusal of an inner apparent split lives only on the racing help page, and the old README stated it. Proposed: fix now, with one README sentence that points to `?nested_tune_race`.
- F3 (past reviews): the header of `tests/testthat/test-design-support.R:7` says that the README gives the reason for the `No` cell. Proposed: fix now, to point at `?nested_resamples`.
- F4 (Opus): the comment at `R/checks.R:349-351` says that rsample warns for "a bootstraps() call". rsample matches the deparsed call text, so `rsample::bootstraps()` builds with no warning. The user hint ("at most") stays true. Proposed: fix now, comment only.
- F5 (Opus): the README sentence "a design that `nested_resamples()` builds" describes a design that it refuses to build. Proposed: fix now, to say that `nested_resamples()` refuses it and each nestedtune function refuses one built another way at entry.
- F6 (all three): the new help line at `R/nested-resamples.R:51` runs 87 characters, and the `R/checks.R:1235` comment breaks early. Proposed: fix now, reflow only.
- F7 (two reviewers): the README no longer defines Untested, while D-095 keeps the rule. Proposed: reject, because T1 dropped it on purpose and no cell reads Untested.
- F8 (Opus): the README defines No as "cannot be built", narrower than D-095. Proposed: reject, because D-096 turned the invalid-estimate cells into Refused, so only an unbuildable design is left for No.
- F9 (history): two Yes qualifiers left the README. Proposed: reject, because the help still gives the per-pair detail.
- F10 (two reviewers): the new `all(.completed)` assertion in the workflow-map test repeats what the identity check implies. Proposed: reject, because T4 asked for a direct assertion.
- F11 (history): `test-design-support.R:648` carries an "(M136)" tag. Proposed: reject, because 42 test files use such tags in comments.
- F12 (past reviews): `test-nested-tune-grid-checks.R:140` says "rsample only warns here". Proposed: reject, because that test builds `bootstraps()`, which does warn.
- F13 (past reviews): the help says "each outer fold that tunes on one of them fails", and `nested_fit_resamples()` tunes nothing. Proposed: reject, because the sentence speaks only of folds that tune.
- F14 (Opus): the help's `validation_set()` wording is loose. Proposed: reject, because the reviewer found it true.
- F15 (Opus): the `tune_cluster()` reason has no recorded basis. Proposed: reject, because AC2 requires that sentence and D-110 records the row.
