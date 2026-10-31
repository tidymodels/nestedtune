# M165: Keep the devel-vctrs test choice from drifting

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — a CI workflow and a marker comment in three test files; no package user relies on either
- **Branch/PR:** m165-devel-vctrs-drift

## Goal

Remove the two places where `devel-vctrs.yaml` can drift without a signal, while its push and pull-request runs stay limited to the vctrs test files.

## Scope

**In:** a marker line in `test-vctrs-compat.R`, `test-dplyr-compat.R` and `test-nested-results-set-compat.R`; the test step of `.github/workflows/devel-vctrs.yaml` selecting the `tests/testthat/test-*.R` files that hold that line, stopping when none does, and computing its whole-suite switch from `GITHUB_EVENT_NAME` and `inputs.full`; the workflow-level concurrency group keyed on those raw values; the workflow's comments and `cairn/PROFILE.md`'s concurrency sentence rewritten to match; a D-entry narrowing D-119.

**Out:** whole-suite runs on push or pull request, which this plan's question set ruled out (the weekly schedule and a full dispatch keep them, D-119). A drift test in `test-ci-workflows.R`, declined at this plan's question set in favor of simplifying the workflow; no row. Watching more test files on push, such as `test-nested-tune-bayes-oracles.R`: a file joins by taking the marker line, a later choice under D-119's falsifier; no row.

## Acceptance criteria

- [ ] AC1: On this milestone's PR `pull_request` run, `devel-vctrs.yaml` runs exactly the test files that `grep -lxF '# devel-vctrs.yaml runs this file on every push and pull request.' tests/testthat/test-*.R` lists at the PR head, and that command lists `test-vctrs-compat.R`, `test-dplyr-compat.R` and `test-nested-results-set-compat.R`. Evidence: the run passes, its log prints `Whole suite: FALSE`, and testthat's report in that log shows no context other than `vctrs-compat`, `dplyr-compat` and `nested-results-set-compat`.
- [x] AC2: In a copy of the repo with `test-vctrs-compat.R` renamed to `test-renamed-plant.R`, the test step's R code selects that file and the other two watched files. With the marker line removed from all three, it stops with an error before `testthat::test_local()` is called.
- [x] AC3: `grep -nE 'vctrs-compat|dplyr-compat|nested-results-set-compat' .github/workflows/devel-vctrs.yaml` prints no line.
- [x] AC4: The `group:` line of the workflow-level `concurrency:` block in `.github/workflows/devel-vctrs.yaml` is four `${{ }}` blocks joined by `-`, holding `github.workflow`, `github.ref`, `github.event_name` and `inputs.full`, each a bare property with no operator.
- [x] AC5: The test step's `env:` block holds one entry, mapped from `inputs.full`, read from the YAML. The step's switch code, run locally with (`GITHUB_EVENT_NAME`, full value) set to (`schedule`, ""), (`workflow_dispatch`, "true"), (`workflow_dispatch`, "false"), (`push`, "") and (`pull_request`, ""), prints `Whole suite: TRUE`, `TRUE`, `FALSE`, `FALSE` and `FALSE` in that order.

## Coverage

- AC1 → T1, T2
- AC2 → T2, T4
- AC3 → T3
- AC4 → T3
- AC5 → T2, T4

## Tasks

- [x] T1: Add the line `# devel-vctrs.yaml runs this file on every push and pull request.` to `tests/testthat/test-vctrs-compat.R`, `test-dplyr-compat.R` and `test-nested-results-set-compat.R`, as a whole line after each file's header comment.
- [x] T2: Rewrite the "Run the tests against it" step of `.github/workflows/devel-vctrs.yaml`. Its `env:` maps `inputs.full` alone; the R code sets the switch to true on `schedule`, and on `workflow_dispatch` when the full value is "true". When the switch is false, it reads `tests/testthat/test-*.R`, keeps the files holding the marker as a whole line, stops with an error naming the marker when none does, prints the selected files, and passes `testthat::test_local()` a filter built from their names with regex characters escaped. It prints `Whole suite:` as now.
- [x] T3: Key the concurrency group on `github.workflow`, `github.ref`, `github.event_name` and `inputs.full`. Rewrite the header paragraph that names the three files, and the concurrency comment, from a same-session read of the new step, to point at the marker line and the raw key. Edit the `devel-vctrs.yaml` concurrency sentence on `cairn/PROFILE.md` line 44 in place, adding no line (the file is at 119 of its <120 cap).
- [x] T4: Copy the step's R code to a scratch script and run it locally: the five cases of AC5, then the rename plant and the no-marker plant of AC2 on a copy of `tests/testthat/`, each plant seen to give its stated result. Record the outcomes in one work-log line.
- [x] T5: Append a D-entry narrowing D-119: the concurrency group keys on `github.event_name` and `inputs.full`, and a test file joins the push-time watch by its marker line. Record the side effect: a scheduled run and a full dispatch no longer share a group, nor do a `full` false dispatch on the default branch and a push to it.

