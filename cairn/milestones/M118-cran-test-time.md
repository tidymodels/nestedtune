# M118: The test step CRAN runs uses at most 120 s of CPU, and CI still runs every slow test

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP2
- **Resolves:** —
- **Surface tier:** internal — it changes test skips, CI configuration and a benchmark record, which no user of the package relies on
- **Branch/PR:** m118-cran-test-time

## Goal

Under CRAN's conditions, the test step of `R CMD check --as-cran` uses at most 120 s of CPU. The CI check matrix still runs every test that this milestone skips on CRAN.

## Scope

**In:** A test helper, `skip_heavy_on_cran()`, runs a block only when `NOT_CRAN` or `NESTEDTUNE_FULL_SUITE` is `"true"`, and skips it otherwise. The helper goes on the files outside the CRAN smoke layer. The smoke layer is the input-refusal (`*-checks.R`) files, the reader files, and one end-to-end run per exported `nested_*` function. Oracle, RNG, time-series and print-shape files leave the CRAN set. Every `R-CMD-check.yaml` leg sets `NESTEDTUNE_FULL_SUITE: true`. `R-CMD-check-hard.yaml` leaves it unset, so that job runs the CRAN subset. A committed record, `benchmarks/cran-check-timing.md`, holds the CRAN-conditions timings of the branch point and the head, with the command that produced them.

**Out:** Vignette build time (47 s at the branch point) stays as is. The plan gate chose this, and a candidate row holds the option to move the slowest guide to a website-only article. Help-page examples (19 s) stay as is. The mirai daemon tests already skip on CRAN through `skip_if_no_daemons()` and are unchanged. They still run under covr and the devel-vctrs job, as today. Work that removes or merges tests to make the full suite faster belongs to the suite-time candidate rows and M113's lineage. The release walk (`cran-comments.md`, `DESCRIPTION`, `NEWS.md`) belongs to `/cairn-release`.

## Acceptance criteria

- [x] AC1: Under CRAN conditions, the median of three runs of the `Running 'testthat.R'` line reports at most 120 s of CPU time. CRAN conditions are `NOT_CRAN` unset, `TESTTHAT_CPUS=2`, and `R CMD check --as-cran --no-manual` on the built tarball, on the maintainer's Mac. The branch point read 560 s CPU and 278 s elapsed on 2026-09-27 at `fde0ba1`.
- [x] AC2: In the same three runs, the median elapsed time of the whole check is at most 200 s (branch point 370 s). In each run, the CPU time of the test step is below 2.5 times its elapsed time.
- [x] AC3: With `NOT_CRAN=true`, as `devtools::test()` sets it, the pass count of the suite is at least the branch point's under the same settings. Every added pass comes from a test added on the branch. The skip count is no higher.
- [x] AC4: `git diff <branch point> -- tests/` deletes and changes no line. In each file that exists at the branch point, every added line outside the `test_that()` blocks the diff adds, and outside the helper functions it adds whose names do not occur under `tests/` at the branch point, is a `skip_heavy_on_cran()` call, a comment or a blank line. A `tests/testthat/helper-*.R` file defines `skip_heavy_on_cran()`. With both `NOT_CRAN` and `NESTEDTUNE_FULL_SUITE` unset, it skips. With either one set to `"true"`, it runs the block.
- [x] AC5: For every `nested_*` function that `NAMESPACE` exports, at least one `test_that()` block calls it and carries no skip that fires under CRAN conditions. The AC1 runs report 0 failures.
- [x] AC6: Every leg of `R-CMD-check.yaml` sets `NESTEDTUNE_FULL_SUITE: true`, and `R-CMD-check-hard.yaml` does not set it.
- [x] AC7: `devtools::test()` passes with 0 failures. `devtools::check()` gives 0 errors and 0 warnings. Every gating prose sweep that `Rscript benchmarks/sweep-prose.R --list-gating` prints is clean.

## Coverage

- AC1 → T3, T5
- AC2 → T5
- AC3 → T1, T3, T5
- AC4 → T1, T3
- AC5 → T2, T3
- AC6 → T4
- AC7 → T6

## Tasks

