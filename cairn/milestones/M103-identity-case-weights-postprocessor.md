# M103: The workflow identity reads case weights and a postprocessor

- **Status:** review
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

- [x] AC1: Two workflows differing only in their case-weights column (`workflows::add_case_weights()`) have different `workflow_identity()` values, and `nested_final_fit()` on a record built from one refuses the other with class `nestedtune_workflow_mismatch` naming the case-weights part; the same holds for a workflow with and without a tailor postprocessor, and for two tailors differing in adjustment type, in one adjustment's argument value, or in adjustment order.
- [x] AC2: `workflow_identity()` of a workflow with neither case weights nor a postprocessor is `identical()` to its value at the branch point, so a record saved before this milestone is accepted by `nested_final_fit()` under the workflow it ran under.
- [x] AC3: `tailor` is in `Suggests`, and the help text in `?nested_final_fit` and `?extract_procedure` listing what the identity does not compare no longer names case weights or a postprocessor.
- [x] AC4: `devtools::test()` clean, `devtools::check()` at 0 errors, 0 warnings, 0 notes, and every sweep `--list-gating` names runs clean.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T3
- AC4 → T4

## Tasks

- [x] T1: Tests first in `test-workflow-identity.R` and `test-nested-final-fit-identity.R`: the case-weights pair, the tailor present/absent pair, and three tailor pairs (type, argument, order), each asserting the class and the named part; a fixture results object saved at the branch point (`saveRDS` under `tests/testthat/fixtures/`) fitted against under the same workflow.
- [x] T2: Add `case_weights` and `postprocessor` parts to `workflow_identity()`, omitted when `NULL`; deparse the tailor as its adjustment list (class and arguments per adjustment, in order); `check_workflow_identity()` names the part.
- [x] T3: `tailor` to Suggests with a D-entry (extends the dependency set D-053 last touched); update `R/nested-final-fit.R` and `R/extract-procedure.R` roxygen; a NEWS bullet; a milestone-local decision naming and superseding M083's amendment-gate choice to hold AC1/AC2 narrow (records-hygiene §2).
- [x] T4: `devtools::document()`, `devtools::test()`, `devtools::check()`, gating sweeps, `air format --check`.

## Work log

