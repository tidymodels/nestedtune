# M123: The parameter set a final fit searched

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1
- **Resolves:** —
- **Surface tier:** user-facing — it adds an exported method and a re-exported generic
- **Branch/PR:** m123-final-fit-parameter-set

## Goal

A final fit answers tune's `extract_parameter_set_dials()` with the parameter set its tuning run searched.

## Scope

**In:** a `nested_final_fit` method for `extract_parameter_set_dials()`. The generic is imported from tune and re-exported, on the pattern of D-068. The help, `NEWS.md` and one D-entry state the addition.

**Out:** `extract_workflow_set_result()`, which workflowsets 1.1.1 defines as a plain function, not a generic, so no method can reach it → the rewritten M106 candidate row. `extract_parameter_set_dials()` on a `nested_results_set` or a `nested_results` → the same row. The per-fold label columns → M122.

## Acceptance criteria

- [x] AC1: `extract_parameter_set_dials()` on a `nested_final_fit` from `nested_tune_grid()` returns the parameter set tune stored on the final fit's tuning run. A test asserts four cases with `expect_identical()`. It computes each expected value from the orchestrator call's inputs. That test covers grid only. The other tuners' final fits keep the tuning run in the same slot. (a) The call gave `param_info` with known ranges: the result is that object. (b) The call gave no `param_info` and every range is known: the result is `hardhat::extract_parameter_set_dials()` of the untrained workflow. (c) The call used a formula workflow, gave no `param_info`, gave `grid` as a number, and `mtry` has an unknown range: the result is `dials::finalize()` of the untrained workflow's `hardhat::extract_parameter_set_dials()` on the full data's predictor columns. (d) The same call with `grid` as a data frame: the result is the untrained workflow's `hardhat::extract_parameter_set_dials()`, with the range of `mtry` still unknown. The help states that with a data-frame `grid` the returned set can keep an unknown range.
- [x] AC2: The same call refuses a final fit from `nested_fit_resamples()` with condition class `nestedtune_no_tuning_run`. It refuses a non-empty `...` with class `rlib_error_dots_nonempty`. A test asserts each class.
- [x] AC3: `extract_parameter_set_dials` is imported from tune and re-exported, as the seven extractors of D-068 are. `NAMESPACE` carries `export(extract_parameter_set_dials)` and the method's `S3method()` line. A test calls `nestedtune::extract_parameter_set_dials()` on a final fit. The method is documented on the `extract-nested_final_fit` help topic, which `_pkgdown.yml` already lists. `pkgdown::check_pkgdown()` reports no problem.
- [x] AC4: `NEWS.md` gains one bullet for the new method.
- [x] AC5: `devtools::check()` reports 0 errors, 0 warnings and 0 notes.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T2, T4
- AC4 → T3
- AC5 → T4

## Tasks

- [x] T1: Write the AC1 to AC3 tests first (four AC1 cases), in the test file of the D-068 extractors. Cases (c) and (d) use a ranger model and take the ranger skip (LESSONS M101). Run the tests before T2 and record that they fail.
- [x] T2: Add `extract_parameter_set_dials.nested_final_fit()` to `R/nested-final-fit.R`, where the `extract-nested_final_fit` topic lives. Read the set from the stored tuning run, not from the trained workflow, which holds no `tune()` placeholders. Refuse with `check_tuning_run()` and `rlang::check_dots_empty()`. Import and re-export the generic in `R/reexports.R`. Append a D-entry that extends D-068 with this method.
- [x] T3: Add the `NEWS.md` bullet. Run `Rscript benchmarks/sweep-prose.R --plain` and `--roxygen --plain`.
- [x] T4: Run `devtools::document()`, `devtools::check()` and `pkgdown::check_pkgdown()`.

## Work log

