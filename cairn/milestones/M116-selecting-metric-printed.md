<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M116: The summaries and the final fit's print name the metric that selects

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** IP4, GP3   <!-- owner: plan · create/amend-via-gate; comma-separated IPn/GPn ids this milestone touches, or — -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate; comma-separated GitHub issues the scope absorbs, each `#N closes` (the PR closes it at merge) or `#N partial` (the remainder gets a candidate row), or — ; skill conduct only — no validate check parses it -->
- **Surface tier:** user-facing — it changes the printed summaries, the procedure record and a help page   <!-- owner: plan · create/amend-via-gate; user-facing | internal — <one-clause reason>; skill conduct only — no validate check parses it -->
- **Branch/PR:** m116-selecting-metric   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

The summaries and the final fit's print name the metric that chose each fold's candidate, and the help of `nested_workflow_map()` says which metric selects.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** A `first_metric` entry in the procedure record, resolved once at entry. A `Selecting metric:` line on the four summary and print surfaces that already carry `Selected by:`. A `first_metric` component on the two summary objects. The help text of `nested_workflow_map()`'s `...` entry. The two M115 candidate rows are absorbed here.

**Out:** The line on `print.nested_results`, which M098 kept free of the rule and which stays so (no row, a standing choice). The rule object's own print, which cannot know the metric. A `metric` argument on `selection_rule()`, which M115's plan rejected. A migration of results built before the entry, which D-041 declines: the summary prints no line for them.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets.
     Every item opens with its positional label — `ACn:` — the item's
     position counted top-to-bottom, the number Coverage cites; an
     insertion, removal, or reorder renumbers the labels and the Coverage
     lines together.
     Driving RR set → its Binding criteria appear VERBATIM here (binding-
     criteria check), each ingested as a numbered criterion carrying its tag
     — `- [ ] ACn (BCm): <verbatim>` — with its own Coverage line, since
     coverage-complete counts AC checkboxes positionally (M107); departures:
     a "Deviations from RR<NN>" table ends this section. -->

- [x] AC1: The procedure record of a `nested_results` from any of the five selecting orchestrators, under any rule, holds `first_metric`. The entry is the name of the first metric in the set as `tune::check_metrics_arg()` resolves it for the workflow. The record of a `nested_final_fit` built from it holds the same name. The final fit resolves that name from its own tuning run. `procedure_tuner()` treats the entry as shared, so no tuner receives it. A test asserts that `extract_procedure()` of the results and of its final fit give a `first_metric` equal to `tune::.get_tune_metric_names(extract_tune_results(fit))[[1]]`. It runs `nested_tune_grid()` under `metric_set(mae, rmse)`, `metric_set(rmse, mae)` and `metrics = NULL`, on one regression and one classification workflow. It runs each of the four other selecting orchestrators once. The same test asserts that a `nested_fit_resamples()` record has no `first_metric` entry.
- [ ] AC2: Under the `"best"`, `"one_std_err"` and `"pct_loss"` rules, four surfaces print the line `Selecting metric: <first_metric>`. They are `summary()` of a `nested_results`, `print()` and `summary()` of a `nested_final_fit`, and each tuned workflow's section of `summary()` of a `nested_results_set`. Under `"best"`, the line is the first line of the "Selected parameters" section. Under `"best"` in the final fit's print, it is the line after `Selected:`. Under the other two rules, it is the line after `Selected by:`. In the results summary and the set section, it prints when no outer fold completed. On each of the four surfaces, the line is absent under the `"desirability"` rule and on a record without `first_metric`. It is also absent on each surface that shows a `nested_fit_resamples()` result. Snapshot tests pin the line on each of the four surfaces under `"best"` and under `"one_std_err"`. Expectations assert each absence named above, and the line's presence in the results summary of a run in which every fold failed.
- [x] AC3: `summary.nested_results` and `summary.nested_final_fit` carry a `first_metric` component. It holds the record's entry, or `NULL` where the record holds none. A test asserts both values. The help pages of `summary.nested_results`, `print.nested_final_fit`, `summary.nested_results_set` and `extract_procedure` describe the line or the entry.
- [x] AC4: The `...` entry of `nested_workflow_map()`'s help says two things about a `metrics` passed there. Under the `"best"`, `"one_std_err"` and `"pct_loss"` rules, its first metric chooses each fold's candidate, and every metric in it is scored. The entry links to `nested_tune_grid()` for the default metric set and for the `"desirability"` rule. `man/nested_workflow_map.Rd` holds the text after `devtools::document()`.
- [ ] AC5: The `verify` slot is clean. `devtools::test()` passes. One exception applies: if `test-parallel-interrupt.R` fails inside the parallel suite and passes when run alone, the review records both runs and AC5 still holds. `devtools::document()` leaves no diff. Every gating sweep that `Rscript benchmarks/sweep-prose.R --list-gating` prints is clean. `devtools::check()` gives 0 errors, 0 warnings and 0 notes. `NEWS.md` has one entry for the line and the record entry.

