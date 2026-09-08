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
  measured order, the sixteen heaviest files longest-first.

| configuration | runs | sum of per-file wall | ÷ 4 workers | wall clock, median (range) |
|---|---|---|---|---|
| branch point | 3 | 777.6 s | 194.4 s | **198.0 s** (196.6–199.4) |
| reorder only | 3 | 794.8 s | 198.7 s | 202.8 s (201.9–205.3) |
| split only | 3 | 862.1 s | 215.5 s | 220.1 s (191.6–239.4) |
| split + reorder | 5 | 789.9 s | 197.5 s | 201.1 s (185.0–203.2) |

## What the numbers say

The `÷ 4 workers` column is the floor a perfect packing of that configuration's
own work could reach. The branch point runs 1.9% above its floor, so the queue
is already almost fully packed and **there is no idle worker time for a
reordering to recover**. That is the finding that governs both levers: on four
workers this suite is bound by how much work it contains, not by how the work
is arranged, and neither lever removes any work.

The split is worse than neutral — it *adds* work. Splitting one file into three
turns one daemon-pool start into three and one worker package-load into three,
and the totals show it: 862.1 s against 777.6 s measured alone (+10.9%), and
789.9 s when the three files are also queued early (+1.6%), the gap between
those two being what queueing the new files late costs. On a 4-vCPU runner the
added pool starts contend with the test workers for cores that do not exist
here, so this machine understates the cost rather than overstating it.

The longest single file is `test-nested-tune-bayes-oracles.R` at 81.9 s, well
under the 198 s wall, which is the same fact from the other side: no single
file is the critical path, so making one file shorter cannot shorten the run.

Both levers were reverted on the strength of these figures (M76). What is left
that would move this number is removing work, not rearranging it.
