# M132: Refuse an inner "Apparent" split that tune drops or a race misreads

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP3
- **Resolves:** —
- **Surface tier:** user-facing — it changes which designs the exported functions refuse
- **Branch/PR:** —

## Goal

Tuning runs on an inner design only where tune and finetune read each of its splits the way the user built them (D-100).

## Scope

**In:** Two inner-loop refusals with class `nestedtune_bad_design`. The first refuses a split whose id is "Apparent", unless it is the apparent split of a bootstrap design. tune leaves that one out on purpose. The second rule applies under the two racers. It refuses that apparent split too, because the race reads its in-sample score. Both rules apply at `check_nested()`, at `nested_resamples()` from `inside`, and in the pre-loop of `nested_workflow_map()`. They also apply to the design that `nested_final_fit()` rebuilds. The README, four help sites, a NEWS bullet and the DESIGN convention bullet state them.

**Out:**
- The package scores an outer fold whose id is "Apparent" as normal. It summarizes outer folds itself, and `last_fit()` sees its own split id. No row, because nothing is wrong.
- The Bayes, annealing and grid tuners keep accepting the apparent split of a bootstrap design. tune's summarized estimate leaves it out. No row.
- A finetune issue about the race reading the "Apparent" split is the maintainer's call to file. No row, because D-100 names such a finetune release as its falsifier.

## Acceptance criteria

- [ ] AC1: The six run functions share the entry check `check_nested()`. They are `nested_tune_grid()`, `nested_tune_bayes()`, `nested_tune_race_anova()`, `nested_tune_race_win_loss()`, `nested_tune_sim_anneal()` and `nested_fit_resamples()`. Take an inner design that holds a split whose id is "Apparent". Unless that split is an apparent split beside bootstrap splits, `check_nested()` refuses the design before any fold runs. As it builds the design from `inside`, `nested_resamples()` refuses it. Both use class `nestedtune_bad_design`. Bootstrap splits here come from `rsample::bootstraps()` or `rsample::group_bootstraps()`. `tests/testthat/test-design-support.R` fires the refusal through `nested_tune_grid()` and through `nested_resamples()`, with its class asserted. It uses three inner designs. The first two are `vfold_cv()` designs with one fold relabelled "Apparent", once as a character id and once as a factor id. The third is a `bootstraps()` design with one bootstrap split relabelled "Apparent". A passing control runs an inner `bootstraps(apparent = TRUE)` design through `nested_tune_grid()`.
- [ ] AC2: Take an inner design that holds an apparent split whose id is "Apparent", beside bootstrap splits. `nested_tune_race_anova()` and `nested_tune_race_win_loss()` refuse it before any fold runs, with class `nestedtune_bad_design`. If any workflow in a set routes to a racer, `nested_workflow_map()` refuses such a design before any workflow runs. The message says that the race eliminates candidates on the score of that split. It also says that this score comes from the rows the model trained on. Tests assert the class and that reason in six cases. Each racer is called directly on an inner `bootstraps(apparent = TRUE)` design. `nested_tune_race_anova()` is called on an inner `group_bootstraps(apparent = TRUE)` design. It is also called on a `manual_rset()` rebuild of an inner `bootstraps(apparent = TRUE)` design, and on such a design whose ids are a factor. `nested_workflow_map()` is called with each racer as `fn`. Its set has a first workflow with no `tune()` marks and a second workflow with them, and no fold of the first workflow runs. A passing control runs `nested_tune_race_anova()` on an inner `bootstraps(apparent = FALSE)` design.
- [ ] AC3: `nested_final_fit()` rebuilds an inner design on the whole data. It applies the AC1 rule to that design. If the recorded tuner is a racer, it also applies the AC2 rule. It refuses with class `nestedtune_bad_design` before it tunes. Two tests assert the class. In the first, the `inside` of a grid result is replaced with a call that returns a `vfold_cv()` design with one fold relabelled "Apparent". In the second, the `inside` of a racer result is replaced with `bootstraps(apparent = TRUE)`.
- [ ] AC4: Three sites state the AC1 rule. They are the README paragraph on refused designs, the design block of `?nested_resamples`, and the "Nested designs" section of `?nested_tune_grid`. The racers' page inherits that section. Text on the racers' page alone states the AC2 rule. The "What is refused" section of `?nested_final_fit` states the check of the final fit and its class. One NEWS bullet states both rules and the check of the final fit.
- [ ] AC5: `devtools::test()` gives 0 failures. `devtools::check()` gives 0 errors, 0 warnings and 0 notes. `Rscript benchmarks/sweep-prose.R --plain` and `--roxygen --plain` are clean.

