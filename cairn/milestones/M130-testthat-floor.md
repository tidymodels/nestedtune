<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M130: Raise the testthat minimum to 3.2.3

- **Status:** planned
- **Priority:** low
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — `DESCRIPTION` ships to CRAN and governs anyone who runs the package's tests
- **Branch/PR:** —

## Goal

`DESCRIPTION` declares `testthat (>= 3.2.3)`, and the package's tests pass at that version both with `NOT_CRAN` unset and with it set to true.

## Scope

**In:** the testthat entry in Suggests. Two `R CMD check` runs with testthat 3.2.3 first on the library path, one under CRAN's conditions and one with `NOT_CRAN=true`. A control run at 3.2.2 that shows the library path reaches the test workers. A D-entry for the dependency change.

Why 3.2.3: testthat 3.2.2 errors on a `skip()` called outside a test (r-lib/testthat issues 2038 and 2039). The suite's 53 file-level `skip_heavy_on_cran()` calls take that path under CRAN's conditions. The regressing commit `dd39c654` came after 3.2.1. The suite also calls `local_mocked_bindings()`, which first appeared in 3.1.7, so the old 3.0.0 floor was already too low.

**Out:**
- A CI job that runs the suite at the floor becomes a `[low]` candidate row, added in this plan commit.
- The floors of the other Suggests entries stay as they are. No report names one.
- `NEWS.md` gets no entry, because the floor only affects someone who runs the package's tests.

## Acceptance criteria

- [ ] AC1: `DESCRIPTION` lists testthat in Suggests as `testthat (>= 3.2.3)`, and `desc::desc_get_deps("DESCRIPTION")` returns exactly one testthat row, of type `Suggests` with version `>= 3.2.3`.
- [ ] AC2: With a library holding testthat 3.2.3 first on `R_LIBS`, so the check's test process and its parallel workers load 3.2.3, the CRAN-conditions command in `benchmarks/cran-check-timing.md` (`NOT_CRAN` and `NESTEDTUNE_FULL_SUITE` unset) prints its `Running 'testthat.R'` line ending in `OK`, and `tests/testthat.Rout` reports `FAIL 0`.
- [ ] AC3: With the same library first on `R_LIBS`, `env -u NESTEDTUNE_FULL_SUITE NOT_CRAN=true TESTTHAT_CPUS=2 _R_CHECK_CRAN_INCOMING_=false R CMD check --as-cran --no-manual nestedtune_*.tar.gz` prints its `Running 'testthat.R'` line ending in `OK`, and `tests/testthat.Rout` reports `FAIL 0`.
- [ ] AC4: `Rscript -e 'devtools::check()'`, run with the installed testthat, reports 0 errors and 0 warnings.

## Coverage

- AC1 → T3
- AC2 → T1, T2, T3
- AC3 → T1, T2, T3
- AC4 → T5

## Tasks

- [ ] T1: Install testthat 3.2.3 and 3.2.2 from the CRAN archive into two separate temporary libraries outside the repo. Do not load devtools in a process that uses them, because devtools 2.5.2 requires testthat 3.3.2 or later.
- [ ] T2: Run the CRAN-conditions command at 3.2.2 as the control. Run it while the floor still reads `>= 3.0.0`, or with `_R_CHECK_FORCE_SUGGESTS_=false`, so the check reaches its tests. Record in the work log whether it fails with issue 2038's error ("attempt to select less than one element in get1index"). If it does not fail, record that and show by another means that the library path reaches the test workers. Then narrow the D-entry's reason to the functions 3.0.0 lacks.
- [ ] T3: Raise the testthat entry in `DESCRIPTION` to `>= 3.2.3`, then run the AC2 and AC3 checks at 3.2.3. Quote each run's `Running 'testthat.R'` line and its `tests/testthat.Rout` summary line in the Review evidence. If either run fails because of the testthat version (snapshot rendering, or the reporter in `tests/testthat/helper-hang-trace.R`), stop and amend the floor through the amendment protocol.
- [ ] T4: Append the D-entry above the `<!-- Template:` block in `DECISIONS.md`: the floor, its two reasons, and the evidence that falsifies it. It extends the dependency set D-072 last touched and carries no measurements.
- [ ] T5: Run the profile's `verify` slot and `devtools::check()` with the installed testthat.

## Work log

- 2026-09-29: created by /milestone-plan, promoting the `[low]` testthat-minimum candidate row (M118 review finding O7).
- 2026-09-29: criteria audit (full mode, fresh [O] reader) returned four findings on AC2 and AC3 and one task-order note. All four were fixed before the gate. The criteria now name the `R_LIBS` mechanism, write out AC3's command, and name `OK` and `FAIL 0` as the evidence. The 3.2.2 control stays in the tasks, and the order note went into T2.
- 2026-09-29: plan gate chose a 3.2.3 floor over the lowest passing release and over keeping 3.0.0. The lowest passing release leaves 3.2.2 and its known error inside the range. The suite's `local_mocked_bindings()` calls already exceed 3.0.0. Falsified by the AC2 or AC3 run failing at 3.2.3 for a testthat reason.
- 2026-09-29: plan gate chose one-time runs at the floor over a CI job pinned to it. The job costs a 15-25 minute run per push, for a Suggests entry that only test runners read. Falsified by a test adopting a testthat function newer than the floor without anyone noticing.
- 2026-09-29: plan gate chose both check runs over the CRAN-conditions run alone. Only the full run reaches the 46 snapshot files and the custom reporter. Falsified by the full run adding no failure mode that the CRAN run lacks.

## Decisions

## Review
