# M118: The test step CRAN runs uses at most 120 s of CPU, and CI still runs every slow test

- **Status:** in-progress
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

- [ ] AC1: Under CRAN conditions, the median of three runs of the `Running 'testthat.R'` line reports at most 120 s of CPU time. CRAN conditions are `NOT_CRAN` unset, `TESTTHAT_CPUS=2`, and `R CMD check --as-cran --no-manual` on the built tarball, on the maintainer's Mac. The branch point read 560 s CPU and 278 s elapsed on 2026-09-27 at `fde0ba1`.
- [ ] AC2: In the same three runs, the median elapsed time of the whole check is at most 200 s (branch point 370 s). In each run, the CPU time of the test step is below 2.5 times its elapsed time.
- [ ] AC3: With `NOT_CRAN=true`, as `devtools::test()` sets it, the pass count of the suite is at least the branch point's under the same settings. Every added pass comes from a test added on the branch. The skip count is no higher.
- [ ] AC4: This branch excludes no test block under CRAN conditions except through `skip_heavy_on_cran()`, which a `tests/testthat/helper-*.R` file defines. The evidence is `git diff <branch point> -- tests/`, read per file. In it, the net count of `skip_on_cran()`, `skip_if_no_daemons()`, `skip_if()`, `skip()` and early `return()` calls must not rise. The count of `test_that(` calls must not fall. A test shows two cases. With both variables unset, the helper skips. With either one set to `"true"`, the helper runs the block.
- [ ] AC5: For every `nested_*` function that `NAMESPACE` exports, at least one `test_that()` block calls it and carries no skip that fires under CRAN conditions. The AC1 runs report 0 failures.
- [ ] AC6: Every leg of `R-CMD-check.yaml` sets `NESTEDTUNE_FULL_SUITE: true`, and `R-CMD-check-hard.yaml` does not set it.
- [ ] AC7: `devtools::test()` passes with 0 failures. `devtools::check()` gives 0 errors and 0 warnings. Every gating prose sweep that `Rscript benchmarks/sweep-prose.R --list-gating` prints is clean.

## Coverage

- AC1 → T3, T5
- AC2 → T5
- AC3 → T1, T3, T5
- AC4 → T1, T3
- AC5 → T2, T3
- AC6 → T4
- AC7 → T6

## Tasks

- [ ] T1: Write `skip_heavy_on_cran()` in a new `tests/testthat/helper-cran.R`. Add a test file that fires both arms under `withr::local_envvar()` and asserts the class and message of the skip condition.
- [ ] T2: List the CRAN smoke layer file by file. For each exported `nested_*` function, name the block that stays unskipped and calls it. Record the list in the Decisions section of this file.
- [ ] T3: Apply `skip_heavy_on_cran()` to every block outside the smoke layer, at the top of each file or of each block. Start with the heaviest files in the per-file table in `benchmarks/cran-check-timing.md`. Stop when a CRAN-conditions run meets AC1.
- [ ] T4: Set `NESTEDTUNE_FULL_SUITE: true` in the `env:` of the check job in `R-CMD-check.yaml`, and leave `R-CMD-check-hard.yaml` unset. Add a block to `test-ci-workflows.R` that reads both files. Update the yaml comments and the PROFILE test-doctrine slot where they say which job runs which tests.
- [ ] T5: Write `benchmarks/cran-check-timing.md`. Record the command, the machine, the branch point's figures and per-file table, and three head runs. For each run, record the CPU and elapsed time of `Running 'testthat.R'`, the elapsed time of the whole check, and the pass and skip counts.
- [ ] T6: Run the verify slot, `devtools::check()` and the gating prose sweeps. The slowest `R-CMD-check.yaml` step of the PR's CI run is read against its cap at review, when the branch is first pushed.

## Work log

- 2026-09-27: created by /milestone-plan.
- 2026-09-27: baseline under CRAN conditions at `fde0ba1`: check 370 s elapsed, tests 560 s CPU and 278 s elapsed, examples 19 s, vignettes 47 s, 10840 pass and 81 skip. Test time is spread out, and the slowest file takes 31 s of 541 s.
- 2026-09-27: criteria audit (reduced mode, fresh [O] reader) returned 8 findings, all fixed before the gate. AC3 allows the new passes of the helper test. AC4 counts net skips and blocks, not added lines. AC5 covers the `nested_*` exports in NAMESPACE and reads test source, not `testthat.Rout`. AC6 drops its "full suite" clause. AC7 names commands, not the profile slot.
- 2026-09-27: plan gate chose a package switch (`NESTEDTUNE_FULL_SUITE`) over plain `skip_on_cran()` with `NOT_CRAN=true` on the CI matrix. The plain form also starts the mirai daemon tests on all five legs, near their step caps. Falsified by the daemon tests proving cheap and stable across the matrix.
- 2026-09-27: plan gate chose a stated smoke layer over skipping the slowest files until the bar is met, because a stated layer gives the CRAN set a one-sentence rule. Falsified by the smoke layer alone using more than 120 s of CPU.

- 2026-09-27: implement started on `m118-cran-test-time`; no question gate, since the plan gate settled the switch, the bar and the smoke-layer rule.
- 2026-09-27: minor amendment: T6's CI read moves to review, because the branch is first pushed at review's merge step.

## Decisions

## Review