## Coverage
<!-- owner: plan · create/amend-via-gate; each acceptance criterion → the
     task(s) satisfying it, by positional number (AC/Task counted
     top-to-bottom). Review reads to fence evidence — tracking-rules "AC fencing". -->

- AC1 → T1
- AC2 → T2
- AC3 → T2, T3
- AC4 → T3
- AC5 → T3

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits); substantive
     change is amend-via-gate. Every item opens with its positional label —
     `Tn:` — the item's position counted top-to-bottom, the number Coverage
     cites; an insertion, removal, or reorder renumbers the labels and the
     Coverage lines together. -->

- [x] T1: Record the entry. Write the test first in `tests/testthat/test-selection-metric.R`. Resolve the name in `nested_loop()` (`R/nested-tune-grid.R:656`) with `names(attr(tune::check_metrics_arg(metrics, object), "metrics"))[[1]]`, the reading `R/checks.R:1586` uses. Add `first_metric` to `new_procedure()` (`R/tuner.R:319`) for a selecting tuner alone, and to the shared names in `procedure_tuner()`. In `R/nested-final-fit.R`, pass the `metric_name` the final fit resolves (line 438) to both `new_procedure()` calls. Reuse the suite's existing fixtures for the four other tuners (D-079).
- [x] T2: Print the line. Extend `print_selected_by()` (`R/nested-results-print.R:391`) to print `Selecting metric:` after the rule line under the three metric rules. Add the `first_metric` component to `new_summary_nested_results()` and `new_summary_nested_final_fit()`. Re-record the two snapshot files and review every changed line. Assert absence through `cli::cli_fmt()`, never `capture.output()` (LESSONS, cli output).
- [x] T3: Write the help and the record. Describe the line and the entry on the four help pages AC3 names and in `nested_workflow_map()`'s `...` entry. Add the NEWS entry and the D-entry that supersedes M098's plan-gate choice for this line. Run the `verify` slot and `devtools::check()`.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates.
     EXEMPT from the 150-line cap (D-046): history under D-045, never edited,
     so the cap must never demand a trim here. Wrapped entries get a WARN.
     The rejected-alternative record (/milestone-plan step 4) takes this form:
     `- YYYY-MM-DD: plan gate chose <approach> over <alternative> because
     <reason>; falsified by <evidence class>.` — one per approach choice the
     gate actually weighed, none where it weighed none, and it is the record
     `/milestone-review`'s thrash trigger (b) reads. It lives here rather than
     below so an instantiated file inherits no placeholder to delete. -->