## Coverage

- AC1 → T1, T2
- AC2 → T3, T4
- AC3 → T5
- AC4 → T6
- AC5 → T6

## Tasks

- [ ] T1: Write the AC1 tests first, in `tests/testthat/test-design-support.R`. Relabel the ids with `$<-` or `rsample::manual_rset()`. `rebuilt()` (line 326) keeps the original ids, so it does not work here. Use `entry_refusal()` (line 163) for the `nested_tune_grid()` cases. For `nested_resamples()`, give `inside` a call to a local builder. The refusals fail on the current code, and the `apparent = TRUE` control passes.
- [ ] T2: Add the AC1 rule in `R/checks.R`, beside `check_inner_refused()` (line 599). Reuse `apparent_ids()` and `split_designs()`. Call the rule from `check_nested()` and from `inner_resamples_from_split()` (`R/nested-resamples.R:231`). Give cli the message text as values (M83 lesson). Update the comments at `R/checks.R:479` and `:495`.
- [ ] T3: Write the AC2 tests first. If `tuner_ready()` is false, the racer tests skip. The map tests take `skip_if_no_wset_fixture()` (M101 lesson). To show that no fold of the unmarked first workflow ran, mock `nested_fit_resamples()` with a function that fails on any call.
- [ ] T4: Add the AC2 rule as a helper in `R/checks.R`. Call it at the entry of the racers in `R/nested-tune-race.R`. Also call it in the pre-loop of `nested_workflow_map()` (`R/nested-workflow-map.R:191`), for each workflow that routes to a racer.
- [ ] T5: Write the AC3 tests first. Then apply the AC1 rule in `nested_final_fit()` to the rset that `eval_inside_spec()` returns (`R/nested-final-fit.R:424`). For a racer result alone, also apply the AC2 rule.
- [ ] T6: Update the documentation and run the checks. Change the Refused paragraph in `README.Rmd` and run `devtools::build_readme()`. Change `R/nested-resamples.R:40` and the "Nested designs" section at `R/nested-tune-grid.R:115`. Add text for the racers alone in `R/nested-tune-race.R`. Add the final fit's check to its "What is refused" section (`R/nested-final-fit.R:98`). Add the NEWS bullet and update the DESIGN.md convention bullet on invalid designs. Run `devtools::document()`, both prose sweeps, `devtools::test()` and `devtools::check()`.

## Work log

- 2026-09-29: created by /milestone-plan. It absorbs the `[low]` candidate row from the M131 review (findings O3 and O4).
- 2026-09-29: the criteria audit ran in full mode, with a fresh [O] reader, and found 7 items. `nested_final_fit()` never calls `check_nested()`, so "seven entry functions" was false. "Before any fold runs" meant nothing for `nested_resamples()`. The map pre-loop does not call `check_nested()`. The map applies a racer by the route of a workflow, not by `fn` (D-058). The probes had no factor id and no `manual_rset()` rebuild. AC4 named a shared help text that does not exist. The racer refusal narrows D-099, so it needs a D-entry. The plan fixed all but one item before the gate. The gate settled the final fit item.
- 2026-09-29: the same reader checked the revised criteria and found 3 items. AC4 did not name the "What is refused" section of `?nested_final_fit`. A map test set of unmarked workflows alone routes nothing to a racer. AC3 did not name how its test builds the results object. The plan fixed all three.
- 2026-09-29: the plan gate chose to refuse the apparent split of a bootstrap design under the racers, over documenting the flaw. The split gives a race nothing. Falsified by a finetune release whose race leaves the "Apparent" split out.
- 2026-09-29: the plan gate chose to refuse, over dropping the apparent split before the race. Dropping changes the design without a word, and the inner record then differs from a direct finetune call. Falsified by a user who needs the split kept in a raced inner record.
- 2026-09-29: the plan gate chose to refuse a renamed "Apparent" split, over a warning that GP3 rules out. Falsified by a supported design that uses the id "Apparent" for a split that tune must score.
- 2026-09-29: the plan gate chose to check the design that `nested_final_fit()` rebuilds, over leaving it out. Then no path tunes on such a design.

## Decisions

## Review
