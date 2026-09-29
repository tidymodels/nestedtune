<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M128: Refuse the resampling designs the README marks No

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** GP1, GP3   <!-- owner: plan · create/amend-via-gate; comma-separated IPn/GPn ids this milestone touches, or — -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate; comma-separated GitHub issues the scope absorbs, each `#N closes` (the PR closes it at merge) or `#N partial` (the remainder gets a candidate row), or — ; skill conduct only — no validate check parses it -->
- **Surface tier:** user-facing — new refusals in exported functions   <!-- owner: plan · create/amend-via-gate; user-facing | internal — <one-clause reason>; skill conduct only — no validate check parses it -->
- **Branch/PR:** m128-refuse-unsupported-designs   <!-- owner: implement (branch) / review (PR URL) · create; a companion checkout the milestone also works in is one further entry per checkout, `companion: <abs-path> <branch>` (implement), its PR URL appended by review — /milestone-review merges companions first, in listed order -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

A nested design with an outer or inner `loo_cv()`, `apparent()` or `permutations()` is refused at the call, before any fold runs.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** The six refusals in `nested_resamples()` and in `check_nested()`, the entry check of every orchestrator. The outer bootstrap refusal in `nested_resamples()` gains the entry check's class. The README table, its paragraphs, the help, and NEWS follow. D-096 records the decision.

**Out:**
- Inner `validation_set()` keeps its `No` cell. It cannot be built, so nothing is left to refuse. The README footnote covers the outer case.
- The five rsample functions the table does not list stay unclaimed (D-095).
- A test that ties each README cell to the test behind it stays a `[low]` candidate row. Its "next change to a cell" trigger is removed, because this milestone's review checks the six cells by hand.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [ ] AC1: `nested_resamples()` refuses six designs with an error of class `nestedtune_bad_design`. The message names the rsample function. The six are an outer `loo_cv()`, `apparent()` or `permutations()`, and an inner design whose `rset` has one of those three classes. An outer design is refused both as a call and as an `rset` built on `data`. The outer bootstrap refusal carries the same class. A test fires the nine cases (three outer designs in two forms, three inner designs) and the bootstrap case. It asserts the class and the function name.
- [ ] AC2: Seven functions refuse a design passed to them if its outer `rset` or any inner `rset` has one of the three classes. The seven are `nested_tune_grid()`, `nested_tune_bayes()`, `nested_tune_race_anova()`, `nested_tune_race_win_loss()`, `nested_tune_sim_anneal()`, `nested_fit_resamples()` and `nested_workflow_map()`. The refusal comes from the entry check, with class `nestedtune_bad_design` and a message that names the rsample function. An inner refusal names the positions of the offending outer folds. A test runs the six shapes `rsample::nested_cv()` builds and one mixed design through `nested_tune_grid()`. In the mixed design, one fold's inner `rset` alone is `apparent()`. The test also runs outer `loo_cv()` through each of the other six functions. It asserts the class and the function name.
- [ ] AC3: In the table in `README.Rmd`, the six cells AC1 covers read `Refused`. The inner `validation_set()` cell is the only `No` cell. The Refused paragraph gives the reason for each refused design. It names both refusal paths: `nested_resamples()` and the entry check of the seven functions in AC2. The No paragraph gives only the inner `validation_set()` reason. After `devtools::build_readme()`, `git status` shows no change to `README.md`.
- [ ] AC4: Two help passages name the six refused designs. One is the "Differences from rsample" section of `?nested_resamples`. The other is the paragraph of `?nested_tune_grid` that names the bootstrap refusal (`R/nested-tune-grid.R:119`). `NEWS.md` has one bullet for the refusals. After `devtools::document()`, `git status` shows no change under `man/`.
- [ ] AC5: On the branch head, `devtools::test()` reports 0 failures. `devtools::check()` reports 0 errors and 0 warnings. It reports no note that `main` does not also give in the same environment.

## Coverage
<!-- owner: plan · create/amend-via-gate; each acceptance criterion → the task(s) satisfying it. -->

