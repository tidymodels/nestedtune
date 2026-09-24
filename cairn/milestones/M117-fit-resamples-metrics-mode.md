<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M117: `nested_fit_resamples()` refuses a metric set that does not suit the model's mode

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** GP3   <!-- owner: plan · create/amend-via-gate; comma-separated IPn/GPn ids this milestone touches, or — -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate; comma-separated GitHub issues the scope absorbs, each `#N closes` (the PR closes it at merge) or `#N partial` (the remainder gets a candidate row), or — ; skill conduct only — no validate check parses it -->
- **Surface tier:** user-facing — an exported function that returned failed folds now raises an error, and two help pages change   <!-- owner: plan · create/amend-via-gate; user-facing | internal — <one-clause reason>; skill conduct only — no validate check parses it -->
- **Branch/PR:** m117-fit-resamples-metrics-mode   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

`nested_fit_resamples()` refuses a metric set that does not suit the model's mode before any fold runs, as the five tuning functions do since M116. `nested_workflow_map()` does the same for every workflow it routes there.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** `nested_loop()` (`R/nested-tune-grid.R:624-629`) runs the entry check `check_metrics_mode()` (`R/checks.R:1215`) for every tuner. It still records the selecting metric's name only for a tuner that selects. The same check in `nested_workflow_map()`'s pre-check branch for workflows routed to `nested_fit_resamples()` (`R/nested-workflow-map.R:195-205`). Tests for both functions. The help of both functions and the unreleased M116 `NEWS.md` bullet say the refusal covers them. D-082 supersedes D-081's clause that `nested_fit_resamples()` keeps its old behavior.

**Out:** recording a `first_metric` on a `nested_fit_resamples()` result: nothing selects there, so D-081's record rule stands. Any other entry check on `nested_fit_resamples()`: none is asked for, and the row that asked for this one is absorbed here. `nested_final_fit()`: it takes no `metrics` argument of its own.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [x] AC1: The call is `nested_fit_resamples()` on a regression model with `metrics = yardstick::metric_set(yardstick::accuracy)`, through its `workflow` method and through its `model_spec` method given a `preprocessor`. Each call raises an error of class `nestedtune_metrics_mode` and no warning. The error's call names `nested_fit_resamples`, and its `parent` is an error. A test in `tests/testthat/test-selection-metric.R` asserts each of these for both methods.
- [x] AC2: A workflow set holds a workflow that `nested_workflow_map()` routes to `nested_fit_resamples()`, with a metric set that does not suit that workflow's mode. Then `nested_workflow_map()` raises an error of class `nestedtune_metrics_mode` before any workflow's run starts. A test covers both routes: `fn = "nested_fit_resamples"`, and a workflow with nothing to tune under `fn = "nested_tune_grid"`. In each, the refused workflow gets the unsuitable set through its own `option` entry (`workflowsets::option_add()`). It comes after a workflow whose set suits it. The test asserts the class, that the message names the refused workflow's id, and that no orchestrator call started.
- [x] AC3: A metric set that suits the mode still runs under `nested_fit_resamples()`, and its procedure record still holds no `first_metric`. The test at `tests/testthat/test-selection-metric.R:89` passes with its assertions unchanged.
- [x] AC4: `man/nested_fit_resamples.Rd` holds a sentence that says this: a metric set that does not suit the model's mode is refused before any fold runs. The two refusal sentences in `man/nested_workflow_map.Rd` and the M116 refusal sentence in `NEWS.md` each name `nested_fit_resamples()` or every workflow the map runs. `grep -rnE "tuned workflow's model|workflows it tunes" R/ man/ NEWS.md` prints no line.
- [x] AC5: The active profile's `verify` slot is clean: `devtools::test()` passes, `devtools::document()` leaves no diff, and `Rscript benchmarks/sweep-prose.R --plain` and `--roxygen --plain` report clean.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2
- AC2 → T3
- AC3 → T2
- AC4 → T4
- AC5 → T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits); substantive change is amend-via-gate. -->

