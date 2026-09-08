# M75: The suite makes each claim once, and the files that test the harness rather than the package are deleted or trimmed

- **Status:** review
- **Priority:** normal
- **Depends on:** M74
- **Driving RR:** —
- **Principles touched:** GP4
- **Resolves:** —
- **Surface tier:** internal — deletes and trims test files; no external consumer of the package relies on them
- **Branch/PR:** m075-suite-prune / https://github.com/tidymodels/nestedtune/pull/85

## Goal

Delete test blocks whose claim a surviving block already asserts, and thin the nine files that test the harness, the CI yaml or the vignettes' citations rather than the package, so the suite reads as one check per claim.

## Scope

**In:** the per-tuner blocks the 2026-09-07 survey found repeating a sibling's claim (the `expect_outer_columns_kept()` trio in bayes-results, race-oracles and anneal-oracles; the zero-row `.iter` pair in anneal-oracles and bayes-results; the failed-fold RNG restoration trio in race-rng, bayes-rng and anneal-rng; the by-hand recipe blocks in race-oracles and anneal-oracles that re-run a fold the reference-loop block already matched; bayes-oracles' "every NAMESPACE method runs"; the `iter = 0` identity asserted in both bayes-oracles and final-fit-oracles; the three final-fit-results blocks sharing one cached fit), each removed with its survivor named; a disposition per harness-testing file — `test-fixture-cache.R`, `test-hang-trace.R`, `test-suite-hygiene.R`, `test-ci-workflows.R`, `test-vignette-citations.R`, `test-drift-manifest.R`, `test-dots-barrier.R`, `test-control-slots.R`, `test-parallel-classify.R` — deleted, kept whole, or trimmed; helpers left uncalled by the deletions removed; the `Config/testthat/start-first` list and the `helper-time-budget.R` ledger re-keyed where a deletion moves a budgeted call.

**Out:** making the surviving blocks faster → M74. Deleting any oracle, rng or identity block that is the only assertion of its claim → never in this milestone; a block whose partner is unclear stays. A coverage-percentage target → none (PROFILE: covr is a diagnostic).

## Acceptance criteria

- [x] AC1: Every `test_that()` block removed between the branch point and the head — enumerated by diffing `test_that_descriptions()` over `tests/testthat/test-*.R` at the two refs — has its claim asserted by a block that survives on the head, except a block removed from a harness-testing file under T3's trim rule (whose claim is about the harness, not the package) and a block removed with its whole file under AC4's deleted disposition; a block added on the head may be the survivor for the blocks it replaces.
- [x] AC2: The head has at least 40 fewer `test_that()` blocks than the branch point, counted by `test_that_descriptions()` over `tests/testthat/test-*.R` (795 at the branch point `accfbe2`; the floor is the 16 blocks the removal table names plus the 25 the two deleted files take, less the one block added on the head to carry a claim a removal left uncovered).
- [x] AC3: Every function defined in `tests/testthat/helper-*.R` (enumerated by `grep -n -E '^[A-Za-z_.]+ <- function' tests/testthat/helper-*.R`) is named outside a comment or string in another top-level expression of some file under `tests/testthat/`, its own included, found by `grep -n -F` on the name; a function that is not is removed.
- [x] AC4: Each of the nine harness-testing files named in Scope carries one of three dispositions — deleted, kept whole, or trimmed — in a classification ledger in the milestone file, one row per file naming the disposition and its reason; a trimmed file's removed blocks appear in AC1's table.
- [x] AC5: `Rscript -e 'devtools::test()'` on the head reports 0 failures and 0 skips, and the active profile's verify slot is clean — `devtools::check()` 0 errors, 0 warnings, 0 unjustified notes — with `air format --check` clean on every file the branch touches (`git diff --name-only <branch point>`).

## Coverage

- AC1 → T1, T2, T3
- AC2 → T2, T3
- AC3 → T4
- AC4 → T3
- AC5 → T5

## Tasks

