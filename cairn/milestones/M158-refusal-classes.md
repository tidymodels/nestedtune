# M158: Give the unclassed refusals a class

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP3
- **Resolves:** —
- **Surface tier:** user-facing — users catch the new condition classes in their own code
- **Branch/PR:** m158-refusal-classes

## Goal

Every `cli::cli_abort()` call in `R/` carries a `nestedtune_` condition class, so a user can catch each refusal by class instead of by message.

## Scope

**In:** a `class` argument on the 26 `cli::cli_abort()` calls in `R/` that have none (19 in `R/checks.R`, 6 in `R/nested-resamples.R`, 1 in `R/tuner.R`; parse walk 2026-10-23). Classes are grouped by kind, as the existing ones are. Seven classes are new and three are reused:

| Calls | Function | Class |
|---|---|---|
| 4 | `check_workflow()` | `nestedtune_bad_workflow` (new) |
| 1 | `abort_bad_object()` | `nestedtune_bad_workflow` |
| 2 | `check_grid()` | `nestedtune_bad_grid` (new) |
| 4 | `check_grid_params()` | `nestedtune_bad_grid` |
| 2 | `eval_inside_spec()` | `nestedtune_bad_design` (existing) |
| 1 | `check_plot_type()` | `nestedtune_bad_type` (existing) |
| 1 | `check_metrics()` | `nestedtune_bad_metrics` (existing) |
| 1 | `check_param_info()` | `nestedtune_bad_param_info` (new) |
| 2 | `check_eval_time()` | `nestedtune_bad_eval_time` (new) |
| 1 | `check_event_level()` | `nestedtune_bad_event_level` (new) |
| 1 | `nested_resamples()`, the `data` refusal | `nestedtune_bad_data` (new) |
| 3 | `nested_resamples()`, the `outside` and `inside` refusals | `nestedtune_bad_design` |
| 1 | `inner_resamples_from_split()` | `nestedtune_bad_design` |
| 1 | `eval_spec()` | `nestedtune_bad_design` |
| 1 | `tuner_entry()`, an internal error | `nestedtune_unknown_tuner` (new) |

Tests that now assert `rlang_error` for one of these refusals (for example `test-eval-time.R`, `test-event-level.R`, `test-model-spec-input.R`, `test-nested-tune-grid-checks.R`) assert the new class. One NEWS bullet.

**Out:**
- Message text. No refusal's wording changes, so no snapshot changes.
- Refusals raised by rlang's own helpers (4 `rlang::arg_match()`, 12 `rlang::check_required()`, 51 `rlang::check_dots_empty()` calls in `R/`) keep rlang's conditions. The candidate row named the package's own calls only. Not planned, no row.
- A help page that lists condition classes. None of the existing 63 classes is listed on one. Not planned, no row.
- A committed test that parses `R/` for unclassed calls. Review runs the parse walk instead (work log).

## Acceptance criteria

- [x] AC1: Each of the 26 refusals in the Scope table, when triggered, raises a condition that inherits from the class its table row assigns. A test triggers each of the 26 and asserts that class and a fragment of the refusal's headline (its first message element) that no other refusal raised under the same class contains.
- [x] AC2: A parse walk with `getParseData()` over every file in `R/` finds no `cli::cli_abort()` call without a `class` argument.
- [x] AC3: For every file in `R/`, the branch's code parsed with `parse(keep.source = FALSE)`, with the `class` argument removed from the 26 calls, is identical to the parsed code at `git merge-base main HEAD`. So no message text and no other code changes.
- [x] AC4: `NEWS.md` has one new bullet under its development heading that names the seven new classes and says which refusals now carry `nestedtune_bad_design`, `nestedtune_bad_type` and `nestedtune_bad_metrics`.
- [x] AC5: The profile's `verify` slot is clean, and `devtools::check()` reports 0 errors, 0 warnings, and no NOTE that `devtools::check()` at `git merge-base main HEAD` does not also report.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2, T3
- AC3 → T1, T2, T3
- AC4 → T3
- AC5 → T3

## Tasks

