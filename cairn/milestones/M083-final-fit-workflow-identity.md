# M083: Every nested result records the workflow it ran under, and the final fit refuses any other

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP4, GP3, GP4
- **Resolves:** —
- **Surface tier:** user-facing — an exported record entry and an exported function's refusal
- **Branch/PR:** `m083-final-fit-workflow-identity`

## Goal

Record a canonical identity of the workflow on every orchestrator's procedure record, so `nested_final_fit()` refuses a workflow other than the one the estimate was built around on every record, the `fit_resamples` one included.

## Scope

**In:** a canonical workflow identity (model specification and preprocessor, deparsed, random ids dropped) built once and stored as the `workflow` entry of the `procedure` record on all six orchestrators' results and on the final fit's own record; an entry check in `nested_final_fit()` refusing a mismatch; the old-record refusal; help pages, DESIGN Architecture, NEWS.

**Out:** storing the workflow object itself → rejected at the plan gate (the M12 lesson: rebuilt tidymodels objects are not `identical()`; the recipe template would copy the data, GP4). Making `object` optional on the final fit → rejected at the plan gate (D-041's signature stands). Migrating results saved before this milestone → refused, per D-041's no-migration clause. Any reader of the identity beyond `extract_procedure()` (a print line, a set-level comparison) → candidate row only if asked for.

## Acceptance criteria

- [ ] AC1: Every `nested_results` the six orchestrators the `tuner_registry` in `R/tuner.R` enumerates return, and each row of a `nested_results_set` from `nested_workflow_map()`, carries the workflow it ran under as `extract_procedure(res)$workflow`: a list naming the model specification (its parsnip class, engine, mode, and its main and engine arguments in canonical deparsed form) and the preprocessor (a formula, a variables selection, or a recipe as its step types in order with each step's selectors and settings in canonical deparsed form, its random step ids left out). The `nested_final_fit` object's record carries the same entry, and the final fit from such a record still runs.
- [ ] AC2: `nested_final_fit()` refuses a workflow whose identity differs from the record's with condition class `nestedtune_workflow_mismatch`, the message naming the part that differs, leaving the caller's generator state unchanged and fitting nothing; the refusal runs after the record checks, the grid-column check and the `tune()`-marker check, and before the seeds are drawn. Tested on a `fit_resamples`, a `tune_grid` and a `tune_bayes` record, one probe per axis: a different model type, engine, mode, main-argument value, an engine argument added and one removed, a `tune()` marker on one side and a value on the other, a formula and a variables selection in place of a recipe, a different formula, a recipe with one step added, one removed, two reordered, a step with a different selector, and a step with a different setting.
- [ ] AC3: A workflow rebuilt from the same code as the recorded one is accepted: the fixture built twice (its recipe step ids and quosure environments differ), and a model specification assembled through `parsnip::set_args()` and `set_engine()` after construction rather than in the constructor call, each pass the check, and under one seed the final fit from the rebuilt workflow gives the same predictions on a fixed frame and the same `extract_fit_parsnip()` coefficients as the fit from the original object, on a `fit_resamples` and a `tune_grid` record.
- [ ] AC4: A `nested_results` whose record carries no `workflow` entry is refused by `nested_final_fit()` with class `nestedtune_bad_results` through the earlier-version origin of `check_results_record()` (`R/checks.R:827`), before the identity check and leaving the generator state unchanged; `nested_final_fit()` on a `nested_results_set` with `id` still fits.
- [ ] AC5: The identity carries no data rows: the identity of a workflow built on a 90-row frame and of the same workflow built on a 900-row frame are `identical()`, and their serialized sizes are equal.
- [ ] AC6: `?nested_final_fit`'s "What is refused" section and `?extract_procedure`'s "What the record holds" section say what the identity compares, what it deliberately does not distinguish (a variable's value bound outside the workflow), and the mismatch refusal; `?nested_fit_resamples`'s "One door for a fixed workflow, one for a tuned one" section says the final fit ties the workflow to the record; DESIGN.md's Architecture entry for the final fit names the check.

## Coverage

- AC1 → T1, T2, T4
- AC2 → T3, T4
- AC3 → T1, T4
- AC4 → T3, T4
- AC5 → T1, T4
- AC6 → T5

## Tasks

- [x] T1: `workflow_identity(object)` in a new `R/workflow-identity.R`: model part from `extract_spec_parsnip()` (class, engine, mode, `args` and `eng_args` deparsed after `rlang::quo_squash()`), preprocessor part from `extract_preprocessor()` by kind (formula deparsed; variables deparsed; recipe as each step's class, its `terms` deparsed and its non-id fields deparsed, `template`, `id` and environments dropped). Tests first: rebuilt-fixture stability, `set_args()` route, 90-row versus 900-row equality and size (AC3, AC5).
- [x] T2: Record it: `new_procedure()` (`R/tuner.R:302`) takes `workflow` and adds it to the shared entries; `procedure_tuner()`'s `shared` vector (`R/tuner.R:336`) lists `workflow` so it is never forwarded as a tuner argument; the orchestrator entry in `R/nested-tune-grid.R:522` and both `new_procedure()` calls in `R/nested-final-fit.R` pass the identity. Test over the six registry entries and one set row (AC1).
- [x] T3: `check_workflow_identity(object, recorded, call)` in `R/checks.R`, aborting with `nestedtune_workflow_mismatch` and naming the differing part; wired into `nested_final_fit()` after `check_tuned_workflow()` and before `sample.int()` (`R/nested-final-fit.R:296`); `check_results_record()` requires the `workflow` entry through its earlier-version branch (AC2, AC4).
- [x] T4: `tests/testthat/test-nested-final-fit-identity.R`: the AC2 probe matrix on the three records, the AC3 same-fit comparison, the AC4 old-record refusal (a record with the entry stripped) and the set path, generator-state checks by `.Random.seed` before and after.
- [x] T5: Help pages (`R/nested-final-fit.R:91`, `R/extract-procedure.R`, `R/nested-fit-resamples.R:47`), DESIGN.md Architecture (`cairn/DESIGN.md:99`), a NEWS bullet; `devtools::check()` 0/0/0.

## Work log

- 2026-09-10: created by /milestone-plan from the candidate row M70's review finding O1 opened (absorbed here). Investigation: the tuned records' only tie is the grid-column check (`R/checks.R:704`), so the gap the row names on `fit_resamples` records exists on all six; a recipe workflow rebuilt from the same code is not `identical()` (random step ids), confirmed by hand.
- 2026-09-10: criteria audit ran in full mode ([O] fresh reader): 15 findings. Fixed: the record reader's shared list (T2), "as written" → canonical deparsed form, the set row added to AC1's domain, test-count and message-shape clauses moved to tasks, the probe matrix widened (variables preprocessor, step removed and reordered, selector, engine argument removed, marker versus value), a `tune_bayes` record added, the same-fit comparison on predictions and coefficients, the old-record refusal through the existing origin branch, "before any seed is drawn" → generator state unchanged, AC5 as `identical()` plus equal size, the fit_resamples section named by its real title, check and NEWS moved to T5. Two findings went to the gate (scope, refusal order).
- 2026-09-10: plan gate chose recording the identity on all six records over the `fit_resamples` record alone because the tuned records' grid-column check passes a different model tuning the same parameter names; falsified by a cost the entry adds to a tuned result that a user measures.
- 2026-09-10: plan gate chose a canonical deparsed fingerprint over storing the workflow and comparing with `identical()` because the M12 lesson and a hand check show rebuilt recipes differ in step ids and quosure frames, and the recipe template would copy the data (GP4); falsified by a workflow pair the fingerprint calls equal whose fits differ.
- 2026-09-10: plan gate chose refusing a pre-milestone results object over skipping the check because D-041 declined migration and IP4 records positively; falsified by a user needing a saved result carried across the change.
- 2026-09-10: plan gate chose running the identity check after the grid and marker checks over before them because those refusals name the exact column or marker; falsified by a user report that the earlier message misled them about which workflow to hand over.
- 2026-09-11: implement started on `m083-final-fit-workflow-identity`; question gate skipped, nothing open (the plan gate fixed the record shape, refusal order, fingerprint and no-migration stance; no dependency change).
- 2026-09-11: T1 done: `R/workflow-identity.R` and `test-workflow-identity.R` (27 assertions); suite 9619 pass, 0 fail. Found by execution: recipes stores a step setting by value (`num_comp = k` records `1L`), parsnip stores a model argument as written (`penalty = p` records `p`), so the help page's "not distinguished" clause holds for model arguments alone; the test file states both.
- 2026-09-11: T2 done: `new_procedure()` takes `workflow` as the last shared entry, `procedure_tuner()` lists it, the three record sites pass `workflow_identity(object)`; AC1 block in `test-nested-final-fit-identity.R` over the six registry entries, a set row and both final-fit paths; three name-pinning tests and two stub builders updated. Suite 9645 pass, 1 fail (the oracles file's name list, fixed and re-run green at 44).
- 2026-09-11: T3 done: `check_workflow_identity()` with `identity_difference()` naming the first differing part (kind, model type, engine, mode, an argument, roles, step count, a step's type, selector or setting), wired after `check_tuned_workflow()` and before `sample.int()`; `check_results_record()` asks for the `workflow` entry through the earlier-version origin, its message pluralized for a record missing both late entries. Suite 9646 pass, 0 fail. The checker was appended with a shell heredoc rather than the Edit tool, so it is absent from that turn's edit card.
- 2026-09-11: T4 done: the AC2 probe matrix (fifteen probes over the fit_resamples, tune_grid and tune_bayes records plus two formula records on lm and `null_model()` for the formula, mode and engine-argument-removed axes), the check-order block, the AC3 same-fit comparison on two records built with `linear_reg(engine = "lm", penalty = 1)`, the AC4 stripped-record refusals and the set path; 150 assertions. Two suite-only failures on the way: a probe built on `decision_tree()`/rpart was refused by the package check for `pec` when the worker had loaded censored's engine registrations, so the extra records use lm and the null model. Suite 9769 pass, 0 fail.
- 2026-09-11: T5 done: `?nested_final_fit` "What is refused" (identity paragraph, four refused shapes), `?extract_procedure` (`workflow` entry, description and return), `?nested_fit_resamples` "One door" section, DESIGN Architecture final-fit entry, one NEWS bullet; `sweep-prose.R --roxygen` and `--spans` clean; `document()` rewrote three Rd files; `devtools::check()` 0 errors, 0 warnings, 0 notes in 6m35s.

## Decisions

## Review