- 2026-09-24: created by /milestone-plan. Absorbs the two candidate rows M115 added (the `Selected by:` line under `"best"`, and the `nested_workflow_map()` help). The help row's premise was wrong: that page has no `metrics` entry to inherit, so the text goes in `...`.
- 2026-09-24: criteria audit (full mode, fresh [O] reader) returned 11 findings. Eight were fixed at the gate. AC1 names `procedure_tuner()`. AC2 drops "takes its place", limits the no-fold-completed clause to the two surfaces that can reach it, and names the absence surfaces. AC4 names its link scope. A D-entry records the M098 reversal. Old records are not migrated, and the final fit resolves its own name. The entry is recorded under every rule. Test breadth and instrument findings needed no change. Posed: the flake exception.
- 2026-09-24: plan gate chose a separate `Selecting metric:` line over extending `Selected by:` to `best on rmse`, because the rule line then stays the same words as the rule object's print (M098) and avoids "by num_comp on rmse"; falsified by a user reading the two lines as naming different things.
- 2026-09-24: plan gate chose recording `first_metric` at entry over deriving it at print time, because a `nested_results` stores no workflow and would read the name off `.inner_metrics` row order, with no answer when no fold completed; falsified by tune changing how `check_metrics_arg()` orders a default set.
- 2026-09-24: plan gate chose M109's named-test exception for `test-parallel-interrupt.R` over a strict pass, because the flake fails on `main` too (M079 candidate row); falsified by the flake being fixed.
- 2026-09-24: implement started on branch m116-selecting-metric; no question gate, since the plan left nothing open. T1 code and test written; full-suite run pending (checkpoint, T1 not ticked).
- 2026-09-24: T1 done. `first_metric` resolved in `nested_loop()` through the new `first_metric_name()`, recorded by `new_procedure()` for selecting tuners, shared in `procedure_tuner()`, and written by the final fit from its own `metric_name`. New `test-selection-metric.R` (22 expectations) passes. The full suite showed 3 failures, all tests pinning the record's entry names; each now lists `first_metric`, and both files pass.
- 2026-09-24: T2 done. `print_selected_by()` prints `Selecting metric:` through the new `names_selecting_metric()`, and both summaries carry `first_metric`. New tests in the two print test files cover placement, absence and the all-failed run. Two tests pinning the final fit's print text and summary names were updated. Snapshots re-recorded under NOT_CRAN=true: 27 added lines, all `Selecting metric: rmse`, none removed. The full suite under NOT_CRAN=true passes with no failures.
- 2026-09-24: T3 in progress. Help on the five pages written and regenerated, NEWS entry and D-081 added; all six gating sweeps clean after five sentences were split. Full suite and check() running (checkpoint, T3 not ticked).
- 2026-09-24: T3 done. Full suite under NOT_CRAN=true: no failures, so the AC5 exception was not used. `devtools::check()` 0 errors, 0 warnings, 0 notes. `devtools::document()` leaves no diff. All six gating sweeps clean.
- 2026-09-24: delegated the claim audit to a fresh [O] general-purpose reader; I applied its two corrections myself.
- 2026-09-24: claim audit: 58 claims read, 2 corrected — R/nested-workflow-map.R, R/nested-results-print.R
- 2026-09-24: status set to review. Only help and comment text changed after the last suite run; document() and all six sweeps are clean after the corrections.
- 2026-09-24: review started; moved the eight implement lines that had landed under Review into this log, unchanged. Checkpoint: full suite still running, AC2 gap found (see Review once recorded).
- 2026-09-24: review returned to in-progress (defect return 1). AC2 fails as written: no expectation asserts that the set summary prints no `Selecting metric:` line on a record without `first_metric`, one of the absences AC2 names on each of the four surfaces. Fix: add that expectation to `tests/testthat/test-nested-results-print.R`, then re-run `/milestone-review M116`. AC5 left unverified because review stopped before `devtools::check()`.
- 2026-09-24: implement resumed after defect return 1; no question gate. Added the set-summary expectation for a record without `first_metric` to the M116 AC2 set test in `test-nested-results-print.R`; the file passes (the test runs 9 expectations, 0 failed). Full suite running (checkpoint).
- 2026-09-24: full suite under NOT_CRAN=true: 89 files, 990 tests, 0 failed, 0 errors, 0 skipped. The earlier claim audit stands; the only prose added since is one test comment, which describes the four lines under it. Status set to review.
- 2026-09-24: review pass 2 returned to in-progress under the return floor (defect return 2). Finding [O]1, verified by running it: `first_metric_name()` calls `tune::check_metrics_arg()` after every fold has run, so a metric set that does not suit the model's mode (for example `metric_set(accuracy)` on a regression workflow) aborts the whole run from an internal frame. On `main` the same call returns a `nested_results` whose folds all failed. That breaks AC2 ("it prints when no outer fold completed") and is a regression. The fix approach, a `tryCatch` to `NULL` (the `check_desirability_rule()` pattern) or an entry refusal with the orchestrator's `call`, is the implement question gate's to settle, with a test for this path. `devtools::check()` was stopped unfinished.

## Decisions
<!-- owner: implement / review · append-only; milestone-local; promote
     cross-cutting ones to cairn/DECISIONS.md.
     EXEMPT from the 150-line cap (D-074) because D-045 makes it history like the work log — dated dispositions, never edited — so the cap must never demand a trim here either.
     Entries carry their rationale; the counterweight `decisions format`
     advisory watches for pasted output, not for entry length (D-075). -->

## Review
<!-- owner: review · exclusive; evidence per criterion, consistency-gate
     results, review findings + triage. EXEMPT from the 150-line cap (M55),
     as are the work log (D-046) and the decisions section (D-074); evidence
     never scrambles plan-owned content. -->
