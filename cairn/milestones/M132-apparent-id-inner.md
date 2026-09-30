# M132: Refuse an inner "Apparent" split that tune drops or a race misreads

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP3
- **Resolves:** —
- **Surface tier:** user-facing — it changes which designs the exported functions refuse
- **Branch/PR:** m132-apparent-id-inner

## Goal

Tuning runs on an inner design only where tune and finetune read each of its splits the way the user built them (D-100).

## Scope

**In:** Two inner-loop refusals with class `nestedtune_bad_design`. The first refuses a split whose id is "Apparent", unless it is the apparent split of a bootstrap design. tune leaves that one out on purpose. The second rule applies under the two racers. It refuses that apparent split too, because the race reads its in-sample score. Both rules apply at `check_nested()`, at `nested_resamples()` from `inside`, and in the pre-loop of `nested_workflow_map()`. They also apply to the design that `nested_final_fit()` rebuilds. The README, four help sites, a NEWS bullet and the DESIGN convention bullet state them.

**Out:**
- The package scores an outer fold whose id is "Apparent" as normal. It summarizes outer folds itself, and `last_fit()` sees its own split id. No row, because nothing is wrong.
- The Bayes, annealing and grid tuners keep accepting the apparent split of a bootstrap design. tune's summarized estimate leaves it out. No row.
- A finetune issue about the race reading the "Apparent" split is the maintainer's call to file. No row, because D-100 names such a finetune release as its falsifier.

## Acceptance criteria

- [x] AC1: The six run functions share the entry check `check_nested()`. They are `nested_tune_grid()`, `nested_tune_bayes()`, `nested_tune_race_anova()`, `nested_tune_race_win_loss()`, `nested_tune_sim_anneal()` and `nested_fit_resamples()`. Take an inner design that holds a split whose id is "Apparent". Unless that split is an apparent split beside bootstrap splits, `check_nested()` refuses the design before any fold runs. As it builds the design from `inside`, `nested_resamples()` refuses it. Both use class `nestedtune_bad_design`. Bootstrap splits here come from `rsample::bootstraps()` or `rsample::group_bootstraps()`. `tests/testthat/test-design-support.R` fires the refusal through `nested_tune_grid()` and through `nested_resamples()`, with its class asserted. It uses three inner designs. The first two are `vfold_cv()` designs with one fold relabelled "Apparent", once as a character id and once as a factor id. The third is a `bootstraps()` design with one bootstrap split relabelled "Apparent". A passing control runs an inner `bootstraps(apparent = TRUE)` design through `nested_tune_grid()`.
- [x] AC2: Take an inner design that holds an apparent split whose id is "Apparent", beside bootstrap splits. `nested_tune_race_anova()` and `nested_tune_race_win_loss()` refuse it before any fold runs, with class `nestedtune_bad_design`. If any workflow in a set routes to a racer, `nested_workflow_map()` refuses such a design before any workflow runs. The message says that the race eliminates candidates on the score of that split. It also says that this score comes from the rows the model trained on. Tests assert the class and that reason in six cases. Each racer is called directly on an inner `bootstraps(apparent = TRUE)` design. `nested_tune_race_anova()` is called on an inner `group_bootstraps(apparent = TRUE)` design. It is also called on a `manual_rset()` rebuild of an inner `bootstraps(apparent = TRUE)` design, and on such a design whose ids are a factor. `nested_workflow_map()` is called with each racer as `fn`. Its set has a first workflow with no `tune()` marks and a second workflow with them, and no fold of the first workflow runs. A passing control runs `nested_tune_race_anova()` on an inner `bootstraps(apparent = FALSE)` design.
- [x] AC3: `nested_final_fit()` rebuilds an inner design on the whole data. It applies the AC1 rule to that design. If the recorded tuner is a racer, it also applies the AC2 rule. It refuses with class `nestedtune_bad_design` before it tunes. Two tests assert the class. In the first, the `inside` of a grid result is replaced with a call that returns a `vfold_cv()` design with one fold relabelled "Apparent". In the second, the `inside` of a racer result is replaced with `bootstraps(apparent = TRUE)`.
- [x] AC4: Three sites state the AC1 rule. They are the README paragraph on refused designs, the design block of `?nested_resamples`, and the "Nested designs" section of `?nested_tune_grid`. The racers' page inherits that section. Text on the racers' page alone states the AC2 rule. The "What is refused" section of `?nested_final_fit` states the check of the final fit and its class. One NEWS bullet states both rules and the check of the final fit.
- [x] AC5: `devtools::test()` gives 0 failures. `devtools::check()` gives 0 errors, 0 warnings and 0 notes. `Rscript benchmarks/sweep-prose.R --plain` and `--roxygen --plain` are clean.

## Coverage

- AC1 → T1, T2
- AC2 → T3, T4
- AC3 → T5
- AC4 → T6
- AC5 → T6

