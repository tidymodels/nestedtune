# M123: The parameter set a final fit searched

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1
- **Resolves:** —
- **Surface tier:** user-facing — it adds an exported method and a re-exported generic
- **Branch/PR:** —

## Goal

A final fit answers tune's `extract_parameter_set_dials()` with the parameter set its tuning run searched.

## Scope

**In:** a `nested_final_fit` method for `extract_parameter_set_dials()`. The generic is imported from tune and re-exported, on the pattern of D-068. The help, `NEWS.md` and one D-entry state the addition.

**Out:** `extract_workflow_set_result()`, which workflowsets 1.1.1 defines as a plain function, not a generic, so no method can reach it → the rewritten M106 candidate row. `extract_parameter_set_dials()` on a `nested_results_set` or a `nested_results` → the same row. The per-fold label columns → M122.

## Acceptance criteria

- [ ] AC1: `extract_parameter_set_dials()` on a `nested_final_fit` from `nested_tune_grid()` returns the parameter set that its tuning run searched. Grid stands for the other tuners, whose final fits keep the tuning run in the same slot. A test asserts three cases with `expect_identical()`. It computes each expected value from the orchestrator call's inputs. (a) The call gave `param_info` with known ranges: the result is that object. (b) The call gave no `param_info` and every range is known: the result is `hardhat::extract_parameter_set_dials()` of the untrained workflow. (c) The call gave no `param_info` and `mtry` has an unknown range: the result is that set after `dials::finalize()` on the full data's predictors.
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

- [ ] T1: Write the AC1 to AC3 tests first, in the test file of the D-068 extractors. Case (c) uses a ranger model and takes the ranger skip (LESSONS M101). Run the tests before T2 and record that they fail.
- [ ] T2: Add `extract_parameter_set_dials.nested_final_fit()` to `R/nested-final-fit-extract.R` on the `extract-nested_final_fit` topic. Read the set from the stored tuning run, not from the trained workflow, which holds no `tune()` placeholders. Refuse with `check_tuning_run()` and `rlang::check_dots_empty()`. Import and re-export the generic in `R/reexports.R`. Append a D-entry that extends D-068 with this method.
- [ ] T3: Add the `NEWS.md` bullet. Run `Rscript benchmarks/sweep-prose.R --plain` and `--roxygen --plain`.
- [ ] T4: Run `devtools::document()`, `devtools::check()` and `pkgdown::check_pkgdown()`.

## Work log

- 2026-09-28: created by /milestone-plan from the "What M106 left" candidate row, split from M122 at the plan gate.
- 2026-09-28: criteria audit (full mode, fresh [O] reader) read the combined draft and returned 14 findings, each with one fix, all applied before the gate. For this milestone it added case (c) for an unknown range and named the help topic. It said "the orchestrator call" in place of "the call". It confirmed by execution that `extract_workflow_set_result()` is not a generic in workflowsets 1.1.1. The split then moved the criteria between files without a change of wording.
- 2026-09-28: plan gate chose to leave `extract_workflow_set_result()` out over an accessor with another name, because `x$result[[i]]` and `extract_workflow(set, id)` already reach each run; falsified by workflowsets making the function a generic, or by a user asking for the reader.
- 2026-09-28: plan gate chose the final fit alone over also adding a method on the set, because the candidate row asked for the final fit; falsified by a user asking for a set's parameter set.
- 2026-09-28: plan chose to read the parameter set from the stored tuning run over handing the call to the trained workflow, because the finalized workflow holds no `tune()` placeholders and returns an empty set; falsified by tune adding a `tune_results` method whose answer differs.

## Decisions

## Review
