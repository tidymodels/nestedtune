# M70: `nested_fit_resamples()` scores a workflow with nothing to tune on the outer folds of a nested design, and the five tuning orchestrators refuse one

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, IP4, GP1, GP2, GP3
- **Resolves:** —
- **Surface tier:** user-facing — a new exported orchestrator and a new entry refusal on the five existing ones
- **Branch/PR:** `m070-fit-resamples`

## Goal

Give a fixed workflow one obvious path through the same nested design a tuned one ran on, so the two score on identical outer folds and the record says no tuning ran.

## Scope

**In:** a sixth orchestrator, `nested_fit_resamples(object, resamples, ..., metrics = NULL, event_level = "first", eval_time = NULL)` shaped like `tune::fit_resamples()`, sharing `nested_loop()` and `dispatch_folds()` with the five, whose fold skips the inner stage and runs `tune::last_fit()` on the outer split; a `fit_resamples` entry in `tuner_registry` (`R/tuner.R`) with a flag saying the tuner selects nothing; the `procedure` record without `grid`, `param_info` or `select`; `nested_final_fit()` accepting the result and fitting the workflow on every row; refusals at entry both ways (a marked workflow on the new export, an unmarked one on the five); the readers and plots on the result; help, pkgdown, NEWS, DESIGN and a `nested-cv.Rmd` section comparing the two runs by fold label. Lineage: the "untuned baseline path" candidate row added 2026-09-06 at M68's plan gate; its premise that entry refuses an unmarked workflow was false (an unmarked workflow ran through the grid orchestrator with tune's warning on every fold, probed 2026-09-06).

**Out:** a plain `rset` (outer folds only) as `resamples` — `tune::fit_resamples()` already serves it, and identical folds with a tuned run is the point; `rbind()` of a tuned and a baseline result carrying both procedures — M37's row in the ROADMAP candidate that holds the M37 review remainders (the template's procedure is stamped); a `workflow_set` through one design — its own candidate row (depends on this milestone); an inner-loop estimate for the fixed workflow (`fit_resamples()` on each inner `rset`) — nothing reads it, not planned; naming the procedure in `summary()` — the M69 candidate row.

## Acceptance criteria

