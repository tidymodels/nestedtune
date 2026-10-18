# M148: Each export and result column is set beside its tidymodels counterpart, with a verdict for each difference

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1
- **Resolves:** —
- **Surface tier:** user-facing — the exported functions, their arguments and the result columns are what user code calls and reads
- **Branch/PR:** m148-export-review

## Goal

Before the first release, every package-owned export, every method of an exported generic, and every result column is compared with its tidymodels counterpart, and each difference is kept for a stated reason, changed where the change breaks no call, or proposed for a later decision.

## Scope

**In:** `benchmarks/export-surface.R`, which reads `NAMESPACE`, pairs each function or method with its counterpart, prints the argument differences, and runs the column fixture. A synthesis note, `cairn/references/export-surface-review.md`, with its `INDEX.md` line, holds one verdict per difference. A kept verdict cites the D-entry or `DESIGN.md` line that chose the difference, or states the reason. A changed verdict is limited to argument order after `...`, which breaks no call, and it ships here with a test and a NEWS entry. A proposed verdict is any other change: a rename, a removed or added argument, an argument moved before `...`, or a result column added, renamed or removed.

**Out:** each proposed verdict becomes a candidate row for a later plan, as the question set chose. Methods of generics this package does not export (print, summary, predict, format, `[`, `names<-`, rbind, and the vctrs and dplyr methods) are not reviewed, because the generic sets their arguments. The structure of a `nested_final_fit` object is not compared with `last_fit()`'s, since it is not a resampling table. Its functions are in AC1.

## Acceptance criteria

- [ ] AC1: For each function named by an `export()` line of `NAMESPACE` whose definition is in this package's `R/` (not a re-export), and each method named by an `S3method()` line whose generic this package exports, `cairn/references/export-surface-review.md` names the tune, finetune, workflowsets or hardhat function or method it mirrors, or none. For each argument that one of the pair has and the other lacks, and for each pair of shared arguments whose order differs, the page gives a verdict of kept, changed or proposed. `benchmarks/export-surface.R` lists the functions and methods by reading `NAMESPACE`.
- [ ] AC2: The workflow methods of the six `nested_*` generics and `nested_workflow_map()` each run on the script's fixture with `save_pred = TRUE` and an `extract` function in the control. Each counterpart runs with the same control on the inner resamples of outer fold 1. For each column name that one result has and the other lacks, the page gives a verdict of kept or proposed.
- [ ] AC3: For each argument with a changed verdict, a testthat test asserts that its order among the arguments it shares with the counterpart matches the counterpart's order, and `devtools::test()` passes.

## Coverage

- AC1 → T1, T3
- AC2 → T2, T3
- AC3 → T4, T6

## Tasks

- [x] T1: Write the first half of `benchmarks/export-surface.R`: read `export()` and `S3method()` lines from `NAMESPACE`, keep the domain AC1 names, pair each item with its counterpart through a table in the script, and print each pair's missing arguments and order differences among shared arguments.
- [x] T2: Write the column half: the six workflow methods and `nested_workflow_map()` on a small fixture with `save_pred = TRUE` and an `extract` function, each counterpart on the inner resamples of outer fold 1 with the same control, and the column-name differences printed.
- [ ] T3: Write the page. Read `DECISIONS.md` by its headings for each difference (D-030, D-038, D-040, D-042, D-046, D-056 and D-069 cover several), and give each difference its verdict. Add the `INDEX.md` line.
- [ ] T4: Apply each changed verdict in `R/`, run `devtools::document()`, add the order tests AC3 names, and write one NEWS entry naming the functions whose argument order changed. With no changed verdict, this task writes nothing.
- [ ] T5: Add the proposed verdicts as candidate rows, searching the existing rows first. Group the verdicts by function so the rows stay within the ROADMAP's byte budget.
- [ ] T6: Run `devtools::test()`, `air format --check .` and the prose sweeps.

## Work log

- 2026-10-17: created by /milestone-plan.
- 2026-10-17: tier check: milestone — the request (items 1, 4 and 5 of the release-readiness list) includes CI jobs and an export review, and asked for a plan.
- 2026-10-17: question set: what happens to a difference with no recorded reason — safe changes only. Argument order after `...` is changed, and each other change goes to a candidate row for a later plan.
- 2026-10-17: question set: how wide the review is — functions, methods and result columns.
- 2026-10-17: criteria audit (full mode) returned seven findings. AC1's domain was what the script listed, so it is now defined by `NAMESPACE`'s lines. Methods of re-exported generics such as `collect_predictions.nested_results()` (which lacks tune's `parameters`) were outside it and are now in. "Position" was undefined and is now the order of shared arguments. There are six `nested_*` generics, and `nested_workflow_map()` is a plain function. AC2 named no fixture control, orchestrator list or counterpart resamples, and now names all three. AC3 checked only arguments and could pass by script output alone. It now needs a test per changed argument, and column changes are proposed only. No D-entry blocks a criterion.
- 2026-10-17: plan gate chose safe changes only over applying every change, at the user's choice, because a rename breaks scripts written against the development version; falsified by a proposed rename the user would have taken here.
- 2026-10-17: inbox sweep: 1 open issue (#91), no overlap with this milestone.
- 2026-10-18: implement started; branch `m148-export-review` cut from main at 41929c7a.
- 2026-10-18: choice: the script loads the source tree with `pkgload::load_all()` rather than an installed copy, so T4's reorder shows in its output; it stops when the pairing table and `NAMESPACE` name different items, so a new export cannot pass unpaired.
- 2026-10-18: choice: pairings. `nested_final_fit()` pairs with `tune::fit_best.tune_results()` (both refit a chosen candidate on all the training data, D-041 names both as the non-nested routes). A `nested_results` method pairs with tune's `tune_results` method, a `nested_results_set` method with workflowsets' `workflow_set` method, a `nested_final_fit` extractor with tune's `tune_results` method or hardhat's generic where tune has none. `augment.nested_final_fit()`, `compute_metrics.nested_results_set()`, `augment.nested_results_set()`, `nested_resamples()` and the package-owned generics pair with none of the four packages.
- 2026-10-18: T1 done: 16 functions and 59 methods read from `NAMESPACE`, 22 pairs differ (tune 2.1.0, finetune 1.3.0, workflowsets 1.1.1, hardhat 1.4.3); `air format --check .` clean.
- 2026-10-18: choice: the column fixture is mtcars with a tuned `step_pca()` ahead of `linear_reg()` (deterministic, 15 s for the whole script), 3 outer and 4 inner folds so the races have a burn-in, `num_comp` in 1 to 8 so the Bayesian search has candidates left; `nested_fit_resamples()` takes an untuned two-predictor workflow; the set comparison also reads `result[[1]]`.
- 2026-10-18: T2 done: all seven runs complete; each nested result adds `.selected`, `.inner_metrics`, `.completed`, `.tuning_seed`, `.outer_fit_seed`, and lacks `.iter` (Bayes, annealing) or `.order` (races); the set adds `workflow` and lacks `info`, `option`.

## Decisions

## Review
