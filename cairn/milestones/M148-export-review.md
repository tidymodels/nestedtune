# M148: Each export and result column is set beside its tidymodels counterpart, with a verdict for each difference

- **Status:** review
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

- [x] AC1: For each function named by an `export()` line of `NAMESPACE` whose definition is in this package's `R/` (not a re-export), and each method named by an `S3method()` line whose generic this package exports, `cairn/references/export-surface-review.md` names the tune, finetune, workflowsets or hardhat function or method it mirrors, or none. For each argument that one of the pair has and the other lacks, and for each pair of shared arguments whose order differs, the page gives a verdict of kept, changed or proposed. `benchmarks/export-surface.R` lists the functions and methods by reading `NAMESPACE`.
- [x] AC2: The workflow methods of the six `nested_*` generics and `nested_workflow_map()` each run on the script's fixture with `save_pred = TRUE` and an `extract` function in the control. Each counterpart runs with the same control on the inner resamples of outer fold 1. For each column name that one result has and the other lacks, the page gives a verdict of kept or proposed.
- [x] AC3: For each argument with a changed verdict, a testthat test asserts that its order among the arguments it shares with the counterpart matches the counterpart's order, and `devtools::test()` passes.

## Coverage

- AC1 → T1, T3, T7
- AC2 → T2, T3
- AC3 → T4, T6

## Tasks

