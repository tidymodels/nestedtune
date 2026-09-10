# M079: The suite asserts the seed it forces, names its daemon records by the pid each holds, and its comments describe the code they sit on

- **Status:** review
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
the duplicate build behind the fixed-workflow hand call at
`tests/testthat/test-nested-workflow-map-oracles.R:22-29`, whose cause is the
random `step_pca()` id `fixed_workflow()` draws
(`tests/testthat/helper-orchestration.R:69-76`), leaving the two workflow sets
that call it carrying different objects; and the comment
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
- [x] T4: Cut the second build of the fixed-workflow hand call at
      `test-nested-workflow-map-oracles.R:22-29`. Read the build count off the
      serial fixture-cache report's `builds` column under
      `TESTTHAT_PARALLEL=FALSE`, never off a source comment, and quote that
      row in the work log.
- [x] T5: Read each of these five comment sites against the code under it and
      correct what has drifted, quoting each reading in the work log:
      `benchmarks/time-examples.R:1,27` ("AC7", renumbered to AC6 at M74's
      re-cut); `test-nested-tune-bayes-oracles.R:431-433` (the block builds
      its own cache entry, so "the one the default oracle above built" is
      false — the workflow's step id is drawn at a different stream state;
      wrong, see the work log);
      `R-CMD-check.yaml:119-120` (reads "in 30 on four legs, 40 on windows",
      which matches today's caps after M76 — expected to need no edit);
      `benchmarks/profile-tests.R:130-140` with
      `profile-tests-parallel.R:205-216`; and `helper-time-budget.R:57-60`,
      whose `times` comment names BC12's site at `test-parallel-identity.R:572`
      alone where `:957` also carries `times = 2L`.
- [x] T6: Remove the second, duplicate per-run count print from
      `benchmarks/profile-tests.R:130-140` and from
      `benchmarks/profile-tests-parallel.R:205-216`, keeping the in-loop print.
- [x] T7: `Rscript -e 'devtools::test()'`, with no failure and no error
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

- 2026-09-10: substantive amendment at a mini gate — Scope In's fixed-workflow entry widened from the hand call at `test-nested-workflow-map-oracles.R:22-29` to the duplicate build behind it and its cause in `helper-orchestration.R:69-76`. The two builds are not two hand calls: `fixed_workflow()`'s `step_pca()` draws its id from the stream, so `wset_two()` (which builds it after `det_workflow()` has drawn) and `wset_fixed()` (which builds it first) carry different workflow objects that produce one value. AC3 unchanged.
- 2026-09-10: T4 — `step_pca()` in `fixed_workflow()` now carries `id = "pca_fixed"`. Serial fixture-cache report for `test-nested-workflow-map-oracles.R` under `TESTTHAT_PARALLEL=FALSE`, `builds` and `requests` columns for `nested_fit_resamples(workflow, folds, metrics = ms)`: `2` / `6` before, `1` / `6` after; file totals `8 signatures, 9 builds, 13 requests` before and `8 signatures, 8 builds, 13 requests` after, the report's "built more than once" warning line present before and absent after.
- 2026-09-10: T4 verify — `devtools::test()` 9588 pass, 0 warn, 0 skip, only AC6's four excluded items; no other test moved, so nothing in the suite depended on the drawn id.

- 2026-09-10: T5 site 1 — `benchmarks/time-examples.R:1` read "(M74, AC7)" and `:27` "the way AC7 reads"; M74's file at `accfbe2^` carries AC1-AC6 and its AC6 is the examples criterion, so both now read AC6.
- 2026-09-10: T5 site 2 — the comment at `test-nested-tune-bayes-oracles.R:431-433` is ACCURATE and stands; T5's parenthesis calling it false is wrong, and so is M74 finding O7 behind it. Both blocks open `d <- make_reg_data(); wf <- bayes_workflow(d)`, and `make_reg_data()` calls `set.seed(4242)`, so the two `step_ns()` ids are drawn at the same stream state whatever ran before (measured: `ns_lfjS1, ns_46opZ` from both openings with 37 `runif()` draws in between). The two calls therefore key one cache entry — `fixture_key()` matched for the pair, and the serial report for the file shows `reference_nested_bayes_loop(... iter = 2 ...)` at `builds 1 / requests 2`, the only two iter = 2 seed = 20 sites being lines 62 and 436. No edit made.
- 2026-09-10: T5 site 3 — `R-CMD-check.yaml:119-120` reads "in 30 on four legs, 40 on windows"; `grep -n timeout-minutes .github/workflows/*.yaml` gives the step cap at `:176` as `windows-latest && 40 || 30` over a five-leg matrix. Accurate, no edit, as the plan expected.
- 2026-09-10: T5 site 4 — the drift at `profile-tests.R:130-140` and `profile-tests-parallel.R:205-216` was the duplicate print itself, which carried no comment of its own; T6 removed it.
- 2026-09-10: T5 site 5 — `helper-time-budget.R:57-60` named one BC12 `shared_daemons()` site as paid twice; both `times = 2L` rows are BC12's, at `test-parallel-identity.R:572` (two daemons, block at `:559`) and `:957` (three daemons, block at `:944`), each inside `for (fn in RACERS)`. The comment now names both and cites the grep that re-reads them.
- 2026-09-10: T6 — the trailing per-run count loop is gone from both profilers; each script now prints its counts once, from inside the run loop. `run %d/%d` remains at `profile-tests.R:62,67` and `profile-tests-parallel.R:141,146`, the `:62`/`:141` pair being the progress line without a colon.
- 2026-09-10: T5, T6 verify — `devtools::test()` 9588 pass, 0 warn, 0 skip, only AC6's four excluded items; `air format --check` clean on every `.R` file the branch touches.

- 2026-09-10: checkpoint — three comment refinements on already-committed work (the `na.last` clause in `name_by_pid()`, a paragraph break above `fixed_workflow()`, the fabricated-fixture rationale in the new test block) and the `daemon_rng_kinds()` ledger pointer moved 246 → 247 as those lines shifted. `air format --check` clean; the suite run that covers them is T7's, the two profiler invocations for AC5 holding the machine meanwhile.

- 2026-09-10: T7 — `devtools::test()` on the committed tree: `[ FAIL 4 | WARN 0 | SKIP 0 | PASS 9588 ]`, the four being AC6's excluded `test-ci-workflows.R` items at `:59`, `:64`, `:65` and `:66`. Branch point was 9580 pass; the 8 added are T3's new block.
- 2026-09-10: AC5 evidence — `Rscript benchmarks/profile-tests.R 2` and `Rscript benchmarks/profile-tests-parallel.R 2`, each emitting exactly one `run 1/2:` count line (`run 1/2: pass 9587 | fail 4 | skip 0 | suite 612.0 s | wall 614.8 s` and `run 1/2: pass 9587 | fail 4 | skip 0 | WALL 235.0 s`); the `run 1/2 ...` progress line above each carries no colon and no counts.
- 2026-09-10: an earlier invocation of the same two scripts reported `fail 6` on its first run against `fail 4` on the other three. Cause was this session editing `helper-parallel.R` and `helper-time-budget.R` while that run was in flight, leaving the ledger's line pointer and the call it addresses briefly out of step — the same two failures planting the pre-change code produced under T3. Re-run on a quiescent tree: all four runs `fail 4`. Not suite intermittency; the lesson is that a source edit during a suite run invalidates that run's record.

## Decisions

- 2026-09-10: Two of the eight items M74's review left behind are not
  defects. M74's archive line naming them as follow-ups is superseded here,
  never edited (IP4). **O4** — `daemon_state_snapshot()` ordering by
  `order(pids)` and naming by `sort(pids)` — misaligns nothing: `order()`
  keeps an NA where `sort()` drops it, and `names<-` pads the short vector
  back into that same slot, so the pre-change helper names every fixture
  tried correctly and planting it back leaves the new test green. What M079
  changes is alignment-by-coincidence to alignment-by-construction.
  **O7** — that `test-nested-tune-bayes-oracles.R:431-433` wrongly calls its
  reference "the one the default oracle above built, served from the cache" —
  is itself wrong. Both blocks open `d <- make_reg_data(); wf <-
  bayes_workflow(d)`, and `make_reg_data()` calls `set.seed(4242)`, so the
  two `step_ns()` ids are drawn at the same stream state whatever ran
  before; the calls key one cache entry, which the file's serial report
  shows as `builds 1 / requests 2`. The comment stands unedited.

## Review