## Tasks

- [x] T1: Write the AC1 tests first, in `tests/testthat/test-design-support.R`. Relabel the ids with `$<-` or `rsample::manual_rset()`. `rebuilt()` (line 326) keeps the original ids, so it does not work here. Use `entry_refusal()` (line 163) for the `nested_tune_grid()` cases. For `nested_resamples()`, give `inside` a call to a local builder. The refusals fail on the current code, and the `apparent = TRUE` control passes.
- [x] T2: Add the AC1 rule in `R/checks.R`, beside `check_inner_refused()` (line 599). Reuse `apparent_ids()` and `split_designs()`. Call the rule from `check_nested()` and from `inner_resamples_from_split()` (`R/nested-resamples.R:231`). Give cli the message text as values (M83 lesson). Update the comments at `R/checks.R:479` and `:495`.
- [x] T3: Write the AC2 tests first. If `tuner_ready()` is false, the racer tests skip. The map tests take `skip_if_no_wset_fixture()` (M101 lesson). To show that no fold of the unmarked first workflow ran, mock the fold dispatch with the `entry_refusal()` sentinel, which fails on any call.
- [x] T4: Add the AC2 rule as a helper in `R/checks.R`. Call it at the entry of the racers in `R/nested-tune-race.R`. Also call it in the pre-loop of `nested_workflow_map()` (`R/nested-workflow-map.R:191`), for each workflow that routes to a racer.
- [x] T5: Write the AC3 tests first. Then apply the AC1 rule in `nested_final_fit()` to the rset that `eval_inside_spec()` returns (`R/nested-final-fit.R:424`). For a racer result alone, also apply the AC2 rule.
- [x] T6: Update the documentation and run the checks. Change the Refused paragraph in `README.Rmd` and run `devtools::build_readme()`. Change `R/nested-resamples.R:40` and the "Nested designs" section at `R/nested-tune-grid.R:115`. Add text for the racers alone in `R/nested-tune-race.R`. Add the final fit's check to its "What is refused" section (`R/nested-final-fit.R:98`). Add the NEWS bullet and update the DESIGN.md convention bullet on invalid designs. Run `devtools::document()`, both prose sweeps, `devtools::test()` and `devtools::check()`.

## Work log

- 2026-09-29: created by /milestone-plan. It absorbs the `[low]` candidate row from the M131 review (findings O3 and O4).
- 2026-09-29: the criteria audit ran in full mode, with a fresh [O] reader, and found 7 items. `nested_final_fit()` never calls `check_nested()`, so "seven entry functions" was false. "Before any fold runs" meant nothing for `nested_resamples()`. The map pre-loop does not call `check_nested()`. The map applies a racer by the route of a workflow, not by `fn` (D-058). The probes had no factor id and no `manual_rset()` rebuild. AC4 named a shared help text that does not exist. The racer refusal narrows D-099, so it needs a D-entry. The plan fixed all but one item before the gate. The gate settled the final fit item.
- 2026-09-29: the same reader checked the revised criteria and found 3 items. AC4 did not name the "What is refused" section of `?nested_final_fit`. A map test set of unmarked workflows alone routes nothing to a racer. AC3 did not name how its test builds the results object. The plan fixed all three.
- 2026-09-29: the plan gate chose to refuse the apparent split of a bootstrap design under the racers, over documenting the flaw. The split gives a race nothing. Falsified by a finetune release whose race leaves the "Apparent" split out.
- 2026-09-29: the plan gate chose to refuse, over dropping the apparent split before the race. Dropping changes the design without a word, and the inner record then differs from a direct finetune call. Falsified by a user who needs the split kept in a raced inner record.
- 2026-09-29: the plan gate chose to refuse a renamed "Apparent" split, over a warning that GP3 rules out. Falsified by a supported design that uses the id "Apparent" for a split that tune must score.
- 2026-09-29: the plan gate chose to check the design that `nested_final_fit()` rebuilds, over leaving it out. Then no path tunes on such a design.
- 2026-09-29: T1 and T2 done. `check_inner_apparent_ids()` and `misread_apparent_rows()` in `R/checks.R` refuse an inner split under the id "Apparent" that is not an apparent split, from `check_nested()` and `inner_resamples_from_split()`. The two new tests failed on the old code at the fold-dispatch sentinel and pass now. `devtools::test()` gave 0 failures, and the plain prose sweep is clean.
- 2026-09-29: T3 and T4 done. `check_race_apparent()` in `R/checks.R` refuses an inner apparent split at the racers' entry. For a set with a workflow that routes to a racer, it also refuses one in the pre-loop of `nested_workflow_map()`. T3 now names the `entry_refusal()` sentinel on the fold dispatch in place of a mocked `nested_fit_resamples()`, a minor edit: the sentinel fails on any fold of any route. The three new tests failed at that sentinel on the old code and pass now, unskipped. `devtools::test()` gave 0 failures, and the plain prose sweep is clean.
- 2026-09-29: checkpoint, T5 not yet ticked. `check_final_inner()` in `R/checks.R` is called from `final_fit_worker()`. The two AC3 tests in `test-nested-final-fit-checks.R` failed on the old code, because each final fit ran through, and they pass now. The full-suite run for T5 was still going at this commit.
- 2026-09-29: T5 done. The full suite on the checkpoint tree gave 0 failures, and the plain prose sweep is clean.
- 2026-09-29: checkpoint, T6 not yet ticked. The README paragraph, `?nested_resamples`, the "Nested designs" section of `?nested_tune_grid`, the racers' details, the "What is refused" section of `?nested_final_fit`, NEWS and the DESIGN convention bullet state the rules. Both prose sweeps are clean. The full suite and `devtools::check()` were still running at this commit.
- 2026-09-29: claim audit: 48 claims read, 4 corrected. R/checks.R, R/nested-final-fit.R. `check_final_inner()` accepted v-fold splits beside an apparent split under the id "Apparent", which the entry check refuses. `misread_apparent_rows()` now accepts that id only on an apparent split that joins a bootstrap design, and a new final-fit case failed before the fix and passes after it. Two comments assumed an entry check ran first, and the final fit's help said the entry checks "refuse both". The earlier suite run was stopped, because its code changed.
- 2026-09-30: T6 done. The full suite at `e0b1f1a6` failed only in `test-sweep-prose.R`. The `--roxygen` sweep found two sentences over 30 words in the final fit's help. After the split, all three sweep modes are clean and that test passes. `devtools::check()` at `e0b1f1a6` gave 0 errors, 0 warnings and 0 notes. Status set to review.
- 2026-09-30: review checkpoint. AC1-AC4 evidence recorded and ticked, and `devtools::check()` for AC5 still running at this commit.
- 2026-09-30: pre-gate checkpoint. AC5 and the consistency gate are recorded and green. Thirteen reviewer findings are logged, and none shows a criterion failing.
- 2026-09-30: gate fixes checkpoint. F1-F5 are fixed, D-101 is added and F6-F8 are one candidate row. The two changed test files pass and all six sweeps are clean. The full suite on this tree was still running at this commit.