## Work log

- 2026-10-31: created by /milestone-plan.
- 2026-10-31: tier check: not run — work named at the question set.
- 2026-10-31: question set: what to plan — the devel-vctrs drift guard, without bringing back whole-suite runs on push and pull request.
- 2026-10-31: question set: simplify the workflow or add a drift test (checker-regress shape on `test-ci-workflows.R`) — simplify the workflow.
- 2026-10-31: idea vet: gap — the hand list of three files; reading taken: a marker line in each watched file selects them, so a rename keeps the file and an empty selection stops the run. gap — the concurrency group repeats the step's switch; reading taken: key the group on the raw event and input values the switch reads. No flaw.
- 2026-10-31: plan gate chose a marker line in each watched file over a `-compat` file-name convention because a file renamed out of the convention would still drop silently; falsified by a watched file losing its marker in an edit that no run flags.
- 2026-10-31: plan gate chose keying the group on raw `github.event_name` and `inputs.full` over keeping the copied switch expression because two runs in one group then share every value the switch reads; falsified by a three-file run cancelling or replacing a whole-suite run.
- 2026-10-31: collision: absorbed candidate "Guard the devel-vctrs filter from drift" (M153 review). D-119 narrowed at T5, not superseded. M153 (done) shipped the three-file filter; this extends it. Inbox: 1 open issue (#91, parked), 0 open PRs, no overlap.
- 2026-10-31: lessons used: 2026-09-02 (M50, extended M53/M58/M67/M79/M88/M153) on CI pushes and dispatch concurrency; 2026-09-11 (M86, extended M89) on a checker whose domain can empty.
- 2026-10-31: criteria audit (reduced mode, fresh Opus reader): AC1 claimed every push and pull request and a log listing no task printed; narrowed to this PR's run against a grep of marker files, the print moved to T2, contexts named instead of files. AC2 narrowed to two named plants, search limited to `test-*.R`. AC3 none. AC4 narrowed to four bare properties. AC5 narrowed to a one-entry `env:` and five named cases with empty full values. Side effect of AC4 moved to T5.
- 2026-10-31: no changelog entry: CI-only, as at M153.
- 2026-10-31: status in-progress, branch m165-devel-vctrs-drift cut from main at f9160fdc.
- 2026-10-31: T1 done: marker line added as its own paragraph at the end of each file's header comment; `grep -lxF` lists the three files; `air format --check .` clean. Comment-only change, so verify's `devtools::test()` waits for T4, which runs the three files through the new step.
- 2026-10-31: T2 done: the step's `env:` holds `FULL_INPUT` alone; the R code decides the switch from `GITHUB_EVENT_NAME` and it, selects marked `test-*.R` files with `readLines(warn = FALSE)`, stops when none, prints the selection, escapes regex characters in the stems. Implementation choice: the marker is matched with `%in%` over the file's lines, a whole-line match like `grep -x`.
- 2026-10-31: T3 done: group keyed on workflow, ref, `github.event_name`, `inputs.full`; header paragraph and concurrency comment rewritten from a same-session read of the step, the dispatch input's description says "watched"; PROFILE.md line 44 edited in place, still 119 lines. A simple-english hook flagged older PROFILE.md sentences outside the edit; left alone, out of scope.
- 2026-10-31: T4 done: step code read from the YAML with `yaml::read_yaml()` into scratch scripts. Switch under (schedule,""), (workflow_dispatch,"true"), (workflow_dispatch,"false"), (push,""), (pull_request,"") printed TRUE, TRUE, FALSE, FALSE, FALSE. Rename plant (`test-renamed-plant.R`) selected it and the other two; no-marker plant stopped with the step's own "No test file ... carries the line" error before `load_all()`. Full step for push ran the three files: FAIL 0, PASS 988 (verify for T1). The escape line, run from a file, gave `a\.b\+c` and `q\(1\)`; an `Rscript -e` check had mangled the backslashes.
- 2026-10-31: T5 done: D-122 narrows D-119's filter and concurrency clauses and records the group side effect.
- 2026-10-31: claim audit: not owed — internal tier.
- 2026-10-31: verify: no `R/` change and the `.R` changes are comment lines, so the gate is `air format --check .` clean plus T4's run of the three watched files (PASS 988); status review.
- 2026-10-31: review checkpoint (half-done): AC2-AC5 evidence recorded and ticked; AC1 waits for the PR run; the gate's `devtools::check()` and the four-lens review are running.
- 2026-10-31: review pass 1: four lenses reported 15 findings; 7 fix now (comment and record wording only), 4 rejected as planned change, 4 noted; no floor return. `devtools::check()` still running.

## Decisions

## Review

- AC1 (local part, 2026-10-31 at 6c3ded1f): `grep -lxF` with the marker lists `test-dplyr-compat.R`, `test-nested-results-set-compat.R`, `test-vctrs-compat.R`. The PR's `pull_request` run of `devel-vctrs.yaml` is read at step 8 before the merge; the box is ticked only then.
- AC2 (2026-10-31 at 6c3ded1f): the step's code before `pkgload::load_all()`, read from the YAML with `yaml::read_yaml()`, run under `pull_request` in a copy with `test-renamed-plant.R`: selected `test-dplyr-compat.R`, `test-nested-results-set-compat.R`, `test-renamed-plant.R`, filter `^(dplyr-compat|nested-results-set-compat|renamed-plant)$`. With the marker removed from all three: stopped with "No test file in tests/testthat carries the line …", exit 1, before `test_local()`.
- AC3 (2026-10-31 at 6c3ded1f): the grep printed no line, exit 1.
- AC4 (2026-10-31 at 6c3ded1f): `group: ${{ github.workflow }}-${{ github.ref }}-${{ github.event_name }}-${{ inputs.full }}`, four bare properties joined by `-`.
- AC5 (2026-10-31 at 6c3ded1f): the step's `env:` has one entry, `FULL_INPUT: ${{ inputs.full }}`. The switch code, run with (schedule,""), (workflow_dispatch,"true"), (workflow_dispatch,"false"), (push,""), (pull_request,""), printed `Whole suite: TRUE`, `TRUE`, `FALSE`, `FALSE`, `FALSE`.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: one file losing its marker drops out of the watch with no signal — reject (planned change): the plan gate chose the marker with this as its falsifier (D-122); the step comment now says so.
- diff-bug #2: "two runs in one group run the same tests" overstates, since each commit's markers pick the files — fix now, fixed 91003c46: workflow concurrency comment and D-122 Decision (branch-only, corrected in place) say the group fixes the whole-suite choice.
- diff-bug #3: the search pattern `^test-.*\.R$` misses testthat's `test_*.R` and `.r` names, so "a renamed file stays in" overstates — fix now, fixed 91003c46: the comment says a file renamed within the `test-*.R` pattern stays in. The pattern stays: every file in `tests/testthat/` is `test-*.R`, and Scope In names that pattern.
- diff-bug #4: `cairn/PROFILE.md:65` still says "the three vctrs compatibility test files" — fix now, fixed 91003c46: it names the marker line.
- diff-bug #5: an orphan short line in the header paragraph — fix now, fixed 91003c46: rewrapped.
- blame-history #1: marker deletion is not guarded — reject (planned change), as diff-bug #1.
- blame-history #2: a scheduled run and a full dispatch can now run side by side, costing CI minutes — reject (planned change): D-122 Consequences records it, and subset groups stay apart from whole-suite groups.
- blame-history #3: the concurrency comment's "same tests" claim — fix now, as diff-bug #2.
- blame-history #4: `cairn/PROFILE.md:65` — fix now, as diff-bug #4.
- prior-review #1, #2, #4, #5, #6: earlier findings checked and not reintroduced (M153 concurrency defect, PROFILE cap at 119, the drift row, M102 and M080 claims, M057 comment accuracy) — noted, no action.
- prior-review #3: `cairn/PROFILE.md:65` — fix now, as diff-bug #4; the 2m38s timeout comment is a dated measurement and stays.
- ripple #1: the ROADMAP candidate row "Guard the devel-vctrs filter from drift" still describes the defect as open — reject (planned change): it carries `started M165` and post-merge hygiene graduates it.
- ripple #2: `cairn/PROFILE.md:65` — fix now, as diff-bug #4.
