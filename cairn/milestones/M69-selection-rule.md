# M69: A `select` argument on the five orchestrators takes a `selection_rule()`, and the final fit applies the recorded rule

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, IP4, GP1, GP3
- **Resolves:** —
- **Surface tier:** user-facing — an exported argument on the five orchestrators and a new exported constructor
- **Branch/PR:** —

## Goal

Let the caller choose the rule each outer fold selects its candidate by, from tune's three selectors, recorded in the procedure so the final fit applies the same rule.

## Scope

**In:** an exported constructor `selection_rule(rule = c("best", "one_std_err", "pct_loss"), ..., limit = NULL)` returning a classed list holding the rule name, the parameter orderings in `...` captured as bare expressions (`rlang::enexprs()`, so nothing carries an environment onto the wire or into the fixture cache), and `limit`, which is `NULL` unless the rule is `"pct_loss"`, where an absent limit takes tune's default of 2. A `select = selection_rule("best")` argument on `nested_tune_grid()`, `nested_tune_bayes()`, `nested_tune_race_anova()`, `nested_tune_race_win_loss()` and `nested_tune_sim_anneal()`, checked at entry, sent with each fold, and applied in `nested_fold_fit()` as `tune::select_best()`, `tune::select_by_one_std_err()` or `tune::select_by_pct_loss()` on the fold's tuning run with `metric` the first metric name, the orderings spliced in, and `limit` for the percent-loss rule; `eval_time` stays unpassed, as today. The rule joins the `procedure` record as `select`, a shared name the final fit reads and never forwards to the tuner, and `nested_final_fit()` applies it in place of its `select_best()` call. Help on all six pages, the tuners vignette's selection sentences, NEWS, DESIGN's orchestration line.

**Out:** naming the rule in `summary()` or the final fit's print (a candidate row; `extract_procedure()` reaches it); the untuned baseline, `workflow_set` and `summarize = TRUE` rows (unchanged candidates); a rule outside tune's three (none asked for); passing `eval_time` to the selector (D-038 reasoning stands); migrating a results object saved before this milestone (D-041 declined migration; such a record is refused by the final fit as a record lacking `select`).

## Acceptance criteria

