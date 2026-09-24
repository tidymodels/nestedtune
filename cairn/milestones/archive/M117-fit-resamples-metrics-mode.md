# M117: `nested_fit_resamples()` refuses a metric set that does not suit the model's mode

**Status:** done (2026-09-24, PR #132 https://github.com/tidymodels/nestedtune/pull/132)

**Goal:** `nested_fit_resamples()` refuses a metric set that does not suit the model's mode before any fold runs, as the five tuning functions do since M116. `nested_workflow_map()` does the same for every workflow it routes there.

**Outcome:** `nested_loop()` calls `check_metrics_mode()` for every tuner and keeps the result as `first_metric` only where `tuner_selects()` holds. A `nested_fit_resamples()` record still has no `first_metric`. A set for the wrong mode now stops that function with class `nestedtune_metrics_mode` before any fold runs. Before, every fold failed and the call warned. `nested_workflow_map()`'s pre-check resolves each workflow's set through `map_args()` on every route. A workflow routed to `nested_fit_resamples()` is therefore judged too, whether `fn` names that function or a tuner. The help of both functions and the unreleased M116 `NEWS.md` bullet say the refusal covers them. `test-selection-metric.R` gained tests for both methods and both map routes. The M116 map test now counts `run_orchestrator()` calls instead of warnings.

**Decisions:** D-082 supersedes D-081's clause that `nested_fit_resamples()` keeps its old behavior. The change is an error with no deprecation period, because the package has no release.

**Review:** First pass, with no return. `devtools::check()` gave 0 errors, 0 warnings and 0 notes, and the suite passed 11503 expectations. Three fresh reviewers found no defect. Six minor findings were rejected at the gate. They were an older help line naming `fit_resamples()` and the route assertion, which the oracle tests already make. The others were the warning-based evidence, the double metric resolution, a roxygen line break, and the waived deprecation. The first CI wait reached its timeout, and the resumed review merged on green CI. No lesson was added or retired.