- [x] T1: Write `skip_heavy_on_cran()` in a new `tests/testthat/helper-cran.R`. Add a test file that fires both arms under `withr::local_envvar()` and asserts the class and message of the skip condition.
- [x] T2: List the CRAN smoke layer file by file. For each exported `nested_*` function, name the block that stays unskipped and calls it. Record the list in the Decisions section of this file.
- [x] T3: Apply `skip_heavy_on_cran()` to every block outside the smoke layer, at the top of each file or of each block. Start with the heaviest files in the per-file table in `benchmarks/cran-check-timing.md`. Stop when a CRAN-conditions run meets AC1.
- [x] T4: Set `NESTEDTUNE_FULL_SUITE: true` in the `env:` of the check job in `R-CMD-check.yaml`, and leave `R-CMD-check-hard.yaml` unset. Add a block to `test-ci-workflows.R` that reads both files. Update the yaml comments and the PROFILE test-doctrine slot where they say which job runs which tests.
- [x] T5: Write `benchmarks/cran-check-timing.md`. Record the command, the machine, the branch point's figures and per-file table, and three head runs. For each run, record the CPU and elapsed time of `Running 'testthat.R'`, the elapsed time of the whole check, and the pass and skip counts.
- [x] T6: Run the verify slot, `devtools::check()` and the gating prose sweeps. The slowest `R-CMD-check.yaml` step of the PR's CI run is read against its cap at review, when the branch is first pushed.

## Work log

- 2026-09-27: created by /milestone-plan.
- 2026-09-27: baseline under CRAN conditions at `fde0ba1`: check 370 s elapsed, tests 560 s CPU and 278 s elapsed, examples 19 s, vignettes 47 s, 10840 pass and 81 skip. Test time is spread out, and the slowest file takes 31 s of 541 s.
- 2026-09-27: criteria audit (reduced mode, fresh [O] reader) returned 8 findings, all fixed before the gate. AC3 allows the new passes of the helper test. AC4 counts net skips and blocks, not added lines. AC5 covers the `nested_*` exports in NAMESPACE and reads test source, not `testthat.Rout`. AC6 drops its "full suite" clause. AC7 names commands, not the profile slot.
- 2026-09-27: plan gate chose a package switch (`NESTEDTUNE_FULL_SUITE`) over plain `skip_on_cran()` with `NOT_CRAN=true` on the CI matrix. The plain form also starts the mirai daemon tests on all five legs, near their step caps. Falsified by the daemon tests proving cheap and stable across the matrix.
- 2026-09-27: plan gate chose a stated smoke layer over skipping the slowest files until the bar is met, because a stated layer gives the CRAN set a one-sentence rule. Falsified by the smoke layer alone using more than 120 s of CPU.

