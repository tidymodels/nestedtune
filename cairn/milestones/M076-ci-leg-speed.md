<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M076: The two slow check legs run their check step under the cap the other three use

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — CI workflow configuration and test-file organization; no exported behavior, documentation or shipped artifact changes
- **Branch/PR:** `m076-ci-leg-speed` / https://github.com/tidymodels/nestedtune/pull/86

## Goal

Rebalance the parallel test run so the windows and devel `check-r-package`
steps earn the 30-minute cap the other three legs carry.

## Scope

**In:** local pricing of the two test-suite levers M74's re-cut left
unpriced — splitting `test-parallel-identity.R` at its daemon-pool section
boundaries, and re-ordering `Config/testthat/start-first` by measured
per-file time — and adopting each only where it pays. One CI round of three
attempts on the finished head, each leg's `timeout-minutes` set from its
measured median, and the yaml cap comment and `cairn/PROFILE.md`
test-doctrine slot brought to the measured figures.

**Out:** the check-time vignette rebuild (197–240 s on windows against
125–157 s before M74) → the candidate row this milestone leaves, which names
its two shapes: pre-rendered vignette sources, and moving the two heaviest
pages to `vignettes/articles/`. The `test-coverage` leg's 14-minute target →
the same row. Any change to what a test asserts → nothing here moves a claim.

## Acceptance criteria

- [x] AC1: The sorted list of `test_that()` descriptions extracted from every
      `tests/testthat/test-*.R` file on the merged head is identical to the
      list extracted the same way at the branch point.
- [x] AC2: Every leg the workflow's `strategy.matrix.config` lists whose
      measured `check-r-package` step median is at or below 24 minutes reads
      `timeout-minutes: 30`.
- [x] AC3: `Rscript -e 'devtools::test()'` and `Rscript -e 'devtools::check()'`
      are clean on the merged head (the profile's verify and consistency-gate
      slots).

## Coverage

- AC1 → T2
- AC2 → T3, T4
- AC3 → T2, T3

## Tasks