- 2026-09-28: created by /milestone-plan from the "What M106 left" candidate row, split from M122 at the plan gate.
- 2026-09-28: criteria audit (full mode, fresh [O] reader) read the combined draft and returned 14 findings, each with one fix, all applied before the gate. For this milestone it added case (c) for an unknown range and named the help topic. It said "the orchestrator call" in place of "the call". It confirmed by execution that `extract_workflow_set_result()` is not a generic in workflowsets 1.1.1. The split then moved the criteria between files without a change of wording.
- 2026-09-28: plan gate chose to leave `extract_workflow_set_result()` out over an accessor with another name, because `x$result[[i]]` and `extract_workflow(set, id)` already reach each run; falsified by workflowsets making the function a generic, or by a user asking for the reader.
- 2026-09-28: plan gate chose the final fit alone over also adding a method on the set, because the candidate row asked for the final fit; falsified by a user asking for a set's parameter set.
- 2026-09-28: plan chose to read the parameter set from the stored tuning run over handing the call to the trained workflow, because the finalized workflow holds no `tune()` placeholders and returns an empty set; falsified by tune adding a `tune_results` method whose answer differs.
- 2026-09-28: implement started on branch m123-final-fit-parameter-set. A probe on tune 2.1.0 found AC1's case (c) false for a data-frame `grid`: tune stores the set with `mtry` at `[1, ?]` and finalizes it only for a numeric `grid`.
- re-audit: AC1 (full) — returned 4 findings on the narrowed draft: the first sentence promised what the run searched rather than what tune stored, "Grid stands for the other tuners" was unbounded, the data-frame case went unstated, and "that set" had a loose antecedent.
- 2026-09-28: amendment gate chose to narrow AC1 and add case (d) over narrowing alone, because the help must explain the `[1, ?]` a user can see.
- re-audit: AC1 (full) — returned 6 findings: (c) needed a formula workflow, sentence order, (d)'s help clause was not checkable, the other-tuner clause lacked evidence, the Goal says "searched", and T1's ranger skip missed (d). The user accepted the tightened wording. The Goal is left unchanged. T1 and T2 got minor edits: the ranger skip covers (d), and the topic lives in `R/nested-final-fit.R`.
- 2026-09-28: T1 done. Five new tests in `test-nested-final-fit-extract.R` cover cases (a) to (d), the two refusals and the re-export. Before T2, all five failed because `extract_parameter_set_dials` was not found in the package.
- 2026-09-28: T2 done. The method reads `attr(x$tuning, "parameters")`, and the help topic, the re-export and D-089 are added. The file's tests and the full suite pass, and both prose sweeps are clean. The re-export test builds the data before the workflow, because a nested `det_workflow(make_reg_data())` draws the `step_pca()` id before the data seed.
- 2026-09-28: T3 done. `NEWS.md` has one bullet for the new method, and both prose sweeps (`--plain`, `--roxygen --plain`) are clean.
- claim audit: 19 claims read, 2 corrected — R/nested-final-fit.R, tests/testthat/test-nested-final-fit-extract.R
- 2026-09-28: The claim audit found the help's finalize sentence false for `nested_tune_bayes()`, which refuses an unknown range. The sentence is narrowed to `nested_tune_grid()`, and a test comment now names the ranges it narrows. The same reader re-read both and found them correct.
- 2026-09-28: T4's first `devtools::check()` gave 1 warning, because the tests called `hardhat::` and hardhat is not declared. The tests now call `tune::extract_parameter_set_dials()`, the same function object re-exported, so no dependency changed. `document()` gives no diff after the fix, and `pkgdown::check_pkgdown()` finds no problem.
- 2026-09-28: T4 done. The second `devtools::check()` on the final code gave 0 errors, 0 warnings and 0 notes. Status set to review.
- 2026-09-28: correction to the claim-audit line above. `nested_tune_bayes()` does not refuse an unknown range at entry. Every outer fold fails with a warning, and `nested_final_fit()` then refuses with class `nestedtune_no_completed_folds`.
- 2026-09-28: review gate fixed O1 to O3 in the help and rejected O4, O5, O6 and O8.
- step-7 approval: m123-final-fit-parameter-set approved for merge

## Decisions

## Review

