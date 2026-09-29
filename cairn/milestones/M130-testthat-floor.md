<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M130: Raise the testthat minimum to 3.3.0

- **Status:** in-progress
- **Priority:** low
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — `DESCRIPTION` ships to CRAN and governs anyone who runs the package's tests
- **Branch/PR:** `m130-testthat-floor`

## Goal

`DESCRIPTION` declares `testthat (>= 3.3.0)`, and the package's tests pass at that version both with `NOT_CRAN` unset and with it set to true.

## Scope

**In:** the testthat entry in Suggests. Two `R CMD check` runs with testthat 3.3.0 first on the library path, one under CRAN's conditions and one with `NOT_CRAN=true`. A probe run that shows the check's test workers load the version on that path. A D-entry for the dependency change.

Why 3.3.0: testthat 3.2.2 errors on a `skip()` called outside a test (r-lib/testthat issues 2038 and 2039, fixed in 3.2.3 by its NEWS). The suite's file-level `skip_heavy_on_cran()` calls take that path under CRAN's conditions. The suite also calls `local_mocked_bindings()`, which first appeared in 3.1.7, so the old 3.0.0 floor was already too low. Releases 3.2.3 and older do not compile under R 4.6.1, because `reassign.c` calls `SET_FORMALS`, `SET_BODY` and `SET_CLOENV`. So 3.3.0 is the lowest release this machine can check. It requires R 4.1, the same minimum as the package's `Depends`. A search of `tests/` for the functions testthat 3.3.0 to 3.3.2 added found none.

**Out:**
- A CI job that runs the suite at the floor stays the `[low]` candidate row. This plan commit rewords it for the 3.3.0 floor.
- The floors of the other Suggests entries stay as they are. No report names one.
- `NEWS.md` gets no entry, because the floor only affects someone who runs the package's tests.

## Acceptance criteria

- [ ] AC1: `DESCRIPTION` lists testthat in Suggests as `testthat (>= 3.3.0)`, and `desc::desc_get_deps("DESCRIPTION")` returns exactly one testthat row, of type `Suggests` with version `>= 3.3.0`.
- [ ] AC2: `R CMD check` starts with an `R_LIBS` whose first entry is a library holding testthat 3.3.0. Under it, the CRAN-conditions command in `benchmarks/cran-check-timing.md` (`NOT_CRAN` and `NESTEDTUNE_FULL_SUITE` unset) ends its `checking tests` step in `OK`, and its `tests/testthat.Rout` reports `FAIL 0`.
- [ ] AC3: Under the same `R_LIBS`, `env -u NESTEDTUNE_FULL_SUITE NOT_CRAN=true TESTTHAT_CPUS=2 _R_CHECK_CRAN_INCOMING_=false R CMD check --as-cran --no-manual nestedtune_*.tar.gz` ends its `checking tests` step in `OK`, and its `tests/testthat.Rout` reports `FAIL 0`.
- [ ] AC4: `Rscript -e 'devtools::check()'`, run with the installed testthat, reports 0 errors and 0 warnings.

## Coverage

- AC1 → T3
- AC2 → T1, T2, T3
- AC3 → T1, T2, T3
- AC4 → T5

## Tasks

- [x] T1: Install testthat 3.3.0 from the CRAN archive into a temporary library outside the repo. Do not load devtools in a process that uses it, because devtools 2.5.2 requires testthat 3.3.2 or later.
- [x] T2: Show that the library path reaches the test processes. Build a scratch copy of the package outside the repo with one added helper file. The helper writes `packageVersion("testthat")` and `Sys.getpid()` to one file per process in a scratch directory, because a worker's output reaches no log. Only the workers source helpers, so the copy's `tests/testthat.R` also writes the same file after `library(testthat)`. Run the CRAN-conditions command on that copy twice: once with the T1 library first on `R_LIBS`, and once without it as the control. Record in the work log the versions and the processes each run wrote. The first run must show 3.3.0 from the runner process and from two distinct worker processes. The control must show the installed version. This probe also covers the AC3 run, because `NOT_CRAN` does not change which library R loads from.
- [x] T3: Raise the testthat entry in `DESCRIPTION` to `>= 3.3.0`, then run the AC2 and AC3 checks at 3.3.0 on the unmodified package. Quote each run's `Running 'testthat.R'` line, the result line after it, and its `tests/testthat.Rout` summary line in the Review evidence. A run can fail because of the testthat version, for example in snapshot rendering or in the reporter in `tests/testthat/helper-hang-trace.R`. If it does, raise the floor to the lowest of 3.3.1 and 3.3.2 at which both runs pass. Make that change through the amendment protocol, and repeat T1 and T2 at that version.
- [x] T4: Append the D-entry above the `<!-- Template:` block in `DECISIONS.md`. It states the floor and the evidence that falsifies it. It gives three reasons: the 3.2.2 `skip()` error, `local_mocked_bindings()`, and the R 4.6 build failure of older releases. It extends the dependency set D-072 last touched and carries no measurements.
- [x] T5: Run the profile's `verify` slot and `devtools::check()` with the installed testthat.

## Work log

