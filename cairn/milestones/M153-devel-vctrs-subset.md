# M153: The devel-vctrs job runs the vctrs test files on each push and the whole suite each week

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — a CI job that gates nothing
- **Branch/PR:** m153-devel-vctrs-subset

## Goal

On a push or pull request, the `devel-vctrs.yaml` job runs only the test files that exercise vctrs. On its weekly schedule, it runs the whole suite.

## Scope

**In:**
- `.github/workflows/devel-vctrs.yaml` watches one experimental vctrs generic, `vec_cbind_frame_ptype()` (D-033). It is not a required check. Today it runs the whole suite on every push and pull request, in 29 to 45 minutes.
- On a `push` or `pull_request` event, the test step runs `testthat::test_local()` with `filter = "^(vctrs-compat|dplyr-compat|nested-results-set-compat)$"`. testthat matches the filter against each file name with `test-` and `.R` removed, so it picks `test-vctrs-compat.R`, `test-dplyr-compat.R` and `test-nested-results-set-compat.R`.
- On the `schedule` event, the step runs the whole suite, as it does today.
- A `workflow_dispatch` input `full`, of type boolean and default `true`, picks between the two. So both paths can run on demand.
- The workflow's header comment states the split.
- One D-entry narrows D-116's clause that every other CI job running the tests runs the full suite. This job runs it only on its schedule.

**Out:**
- The five check legs, the coverage job and the CRAN-condition jobs keep what D-116 fixed.
- Which files count as vctrs-facing is set once here. A later file that needs the watch adds itself to the filter.

## Acceptance criteria

- [ ] AC1: Start a `workflow_dispatch` run of the branch's workflow with `full=false`. Its test step's log reports results for the three files in Scope In and for no other test file.
- [ ] AC2: Start a `workflow_dispatch` run of the branch's workflow with `full=true`. Its test step's log reports results for every `tests/testthat/test-*.R` file at the head commit.
- [ ] AC3: In the head workflow, if the event is `push` or `pull_request`, or `workflow_dispatch` with `full` false, the test step runs the filter. If the event is `schedule`, or `workflow_dispatch` with `full` true, the test step runs the whole suite.
- [ ] AC4: `cairn/DECISIONS.md` holds one new entry that names the D-116 clause it narrows.
- [ ] AC5: The profile's `verify` slot is clean at the head.

## Coverage

- AC1 → T1, T3
- AC2 → T1, T3
- AC3 → T1
- AC4 → T4
- AC5 → T2

## Tasks

- [x] T1: Edit `devel-vctrs.yaml`: add the `full` input, and make the test step choose between the filter and the whole suite.
- [x] T2: Run the `verify` slot.
- [x] T3: Push the branch, and start both `workflow_dispatch` runs with `gh workflow run devel-vctrs.yaml --ref <branch> -f full=<value>`. Record each run id and the test files its log reports.
- [x] T4: Write the D-entry.

## Work log

- 2026-10-21: created by /milestone-plan.
- 2026-10-21: tier check: milestone — a CI change that narrows a recorded decision (D-116).
- 2026-10-21: idea vet: one concern, that dplyr and tibble build on vctrs, so a development-vctrs break can reach files outside the three; answered at the question set, which chose the subset on each push with the whole suite weekly.
- 2026-10-21: question set: what the job runs on push and pull request — the three vctrs-facing files, with the whole suite weekly and on demand.
- 2026-10-21: question set: may implement start two `workflow_dispatch` runs on the branch — yes, both.
- 2026-10-21: plan gate chose the subset on each push over weekly-only runs, because a push still checks the watched generic at once; falsified by a development-vctrs break that the subset misses and only the weekly run catches.
- 2026-10-21: criteria audit (reduced, fresh Opus reader): four findings, all fixed. The filter is now a regex on file names without `test-` and `.R`; AC2's domain is the head's `test-*.R` files; AC3 covers all four events; the `ci-usage.py` clause was dropped, since its exit status depends on `gh` and the network. A D-entry task was added, because the change narrows D-116.
- 2026-10-22: status in-progress; branch m153-devel-vctrs-subset cut from origin/main at 1d3d2fe5.
- 2026-10-22: T1 done. The step reads a `FULL_SUITE` env value, true on `schedule` or on a dispatch with `full` true, and passes the filter to `test_local()` otherwise; it prints `Whole suite: <TRUE|FALSE>` so the log shows the path. The filter, read against testthat 3.3.2's `filter_test_scripts()`, picks the three files out of 105 locally. PROFILE.md's devel-vctrs sentence now states the split.
- 2026-10-22: T3 started. Branch pushed. The two dispatches started together, and the workflow's `concurrency` block (keyed on workflow and ref, cancelling on a non-default ref) cancelled the `full=false` run 39861928720 when the `full=true` run 39861932693 started. Cancelled 39861932693 too; the runs go one at a time, `full=false` first (39861993834).
- 2026-10-22: T4 done (out of order, while T3's runs wait): D-119 narrows D-116's every-other-job-full-suite clause for this job.
- 2026-10-22: T3 run 39861993834 (`full=false`, head 6d52f81f) green: the step printed `Whole suite: FALSE` and reported dplyr-compat, nested-results-set-compat and vctrs-compat and no other file (988 passes, 16.9 s); the job took 2m03s. Full run 39862460114 started.
- 2026-10-22: T2 done. `devtools::test()` at 6d52f81f: FAIL 0, PASS 13367. No `.R`, roxygen, vignette or README file changed, so `air`, `document()` and the prose sweeps are not owed.
- 2026-10-22: T3 done. Run 39862460114 (`full=true`, head 6d52f81f) green: the step printed `Whole suite: TRUE`, and its reported contexts match the 105 `tests/testthat/test-*.R` files in `git ls-tree 6d52f81f` exactly (FAIL 0, PASS 13367, 2133.9 s); the job took 37m36s.
- 2026-10-22: claim audit: not owed — internal tier
- 2026-10-22: status review; all tasks checked, verify clean at ba523f66 (later commits are tracking-only).

## Decisions

## Review