## Decisions

## Review

Evidence gathered 2026-09-30 on `43506a8c`, which contains `origin/main` (`676ffb7a`), so no merge was needed.

- AC1: `devtools::test()` passed "an inner split relabelled Apparent is refused" in `test-design-support.R`. It runs a v-fold design with a character id, one with a factor id and a bootstrap design, each with one split relabelled "Apparent". Each goes through `nested_tune_grid()` and through `nested_resamples()` from `inside`. Both calls assert class `nestedtune_bad_design` and the reason. `entry_refusal()` makes the fold dispatch fail with a sentinel class, so the refusal comes before any fold runs. The control "a bootstrap's own apparent split still reaches the folds" reaches that sentinel on `bootstraps(apparent = TRUE)`.
- AC2: the same run passed "the racers refuse a bootstrap's apparent split at entry". It also passed "the map refuses a bootstrap's apparent split before any workflow runs". `tuner_ready()` was TRUE for both racers. The suite reported 0 skips, so every case ran. Each racer runs on `bootstraps(apparent = TRUE)`. `nested_tune_race_anova()` also runs on `group_bootstraps(apparent = TRUE)`, on a `manual_rset()` rebuild and on a factor id. The map runs with each racer as `fn` and an unmarked first workflow. Each case asserts the class and both parts of the reason. The map case gets the refusal, not the sentinel of a fold dispatch. The control on `bootstraps(apparent = FALSE)` reaches the sentinel.
- AC3: in `test-nested-final-fit-checks.R`, the same run passed "the final fit refuses an inner split relabelled Apparent". It also passed "the final fit of a race refuses a bootstrap's apparent split". The first gives a grid result an `inside` call that returns a relabelled `vfold_cv()` design. It also tries v-fold splits beside an apparent split. The second gives a racer result `bootstraps(apparent = TRUE)`. Each asserts `nestedtune_bad_design` from `nested_final_fit()`. `check_final_inner()` runs in `final_fit_worker()` before `run_tuner()` (`R/nested-final-fit.R:435`).
- AC4: read on `43506a8c`. The README paragraph on refused designs, the design block of `man/nested_resamples.Rd` and the "Nested designs" section of `man/nested_tune_grid.Rd` state the AC1 rule. `man/nested_tune_race.Rd` carries that section, and the race text ("eliminates race candidates") appears in no other `.Rd` file. The "What is refused" section of `man/nested_final_fit.Rd` (line 100) states the final fit's check and its class at line 139. One NEWS bullet states both rules and the final fit's check.
- AC5: on `43506a8c`, `devtools::test()` gave 0 failures, 0 errors, 0 skips and 13740 passes. `devtools::check()` gave 0 errors, 0 warnings and 0 notes. All six gating prose sweeps from `--list-gating` printed "clean", `--plain` and `--roxygen --plain` among them.
- Consistency gate: `cairn_validate.py` exited 0 with 18 references-staleness advisories, none from this branch. `devtools::document()` and `devtools::build_readme()` left no diff. `pkgdown::check_pkgdown()` found no problems. NEWS has the bullet, and no new top-level file was added. No DESIGN principle changed, so `cairn_impact` was skipped.

