# M092: A nested run answers compute_metrics() and augment()

**Status:** done (2026-09-14, PR #105 https://github.com/tidymodels/nestedtune/pull/105)

**Goal:** A user scores the saved out-of-fold predictions of a nested run with a new metric set, and joins them onto the data rows, through two tune generics.

**Outcome:** `compute_metrics.nested_results()` in `R/nested-results-collect.R` scores each completed fold's `.predictions` through the metric set by the recorded fold labels. It reuses `per_fold_metrics()`, which gained a `frames` argument, and `summarize_folds()`. It refuses a metric set whose prediction type the run did not save (`nestedtune_metric_type_not_saved`). `augment.nested_results()` counts hold-outs over every fold's split and refuses a count other than 1 (`nestedtune_augment_rows`). It places each fold's `.pred*` columns by `.row` after the outcome. The set methods in `R/nested-results-set.R` go through `stack_set()`. `tune::compute_metrics` is re-exported. The PR adds two help pages, `_pkgdown.yml` rows and a NEWS bullet. The tests are in `test-compute-metrics.R` and `test-augment.R`.

**Decisions:** D-063 records the methods, the recorded-level `event_level` default and the refusal of repeated designs.

**Review:** one pass, all seven criteria verified. `devtools::check()` gave 0 errors, 0 warnings and 0 notes. The three-lens review found nothing in history or prior reviews and seven findings in the diff. Two were fixed at the gate. The `augment()` help now says failed-fold rows hold `NULL` in a list column. A new test scores a new metric set at the second event level. Follow-up: one candidate row holds three findings. A row missing from saved predictions gets a silent NA, and a repeated `.row` overwrites. The set test does not pass `event_level`. Rejected: base R errors for a bad `summarize` or a missing `metrics`, a gap `collect_metrics()` shares. One lesson added, on `document()` refusing under an older roxygen2. CI green after an `air format` commit.
