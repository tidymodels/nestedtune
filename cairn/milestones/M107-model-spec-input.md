# M107: A model specification with a formula or recipe as the orchestrators' input

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2, GP1, GP3
- **Resolves:** —
- **Surface tier:** user-facing — changes the signature of six exported functions
- **Branch/PR:** `m107-model-spec-input` · https://github.com/tidymodels/nestedtune/pull/122

## Goal

A user who calls `tune_grid(spec, preprocessor, resamples)` can call `nested_tune_grid(spec, preprocessor, resamples)` and its five siblings the same way.

## Scope

**In:** Each of the six orchestrators becomes an S3 generic. It has a `workflow` method that keeps today's signature, and a `model_spec` method `(object, preprocessor, resamples, ...)` in tune's argument order. That method wraps the two in `workflows::workflow()` and runs the workflow path. The six are `nested_tune_grid()`, `nested_tune_bayes()`, `nested_tune_race_anova()`, `nested_tune_race_win_loss()`, `nested_tune_sim_anneal()` and `nested_fit_resamples()`. A D-entry records the signature. `check_workflow()`'s message on a bare `model_spec` passed to `nested_final_fit()` names the `workflow(preprocessor, spec)` wrapping.

**Out:** A `model_spec` door on `nested_final_fit()`, which the plan gate rejected (work log). `nested_workflow_map()`, whose input is already a set of workflows.

## Acceptance criteria

- [x] AC1: Each of the six orchestrators accepts a parsnip `model_spec` with a formula `preprocessor`. The five tuners share a fixture with tuned parameters, and `nested_fit_resamples()` uses one with none. The test builds the preprocessor once, before the seed, and passes the same object to both calls. The reference is the same call on `workflows::workflow(preprocessor, spec)` under the same seed. For each orchestrator, a test asserts that `collect_metrics(summarize = FALSE)` and `collect_selections()` are identical to the reference. For `nested_fit_resamples()`, only `collect_metrics()` is compared.
- [x] AC2: The same identity holds with a recipe `preprocessor` for `nested_tune_grid()` and `nested_fit_resamples()`, tested.
- [x] AC3: `nested_final_fit(workflows::workflow(preprocessor, spec), res)` on a result built from a `model_spec` passes the workflow-identity check. Under one seed, its `predict()` output is identical to the final fit of the result built from the workflow. The test uses the `nested_tune_grid()` case with the AC2 recipe, built once.
- [x] AC4: Each of three inputs raises an error the test names by class, for each of the six orchestrators. The first is a `model_spec` with no `preprocessor`. The second is a `preprocessor` that is neither a formula nor a recipe. The third is a `preprocessor` passed by name beside a `workflow`, whose message says that a workflow carries its own preprocessor. `nested_final_fit()` given a bare `model_spec` raises an error whose message names `workflows::workflow()`, tested.
- [x] AC5: A D-entry records the signature choice. `NEWS.md` describes the new input, and each orchestrator's help documents `preprocessor`. `devtools::check()` gives 0 errors, 0 warnings, and no note absent from the check of `main` at the branch point.

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
- [x] T5: Write the help and `NEWS.md` text, then run `devtools::document()`, the prose sweeps from the verify slot, and `devtools::check()`.

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
- 2026-09-21: T5 in progress (checkpoint). Help and `NEWS.md` text written, `document()` run, and all six gating prose sweeps clean. `devtools::check()` is running. The claim audit's first pass read 27 claims and flagged 4. Four comments are corrected, and D-070 corrects D-069's reason for refusing `workflow_variables()`. The audit's re-read is pending.
- 2026-09-21: claim audit: 27 claims read, 4 corrected — R/checks.R, tests/testthat/test-model-spec-input.R, tests/testthat/test-dots-barrier.R. The same reader re-read the four and found each true.
- 2026-09-21: T5 done. `devtools::check()` gave 0 errors, 0 warnings and 0 notes, so no note is new against `main`. It ran before the comment-only corrections. The edited test files were re-run clean after them. `cairn_validate` passes. Status set to review.
- 2026-09-21: review in progress (checkpoint). AC1 to AC4 evidence recorded and ticked. `devtools::check()` and the three reviewers are still running.
- 2026-09-21: review gate: the user took every fix-now group (findings 1, 2, 4 to 7, 10 to 13) and approved the merge, subject to a re-ask if a fix is nontrivial. D-070 is widened for finding 10, instead of a new entry, to keep one correcting entry for this milestone. It had not reached `main`.
- 2026-09-21: step-7 approval: m107-model-spec-input approved for merge (re-asked after the nontrivial fixes in 60dec8e).

## Decisions

## Review

Branch in sync with `origin/main` (3b35c86, unmoved since the branch point). Evidence gathered 2026-09-21.

