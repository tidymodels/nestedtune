# M156: Test code cites no line numbers and names no tracking records

**Status:** done (2026-10-23, PR #173 https://github.com/tidymodels/nestedtune/pull/173)

**Goal:** Clear the tracking leftovers that M152, M154 and M155's reviews filed against the test code, as the candidate row "Clear tracking leftovers from test code" lists them.

**Outcome:** Tests, comments in two `R/` files and two benchmark scripts; no help page, NEWS or behavior change.
- `file:line` comment citations in `tests/testthat/` and `R/` (AC1's grep) now name the call, block or test; the four `helper-time-budget.R` notes name the `daemons(0)` calls by role.
- Renamed `ac1_control()` to `early_stop_control()`, `PRINT_AS_AGREED_M46` to `PRINT_AS_AGREED`, `CLASSIFY_BUDGET_PRE_M16_S` to `CLASSIFY_BUDGET_BEFORE_CUT_S`; `benchmarks/test-time-budget.R` prints "before the waits were cut" and lost its M14 and M16 ids.
- Four test names lost history ("branch point", "pre-milestone", "used to emit", "as the criteria describe") and two lost "before any fold runs"; 14 "criterion" and "criteria" comments state the property.
- `R/parallel.R`: the `workflow_pkgs()` comment names test-parallel-interrupt.R and test-parallel-payload.R, both `object = NULL`; the `.args` comment drops 25,714,635 B and 4,701,505 B for the ratio test-parallel-payload.R asserts on its default fixture.
- Seed-identity assertions left the `nested_fit_resamples()` and `nested_workflow_map()` refusal tests, since `restore_rng()` is registered before the draw. "the refusals fire before the RNG is drawn from" is gone; "the shared entry checks fire, in the shared shapes" asserts its three refusals by class (the metrics one by `rlang_error` and "metric_set").
- Plan: three candidate rows merged into one for the ROADMAP caps; the reduced criteria audit fixed five criteria before the plan was pushed.

**Decisions:** milestone-local only: removing the seed checks over replacing them with `last_dispatch()` checks; plain edits over extending `benchmarks/sweep-test-comments.R`. None promoted.

**Review:** Four-lens fan-out, two passes, one defect return (AC5: the metrics refusal was asserted by message only). Pass 1: 12 fixed, 6 to a row, 8 rejected; pass 2: 5 comment fixes, 1 to the row, 8 rejected. The blame lens's claim that seed identity showed a refusal preceding the draw was rejected as false. Follow-ups went to the new row "Fix the leftovers of M156's review". `devtools::test()` 1152 blocks, 0 failed, and `check()` 0/0/0, both twice. CI: the push-triggered prose-sweep was cancelled at its 10-minute cap inside `setup-r` and passed on rerun; the first CI wait hit the tool ceiling. The local PR-record, CI-stop and resume commits were dropped by `--delete-branch`; this summary carries them. Row "Clear tracking leftovers from test code" graduated; "Clear milestone ids from R comments" was filed at plan. No lesson added; none retired; none unparked.
