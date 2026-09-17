# M103: The workflow identity reads case weights and a postprocessor

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP3
- **Resolves:** —
- **Surface tier:** user-facing — what nested_final_fit() refuses
- **Branch/PR:** m103-identity-case-weights-postprocessor

## Goal

`workflow_identity()` records a workflow's case-weights column and its tailor postprocessor, so `nested_final_fit()` refuses a workflow differing in either, while a workflow with neither keeps the identity it has today.

## Scope

**In:** two new identity parts read from `pre$actions$case_weights$col` and `post$actions$tailor` (`R/workflow-identity.R:21`), omitted when absent; `tailor` in Suggests with a D-entry; refusal tests; the two help pages naming what is not compared.

**Out:** what a function-valued step setting closes over (stays a candidate row); a mismatch message diffing two tailors beyond naming the part.

## Acceptance criteria

- [ ] AC1: Two workflows differing only in their case-weights column (`workflows::add_case_weights()`) have different `workflow_identity()` values, and `nested_final_fit()` on a record built from one refuses the other with class `nestedtune_workflow_mismatch` naming the case-weights part; the same holds for a workflow with and without a tailor postprocessor, and for two tailors differing in adjustment type, in one adjustment's argument value, or in adjustment order.
- [ ] AC2: `workflow_identity()` of a workflow with neither case weights nor a postprocessor is `identical()` to its value at the branch point, so a record saved before this milestone is accepted by `nested_final_fit()` under the workflow it ran under.
- [ ] AC3: `tailor` is in `Suggests`, and the help text in `?nested_final_fit` and `?extract_procedure` listing what the identity does not compare no longer names case weights or a postprocessor.
- [ ] AC4: `devtools::test()` clean, `devtools::check()` at 0 errors, 0 warnings, 0 notes, and every sweep `--list-gating` names runs clean.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T3
- AC4 → T4

## Tasks

- [x] T1: Tests first in `test-workflow-identity.R` and `test-nested-final-fit-identity.R`: the case-weights pair, the tailor present/absent pair, and three tailor pairs (type, argument, order), each asserting the class and the named part; a fixture results object saved at the branch point (`saveRDS` under `tests/testthat/fixtures/`) fitted against under the same workflow.
- [x] T2: Add `case_weights` and `postprocessor` parts to `workflow_identity()`, omitted when `NULL`; deparse the tailor as its adjustment list (class and arguments per adjustment, in order); `check_workflow_identity()` names the part.
- [x] T3: `tailor` to Suggests with a D-entry (extends the dependency set D-053 last touched); update `R/nested-final-fit.R` and `R/extract-procedure.R` roxygen; a NEWS bullet; a milestone-local decision naming and superseding M083's amendment-gate choice to hold AC1/AC2 narrow (records-hygiene §2).
- [ ] T4: `devtools::document()`, `devtools::test()`, `devtools::check()`, gating sweeps, `air format --check`.

## Work log

- 2026-09-16: created by /milestone-plan from the candidate row added 2026-09-11 (M083 gates).
- 2026-09-16: plan gate chose omitting absent parts (old records still match) over refusing pre-milestone records as an earlier version (D-041's shape) because no record is made wrong by the change; falsified by a pre-milestone record matching a workflow that now carries weights.
- 2026-09-16: implement gate: tailor to Suggests (D-065); the postprocessor part records the adjustments alone, never the tailor's derived `type`; the branch-point fixture and its generator live under `tests/testthat/fixtures/`.
- 2026-09-16: T1 done. `fixtures/branch-point-results.rds` generated at a0837b5 by `fixtures/make-branch-point-results.R` (the `fit_resamples_results()` recipe written out; 6.9 KB). Tests: the case-weights pair, the tailor present/absent pair, and the type, argument and order pairs, each asserting the mismatch class and the named part, in `test-workflow-identity.R` and `test-nested-final-fit-identity.R`; `custom_tailor()` joins the helpers. A recipe naming the predictors alone drops the weights column's role and fails every fold, so the weighted record's recipe names the column.
- 2026-09-16: T2 done. `workflow_identity()` appends `case_weights` (the column deparsed) and `postprocessor` (each adjustment's class and deparsed arguments, in order) when present; `identity_difference()` names a part present on one side only through `optional_part_difference()`, and `identity_part()` names the column, the adjustment count, an adjustment's type or an argument.
- 2026-09-16: T3 done. tailor in Suggests; the two help pages and the NEWS bullet say what the identity now compares; DESIGN Architecture's identity sentence names the two parts; D-065 and the milestone-local decision superseding M083's gate choice written. The roxygen sweep caught one semicolon and one 31-word sentence, both split.

## Decisions

- 2026-09-16: M083's return-gate choice to hold its AC1 and AC2 narrow (the identity reads the model and the preprocessor alone; case weights and the postprocessor filed as a candidate row) is superseded here: the identity reads both parts when the workflow carries them, and leaves them out when it does not, so the M083 promise stands for a workflow with neither and widens for one with either. The candidate row that carried the gap closes at this milestone's hygiene pass, its third item (what a function-valued step setting closes over) staying a candidate.

## Review