- [x] T1: Write AC1's tests in `tests/testthat/test-selection-metric.R` beside the M116 refusal test (line 95), under `skip_if_no_engines()` (LESSONS, M101). See both fail on `main`'s code with the failure they are expected to have: no error, and a failed-fold warning.
- [x] T2: In `nested_loop()` run `check_metrics_mode()` for every tuner and keep its value as `first_metric` only where `tuner_selects()` holds. Update the comments there and above `check_metrics_mode()` (`R/checks.R:1209`). AC1's tests pass, and the line-89 test passes unchanged.
- [x] T3: Write AC2's test under `skip_if_no_wset_fixture()` and see it fail. The refused workflow takes its set from `workflowsets::option_add(metrics = ...)`, since a shared set in `...` refuses the first workflow. Count orchestrator calls with `local_mocked_bindings(run_orchestrator = ...)` (`R/nested-workflow-map.R:258-267`) or an equal probe. Update the pre-check comment at `R/nested-workflow-map.R:190-192`. Then call `check_metrics_mode()` in the `nested_fit_resamples` branch of `nested_workflow_map()`'s pre-check. Use the `map_args()` resolution and the metric-set guard of the tuned branch (`R/nested-workflow-map.R:198-204`).
- [x] T4: Say the refusal in `nested_fit_resamples()`'s help (the `metrics` entry at `R/nested-fit-resamples.R:25`). Make the details line at `:20` agree with it. Drop "tuned" from the two sentences in `nested_workflow_map()`'s help (`R/nested-workflow-map.R:43-45`, `125-127`). Rewrite the M116 bullet in `NEWS.md` (lines 11-14) to name `nested_fit_resamples()` and every workflow the map runs. Run `devtools::document()`.
- [x] T5: Run the `verify` slot in full and `air format --check` on the touched files.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-09-24: created by /milestone-plan, absorbing the `[low]` candidate row added at M116's review gate (finding P2).
- 2026-09-24: full criteria audit ([O] fresh reader) returned five findings, all fixed before the gate: AC2 needs the refused set in the workflow's own `option` entry, D-082 must land before the change, AC4 was a grep alone, T3/T4 missed two comments, AC1 lacked the `preprocessor`.
- 2026-09-24: plan gate chose an immediate error over a deprecation warning first because the package has no release; falsified by a user on a released version relying on the all-failed result.
- 2026-09-24: plan gate chose the check in the shared `nested_loop()` over one inside `nested_fit_resamples()` because one site covers every tuner; falsified by a tuner whose run accepts a set `tune::check_metrics_arg()` refuses.
- 2026-09-24: plan gate chose rewriting M116's unreleased NEWS bullet over a second bullet because one bullet then states the whole rule; falsified by a release that ships M116's bullet before this milestone merges.
- 2026-09-24: implement started on branch `m117-fit-resamples-metrics-mode`; no open choice, so no question gate.
- 2026-09-24: T1/T2 done. On `main` the AC1 test got no error and one `nestedtune_failed_folds` warning (3 of 3 folds failed); after `nested_loop()` checks every tuner, `test-selection-metric.R` passes whole.
- 2026-09-24: T3 done. On the old pre-check the AC2 test got no error under either route. The M116 map test now gives its fixed workflow a suitable `option` set and asserts the tuned workflow's id, so it still tests the tuned branch (minor edit to an existing test).
- 2026-09-24: T4 done. The help and NEWS name the new reach, and the AC4 grep prints nothing. The details line at `R/nested-fit-resamples.R:20` already agreed, so it is unchanged. Both prose sweeps are clean.
- 2026-09-24: T5 done. Full `devtools::test()` at `4332313` passed 11503 expectations with 0 failures. The claim-audit fixes after it touched one roxygen sentence and one test file, and both reran clean.
- claim audit: 14 claims read, 4 corrected — R/nested-workflow-map.R, tests/testthat/test-selection-metric.R. The M116 map test's warning count was blind after T3, so it now counts `run_orchestrator()` calls. With the pre-check disabled it read 2 runs and failed.

