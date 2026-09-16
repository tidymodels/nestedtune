# M098: The summary and final-fit prints name a non-default selection rule

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP4
- **Resolves:** —
- **Surface tier:** user-facing — printed output and help pages of exported methods
- **Branch/PR:** `m098-selection-rule-printed`

## Goal

If a run selected each fold's candidate by a rule other than the default best-by-metric rule, the results summary and the final fit's print and summary name that rule.

## Scope

**In:** One shared label for a `selection_rule` in `R/selection-rule.R`. A `select` component on `summary.nested_results` and `summary.nested_final_fit`. One "Selected by:" line under the selected-parameters heading of `print.summary.nested_results`, `print.nested_final_fit` and `print.summary.nested_final_fit`. The set's summary print reuses the first of those. The line shows only when the recorded rule is `"one_std_err"` or `"pct_loss"`. The four help pages and a NEWS bullet.

**Out:** The line on `print.nested_results`, which describes the object and points at `summary()`. The plan gate declined it on 2026-09-15. Naming the rule always, the default included. The gate declined it because the line's presence is the signal, as with the fold-failure and candidate-set lines. A prose rendering of each rule's name, declined because one helper renders the rule's print and these lines. A set-level `select` component, because a set's summary is a list of per-workflow summaries with no top-level components.

## Acceptance criteria

- [ ] AC1: Take a `nested_results` whose recorded rule is `"one_std_err"` or `"pct_loss"`. Printing `summary(res)` shows one line directly under the "Selected parameters" heading. The line reads `Selected by: <label>`. The label is the rule name, then ` by ` and the orderings as written, then ` (limit = <limit>)` for `"pct_loss"`. Examples: `one_std_err by num_comp` and `pct_loss by desc(df1), df2 (limit = 5)`. The line prints whether or not any fold completed. On a record whose rule is `"best"`, and on a `nested_fit_resamples()` record, no `Selected by:` line prints. Snapshot tests in `test-nested-results-print.R` cover seven cases. They are `"one_std_err"` with one ordering, `"one_std_err"` with two, `"pct_loss"` at the default limit, `"pct_loss"` at an explicit limit, a `"one_std_err"` run in which no fold completed, `"best"`, and `nested_fit_resamples()`.
- [ ] AC2: `summary(res)` and `summary(final)` each return a list whose names include `select`. That entry holds the rule from the object's procedure record, `extract_procedure(x)$select`. If the record holds no rule, the entry is `NULL`. Tests in the two print test files assert `identical(s[["select"]], extract_procedure(x)$select)` for a `"one_std_err"` run and a `"best"` run. They assert `"select" %in% names(s)` and `is.null(s[["select"]])` for a `nested_fit_resamples()` run. Both objects are covered.
- [ ] AC3: Take a `nested_final_fit` whose rule is `"one_std_err"` or `"pct_loss"`. `print(final)` shows the AC1 line directly after its `Selected:` line. `print(summary(final))` shows it directly under its "Selected parameters" heading. The same helper as AC1 renders the label. On `"best"`, and on a fit that tuned nothing, neither print shows a `Selected by:` line. Snapshot tests in `test-nested-final-fit-print.R` cover four cases on each of the two prints. They are `"one_std_err"` with two orderings, `"pct_loss"` at an explicit limit, `"best"`, and a fit that tuned nothing.
- [ ] AC4: Take a `nested_results_set` run under `"one_std_err"`. `print(summary(set))` shows the AC1 line inside each tuned workflow's section and none inside a fixed workflow's section. Under the default rule it shows none. A snapshot test in `test-nested-results-print.R` on a set holding one tuned and one fixed workflow covers both rules.
- [ ] AC5: Take a run under the default rule, and a `nested_fit_resamples()` run. Every line `print()` and `summary()` print for them is unchanged from the branch point. The snapshot blocks for those runs in `_snaps/nested-results-print.md` and `_snaps/nested-final-fit-print.md` pass without re-acceptance.
- [ ] AC6: The help pages for `summary.nested_results()`, `print.nested_final_fit()` and `summary.nested_final_fit()` each describe the `Selected by:` line and the `select` component. The page for `summary.nested_results_set()` describes the line. A `NEWS.md` bullet names the change. The page for `selection_rule()` names the label its print and these lines share.

## Coverage

- AC1 → T2
- AC2 → T2, T3
- AC3 → T3
- AC4 → T2
- AC5 → T2, T3, T4
- AC6 → T4

## Tasks

