<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M076: The two slow check legs run their check step under the cap the other three use

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — CI workflow configuration and test-file organization; no exported behavior, documentation or shipped artifact changes
- **Branch/PR:** —

## Goal

Rebalance the parallel test run so the windows and devel `check-r-package`
steps earn the 30-minute cap the other three legs carry.

## Scope

**In:** the two test-suite levers M74's re-cut left unpriced — splitting
`test-parallel-identity.R` at its daemon-pool section boundaries so its two
sections run as separate testthat workers, and re-ordering
`Config/testthat/start-first` by measured per-file time. Local pricing of each
lever, one CI round of three attempts on the finished head, each leg's
`timeout-minutes` set from its measured median, and the yaml cap comment and
`cairn/PROFILE.md` test-doctrine slot brought to the measured figures.

**Out:** the check-time vignette rebuild (197–240 s on windows against
125–157 s before M74) → the candidate row this milestone leaves, which names
its two shapes: pre-rendered vignette sources, and moving the two heaviest
pages to `vignettes/articles/`. The `test-coverage` leg's 14-minute target →
the same row. Any change to what a test asserts → nothing here moves a claim.

## Acceptance criteria

- [ ] AC1: Every file under `tests/testthat/` holding a `share_daemons(` call
      starts exactly one daemon pool, over the call sites
      `grep -rn 'share_daemons(' tests/testthat/` lists.
- [ ] AC2: The sorted list of `test_that()` descriptions extracted from every
      `tests/testthat/test-*.R` file on the merged head is identical to the
      list extracted the same way at the branch point.
- [ ] AC3: Every leg the workflow's `strategy.matrix.config` lists whose
      measured `check-r-package` step median is at or below 24 minutes reads
      `timeout-minutes: 30`.
- [ ] AC4: `Rscript -e 'devtools::test()'` and `Rscript -e 'devtools::check()'`
      are clean on the merged head (the profile's verify and consistency-gate
      slots).

## Coverage

- AC1 → T2
- AC2 → T2, T3
- AC3 → T5, T6
- AC4 → T4, T5

## Tasks

- [ ] T1: Price the two levers locally. Record per-file wall-clock medians of
      three parallel runs (`TESTTHAT_CPUS` at this machine's core count) at the
      branch point and under each lever separately, into `benchmarks/`, naming
      head, machine, R version and worker count. `benchmarks/profile-tests.R`
      pins itself serial, so this is a second measurement mode, not that script.
- [ ] T2: Split `test-parallel-identity.R` (1139 lines) at its two pool-section
      boundaries — the shared 2-daemon section (`:33`–`:887`), the shared
      3-daemon section (`:889`–`:1025`) and BC3's private pool (`:1027`–) —
      so each resulting file starts exactly one pool. Watch for
      oversubscription: two files each holding a pool run concurrently on a
      4-vCPU runner, which T1 must price rather than assume.
- [ ] T3: Re-order `Config/testthat/start-first` in `DESCRIPTION` by T1's
      medians, adding the files T2 created and dropping any name that no
      longer exists.
- [ ] T4: Re-key the `helper-time-budget.R` ledger to the moved call sites and
      get `test-suite-hygiene.R` green (the ledger re-reads its sites by
      `file:line`, so T2's split renumbers them).
- [ ] T5: Push the branch, re-run the check workflow three times on one head,
      and record each leg's `check-r-package` step duration and median in this
      file, naming the head and its net diff outside `cairn/`.
- [ ] T6: Set each leg's `timeout-minutes` from its T5 median, and bring the
      yaml cap comment and `cairn/PROFILE.md`'s test-doctrine slot to those
      figures.
- [ ] T7: Close the absorbed CI-timing candidate row, or re-cut it to what T5
      measured and what stays unpriced.

## Work log

- 2026-09-08: created by /milestone-plan. Absorbs the CI-timing candidate row added 2026-09-07 at M74's re-cut.
- 2026-09-08: criteria audit ran in reduced mode (internal tier) with a fresh [O] reader over the drafted wording; eight findings, all disposed before the gate. Three of four drafted criteria bound records rather than the branch (a levers-landed-or-work-logged promise, the yaml/PROFILE recording clauses, a pass/fail/skip harness-report clause); two promised domains only authored lists or exemption registries reach; one cited a `--descriptions` flag `benchmarks/profile-tests.R` does not carry. The measurement and the record writing moved to T1, T5 and T6; the ledger criterion became T4.
- 2026-09-08: AC4 was added after that audit, unread by it — the template's standing code-milestone criterion naming the profile's verify and consistency-gate slots, bounded by the two commands it names, binding the branch rather than a record.
- 2026-09-08: plan gate chose caps-follow-the-measurement over promising the windows median lands under 24, because no measurement yet says the two test levers are worth the three minutes and the alternative fails the milestone for a reason outside it; falsified by T1 pricing the levers well past three minutes, which would make the harder promise safe to make.
- 2026-09-08: plan gate chose local per-lever pricing plus one CI round over measuring each lever on the runners, because a CI round is five legs times three attempts and both levers are assertion-neutral; falsified by a lever whose local and runner figures disagree in sign, the local core count differing from the runners' four.
- 2026-09-08: plan gate left the check-time vignette rebuild out over pre-rendering it or moving pages to `articles/`, because both change what ships to users and the second is a documentation decision, not a speed one; falsified by T5 showing the test levers cannot reach 24 without it.

## Decisions

## Review
