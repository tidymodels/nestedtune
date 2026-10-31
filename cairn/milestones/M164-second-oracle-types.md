# M164: Give six one-type results a second oracle

- **Status:** in-progress
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

- [ ] AC1: `test-nested-tune-grid-oracles.R` gains a test whose expected selections are computed by explicit code from the definitions in tune's help pages for `select_best()`, `select_by_one_std_err()` and `select_by_pct_loss()`, on each fold's inner metrics of one grid run, and it asserts that the fold's recorded selection under each of the three rules equals that computed candidate.
- [ ] AC2: `test-nested-final-fit-race.R` and `test-nested-final-fit-sim-anneal.R` each gain a test on the suite's deterministic fixture that asserts the final fit's predictions on the data equal those of the workflow finalized by hand on the candidate that the recorded rule picks from the final fit's own tuning run (`extract_tune_results()`) and fit by hand on the same data.
- [ ] AC3: `test-nested-workflow-map-oracles.R` gains a test asserting that the map's element for a workflow routed to `nested_tune_grid()` matches `reference_nested_loop()` on that workflow in each fold's selected parameters and outer metrics.
- [ ] AC4: `test-nested-resamples-identity.R` gains a test on a `nested_resamples()` v-fold outer / v-fold inner design over data with a row-id column that asserts, for every outer split, that every inner analysis and assessment row is a row of the outer analysis set, and that the inner assessment sets hold each outer analysis row exactly once.
- [ ] AC5: `test-nested-tune-grid-results.R` gains a test on a grid run under `save_pred = TRUE` with an `extract` that returns the fitted workflow, asserting that each fold's saved predictions equal `predict()` of that fold's extracted workflow on the fold's outer assessment rows.
- [ ] AC6: `cairn/ORACLES.md` holds one oracle row for each of the six tests AC1 to AC5 add (AC2 adds two), with id, type, source and its test quoted by name, in its group; the headings of the six groups (selection rules and the selection metric, the racing final fit, the annealing final fit, `nested_workflow_map()`, the splits `nested_resamples()` builds, each fold's outer-fit predictions and extracts) each state two types; each of the three table groups (wide metric tables, fold labels, rows `augment()` joins) carries one line that names at least one group whose oracles check numbers it restates, or says it holds no number; and a new `cairn/DECISIONS.md` entry records that such a table owes no second oracle type.
- [ ] AC7: `devtools::test()` reports no failures, and `air format --check .` is clean.

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
- [ ] T5: Splits, invariant. In `test-nested-resamples-identity.R`, map each inner split back through a row-id column and check containment and the exactly-once cover. Plant a dropped row and see it fail.
- [ ] T6: Outer-fit predictions, invariant. In `test-nested-tune-grid-results.R`, run with an `extract` that returns the fitted workflow, built over `baseenv()` so the fixture cache keys it, and compare each fold's `.predictions` with `predict()` on the outer assessment rows. Plant a shifted row and see it fail.
- [ ] T7: Registry and decision. Add the new rows to `cairn/ORACLES.md` under its quoting rule, update the six headings, write the three table-group lines with the group each rides on, and append the D-entry. Re-point `helper-time-budget.R` rows for the new blocks in one pass.
- [ ] T8: Run `devtools::test()` and `air format --check .` clean.

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