- 2026-09-27: implement started on `m118-cran-test-time`; no question gate, since the plan gate settled the switch, the bar and the smoke-layer rule.
- 2026-09-27: minor amendment: T6's CI read moves to review, because the branch is first pushed at review's merge step.
- 2026-09-27: T1 done: `helper-cran.R` and `test-skip-heavy.R` (4 blocks, 5 expectations pass). Minor edit: the test saves and restores the variables by hand, because `withr` is not a dependency and adding it needs a gate.
- 2026-09-27: T2 and T3 done. A [S] subagent added the file-level call to 42 files with the Edit tool. In 8 files it split a function from its comment, and I moved those calls above the comment. `test-nested-final-fit-sim-anneal.R` then went back into the smoke layer. `devtools::test()` gives 998 blocks, 11508 pass, 0 fail, 0 skip. One CRAN-conditions run of the 42-file set read tests 92 s CPU and 45 s elapsed, and the whole check 136 s.
- 2026-09-27: T4 done. `R-CMD-check.yaml` sets `NESTEDTUNE_FULL_SUITE: true` in the job `env:`, and the hard job has a comment and no setting. The new `test-ci-workflows.R` block passes, and it fails with `false` planted in place of `true`. PROFILE's test-doctrine line names the switch.
- 2026-09-27: T5 done. `benchmarks/cran-check-timing.md` holds three CRAN-conditions runs at `2af34dc`: tests 94, 96 and 92 s CPU, whole check 134.3, 133.9 and 133.0 s, ratio at most 2.09, 6540 pass and 0 fail each. Full suite: 994 blocks and 11503 pass at `2e50d31`, 1000 and 11512 at the head, 0 skip on both.
- 2026-09-27: T6 done. `devtools::document()` leaves no diff, the six gating prose sweeps are clean, and `devtools::check()` gives 0 errors, 0 warnings and 0 notes at `9def2f5`.
- 2026-09-27: claim audit: not owed — internal tier.
- 2026-09-27: status set to review.
- 2026-09-27: review: AC1-AC3 and AC5-AC7 verified with fresh evidence. AC4 fails as written, because the helper's own `skip(` and `return(` raise its count and a new source-reading block skips through `skip_if_not()`. 16 findings logged in the Review section. F1 says CI already sets `NOT_CRAN` true, so the switch has no effect there.
- 2026-09-27: amendment return: AC4 — "This branch excludes no test block that ran under CRAN conditions at the branch point, except through `skip_heavy_on_cran()`, which a `tests/testthat/helper-*.R` file defines. The evidence is `git diff <branch point> -- tests/`, read per file. Outside the body of `skip_heavy_on_cran()`, the net count of `skip_on_cran()`, `skip_if_no_daemons()`, `skip_if()`, `skip()` and early `return()` calls must not rise."
- 2026-09-27: status set to in-progress for the AC4 amendment alone. The findings wait for triage at the re-review gate. F1 comes first, because it decides whether any CI job runs the CRAN subset.
- re-audit: AC4 (reduced) — bounded-promise: the five counted skip forms stand in for "excludes no test block", and the added `skip_if_not()` escapes them; proportionality: "ran under CRAN conditions at the branch point" needs a CRAN-conditions run to enumerate; instrument: "A test shows" binds a test, not the helper.
- 2026-09-27: mini gate chose a diff-line wording for AC4, which is narrower than the returned wording. The reader's draft exempted only new blocks, so I added new helper functions, because `test-ci-workflows.R` adds `full_suite_lines()` outside any block.
- re-audit: AC4 (reduced) — bounded-promise: a new helper could reuse an old helper's name and change unchanged blocks; proportionality: nothing; instrument: nothing.
- 2026-09-27: second re-audit is the stop, so the user chose the narrowing to helper names absent under `tests/` at the branch point. AC4 now reads as in the criteria list. The findings still wait for triage at the re-review gate.
- 2026-09-27: status set to review.
- 2026-09-27: re-review gate triage applied: F1 prose fix, O3, O8, O9, O10, O12 and O13 fixed, O7 to a candidate row. Checkpoint before the full suite and a CRAN-conditions check re-verify the fixes.

## Decisions

- 2026-09-27 (T2): the CRAN smoke layer is decided per file, by class first and time second. Every oracle, RNG, time-series and print-or-plot-shape file skips on CRAN at any cost. Of the rest, the `*-checks.R` files, the `*-readers.R` files and the six reader files (`collect-readers`, `collect-metrics-wide`, `extract-procedure`, `nested-final-fit-extract`, `nested-final-fit-predict`, `predict-results`) stay. Any other file under 2 s in the branch point's CRAN-conditions run also stays. `test-nested-final-fit-sim-anneal.R` (4.4 s) stays too, because no other kept block completes an annealing run. So 41 files skip through a file-level `skip_heavy_on_cran()` call, and 49 run on CRAN. The end-to-end run per export: `nested_resamples()` in `test-nested-resamples-specs.R`; `nested_tune_grid()` in `test-collect-metrics-wide.R`; `nested_tune_bayes()` in `test-nested-tune-bayes-checks.R` ("the three acquisition functions tune offers are accepted"); both racers in `test-nested-tune-race-checks.R` ("the final fit on a racing result asks for the race's packages first", through `race_final_results()`); `nested_tune_sim_anneal()` in `test-nested-final-fit-sim-anneal.R`; `nested_fit_resamples()` in `test-nested-final-fit-resamples.R`; `nested_workflow_map()` in `test-nested-workflow-map-readers.R`; `nested_final_fit()` in `test-nested-final-fit-set.R`.
- 2026-09-27 (review, O3): three files that call themselves oracle files stay on CRAN, against the class rule above: `test-nested-resamples-identity.R` (0.3 s), `test-nested-resamples-memory.R` (1.2 s) and `test-parallel-payload.R` (0.3 s). The T2 pass kept them by the 2 s rule, and the AC1 runs include them. They stay, and this line corrects the record.

## Review

Fresh evidence, 2026-09-27, at `150d92f`. The default branch had not moved since the branch point (`2e50d31`), so no merge was needed. The three CRAN-conditions runs used the command in `benchmarks/cran-check-timing.md` on the maintainer's Mac, from one tarball built at the head.

