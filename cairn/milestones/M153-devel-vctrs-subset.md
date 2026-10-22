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

- [x] AC1: Start a `workflow_dispatch` run of the branch's workflow with `full=false`. Its test step's log reports results for the three files in Scope In and for no other test file.
- [x] AC2: Start a `workflow_dispatch` run of the branch's workflow with `full=true`. Its test step's log reports results for every `tests/testthat/test-*.R` file at the head commit.
- [x] AC3: In the head workflow, if the event is `push` or `pull_request`, or `workflow_dispatch` with `full` false, the test step runs the filter. If the event is `schedule`, or `workflow_dispatch` with `full` true, the test step runs the whole suite.
- [x] AC4: `cairn/DECISIONS.md` holds one new entry that names the D-116 clause it narrows.
- [ ] AC5: The profile's `verify` slot is clean at the head.

## Coverage

- AC1 → T1, T3, T5
- AC2 → T1, T3, T5
- AC3 → T1, T5
- AC4 → T4, T5
- AC5 → T2, T5

## Tasks

- [x] T1: Edit `devel-vctrs.yaml`: add the `full` input, and make the test step choose between the filter and the whole suite.
- [x] T2: Run the `verify` slot.
- [x] T3: Push the branch, and start both `workflow_dispatch` runs with `gh workflow run devel-vctrs.yaml --ref <branch> -f full=<value>`. Record each run id and the test files its log reports.
- [x] T4: Write the D-entry.
- [x] T5: Review return 1: bring `cairn/PROFILE.md` under its 120-line cap, fix the pass-1 fix-now findings (concurrency group keyed on the switch, header and PROFILE wording, D-119), run `verify`, and rerun both `workflow_dispatch` runs on the new head.

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
- 2026-10-22: review return 1: `cairn_validate.py` weight caps FAIL, `cairn/PROFILE.md` at 121 lines (cap <120). The pass-1 fix-now findings (Review section: diff-bug #1-#7) ride the same return, since #1 changes the workflow and AC1 and AC2 then need fresh dispatch runs.
- 2026-10-22: minor amendment: T5 added for review return 1; Coverage lines gain T5.
- 2026-10-22: T5 edits: PROFILE.md reflowed to 119 lines, its worker-count sentence now says devel-vctrs runs the whole suite only on schedule and full dispatch; workflow concurrency group keyed on the `FULL_SUITE` expression (GitHub docs read this session: a newly queued run cancels the pending one in its group, `cancel-in-progress` touches only running ones); header and timeout comments reworded per pass-1 findings. D-119 corrected in place, not superseded, because it exists only on this unmerged branch.
- 2026-10-22: T5 run 39867888167 (`full=false`, head 813d3a66) green: `FULL_SUITE: false`, `Whole suite: FALSE`, result table lists dplyr-compat, nested-results-set-compat and vctrs-compat only (988 passes); job 2m38s. It ran at the same time as full run 39867891668 and neither cancelled the other.
- 2026-10-22: T5 verify: `devtools::test()` at a247b519 FAIL 0, PASS 13367; no `R/`, `tests/`, DESCRIPTION or NAMESPACE change since (`git diff --stat a247b519 HEAD` empty on those paths), and no `.R` file changed, so `air` is not owed.
- 2026-10-22: T5 done. Run 39867891668 (`full=true`, head 813d3a66) green: `FULL_SUITE: true`, `Whole suite: TRUE`; its reported contexts match the 105 `test-*.R` files in `git ls-tree 813d3a66` exactly (FAIL 0, PASS 13367, 2090.0 s); job 36m43s.
- 2026-10-22: claim audit: not owed — internal tier
- 2026-10-22: status review; T5 checked, verify clean, validator weight caps PASS.

## Decisions

## Review

- AC1 evidence (2026-10-22): run 39861993834, `workflow_dispatch` with `full=false` on head 6d52f81f (no `.github`, `tests` or `R` change since, `git diff --stat 6d52f81f HEAD`), success. Re-read log: the step printed `Whole suite: FALSE` and its result table lists dplyr-compat (247), nested-results-set-compat (212) and vctrs-compat (529) and no other context; FAIL 0, PASS 988. Pass.
- AC2 evidence (2026-10-22): run 39862460114, `workflow_dispatch` with `full=true` on head 6d52f81f, success. Re-read log: `Whole suite: TRUE`; the 105 contexts in its result table diff empty against the 105 `test-*.R` names from `git ls-tree HEAD tests/testthat/`; FAIL 0, PASS 13367. Pass.
- AC3 evidence (2026-10-22): head `devel-vctrs.yaml` lines 145-157: `FULL_SUITE` is `github.event_name == 'schedule' || (github.event_name == 'workflow_dispatch' && inputs.full)`; the R step sets `full` only when that value is the string `true`, and passes the three-file filter otherwise, `NULL` (every file) when full. So `push` and `pull_request` (both terms false) take the filter, `schedule` the whole suite, and a dispatch follows `full`. The two dispatch logs show the rendered value: `FULL_SUITE: false` in 39861993834, `FULL_SUITE: true` in 39862460114. Pass.
- AC4 evidence (2026-10-22): `git diff origin/main...HEAD -- cairn/DECISIONS.md` adds one `### D-` heading, D-119, whose heading and closing parenthesis name D-116's every-other-job-full-suite clause as the clause it narrows. Pass.
- gate (pass 1): `cairn_validate.py` FAIL `weight caps`: `cairn/PROFILE.md` 121 lines (cap <120), from T1's added sentence. Gate failure; review return 1.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: the `concurrency` group (workflow and ref) is shared by whole-suite and three-file runs, so a pending scheduled run on main is replaced by a newer push run, and on a branch a push cancels a running full dispatch; D-119 says a break outside the three files shows on the next weekly or full run — fix now (key the group on the full/subset switch too; record in header and D-119).
- diff-bug #2: header lines 19-21 and PROFILE.md call the three files the ones that exercise vctrs, but `test-nested-tune-bayes-oracles.R:387-388` calls `vctrs::vec_cbind_frame_ptype()` and 12 test files call `vctrs::`; D-119 names only dplyr and tibble as the other route — fix now (reword to the three vctrs compatibility files; add the direct-call route to D-119). Adding a file to the filter is rejected: planned change (Scope In fixes the three files, AC1 names them).
- diff-bug #3: PROFILE.md line 60 "the four workflows that run the whole suite" now fits devel-vctrs only on schedule and full dispatch — fix now. Its `R-CMD-check-cran.yaml:11-12` echo — reject, false: devel-vctrs still runs the whole suite on its schedule and sets `TESTTHAT_CPUS` on every trigger.
- diff-bug #4: D-119's list of jobs keeping D-116 ("five check legs, coverage job, CRAN-condition jobs") omits `R-CMD-check-hard.yaml` — fix now in D-119 (every other job). Scope Out's same wording is plan-owned; no change.
- diff-bug #5: header lines 9-11 "the break surfaces on the next push or pull request" now holds only for breaks the three files catch — fix now.
- diff-bug #6: the timeout comment sizes the cap on the whole-suite measurement without saying a push run is about 2 minutes — fix now (one clause).
- diff-bug #7: line 132 "The suite's verdict" — fix now ("The run's verdict"); "with `test-` and `.R` removed" narrower than testthat's pattern — reject, false: it is exact for this repo's file names.
- diff-bug #8: any `FULL_SUITE` value other than "true" falls back to the subset silently — reject, false: the expression renders only "true" or "false" on the four triggers (diff-bug Q1), and a new trigger is a future planned change.
- diff-bug #9: AC3's push and pull_request branches rest on reading, not a run — reject, false: AC3 is a claim about the head workflow's logic, read at lines 145-157 with both dispatch values observed; the PR's own `pull_request` run adds an observed case.
- blame-history #1: the three files are not the only ones exercising vctrs (same as diff-bug #2) — fix now.
- blame-history #2: PROFILE.md line 60 (same as diff-bug #3) — fix now.
- blame-history #3: header lines 9-11 (same as diff-bug #5) — fix now.
- blame-history #4: timeout comment's 2.5x against a 37m36s full run — reject, false: the ratio is stated against its own dated 35m24s measurement, which holds; diff-bug #6's clause covers the push path.
- blame-history #5: the concurrency block lets runs on one branch cancel each other — fix now under diff-bug #1.
- prior-review #1: header lines 9-10 repeat the M080-fixed overstatement of when a break surfaces (same as diff-bug #5) — fix now.
- prior-review #2: PROFILE.md line 60 whole-suite sentence, which M080's review also fixed (same as diff-bug #3) — fix now.
- ripple #1: PROFILE.md line 60 (same as diff-bug #3) — fix now.
- ripple #2: `R-CMD-check-cran.yaml:11-12` "unlike in the workflows that run the whole suite" — reject, false: see diff-bug #3.
- ripple #3: PROFILE.md line 50 "every CI job runs the tests `skip_heavy_on_cran()` keeps off CRAN" — reject, false: the sentence is about `NOT_CRAN`, which devel-vctrs keeps true on every trigger.
- ripple #4: ROADMAP title omits the dispatch default — reject, false: nothing in the title contradicts the diff.
- ripple #5: DESIGN.md Known issues entry on dispatched runs does not separate three-file runs — reject, false: its point (runs fired from no commit are unattributed) holds for both.
- ripple #6: `helper-cran.R:14-17` and the `FULL_SUITE` name beside `NESTEDTUNE_FULL_SUITE` — reject, false: the helper's claim holds (`NOT_CRAN` true), and the step-local name is read by no other code.