- [ ] AC1: `nested_fit_resamples()` is exported, and on the deterministic fixture (the D-013 `step_pca()` + `linear_reg()` workflow with `num_comp` fixed, no `tune()` marker) over a 3-fold `nested_resamples()` design, every fold's `.metrics` `.estimate` values are `identical()` to `tune::fit_resamples()`'s `collect_metrics(summarize = FALSE)` rows on the same outer `rsample::vfold_cv()` splits, and to a by-hand `fit()` on the analysis set, `predict()` on the assessment set and `yardstick` metric computation for that fold.
- [ ] AC2: The result is a `nested_results` whose columns are those `record_columns()` names for the five tuning orchestrators, with `.selected` a zero-row, zero-column tibble on every completed fold, `.inner_metrics` a zero-row table with the columns `.metric`, `.estimator`, `mean`, `n`, `std_err` and `.config`, `.tuning_seed` and `.outer_fit_seed` the two seeds `nested_loop()` draws for the fold (so a tuned run under the same session seed shares each fold's outer-fit seed), and `.predictions` and `.extracts` present exactly when `save_pred = TRUE` or `extract` reached `...`; a fold whose fit raises is recorded as failed with a note at location `"outer fit"` (IP4).
- [ ] AC3: On that result each of `collect_metrics()`, `summary()`, `print()`, `collect_notes()`, `collect_selections()`, `collect_inner_metrics()`, `collect_predictions()`, `collect_extracts()`, `agreement()` (zero rows) and `autoplot(type = "performance")` returns without a condition, and `autoplot(type = "parameters")` refuses with condition class `nestedtune_no_tuned_parameters`.
- [ ] AC4: `extract_procedure()` on the result holds `tuner = "fit_resamples"`, the effective `tune::control_resamples()`, `event_level` and `eval_time`, and no `grid`, `param_info` or `select` entry, and `check_results_record()` accepts that record; `nested_final_fit(object, results)` fits the workflow on every row with no tuning run, its `predict()` on the deterministic fixture is `identical()` to `predict()` from `workflows::fit(object, data)`, its print names the procedure as no tuning and the selection as nothing to select, and `extract_tune_results()` and `extract_scored_candidates()` on it refuse with condition class `nestedtune_no_tuning_run`.
- [ ] AC5: A workflow carrying a `tune()` marker is refused at `nested_fit_resamples()`'s entry with condition class `nestedtune_tuned_workflow`, naming the tuning orchestrators, before any fold runs; and each of the five tuners in `tuner_registry` refuses at its orchestrator's entry a workflow with no `tune()` marker with condition class `nestedtune_untuned_workflow`, naming `nested_fit_resamples()`, before any fold runs.
- [ ] AC6: The same seed gives `identical()` results across two direct serial calls on a ranger workflow with fixed parameters, and the run on two mirai daemons is `identical()` to the serial run on that workflow (IP2).
- [ ] AC7: The help page for `nested_fit_resamples()` carries an executed example, the per-fold reproduction recipe stating that the tuning seed is drawn and consumed by nothing, and a "Differences from calling tune directly" section classifying every slot `tune::control_resamples()` returns; the five orchestrator pages state the new refusal; a pkgdown row under "Running the loop"; a NEWS entry; the DESIGN.md Function Families line; and a section in `vignettes/nested-cv.Rmd` scoring a fixed workflow on the same design and joining the two runs' per-fold metrics by fold label.

## Coverage

- AC1 → T1, T2, T3, T4
- AC2 → T2, T4
- AC3 → T2, T5
- AC4 → T2, T6
- AC5 → T3, T7
- AC6 → T1, T8
- AC7 → T9, T10

## Tasks

- [x] T1: Fixtures in `tests/testthat/helper-orchestration.R`: `fixed_workflow(data)` (the deterministic workflow finalized at `num_comp = 2L`) and `fixed_stoch_workflow(data)` (ranger, `min_n` and `trees` fixed, `num.threads = 1`); grep every holder of each new name first (the M41 lesson).
- [x] T2: The `fit_resamples` registry entry in `R/tuner.R` (`package`/`requires` tune, `control = tune::control_resamples()`, `control_class = "control_resamples"`, `takes_grid = FALSE`, `iterates = FALSE`, a new `selects = FALSE` flag, `label = "no tuning"`), `tuner_fit_resamples()`, and the fold path in `nested_fold_fit()` (`R/nested-tune-grid.R`) that skips `analysis_framed_inner()`, `run_tuner()` and `apply_selection_rule()` for it, records the AC2 shapes, and runs `last_fit()` under the outer-fit seed; `new_procedure()` omits `select` and `param_info` for it and `check_results_record()` (`R/checks.R`) requires the rule only where the registry says the tuner selects.
- [x] T3: `nested_fit_resamples()` in `R/nested-fit-resamples.R` with its entry checks (`check_workflow()`, `check_nested()`, `check_metrics()`, `check_event_level()`, `check_eval_time()`, `check_control()` against `control_resamples`) and `check_tuned_workflow()`; `check_untuned_workflow()` reading `tune::extract_parameter_set_dials(object)$id` on the five orchestrators' entry (skipped, never a false refusal, when extraction fails); NAMESPACE.
- [x] T4: `test-nested-fit-resamples-oracles.R`: AC1's two oracles (the `fit_resamples()` reference in the shape of `test-nested-tune-grid-oracles.R`'s single-candidate test, and the by-hand fit) and AC2's record shapes, including a failing fold and the `save_pred`/`extract` columns.
- [x] T5: `test-nested-fit-resamples-readers.R` over AC3's list; the `nestedtune_no_tuned_parameters` class on `plot_selection()`'s abort (`R/nested-results-plot.R`); the dots probe entries where a new reader shape appears.
- [x] T6: `nested_final_fit()` on the record: `final_fit_worker()` fits without a tuning run, `procedure_label()` and `selected_label()` (`R/nested-final-fit-print.R`) print "no tuning" and "nothing to select", the two extractors in `R/nested-final-fit-extract.R` refuse with `nestedtune_no_tuning_run`; tests in `test-nested-final-fit*.R`.
- [x] T7: AC5's refusal tests in `test-nested-fit-resamples-checks.R` and the five `*-checks.R` files, asserting the class and that no fold ran.
- [x] T8: AC6's reproducibility test (two direct calls, never through `memoised()`, the M42 lesson) and BC16 in `test-parallel-identity.R` with its comment block, a `helper-time-budget.R` ledger row for any bounded wait; a third RNG kind where a pin is asserted (the M07 lesson).
- [x] T9: Roxygen for the new page (headings as the grid page, every `control_resamples()` slot classified, the reproduction recipe, executed example), the refusal paragraph on the five pages, `_pkgdown.yml`, `NEWS.md`, `cairn/DESIGN.md` Function Families and the orchestration line.
- [x] T10: The `nested-cv.Rmd` section; `devtools::install()` the branch before rendering (the M06 lesson) and measure the render on a quiet machine (the M66 lesson); `air format --check` on touched files before the review push (the M56 lesson).