- AC1 → T1, T2
- AC2 → T3
- AC3 → T4
- AC4 → T4
- AC5 → T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits); substantive change is amend-via-gate. -->

- [x] T1: Write the AC1 tests first in `tests/testthat/test-design-support.R`. Replace the six tests that pin the old `No` behavior (the outer and inner `loo_cv()`, `apparent()` and `permutations()` blocks, lines 111-230). Add a class assertion to the group-bootstrap test at line 84. Keep the two `validation_set()` tests. Update the header comment's definitions of the `Refused` and `No` cells. Show that each new test fails on today's code because no refusal fires.
- [x] T2: In `R/nested-resamples.R`, refuse the three outer designs next to the bootstrap refusal (line 150). Refuse the three inner designs in `inner_resamples_from_split()`, right after `eval_spec()`. Give the new refusals and the bootstrap refusal class `nestedtune_bad_design`. Each message gives the reason the README gives today for that design in that role. An outer `loo_cv()` scores one row per fold, so R² cannot be computed and the averaged RMSE is the mean absolute error. An outer `apparent()` scores the rows it trained on. An outer `permutations()` gives each fold no assessment set. As inner designs, tune refuses `loo_cv()` and `permutations()` and reports no results for `apparent()`.
- [ ] T3: Write the AC2 tests first, then add the refusals to `check_nested()` in `R/checks.R`. Place them after the bootstrap check and before the element checks. The inner check reads each `inner_resamples` element with `inherits()`, because the class checks come later. The racer and annealer tests pass over legs where `tuner_ready()` is false (LESSONS, M101). `nested_workflow_map()` re-signals the error with its class kept (LESSONS, M73), so its test asserts the class.
- [ ] T4: Edit the `README.Rmd` table and its Refused and No paragraphs, then run `devtools::build_readme()`. Edit the roxygen in `R/nested-resamples.R` and at `R/nested-tune-grid.R:119`, then run `devtools::document()`. Add one `NEWS.md` bullet. Run `benchmarks/sweep-prose.R` over the touched pages.
- [ ] T5: Run `devtools::test()` and `devtools::check()`. Compare any note with one run on `main` in the same environment.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-09-29: created by /milestone-plan, promoting the `[high]` candidate row that M127's plan gate added.
- 2026-09-29: criteria audit ran in full mode (fresh [O] reader). It found no check that fires first and no principle conflict. Nine findings were fixed before the gate, and the gate decided the tenth (`nested_fit_resamples()` and the inner check).
- 2026-09-29: plan gate chose refusing outer `loo_cv()` over leaving it `No`, because tune refuses leave-one-out for a flat run. Also, one-row folds turn the averaged RMSE into the mean absolute error. Falsified by a tune release that tunes on leave-one-out, or by a source that gives a valid nested estimate from one-row outer folds.
- 2026-09-29: plan gate chose one refusal rule for all seven functions over skipping the inner check in `nested_fit_resamples()`, because `nested_resamples()` already refuses these inner designs at construction. Falsified by a user who needs such an `rsample::nested_cv()` design in `nested_fit_resamples()`.
- 2026-09-29: plan chose class `nestedtune_bad_design` for the `nested_resamples()` refusals over a new class, because every entry-check refusal already carries it. Falsified by a caller who needs to tell a construction refusal from an entry refusal.
- 2026-09-29: the audit reader rechecked the revised wording and found two new problems, both fixed. AC2 now covers any design passed in, so the mixed case falls inside its domain. T2 now takes each refusal reason from the README's current text.
- 2026-09-29: implement started on branch `m128-refuse-unsupported-designs`. No question gate, because the plan left no implementation choice open.
- 2026-09-29: T1 done. Six refusal tests and the bootstrap class assertion replace the six `No` tests. Before T2, all seven failed, each on a missing `nestedtune_bad_design` error.
- 2026-09-29: T2 done. `refused_design()` and `refused_design_reason()` in `R/checks.R` serve both refusal sites. Full suite 0 failures, plain prose sweep clean.

## Decisions
<!-- owner: implement / review · append-only; milestone-local. -->

## Review
<!-- owner: review · exclusive. -->
