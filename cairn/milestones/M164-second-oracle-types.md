# M164: Give six one-type results a second oracle

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP2
- **Resolves:** —
- **Surface tier:** internal — tests and in-repo tracking records; no package code or user doc changes
- **Branch/PR:** m164-second-oracle-types

## Goal

Back each of the six `cairn/ORACLES.md` groups whose result is its own and that rests on one oracle type with a test of a second, independent type.

## Scope

**In:** one new test per result for the selection rules, the racing and annealing final fits, `nested_workflow_map()`, the splits `nested_resamples()` builds, and each fold's outer-fit predictions and extracts. A source note for tune's three selector help pages, which AC1's test rests on. The registry rows for the new oracles. One line in each of the three groups that restate stored tables (wide metric tables, fold labels, rows `augment()` joins) saying which group checks their numbers, and a D-entry recording that such a table owes no second type.

**Out:** the finer one-type results that M163's review found (`compute_metrics()` own vs new metric set, final fit under `eval_time` and `event_level`, failed-fold weights, race fold record, Bayesian and annealing iteration stage, memory slope, `hand_average()`-only cases), and the selection group's desirability rule and recorded selection metric, which keep one type → the candidate row "Give finer results a second oracle". Pointing the 21 test-file headers at the registry → its parked row. No change to package code.

## Acceptance criteria

