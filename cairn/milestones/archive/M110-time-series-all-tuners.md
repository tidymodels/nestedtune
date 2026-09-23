# M110: Rolling-origin and sliding-window designs under every orchestrator

**Status:** done (2026-09-23, PR #125 https://github.com/tidymodels/nestedtune/pull/125)

**Goal:** The rolling-origin and sliding-window outer designs that M108 supports under `nested_tune_grid()` are tested and documented under the five other orchestrators.

**Outcome:** No package code changed. Tests show `nested_tune_bayes()`, both racing tuners and `nested_tune_sim_anneal()` matching their reference loops on `ts_rolling_nested()` and `ts_sliding_nested()`, and `nested_fit_resamples()` matching `tune::fit_resamples()` on the rebuilt outer splits. `nested_final_fit()` matches a reference on each tuner's rolling-origin result, and on the Bayesian and fit_resamples sliding-window results. The references take the inner design through `reference_inner()` and an `inner_design` argument. `nested_workflow_map()` matches `hand_call()` on the rolling-origin design, and `hand_call()` moved to `helper-orchestration.R`. The tests sit in `test-time-series-bayes.R`, `-race.R`, `-anneal.R` and `-designs.R`, and the Bayes and race files join `Config/testthat/start-first`. The help of the orchestrators and `nested_resamples()`, and `NEWS.md`, state the support.

**Decisions:** D-074 (the support widened to every orchestrator), D-075 (the map on rolling-origin alone, and what the final fit reads).

**Review:** All seven criteria verified at `dc35bf8`, and `devtools::check()` gave 0 notes. The blame-history and prior-review lenses found nothing. The diff-bug lens ranked 15 findings. The gate fixed F1, F8 and F10 (D-075), F6 (design-class checks), F9 (a sliding-window fit_resamples final fit), F11 (oracle records) and F14 (seed columns). F2 and F4 were fixed after CI timed out two ubuntu legs at their 30 min step cap: the tests passed, but a 169 s file ran late and alone. Split in four, the leg went green at 28.8 min. F3 went to the fixture-key candidate row. F5 resolved, F7 and F15 noted, F12 and F13 rejected. Hygiene extended the M16 suite-time lesson and corrected the PROFILE start-first line.
