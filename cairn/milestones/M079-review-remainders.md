# M079: The suite asserts the seed it forces, names its daemon records by the pid each holds, and its comments describe the code they sit on

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2
- **Resolves:** —
- **Surface tier:** internal — test files, developer benchmark scripts, and code comments, none of which any consumer of the package reaches.
- **Branch/PR:** `m079-review-remainders`

## Goal

Close the eight remainders M74's and M76's reviews left behind: one dropped
assertion, one mislabeled record, one doubly-built fixture, and five comments
that no longer describe the code under them.

## Scope

**In:** the eight sites those two reviews named — the merged control block in
`tests/testthat/test-nested-tune-bayes-results.R:248-289`;
`daemon_state_snapshot()` at `tests/testthat/helper-parallel.R:213,224-225`;
the fixed-workflow hand call at
`tests/testthat/test-nested-workflow-map-oracles.R:22-29`; and the comment
sites at `benchmarks/time-examples.R:1,27`,
`tests/testthat/test-nested-tune-bayes-oracles.R:431-433`,
`.github/workflows/R-CMD-check.yaml:119-120`,
`benchmarks/profile-tests.R:130-140` with
`benchmarks/profile-tests-parallel.R:205-216`, and
`tests/testthat/helper-time-budget.R:57-60`.

**Out:** the findings M74's review rejected — the "served from the cache"
comments at `test-nested-tune-grid-oracles.R:329`,
`test-nested-tune-sim-anneal-oracles.R:323` and
`test-nested-tune-race-oracles.R:354`, which hold, and the run-time figures at
`R-CMD-check.yaml:76`; they stay rejected. The eight items M56 and M57 left of
the older review rows → their own ROADMAP candidate row. Suite speed beyond
this one duplicate fixture build → the windows-leg candidate row. The CI
records → M080.

## Acceptance criteria

- [ ] AC1: `tests/testthat/test-nested-tune-bayes-results.R` runs
      `nested_tune_bayes()` under `tune::control_bayes(allow_par = TRUE, seed
      = 999L)` and asserts that result identical to the same run made under no
      explicit control.
- [ ] AC2: `daemon_state_snapshot()` names each record by the pid of the
      answer that record holds, including when one answer carries no integer
      `pid`.
- [ ] AC3: The fixed-workflow hand call is built once across the five `fn`
      blocks of `tests/testthat/test-nested-workflow-map-oracles.R`.
- [ ] AC4: Each of the five comment sites named in T5 describes the code it
      annotates.
- [ ] AC5: A two-run invocation of `benchmarks/profile-tests.R` and of
      `benchmarks/profile-tests-parallel.R` each emits exactly one `run 1/2:`
      count line.
- [ ] AC6: `Rscript -e 'devtools::test()'` reports no failure and no error
      other than the four `tests/testthat/test-ci-workflows.R` already
      reports at the branch point (`b07beb3`) — failures at lines 59, 64 and
      65 and an error at line 66, all from `job_uses()` finding no job named
      `pkgdown` in `pkgdown.yaml`, which M78 split into `build` and `deploy`.

## Coverage

- AC1 → T1, T2
- AC2 → T3
- AC3 → T4
- AC4 → T5
- AC5 → T6
- AC6 → T7

## Tasks