- [x] AC1: `test-nested-tune-grid-oracles.R` gains a test whose expected selections are computed by explicit code from the definitions in tune's help pages for `select_best()`, `select_by_one_std_err()` and `select_by_pct_loss()`, on each fold's inner metrics of one grid run, and it asserts that the fold's recorded selection under each of the three rules equals that computed candidate.
- [x] AC2: `test-nested-final-fit-race.R` and `test-nested-final-fit-sim-anneal.R` each gain a test on the suite's deterministic fixture that asserts the final fit's predictions on the data equal those of the workflow finalized by hand on the candidate that the recorded rule picks from the final fit's own tuning run (`extract_tune_results()`) and fit by hand on the same data.
- [x] AC3: `test-nested-workflow-map-oracles.R` gains a test asserting that the map's element for a workflow routed to `nested_tune_grid()` matches `reference_nested_loop()` on that workflow in each fold's selected parameters and outer metrics.
- [x] AC4: `test-nested-resamples-identity.R` gains a test on a `nested_resamples()` v-fold outer / v-fold inner design over data with a row-id column that asserts, for every outer split, that every inner analysis and assessment row is a row of the outer analysis set, and that the inner assessment sets hold each outer analysis row exactly once.
- [x] AC5: `test-nested-tune-grid-results.R` gains a test on a grid run under `save_pred = TRUE` with an `extract` that returns the fitted workflow, asserting that each fold's saved predictions equal `predict()` of that fold's extracted workflow on the fold's outer assessment rows.
- [x] AC6: `cairn/ORACLES.md` holds one oracle row for each of the six tests AC1 to AC5 add (AC2 adds two), with id, type, source and its test quoted by name, in its group; the headings of the six groups (selection rules and the selection metric, the racing final fit, the annealing final fit, `nested_workflow_map()`, the splits `nested_resamples()` builds, each fold's outer-fit predictions and extracts) each state two types; each of the three table groups (wide metric tables, fold labels, rows `augment()` joins) carries one line that names at least one group whose oracles check numbers it restates, or says it holds no number; and a new `cairn/DECISIONS.md` entry records that such a table owes no second oracle type.
- [x] AC7: `devtools::test()` reports no failures, and `air format --check .` is clean.

## Coverage

- AC1 → T1
- AC2 → T2, T3
- AC3 → T4
- AC4 → T5
- AC5 → T6
- AC6 → T7
- AC7 → T8

## Tasks

- [x] T1: Selection rules, closed-form. Read `?tune::select_best`, `?tune::select_by_one_std_err` and `?tune::select_by_pct_loss` in the installed tune and write the source note (`cairn/references/`, with its `INDEX.md` line and the tune version). In `test-nested-tune-grid-oracles.R` (beside the test at :307), recompute each rule's pick from a fold's `.inner_metrics` with plain code and compare with the recorded `.selected`. Pick a fixture where the three rules pick different candidates on at least one fold, so the test can tell them apart. Plant a swapped rule and see the test fail.
- [x] T2: Racing final fit, invariant. In `test-nested-final-fit-race.R`, on the deterministic race fixture (`skip_if_no_race_fixture()`, no `stochastic`), select from `extract_tune_results()` by the recorded rule, `finalize_workflow()`, `fit()` on the same data, and compare predictions with the final fit's. Plant a wrong candidate and see it fail.
- [x] T3: Annealing final fit, invariant. The same in `test-nested-final-fit-sim-anneal.R` on the deterministic annealing fixture.
- [x] T4: `nested_workflow_map()`, live. In `test-nested-workflow-map-oracles.R`, compare the grid element with `reference_nested_loop()` (helper-orchestration.R:163) under the same seed. Plant a perturbed seed and see it fail.
- [x] T5: Splits, invariant. In `test-nested-resamples-identity.R`, map each inner split back through a row-id column and check containment and the exactly-once cover. Plant a dropped row and see it fail.
- [x] T6: Outer-fit predictions, invariant. In `test-nested-tune-grid-results.R`, run with an `extract` that returns the fitted workflow, built over `baseenv()` so the fixture cache keys it, and compare each fold's `.predictions` with `predict()` on the outer assessment rows. Plant a shifted row and see it fail.
- [x] T7: Registry and decision. Add the new rows to `cairn/ORACLES.md` under its quoting rule, update the six headings, write the three table-group lines with the group each rides on, and append the D-entry. Re-point `helper-time-budget.R` rows for the new blocks in one pass.
- [x] T8: Run `devtools::test()` and `air format --check .` clean.

## Work log

- 2026-10-31: created by /milestone-plan.
- 2026-10-31: tier check: not run — work named at the question set.
- 2026-10-31: idea vet: gap — "settle" read as new tests or as a record only, since the plugin's test rule admits tests on unchanged code only where criteria name them; asked at the question set, answered six tests plus a record. gap — whether the three table groups owe a second type; same answer, they owe none. No flaw.
- 2026-10-31: question set: what to work on — the oracle row; what settling means — a second-type test for the six own-result groups, and a record that the three table groups owe none. No permission, file or access was asked; the devel-vctrs approach question was not applicable.
- 2026-10-31: lessons used: 2026-10-31 (M163) registry upkeep; 2026-09-06 (M68) extract over `baseenv()`; 2026-09-16 (M101) skip helpers; 2026-10-22 (M152) re-point time-budget rows once.
- 2026-10-31: collision check: absorbs part of candidate "Settle oracle types for nine groups"; the finer results move to the new row "Give finer results a second oracle". No D-entry collides (no prior entry accepts a one-type group). Inbox: 1 open issue (#91, held by a parked row), 0 open PRs; no overlap.
- 2026-10-31: criteria audit (reduced mode, internal tier; fresh Opus reader): AC1-AC5 and AC7 no finding. AC6: "the group" claimed one group covers every restated number, which the wide tables break (they restate several groups' estimates) — narrowed to "at least one group"; "each oracle" had no unit — now one row per new test (AC2 adds two), and the six headings named inline. Instrument question: none, the registry and D-entry are the chosen deliverable.
- 2026-10-31: plan gate chose one milestone over splitting per group because each test is small and the registry edit spans all six; falsified by the plan-owned body passing the cap or T1-T6 not fitting two sessions.
- 2026-10-31: plan gate chose the stored-run invariant for the racing and annealing final fits over a single-candidate degenerate race, because the stored-run route needs no new fixture and works for both tuners; falsified by finetune accepting a one-candidate race and that test costing less.
- 2026-10-31: T1 done. New test "each selection rule picks the candidate its definition names in the fold's inner metrics" (test-nested-tune-grid-oracles.R:360) reads each rule from tune 2.1.0's `?select_best` page; the existing selection test now builds its three runs through `memoised()`, so the new test adds no fit (3 builds, 6 requests). Planted defect (rule ignored) failed one_std_err and pct_loss in fold 2. Source note `references/tune-select-best.md`: the page's percent-loss example divides by the candidate's value where tune's method body divides by the best's and stops at the best; both pick the same candidates on this fixture.
- 2026-10-31: verify scope: each task runs `devtools::test()` on the files it changes, and T8 runs the full suite once, alone (M152 lesson), since the new tests share no state across files.
- 2026-10-31: T2 done. New test "the racing final fit is the workflow finalized on its own race's pick" (test-nested-final-fit-race.R) reuses the cached deterministic final fit (`det_workflow`, seed 33) for both racers, picks from `extract_tune_results()` with `reference_select()` and the recorded rule, and fits by hand. Planted defect (worst-ranked candidate) failed for both racers.
- 2026-10-31: T3 done. New test "the annealing final fit is the workflow finalized on its own run's pick" (test-nested-final-fit-sim-anneal.R), same route on the cached deterministic annealing final fit. Planted defect (worst-ranked candidate) failed.
- 2026-10-31: T4 done. New test "the grid element matches a hand-rolled reference loop" (test-nested-workflow-map-oracles.R) compares the cached grid map element (`wset_two()`, seed 31) with `reference_nested_loop()` fold by fold. Planted defects: a perturbed seed passed (the engine is deterministic and the inner splits are fixed, so the seed reaches nothing compared), a reference selecting on rsq passed (rsq and rmse pick alike here), a one-candidate grid failed `.selected` and `.metrics`. The task's seed plant is replaced by the grid plant.
- 2026-10-31: T5 done. New test "inner v-fold splits partition their outer analysis rows" (test-nested-resamples-identity.R) maps a `.row_id` column through each inner split of a 3-fold outer, 4-fold inner `nested_resamples()` design. Planted defects: a row dropped from an inner `in_id` passed (vfold carries an explicit `out_id`, so the assessment cover is unchanged and AC4 does not check analysis completeness); a row dropped from an inner `out_id` failed the cover. A first run of that plant errored on `info = i` (a number), fixed to `paste(i)`.
- 2026-10-31: T6 done. New test "each fold's saved predictions are its extracted outer-fit workflow's predictions" (test-nested-tune-grid-results.R) runs `extracted_results()` with an `extract` returning the workflow, built over `baseenv()`, and compares each fold's `.pred` with `predict()` on the outer assessment rows. Planted defect (fold 1's predictions reversed) failed. `air format` applied.
- 2026-10-31: T7 done. `cairn/ORACLES.md`: six rows (grid-oracles/O7 closed-form, final-fit-race/O6 and final-fit-sim-anneal/O6 invariant, workflow-map-oracles/O2 live, resamples-identity/O1 and tune-grid-results/O1 invariant), six headings at two types, a ride-on line in each table group, a header rule for labels on added oracles, and the finer-results pointer re-aimed at the new row. D-121 appended. `helper-time-budget.R` needed no rows: it ledgers daemon waits, and no new test starts daemons.
- 2026-10-31: T8 done. Full `devtools::test()` run alone with `SummaryReporter$new(max_reports = Inf)`: no failed, skipped or warnings section; the six changed files all ran. `air format --check .` clean.
- 2026-10-31: claim audit: not owed — internal tier
- 2026-10-31: review pass 1 fix-now (docs half, checkpoint): ORACLES.md label rule, O7 caveat, map O2 seed wording, ride-on sentence; DESIGN.md oracle-records bullet admits later rows; tune-select-best.md "Traces to" and open question corrected. Test-file fixes wait for the running suite.
- 2026-10-31: review return 1: AC1 — the selection test computed each rule's pick from that rule's own run, where AC1 says "each fold's inner metrics of one grid run" (diff-bug #14). Fixed on the branch at review: the picks read the default rule's run, with two assertions that the three runs' inner metrics are identical; status stays review, since the fix is the whole of the return.
- 2026-10-31: review pass 1 fix-now (tests): selection test also asserts one_std_err and pct_loss pick differently; splits test asserts each inner split's analysis and assessment rows are disjoint; predictions test also compares `.row` with the split's complement; one-line source comments before the five other new tests and a line in the splits file header; `air format` applied. The six files pass.

## Review

Evidence at head `dda5c363` (tests) and `163b1f55` (registry), gathered 2026-10-31.

- AC1 evidence: `test-nested-tune-grid-oracles.R` "each selection rule picks the candidate its definition names in the fold's inner metrics" writes `best`, one-standard-error and percent-loss picks in `pick()` from `?select_best` (percent loss divided by the candidate's value, per the page's example), reads one run's `.inner_metrics` (the default rule's, asserted identical to the other two runs'), and compares each fold's recorded `.selected` under each rule. Passed in the full suite run alone (`review-test2`, no failed, skipped or warnings section). Plant (rule ignored) failed one_std_err and pct_loss in fold 2 (implement).
- AC2 evidence: "the racing final fit is the workflow finalized on its own race's pick" (`test-nested-final-fit-race.R`, both racers) and "the annealing final fit is the workflow finalized on its own run's pick" (`test-nested-final-fit-sim-anneal.R`) take `det_workflow()` final fits (seed 33), select from `extract_tune_results(final)` with `reference_select()` under `final$procedure$select`, finalize, `parsnip::fit()` on the same data, and compare `predict()` on the data. Passed in the full suite. Plant (worst-ranked candidate) failed for both racers and annealing.
- AC3 evidence: "the grid element matches a hand-rolled reference loop" (`test-nested-workflow-map-oracles.R`) compares the map's grid element on `wset_two()` with `reference_nested_loop()` on that workflow, fold by fold, in `.selected` and `.metrics`. Passed in the full suite. Plant (one-candidate grid) failed both comparisons.
- AC4 evidence: "inner v-fold splits partition their outer analysis rows" (`test-nested-resamples-identity.R`) builds a 3-fold outer, 4-fold inner `nested_resamples()` design over data with `.row_id`, and for each outer split asserts every inner analysis and assessment row is in the outer analysis rows and the inner assessment rows, sorted, equal the outer analysis rows (each exactly once). Passed in the full suite. Plant (row dropped from an inner `out_id`) failed the cover.
- AC5 evidence: "each fold's saved predictions are its extracted outer-fit workflow's predictions" (`test-nested-tune-grid-results.R`) runs `extracted_results()` under `save_pred = TRUE` with an `extract` returning the workflow, and asserts each fold's `.pred` equals `predict()` of that fold's extract on `rsample::assessment()` of its outer split. Passed in the full suite. Plant (fold 1 predictions reversed) failed.
- AC6 evidence: `cairn/ORACLES.md` holds the six rows (grid-oracles/O7 closed-form; final-fit-race/O6, final-fit-sim-anneal/O6, resamples-identity/O1, tune-grid-results/O1 invariant; workflow-map-oracles/O2 live), each with id, type, source and its test quoted by name, read by grep on the row and its test line. Headings at :45, :157, :166, :175, :188, :211 each state two types. The three table groups carry their line at :322 (rides on "nested_tune_grid() estimate"), :334 (holds no number) and :346 (rides on the outer-fit predictions and summarize-average groups). `cairn/DECISIONS.md:2132` is D-121.
- AC7 evidence: full `devtools::test()` run alone at the fixed head with `SummaryReporter$new(max_reports = Inf)`: exit 0, no failed, skipped or warnings section, 105 file lines, the six changed files present. `air format --check .` clean.
- Gate: `cairn_validate.py` all checks passed (coverage complete). No principle text changed, so `cairn_impact` skipped. `devtools::document()` diff was only the `Config/roxygen2/version` stamp (8.1.0 to 8.1.1), reverted. `pkgdown::check_pkgdown()` no problems. README untouched. No changelog entry: no user-visible change. No new top-level file. `devtools::check()` 0 errors, 0 warnings, 0 notes at `163b1f55` (before the review's test-comment and assertion fixes, which touch only `tests/testthat/`). All six gating prose sweeps exit 0.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: one_std_err and pct_loss were never told apart — fix now, fixed dda5c363
- diff-bug #2: the closed form takes the silent-point readings (best's own std_err, inclusive bound, strict limit) from tune's body while the note said it did not — fix now, note corrected, fixed 163b1f55
- diff-bug #3: five new oracles had no source comment in their test file (DESIGN Conventions) — fix now, fixed dda5c363
- diff-bug #4: race and anneal O6 broke the new label rule — fix now, rule reworded to "after the highest", fixed 163b1f55
- diff-bug #5: the splits test did not check an inner split's analysis rows against its own assessment rows — fix now, disjointness asserted, fixed dda5c363
- diff-bug #6: map O2 row's "under the map's seed" overstated — fix now, fixed 163b1f55
- diff-bug #7: the predictions test compared only `.pred` — fix now, `.row` against the complement added, fixed dda5c363
- diff-bug #8: AC2 runs only the default rule — reject, planned change: AC2 names the deterministic fixture, whose recorded rule is the default; a final fit under a recorded non-default rule is the selection group's `nested-final-fit-results/U1`
- diff-bug #9: the intro said each table group names a group, but fold labels hold no number — fix now, fixed 163b1f55
- diff-bug #10: the selection heading states two types while desirability and the selection metric keep one — reject, planned change: AC6 requires the heading and the text under it names the exception and the finer-results row
- diff-bug #11: DESIGN's oracle-records bullet still scoped the registry to `576c3d19` — fix now, fixed 163b1f55
- diff-bug #12: stray blank lines and row order — reject: blank lines false (the diff removes three and adds none), order style
- diff-bug #13: the note's `slice(1:best_index)` difference cannot change a pick — fix now, fixed 163b1f55
- diff-bug #14: the selection test read three runs' inner metrics where AC1 says one run — fix now (review return 1), fixed dda5c363
- blame-history #1: O7 row lacked the page-versus-code caveat — fix now, fixed 163b1f55
- blame-history #2: O7 contradicts D-079's selection count — reject, false: D-079 fixes which per-tuner tests stay and counts their two oracles; a third oracle contradicts nothing it decides
- blame-history #3: ROADMAP candidate rows not edited on the branch — reject, false: the plan commit on main narrowed them and marked "started M164"; step 9 graduates the row
- blame-history #4: D-121 says "applies" not "narrows", and the "all nine" option is unrecorded — reject, false: D-121 reads which tables are numeric results and leaves GP2's text as is; "Tests for all nine" was an option at the plan question set
- blame-history #5: label rule broken — fix now (same as diff-bug #4), fixed 163b1f55
- blame-history #6: the "adds no fit" count holds only in one worker — reject, false: the work log states the count of the measured run
- prior-review #1: missing source comments — fix now (same as diff-bug #3), fixed dda5c363
- prior-review #2: race and anneal O6 should be live — reject, false: the registry's type rule makes a by-hand route over the package's own stored run invariant
- prior-review #3: label rule broken — fix now (same as diff-bug #4), fixed 163b1f55
- prior-review #4: no `helper-time-budget.R` re-point — reject, false: T7's work-log line records that the ledger holds only daemon waits and no new test starts daemons
- ripple #1: ROADMAP's "Settle oracle types for nine groups" row reads stale — reject, planned change: it carries "started M164" and step 9 graduates it
- ripple #2: splits file header named only `nested_cv()` — fix now, fixed dda5c363
- ripple #3: the grid-oracles selection note describes only the old test — reject, false: it introduces the block below it, which it still describes; the new block has its own source line
- ripple #4: map file header names only the hand call — fix now, source line before the new block, fixed dda5c363
- ripple #5: the "Files with prose oracle comments at 576c3d19" list omits the new rows — reject, false: the heading scopes it to records at `576c3d19`
- ripple #6: race and anneal headers describe only O5 — fix now, source lines before the new blocks, fixed dda5c363
- Changed snapshot files: none (`git diff --name-only main...HEAD` lists no `_snaps` path).
- 2026-10-31: step-7 approval: m164-second-oracle-types approved for merge