- [x] T1: Price the two levers locally. Record per-file wall-clock medians of
      three parallel runs (`TESTTHAT_CPUS` at the runners' four) at the branch
      point and under each lever separately, into `benchmarks/`, naming head,
      machine, R version and worker count. `benchmarks/profile-tests.R` pins
      itself serial, so this is a second measurement mode, not that script.
- [x] T2: Revert both levers on the branch, on T1's figures — the split of
      `test-parallel-identity.R` and the `start-first` re-ordering — leaving
      `benchmarks/profile-tests-parallel.R` and T1's record in place.
- [x] T3: Push the branch, re-run the check workflow three times on one head,
      and record each leg's `check-r-package` step duration and median in this
      file, naming the head and its net diff outside `cairn/`.
- [ ] T4: Set each leg's `timeout-minutes` from its T3 median, and bring the
      yaml cap comment and `cairn/PROFILE.md`'s test-doctrine slot to those
      figures.
- [x] T5: Close the absorbed CI-timing candidate row, or re-cut it to what T3
      measured and what stays unpriced.

## Work log

- 2026-09-08: created by /milestone-plan. Absorbs the CI-timing candidate row added 2026-09-07 at M74's re-cut.
- 2026-09-08: criteria audit ran in reduced mode (internal tier) with a fresh [O] reader over the drafted wording; eight findings, all disposed before the gate. Three of four drafted criteria bound records rather than the branch (a levers-landed-or-work-logged promise, the yaml/PROFILE recording clauses, a pass/fail/skip harness-report clause); two promised domains only authored lists or exemption registries reach; one cited a `--descriptions` flag `benchmarks/profile-tests.R` does not carry. The measurement and the record writing moved to T1, T5 and T6; the ledger criterion became T4.
- 2026-09-08: AC4 was added after that audit, unread by it — the template's standing code-milestone criterion naming the profile's verify and consistency-gate slots, bounded by the two commands it names, binding the branch rather than a record.
- 2026-09-08: plan gate chose caps-follow-the-measurement over promising the windows median lands under 24, because no measurement yet says the two test levers are worth the three minutes and the alternative fails the milestone for a reason outside it; falsified by T1 pricing the levers well past three minutes, which would make the harder promise safe to make.
- 2026-09-08: plan gate chose local per-lever pricing plus one CI round over measuring each lever on the runners, because a CI round is five legs times three attempts and both levers are assertion-neutral; falsified by a lever whose local and runner figures disagree in sign, the local core count differing from the runners' four.
- 2026-09-08: plan gate left the check-time vignette rebuild out over pre-rendering it or moving pages to `articles/`, because both change what ships to users and the second is a documentation decision, not a speed one; falsified by T5 showing the test levers cannot reach 24 without it.
- 2026-09-08: implement gate chose four test workers for the local pricing (the runners' count, not this machine's eighteen), split-file names saying which pool each holds, and a new sibling benchmark script rather than a mode on `benchmarks/profile-tests.R`, whose header pins itself serial.
- 2026-09-08: T1 part: `benchmarks/profile-tests-parallel.R` measures suite wall clock with the files parallel, reading per-file wall clock from the hang-trace reporter's stamps because a testthat result's `real` column is 0 for every test under parallel files. Branch point `9b91e18` at 4 workers, 18-core macOS, R 4.6.1, testthat 3.3.2: 198.0 s median over three runs (196.6-199.4); longest single file 81.9 s.
- 2026-09-08: T1 part: `start-first` reordered by measured time, split not applied, measured 202.8 s median (201.9-205.3) -- slower than the branch point on non-overlapping ranges.
- 2026-09-08: the split was implemented and green before it was priced and reverted (commit `c2a5bdd`, then the old T2/T4): three files one pool each, the four serial-reference builders moved to a helper, the time-budget ledger re-keyed over all 30 identity call sites, `devtools::test()` clean and the 756 `test_that()` descriptions sorting identical to the branch point. That is what T1 priced.
- 2026-09-08: checkpoint, T1 unfinished: the split's own pricing is mid-run and its first two runs read 220.1 s and 239.4 s against the 198.0 branch point, which is the oversubscription T2 was told to price rather than assume.
- 2026-09-08: T1 done. Four configurations at 4 workers, three runs each (five for the last), all `pass 9517 | fail 0 | skip 0`; `benchmarks/test-timing-parallel.md` owns the table. Branch point 198.0 s median against a 194.4 s perfect-packing floor of its own work, so the queue carries 1.9% slack and no re-ordering can recover more than that; re-ordering alone 202.8 s, the split alone 220.1 s, both 201.1 s. The split adds work rather than repacking it -- 862.1 s of file wall against 777.6 -- being three daemon-pool starts and three worker package-loads where there was one, and a 4-vCPU runner pays that more than this 18-core machine does.
- 2026-09-08: amendment, on T1: both levers reverted and the criteria set narrowed. Dropped the one-pool-per-file criterion, which described only the world where the split landed; the other three keep their wording unchanged, renumbered AC1-AC3, and Coverage with them. Scope now promises pricing both levers and adopting each only where it pays. Tasks re-cut to five: T1 pricing (done), T2 the revert, T3 the CI round, T4 the caps, T5 the candidate row. No re-audit reader was spawned: no criterion's wording changed, one was dropped and three renumbered.
- 2026-09-08: T2 done. `DESCRIPTION`, `test-parallel-identity.R`, `helper-time-budget.R`, `test-suite-hygiene.R` and `test-parallel-metrics.R` restored to `9b91e18`; the two split files and `helper-parallel-identity.R` deleted. Net diff outside `cairn/` is now `benchmarks/profile-tests-parallel.R` and `benchmarks/test-timing-parallel.md`. `devtools::test()` clean at 9517 passing, the branch-point count.
- 2026-09-08: implement gate chose opening the PR from this phase over reusing M74's figures or deferring to review, because `R-CMD-check.yaml` fires on a branch only through `pull_request` (no `workflow_dispatch`, push restricted to the default branch) and T4's cap edit is a code change that belongs on the branch before review. PR https://github.com/tidymodels/nestedtune/pull/86; review reuses it. Its `concurrency` block cancels superseded runs on a non-default ref, so the three attempts run one after another.
- 2026-09-08: T3 done. Three attempts on head `d8b8ef6`, whose net diff outside `cairn/` is `benchmarks/profile-tests-parallel.R` and `benchmarks/test-timing-parallel.md`, both under the `^benchmarks$` `.Rbuildignore` entry, so the package `R CMD check` saw is the default branch's. `check-r-package` step minutes per leg, attempt order, median in brackets: windows 19.7, 25.7, 25.3 [25.3]; devel 20.8, 18.8, 23.7 [20.8]; macOS 19.5, 17.4, 19.3 [19.3]; oldrel-1 16.0, 17.6, 24.5 [17.6]; ubuntu release 17.8, 19.0, 22.7 [19.0]. All five legs green on all three. Attempts are sequential: the workflow's `concurrency` block cancels a superseded run on a non-default ref.
- 2026-09-08: the `test-coverage` leg failed once at `readRDS(f): error reading from connection` inside `covr::merge_coverage` (run 34287906318). Same failure identity on M74's and M75's branches (runs 34172488510, 34238384255, 34240761747), and this branch changes nothing `covr` sees, so it is pre-existing and intermittent, not this milestone's. The profile declares `covr` a diagnostic and the leg non-gating; carried to the review gate rather than fixed here.
- 2026-09-08: T4 part: `.github/workflows/R-CMD-check.yaml`'s step cap is now `matrix.config.os == 'windows-latest' && 40 || 30`, devel having measured a 20.8-minute median; the yaml comment holds every attempt and the per-leg spread, up to 8.5 minutes across three attempts, which is why a median of three sets the cap. `cairn/PROFILE.md`'s test-doctrine slot brought to the same figures.
- 2026-09-08: corrected in `cairn/PROFILE.md`, marked in place: the run is not bounded by its largest file. At four workers it takes 198 s against a longest file of 82 s, and sits within 2% of its own perfect-packing floor, so `start-first` buys only that a long file cannot land last.
- 2026-09-08: T5 done. The candidate row re-cut, both its promotion conditions having fired: the test levers measured short of 24 on windows, and the coverage leg failed at 18m23s against its 20-minute job cap. Its remaining half is the check-time vignette rebuild, no longer waiting on a test-suite lever. `ROADMAP.md` was already 17 bytes over its 24,000 budget before this row; four other rows compressed to 23,937, each cross-referencing a record that owns the detail it lost.
- 2026-09-08: AC3 evidence: `devtools::test()` 9517 pass / 0 fail / 0 skip, and `devtools::check()` Status OK, 0 errors, 0 warnings, 0 notes.
- 2026-09-08: `cairn/PROFILE.md` crossed its 120-line cap on M76's edits (124). Compressed in one pass on its heaviest section, the CI-divergences bullet of the test-doctrine slot, 26 lines to 23: what went is narration the cited artifacts already carry — the two hang durations, the M48 cap history, and M76's per-attempt figures, all in the workflow yaml comments or git. File at 118; `cairn_validate` green.
- 2026-09-08: all five tasks done; status to review. Package code, tests and DESCRIPTION are byte-identical to the branch point `9b91e18`; the branch's whole diff outside `cairn/` is the two `benchmarks/` files and the workflow cap edit.

## Decisions

- 2026-09-08: review. AC1-AC3 verified with fresh evidence (medians re-derived from the GitHub API, `devtools::test()` 9517/0/0, `devtools::check()` OK/0/0/0); consistency gate green, `cairn_validate` exit 0. Three fresh-context reviewers plus one gate finding: 16 findings, none demonstrating a criterion failing and none in package code, so no return floor fires; triage goes to the gate.

## Review

### Acceptance-criteria evidence

- AC1 verified 2026-09-08. `test_that()` descriptions parsed from every
  `tests/testthat/test-*.R` with R's own parser (a walk over the parse tree,
  literal first arguments only), at HEAD `aa3312d` and at the branch point
  `9b91e18`: 755 descriptions each, sorted lists byte-identical (`diff` empty).
  `git diff 9b91e18 HEAD -- tests/ R/ DESCRIPTION NAMESPACE man/ vignettes/` is
  also empty, so the package content the criterion ranges over never moved.