- AC1: the three `Running 'testthat.R'` lines read 100 s, 91 s and 92 s of CPU. The median is 92 s, against a bar of 120 s (branch point 560 s). During run 1 the three review subagents were also reading files, which probably explains its higher figure.
- AC2: the whole check took 140.2 s, 131.8 s and 133.1 s. The median is 133.1 s, against a bar of 200 s (branch point 370 s). The test-step CPU to elapsed ratios are 100/48 = 2.08, 91/44 = 2.07 and 92/45 = 2.04, each below 2.5.
- AC3: `devtools::test()` at the head gives 1000 blocks, 11512 pass, 0 fail and 0 skip. The branch point's record at `2e50d31` is 994 blocks, 11503 pass and 0 skip. The 9 added passes are the 5 in the new `test-skip-heavy.R` and the 4 in the two new `test-ci-workflows.R` blocks. The source count of `test_that(` under `tests/` goes from 979 to 985.
- AC4, not met as written. `git diff 2e50d31 -- tests/` has 200 insertions and 0 deletions over 44 files, so no `test_that(` call and no skip is removed. Counts of `skip_on_cran()`, `skip_if_no_daemons()` and `skip_if()` are unchanged in every file. Two counts named in the criterion rise, and both come from the body of `skip_heavy_on_cran()` in `helper-cran.R`: one `testthat::skip(` and one early `return(invisible(TRUE))`. The new block in `test-ci-workflows.R` on the check matrix also skips under CRAN conditions, through `skip_if_not(file.exists(...))`. It skips because the built package has no `.github/`. Three blocks already in that file skip the same way. `skip_if_not(` is not in the criterion's list, but the first sentence says no block is excluded except through the helper. The two-case helper test passes (`test-skip-heavy.R`, 4 blocks). The work meets the plan's intent, so the fault is in the criterion's wording, and it goes back for a gated amendment.
- AC5: NAMESPACE exports 9 `nested_*` functions. A parse of the test files with no file-level `skip_heavy_on_cran()` lists the blocks that call each function. A counted block calls the function directly or through a helper, and it has no skip that fires on CRAN. The counts are `nested_final_fit` 56, `nested_fit_resamples` 18, `nested_resamples` 105, `nested_tune_bayes` 20, `nested_tune_grid` 131, `nested_tune_race_anova` 6, `nested_tune_race_win_loss` 4, `nested_tune_sim_anneal` 17 and `nested_workflow_map` 34. All three AC1 runs report `[ FAIL 0 | WARN 0 | SKIP 107 | PASS 6540 ]`.
- AC6: `R-CMD-check.yaml` sets `NESTEDTUNE_FULL_SUITE: true` once, in the job-level `env:` of the one matrix job, so all five legs get it. `R-CMD-check-hard.yaml` names the variable only in a comment.
- AC7: `devtools::test()` gives 0 failures (see AC3). `devtools::check()` gives 0 errors, 0 warnings and 0 notes. The six commands that `sweep-prose.R --list-gating` prints each exit 0 and print "clean".

Consistency gate: `cairn_validate.py` exits 0, with 18 reference-staleness advisories that predate this branch. `devtools::document()` leaves no diff. `pkgdown::check_pkgdown()` finds no problems. `devtools::check()` is clean, as AC7 records. No file a user reads changed, so NEWS needs no entry. No DESIGN principle changed, so `cairn_impact` is not owed.

Findings, most severe first. Each one waits for triage at the re-review gate, except where a line says otherwise.