## Work log

- 2026-09-06: created by /milestone-plan. Criteria audit ran in full mode ([O] reader): twelve findings; nine fixed in the wording (the final fit refused a record without a selection rule, two unnamed condition classes, the `.selected` shape, the seed draw, the inner-metrics shape, a fixture that did not exist, instrument-bound clauses, the control-slot promise), two posed at the gate (the refusal on the five, the final fit on a baseline), one noted without change (the value oracle is deterministic-engine only; ranger is pinned by seed identity).
- 2026-09-06: plan gate chose a sixth orchestrator over accepting an unmarked workflow on the five because the inner loop would run for nothing, tune would warn once per fold, and the record would call it a grid search; falsified by a user needing the inner-loop estimate of a fixed workflow.
- 2026-09-06: plan gate chose refusing an unmarked workflow on all five over refusing only where the tuner cannot run because one path for a fixed model is GP3's stance and D-003 waives the cycle; falsified by a user needing tune's warn-and-run path through a nested design.
- 2026-09-06: plan gate chose the final fit accepting a baseline result over refusing it because one story (run, then final fit) holds for every result; falsified by a reader mistaking the plain fit for a tuned one.
- 2026-09-06: plan chose a zero-row, zero-column `.selected` over a one-row empty tuple because D-039 rejected the empty-tuple row for claiming a candidate where none was chosen; falsified by a reader needing one row per completed fold from `collect_selections()`.
- 2026-09-06: plan chose recording the drawn tuning seed over `NA` because the seed layout then matches a tuned run's and the reproduction recipes stay one shape; falsified by a reader misreading the seed as consumed.
- 2026-09-06: /milestone-implement started; branch `m070-fit-resamples` cut from the pushed default branch at `9601cc5`.
- 2026-09-06: T1 done: `fixed_workflow()` and `fixed_stoch_workflow()` added to `helper-orchestration.R`; grep over `R/`, `tests/`, `vignettes/`, `man/` found no holder of either name or of the M70 export and check names.
- 2026-09-06: checkpoint, half-done: T2 to T9 code, tests and docs written (registry entry, fold path, export and checks, oracle/readers/checks/final-fit/rng test files, BC16, help pages, pkgdown, NEWS, DESIGN); the targeted test files pass; the full-suite verify for T2 to T8 is running and the boxes are ticked on its green, T10 (vignette) not started.
- 2026-09-06: T2 done: `fit_resamples` registry entry with `selects = FALSE` (the five carry `selects = TRUE`), `tuner_fit_resamples()`, `tuner_selects()` total toward selecting for an unknown name, the fold path in `nested_fold_fit()` skipping the framed inner rset, the tuner call and the rule and fitting the workflow as given, `new_procedure()` omitting `select` and `param_info`, `check_results_record()` asking for a rule only where the tuner selects.
- 2026-09-06: T3 done: `R/nested-fit-resamples.R` with its roxygen page written here rather than at T9, `check_tuned_workflow()` and `check_untuned_workflow()` over `tuned_parameter_ids()` in `R/checks.R`, the untuned refusal placed after `check_workflow()` on the five; NAMESPACE by `document()`. Probe: `control_resamples()` and `control_grid()` share one class vector in tune 2.1.0, so the class check accepts either.
- 2026-09-06: T4 done: `test-nested-fit-resamples-oracles.R` (O1 `fit_resamples()` live, O2 by-hand fit/predict/score; AC2 shapes, seeds by the written contract and shared with a grid run, optional columns, a failing fold); `fit_resamples_results()` fixture seeded before the workflow so the recipe step id keys one build.
- 2026-09-06: T5 done: `test-nested-fit-resamples-readers.R` over AC3's list; `plot_selection()`'s abort classed `nestedtune_no_tuned_parameters`; no new reader method, so the dots probe lists are unchanged.
- 2026-09-06: T6 done: the final fit on a `fit_resamples` record fits under the second seed with no inner rset and `tuning = NULL`, refuses a marked workflow with `nestedtune_tuned_workflow`, prints "Procedure: no tuning" with a bullet saying the two accessors refuse (the standing bullet named them as reachable), `summary()` print drops the count line, `check_tuning_run()` refuses both extractors with `nestedtune_no_tuning_run`; `test-nested-final-fit-resamples.R`.
- 2026-09-06: T7 done: `test-nested-fit-resamples-checks.R` and one untuned-refusal test in each of the four `*-checks.R` files; the shared-check tables in the bayes, race and annealing files gained the new check, the finalize and recipe loops skip a tuner that selects nothing, the registry name list gained the entry.
- 2026-09-06: T8 done: `test-nested-fit-resamples-rng.R` (two direct calls, Wichmann-Hill pin on the fold, state restored) and BC16 in `test-parallel-identity.R` with its ledger row at line 928.
- 2026-09-06: verify for T2 to T8 ran once over the finished state (full `devtools::test()` green, 0 failures) rather than per task; the intermediate task states were checked by their own test files only.
- 2026-09-06: T9 done: the refusal on the five pages through the grid page's inherited `object` parameter, the final-fit page (object, results, return, recipe prose), `extract_procedure()`'s return, a pkgdown row, the NEWS entry, DESIGN's Function Families and Architecture lines, and a control-slot classification test for the new page; `air format --check` clean.
- 2026-09-06: T10 done: "A baseline on the same folds" section in `vignettes/nested-cv.Rmd` before "The model you deploy": a fixed ranger workflow through `nested_fit_resamples()` on the same design, the two runs' per-fold rmse joined by `id`, and the refusal shown; rendered from the installed branch in 9.1 s elapsed at load average 4.2 to 3.9; `pkgdown::check_pkgdown()` and `cairn_validate` clean.
- 2026-09-06: all tasks checked; `devtools::test()` green over the finished code, `document()` no diff, `air format --check` clean; status set to review.

## Decisions

- 2026-09-06: `nested_final_fit()` on a `fit_resamples` record refuses a workflow carrying a `tune()` marker at entry with class `nestedtune_tuned_workflow`, as a grid record refuses a workflow that does not match its recorded grid; letting it reach `fit()` would fail there with tune's message. Falsified by a user needing the final fit to finalize a marked workflow from a record that selected nothing.
- 2026-09-06: the final fit's print names a `fit_resamples` procedure by the registry label alone ("Procedure: no tuning"), with no candidate count, because a count of zero reads as a search that found nothing; the selection line reads "nothing to select". Falsified by a reader needing the count line on every final fit.
- 2026-09-06: `nested_final_fit()` on a `fit_resamples` record draws both seeds, the tuning seed consumed by nothing (the fold's shape), and does not evaluate the design's inner specification, which nothing on this path reads; `check_results_record()` still requires the specification as the mark of an orchestrator-built object. Falsified by a reader of the final fit's seeds needing the inner resamples rebuilt.

## Review