- AC2 verified 2026-09-08, medians re-derived at review from the GitHub API
  rather than read back from the record: run 34287906467, three attempts, all
  five legs green on each. `check-r-package` step minutes, attempt order,
  median in brackets -- windows 19.67, 25.68, 25.32 [25.32]; devel 20.78,
  18.82, 23.70 [20.78]; macOS 19.47, 17.43, 19.27 [19.27]; oldrel-1 16.00,
  17.63, 24.48 [17.63]; ubuntu release 17.77, 18.97, 22.67 [18.97]. Four legs
  sit at or below 24; the workflow's expression
  `matrix.config.os == 'windows-latest' && 40 || 30` yields 30 for each of
  them, and windows at 25.32 is outside the criterion's domain and keeps 40.
  The current head `aa3312d` ran green under those caps (run 34295176957):
  devel 24.08 and oldrel-1 24.03 against 30, windows 26.73 against 40.
- AC3 verified 2026-09-08 on HEAD `aa3312d`. `Rscript -e 'devtools::test()'`:
  `FAIL 0 | WARN 0 | SKIP 0 | PASS 9517`. `Rscript -e 'devtools::check()'`:
  `Status: OK`, 0 errors, 0 warnings, 0 notes, duration 7m21.8s.

### Consistency gate

- `cairn_validate.py` exit 0: every check PASS, four advisories OK, one WARN
  (`references staleness`, 18 pages) that is pre-existing and untouched here.