- 2026-09-16: created by /milestone-plan from the candidate row added 2026-09-11 (M083 gates).
- 2026-09-16: plan gate chose omitting absent parts (old records still match) over refusing pre-milestone records as an earlier version (D-041's shape) because no record is made wrong by the change; falsified by a pre-milestone record matching a workflow that now carries weights.
- 2026-09-16: implement gate: tailor to Suggests (D-065); the postprocessor part records the adjustments alone, never the tailor's derived `type`; the branch-point fixture and its generator live under `tests/testthat/fixtures/`.
- 2026-09-16: T1 done. `fixtures/branch-point-results.rds` generated at a0837b5 by `fixtures/make-branch-point-results.R` (the `fit_resamples_results()` recipe written out; 6.9 KB). Tests: the case-weights pair, the tailor present/absent pair, and the type, argument and order pairs, each asserting the mismatch class and the named part, in `test-workflow-identity.R` and `test-nested-final-fit-identity.R`; `custom_tailor()` joins the helpers. A recipe naming the predictors alone drops the weights column's role and fails every fold, so the weighted record's recipe names the column.
- 2026-09-16: T2 done. `workflow_identity()` appends `case_weights` (the column deparsed) and `postprocessor` (each adjustment's class and deparsed arguments, in order) when present; `identity_difference()` names a part present on one side only through `optional_part_difference()`, and `identity_part()` names the column, the adjustment count, an adjustment's type or an argument.
- 2026-09-16: T3 done. tailor in Suggests; the two help pages and the NEWS bullet say what the identity now compares; DESIGN Architecture's identity sentence names the two parts; D-065 and the milestone-local decision superseding M083's gate choice written. The roxygen sweep caught one semicolon and one 31-word sentence, both split.
- 2026-09-16: T4 done. `document()` no diff, `devtools::test()` clean, `devtools::check()` 0 errors, 0 warnings, 0 notes (12m 53s), the six gating sweeps clean, `air format --check` clean.
- 2026-09-16: claim audit: 31 claims read, 2 corrected — R/workflow-identity.R, tests/testthat/test-workflow-identity.R (the tailor's `type` is set by its adjustments at construction and by the outcome column at fitting, not by the model's mode; `requires_fit` added to the unrecorded fields; both re-read correct).
- 2026-09-16: all tasks checked; status review.

## Decisions

- 2026-09-16: M083's return-gate choice to hold its AC1 and AC2 narrow (the identity reads the model and the preprocessor alone; case weights and the postprocessor filed as a candidate row) is superseded here: the identity reads both parts when the workflow carries them, and leaves them out when it does not, so the M083 promise stands for a workflow with neither and widens for one with either. The candidate row that carried the gap closes at this milestone's hygiene pass, its third item (what a function-valued step setting closes over) staying a candidate.

## Review

- 2026-09-16, pass 1. Branch at `674e451`, two commits past `a0837b5`; `origin/main` unchanged since the branch point, no PR yet.
- AC1: `devtools::test()` clean (10516 passes, 0 skips, so the tailor tests ran). The suite's M103 blocks assert `nestedtune_workflow_mismatch` and the named part for the case-weights pair (another column, none against one, one against none), the tailor present/absent pair, and the type, argument and order pairs (`test-nested-final-fit-identity.R`, `test-workflow-identity.R`). Verified.
- AC2: a review-side probe rebuilt the fixture's workflow and found `workflow_identity()` `identical()` to the record in `fixtures/branch-point-results.rds`, whose names are `model`, `preprocessor`; `a0837b5` is the merge base. The suite's AC2 blocks fit against that fixture. Verified.
- AC3: `tailor` at DESCRIPTION Suggests; `man/nested_final_fit.Rd` and `man/extract_procedure.Rd` name the case-weights column and the tailor's adjustments as compared, and no "not held"/"does not read" sentence remains. Verified.
- AC4: `devtools::check()` 0 errors, 0 warnings, 0 notes (16m 55s); the six `--list-gating` sweeps clean. Verified.
- Consistency gate: `cairn_validate.py` exit 0 (18 references-staleness advisories, pre-existing); no principle text changed, `cairn_impact` skipped; `document()` no diff; `air format --check` clean; `pkgdown::check_pkgdown()` no problems; README untouched; NEWS bullet present; no new top-level file. Pass.
- Independent review: [S] blame-history, no findings (M083's exclusion is superseded by a recorded milestone decision, D-041's shape was rejected at the plan gate, the string-leaf invariant and the earlier-version refusal hold). [S] prior-review, no regression (the M083 findings on cli interpolation, quosure deparse and engine-argument order all still guarded; PR #97 carried no inline comments). [O] diff-bug, six findings, none failing a criterion, ranked:
  1. `R/checks.R` `optional_part_difference()`'s fallback sentence ("a part the comparison cannot name") is fired by no test, unlike `identity_difference()`'s own fallback.
  2. When both optional parts differ in presence, only the case weights are named; the postprocessor difference goes unmentioned.
  3. Two branches of `identity_part()`'s postprocessor arm look unreachable from any tailor a constructor builds (the plural "arguments" sentence and the switch default).
  4. `as.integer(at(3L))` assumes an unnamed `adjustments` list; a named one would error inside the mismatch message. Same shape as `step_identity()`'s.
  5. Both passing controls mock `final_fit_worker`, so no test refits a weighted or tailored workflow through `nested_final_fit()` unmocked.
  6. A data-frame adjustment argument would deparse whole, rows included, as recipe step settings already can; no current tailor adjustment takes one.
- Triage at the gate (2026-09-16): finding 1 fixed now, a test in `test-workflow-identity.R` firing the fallback sentence on a names-only difference in neither optional part (60 passes in the file, `air` clean). Findings 2-6 rejected: 2 is the milestone's Out scope (naming the part, never diffing beyond it); 3, 4 and 6 are latent under every tailor a constructor builds and match how recipe steps are already recorded, so they are not this diff's defect; 5 is outside AC1, which names the refusal, and the suite fits weighted and tailored workflows through `nested_fit_resamples()`.
- step-7 approval: m103-identity-case-weights-postprocessor approved for merge (2026-09-16).

