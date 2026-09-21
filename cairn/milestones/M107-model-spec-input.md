# M107: A model specification with a formula or recipe as the orchestrators' input

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP1, GP3
- **Resolves:** —
- **Surface tier:** user-facing — changes the signature of six exported functions
- **Branch/PR:** `m107-model-spec-input`

## Goal

A user who calls `tune_grid(spec, preprocessor, resamples)` can call `nested_tune_grid(spec, preprocessor, resamples)` and its five siblings the same way.

## Scope

**In:** Each of the six orchestrators becomes an S3 generic. It has a `workflow` method that keeps today's signature, and a `model_spec` method `(object, preprocessor, resamples, ...)` in tune's argument order. That method wraps the two in `workflows::workflow()` and runs the workflow path. The six are `nested_tune_grid()`, `nested_tune_bayes()`, `nested_tune_race_anova()`, `nested_tune_race_win_loss()`, `nested_tune_sim_anneal()` and `nested_fit_resamples()`. A D-entry records the signature. `check_workflow()`'s message on a bare `model_spec` passed to `nested_final_fit()` names the `workflow(preprocessor, spec)` wrapping.

**Out:** A `model_spec` door on `nested_final_fit()`, which the plan gate rejected (work log). `nested_workflow_map()`, whose input is already a set of workflows.

## Acceptance criteria

- [ ] AC1: Each of the six orchestrators accepts a parsnip `model_spec` with a formula `preprocessor`. The five tuners share a fixture with tuned parameters, and `nested_fit_resamples()` uses one with none. The test builds the preprocessor once, before the seed, and passes the same object to both calls. The reference is the same call on `workflows::workflow(preprocessor, spec)` under the same seed. For each orchestrator, a test asserts that `collect_metrics(summarize = FALSE)` and `collect_selections()` are identical to the reference. For `nested_fit_resamples()`, only `collect_metrics()` is compared.
- [ ] AC2: The same identity holds with a recipe `preprocessor` for `nested_tune_grid()` and `nested_fit_resamples()`, tested.
- [ ] AC3: `nested_final_fit(workflows::workflow(preprocessor, spec), res)` on a result built from a `model_spec` passes the workflow-identity check. Under one seed, its `predict()` output is identical to the final fit of the result built from the workflow. The test uses the `nested_tune_grid()` case with the AC2 recipe, built once.
- [ ] AC4: Each of three inputs raises an error the test names by class, for each of the six orchestrators. The first is a `model_spec` with no `preprocessor`. The second is a `preprocessor` that is neither a formula nor a recipe. The third is a `preprocessor` passed by name beside a `workflow`, whose message says that a workflow carries its own preprocessor. `nested_final_fit()` given a bare `model_spec` raises an error whose message names `workflows::workflow()`, tested.
- [ ] AC5: A D-entry records the signature choice. `NEWS.md` describes the new input, and each orchestrator's help documents `preprocessor`. `devtools::check()` gives 0 errors, 0 warnings, and no note absent from the check of `main` at the branch point.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T3
- AC3 → T4
- AC4 → T2, T4
- AC5 → T1, T5

## Tasks

- [x] T1: Write the D-entry for the generic-with-methods signature. (RB tripwire: irreversible-api) Read tune's `tune_grid.model_spec()` and the finetune methods for argument order and refusals first (LESSONS, claims about another package).
- [x] T2: Convert `nested_tune_grid()` (`R/nested-tune-grid.R:446`) to a generic with both methods, and add the classed refusals for the three bad inputs. The dots carry `control` (D-042), so check how `test-dots-barrier.R` and `test-fixture-cache.R` enumerate formals, and update them.
- [x] T3: Repeat T2 for the other five orchestrators. Write the AC1 and AC2 identity tests.
- [x] T4: Change `check_workflow()`'s message (`R/checks.R:8`) for a `model_spec`. Write the AC3 final-fit identity test and the AC4 refusal tests.
- [ ] T5: Write the help and `NEWS.md` text, then run `devtools::document()`, the prose sweeps from the verify slot, and `devtools::check()`.

## Work log

- 2026-09-21: created by /milestone-plan.
- 2026-09-21: criteria audit ran in full mode and returned four findings, all fixed above. They were recipe step ids drawn from the RNG stream, two fixtures for the tuned and untuned cases, `nested_final_fit()` refusing a bare spec, and a positional `preprocessor` beside a workflow landing in `resamples`.
- 2026-09-21: plan gate chose S3 generics in tune's argument order over a named `preprocessor` argument after the dots, because ported tune code then needs only a rename; falsified by the generic breaking a documented workflow call.
- 2026-09-21: plan gate chose wrapping in `workflow()` by the user for `nested_final_fit()` over a `model_spec` method there, because the final fit matches a recorded workflow (D-041); falsified by a user report that the spec route cannot pass that match.
- 2026-09-21: re-audit in full mode found AC3 silent on its preprocessor and AC4's third input already refused with an uninformative message. Both were fixed after the plan commit.
- 2026-09-21: implement started on branch `m107-model-spec-input`. Question gate took every recommendation: the spec method calls the generic again on the built workflow, two error classes (`nestedtune_bad_preprocessor`, `nestedtune_preprocessor_with_workflow`), a positional formula or recipe beside a workflow refused under the second class, and a default method refusing any other object.
- 2026-09-21: T1 done. D-069 records the signature, read against tune 2.1.0's `tune_grid`, `tune_bayes` and `fit_resamples` spec methods and finetune 1.3.0's race and annealing ones.
- 2026-09-21: T2 and T3 share one checkpoint (minor amendment). `orchestrator_args()` in `R/checks.R` reads the formals of all six for `nested_workflow_map()`, so it now reads each `.workflow` method, and converting one orchestrator alone left the map's tests red.
- 2026-09-21: T2 and T3 done. All six are generics with `default`, `model_spec` and `workflow` methods. `test-model-spec-input.R` holds the AC1 and AC2 identities and the AC4 refusals for all six. Tests that read the formals or bodies of the exports now read the `workflow` methods. Four check tests passed a bare spec as their `check_workflow` case, which now reaches the spec method, so they use an empty workflow. A planted defect (the grid spec method dropping `grid`) turned the AC1 and AC2 grid identities red. Suite 929 tests, 0 failed; both prose sweeps clean; `air format --check` clean.
- 2026-09-21: T4 done. The `check_workflow()` message change for a bare spec landed with T2, and its test with T3. The AC3 test finalizes both grid-recipe results on `workflow(recipe, spec)` under one seed and compares `predict()`. Its control, a recipe over other predictors, is refused with `nestedtune_workflow_mismatch`. The test file passes 195 expectations.

## Decisions

## Review