- [x] T1: Write the first half of `benchmarks/export-surface.R`: read `export()` and `S3method()` lines from `NAMESPACE`, keep the domain AC1 names, pair each item with its counterpart through a table in the script, and print each pair's missing arguments and order differences among shared arguments.
- [x] T2: Write the column half: the six workflow methods and `nested_workflow_map()` on a small fixture with `save_pred = TRUE` and an `extract` function, each counterpart on the inner resamples of outer fold 1 with the same control, and the column-name differences printed.
- [x] T3: Write the page. Read `DECISIONS.md` by its headings for each difference (D-030, D-038, D-040, D-042, D-046, D-056 and D-069 cover several), and give each difference its verdict. Add the `INDEX.md` line.
- [x] T4: Apply each changed verdict in `R/`, run `devtools::document()`, add the order tests AC3 names, and write one NEWS entry naming the functions whose argument order changed. With no changed verdict, this task writes nothing.
- [x] T5: Add the proposed verdicts as candidate rows, searching the existing rows first. Group the verdicts by function so the rows stay within the ROADMAP's byte budget.
- [x] T6: Run `devtools::test()`, `air format --check .` and the prose sweeps.
- [x] T7: Add a pairing table to the page, one row per item the script reads, naming its counterpart or none (review return 1).

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
- 2026-10-18: T3 done: `cairn/references/export-surface-review.md` and its INDEX line. Verdicts: 2 changed (shared-argument order on the `nested_tune_bayes()` and `nested_tune_sim_anneal()` methods, which T4 applies; the page states the new order), 3 proposed (`verbose` on `nested_workflow_map()`, `type` on `collect_inner_metrics()`, `id` on the set's `autoplot()`), every other argument and column kept with a D-entry or a stated reason. Claims read against `R/` and the installed packages; that read corrected two drafted reasons (16 re-exports, not 17; `event_level`'s reason, since a control's level does reach the outer fit). The page keeps the template's `— observed` and `Pagination: —` dashes, which the references check parses. `cairn_validate` passes.
- 2026-10-18: T4 done: the `workflow` and `model_spec` methods of `nested_tune_bayes()` now read `metrics, event_level, eval_time, objective, initial`, and of `nested_tune_sim_anneal()` `metrics, event_level, eval_time, initial`; `event_level` keeps its place after `metrics`, as on the grid methods. New `test-argument-order.R` failed 8 of 8 on the old order and passes; the written-out signatures in `test-dots-barrier.R` and `test-nested-tune-sim-anneal-oracles.R` follow the new order. One NEWS entry. `devtools::document()` rewrote the two Rd files; `devtools::test()` 15533 pass, 0 fail; `air` and both prose sweeps clean. The four formals were moved by a short python replace, not the Edit tool (deviation from the file-edit rule, diff reviewed).
- 2026-10-18: T5 done: the three proposed verdicts are one `[low]` candidate row, "Three tidymodels arguments missing here", at the top of the `[low]` rows. Search-first found no overlap in the candidates, `milestones/archive/` or `DECISIONS.md` (D-030's `verbose` line is about printing inside a daemon). ROADMAP is 23,884 bytes and 59 lines.
- 2026-10-18: T6 done: `devtools::test()` 15533 pass, 0 fail, 0 skip on 890190d2; `air format --check .` clean; all six gating prose sweeps clean; `devtools::document()` no diff.
- 2026-10-18: claim audit: 27 claims read, 1 corrected — benchmarks/export-surface.R, NEWS.md, tests/testthat/test-argument-order.R. The script header said "Nothing here is asserted" and that a release change "is caught by running this again"; it now says the script stops on a missing package or a table that disagrees with `NAMESPACE`, and that a person reads the output against the page. Re-read by the same reader: 4 claims, 0 wrong.
- 2026-10-18: status → review.
- 2026-10-18: review return 1: AC1 fails as written. It asks the page to name each item's counterpart or none, and 56 of the script's 75 items (for example `extract_mold.nested_final_fit`, `nested_tune_grid.workflow`, `collect_notes.nested_results_set`) are named on the page only through a grouping rule, not one by one. Argument verdicts are complete (20 one-side arguments, each in a verdict row). Fix: a pairing table on the page with one row per item and its counterpart or none.
- 2026-10-18: minor amendment: T7 added for review return 1, Coverage AC1 → T1, T3, T7.
- 2026-10-18: T7 done: the page's "Every item and its counterpart" table, 75 rows built from the script's Part 1 output at 890190d2. A check of one row per item with the printed counterpart found 0 wrong or missing (56 missing before). No code changed, and the branch adds no lines outside `cairn/` since the claim audit. `cairn_validate` passes. Status → review.
- 2026-10-18: review pass 2 settled 15 findings: 9 fix now, 1 follow-up, 5 rejected. D-117 written (narrows D-069). The candidate row is retitled "Argument gaps beside tidymodels" and holds the uncompared defaults. ROADMAP 23,931 bytes.
- 2026-10-18: step-7 approval: m148-export-review approved for merge

## Decisions

## Review

Pass 1 (2026-10-18) returned AC1: 56 of 75 items were named only through a grouping rule (review return 1, fixed by T7). Pass 2 evidence follows, at e94674f7.

- AC1: `Rscript benchmarks/export-surface.R` exit 0. It reads 16 package-owned functions and 59 methods from `NAMESPACE`, and stops on a table that disagrees with it (claim audit, a deleted row). A check over its Part 1 output found each of the 75 items in its own page row with the printed counterpart or none (0 wrong), each of the 20 arguments one side lacks in a kept/changed/proposed row (0 missing), and the one shared-order difference left (`autoplot.nested_results_set()`, before `...`) in a kept row. The two pre-change order differences (`nested_tune_bayes()`, `nested_tune_sim_anneal()` methods) have changed rows.
- AC2: the same run's Part 2 completes all seven runs (the six workflow methods and `nested_workflow_map()`) with `save_pred = TRUE` and an `extract` function, each counterpart on `folds$inner_resamples[[1]]` under the same control object. The 10 column names one side lacks (`.selected`, `.inner_metrics`, `.completed`, `.tuning_seed`, `.outer_fit_seed`, `.iter`, `.order`, `workflow`, `info`, `option`) each have a kept or proposed row (0 missing).
- AC3: the changed verdicts cover `eval_time`, `objective` and `initial` on `nested_tune_bayes()` and `eval_time` and `initial` on `nested_tune_sim_anneal()`. `test-argument-order.R` asserts, for the `workflow` and `model_spec` methods of each, that the shared arguments are in the counterpart's order, and states the moved arguments' order as literal text. It failed 8 of 8 before the reorder (T4) and passes 8 of 8 at ea06582b. `devtools::test()` at ea06582b: 15533 pass, 0 fail, 0 skip.

Consistency gate at ea06582b: `cairn_validate` all checks pass (18 advisory warnings, references staleness on older source notes); no principle changed, so `cairn_impact` is skipped. `devtools::document()` no diff. README.Rmd untouched. `pkgdown::check_pkgdown()` no problems. NEWS.md has the entry for the reorder. No new top-level file (`benchmarks/` is already in `.Rbuildignore`). `devtools::check()` 0 errors, 0 warnings, 0 notes. All six gating prose sweeps clean. `air format --check .` clean.

spawned: diff-bug, blame-history, prior-review

- diff-bug #1: `test-argument-order.R` compares with installed tune and finetune formals with no CRAN skip, so an upstream reorder would fail the CRAN check — fix now: `skip_on_cran()` in both tests (8 pass with `NOT_CRAN` true, 2 skips with it false).
- diff-bug #2: the page's `std_errs` reason (no ranking view) is wrong; workflowsets uses it for interval bars — fix now: own row, reason is that the set's plot draws no interval bars.
- diff-bug #3: the changed rows say no decision chose the old order but omit D-069, whose `workflow` method keeps each function's formals — fix now: D-117 narrows D-069, and both changed rows cite it.
- diff-bug #4: provenance and evidence snapshot name `93c10377`, but the table and verdicts read output at `890190d2` — fix now.
- diff-bug #5: `extract_procedure()` is cited to D-023, D-039, D-052, none of which names it — fix now: each owned generic gets its own entry, `extract_procedure()` cites D-023's shape and `DESIGN.md` (M67).
- diff-bug #6: the `.iter` row cites D-043 for annealing, which D-043 does not cover — fix now: D-043 for Bayes, `R/tuner.R`'s iterating flag for both.
- diff-bug #7: `augment()`'s `parameters` row cites D-090, which covers `collect_predictions()` — fix now: cites D-092 and `?augment.nested_results`.
- diff-bug #8: the script compares names and order, not defaults, and misses `autoplot()`'s `type` default (`"parameters"` here, `"marginals"` in tune) — follow-up: the M148 candidate row, retitled "Argument gaps beside tidymodels", now holds it, and the page says defaults were not compared.
- diff-bug #9: the `model_spec` methods forward `initial`/`objective` in the old order, and the `SETTABLE_TAIL` prose lists `iter`, `initial`, `objective`, `eval_time` — reject, style: both pass or list by name, and neither claims an order.
- diff-bug #10: the script needs the repo root as working directory and does not check it — reject, style: its header gives the command from the root, as the other benchmark scripts do.
- blame-history #1: the `workflow` method reorder contradicts D-069 — fix now: D-117 (same fix as diff-bug #3).
- blame-history #2: the page's "no decision chose the old order" omits D-069, and the tests pin the new order — fix now: the D-117 citation (same fix); the tests pin the order D-117 chose.
- blame-history #3: the branch order matches tune, and D-069's `model_spec` claim was not met before — reject, false as a defect: it reports the change is correct.
- blame-history #4: no comment or commit recorded a reason for the old order — reject, false as a defect: it supports the change.
- blame-history #5: positional use cannot break, every moved formal is after `...` — reject, false as a defect: it confirms NEWS.
- prior-review: no candidate finding; archived reviews on the touched files (M028, M045, M051, M057, M061) are not reintroduced, and the PR threads hold no human comments on these paths.
