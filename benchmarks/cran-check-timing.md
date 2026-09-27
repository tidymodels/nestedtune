# The check under CRAN's conditions

What `R CMD check --as-cran` costs when it runs the way CRAN runs it, before
and after the tests outside the CRAN smoke layer began to call
`skip_heavy_on_cran()` (`tests/testthat/helper-cran.R`, M118). Re-run the
command below on the same machine to get a comparable figure. Each condition
below is part of the measurement.

| Condition | Value |
|---|---|
| Machine | Apple M5 Pro, macOS 27.0, on mains power |
| R | 4.6.1 (2026-06-24) |
| testthat | 3.3.2 |
| `NOT_CRAN` | unset, as on CRAN |
| `NESTEDTUNE_FULL_SUITE` | unset |
| `TESTTHAT_CPUS` | 2, the most cores CRAN allows a package |
| Suggests | all installed |

The command, run in an empty directory:

```sh
R CMD build /path/to/nestedtune
env -u NOT_CRAN -u NESTEDTUNE_FULL_SUITE TESTTHAT_CPUS=2 \
  _R_CHECK_CRAN_INCOMING_=false \
  /usr/bin/time -p R CMD check --as-cran --no-manual nestedtune_*.tar.gz
```

The test figures are the `Running 'testthat.R' [cpu/elapsed]` line that
`R CMD check` prints. The whole-check figure is the `real` line of
`/usr/bin/time`, which times `R CMD check` alone and not the build.

## Branch point and head

The CRAN-conditions baseline ran at `fde0ba1`. The branch point `2e50d31` is
the next commit. That commit added the plan and changed no file outside
`cairn/`, so both trees give the same figures.

| Tree | Run | Tests CPU | Tests elapsed | CPU / elapsed | Whole check | Pass | Skip | Fail |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `fde0ba1` | 1 | 560 s | 278 s | 2.01 | 370.1 s | 10840 | 81 | 0 |
| `2af34dc` | 1 | 94 s | 45 s | 2.09 | 134.3 s | 6540 | 107 | 0 |
| `2af34dc` | 2 | 96 s | 46 s | 2.09 | 133.9 s | 6540 | 107 | 0 |
| `2af34dc` | 3 | 92 s | 45 s | 2.04 | 133.0 s | 6540 | 107 | 0 |

The head's medians are 94 s of test CPU and 133.9 s for the whole check. In
every run, the examples took 19 to 20 s and the vignette rebuild took 44 to
47 s. This change does not touch either one.

The skip count rises by 26, not by 41, as read from the "Skipped tests" list in
each run's `tests/testthat.Rout`. At `fde0ba1`, 16 of the 81 skips were in the
41 files that now skip, and 65 were in the other files. At the head, each of
the 41 files reports one skip, and the other files report 66. The one added
skip is the new block in `test-ci-workflows.R`. It skips because the built
package holds no `.github/` folder.

## The full suite, where it still runs

`devtools::test()` sets `NOT_CRAN=true`, so it runs every test. The same holds
for every CI job, because `r-lib/actions/setup-r` sets `NOT_CRAN: true` for the
steps after it. The `R-CMD-check.yaml` legs also set `NESTEDTUNE_FULL_SUITE: true`.

| Tree | Blocks | Pass | Fail | Skip |
|---|---:|---:|---:|---:|
| `2e50d31` (branch point) | 994 | 11503 | 0 | 0 |
| `2af34dc` (head) | 1000 | 11512 | 0 | 0 |

The six added blocks are the four in `test-skip-heavy.R` (5 expectations) and
the two in `test-ci-workflows.R` (4 expectations). Both trees ran through
`devtools::test()` with the `SummaryReporter`, on the machine above.

## Seconds per file at the branch point

Each file's seconds are the sum of its blocks' times, read from the
`[hang-trace]` start and end lines in `tests/testthat.Rout` of the
`fde0ba1` run above. The blocks sum to 541 s. The last column says whether the
file runs on CRAN at the head. `test-skip-heavy.R` is new at the head and runs
on CRAN.