- 2026-09-29: created by /milestone-plan, promoting the `[low]` testthat-minimum candidate row (M118 review finding O7).
- 2026-09-29: criteria audit (full mode, fresh [O] reader) returned four findings on AC2 and AC3 and one task-order note. All four were fixed before the gate. The criteria now name the `R_LIBS` mechanism, write out AC3's command, and name `OK` and `FAIL 0` as the evidence. The 3.2.2 control stays in the tasks, and the order note went into T2.
- 2026-09-29: plan gate chose a 3.2.3 floor over the lowest passing release and over keeping 3.0.0. The lowest passing release leaves 3.2.2 and its known error inside the range. The suite's `local_mocked_bindings()` calls already exceed 3.0.0. Falsified by the AC2 or AC3 run failing at 3.2.3 for a testthat reason.
- 2026-09-29: plan gate chose one-time runs at the floor over a CI job pinned to it. The job costs a 15-25 minute run per push, for a Suggests entry that only test runners read. Falsified by a test adopting a testthat function newer than the floor without anyone noticing.
- 2026-09-29: plan gate chose both check runs over the CRAN-conditions run alone. Only the full run reaches the 46 snapshot files and the custom reporter. Falsified by the full run adding no failure mode that the CRAN run lacks.
- 2026-09-29: /milestone-implement set in-progress and cut `m130-testthat-floor`. At T1, testthat 3.2.3 and 3.2.2 failed to compile under R 4.6.1: `reassign.c` calls `SET_FORMALS`, `SET_BODY` and `SET_CLOENV`, which R 4.6 no longer declares. testthat 3.3.0 (published 2025-11-13, `R (>= 4.1.0)`) built and loaded. The machine has no other R and no rig.
- 2026-09-29: implement gate chose to re-plan at a 3.3.0 floor. It rejected verifying 3.2.3 on a CI job with R 4.5, or on a local R 4.5 the user installs. The goal names 3.2.3, so M130 returns to planned. The branch held no code and was deleted.
- 2026-09-29: /milestone-plan re-planned M130 at a 3.3.0 floor. The Goal, Scope, criteria and tasks were rewritten. The 3.2.2 control run became a version probe with a control, because 3.2.2 does not build under R 4.6 either. A search of `tests/` found no function that testthat 3.3.0 to 3.3.2 added.
- 2026-09-29: criteria audit (full mode, fresh [O] reader) returned three findings, all fixed before the gate. AC2 and AC3 read `OK` from the `checking tests` result line, not the `Running` line. AC2's loading clause became an `R_LIBS` precondition. T2's probe now records the runner process too. AC1 and AC4 had no findings.
- 2026-09-29: for a failure at 3.3.0 with a testthat cause, the plan gate chose an in-milestone amendment to 3.3.1 or 3.3.2 over a return to plan. Every candidate release already fixes the 3.2.2 error. Falsified by a failure at 3.3.2 too, which makes the floor a testthat question and not a floor question.
- 2026-09-29: plan gate chose a probe with a control over a probe alone and over no probe. Without the control, the probe never shows it can report a version other than 3.3.0. Falsified by the control run also reporting 3.3.0.
- 2026-09-29: /milestone-implement set in-progress and cut `m130-testthat-floor` from `88a61184`. The implement gate had no open question. T1: testthat 3.3.0 from the CRAN archive installed into a session scratch library, and `packageVersion()` under `R_LIBS` set to it reads 3.3.0.
- 2026-09-29: T2 probe, CRAN-conditions command on a scratch copy built from `eb793590`. With the 3.3.0 library first on `R_LIBS`, the runner (pid 36716) and two workers (36735, 36736) each wrote 3.3.0 from that library. The control without it wrote 3.3.2 from the R framework library in the runner (38868) and two workers (38882, 38883). Both checks ended `Status: OK`. The first repack of the copy carried macOS extended attributes, which R's `untar` rejects, so that pair never ran and was repacked with `tar --no-xattrs`.
- 2026-09-29: T3 raised the floor to `>= 3.3.0`, and `desc_get_deps()` returns one testthat row, `Suggests` `>= 3.3.0`. With the 3.3.0 library first on `R_LIBS`, the AC2 run printed `Running ‘testthat.R’ [101s/49s]`, then `[101s/50s] OK`, and `testthat.Rout` read `[ FAIL 0 | WARN 0 | SKIP 118 | PASS 6554 ]`. The AC3 run printed `Running ‘testthat.R’ [784s/412s]`, then `[785s/413s] OK`, and `[ FAIL 0 | WARN 0 | SKIP 13 | PASS 13390 ]`. The fallback to 3.3.1 or 3.3.2 was not needed. The Review section is review's to write, so the quotes live here for review to re-run or cite.
- 2026-09-29: T4 appended D-098, the 3.3.0 floor with its three reasons and its falsifiers.
- 2026-09-29: T5 with the installed testthat 3.3.2: `devtools::test()` failed 0 and passed 13508, and `devtools::check()` returned 0 errors, 0 warnings and 0 notes. No roxygen, `R/` or prose file changed, so the verify slot's other steps do not apply.

## Decisions

## Review
