# The suite's wall clock with the files running in parallel

Produced by `benchmarks/profile-tests-parallel.R`, which is the parallel
counterpart to `benchmarks/profile-tests.R` (serial, per-file seconds; its
figures are in `benchmarks/test-timing-baseline.md`). Read that script's
header for why the two modes are two scripts.

**Conditions.** Commit `9b91e18`, and three variants of it described below.
macOS Tahoe 26.6.2, 18 cores, R 4.6.1, testthat 3.3.2, `NOT_CRAN=true`,
`TESTTHAT_CPUS=4`. Four workers rather than this machine's eighteen because
four is what the three check workflows set for the ubuntu and windows runners
(`cairn/PROFILE.md`, test-doctrine slot): with eighteen workers every file
gets its own at once and the queue order cannot matter at all. Every run
reported `pass 9517 | fail 0 | skip 0`.

Per-file seconds are each file's own wall clock in the worker queue, read from
the start/end timestamps `HangTraceReporter` writes to stderr
(`tests/testthat/helper-hang-trace.R`). A testthat result's `real` column is 0
for every test under parallel files, the timing being taken in the parent,
which does no work.

## What was measured

Two levers, priced separately and together against the branch point:

- **split** — `tests/testthat/test-parallel-identity.R` cut at its two
  daemon-pool section boundaries into three files, one pool each.
- **reorder** — `Config/testthat/start-first` in `DESCRIPTION` rewritten in
  measured order, the sixteen heaviest files longest-first. Note that the
  branch point's list carries eleven names, so this arm changed the size of the
  priority set as well as its order and does not isolate ordering on its own.

| configuration | runs | sum of per-file wall | ÷ 4 workers | wall clock, median (range) |
|---|---|---|---|---|
| branch point | 3 | 777.6 s | 194.4 s | **198.0 s** (196.6–199.4) |
| reorder only | 3 | 794.8 s | 198.7 s | 202.8 s (201.9–205.3) |
| split only | 3 | 862.1 s | 215.5 s | 220.1 s (191.6–239.4) |
| split + reorder | 5 | 789.9 s | 197.5 s | 201.1 s (185.0–203.2) |

## What the numbers say

The `÷ 4 workers` column is the makespan floor a perfect packing of that
configuration's own occupancy could reach. **It bounds one configuration
against itself and cannot rank two of them** — the wall/floor ratio is 1.019,
1.021, 1.021 and 1.018 down the table, so "within 2%" is true of every arm
here, the rejected ones included. Read as the bound it is: the branch point
runs 1.9% above its own floor, so **there is no idle worker time for a
reordering of the branch point to recover**. On four workers this suite is
bound by how much work it contains, not by how that work is arranged.

Neither split arm shows a gain, and the split-only arm's totals point at added
cost. Splitting one file into three turns one daemon-pool start into three;
worker package-loads do *not* multiply with it, `testthat:::queue_setup`
passing the load as a per-worker `load_hook` to
`task_q$new(concurrency = num_workers, ...)`, so they stay at the worker count
whatever the file count. Occupancy totals: 862.1 s against 777.6 s measured
alone (+10.9%), and 789.9 s when the three files are also queued early (+1.6%).
Those two arms hold identical package content and differ only in queue order,
so the 72 s between them is queueing cost, not work — which is why the +10.9%
is an upper bound on the split's cost rather than a measurement of it. On a
4-vCPU runner the added pool starts contend with the test workers for cores
that do not exist here, so this machine understates that cost rather than
overstating it.

The longest single file is `test-nested-tune-bayes-oracles.R` at 81.9 s, well
under the 198 s wall, which is the same fact from the other side: no single
file is the critical path, so making one file shorter cannot shorten the run.

**What the wall-clock ranges do and do not settle.** Only the reorder arm is
separated from the branch point (201.9–205.3 against 196.6–199.4). The two
split arms overlap it heavily — split-only ran 191.6–239.4 and split+reorder
185.0–203.2, each with a run faster than every branch-point run — so three (and
five) runs do not establish that splitting is slower, only that neither arm
shows a gain. The split+reorder arm got five runs rather than three because its
first three spread widely enough to be worth extending; the extra runs did not
narrow it much.

Both levers were reverted on the strength of these figures (M76): the reorder
arm measured slower on non-overlapping ranges, and the split arms bought
nothing while adding a pool start per file. What is left that would move this
number is removing work, not rearranging it.