- AC1: `test-model-spec-input.R` ran fresh under `devtools::load_all()`. The five AC1 blocks (grid, bayes, both racers, sim_anneal, fit_resamples) ran with no skip and 0 failures. Each block builds the formula once before `set.seed(107)` and passes that object to both calls. Each asserts that `collect_metrics(summarize = FALSE)` is identical on the two routes. The five tuners also assert identical `collect_selections()`. The tuners use `rand_forest(min_n = tune())`. `nested_fit_resamples()` uses `rand_forest(min_n = 10L)` and also compares the summarized `collect_metrics()`.
- AC2: the same run passed the two AC2 blocks with no skip and 0 failures. `nested_tune_grid()` runs on a `step_pca` recipe that tunes `num_comp`, with a written-out step id, and `nested_fit_resamples()` runs on the same recipe with `num_comp = 2L`. Each recipe is built once and passed to both calls under one seed. The grid block compares metrics and selections, and the fit_resamples block compares metrics.
- AC3: the AC3 block passed 3 expectations in the same run, with no skip. It reuses the AC2 grid-recipe results, built once. `nested_final_fit(workflow(recipe, spec), res)` on the spec-route result raises no `nestedtune_workflow_mismatch`. Under `set.seed(3)`, its `predict()` output is identical to the final fit of the workflow-route result. A control workflow with a recipe over other predictors is refused with `nestedtune_workflow_mismatch`, so the identity check is live on this result.
- AC4: the four AC4 blocks passed in the same run. finetune is installed, so the `tuner_ready()` guard skipped no orchestrator. Every block looped over all six exports: 18, 66 and 54 expectations for the three inputs. A spec with no preprocessor raises `nestedtune_bad_preprocessor`. A number, a nested design and `workflow_variables()` as preprocessor each raise `nestedtune_bad_preprocessor`. A formula beside a workflow, by name or by position, raises `nestedtune_preprocessor_with_workflow`, and the by-name message contains "A workflow carries its own preprocessor". Each condition's call names the export. `nested_final_fit()` on a bare spec raises an error whose message contains `workflows::workflow(preprocessor, spec)`.
- AC5: D-069 records the signature, and D-070 corrects its reason for refusing `workflow_variables()`. `NEWS.md` has one entry for the new input, with no milestone number. Each of the five Rd files for the six orchestrators documents `preprocessor` (`nested_tune_race.Rd` covers both racers). `devtools::check()` ran fresh on 0562c9f: 0 errors, 0 warnings, 0 notes, so no note is absent from the check of `main`.

Consistency gate (2026-09-21): `cairn_validate` passes, with 18 references-staleness advisories that predate this branch. No DESIGN principle changed, so `cairn_impact` is skipped. `devtools::document()` gives no diff. README.Rmd and README.md are both untouched by the branch. `pkgdown::check_pkgdown()` finds no problems. The six gating prose sweeps each exit 0. No new top-level files.

Independent review: three fresh-context reviewers ran. The blame-history reviewer found nothing. The prior-review reviewer found no prior-review evidence on the touched files. Its side note claimed that the annealer and the racers order the finetune check differently, which is false: both call `check_tuner_installed()` first. The diff-bug reviewer reported 14 findings, ranked below. Findings 1, 5 and 7 were confirmed by running code at review.

1. A missing `resamples` gives base R's unclassed "argument missing" error naming `nested_tune_grid.workflow(wf)` or `nested_tune_grid.model_spec(...)`, where `main` named `nested_tune_grid(wf)`.
2. The identity tests do not catch a spec method dropping `metrics` (the fixture equals the default), `event_level`, `eval_time`, `select`, `objective`, or `...` outside the racers.
3. The AC3 `predict()` identity holds by construction, because both fits use one workflow and the `lm` engine draws nothing.
4. A formula by position beside a workflow, with `resamples` named, gets the generic `nestedtune_bad_dots` message instead of `nestedtune_preprocessor_with_workflow`.
5. Errors raised through the spec route carry the internal re-dispatch call as `conditionCall()`. The rlang header still prints the export's name.
6. On the racers and the annealer, the spec route judges the preprocessor before it checks that finetune is installed.
7. Calling an orchestrator with no arguments fails inside cli with "Could not evaluate cli `{}` expression".
8. A spec with no mode fails inside `add_model()`, so the error names that function. tune does the same.
9. The default method gives no hint for a reversed `(recipe, spec, folds)` call or a `workflow_set`.
10. D-069's text names only a formula or recipe in the `resamples` position, but the code also refuses `workflow_variables()` there and any value passed by name as `preprocessor`.
11. The `...` help entry says the dots carry `control` "and nothing else", but the generic's usage line is now `(object, ...)`.
12. In the race identity test, a skip for the anova fixture also skips win_loss, because the skip sits inside the loop.
13. The `check_workflow()` comment frames the function around the orchestrators. `nested_workflow_map()` also calls it.
14. `cairn/DESIGN.md` is unchanged. It does not describe the orchestrators' inputs.

Triage at the merge gate (2026-09-21). No finding shows a criterion failing, so none returns the milestone.

- Fix now, done: 1, 4, 5, 6, 7 (error messages and the recorded call), 2 and 12 (test strength), 10, 11 and 13 (doc text).
- Rejected: 3, because AC3 asks for the `predict()` identity and the test gives it with a live mismatch control. 8 and 9, because tune's own methods behave the same way. 14, because DESIGN.md does not describe the orchestrators' inputs.
- Prior-review side note (finetune check order in the workflow methods): rejected, because both call `check_tuner_installed()` first.

Fix-now evidence. A missing `resamples` on either route and a call with no `object` raise `rlang::check_required()` errors that name the export. A formula passed unnamed beside a workflow, with `resamples` named, raises `nestedtune_preprocessor_with_workflow`. The racer and annealer spec methods check finetune before the preprocessor, which a mocked absent finetune confirms. `with_user_call()` rewrites the internal call on errors from the workflow method to the user's call, and a test asserts `conditionCall()` identical to the user's call for all six. A forwarding test replaces each workflow method and asserts that every named argument and `control` arrive as given. Planted defects turned it red: `select` dropped from the grid spec method, and `...` dropped from the bayes spec method. Disabling the rewrite turned the recorded-call test red (6 of 12). The two racers' identity tests are now separate blocks. The `...` help now describes the generic and the methods apart. D-070 is widened to state every input refused beside a workflow. The three shared-check tests list `check_required` as a new shared check. `test-model-spec-input.R` and the three checks files pass. Prose sweeps and `air format --check` are clean, and `document()` is in sync. `devtools::check()` on 60dec8e: 0 errors, 0 warnings, 0 notes.