- [x] T1: Write the removal table from the survey's per-file findings before deleting anything: one row per candidate block with its surviving partner's `file: description`, and drop from the list any block whose partner asserts less than it does.
- [x] T2: Delete the per-tuner duplicates in the table; where a partner asserts less, extend the partner rather than keep both.
- [x] T3: Disposition each of the nine harness-testing files in the classification ledger — a file whose subject is a repo artifact (the yaml, vignette citations, the drift manifest) is deleted unless a block detects a defect that has reached the default branch before, cited by commit; a file testing a harness the surviving tests depend on (the hang trace, the fixture cache, the parallel classifier) is trimmed to the blocks that would fail on a defect in that harness — then apply it, re-key `start-first` and the time-budget ledger.
- [x] T4: Run the AC3 enumeration; remove every helper it leaves uncalled.
- [x] T5: `devtools::test()`, `devtools::check()`, `air format --check`.

## Removals (AC1)

One row per removed `test_that()` description; the survivor is the block on the head that asserts the removed block's claim. Mechanism notes cite the one site in `R/` the duplicated blocks all exercised.

| Removed (`file: description`) | Survivor (`file: description`) | Note |
|---|---|---|
| `test-nested-tune-bayes-results.R: a Bayesian run keeps the outer fit's predictions and extracts when the control asks (AC1, AC2)` | `test-nested-tune-grid-results.R: save_pred = TRUE keeps each fold's outer-fit predictions, identical to last_fit()'s (AC1)`; `test-nested-tune-grid-results.R: extract = f keeps f() of each fold's outer-fit workflow, identical to f() on last_fit()'s (AC2)` | one outer-fit site reads the merged control for every tuner (`R/nested-tune-grid.R`, `save_pred` and `extract` branches of the outer fit) |
| `test-nested-tune-race-oracles.R: a racing run keeps the outer fit's predictions and extracts when the control asks (AC1, AC2)` | the two grid-results blocks above | same site |
| `test-nested-tune-sim-anneal-oracles.R: an annealing run keeps the outer fit's predictions and extracts when the control asks (AC1, AC2)` | the two grid-results blocks above | same site |
| `test-nested-tune-race-rng.R: the RNG state is restored when folds fail but the run completes` | `test-nested-tune-grid-rng.R: the RNG state is restored when folds fail but the run completes`; its failed-fold zero-row clause by `test-nested-tune-race-oracles.R: a race fold that scored nothing carries a zero-row table with no .iter`, a block added on the head | one `restore_rng()` exit handler in the shared loop (`R/nested-tune-grid.R`) serves every tuner |
| `test-nested-tune-bayes-rng.R: the RNG state is restored when folds fail but the run completes` | the grid-rng block above | same handler |
| `test-nested-tune-sim-anneal-rng.R: the RNG state is restored when folds fail but the run completes` | the grid-rng block above; its failed-fold zero-row clause by `test-nested-tune-sim-anneal-oracles.R: a fold that scored nothing carries .iter on its zero-row table (AC1)` | same handler, same prototype site |
| `test-nested-final-fit-results.R: the fitted workflow predicts on new data` | `test-nested-final-fit-results.R: the final fit returns a trained workflow inside its own object` (extended with the prediction assertions) | one cached fit |
| `test-nested-final-fit-results.R: the final fit trains on every row, not on an outer analysis set` | the same extended block | one cached fit |
| `test-parallel-classify.R: dispatch refuses daemons that cannot load the package` | `test-parallel-classify.R: a pool that cannot load AND holds an old build names both fixes` (its plain-pool clause makes the same call and class assertion) | its ledger row (`helper-time-budget.R`, line 209) goes with it |
| `test-parallel-classify.R: a load failure still outranks an incompatible daemon` | the same both-fixes block (asserts `outcome`, `cannot_load` and `incompatible` on the same pool shape, plus the message) | — |
| `test-parallel-classify.R: a miraiInterrupt aborts instead of being recorded as a failed fold` | `test-parallel-classify.R: a real interrupt is an interrupt, not a cancellation` (extended to assert the condition is an error of that class) | same fixture |
| `test-fixture-cache.R: the report counts one build per signature and every request` | — (T3 trim rule: tests the build report, a diagnostic the cache's correctness does not rest on) | — |
| `test-fixture-cache.R: one call written two ways is one fixture, reported as built twice` | — (T3 trim rule: report grouping) | — |
| `test-fixture-cache.R: the same call under two seeds is two fixtures, not one rebuilt` | — (T3 trim rule: report grouping; the seed's place in the key is `the key separates the seed, and argument order does not` and `a different seed rebuilds rather than serving the first result`) | — |
| `test-fixture-cache.R: the teardown's report is written to stderr, and nothing to stdout` | — (T3 trim rule: the report's print format) | — |
| `test-hang-trace.R: the two-block fixture's directory is gone once its caller returns` | — (T3 trim rule: a self-test of the test fixture's cleanup) | — |

The 25 descriptions removed with `test-vignette-citations.R` and `test-drift-manifest.R` are in git at the branch point (`accfbe2`) and take AC4's deleted disposition.
Considered and kept: the `iter = 0` pair (`test-nested-tune-bayes-oracles.R` run identity with `.iter` zeros; `test-nested-final-fit-oracles.R` final-fit identity) — each asserts what the other does not.

## File ledger (AC4)

| File | Disposition | Reason |
|---|---|---|
| `test-fixture-cache.R` | trimmed | the hit-identity, condition-replay, RNG, caller-frame and key-separation blocks fail on a cache defect and stay; the four report and teardown-format blocks test the diagnostic |
| `test-hang-trace.R` | trimmed | the pairing, bracket, wedge, file-end, live-mode and duplicate-description blocks stay, the planted-duplicate positive among them (it is what fails when the scan stops reporting); the fixture-directory self-test goes |
| `test-suite-hygiene.R` | kept whole | guards the time-budget ledger the scope keeps and the bounded-wait rule (question gate 2026-09-08) |
| `test-ci-workflows.R` | kept whole | the regression test of a defect that reached the default branch (pkgdown deploy hotfix, commit 7ca14b7, PR #17) |
| `test-vignette-citations.R` | deleted | rules 1-5 and 7 read shipped `vignettes/*.Rmd`, rule 6 reads author-year citations in `R/` roxygen against the `cairn/` shelf; every rule's real-tree half skips in a built package while its planted-fixture half runs there. No defect on the default branch behind it; deleted at the 2026-09-08 question gate and kept on these corrected facts |
| `test-drift-manifest.R` | deleted | repo-artifact test of `benchmarks/mori-wire-manifest.json`, no defect on the default branch behind it; `helper-drift-manifest.R` goes with it |
| `test-dots-barrier.R` | kept whole | tests exported behavior: the condition class each entry point raises on an unknown argument (question gate 2026-09-08) |
| `test-control-slots.R` | kept whole | a documented contract read from tune's `formals()` (question gate 2026-09-08) |
| `test-parallel-classify.R` | trimmed | package tests of `R/parallel.R`, not a harness (question gate 2026-09-08): only blocks repeating a sibling's claim go, each in the AC1 table |

## Work log

- 2026-09-07: created by /milestone-plan, from the user's question at M74's plan gate on how many tests are needed. Criteria audit ran in reduced mode (internal tier) on a fresh [O] reader: five findings on AC1–AC5, all fixed — AC3's uncalled test counts a helper's own file (23 helpers are used only there); AC4's planted-defect family replaced by a per-file classification ledger; AC1 records one row per removed description with its survivor and admits a replacing block; AC3's "called" made a grep; AC5 reads one `devtools::test()` rather than the three-run profiler and states 0 unjustified notes.
- 2026-09-08: question gate: `test-parallel-classify.R` read as package tests and deduplicated only; `test-vignette-citations.R` deleted; suite-hygiene, dots-barrier and control-slots kept whole; `test-ci-workflows.R` kept as the regression test of 7ca14b7 (PR #17). T1: removal table written, 15 rows (12 from the scope's tuner list, 3 from an [O] survey of `test-parallel-classify.R`, verified by reading each pair); the `iter = 0` pair kept, each block asserting what the other does not. Branch point `accfbe2` has 795 blocks.
- 2026-09-08: amendment gate (Substantive): AC1 admits no survivor-less removal, which every whole-file deletion and harness self-test trim is, and AC2's 60 is out of reach under the question gate's choices (46 reachable); the user chose to amend both.
- 2026-09-08: re-audit: AC2 (reduced) — nothing; the parenthetical read as provenance for the floor, not a condition.
- 2026-09-08: re-audit: AC1 (reduced) — instrument finding: the proposed text led with "has one row in the removal table", a property of the record, not the suite; the reader's repair leads with the claim-asserted-by-a-survivor property and makes the table the record.
- 2026-09-08: re-audit: AC1 (reduced) — the repaired wording re-entered with a fresh reader: instrument finding on its second sentence (the table clause binds the recording instrument; T1 already mandates the table); this second line is the stop, so the choice between the two repairs goes to the user.
- 2026-09-08: AC2 amended to the audited text above. T2: the 15 removal-table blocks deleted; the partners that asserted less extended (`the final fit returns a trained workflow inside its own object` takes the prediction and mould assertions; race-oracles' AC3 block asserts no `.iter` on the race record; `a real interrupt is an interrupt, not a cancellation` asserts the error by class); the 43 remaining `test-parallel-classify.R` ledger rows re-keyed by a line map and the removed block's row dropped. `devtools::test()` with 6 workers: 786 blocks, 0 failures, 0 skips; `air format --check` clean on the touched files.
- 2026-09-08: AC1 amended to the second reader's wording at the user's choice (the table sentence dropped; the table stays T1's deliverable).
- 2026-09-08: T3: the ledger applied — `test-vignette-citations.R`, `test-drift-manifest.R` and `helper-drift-manifest.R` deleted; four report blocks cut from `test-fixture-cache.R` and two self-tests from `test-hang-trace.R`; one comment in `test-dplyr-compat.R` that named the deleted file trimmed. Nothing in `start-first` or the time-budget ledger keyed to the moved calls. Head count 749 against 795 (46 fewer). `devtools::test()` with 6 workers: 755 blocks, 0 failures, 0 skips; `air format --check` clean on the trimmed files.
- 2026-09-08: T4: the AC3 enumeration (parse tokens over every file under `tests/testthat/`, the defining expression excluded) left two helpers uncalled — `fixture_cache_reset()`, uncalled before this branch, and `expect_outer_columns_kept()`, left by T2 — both removed from `helper-orchestration.R`; 156 helpers remain, none uncalled. `devtools::test()` with 6 workers: 755 blocks, 0 failures, 0 skips.
- 2026-09-08: T5: `devtools::check()` on the head — 0 errors, 0 warnings, 0 notes (7m 16s); `air format --check` clean on every R file the branch diff touches; the description diff against `accfbe2` is 46 removed and none added, matching the removal table's 21 rows plus the 25 descriptions of the two deleted files. Status to review.
- 2026-09-08: review gate: AC2, AC3, AC4 and AC5 verified with fresh evidence (749 vs 795 blocks; 156 helpers all called; nine ledger rows matching disk; `devtools::test()` 0/0/0 with 9456 passes, `devtools::check()` 0/0/0, `air format --check` clean). AC1 FAILED: four of the fifteen deduplication rows remove a claim no surviving block asserts — bayes-oracles' `NAMESPACE` completeness tripwire (`setdiff(registered, names(calls))`), both by-hand-recipe blocks' re-run of a fold from the recorded `procedure` attributes, the race path's failed-fold zero-row `nrow == 0`, and a fourth row whose named survivor is a `formals()` test that asserts no `.iter` (with the failed **annealing** fold's zero-row table left uncovered). Status to in-progress; first defect return. Fix-now findings carried with it: the `test-hang-trace.R` planted-duplicate positive (T3's trim rule keeps blocks that would fail on a harness defect; the survivor would not), the inaccurate `test-vignette-citations.R` ledger reason, and `helper-time-budget.R:44`'s de-keyed comment. Consistency gate green (`cairn_validate` exit 0; `document()` no diff; `check_pkgdown()` clean). PR #85 open as a draft.
- 2026-09-08: repair pass on the first defect return. O1-O4: the bayes-oracles `NAMESPACE` completeness block, both by-hand-recipe blocks and the annealing zero-row block restored verbatim from `accfbe2` and their rows dropped from the removal table; a new block `a race fold that scored nothing carries a zero-row table with no .iter` added to `test-nested-tune-race-oracles.R` to carry the race path's failed-fold claim, and the two rng rows re-pointed at it and at the restored annealing block. O5: the planted-duplicate block restored to `test-hang-trace.R` and its ledger reason corrected. P7: `helper-time-budget.R:44` re-keyed to `classify:723 sets it, :729 spends it`, read off the head's `test-parallel-classify.R`; the review's suggested 726 is the `setTimeLimit()` line, not the option line.
- 2026-09-08: amendment gate (Substantive): the repair restores five blocks, so the head is 40 fewer against AC2's floor of 45; the user chose to lower the floor to the count the surviving dispositions give and to keep `test-vignette-citations.R` deleted on corrected ledger facts (rule 6 reads `R/` roxygen, but against the `cairn/` shelf, so no rule of the file can run outside the source tree).
- 2026-09-08: re-audit: AC2 (reduced) - nothing; the derivation clause read as provenance for the floor, not a second condition. Second line for AC2, so no further reader is spawned for it.
- 2026-09-08: AC2 amended to the audited text above; the AC3, AC4 and AC5 ticks cleared, their review evidence having been measured on the pre-repair head.
- 2026-09-08: checkpoint, half-done: the repair edits and the amended records are committed, but the head's `devtools::test()` and `devtools::check()` had not finished when this commit was made; the four affected test files pass on their own (0 failures, 0 skips) and `air format --check` is clean on the touched files. Head count 755 against 795, 40 fewer, meeting the amended floor.
- 2026-09-08: repair pass verified on the head: `devtools::test()` with 6 workers reports FAIL 0 | WARN 0 | SKIP 0 | PASS 9517; `devtools::check()` 0 errors, 0 warnings, 0 notes (7m 13.6s, Status OK); `air format --check` clean on every R file the branch diff touches. Description diff against `accfbe2`: 795 to 755, 40 fewer, 1 added. Status back to review.
- 2026-09-08: re-review on the repaired head: AC1-AC5 all met with fresh evidence (795 to 755 blocks, 41 removed and 1 added, each of the 11 deduplication removals read against its survivor; 156 helpers all called; nine ledger rows matching disk; `devtools::test()` 0/0/0 with 9517 passes, `devtools::check()` 0/0/0 Status OK, `air format --check` clean). Consistency gate green (`cairn_validate` exit 0; `document()` no diff; `check_pkgdown()` clean). Three-lens fan-out: ten findings, two fixed on the branch (the stale Review section, a double blank line in race-oracles), five follow-ups, two rejected, one noted; no finding meets the return floor.
- 2026-09-07: plan gate chose a separate pruning milestone over folding it into M74 (see M74's work log); no other alternative weighed here.

## Decisions

## Review

Evidence gathered 2026-09-08 on the `m075-suite-prune` head against branch point
`accfbe2`, PR #85. This replaces the first round's evidence, which was measured
on the pre-repair head.

### Acceptance criteria

- **AC1 — met.** The description diff ran as the criterion names it:
  `test_that_descriptions()` over `tests/testthat/test-*.R` gives 795 at
  `accfbe2` and 755 on the head, keyed per file so that three identically worded
  rng descriptions are told apart — 41 blocks removed, 1 added. 25 leave with
  `test-vignette-citations.R` (22) and `test-drift-manifest.R` (3) under AC4's
  deleted disposition; 5 go under T3's trim rule, all with harness claims (four
  `test-fixture-cache.R` blocks about the build report, one `test-hang-trace.R`
  self-test of its own fixture's cleanup). The remaining 11 each have a
  survivor, read on both sides: the three-into-one merge in
  `test-nested-final-fit-results.R` and the three merges in
  `test-parallel-classify.R` are supersets (the surviving both-fixes block makes
  the plain-pool `check_daemons_can_load()` call and the ladder's `outcome` /
  `cannot_load` / `incompatible` assertions alike); the three rng removals are
  carried by `test-nested-tune-grid-rng.R`'s block plus, for the failed-fold
  zero-row clause, the new race-oracles block and the restored anneal-oracles
  block, both of which assert on a broken fold; the outer-columns trio is
  carried by the two grid-results blocks. The mechanism notes were checked
  against `R/`: every orchestrator calls `nested_loop()`
  (`R/nested-tune-grid.R:592`, `R/nested-tune-race.R:309`,
  `R/nested-tune-sim-anneal.R:268`, `R/nested-tune-bayes.R:244`,
  `R/nested-fit-resamples.R:209`), and `control$save_pred` and `control$extract`
  are read at one site inside `nested_fold_fit()` (`R/nested-tune-grid.R:847`
  and `:860`). The four blocks the first round returned on are present on the
  head.
- **AC2 — met.** The same enumeration gives 795 at `accfbe2` and 755 on the
  head: 40 fewer, against the amended floor of 40 (16 removal-table rows plus
  the 25 the two deleted files take, less the one block added on the head).
- **AC3 — met.** `grep -n -E '^[A-Za-z_.]+ <- function' tests/testthat/helper-*.R`
  enumerates 156 functions. For each, `grep -n -F` over `tests/testthat/*.R`
  finds at least one occurrence that is neither its own defining line nor a
  comment line; none is uncalled. `fixture_cache_reset()` and
  `expect_outer_columns_kept()` are absent from the tree.
- **AC4 — met.** The File ledger carries one row for each of the nine files,
  each naming one of the three dispositions and a reason, and each disposition
  matches disk: `test-vignette-citations.R`, `test-drift-manifest.R` and
  `helper-drift-manifest.R` absent; `test-fixture-cache.R`, `test-hang-trace.R`
  and `test-parallel-classify.R` modified; `test-suite-hygiene.R`,
  `test-ci-workflows.R`, `test-dots-barrier.R` and `test-control-slots.R`
  unmodified against `accfbe2`. All eight blocks removed from the three trimmed
  files appear in the AC1 table. The `test-vignette-citations.R` reason was
  checked against the deleted file: `shelf_dir()` resolved to
  `../../cairn/references`, so rule 6's real-tree half skipped out of the source
  tree like the rest.
- **AC5 — met.** `devtools::test()` at `TESTTHAT_CPUS=6`:
  `FAIL 0 | WARN 0 | SKIP 0 | PASS 9517`. `devtools::check()`: 0 errors,
  0 warnings, 0 notes, 7m 10.6s, `Status: OK`. `air format --check` exit 0 over
  the 13 R files the branch diff touches that still exist (16 touched, 3
  deleted), re-run after the one fix-now whitespace edit below.

### Consistency gate

`cairn_validate.py` exit 0: all 16 checks PASS, `coverage complete` and
`binding criteria` among them; five advisories OK; `references staleness` WARNs
on 18 pages, unrelated to this branch; `release window` OK. `cairn_impact.py`
skipped — the branch touches no `DESIGN.md` principle. The `r-package` profile's
toolchain half: `devtools::document()` leaves no diff in `man/`, `NAMESPACE`,
`R/` or `DESCRIPTION`; `pkgdown::check_pkgdown()` "No problems found";
`README.Rmd` untouched, so `README.md` is in sync; no new top-level files;
`NEWS.md` needs no entry (test-only, no user-visible change); `devtools::check()`
clean as recorded under AC5.

### Independent review (three-lens fan-out)

Executable surface touched (13 `.R` files), so the full fan-out ran: [O]
diff-bug, [S] blame-history, [S] prior-review, none having seen the
implementation. The [O] lens re-derived the description diff independently and
reached the same 795 → 755, 41 removed, 1 added, and read both sides of all 16
non-file-deletion removals. The [S] blame lens found no new history regression.
The [S] prior-review lens ran its existence probe
(`gh api repos/tidymodels/nestedtune/pulls/comments?per_page=1`): one real human
thread exists, on `.github/workflows/pkgdown.yaml`, which this diff does not
touch, so no per-PR walk was warranted; its evidence came from the archived
`## Review` sections.

| # | Lens | Finding | Disposition |
|---|---|---|---|
| F1 | O(1), S-prior | Deleting `test-vignette-citations.R` removes the only guard on author-year citations in `R/` roxygen and in the shipped vignettes: a citation with no shelf page, an emptied `## References` section, or an uncited numeral now passes green. Not a harness test, and the largest capability the branch removes. | **Follow-up** — candidate row. The deletion itself was chosen by the user at the 2026-09-08 question gate and kept at the amendment gate on the corrected ledger facts; what is filed is the coverage gap. |
| F2 | O(4), S-blame, S-prior | Deleting `test-drift-manifest.R` leaves the wire figures cited in `cairn/references/mori-backend-assessment.md` and in the ROADMAP's live mori candidate row unenforced against `benchmarks/mori-wire-manifest.json`. `LESSONS.md` records that of the repo's figure citations only that and the `helper-time-budget.R` ledger were test-enforced. | **Follow-up** — same candidate row. |
| F3 | O(2), S-blame, S-prior | With `expect_outer_columns_kept()` and its three callers gone, every `.predictions` / `.extracts` assertion in the suite passes a `tune::control_grid()`; nothing asserts that the Bayesian, racing and annealing entry points honour `save_pred` and `extract`. The single-site argument was verified (`nested_loop()` → `nested_fold_fit()`, `R/nested-tune-grid.R:847` and `:860`, with `effective_control()` preserving both slots), and `test-control-slots.R` still asserts both slots are documented as kept on each of the five pages, so the residual is drift in an upstream control's slots. | **Follow-up** — same candidate row. |
| F4 | O(3), S-blame, S-prior | `print_fixture_cache_report()` now has no assertions while still running for real in `teardown-fixture-cache.R`; the stream split M57 measured, the built-more-than-once warning line and the empty-report silent case are untested. | **Follow-up** — same candidate row. |
| F5 | O(9) | `DESCRIPTION`'s `Config/testthat/start-first` was not re-ordered, though three rng files listed there lost their most expensive block. No deleted file is named in the list, so nothing is broken; it is a scheduling question. | **Follow-up** — absorbed into the existing ROADMAP candidate on CI leg times, which already names M75's deletions as an unpriced lever. |
| F6 | O(6) | The `## Review` section as committed was the previous round's, with figures (749 / 46 / 0 added) the head no longer matches. | **Fix now** — this rewrite. |
| F7 | O(8) | Double blank line before the by-hand-recipe block in `test-nested-tune-race-oracles.R`, the only such gap in the file; `air format --check` does not collapse it. | **Fix now** — collapsed; `air format --check` re-run clean on the file. |
| F8 | O(5) | Scope → In still lists four removal families the repair pass restored and the branch does not perform (both by-hand-recipe blocks, bayes-oracles' NAMESPACE block, the zero-row `.iter` pair, the `iter = 0` identity). | **Reject** — Scope is the plan's record of what was proposed, not of what happened; the Removals table and the work log carry the outcome, and the archive summary will. Amending a plan-owned section at review would take the gated amendment protocol for no gain. |
| F9 | O(7) | Merging three `test-nested-final-fit-results.R` blocks into one costs failure granularity: an error in the shared prologue now takes all three claims down as one reported failure. | **Reject** — inherent to the merge the milestone planned, and the [O] lens confirmed the merged block is a true superset of the claims. |
| F10 | S-blame(4) | `fixture_cache_reset()` was already uncalled before this branch and `expect_outer_columns_kept()` only by the blocks T2 removed, so T4's removals lose no coverage. | **Noted** — no defect. |

Return floor: no actioned finding demonstrates an acceptance criterion failing,
and none is a load-bearing defect in what the package does for its users. F1–F4
are reductions in test coverage that follow from the deletions the milestone was
planned and gated to make; they are filed rather than fixed.

### Outcome

Every acceptance criterion is met on fresh evidence and the consistency gate is
green. Ten findings were reported across the three lenses: two fixed on the
branch, five filed as follow-ups, two rejected with reason, one noted. The
milestone goes to the merge-approval gate.