- No `DESIGN.md` principle changed (`Principles touched: —`), so `cairn_impact`
  is skipped.
- Profile (`r-package`) consistency-gate slot: `devtools::document()` leaves no
  diff; no generated file hand-edited; `README.Rmd` and `README.md` last moved
  in the same commit and neither is in this diff; `pkgdown::check_pkgdown()`
  reports no problems; no `NEWS.md` entry owed, the milestone changing nothing
  user-visible; the two new files sit under `benchmarks/`, already covered by
  `.Rbuildignore`'s `^benchmarks$`; `devtools::check()` clean as above.
- Weight caps by hand: `ROADMAP.md` 23,932 B / 53 lines, `LESSONS.md` 19,902 B
  / 49 lines, `PROFILE.md` 118 lines. All under budget; `LESSONS.md` is 98 B and
  one line from its cap.

### Independent review

Three fresh-context reviewers, distinct evidence bases: [O] over the full
`origin/main...HEAD` diff against the criteria, DESIGN and DECISIONS; [S] over
`git log`/`blame` on the modified lines and the archive; [S] over the prior
review record. One gate finding (G1) from the review session's own
verification. Findings ranked by their reporter, most severe first.

- G1: the yaml comment and the T3 work-log line pin the measurement to head
  `d8b8ef6`, which is the pull-request merge ref as it stood then and no longer
  resolves in this repo (`git cat-file -t d8b8ef6` fails; the ref now points at
  `e173cd9`). The measured branch head was `3b313dd`, run 34287906467, three
  attempts. A pinned figure in a code-adjacent artifact must name a commit a
  later reader can resolve.
- O1: the `÷ 4 workers` column in `benchmarks/test-timing-parallel.md` is
  `sum of per-file wall / 4`, and the ratio of wall clock to that column is
  1.019, 1.021, 1.021, 1.018 across the four arms -- so "within 2% of a perfect
  packing" holds of every configuration by construction, including the two the
  milestone rejects, and describes worker utilization rather than the amount of
  work. Propagated into the yaml comment and `PROFILE.md`.
- O2: "the split adds work" is contradicted by the file's own two split rows --
  split-only and split+reorder measure identical package content and differ only
  in queue order, yet their sums are 862.1 s and 789.9 s, so the quantity called
  "work" moves with ordering and the headline +10.9% is not an added-work figure.
- O3: "Splitting one file into three turns one daemon-pool start into three and
  one worker package-load into three" is wrong on the second half.
  `testthat:::queue_setup` passes the package load as a per-worker `load_hook`
  to `task_q$new(concurrency = num_workers, ...)`, so package loads equal the
  worker count whatever the file count.
- O4: the split conclusions rest on overlapping ranges. Split-only is 220.1
  (191.6-239.4) against a branch point of 198.0 (196.6-199.4), so one split run
  beat every branch-point run; split+reorder is 201.1 (185.0-203.2). Only the
  reorder arm is separated from the baseline. The honest statement is that
  neither split arm shows a gain, not that splitting adds work. The
  split+reorder arm also got five runs where the others got three, unexplained.
- O5: the reorder arm confounds ordering with membership. The file describes it
  as "the sixteen heaviest files longest-first"; `DESCRIPTION`'s `start-first`
  carries eleven names, so the arm changed the size of the priority set as well
  as its order, and 202.8 vs 198.0 cannot be attributed to ordering alone.