- 2026-09-24 (pass 1): synced, `origin/main` is an ancestor of the branch and `main` has no unpushed commits.
- AC1: `test-selection-metric.R` compares the record's `first_metric` on the results and on the final fit with `tune::.get_tune_metric_names()` of the final fit's run. It covers grid under `metric_set(mae, rmse)`, `metric_set(rmse, mae)` and `metrics = NULL` (regression), `metrics = NULL` (classification), Bayes, both racers and annealing, `procedure_tuner()` dropping the entry, and no entry on a `nested_fit_resamples()` record. The two named sets run on the regression workflow alone, since `mae` and `rmse` do not apply to a classification model. Suite green (below). The final fit writes `metric_name` from its own run (`R/nested-final-fit.R:463`).
- AC2: FAIL. Snapshots pin the line on all four surfaces under `"best"` and `"one_std_err"`, and placement, the all-failed results summary and set, desirability absence on all four surfaces, and fit_resamples absence on all four are asserted. No expectation asserts absence on the set summary for a record without `first_metric`. The behavior likely holds through the shared `print_selection()`, but AC2 requires the expectation. Box left unticked.
- AC3: `summary.nested_results` and `summary.nested_final_fit` carry `first_metric`, asserted as the record's entry and as `NULL` on untuned runs in the two print test files. The four named help pages describe the line or the entry (diff of `man/`).
- AC4: `R/nested-workflow-map.R` `...` entry states the first metric chooses under the three rules and every metric is scored, links `nested_tune_grid()` for `NULL` and desirability; `man/nested_workflow_map.Rd` holds it after `document()`.
- AC5: not verified on this pass. Evidence so far: `devtools::test()` under NOT_CRAN=true, 89 files, 990 tests, 0 failed, 0 errors, 0 skipped, 0 warnings (the flake exception not used); `devtools::document()` no diff; all six gating sweeps print `clean`; NEWS entry present. `devtools::check()` not run.
- Consistency gate (partial): `cairn_validate` all checks passed (18 references-staleness advisories); `pkgdown::check_pkgdown()` no problems; README.md not touched. Independent review not run, since review stopped at the AC2 failure.
- 2026-09-24 (pass 2): synced, `origin/main` is an ancestor of the branch; no PR exists. The only code change since pass 1 is the added test (`472bd94`).
- AC1 (pass 2): unchanged since pass 1; the suite run below re-passes `test-selection-metric.R`.
- AC2 (pass 2): the set test in `test-nested-results-print.R` now strips `first_metric` from the tuned workflow's record and asserts no `Selecting metric:` line in the set summary (the test's 9 expectations pass). Every absence AC2 names is now asserted on each surface, and the snapshots and presence checks from pass 1 stand. Full suite under NOT_CRAN=true: 89 files, 990 tests, 0 failed, 0 errors, 0 skipped.
- AC3, AC4 (pass 2): no change to their code, tests or help since pass 1; same suite run.
- Review pass 2, independent review (three lenses; findings ranked by each reviewer, all logged):
  - [O]1 (floor return, above): the run aborts after all folds on a metric set that does not suit the mode. The error names `first_metric_name()` rather than the orchestrator. It also hits a mode `"unknown"` spec, and a `nested_workflow_map()` over mixed modes with one shared `metrics`.
  - [O]2: no test covers a run whose folds fail for a reason `check_metrics_arg()` also rejects. Disposition: fix with [O]1.
  - [O]3: under `"desirability"`, `first_metric` and `summary()$first_metric` hold `"rmse"`, which chose nothing. This is intended by D-081, and the help says "first metric in the set". Disposition pending at the next gate (proposed: reject, as planned behavior).
  - [O]4: the AC1 test runs the two ordered sets on regression alone. The reviewer calls the AC ambiguous. Pass 1 recorded the collective reading. Disposition pending (proposed: noted).
  - [O]5: the final fit's print and summary help omit the no-entry absence, and the results summary's line paragraph omits the fit_resamples and no-entry absences (the component bullet covers them). Disposition pending (proposed: fix now).
  - [O]6: under censored regression the line omits the evaluation time tune selects at. Disposition pending (proposed: reject, informational; the name matches tune's).
  - [O]7: NEWS says "each fold's candidate" for the final fit, which chose one candidate. Disposition pending (proposed: fix now).
  - [S] blame-history: no findings; D-081 records the one M098 reversal.
  - [S] prior-review: no regression of an archived review finding. Side note that `R/tuner.R`'s "seven shared entries" should read eight: rejected, since `tuner` is the description, not a shared entry.
