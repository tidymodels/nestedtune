# M093: augment() refuses saved predictions that do not match what each fold held out

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP4, GP3
- **Resolves:** —
- **Surface tier:** user-facing — changes what `augment()` returns or refuses for a user's results object
- **Branch/PR:** —

## Goal

`augment()` on a nested run refuses a completed fold whose saved predictions do not hold exactly the rows that fold held out.

## Scope

**In:** Today a missing row gets a silent missing value, and a repeated row overwrites another. This milestone adds a check to `augment.nested_results()` in `R/nested-results-collect.R`. For each completed fold, the check compares `.predictions$.row` with the rows the fold held out. It refuses any mismatch with one class. The milestone also adds a test of that refusal on a set, and a test that `compute_metrics()` on a `nested_results_set` passes `event_level` on (M092 review finding 4). It updates the help page and the NEWS bullet. It absorbs the candidate row "`augment()` trusts each fold's `.predictions`" (M092 review findings 1, 3, 4).

**Out:**
- `compute_metrics()` trusts `.predictions` in the same way, so a repeated `.row` inside a fold counts twice. That goes to a new candidate row, added at this gate.
- Averaging the predictions of a repeated or Monte Carlo design stays with the `summarize = TRUE` candidate row (D-063).
- A warning with a count for a missing row, as tune's `merge_pred()` gives, was rejected at this gate (work log).

## Acceptance criteria

- [ ] AC1: The `.row` values in a completed fold's `.predictions` must be exactly the rows that fold held out, each once. If they are not, `augment()` on a `nested_results` refuses with class `nestedtune_augment_predictions`. The values are compared as whole numbers, so a double `.row` with the same values is accepted. A mismatch is one of five cases: a held-out row with no entry, a repeated `.row`, an `NA` `.row`, a `.row` the fold did not hold out, or no `.row` column. The check runs after the existing refusals for the design (`nestedtune_augment_rows`) and for unsaved predictions. It runs before the name-collision refusal, the join, and any warning. Its message names the labels of the fold. A test asserts the class for each of the five cases. At least one case is on a fold other than the first, and one is on a censored run whose `.pred` is a list column. One case is on a run with a failed fold, and there the test also asserts that no warning is raised and that the message holds the labels of the edited fold. The tests in `test-augment.R` at the start of this milestone pass without edits.
- [ ] AC2: On a `nested_results_set`, the refusal of AC1 keeps its class, and its message names the workflow. A test edits the `.predictions` of one workflow in a two-workflow set and asserts both.
- [ ] AC3: `compute_metrics()` on a `nested_results_set` scores each workflow at the `event_level` passed. If `event_level` is `NULL`, it scores each workflow at its recorded level. A test uses a set of two classification workflows and a metric set with `yardstick::mn_log_loss`. The test edits the recorded level of one workflow to `"second"` and leaves the other at `"first"`. With `expect_identical()`, it asserts that the table of the set at `"second"`, and at `NULL`, equals the stack under `wflow_id` of the own `compute_metrics()` call of each workflow with the same argument. It also asserts that the tables of the set at `"second"` and at `"first"` differ.
- [ ] AC4: The help page of `augment.nested_results()` names the class `nestedtune_augment_predictions`. It says that a fold whose saved predictions do not match the rows it held out raises that class. The `augment()` bullet in `NEWS.md` describes that refusal in words. `devtools::test()` passes. `devtools::check()` returns 0 errors and 0 warnings. Every gating prose sweep that `Rscript benchmarks/sweep-prose.R --list-gating` prints passes.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4

## Tasks

- [ ] T1: Write the AC1 tests first in `test-augment.R`. Plant each case by editing `res$.predictions[[i]]`, as `test-compute-metrics.R:92-96` edits a run. Then add a helper beside `check_held_out_once()`. For each completed fold, the helper compares `.predictions$.row` with `rsample::complement()` of the split. Call it after `check_column_saved()` (:645) and `check_held_out_once()` (:648). Call it before the name-collision check and `warn_partial_summary()` (:667). As a planted defect, turn off one part of the check at a time and see the matching test fail. Record the result in the work log. Run the earlier tests of the file without edits.
- [ ] T2: In `test-nested-workflow-map-readers.R`, edit one element of `kept_set_results()`. Assert the class and the workflow id in the message. `for_workflow()` (`R/nested-workflow-map.R:266-282`) signals errors again with the class kept, so no code change is expected. If the test fails, record the cause in the work log before you change code.
- [ ] T3: In `test-nested-workflow-map-readers.R`, build a two-workflow classification set from `cls_workflow()` and `cls_data()`. Use `skip_if_no_wset_fixture()`, the stochastic engine skip, and `memoised()`. Edit the recorded `event_level` of one element in its `procedure` attribute. Write the AC3 test. As a planted defect, make the set method drop `event_level` and see the test fail. Record the result in the work log.
- [ ] T4: Add a sentence to the "Designs and folds refused" section of the `augment.nested_results()` help. Update the `augment()` bullet at the top of `NEWS.md`. Run `devtools::document()`, `devtools::test()`, `devtools::check()`, and every gating sweep, with the roxygen `--plain` and `--spans` modes.

## Work log

- 2026-09-14: created by /milestone-plan, from the candidate row "`augment()` trusts each fold's `.predictions`" (M092 review findings 1, 3, 4).
- 2026-09-14: criteria audit ran in full mode with a fresh [O] reader, two passes. Pass one returned 10 findings on the warn-and-refuse draft, among them no tune 2.1.0 path to a short or repeated fold, and `roc_auc` giving one value at both levels. Pass two returned 10 findings on the refuse-only draft. The fixes set the order of the check, added the no-`.row` and double cases, added probes on a later fold, a censored run and a failed-fold run, and added an edited level for the `NULL` case.
- 2026-09-14: plan gate chose to refuse a fold whose predictions lack a held-out row over a warning with the count, as tune's `merge_pred()` gives. The audit found no tune 2.1.0 path to such a fold except an edit to the object, and GP3 prefers a refusal. Falsified by a tune version or a preprocessor that completes a fold with fewer predictions than held-out rows.

## Decisions