- [ ] AC1: Under each of `selection_rule("best")` (the default), `selection_rule("one_std_err", <ordering>)` and `selection_rule("pct_loss", <ordering>, limit = 5)`, every completed fold's `.selected` is identical to the row the matching tune selector returns on that fold's inner tuning run with the same metric, orderings and limit, computed by the four reference loops in `tests/testthat/helper-orchestration.R` (`reference_nested_loop()`, `reference_nested_bayes_loop()`, `reference_nested_race_loop()` for both racers, `reference_nested_anneal_loop()`) each given the rule; the grid probe runs on `bayes_workflow()` with the two-term ordering `desc(df1), df2`, the other four on the fixtures their oracle tests already use with a one-term ordering; the existing default-rule oracle tests pass unchanged.
- [ ] AC2: `extract_procedure(res)$select` is identical to the `selection_rule()` the call was given, and `nested_final_fit(object, res)$selected` is identical to the matching tune selector applied to `nested_final_fit(object, res)$tuning` with the recorded orderings and limit, for each of the three rules on the grid orchestrator over `bayes_workflow()`; a results object whose record has no `select` entry is refused by `nested_final_fit()` with the class `check_results_record()` uses for a missing record.
- [ ] AC3: `selection_rule()` refuses each of these at construction with the named class: a `rule` outside the three names (`rlang::arg_match()`'s `rlang_error`); `"one_std_err"` or `"pct_loss"` with no ordering (`nestedtune_selection_rule_no_order`); a `limit` given with `"best"` or `"one_std_err"`, and each of `limit = -1`, `NA_real_`, `c(1, 2)` and `"2"` with `"pct_loss"` (`nestedtune_selection_rule_limit`).
- [ ] AC4: Each of the five orchestrators refuses at entry, with the error's call naming the orchestrator and no fold run, `select = "best"` and `select = NULL` (`nestedtune_bad_selection_rule`) and an ordering whose symbols include a name that is not one of `object`'s tuned parameter ids (`nestedtune_selection_rule_unknown_param`, naming the symbol and the ids).
- [ ] AC5: Under `selection_rule("pct_loss", <ordering>, limit = 5)`, the grid orchestrator's run on two mirai daemons is identical to its serial run, as `test_that()` block BC15 in `tests/testthat/test-parallel-identity.R`.
- [ ] AC6: The five orchestrator help pages document `select` in their arguments and under "Differences from calling tune directly", and no roxygen line of `R/nested-tune-grid.R`, `R/nested-tune-bayes.R`, `R/nested-tune-race.R`, `R/nested-tune-sim-anneal.R` or prose line of `vignettes/tuners.Rmd` states that selection is by `select_best()` or "the best candidate" without naming the rule, the sweep being `grep -n "select_best\|best candidate"` over those files restricted to `#'` lines and vignette prose; `selection_rule()` has its own help page with an executed example and a `_pkgdown.yml` row.
- [ ] AC7: `devtools::document()` produces no diff, `devtools::test()` passes, and `devtools::check()` reports 0 errors and 0 warnings, any NOTE justified in the review evidence.

## Coverage

- AC1 → T2
- AC2 → T3
- AC3 → T1
- AC4 → T2
- AC5 → T4
- AC6 → T1, T5
- AC7 → T6

## Tasks

- [ ] T1: `R/selection-rule.R`: `selection_rule()` with `rlang::arg_match()` on `rule`, `rlang::enexprs(...)` for the orderings, the three refusals of AC3, a `new_selection_rule()` constructor and `is_selection_rule()`; roxygen with an executed example, `@export`, `_pkgdown.yml` row after `extract_procedure` (`_pkgdown.yml:53`). Tests first in `test-selection-rule.R`: each refusal by class, the captured orderings carry no environment (`rlang::is_quosure()` false on each), `limit` defaults to 2 only for `"pct_loss"`.
- [ ] T2: `check_selection_rule(select, object, call)` in `R/checks.R` beside `check_dots_control()` (`R/checks.R:1132`), the unknown-symbol check reading `tune::extract_parameter_set_dials(object)$id` as `R/checks.R:653` does; `select` formal after `eval_time` on the five signatures (`R/nested-tune-grid.R:537`, `R/nested-tune-bayes.R:209`, `R/nested-tune-race.R:209,235,268`, `R/nested-tune-sim-anneal.R:228`); threaded through `dispatch_folds()` (`R/nested-tune-grid.R:622`) and `fold_task()` (`R/parallel.R:1211`) to `nested_fold_fit()` (`R/nested-tune-grid.R:654`); `apply_selection_rule(tuned, select, metric_name)` in `R/selection-rule.R` replacing the call at `R/nested-tune-grid.R:710`, splicing the orderings with `!!!`; `new_procedure()` gains `select` and `procedure_tuner()`'s `shared` vector names it (`R/tuner.R:255,276`). The four reference loops gain a `select` argument applied at `helper-orchestration.R:102,181,1690,1921`; oracle tests for AC1 in the four `*-oracles.R` files; AC4's refusals in the five `*-checks.R` files.
- [ ] T3: `nested_final_fit()` reads `procedure$select` (`R/nested-final-fit.R:279`) and `apply_selection_rule()` replaces the call at `R/nested-final-fit.R:342`; a record without `select` is refused where `check_results_record()` refuses a missing record. Tests for AC2 in `test-nested-final-fit-results.R`, the `extract_procedure()` identity in `test-extract-procedure.R`.
- [ ] T4: BC15 in `test-parallel-identity.R` after BC14 (`:803`), on the same two-daemon shape, with the percent-loss rule and `limit = 5`; the `helper-time-budget.R` ledger row if the block is budgeted.
- [ ] T5: The five help pages: `@param select`, a "Selected by" paragraph under "Differences from calling tune directly" (`R/nested-tune-grid.R:430`), the `.selected` sentence at `R/nested-tune-grid.R:131` and the `select_best()` sentence at `:500`, and the sibling pages' `res$.selected[[i]]` sentences (`R/nested-tune-race.R:96`, `R/nested-tune-sim-anneal.R:114`); `vignettes/tuners.Rmd:360`; NEWS entry; DESIGN Function Families orchestration line names the argument and constructor. Run AC6's sweep and fix what it finds.
- [ ] T6: `devtools::document()`, `devtools::test()`, `devtools::check()`; `air format --check` on the touched files.

## Work log

- 2026-09-06: created by /milestone-plan from the candidate row of 2026-09-06 ("A selection-rule argument on the orchestrators"); criteria audit ran in full mode on a fresh [O] reader and returned 13 findings, 12 fixed in the wording (four named loops; named fixtures; a two-term ordering with `desc()` in the grid probe; the snapshot-directory clause dropped as an instrument property; refusals split into constructor and entry with the bad `limit` values enumerated; BC15 as a `test_that()` block probing `pct_loss` with a non-default `limit`; the doc sweep scoped to roxygen and vignette prose with a "best candidate" term; NEWS moved to T5; AC7 in the profile's wording), the 13th (`limit` indistinguishable from its default) settled by `limit = NULL`; the reader's note that `select` must join `procedure_tuner()`'s shared names is T2.
- 2026-09-06: plan gate chose a `selection_rule()` constructor object over a function-valued `select` because a user's closure serializes its frame to the daemons (M12 lesson) and defeats the fixture cache (M68 lesson), and over strings plus ordering and limit formals because that is three formals on five functions; falsified by a caller needing a selector outside tune's three, which the constructor cannot express.
- 2026-09-06: plan gate chose the argument name `select` over `selection` and `rule` for reading beside tune's `select_best()` family; falsified by a documented collision with a tune or workflows argument of that name.
- 2026-09-06: plan gate left the rule out of `summary()` and the final fit's print, a candidate row, to keep one PR; falsified by a user misreading `.selected` for lack of the rule on the printed surface.

## Decisions

## Review