## Decisions
<!-- owner: implement / review · append-only; milestone-local. -->

## Review
<!-- owner: review · exclusive -->

Review of `7b5e4ef` on 2026-09-24. The branch already contained `origin/main`, so no merge was needed.

- AC1: `test_file("test-selection-metric.R")` gave the M117 AC1 test 8 expectations, 0 failed. It covers the `workflow` method and the `model_spec` method with a `preprocessor`, asserting class `nestedtune_metrics_mode`, 0 warnings, call `nested_fit_resamples`, and an error `parent`. The [O] reviewer removed the `nested_loop()` check and saw the test fail.
- AC2: the M117 AC2 test ran 6 expectations with 0 failures. It covers `fn = "nested_fit_resamples"` and `fn = "nested_tune_grid"` with a fixed workflow. The refused workflow `bad` comes second and takes its set from `option_add()`. The test asserts the class, `Workflow "bad"` in the message, and 0 `run_orchestrator()` calls. The [O] reviewer removed the pre-check and saw it fail.
- AC3: the test at `test-selection-metric.R:89` ("the entry reaches no tuner, and a run that selects nothing records none") ran 2 expectations with 0 failures. The branch diff of that file begins at line 111, so its assertions are unchanged. The [O] reviewer read the procedure names of a `nested_fit_resamples()` result and found no `first_metric`.
- AC4: `man/nested_fit_resamples.Rd:59-61` says a metric set that does not suit the model's mode is refused before any fold runs. `man/nested_workflow_map.Rd:29` and `:136` say "any workflow the map runs". The `NEWS.md` M116 bullet names `nested_fit_resamples()` and "every workflow the map runs". The AC4 grep printed no line (exit 1).
- AC5: full `devtools::test()` at `7b5e4ef` recorded 11503 passing expectations with no failure, warning or skip mark, and exited 0. `devtools::document()` left `git status` empty. `sweep-prose.R --plain` and `--roxygen --plain` both printed "clean".

Consistency gate: `cairn_validate.py` exited 0 (18 `references staleness` advisories, none failing). No DESIGN principle changed, so `cairn_impact` was skipped. `document()` made no diff. `pkgdown::check_pkgdown()` found no problems. The `NEWS.md` bullet covers the change. No new top-level files. `devtools::check()` gave 0 errors, 0 warnings, 0 notes. All six gating prose sweeps are clean. `air format --check` on the touched R files exited 0.

Independent review: three fresh reviewers ([O] diff, [S] blame history, [S] prior reviews) found no correctness defect. The [S] prior-review lens found no regression of an earlier finding. Findings, most severe first, with the dispositions proposed at the gate:

- O1: the help line at `R/nested-fit-resamples.R:20` says `metrics` "is read as `tune::fit_resamples()` reads it", but each fold scores with `tune::last_fit()`. Proposed: reject. The line is older than this branch, and both functions resolve metrics through `check_metrics_arg()`.
- O2: the AC2 test does not assert that `fn = "nested_tune_grid"` routes the fixed workflow to `nested_fit_resamples()`. Proposed: reject. `test-nested-workflow-map-oracles.R:58` already asserts that route.
- O3: AC1's "no fold ran" evidence rests on the failed-fold warning. Proposed: reject. AC1 asks for no warning. If folds run, the `expect_error()` still fails.
- O4: the map resolves the metric set twice, in the pre-check and again in `nested_loop()`. Proposed: reject. The plan put the check at both sites on purpose, and the cost is one `check_metrics_arg()` call per workflow.
- O5 and S1: an irregular line break before "it is refused" at `R/nested-workflow-map.R:128-129`. Proposed: reject. It is a style point and the rendered help is unchanged.
- O6: the change is an error with no deprecation period. Proposed: reject. The plan gate waived the deprecation because the package has no release, and the NEWS bullet ends "Before, every fold ran and failed."