Findings from three fresh reviewers: O is the diff reviewer, B the blame-history reviewer, P the prior-review reviewer. No finding shows a criterion failing. Proposed dispositions are awaiting the gate.

- F1 (O6, B3, P1): the new refusal text says "an inner split that tuning would leave out" and "the fold would tune on fewer resamples". It also fires from `nested_fit_resamples()`, which tunes nothing. The inherited help says the same. M128 fixed the same flaw in the older inner refusals. Proposed: fix now.
- F2 (O5): the racer entry test skips a racer that is not ready with `next`, so a case can vanish with no skip reported. In the map test, a skip inside the loop drops both racers. Proposed: fix now.
- F3 (P2): the new paragraph in the final fit's "What is refused" section sits before refusals that fire earlier, which breaks M53's firing order. Proposed: fix now.
- F4 (P3): the DESIGN paragraph that lists the final fit's refusals does not name the new check. Proposed: fix now.
- F5 (O4): the milestone Scope and D-100 say both rules apply at `nested_resamples()` and in the map pre-loop. `nested_resamples()` applies only the first, and the map pre-loop only the race rule. The first rule still fires before any fold in the map, from each workflow's entry check. Proposed: fix now, by one D-entry correcting D-100.
- F6 (O1): an inner split with an NA id is dropped by tune the same way, and nothing refuses it. Probed: `fit_resamples()` on a 3-fold design with one NA id gives n = 2 and an empty metric row. It predates this branch. Proposed: follow-up.
- F7 (O2, O3): the final fit's rebuilt design gets only the two new rules, not the older inner refusals. For an `inside` of `apparent()` or `permutations()`, its message advises "Give the split another id", which does not fix the design. Proposed: follow-up.
- F8 (B2): a split rebuilt with `make_splits()` loses its apparent class. Under the id "Apparent" it is refused with a reason that does not fit, and a racer does not see it. Proposed: follow-up.
- F9 (B1): the older hint says a bootstrap keeps its apparent split only under "Apparent", and a racer then refuses that split. The second message names the fix (`apparent = FALSE`). Proposed: reject.
- F10 (O7): in a racer map, the race message comes before the message a direct call gives. Both refuse the design truthfully. Proposed: reject.
- F11 (B4): the map's race refusal names no workflow. The design is shared by the whole call, so there is no one workflow to name. Proposed: reject.
- F12 (O8): two "Apparent" apparent splits beside bootstrap splits are accepted. tune drops both, and the racers refuse them. Proposed: reject, informational.
- F13 (B5): the final fit of an untuned result never builds an inner design, so it skips the check. This matches M70. Proposed: noted.

Triage, 2026-09-30: the maintainer accepted every proposed disposition.

- F1 fixed. The headline now says "an inner split that tune would leave out of its estimates". The reason says "each outer fold that tunes on it would use fewer resamples". The inherited help and the README say the same.
- F2 fixed. Each racer's entry case and each map case is its own `test_that()` block with its own skip. The rebuilt and grouped cases moved to a separate block.
- F3 fixed. The final fit's paragraph on its rebuilt design now comes last in "What is refused", opening with "Last, just before tuning". Every other check in `nested_final_fit()` runs before `final_fit_worker()`.
- F4 fixed. The DESIGN paragraph on `nested_final_fit()` names `check_final_inner()`.
- F5 fixed by D-101, which corrects D-100's site list. A probe under `nested_workflow_map()` with `fn = "nested_fit_resamples"` showed its consequence: the refusal carries the prefix `Workflow "a":`.
- F6, F7 and F8 became one candidate row in ROADMAP, "M132's review leftovers".
- F9, F10, F11 and F12 rejected, and F13 noted, for the reasons above.

Re-verified after the fixes, on `8963aab9`. The first suite run at `dd32dc7a` failed twice in `test-sweep-prose.R`, because the roxygen sweep flagged "just" in the F3 paragraph, and `8963aab9` drops the word. On `8963aab9`, `devtools::test()` gave 0 failures, 0 skips and 13740 passes. `devtools::check()` gave 0 errors, 0 warnings and 0 notes, and all six sweeps exit 0 with "clean".