| File | Seconds | On CRAN at head |
|---|---:|---|
| `test-nested-results-print.R` | 31.2 | skips |
| `test-time-series-designs.R` | 30.3 | skips |
| `test-nested-tune-race-oracles.R` | 27.2 | skips |
| `test-nested-tune-grid-oracles.R` | 23.4 | skips |
| `test-nested-tune-bayes-oracles.R` | 20.9 | skips |
| `test-nested-tune-finalize.R` | 18.2 | skips |
| `test-time-series-bayes.R` | 17.8 | skips |
| `test-nested-tune-grid-failures.R` | 17.7 | skips |
| `test-model-spec-input.R` | 17.1 | skips |
| `test-time-series-race.R` | 17.0 | skips |
| `test-nested-workflow-map-oracles.R` | 16.0 | skips |
| `test-augment.R` | 12.7 | skips |
| `test-nested-final-fit-identity.R` | 12.4 | skips |
| `test-nested-tune-sim-anneal-oracles.R` | 12.2 | skips |
| `test-eval-time.R` | 12.2 | skips |
| `test-nested-final-fit-results.R` | 12.0 | skips |
| `test-nested-final-fit-oracles.R` | 11.8 | skips |
| `test-nested-tune-grid-results.R` | 11.4 | skips |
| `test-metrics-argument.R` | 10.6 | skips |
| `test-time-series-anneal.R` | 10.4 | skips |
| `test-nested-final-fit-print.R` | 10.4 | skips |
| `test-nested-final-fit-rng.R` | 10.2 | skips |
| `test-nested-tune-bayes-rng.R` | 8.8 | skips |
| `test-nested-tune-grid-checks.R` | 8.0 | runs |
| `test-compute-metrics.R` | 7.9 | skips |
| `test-nested-results-agreement.R` | 7.9 | skips |
| `test-selection-metric.R` | 7.7 | skips |
| `test-nested-tune-race-checks.R` | 7.3 | runs |
| `test-resample-weights.R` | 7.1 | skips |
| `test-nested-workflow-map-readers.R` | 6.8 | runs |
| `test-nested-tune-bayes-results.R` | 6.5 | skips |
| `test-nested-tune-grid-rng.R` | 6.4 | skips |
| `test-nested-tune-race-rng.R` | 6.1 | skips |
| `test-nested-final-fit-race.R` | 5.9 | skips |
| `test-nested-fit-resamples-oracles.R` | 5.8 | skips |
| `test-param-info.R` | 5.8 | skips |
| `test-collect-metrics-wide.R` | 5.8 | runs |
| `test-autoplot-filter.R` | 5.5 | skips |
| `test-nested-results-plot.R` | 5.4 | skips |
| `test-nested-final-fit-extract.R` | 5.2 | runs |
| `test-nested-tune-sim-anneal-rng.R` | 5.1 | skips |
| `test-nested-final-fit-checks.R` | 5.0 | runs |
| `test-nested-workflow-map-rng.R` | 4.6 | skips |
| `test-nested-final-fit-sim-anneal.R` | 4.4 | runs |
| `test-event-level.R` | 4.2 | skips |
| `test-nested-tune-sim-anneal-checks.R` | 3.9 | runs |
| `test-nested-tune-bayes-checks.R` | 3.6 | runs |
| `test-fixture-cache.R` | 3.2 | skips |
| `test-collect-readers.R` | 2.9 | runs |
| `test-extract-procedure.R` | 1.9 | runs |
| `test-nested-final-fit-predict.R` | 1.9 | runs |
| `test-nested-final-fit-set.R` | 1.8 | runs |
| `test-dplyr-compat.R` | 1.7 | runs |
| `test-parallel-classify.R` | 1.6 | runs |
| `test-selection-rule.R` | 1.3 | runs |
| `test-hang-trace.R` | 1.2 | runs |
| `test-nested-resamples-memory.R` | 1.2 | runs |
| `test-vctrs-compat.R` | 0.8 | runs |
| `test-nested-workflow-map-checks.R` | 0.8 | runs |
| `test-parallel-identity.R` | 0.6 | runs |
| `test-nested-fit-resamples-rng.R` | 0.6 | skips |
| `test-nested-fit-resamples-checks.R` | 0.5 | runs |
| `test-nested-resamples-specs.R` | 0.4 | runs |
| `test-dots-barrier.R` | 0.4 | runs |
| `test-control-slots.R` | 0.4 | runs |
| `test-suite-hygiene.R` | 0.4 | runs |
| `test-nested-final-fit-resamples.R` | 0.3 | runs |
| `test-parallel-payload.R` | 0.3 | runs |
| `test-nested-fit-resamples-readers.R` | 0.3 | runs |
| `test-nested-resamples-identity.R` | 0.3 | runs |
| `test-id-columns.R` | 0.3 | runs |
| `test-nested-results-set-compat.R` | 0.3 | runs |
| `test-help-structure.R` | 0.2 | runs |
| `test-tuner-registry.R` | 0.2 | runs |
| `test-selection-rule-installed.R` | 0.2 | runs |
| `test-workflow-pkgs.R` | 0.1 | runs |
| `test-parallel-detection.R` | 0.1 | runs |
| `test-workflow-identity.R` | 0.1 | runs |
| `test-nested-resamples-regressions.R` | 0.1 | runs |
| `test-covr-traces.R` | 0.1 | runs |
| `test-predict-results.R` | 0.1 | runs |
| `test-nested-tune-grid-leakage.R` | 0.1 | runs |
| `test-nested-resamples-rng.R` | 0.1 | skips |
| `test-sweep-prose.R` | 0.0 | runs |
| `test-ci-workflows.R` | 0.0 | runs |
| `test-format-inline.R` | 0.0 | runs |
| `test-parallel-interrupt.R` | 0.0 | runs |
| `test-parallel-required-pkgs.R` | 0.0 | runs |
| `test-parallel-metrics.R` | 0.0 | runs |
