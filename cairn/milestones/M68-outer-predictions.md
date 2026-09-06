# M68: `save_pred` and `extract` reach the outer fit, and `collect_predictions()` and `collect_extracts()` stack what each fold kept

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, IP4, GP1, GP3, GP4
- **Resolves:** —
- **Surface tier:** user-facing — two exported reader methods and two columns on the results object
- **Branch/PR:** `m068-outer-predictions`

## Goal

Keep what each outer fold's scoring fit already produces, the assessment-set predictions and an extract of the fitted workflow, when the control asks for it, and read them back stacked with the fold labels through tune's two generics.

## Scope

**In:** `nested_fold_fit()` (`R/nested-tune-grid.R:640-790`), the one per-fold path all five orchestrators run, keeps the `.predictions` element `tune::last_fit()` returns when the control passed through `...` carries `save_pred = TRUE`, and applies the control's `extract` function to the `.workflow` element it returns, keeping the value; a failed fold holds `NULL` in each. The constructor writes `.predictions` and `.extracts` only when the slot asked, tune's shape; `record_columns()` (`R/nested-results.R:133`) names both, so a present column is part of the record the dplyr and vctrs invariant reads (D-031, D-043). An `extract` that errors leaves the fold completed and records the error in its `.notes`. `collect_predictions()` and `collect_extracts()`, tune's generics, are re-exported with a `nested_results` method each on the D-052 stacker, refusing an object that lacks the column with a classed condition naming the slot. The inner run's `save_pred` and `extract` keep landing where they land today. Serial and parallel runs agree on both columns (IP2). Help text on the four orchestrator pages, a help topic for the two readers, pkgdown, NEWS, DESIGN, and a `results.Rmd` paragraph. A D-entry superseding the "Not returned" classification of the two slots.