- O6: `benchmarks/profile-tests-parallel.R` sets `TESTTHAT_CPUS` only, but
  `testthat:::default_num_cpus()` returns `getOption("Ncpus")` first when it is
  set -- and `Rscript` reads the user's `~/.Rprofile`. The header then prints
  `workers: 4 (TESTTHAT_CPUS)` regardless, so a maintainer with
  `options(Ncpus = 18)` gets a comparison that looks valid and is not.
- O7: `T4` is unticked and its work is described as done in three work-log
  lines, the last of which reads "all five tasks done". AC1 and AC2 were ticked
  by the plan/implement path's own convention, so the inconsistency is not a
  convention.
- O8: `PROFILE.md`'s compression removed the two hang locations (52 min under
  `R CMD check`, 40 min under `covr`) that made "hence the two scopes" follow;
  the surviving sentence names one code site and the clause no longer parses as
  an argument.
- O9: `PROFILE.md` keeps "queues the slowest files first, so a long file cannot
  land last -- and that is all it buys" in a bullet whose point is that the
  lever was priced, while M76 measured queueing by actual measured time 2.4%
  slower than the current list on non-overlapping ranges.
- O10: `.github/workflows/R-CMD-check.yaml`'s job-cap comment still reads "The
  step cap still ends a hung test suite in 30", false on the windows leg at 40.
  Pre-existing, but inside the comment M76's scope brought to the measured
  figures. Separately: devel's 20.8-minute median plus the 8.5-minute
  within-leg spread the same comment documents reaches 29.3, 42 s under the new
  cap -- a consequence of AC2 as written, not a coding error.
- O11: the `med()` comment in `benchmarks/profile-tests-parallel.R` is garbled
  -- "`[[` on a name `per_file` does not carry raises "subscript out of bounds""
  -- a clause is missing. The code it describes is correct.
- O12: smaller script items -- `max(elapsed)` without `na.rm` prints `NA` for
  LONGEST SINGLE FILE in the case `med()` defends against; the `real`-column
  claim is "near zero", not zero, and the subprocess's own `proc.time()` rides
  on each message as `m$time`; one `sprintf()` with a constant and no arguments;
  three env vars set process-wide with no `withr` restore (consistent with the
  serial sibling); the `load_package = "source"` rationale is moot because
  `queue_setup` rewrites `"none"` to `"source"` unconditionally.
- O13: bookkeeping -- the work log says the compressed `ROADMAP.md` is 23,937 B
  where `wc -c` reads 23,932; the re-cut candidate row is titled "The windows
  leg's last three minutes" where the measured gap from 25.3 to AC2's 24 is 1.3;
  Coverage maps AC3 to T2 and T3, but T3 is the CI round and produces no local
  check evidence.
- P1: `benchmarks/profile-tests-parallel.R` copies the two-tier per-run
  pass/fail/skip printing that M74's review flagged on its sibling
  `benchmarks/profile-tests.R` (finding O10, "duplicate per-run count
  printing"), which was deferred rather than fixed and is still present on the
  default branch. An unresolved lesson carried forward, not a fixed defect
  undone.
- [S] blame-history: no history conflicts. The 40-minute devel cap was set on
  pre-M74 observations and M74 cut the suite without re-measuring; M76 supplies
  that measurement, so the drop to 30 is a re-measurement rather than a
  reversion. The `start-first` correction in `PROFILE.md` is marked in place per
  the repo's convention and no live file still asserts the superseded claim.
- [S] prior-PR-comments, secondary surface: the existence probe found one real
  human inline comment in the repo (topepo, PR #30). Walking the PRs that
  touched these files (#84, #82, #62, #86) found no inline review comments on
  any of them.

The review session verified O3, O5, O6, O10 and O11 against the implementation
rather than the reporter's account, and refutes part of O1: `sum / 4` is a valid
makespan lower bound for four workers, so "no reordering of the branch point can
recover more than 1.9%" stands on its own terms. What O1 establishes is that the
figure cannot discriminate between configurations and should not be read as one
arm being better packed than another.

### PR conversation

- conversation: PR #86 -- no reviews, no conversation comments, no unresolved
  review threads. Nothing to triage.