- [x] T1: Add `selection_rule_label(x)` to `R/selection-rule.R` to render the AC1 label. Make `format.selection_rule()` (line 174) return `paste0("<selection_rule> ", selection_rule_label(x))`. Add unit tests in `test-selection-rule.R` for the four label shapes (no ordering, one, two, with limit). The existing `_snaps/selection-rule.md` blocks must pass unchanged.
- [x] T2: In `new_summary_nested_results()` (`R/nested-results-print.R`) add `select = attr(x, "procedure")$select` as a named entry that stays present when `NULL`. If the rule is non-default, `print_selection()` prints `Selected by: {label}` after the heading and before its early returns. Add the snapshot and identity tests for AC1, AC2 (results side) and AC4. The set case reuses the mixed fixture the set summary tests at `test-nested-results-print.R:1016` build. Verify with `devtools::test()`.
- [x] T3: In `new_summary_nested_final_fit()` (`R/nested-final-fit-print.R`) add the `select` entry from `x$procedure$select`. In `print.nested_final_fit()` add the line after `Selected:`, and in `print_final_selection()` under its heading, both read from the summary's component. Add the snapshot and identity tests for AC2 (fit side) and AC3. Update the component-list assertions in `test-nested-final-fit-print.R` that enumerate the summary's names. Verify with `devtools::test()`.
- [x] T4: Write the help text on the four pages and on `selection_rule()`'s page, and the NEWS bullet. Run `devtools::document()` until it leaves no diff. Run `Rscript benchmarks/sweep-prose.R --plain` and `--roxygen --plain` clean, and `air format --check` on touched files. Read the `_snaps/` diff and make sure that it holds only added blocks (AC5). Run the full `devtools::test()`.

## Work log

- 2026-09-15: created by /milestone-plan from the M69 candidate row ("Name the selection rule in `summary()` and the final fit's print", the item D-056 deferred).
- 2026-09-15: criteria audit ran in full mode ([O] reader) and returned seven findings, all disposed. Set sections are scoped to tuned workflows. `select` partial-matching `selection` is pinned by `[["select"]]` and name presence. The snapshot-diff criterion is restated as a deliverable property, the diff read moved to T4. One shared label helper carries pinned wording. The set help documents the line only. Probes widened over orderings, limit and the no-fold-completed branch.
- 2026-09-15: plan gate chose printing the line only under a non-default rule over always printing it. The existing prints make a line's presence the signal, and the default run's snapshots stay unchanged. Falsified by a reader misreading a default run as unrecorded.
- 2026-09-15: plan gate chose printing the line on a run in which no fold completed over omitting it. The rule describes the procedure asked for, not what completed (IP4). Falsified by a reader taking the line as a claim that a selection happened.
- 2026-09-15: plan gate chose leaving `print.nested_results` without the line over adding it because that print describes the object and defers meaning to `summary()`. Falsified by users reading `.selected` off the print without reaching `summary()`.
- 2026-09-15: plan gate chose the `Selected by: one_std_err by num_comp` form over a prose rendering. One helper then serves the rule's own print and these lines. Falsified by readers not recognizing the rule names as tune's selectors.
- 2026-09-16: /milestone-implement started. Branch `m098-selection-rule-printed` cut from pushed `main` at `452b015`. No question gate. The plan fixed the label wording, the helper name and the line's placement.
- 2026-09-16: T1 done. `selection_rule_label()` renders the label and `format.selection_rule()` reads it. `names_selection_rule()` answers whether a record's rule is one the summaries name, which is a non-default rule and not `NULL`. Label tests cover the four shapes and the default limit. `_snaps/selection-rule.md` is unchanged.
- 2026-09-16: T2 done. The results summary carries `select` and `print_selected_by()` prints the line under the heading, ahead of the early returns. Tests add the seven AC1 snapshots, the AC2 identity tests and the AC4 set snapshots on a `wset_two()` run. The set fixture takes `select` through the map's dots, which reach the tuned workflow alone. The snapshot diff holds 247 added lines and no removed line. Full `devtools::test()` clean.
- 2026-09-16: T3 done. The final-fit summary carries `select` after `selection`, and both prints read the line from that component. Tests add the fit-side AC2 identity tests, the AC3 placement tests on both prints, and eight snapshots over the four cases. The hand-agreed M46 print text is unchanged, as the default rule prints no line. The snapshot diff holds 195 added lines and no removed line. Full `devtools::test()` clean.
- 2026-09-16: T4 done. The five help pages describe the line and the `select` component, and NEWS carries the bullet. `devtools::document()` leaves no diff, both prose sweeps clean, `air format --check` clean. The `_snaps/` diff against `main` holds added blocks only (AC5). Full `devtools::test()` clean.
- 2026-09-16: claim audit: 28 claims read, 1 corrected — NEWS.md, R/nested-final-fit-print.R, R/nested-results-print.R and their man pages. The line carries the rule's label without the `<selection_rule>` tag, so "as `selection_rule()` prints it" became "in the words the print of `selection_rule()` uses after its class tag" at four sites. The reader re-read the four once and cleared them.
- 2026-09-16: all tasks done and verify clean. Status set to `review`.

## Decisions

## Review