- F1 (orchestrator, verified): CI already runs with `NOT_CRAN` set to true. `r-lib/actions/setup-r` puts `NOT_CRAN: true` in the environment of every later step. The `check-r-package` step logs show it on all five `R-CMD-check.yaml` legs (run 36062063637). They also show it on the hard job (run 36062063647), whose tests took 1302 s of CPU. So `NESTEDTUNE_FULL_SUITE` changes nothing in CI, and the hard job runs the full suite, not the CRAN subset. The mirai daemon tests already run on all five legs. The plan gate's reason for a second variable, the `helper-cran.R` header, both yaml comments and the new PROFILE sentence all state the opposite. No CI job runs the CRAN subset.
- O2: AC4's wording fails, as recorded above. This is the amendment return in the work log.
- O1: the coverage job can skip the 41 files, the reviewer said. Rejected: its log (run 36062063607) shows `NOT_CRAN: true`, so every test runs there.
- S1 (blame lens): the hard-dependency job loses the 41 files. F1 refutes it today. If a fix for F1 sets `NOT_CRAN: false` there, it becomes true. About 26 of the 41 files have no `skip_if_not_installed()` guard.
- O3: the T2 Decision says every oracle file skips on CRAN, but `test-nested-resamples-identity.R`, `test-nested-resamples-memory.R` and `test-parallel-payload.R` call themselves oracle files and stay.
- O4: PROFILE says `TESTTHAT_CPUS` is set in "the four workflows that run the whole suite". This is true under F1. If the hard job gets the CRAN subset, it becomes false.
- O5: the hard job's 30-minute cap comment measures a full-suite run. The same dependence on F1 applies.
- O14: nothing shows the switch reaching `R CMD check` in CI. F1 shows that it cannot matter there.
- O6: `Config/testthat/start-first` queues about ten files that now skip at once under CRAN conditions. The effect has not been measured.
- O7: DESCRIPTION allows `testthat (>= 3.0.0)`. testthat 3.2.3 fixed an error from `skip()` called outside a test, and the 41 file-level calls use that path.
- O8: `skip_heavy_on_cran()` accepts only `NOT_CRAN == "true"`, while testthat also accepts "TRUE" and "T".
- O9: `test-skip-heavy.R:17` is 87 characters, over air's 80.
- O10: in `test-nested-final-fit-identity.R:14` and `test-nested-results-agreement.R:13`, the skip call sits between a comment and the block that the comment describes.
- O11: the T2 Decision names an indirect witness for the two racers, although direct calls exist in other kept files.
- O12: the `helper-cran.R` header describes a narrower kept set than the T2 Decision.
- O13: `benchmarks/cran-check-timing.md` calls both `fde0ba1` and `2e50d31` "branch point" and does not say that only a plan commit separates them.
- Prior-review lens: no prior-review evidence touches this diff.

Re-review after the AC4 amendment, 2026-09-27, at `e69aee7`. The default branch is still at the branch point `2e50d31`. `git diff 150d92f e69aee7` outside `cairn/` is empty, so the evidence for AC1-AC3 and AC5-AC7 above still describes the head. The review fan-out above read the same code, so no new lenses ran.

Triage at the re-review gate:

- F1: fix now, prose only. The `helper-cran.R` header, both yaml comments, the PROFILE sentence, the `test-ci-workflows.R` comment and block title, and the full-suite paragraph of `benchmarks/cran-check-timing.md` now say that `setup-r` sets `NOT_CRAN: true` in every CI job, so every job runs the full suite. No behavior changed. The older hard-yaml line 41 ("the suite skips every daemon test") predates this branch and stays.
- O1: rejected at the first review. O2: resolved by the AC4 amendment.
- S1, O4, O5: no change. Each one depended on the hard job getting the CRAN subset, and the F1 disposition keeps the full suite there.
- O3: fix now, a dated line in Decisions.
- O6: rejected. A file that skips at its top finishes at once, so its place in the queue costs almost nothing.
- O7: follow-up, a candidate row in ROADMAP.
- O8: fix now. The helper reads each variable with `as.logical()`, and a new block tests "TRUE" and "T".
- O9: fix now, the long line wrapped.
- O10: fix now. In both files, the skip call moved above the section comment.
- O11: rejected. The Decision names a valid witness, and the direct witnesses do not change the smoke layer.
- O12: fix now, in the new `helper-cran.R` header.
- O13: fix now. The timing record says that `2e50d31` follows `fde0ba1` with a plan commit only.
- O14: rejected, covered by F1.

- AC4: `git diff 2e50d31 -- tests/` has 200 insertions and 0 deletions over 44 files. Two files are new: `helper-cran.R` and `test-skip-heavy.R`. In 41 of the 42 changed files, each added line is `skip_heavy_on_cran()` or a blank line. In `test-ci-workflows.R`, the added lines are two new `test_that()` blocks, the new helper `full_suite_lines()`, comments and blank lines. `git grep full_suite_lines 2e50d31 -- tests/` finds nothing. `helper-cran.R` defines `skip_heavy_on_cran()`. `test-skip-heavy.R` passes 5 expectations over the unset case and each variable set to `"true"`.
