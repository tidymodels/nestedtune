# M75: The suite makes each claim once, and the files that test the harness rather than the package are deleted or trimmed

- **Status:** planned
- **Priority:** normal
- **Depends on:** M74
- **Driving RR:** —
- **Principles touched:** GP4
- **Resolves:** —
- **Surface tier:** internal — deletes and trims test files; no external consumer of the package relies on them
- **Branch/PR:** —

## Goal

Delete test blocks whose claim a surviving block already asserts, and thin the nine files that test the harness, the CI yaml or the vignettes' citations rather than the package, so the suite reads as one check per claim.

## Scope

**In:** the per-tuner blocks the 2026-09-07 survey found repeating a sibling's claim (the `expect_outer_columns_kept()` trio in bayes-results, race-oracles and anneal-oracles; the zero-row `.iter` pair in anneal-oracles and bayes-results; the failed-fold RNG restoration trio in race-rng, bayes-rng and anneal-rng; the by-hand recipe blocks in race-oracles and anneal-oracles that re-run a fold the reference-loop block already matched; bayes-oracles' "every NAMESPACE method runs"; the `iter = 0` identity asserted in both bayes-oracles and final-fit-oracles; the three final-fit-results blocks sharing one cached fit), each removed with its survivor named; a disposition per harness-testing file — `test-fixture-cache.R`, `test-hang-trace.R`, `test-suite-hygiene.R`, `test-ci-workflows.R`, `test-vignette-citations.R`, `test-drift-manifest.R`, `test-dots-barrier.R`, `test-control-slots.R`, `test-parallel-classify.R` — deleted, kept whole, or trimmed; helpers left uncalled by the deletions removed; the `Config/testthat/start-first` list and the `helper-time-budget.R` ledger re-keyed where a deletion moves a budgeted call.

**Out:** making the surviving blocks faster → M74. Deleting any oracle, rng or identity block that is the only assertion of its claim → never in this milestone; a block whose partner is unclear stays. A coverage-percentage target → none (PROFILE: covr is a diagnostic).

## Acceptance criteria

- [ ] AC1: Every `test_that()` block removed between the branch point and the head — enumerated by diffing `test_that_descriptions()` over `tests/testthat/test-*.R` at the two refs — has its claim asserted by a block that survives on the head, the mapping recorded in the milestone file as one row per removed description naming the surviving `file: description`; an added block appears in that table as the survivor for the blocks it replaces.
- [ ] AC2: The head has at least 60 fewer `test_that()` blocks than the branch point, counted by `test_that_descriptions()` over `tests/testthat/test-*.R` (789 at `6cfccb1`; the survey names about 25 duplicate blocks and 135 harness-layer blocks, and 60 is the 25 plus a floor of 35 from the nine files).
- [ ] AC3: Every function defined in `tests/testthat/helper-*.R` (enumerated by `grep -n -E '^[A-Za-z_.]+ <- function' tests/testthat/helper-*.R`) is named outside a comment or string in another top-level expression of some file under `tests/testthat/`, its own included, found by `grep -n -F` on the name; a function that is not is removed.
- [ ] AC4: Each of the nine harness-testing files named in Scope carries one of three dispositions — deleted, kept whole, or trimmed — in a classification ledger in the milestone file, one row per file naming the disposition and its reason; a trimmed file's removed blocks appear in AC1's table.
- [ ] AC5: `Rscript -e 'devtools::test()'` on the head reports 0 failures and 0 skips, and the active profile's verify slot is clean — `devtools::check()` 0 errors, 0 warnings, 0 unjustified notes — with `air format --check` clean on every file the branch touches (`git diff --name-only <branch point>`).

## Coverage

- AC1 → T1, T2, T3
- AC2 → T2, T3
- AC3 → T4
- AC4 → T3
- AC5 → T5

## Tasks

- [ ] T1: Write the removal table from the survey's per-file findings before deleting anything: one row per candidate block with its surviving partner's `file: description`, and drop from the list any block whose partner asserts less than it does.
- [ ] T2: Delete the per-tuner duplicates in the table; where a partner asserts less, extend the partner rather than keep both.
- [ ] T3: Disposition each of the nine harness-testing files in the classification ledger — a file whose subject is a repo artifact (the yaml, vignette citations, the drift manifest) is deleted unless a block detects a defect that has reached the default branch before, cited by commit; a file testing a harness the surviving tests depend on (the hang trace, the fixture cache, the parallel classifier) is trimmed to the blocks that would fail on a defect in that harness — then apply it, re-key `start-first` and the time-budget ledger.
- [ ] T4: Run the AC3 enumeration; remove every helper it leaves uncalled.
- [ ] T5: `devtools::test()`, `devtools::check()`, `air format --check`.

## Work log

- 2026-09-07: created by /milestone-plan, from the user's question at M74's plan gate on how many tests are needed. Criteria audit ran in reduced mode (internal tier) on a fresh [O] reader: five findings on AC1–AC5, all fixed — AC3's uncalled test counts a helper's own file (23 helpers are used only there); AC4's planted-defect family replaced by a per-file classification ledger; AC1 records one row per removed description with its survivor and admits a replacing block; AC3's "called" made a grep; AC5 reads one `devtools::test()` rather than the three-run profiler and states 0 unjustified notes.
- 2026-09-07: plan gate chose a separate pruning milestone over folding it into M74 (see M74's work log); no other alternative weighed here.

## Decisions

## Review