- [x] T1: Restore the branch point's `control_bayes(allow_par = TRUE, seed =
      999L)` run and its identity assertion to the merged block at
      `test-nested-tune-bayes-results.R:248-289`. Prove the assertion able to
      fail: revert the package's seed-forcing line once, record the failure's
      condition class and message in the work log, restore the line.
- [x] T2: Re-read `helper-time-budget.R`'s ledger after T1's insertion — its
      rows address call sites by `file:line`, so an insertion above a budgeted
      call renumbers them — and sum the file's declared bounds against the
      step cap before checking T1 off.
- [x] T3: Fix the naming at `helper-parallel.R:224-225`, where records are
      ordered by `order(pids)` and named by `sort(pids)`. Add a fixture case
      whose answers include one with no integer `pid`; record in the work log
      the aligned names the fixed helper yields, beside what the pre-change
      helper yields on the same fixture.
- [ ] T4: Cut the second build of the fixed-workflow hand call at
      `test-nested-workflow-map-oracles.R:22-29`. Read the build count off the
      serial fixture-cache report's `builds` column under
      `TESTTHAT_PARALLEL=FALSE`, never off a source comment, and quote that
      row in the work log.
- [ ] T5: Read each of these five comment sites against the code under it and
      correct what has drifted, quoting each reading in the work log:
      `benchmarks/time-examples.R:1,27` ("AC7", renumbered to AC6 at M74's
      re-cut); `test-nested-tune-bayes-oracles.R:431-433` (the block builds
      its own cache entry, so "the one the default oracle above built" is
      false — the workflow's step id is drawn at a different stream state);
      `R-CMD-check.yaml:119-120` (reads "in 30 on four legs, 40 on windows",
      which matches today's caps after M76 — expected to need no edit);
      `benchmarks/profile-tests.R:130-140` with
      `profile-tests-parallel.R:205-216`; and `helper-time-budget.R:57-60`,
      whose `times` comment names BC12's site at `test-parallel-identity.R:572`
      alone where `:957` also carries `times = 2L`.
- [ ] T6: Remove the second, duplicate per-run count print from
      `benchmarks/profile-tests.R:130-140` and from
      `benchmarks/profile-tests-parallel.R:205-216`, keeping the in-loop print.
- [ ] T7: `Rscript -e 'devtools::test()'`, with no failure and no error
      outside the four `test-ci-workflows.R` carries at the branch point.

## Work log

- 2026-09-10: created by /milestone-plan; absorbs the M74-remainders candidate row, which graduates when this milestone completes.
- 2026-09-10: criteria audit ran in reduced mode (internal tier), fresh [O] reader; returned five findings on this milestone's criteria — four instrument-binding (AC1-AC4 each bolted a mutation demo, a before/after comparison, an evidence-provenance rule or a mandated quotation onto a deliverable promise) and one bounded-promise (AC5 quantified over source lines its procedure could not reach); all five fixed at the gate, the demonstrations moving into T1, T3 and T4 and AC5 narrowing to what the two-run invocation settles.
- 2026-09-10: plan gate chose restoring the dropped `seed = 999L` assertion over widening an existing block's control coverage because the branch point ran exactly this pair and nothing else in `tests/` mentions 999; falsified by evidence that an overwritten explicit seed is already asserted at another site.
- 2026-09-10: minor amendment — T1, T3, T4 and T5 said to record their demonstrations in the `## Review` section, which tracking-rules reserves to `/milestone-review`; the four now record in the work log. T4 also said the fixture-cache report's `builds` count is its `requests` column; corrected to `builds`, `requests` counting cache hits rather than builds.
- 2026-09-10: gate — AC2's naming defect is latent, not live: `order()`'s `na.last = TRUE`, `sort()`'s NA drop and `names<-`'s NA padding cancel, so the pre-change helper already aligns on every NA fixture tried (pids 30,NA,20 / NA,30,20 / 20,30,NA / NA,NA,20 / 20,20,NA all name in true pid order). User chose to make the alignment true by construction and pin it with a fixture, AC2 unchanged, and to leave the no-pid record's name missing rather than give it a placeholder string.
- 2026-09-10: T1 — restored the `control_bayes(allow_par = TRUE, seed = 999L)` run and `expect_identical(forced, plain)` to the merged block; file 64 pass / 0 fail. Proved able to fail by deleting `control$seed <- NULL` from `effective_control()` (`R/tuner.R:274`) once: class `expectation_failure`, message "Expected `forced` to be identical to `plain`. Differences: `attr(actual, 'procedure')$control$seed`: 999 / `attr(expected, 'procedure')$control$seed`: 1" — 999 named, so the failure is the explicit-seed one; line restored, `git diff R/tuner.R` empty.
- 2026-09-10: T2 — `helper-time-budget.R`'s ledger addresses only `test-parallel-*.R` and `helper-parallel.R` call sites, so T1's insertion in `test-nested-tune-bayes-results.R` renumbers no row; `test-suite-hygiene.R` re-reads the ledger and sums the per-file bounds as tests, run under T7.

- 2026-09-10: substantive amendment at a mini gate — AC6 and T7 narrowed from "`devtools::test()` clean" to "no failure and no error outside the four `test-ci-workflows.R` items the branch point already carries". Those four (failures at :59, :64, :65, an error at :66) fail on `main` at `b07beb3`, from `job_uses()` finding no job named `pkgdown` after M78 split that workflow into `build` and `deploy`; `.github/` being `.Rbuildignore`d hides them from `R CMD check`. Neither M079's scope nor M080's covers that file, so the repair got its own ROADMAP candidate row rather than widening M079.
- 2026-09-10: re-audit: AC6 (reduced) — returned one bounded-promise finding, that `devtools::test()` separates failures from errors and line 66 is an error, so the drafted wording left the whole error class unbounded; fixed at the gate by binding both classes. Proportionality and instrument questions: no finding.

- 2026-09-10: T3 — the naming moved into `name_by_pid()` (`helper-parallel.R`), which orders and names from one `order(pids)` permutation; `daemon_state_snapshot()` calls it, and the ledger row for `daemon_rng_kinds()`'s `collect_bounded` moved 232 → 246 with it. New block in `test-suite-hygiene.R` over two fabricated answer sets, one carrying a non-list answer and one whose `pid` is `NULL`.
- 2026-09-10: T3 evidence — fixed helper names the shuffled fixture `"10" "20" "30"` and the gapped fixture `"10" "30" NA NA`, each name the pid its own record carries. Pre-change code (`answers[order(pids)]` + `names<-as.character(sort(pids))`) planted back: naming assertions all PASS, the only two failures being the ledger's line pointers, which moved because that form is a line shorter — so the misalignment M74 predicted does not occur, `order()`'s `na.last = TRUE`, `sort()`'s NA drop and `names<-`'s NA padding cancelling. Defect class the block does catch, planted as `names(answers) <- as.character(pids)` after ordering: 5 failures, first reading `actual: "30" "10" "20" / expected: "10" "20" "30"`.
- 2026-09-10: T3 verify — `devtools::test()` 9588 pass, 0 warn, 0 skip, and only the four `test-ci-workflows.R` items AC6 excludes.

## Decisions

## Review