**Out:** `save_workflow` and `save_history` stay "Not returned" (gate 2026-09-06; `extract = function(x) x` keeps a fold's fitted workflow). `summarize = TRUE` averaging across repeats → candidate row. The inner run's predictions and extracts → D-043's falsifier, unchanged. A plot over out-of-fold predictions → the autoplot candidate row. `collect_predictions()` on a `nested_final_fit` → tune's default refuses it, D-014's rule. The three other gaps the 2026-09-06 survey found (a selection-rule argument, an untuned baseline path, workflow sets) → candidate rows.

## Acceptance criteria

- [ ] AC1: For each of the five orchestrators, a run given a control with `save_pred = TRUE` through `...` returns a `nested_results` carrying a `.predictions` list column, and on the grid orchestrator each completed fold's element is `identical()` to `.predictions[[1]]` of `tune::last_fit()` called on that fold's outer split with the workflow finalized on the fold's `.selected` row, the run's metrics, `eval_time` and `event_level`, under `tune::control_last_fit(event_level, allow_par = FALSE)`, the fold's recorded `.outer_fit_seed` set after finalizing and before the call; a run given the default control, or one with `save_pred = FALSE`, returns an object with no `.predictions` column; a failed fold's element is `NULL`.
- [ ] AC2: For each of the five orchestrators, a run given a control with `extract = f` through `...`, where `f` returns the engine fit's coefficient vector through `coef(workflows::extract_fit_engine(x))`, returns an object carrying an `.extracts` list column, and on the grid orchestrator each completed fold's element is `identical()` to `f()` applied to the `.workflow[[1]]` of the `tune::last_fit()` call AC1 names; an `f` that errors on a fold leaves that fold `.completed`, its `.extracts` element `NULL`, and one row in its `.notes` with `location` `"outer extract"`, `type` `"error"` and the condition's message as `note`; a run given a control with `extract = NULL` returns an object with no `.extracts` column.
- [ ] AC3: `collect_predictions()` and `collect_extracts()`, tune's generics re-exported, each have a `nested_results` method returning the recorded fold label columns first (`id` and `id2` on a repeated design) and then the stacked rows of the completed folds, with one `nestedtune_partial_summary` warning on a partial run, a `nestedtune_no_completed_folds` error on a run with no completed fold (winning over every other refusal below), a `nestedtune_collect_name_collision` error when a stacked column is named like a label column, a `nestedtune_column_not_saved` error naming the control slot to set when the object lacks the column, and an `rlib_error_dots_nonempty` error on a non-empty `...`.
- [ ] AC4: The grid orchestrator run on the ranger workflow with a control carrying `save_pred = TRUE` and AC2's `f` gives `.predictions` and `.extracts` columns `identical()` between a serial run and a run on two or more mirai daemons whose dispatch the test asserts was parallel.
- [ ] AC5: `.predictions` and `.extracts`, when the template object carries them, are record columns: `dplyr::mutate()` replacing either, `dplyr::select()` dropping either, and `[` dropping either return a bare tibble, `vctrs::vec_restore()` on an object with either altered returns a bare tibble, and `dplyr::relocate()` moving either keeps the class.
- [ ] AC6: The four orchestrator help pages classify `save_pred` and `extract` under a heading saying they reach the outer fit, say that the kept predictions and extracts are the outer fit's while the inner run's are still discarded, and leave `save_workflow` (and `save_history` on the annealing page) under "Not returned"; a `collect_predictions` help topic documents both methods and `_pkgdown.yml` lists it; `NEWS.md` carries an entry; `DESIGN.md`'s Function Families paragraph names the two readers; `vignettes/results.Rmd`'s "The readers" section shows `collect_predictions()` on a run that saved them, and the page renders.
- [ ] AC7: `devtools::check()` reports 0 errors, 0 warnings, 0 notes; `devtools::test()` passes with no failures; `air format --check` reports no file to change over the touched files.

## Coverage

- AC1 → T1, T2
- AC2 → T2, T3
- AC3 → T4
- AC4 → T5
- AC5 → T6
- AC6 → T7
- AC7 → T8

## Tasks

- [x] T1: Tests first in `test-nested-tune-grid-results.R`: the `last_fit()` reference-implementation oracle for `.predictions` recorded in the file's provenance header, absence under the default control and under `save_pred = FALSE`, `NULL` on a failed fold. Then `nested_fold_fit()` keeps `fitted$.predictions[[1]]` when `control$save_pred` is `TRUE` (`R/nested-tune-grid.R:726-790`), `failed_fold()` returns `NULL` (`:1030`), `new_nested_results()` writes the column when asked (`R/nested-results.R:8-40`), `record_columns()` names it (`:133`).
- [ ] T2: Presence tests on the four sibling orchestrators for both columns, in their results test files (`test-nested-tune-bayes-results.R`, the race and annealing oracle files), on existing fixtures with the control extended.
- [x] T3: Tests first for `.extracts`: the oracle on `f(fitted$.workflow[[1]])`, the erroring `f` (fold completed, `NULL`, the `"outer extract"` note row through `own_note()`), absence under `extract = NULL`. Then the extract call inside `nested_fold_fit()` after the outer fit, in its own `tryCatch()`, and the column plumbing of T1 for `.extracts`.
- [ ] T4: Tests first in `test-collect-readers.R` on a repeated design: label columns, partial warning, all-failed refusal winning, name collision, the `nestedtune_column_not_saved` refusal for each reader, dots refusal. Then the two methods in `R/nested-results-collect.R` on `stack_fold_column()`, re-exports in `R/reexports.R`, the new methods in `test-dots-barrier.R`'s probe lists (M67).
- [ ] T5: The identity case in `test-parallel-identity.R` (two daemons, `expect_identical(last_dispatch(), "parallel")`), on the file's ranger workflow, with its bounded wait in `helper-time-budget.R`'s ledger.
- [ ] T6: Tests first in `test-nested-tune-grid-results.R` for the five invariant doors of AC5 on an object carrying both columns, and one control where a run without them keeps its class through the same verbs. Then the D-entry: `save_pred` and `extract` govern the outer fit as well as the inner run, the two columns join the record when present, superseding the "Not returned" clause D-042's help classification carries and annotating D-043's column set and D-030's falsifier.
- [ ] T7: Roxygen on the four orchestrator pages (`R/nested-tune-grid.R:475`, `R/nested-tune-bayes.R:159`, `R/nested-tune-race.R:154`, `R/nested-tune-sim-anneal.R:173`); the `collect_predictions` topic with an executed example; `_pkgdown.yml` row after `collect_selections`; NEWS entry; DESIGN Function Families line and the collect readers' comment at `R/nested-results-collect.R:26` (a completed fold can now carry an error note); `results.Rmd` paragraph, rendered after `devtools::install()` of the branch (M06 lesson) on a quiet machine (M66 lesson).
- [ ] T8: `devtools::check()`, `devtools::test()`, `air format --check` on the touched files (M56 lesson); hold docs-only commits local while CI runs (M50 lesson).

## Work log

- 2026-09-06: created by /milestone-plan from the user's survey question "are there any features missing"; scope chosen at the gate over three other gaps, which became candidate rows.
- 2026-09-06: criteria audit ran in full mode on a fresh [O] reader; six of seven criteria returned findings (AC2 and AC4 unsatisfiable for an environment-bearing extract, AC4 instrument-framed and vacuity-prone, AC6 miscounting the help pages and contradicting the pkgdown clause, AC5's "when present" ambiguous, AC1's oracle missing `allow_par` and the seed order, four instrument-bound clauses), each fixed as one clear answer before the gate; AC7 returned nothing.
- 2026-09-06: plan gate chose control-gated retention (`save_pred`, `extract`) over always-keeping predictions because tune's results behave that way and daemons ship the object back; falsified by users repeatedly re-running to recover predictions they did not ask for.
- 2026-09-06: plan gate chose a completed fold with a `NULL` extract and an error note over failing the fold on an extract error because a reporting failure must not discard a valid estimate (IP4); falsified by a user reading a `NULL` extract as a legitimate value without consulting the notes.
- 2026-09-06: plan gate chose leaving `save_workflow` not returned over a `.workflow` column because `extract = function(x) x` already keeps the fitted workflow and a per-fold ensemble copy is a size risk (GP4); falsified by a user needing the fitted workflows without knowing the extract idiom.
- 2026-09-06: plan gate chose a candidate row for `summarize = TRUE` over implementing it because averaging class probabilities needs its own oracle; falsified by a user on a repeated design asking for it.
- 2026-09-06: plan chose applying `extract` to the returned `.workflow` after the fit over routing it through `control_last_fit()` because tune's `last_fit()` moves its own identity extract into `.workflow` and a caller's function there would replace the workflow (audit finding); falsified by an extract whose value depends on running inside tune's fit loop.
- 2026-09-06: implement gate chose one row per completed fold with an `.extracts` list column for `collect_extracts()`, tune's own shape, over stacking a data-frame return or adding `.config`; and the help-page heading "Kept from the outer fit" over "Reaches the outer fit" and "Returned". Branch `m068-outer-predictions` cut from the pushed default branch.
- 2026-09-06: T1 checkpoint: the `.predictions` oracle tests, absence tests and failed-fold test land with the fold-fit, failed-fold, constructor and `record_columns()` plumbing; the file's tests pass and fail without the code change; the full suite is running and T1 is ticked once it is clean.
- 2026-09-06: T1 done; `devtools::test()` clean on the full suite after the checkpoint.
- 2026-09-06: T3 done: `.extracts` oracle, erroring-extract, absence and failed-fold tests; the extract call after the outer fit in its own `tryCatch()`, the `"outer extract"` note, and the column plumbing; `coef_extract()` in the helper is built over `baseenv()` because the fixture key hashes a closure with its environment and the helper's holds the cache (two builds of one run observed); the absence runs are unmemoised because they equal the default run in value; tune files the inner run's extract errors as notes the fold keeps, nine on the fixture, beside this package's one. Suite clean.

## Decisions

## Review
