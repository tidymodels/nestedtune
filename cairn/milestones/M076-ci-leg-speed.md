<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M076: The two slow check legs run their check step under the cap the other three use

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — CI workflow configuration and test-file organization; no exported behavior, documentation or shipped artifact changes
- **Branch/PR:** `m076-ci-leg-speed`

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

- [ ] AC1: The sorted list of `test_that()` descriptions extracted from every
      `tests/testthat/test-*.R` file on the merged head is identical to the
      list extracted the same way at the branch point.
- [ ] AC2: Every leg the workflow's `strategy.matrix.config` lists whose
      measured `check-r-package` step median is at or below 24 minutes reads
      `timeout-minutes: 30`.
- [ ] AC3: `Rscript -e 'devtools::test()'` and `Rscript -e 'devtools::check()'`
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
- [ ] T3: Push the branch, re-run the check workflow three times on one head,
      and record each leg's `check-r-package` step duration and median in this
      file, naming the head and its net diff outside `cairn/`.
- [ ] T4: Set each leg's `timeout-minutes` from its T3 median, and bring the
      yaml cap comment and `cairn/PROFILE.md`'s test-doctrine slot to those
      figures.
- [ ] T5: Close the absorbed CI-timing candidate row, or re-cut it to what T3
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

## Decisions

## Review
