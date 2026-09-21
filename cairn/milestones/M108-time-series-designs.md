# M108: Rolling-origin and sliding-window outer designs

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, IP4, GP2
- **Resolves:** —
- **Surface tier:** user-facing — states which outer designs the package supports
- **Branch/PR:** —

## Goal

The package tests and documents `rolling_origin()` and `sliding_window()` outer designs, which run today with no test and no stated support.

## Scope

**In:** `nested_tune_grid()` and `nested_final_fit()` over `rolling_origin()` and `sliding_window()` outer designs, each with a `rolling_origin()` inner design. `nested_resamples()` building the same designs. `augment()`'s refusal message naming the cause a time-series design has. A D-entry and help text stating the support.

**Out:** `sliding_index()`, `sliding_period()`, and the other five orchestrators over time-series designs. These go to a candidate row added with this plan.

## Acceptance criteria

- [ ] AC1: `nested_tune_grid()` runs over an `rsample::nested_cv()` design whose outer and inner resamples are both `rolling_origin()`. Each fold's selection and outer metrics equal those of `reference_nested_loop()` (`tests/testthat/helper-orchestration.R`) on the same design, tested.
- [ ] AC2: The AC1 test also passes for a design whose outer resamples are `sliding_window()` and whose inner resamples are `rolling_origin()`.
- [ ] AC3: `nested_resamples()` accepts `rolling_origin()` and `sliding_window()` as `outside`, with `rolling_origin()` as `inside`. For both designs, a test asserts that every outer and inner analysis and assessment set matches `rsample::nested_cv()` row for row, as `expect_outer_identical()` and `expect_inner_identical()` check.
- [ ] AC4: `nested_final_fit()` on the AC1 result completes, and its `predict()` output equals a reference built in the test. The reference is `tune::tune_grid()` over the recorded inner design on the full data, then the recorded selection rule, then `fit()`.
- [ ] AC5: With `save_pred = TRUE` on the AC1 design, `collect_predictions()` returns one row per outer-assessment row per fold, tested. `augment()` on that result raises an error the test names by class. Its message names rows that no fold held out, not a repeated or Monte Carlo design.
- [ ] AC6: A D-entry records support for `rolling_origin()` and `sliding_window()` outer designs under `nested_tune_grid()` and `nested_final_fit()`. The help of `nested_tune_grid()` and `nested_resamples()` names both, and `NEWS.md` describes the support. `devtools::check()` gives 0 errors, 0 warnings, and no note absent from the check of `main` at the branch point.

## Coverage

- AC1 → T1
- AC2 → T1
- AC3 → T2
- AC4 → T3
- AC5 → T4
- AC6 → T5

## Tasks

- [ ] T1: Build the two designs as test fixtures with `rsample::nested_cv()`, and write the AC1 and AC2 oracle tests against `reference_nested_loop()`. A mismatch here is a defect to fix, not a test to loosen.
- [ ] T2: Run `nested_resamples()` on both designs and write the AC3 split-identity tests. If the constructor refuses either design, lift the refusal only where the D-entry's reasoning covers it.
- [ ] T3: Write the AC4 final-fit test and its reference.
- [ ] T4: Fit `augment()`'s refusal message (`R/nested-results-collect.R:710`) to the design it refuses, and write the AC5 tests.
- [ ] T5: Write the D-entry, the help and `NEWS.md` text, then run `devtools::document()`, the prose sweeps from the verify slot, and `devtools::check()`.

## Work log

- 2026-09-21: created by /milestone-plan. A probe on `main` at `74c0a95` ran `nested_tune_grid()` over a six-fold `rolling_origin()` design to completion.
- 2026-09-21: criteria audit ran in full mode and returned five findings, all fixed above. They were an unnamed oracle, an unset inner design, a split identity the constructor cannot meet, `save_pred` unstated, and a support claim wider than the tests.
- 2026-09-21: plan gate chose a support claim bounded to what is tested over probing every orchestrator and sliding design, because it halves the milestone; falsified by a user report of a failure on a design or orchestrator the claim leaves out.

## Decisions

## Review