- Sync: 2026-09-28, the branch already contains `origin/main`; no merge was needed. No PR exists for the branch (resume route d).
- AC1: `test-nested-final-fit-extract.R` run with `NOT_CRAN=true` on 2026-09-28: the three tests for cases (a) to (d) pass, 8 expectations, none skipped. Each case uses `expect_identical()` against a value built from the call's inputs, with a control that the expected set differs from the alternative. A planted method that reads the trained workflow failed all five new tests. The Rd `\details` states that a data-frame `grid` can keep an unknown range.
- AC2: the refusal test passes in the same run: class `nestedtune_no_tuning_run` for a `nested_fit_resamples()` fit and `rlib_error_dots_nonempty` for `nonesuch = 1`. The planted method, which does not refuse, failed it.
- AC3: `NAMESPACE` has `export(extract_parameter_set_dials)` (line 110), `S3method(extract_parameter_set_dials,nested_final_fit)` (line 36) and the tune `importFrom` (line 142). The re-export test calls `nestedtune::extract_parameter_set_dials()` and passes. The method is on `man/extract-nested_final_fit.Rd`, which `_pkgdown.yml` line 75 lists. `pkgdown::check_pkgdown()`: no problems found.
- AC4: `git diff main...HEAD -- NEWS.md` adds one bullet, which names `extract_parameter_set_dials()` on a `nested_final_fit`. It carries no milestone number.
- AC5: `devtools::check()` on 2026-09-28 at `3129a5f1`: 0 errors, 0 warnings, 0 notes.
- Consistency gate: `cairn_validate.py` exit 0, with 18 advisory warnings on reference staleness that predate this branch. `devtools::document()` gives no diff. `pkgdown::check_pkgdown()` finds no problem. The six gating prose sweeps exit 0. README is not touched. No new top-level file. No DESIGN principle changed, so `cairn_impact` is skipped.
- Reviewers: three lenses, because the tier is user-facing. The blame-history lens found nothing against D-068 or D-089. The prior-review lens found no regression of the M106 lessons. The PR comment probe found only one comment, on an unrelated file. The diff-bug lens found no code bug and ranked 8 findings. The session re-ran O1 and O2: with `grid = 3`, racing, annealing, and a `param_info` with an unknown range all return `mtry` as `[1, 4]`.
- O1: the help names only `nested_tune_grid()` with a numeric `grid` as a case where tune finalizes an unknown range. Racing and annealing finalize too, so a reader can infer the opposite. Fixed now: the help says tune finalizes where it built the candidates itself, as for a numeric `grid` or for `nested_tune_sim_anneal()`.
- O2: the help says that for a call with `param_info`, the stored set is that object. A `param_info` with an unknown range comes back finalized, not as that object. Fixed now: the help says the set starts from `param_info`, and the finalize sentence then applies to it.
- O3: the topic description says each method gives the same answer as the call on `extract_workflow()`'s output, and this method does not. Fixed now: the description names `extract_parameter_set_dials()` as the exception.
- O4: test (c) cannot tell a full-data finalize from one on a row subset, because the bound of `mtry` depends only on the column count. Rejected: a row subset gives the same set, so a user sees no difference.
- O5: under `devtools::test()`, the `nestedtune::` call resolves even without the `export()` line. Only `R CMD check` tests the installed package. Rejected: AC5's `R CMD check` runs the test on the installed package.
- O6: only grid is tested, which AC1 allows. Rejected: AC1 covers grid only, and the session probed racing and annealing.
- O7: a work-log line says `nested_tune_bayes()` refuses an unknown range. In fact every outer fold fails, and `nested_final_fit()` then refuses. Fixed now: a work-log line corrects it, after a session probe gave the fold warning and class `nestedtune_no_completed_folds`.
- O8: `@importFrom tune extract_parameter_set_dials` appears in two files. NAMESPACE holds it once. Rejected: no effect on the built package.
- Fix-now re-check, 2026-09-28: after the help edit, `document()` gives no further diff and the six prose sweeps exit 0. `pkgdown::check_pkgdown()` finds no problem. `devtools::check()` gives 0 errors, 0 warnings, 0 notes.
