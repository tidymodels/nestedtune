# M079: The suite asserts the seed it forces, names its daemon records by the pid each holds, and its comments describe the code they sit on

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP2
- **Resolves:** —
- **Surface tier:** internal — test files, developer benchmark scripts, and code comments, none of which any consumer of the package reaches.
- **Branch/PR:** `m079-review-remainders` / [#89](https://github.com/tidymodels/nestedtune/pull/89)

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

- [x] AC1: `tests/testthat/test-nested-tune-bayes-results.R` runs
      `nested_tune_bayes()` under `tune::control_bayes(allow_par = TRUE, seed
      = 999L)` and asserts that result identical to the same run made under no
      explicit control.
- [x] AC2: `daemon_state_snapshot()` names each record by the pid of the
      answer that record holds, including when one answer carries no integer
      `pid`.
- [x] AC3: The fixed-workflow hand call is built once across the five `fn`
      blocks of `tests/testthat/test-nested-workflow-map-oracles.R`.
- [x] AC4: Each of the five comment sites named in T5 describes the code it
      annotates.
- [x] AC5: A two-run invocation of `benchmarks/profile-tests.R` and of
      `benchmarks/profile-tests-parallel.R` each emits exactly one `run 1/2:`
      count line.
- [x] AC6: `Rscript -e 'devtools::test()'` run on the branch head on a
      quiescent machine reports no failure and no error in any file this
      branch touches (`git diff --name-only b07beb3 HEAD`).

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
- [x] T7: Run `Rscript -e 'devtools::test()'` on the branch head and on `main`
      at the branch point (`b07beb3`), each on a quiescent machine; compare the
      two runs' failure and error items by file, line and message, and record
      the comparison in the work log.

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

- 2026-09-10: review opened; branch pushed and draft PR [#89](https://github.com/tidymodels/nestedtune/pull/89) created. `main` had not moved since the branch point, so no merge was needed.
- 2026-09-10: amendment return: AC6 — "no failure and no error other than the four `tests/testthat/test-ci-workflows.R` already reports at the branch point (`b07beb3`)". The branch point reports five, not four: `test-parallel-interrupt.R:108` fails there too, identically. Status to `in-progress` for that amendment alone; review stops.
- 2026-09-10: the fifth item is pre-existing and not M079's. `test-parallel-interrupt.R:108` ("Expected `interrupted` to be TRUE") fails on `b07beb3` and on the branch head, same line and same message, and passes 7/7 when its file is run alone under `NOT_CRAN=true` — a timing interaction inside the parallel suite, not a defect this branch introduced. Worth its own candidate row when the amendment gate sets scope.
- 2026-09-10: amendment return: AC6 — "`Rscript -e 'devtools::test()'` run on the branch head on a quiescent machine reports no failure and no error in any file this branch touches (`git diff --name-only b07beb3 HEAD`)." The review's return was reclassified under its widening test, so the repair narrows the promise rather than widening the excused list: the branch-point comparison moves into T7, which is amended to run both refs and compare their items by file, line and message.
- 2026-09-10: re-audit: AC6 (reduced) — returned one instrument-binding finding on the wording fixed at the mini gate, that a branch-head-versus-branch-point comparison promises a relation between two harness reports rather than a property of the deliverable, and turns on whether each run happens to hit `test-parallel-interrupt.R:108`'s timing flake; bounded-promise and proportionality: no finding. This is AC6's second re-audit line, so the disposition went to the user, who took the reader's repair. Neither `test-ci-workflows.R` nor `test-parallel-interrupt.R` is among the ten files `git diff --name-only b07beb3 HEAD` names, so both leave the promise by construction rather than by name.
- 2026-09-10: T7 under the amended wording — the two quiescent runs and their comparison are the ones `/milestone-review` made on this tree this session and recorded in `## Review`: branch head `FAIL 5 | PASS 9587`, `main` at `b07beb3` `FAIL 5 | PASS 9578`, the same five items (`test-ci-workflows.R:59,:64,:65,:66` and `test-parallel-interrupt.R:108`) byte-identical across the two, so the branch head adds none.
- 2026-09-10: claim audit: not owed — internal tier.
- 2026-09-10: step-7 approval: PR #89 approved for merge.

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

### Round 1 — stopped at the AC6 amendment return (2026-09-10)

Phase stopped at an amendment return on AC6 (step 5's amendment-return clause);
AC3, AC4 and AC5 were not reached. Evidence below is what ran before the stop.

**Criteria executed.**

- **AC1 — verified.** `devtools::test()` on the branch head (tree of `838441e`,
  quiescent machine) reports no failure in
  `tests/testthat/test-nested-tune-bayes-results.R`. The restored block runs
  `nested_tune_bayes()` under `tune::control_bayes(allow_par = TRUE, seed =
  999L)` and asserts `expect_identical(forced, plain)` against the same run made
  with no `control` argument.
- **AC2 — verified.** The same run reports no failure in
  `tests/testthat/test-suite-hygiene.R`, whose new block drives `name_by_pid()`
  over two fabricated answer sets and asserts each record's name equals the pid
  read back off that record — including the set carrying a non-list answer and
  one whose `pid` is `NULL`, which come back named `NA`.
- **AC3, AC4, AC5 — not reached.** The fixture-cache build count, the five
  comment-site readings and the two-run profiler invocations were not executed
  before the return.
- **AC6 — FAILS as written; returned for amendment.** Three full
  `devtools::test()` runs this session: branch head under machine contention,
  `FAIL 5 | PASS 9587`; branch head quiescent, `FAIL 5 | PASS 9587`; **`main` at
  the branch point `b07beb3`, quiescent, `FAIL 5 | PASS 9578`**. Every run
  carries the same five items — `test-ci-workflows.R` at `:59`, `:64`, `:65` and
  the `:66` error, plus `test-parallel-interrupt.R:108`, "Expected `interrupted`
  to be TRUE", byte-identical across refs. AC6 excludes four by name, so a fifth
  item present at the branch point falsifies the criterion's own premise rather
  than the work: its exclusion list was fixed by recall of one earlier run, not
  by a procedure over the branch point. Run alone under `NOT_CRAN=true` that file
  passes 7/7, so the fifth item is a timing interaction inside the parallel
  suite, pre-existing and untouched by this branch.

**Consistency gate.** `cairn_validate.py` exit 0, every check PASS, 18
`references staleness` advisories and no `release window` advisory. No
`DESIGN.md` principle changed, so `cairn_impact.py` was skipped. Toolchain
half (`r-package` profile) was not reached before the return: `document()`,
`pkgdown::check_pkgdown()` and `devtools::check()` are still owed at re-review.
`README.Rmd` and `README.md` last changed in the same commit and neither is
touched by this branch; `NEWS.md` needs no entry, the tier being internal.

**Independent review — three-lens fan-out**, fresh context, distinct evidence
bases. Findings are carried to the re-review's triage gate, untriaged.

- **[S] blame-history: 0 findings.** Traced the drawn `step_pca()` id to
  `9aab34d0` (M12) and found no milestone relying on it; found the duplicate
  per-run print was M74's own flagged defect (O10) rather than a second figure;
  found the `seed = 999L` assertion was dropped by M74's merge (O2), not by
  intent.
- **[S] prior-review regression: 0 findings.** Archived `## Review` sections on
  the touched files are M74's and M76's; each diff site matches its named
  finding. Neither rejected-finding file appears in the diff. The GitHub probe
  returned three real inline comments repo-wide, all on workflow files this
  branch does not touch, so no thread walk was warranted.
- **[O] diff-bug: 6 findings**, ranked as the reviewer ranked them.
  1. `tests/testthat/helper-orchestration.R:106-109` — `fit_resamples_results()`
     still says "the recipe step id is drawn from the stream", 26 lines after the
     diff's own new comment says it no longer is; the `set.seed(seed)` at `:111`
     that the false rationale justifies is now inert. The same drift class AC4
     exists to remove, introduced by this milestone.
  2. `tests/testthat/test-nested-tune-bayes-results.R:296-306` — the restored
     live `nested_tune_bayes()` run is not memoised and pays back suite time M74
     spent, with no seconds recorded anywhere in this milestone.
  3. `tests/testthat/helper-time-budget.R:61-62` — "the ledger's only rows
     carrying a `times` above 1" is a universal claim the cited grep cannot
     check: `grep 'times = 2L'` matches the literal only, misses a `times = 3L`
     row, and self-matches the comment line.
  4. `tests/testthat/helper-orchestration.R:2536-2537` and `:2604-2606` —
     `plain_workflow()`'s "no recipe step id drawn from the stream" contrast and
     `wset_results()`'s `force(data)` rationale are now over-general;
     `wset_fixed()` draws no ids at all, though `wset_two()` still does through
     `det_workflow()`.
  5. AC3's "the five `fn` blocks" undercounts: `MAP_FNS` holds six and the hand
     call is reached from all six. The promise still holds a fortiori.
  6. `cairn/ROADMAP.md:4` — the hygiene stamp claims 23,460 bytes; `wc -c`
     reports 23,327.

  Verified independently this session: finding 1's two contradicting comments
  and the inert seed; finding 3's grep behaviour and the two `times = 2L` rows
  at `helper-time-budget.R:767` and `:847`, whose pointers to
  `test-parallel-identity.R:572` and `:957` are both correct and both inside
  `for (fn in RACERS)`; finding 5's `for (fn in MAP_FNS)` over six names;
  finding 6's byte count. The reviewer's clean list was spot-checked on the
  ledger pointer `helper-parallel.R:247`, which is where `daemon_rng_kinds()`'s
  `collect_bounded` now sits, and on `R-CMD-check.yaml:119-120` against the cap
  at `:176`.

### Round 2 — after the AC6 amendment (2026-09-10)

Re-entered at step 1 (PR #89 open, criteria unticked). `origin/main` is still
`b07beb3`, an ancestor of the branch head, so no merge and no re-run were owed
before evidence was gathered. PR #89 already open; `gh pr create` skipped.

**Criteria executed.**

- **AC1 — verified.** `Rscript -e 'devtools::test()'` on the branch head
  (`7ee30e4`, quiescent machine): `[ FAIL 4 | WARN 0 | SKIP 0 | PASS 9588 ]`,
  no failure in `tests/testthat/test-nested-tune-bayes-results.R`. Read against
  the source: the block at `:248` binds `plain <- bayes_results()`, whose helper
  (`helper-orchestration.R:1142`) calls `nested_tune_bayes()` with no `control`
  argument under `set.seed(20)`; the restored run at `:298-307` repeats those
  arguments under the same entry seed with
  `control = tune::control_bayes(allow_par = TRUE, seed = 999L)` and
  `expect_identical(forced, plain)` at `:308`.
- **AC2 — verified.** The same run reports no failure in
  `tests/testthat/test-suite-hygiene.R`. `daemon_state_snapshot()`
  (`helper-parallel.R:213-220`) returns `name_by_pid(answers)`, which builds one
  `order(pids)` permutation and names from `pids[ord]`, so a record's name is the
  pid that record carries. The hygiene block drives it over a shuffled fixture
  (named `"10" "20" "30"`) and a gapped one carrying a non-list answer and a
  `NULL` pid (named `"10" "30" NA NA`), and closes with a loop asserting over
  both fixtures that `names(out)` equals the pid read back off each record.
- **AC6 — verified.** The same run's four items are all in
  `tests/testthat/test-ci-workflows.R` — failures at `:59`, `:64`, `:65` and the
  `:66` `subscriptOutOfBoundsError`. `git diff --name-only b07beb3 HEAD` names
  ten files (three under `benchmarks/`, two under `cairn/`, and
  `helper-orchestration.R`, `helper-parallel.R`, `helper-time-budget.R`,
  `test-nested-tune-bayes-results.R`, `test-suite-hygiene.R` under
  `tests/testthat/`); `test-ci-workflows.R` is not among them, so no failure and
  no error falls in a file this branch touches. Round 1's fifth item,
  `test-parallel-interrupt.R:108`, did not fire in this run — the timing
  interaction the amendment moved out of the promise.
- **AC3 — verified.** `TESTTHAT_PARALLEL=FALSE Rscript -e 'devtools::test(filter
  = "nested-workflow-map-oracles")'` on the branch head: `[ FAIL 0 | WARN 0 |
  SKIP 0 | PASS 108 ]`, and the serial fixture-cache report reads `8 signatures,
  8 builds, 13 requests` with no "built more than once" line. The hand call's
  signature — `nested_fit_resamples(workflow, folds, metrics = ms)`, the
  `memoised()` call at `test-nested-workflow-map-oracles.R:29` — reports
  `builds 1 / requests 6`, one request per name in `MAP_FNS`
  (`helper-orchestration.R:2564-2571`, six). Built once across six `fn` blocks,
  so once across the five the criterion names.
- **AC4 — verified**, each of the five sites read against the code under it on
  the branch head.
  1. `benchmarks/time-examples.R:1,27` reads "(M74, AC6)" and "the way AC6
     reads the branch point against the branch head". `git show
     accfbe2^:cairn/milestones/M074-suite-speed.md` carries AC1-AC6, and its AC6
     is the examples criterion, which compares the two refs. Accurate.
  2. `tests/testthat/test-nested-tune-bayes-oracles.R:431-433` calls its
     reference "the one the default oracle above built, served from the cache".
     Both blocks open `d <- make_reg_data()`, whose `seed = 4242` default is set
     inside the helper (`helper-orchestration.R:6-7`), so the two workflows are
     drawn at the same stream state. The two `iter = 2, seed = 20` sites are
     `:62` and `:436`, and the serial fixture-cache report for the file (`[ FAIL
     0 | PASS 134 ]`, `6 signatures, 6 builds, 8 requests`) shows that
     signature at `builds 1 / requests 2`. Accurate.
  3. `.github/workflows/R-CMD-check.yaml:119-120` reads "in 30 on four legs, 40
     on windows"; the step cap at `:176` is `windows-latest && 40 || 30` over a
     five-leg matrix carrying one `windows-latest`. Accurate.
  4. `benchmarks/profile-tests.R:130-140` with
     `profile-tests-parallel.R:205-216`: the drift T5 named was the duplicate
     per-run print, which carried no comment of its own and which T6 removed.
     Those lines now hold the optional-packages report and the wall-clock line,
     with no comment sitting on them, so nothing there states anything about the
     code.
  5. `tests/testthat/helper-time-budget.R:57-62` names both BC12
     `shared_daemons()` sites and claims they are "the ledger's only rows
     carrying a `times` above 1". `grep -n "times = "` over the file returns
     `:767` and `:847` as the only rows above the `times = 1L` default (plus the
     `tb_row()` signature at `:63` and its passthrough at `:69`), and both are
     BC12's. Accurate as a claim; round 1's finding 3 about the cited grep's
     reach is carried to triage separately.
- **AC5 — verified.** `Rscript benchmarks/profile-tests.R 2` emits one `run 1/2:`
  count line — `run 1/2: pass 9587 | fail 4 | skip 0 | suite 622.6 s | wall
  625.0 s` — and `Rscript benchmarks/profile-tests-parallel.R 2` one — `run 1/2:
  pass 9587 | fail 4 | skip 0 | WALL 225.0 s`. `grep -c '^run 1/2:'` returns 1
  on each log. Each script's other `run 1/2` line is the progress line, which
  carries no colon and no counts, and each run's `run 2/2:` line follows.

**Consistency gate — clean, both halves.** Universal: `cairn_validate.py` exit
0, every check PASS, 18 `references staleness` advisories and no `release
window` advisory; no `DESIGN.md` principle changed, so `cairn_impact.py` was
skipped. Toolchain (`r-package` profile): `devtools::document()` left the tree
unchanged; `pkgdown::check_pkgdown()` reported no problems;
`devtools::check()` `Status: OK`, 0 errors / 0 warnings / 0 notes in 8m 58s;
`air format --check` clean on every `.R` file the branch touches. `README.Rmd`
and `README.md` last changed in the same commit (`28c3b14`) and neither is in
this diff; `NEWS.md` needs no entry, the tier being internal.

**Independent review — three-lens fan-out**, fresh context, distinct evidence
bases. The two [S] lenses converged on the [O] lens's top items; the merged,
de-duplicated list is below, ranked as the [O] lens ranked it. Round 1's six
findings are all present in it.

- **[S] blame-history: 5 findings**, every one a duplicate of the merged list.
  Its clean list: T6's removal preserves the in-loop reporting M76 added, T3's
  reordering contradicts no recorded decision, and the AC7→AC6 and BC12
  site-naming fixes match M74's recorded follow-ups O6 and O11.
- **[S] prior-review: 5 findings**, all duplicates, each rooted in an archived
  M74/M76 review lesson. GitHub probe: one real inline comment repo-wide, on a
  workflow file this branch does not touch, and no inline comments on the PRs
  that touched these files — no thread walk warranted. It declined to flag
  M079's supersession of O4 and O7 as a contradiction, reading it as a
  documented reversal under IP4.
- **[O] diff-bug: 15 findings.**

  1. `helper-orchestration.R:103-108` — `fit_resamples_results()` still says
     "the recipe step id is drawn from the stream", contradicting the branch's
     own new comment at `:78-80`; the first `set.seed(seed)` at `:110` it
     justifies is now inert. Verified: `fixed_workflow()` carries `id =
     "pca_fixed"`, `det_nested()` reseeds itself and `reg_metrics()` draws
     nothing.
  2. AC6 as amended binds failures in two test files in practice — of the ten
     files the diff names, five are outside `tests/`, and testthat attributes a
     failure to the test file rather than to a helper.
  3. `helper-orchestration.R:2598-2604` — `wset_results()`'s "the recipe step
     ids are drawn from the stream" and its `force(data)` rationale hold for
     `wset_two()`, which still draws through `det_workflow()` (verified: no `id
     =` there), and not for `wset_fixed()`.
  4. `helper-orchestration.R:2535-2536` — `plain_workflow()`'s "no recipe step
     id drawn from the stream" contrast no longer distinguishes it from
     `fixed_workflow()`.
  5. AC2 promises a property of `daemon_state_snapshot()`, but the new block
     drives `name_by_pid()` directly; dropping the call at `helper-parallel.R:219`
     would leave the block green. The naming logic itself the lens traced and
     found correct.
  6. `helper-time-budget.R:61-62` — "the ledger's only rows carrying a `times`
     above 1" is a universal claim the cited `grep 'times = 2L'` cannot check;
     it misses a `times = 3L` row and self-matches the comment. The substance is
     accurate (verified: `:767` and `:847`, both BC12's, are the only rows above
     the default).
  7. `cairn/ROADMAP.md:4` — the hygiene stamp claims 23,460 bytes; `wc -c`
     reports 23,327.
  8. `test-nested-tune-bayes-results.R:296-307` — the restored run is live and
     un-memoised, paying back suite time M74 spent, with no seconds recorded.
     The assertion's logic the lens traced and found sound.
  9. `test-suite-hygiene.R` — the new block is the file's first that reads no
     source, and the header still enumerates only the parse-token rules.
  10. AC3's "the five `fn` blocks" undercounts; `MAP_FNS` holds six and the
      promise holds a fortiori.
  11. `helper-orchestration.R:74-78` pins `2 builds / 6 requests` and `1 / 6`,
      whose 6 is `length(MAP_FNS)` and drifts if an orchestrator is added.
  12. The `test-parallel-interrupt.R:108` flake got no candidate row, though the
      work log said it was worth one (verified: no ROADMAP row mentions it).
  13. AC5 was unticked with no Review evidence when the lens read the file —
      resolved since; AC5's evidence is above.
  14. `benchmarks/profile-tests.R:128` keeps a `cat("\n")` whose counterpart the
      parallel script lost with the removed block.
  15. `helper-parallel.R:227-229`'s "Were `order()`'s `na.last` ever `FALSE`"
      describes an argument as if it were a setting; the mechanism it states is
      correct.

**Triage at the approval gate.** No finding demonstrated an acceptance
criterion failing, so none met the return floor.

- **Fixed now** (1, 3, 4, 6): the three stale rationales in
  `helper-orchestration.R` now say what the code does — `fit_resamples_results()`
  records that its pre-build seed has no draw left to protect and is kept for
  the shape it shares with its siblings, `wset_results()` splits the rationale
  between `wset_two()`, which still draws through `det_workflow()`, and
  `wset_fixed()`, which does not, and `plain_workflow()` contrasts on having no
  recipe rather than on where an id comes from. `helper-time-budget.R` now cites
  `grep -n 'times = [0-9]'`, which returns the three rows that set the argument
  (`:65`, `:769`, `:849`) and does not match its own comment. `air format
  --check` clean on both files; `devtools::test(filter = "suite-hygiene")`
  `[ FAIL 0 | PASS 32 ]`.
- **Fixed now** (12, 7): a ROADMAP candidate row for the
  `test-parallel-interrupt.R:108` flake, and the hygiene stamp rewritten to stop
  restating a byte figure that had drifted from the file twice — `wc -c` at each
  pass is the procedure now. Two wide rows compressed to pay for the additions;
  `wc -c` 23,946 of 24,000.
- **Follow-up** (5, 8, 9): one candidate row, "M079's review remainders".
- **Accepted with the limit recorded** (2): AC6 binds failures in two test files
  in practice. Put to the user at the gate, AC6 having spent both its amendment
  rounds; accepted as verified, the suite-wide comparison living in T7, which
  ran both refs and is what surfaced the interrupt flake.
- **Rejected** (10): AC3's five-versus-six undercount leaves the promise holding
  a fortiori, and amending it would convene a gate for a criterion already met.
  (11): the pinned `2 builds / 6 requests` figures name their producing
  procedure and file, which is what the derived-figures rule asks. (13):
  resolved — AC5's evidence is recorded above. (14): cosmetic asymmetry between
  two benchmark scripts. (15): the phrasing describes an argument as a setting,
  and the mechanism it states the lens confirmed correct.

**Conversation read.** PR #89 carries no reviews, no conversation comments and
no unresolved threads.