- [x] T1: Tests first, then code, for the 19 calls in `R/checks.R`. For each refusal, add or tighten an `expect_error(..., class = , regexp = )` in the `*-checks.R` or topic test file that already covers it (new tests go in the file of the public function that reaches the check). See each new test fail, then add the `class` argument from the Scope table.
- [x] T2: The same for the 6 calls in `R/nested-resamples.R` (tests in `test-nested-resamples-specs.R` or the file that already covers the refusal) and the 1 in `R/tuner.R` (tighten `test-tuner-registry.R`'s "Unknown tuner" expectations).
- [x] T3: Add the NEWS bullet. Run the parse walk over `R/`, and a walk that compares each `R/` file's parse tree with the merge base's after removing `class` from the calls that had none there. Run `verify` and `devtools::check()` from the main checkout, and `check()` at the merge base if the branch reports a NOTE.

## Work log

- 2026-10-23: created by /milestone-plan.
- 2026-10-23: tier check: not run — work named at the question set.
- 2026-10-23: idea vet: no concern. Classes follow the existing kind-grouped names. The `tuner_entry()` call is an internal error, not a user refusal; it gets a class because the user chose all 26.
- 2026-10-23: question set: which candidate to plan — "Give the unclassed refusals a class"; class grouping — one class per kind; scope — all 26 calls, not only the 19 in `R/checks.R`.
- 2026-10-23: collision check: absorbs the candidate row "Give the unclassed refusals a class". No D-entry or archived milestone covers condition classes for these calls. Inbox: 1 open issue (#91, docs pass, no overlap), 0 open PRs.
- 2026-10-23: plan chose `nestedtune_bad_grid` for all four `check_grid_params()` refusals over `nestedtune_workflow_mismatch` for the two that name `object`, because DESIGN.md describes that class as the identity check's alone and the final fit's marker check has its own class; falsified by a user catching `nestedtune_workflow_mismatch` who expects those two among them.
- 2026-10-23: criteria audit (full mode, fresh Opus reader): counts and attributions confirmed, all 26 refusals reachable. Fixed: AC1 assigned a class per function where two functions take two classes (now per table row); AC1's message fragment could match a sibling refusal or a parent condition's text (now a headline fragment unique within its class), and its "so a test fails" clause claimed a suite property no procedure checks (dropped); AC3 compared against a moving `main` (now the merge base); AC5's "0 notes" was stricter than the profile and over notes the milestone cannot control (now no NOTE the merge base lacks). Answered: `nestedtune_workflow_mismatch` would leave DESIGN.md's description incomplete (switched to `nestedtune_bad_grid`); `nestedtune_unknown_tuner` labels an internal error (kept, user's choice of all 26); the "built on different data" refusal keeps `nestedtune_bad_design`, since it refuses the `outside` design argument. AC2 and AC4 had no finding.
- 2026-10-23: implement: branch `m158-refusal-classes` cut from 67aa0b3a; status in-progress.
- 2026-10-23: T1 checkpoint: 19 `class` arguments added in `R/checks.R`; class assertions added or tightened in seven test files. Before the code change 18 edited blocks failed or errored, and after it they pass. The cont_workflow final-fit case reaches the "does not tune" refusal, so a new workflow tuning `num_comp` and `threshold` triggers the "recorded grid has no column" one. Full-suite verify still running; T1 not yet ticked.
- 2026-10-23: T1 verified: `devtools::test()` 1152 blocks, 0 failed; `air format --check .` and `sweep-prose.R --plain` clean.
- 2026-10-23: T2: 7 `class` arguments in `R/nested-resamples.R` and `R/tuner.R`; seven blocks in three test files red before, green after (20 blocks, 0 red). Four `cli_abort(c(...))` calls there took the file's existing multi-line form to carry `class`.
- 2026-10-23: T3 in progress: NEWS bullet added. The AC3 walk (scratchpad script comparing each `R/` file's parse tree with the merge base after removing `class` from `cli_abort()` calls) first failed on `R/nested-resamples.R`: re-indenting two calls had shifted the continuation whitespace inside four string literals, which cli trims but the parse tree keeps. Restored; the walk then reported 25 files, 26 classes added, no other change and no existing class altered.
- 2026-10-23: T3 verified at 3453ac96: `sweep-prose.R --plain` clean; `devtools::test()` 1152 blocks, 0 failed; `devtools::check()` 0 errors, 0 warnings, 0 notes (10m 38s). Claim audit spawned.
- 2026-10-23: claim audit: 21 claims read, 2 corrected — NEWS.md (the `param_info`/`eval_time`/`event_level` sentence implied every refusal of those arguments carries the new classes, where `autoplot()` uses `nestedtune_bad_plot_filter` and `nested_fit_resamples()` and `compute_metrics()` also raise them; the grid sentence omitted "neither a data frame"). The re-read confirmed both, adding `nested_fit_resamples()`.
- 2026-10-23: implement complete; status review.
- 2026-10-23: plan chose the review-time parse walk over a committed test that parses `R/`, because such a test reads source text rather than behavior and AC1's tests pin each class; falsified by a new unclassed `cli_abort()` reaching main.
- 2026-10-23: review: 4-lens fan-out at ab3d2dc1, 23 findings (7 fixed at 24ce0fe5, 15 rejected, 1 noted, 0 follow-up); no return.
- 2026-10-23: step-7 approval: m158-refusal-classes approved for merge

## Decisions

## Review

Evidence at 493c5357 (branch head; main unmoved at 67aa0b3a), 2026-10-23.

- AC1: mutation run, branch tests over the merge base's `R/` (scratchpad copy): 40 expectations red across 10 test files, covering 23 of the 26 refusals; the other 3 (the whole-number grid refusal and the two recorded-grid refusals) sit behind an earlier error in their blocks, so a second copy of HEAD's `R/` with only those three `class` lines removed turned exactly those 3 red. Fragment check: each of the 27 test fragments matches exactly one of the 136 classed headlines read from `R/` under its own class (the `eval_spec()` fragment checked by grep, 1 site); the 3 `nestedtune_bad_design` headlines built at run time hold none of the fragments, which grep finds nowhere else in `R/`.
- AC2: parse walk over all 25 files in `R/`: 0 `cli_abort()` calls without `class` (26 before, at the merge base).
- AC3: parse-tree walk against `git merge-base main HEAD` (67aa0b3a): 25 files, code identical after removing the 26 added `class` arguments, every class the merge base had unchanged.
- AC4: `git diff main -- NEWS.md` adds one bullet, the first under `# nestedtune 0.0.0.9000`. It names each of the seven new classes with the refusals that carry it, and says which refusals now carry `nestedtune_bad_design`, `nestedtune_bad_type` and `nestedtune_bad_metrics` (read in place; lines reflowed at review with no word changed).

Independent review at ab3d2dc1. spawned: diff-bug, blame-history, prior-review, ripple.

- diff-bug #1: the two final-fit refusals that name `object` carry `nestedtune_bad_grid`, so a caller catching `nestedtune_workflow_mismatch` misses them, and the NEWS line leads with a `grid` argument `nested_final_fit()` lacks — reject (planned change: the plan chose `bad_grid` over `workflow_mismatch`, work log); the NEWS wording is fixed with ripple #3.
- diff-bug #2: `eval_spec()` and `eval_inside_spec()` rethrow any evaluation error, rsample's zero-row refusal included, as `nestedtune_bad_design` — reject (planned change: the Scope table assigns `bad_design` to both; the cause stays in the condition's `parent`).
- diff-bug #3: a bad workflow-set element raises `nestedtune_bad_workflow`, not `nestedtune_bad_workflow_set`, and NEWS does not name that path — reject (planned change: `check_workflow()` gets `bad_workflow` wherever it runs, and the set's own refusals keep their class).
- diff-bug #4: `nestedtune_unknown_tuner` gives an internal error a public-looking class — reject (planned change: the user chose all 26 at the question set); the NEWS wording is fixed with blame-history #1.
- diff-bug #5: NEWS says `nested_fit_resamples()` and `compute_metrics()` raise the new classes, and no test asserts it — fix now: `test-nested-fit-resamples-checks.R` and `test-compute-metrics.R` assert the classes.
- diff-bug #6: the `eval_spec()` class assertion sat inside the message-size block — fix now: its own block in `test-nested-resamples-specs.R`.
- diff-bug #7: two added test comments narrate what the code shows — fix now for `test-eval-time.R` (comment removed); reject for `test-nested-final-fit-checks.R` (false: it states the recorded grid's columns, which the block does not show).
- diff-bug #8: the text-only `grid = -1`, `2.5`, `c(1, 2)` and plot `type` expectations repeat the new exact one — reject (false: each input reaches a different clause of the refusal's condition, `R/checks.R` `check_grid()` and the plot type's `x` bullet).
- diff-bug #9: the NEWS sub-list uses `-` where older nested lists use `*` — reject (style).
- blame-history #1: an unknown tuner name in a hand-altered record reaches `tuner_entry()`, and NEWS called the class a bug report — fix now: NEWS says "an internal error for a tuner name that nestedtune does not know"; the reachability predates this diff and DESIGN.md Known issues covers hand-altered records.
- blame-history #2: `test-nested-fit-resamples-checks.R` still asserted `rlang_error` for the metrics refusal and message only for event_level and eval_time — fix now (as diff-bug #5).
- blame-history #3: no past decision explains why these refusals were unclassed — reject (false as a defect: nothing to reverse).
- blame-history #4: M157 chose `rlang_error` for the no-preprocessor block a day earlier — reject (planned change: that refusal now has a class).
- blame-history #5: the recorded-grid refusals take `bad_grid`, not `workflow_mismatch` — reject (planned change, as diff-bug #1).
- blame-history #6: the `outside` "not an rset" and `inside` "must be an expression" refusals are argument-shape checks under `bad_design` — reject (planned change: Scope table).
- prior-review #1: M157's archive says it fixed "the no-preprocessor class" while main had none — reject (false: that line records the test's `rlang_error` assertion; archives are history).
- prior-review #2: the candidate row "Fix seed checks in four refusal tests" names a `test-event-level.R` block this diff leaves alone — reject (false as a regression: the row stays open).
- prior-review #3: DESIGN.md lines on unclassed errors — reject (false: they describe raw base R and vctrs errors on paths this diff does not touch).
- prior-review #4: the M053 Known issues entry on `.completed` errors still stands — reject (false: path untouched).
- prior-review #5: names match the `nestedtune_bad_<arg>` pattern — noted, requests nothing.
- ripple #1: the candidate row "Give the unclassed refusals a class" goes stale at merge — reject (planned change: post-merge hygiene graduates it).
- ripple #2: `test-nested-fit-resamples-checks.R:71` asserts `rlang_error` — fix now (as diff-bug #5).
- ripple #3: NEWS "does not match the recorded grid" reads like the identity mismatch — fix now: "tunes other parameters than the recorded grid holds".
- gate: `devtools::document()` changed only `Config/roxygen2/version` 8.1.0 to 8.1.1, from the local roxygen2 8.1.1; reverted, no `man/` or `NAMESPACE` change.
- gate: the full suite run at ab3d2dc1 overlapped the mutation runs and two other R sessions, and up to 17 parallel-daemon blocks failed; rerun alone on the final head below.
- AC5 (at 24ce0fe5, run alone): `devtools::test()` 1153 blocks, 0 failed, 0 skipped; `air format --check .` clean; `sweep-prose.R --plain` clean; `devtools::check()` 0 errors, 0 warnings, 0 notes (7m 0s), so no NOTE to compare with the merge base.
- gate: `cairn_validate.py` all checks passed (18 advisories, reference-page staleness only); `devtools::document()` no `man/` or `NAMESPACE` diff; `pkgdown::check_pkgdown()` no problems; all six gating prose sweeps clean (at ab3d2dc1; the later commit changes tests and NEWS only); README untouched; no new top-level file; NEWS.md entry present. Snapshots: no `_snaps` file in `git diff --name-only main...HEAD`. Open-PR read: 0 open PRs by the operator, under the feature cap of 1.
