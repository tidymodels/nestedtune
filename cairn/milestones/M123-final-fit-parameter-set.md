# M123: The parameter set a final fit searched

- **Status:** in-progress
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

- [ ] AC1: `extract_parameter_set_dials()` on a `nested_final_fit` from `nested_tune_grid()` returns the parameter set tune stored on the final fit's tuning run. A test asserts four cases with `expect_identical()`. It computes each expected value from the orchestrator call's inputs. That test covers grid only. The other tuners' final fits keep the tuning run in the same slot. (a) The call gave `param_info` with known ranges: the result is that object. (b) The call gave no `param_info` and every range is known: the result is `hardhat::extract_parameter_set_dials()` of the untrained workflow. (c) The call used a formula workflow, gave no `param_info`, gave `grid` as a number, and `mtry` has an unknown range: the result is `dials::finalize()` of the untrained workflow's `hardhat::extract_parameter_set_dials()` on the full data's predictor columns. (d) The same call with `grid` as a data frame: the result is the untrained workflow's `hardhat::extract_parameter_set_dials()`, with the range of `mtry` still unknown. The help states that with a data-frame `grid` the returned set can keep an unknown range.
- [ ] AC2: The same call refuses a final fit from `nested_fit_resamples()` with condition class `nestedtune_no_tuning_run`. It refuses a non-empty `...` with class `rlib_error_dots_nonempty`. A test asserts each class.
- [ ] AC3: `extract_parameter_set_dials` is imported from tune and re-exported, as the seven extractors of D-068 are. `NAMESPACE` carries `export(extract_parameter_set_dials)` and the method's `S3method()` line. A test calls `nestedtune::extract_parameter_set_dials()` on a final fit. The method is documented on the `extract-nested_final_fit` help topic, which `_pkgdown.yml` already lists. `pkgdown::check_pkgdown()` reports no problem.
- [ ] AC4: `NEWS.md` gains one bullet for the new method.
- [ ] AC5: `devtools::check()` reports 0 errors, 0 warnings and 0 notes.

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
- [ ] T4: Run `devtools::document()`, `devtools::check()` and `pkgdown::check_pkgdown()`.

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

## Decisions

## Review
