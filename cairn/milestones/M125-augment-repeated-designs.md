# M125: augment() on repeated and Monte Carlo designs

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M124
- **Driving RR:** —
- **Principles touched:** GP1, GP3, IP4
- **Resolves:** —
- **Surface tier:** user-facing — it changes which designs an exported method accepts
- **Branch/PR:** m125-augment-repeated-designs

## Goal

`augment()` accepts a nested run whose outer design holds every data row out at least once, and joins each row's averaged prediction.

## Scope

**In:** `check_held_out_once()` refuses only a design that leaves some row out of every assessment set. When a row is held out more than once, `augment()` joins M124's averaged table. On a design that holds each row out once, it joins the saved predictions as now. One D-entry supersedes D-063's refusal clause. The help pages and `NEWS.md` state the change.

**Out:** a design that leaves a row never held out stays refused. tune joins `NA` there, and the plan gate chose the refusal (work log). The averaging itself → M124.

## Acceptance criteria

- [ ] AC1: The design under test holds some data row out more than once and every row at least once. On it, `augment()` returns one row per data row, in the data's order. Each prediction column holds the value `collect_predictions(res, summarize = TRUE)` gives for that row's `.row`. A test asserts this on a repeated v-fold design for a regression, a probability classification and a censored regression. A second test asserts it for a regression on a Monte Carlo design, after it shows that the design holds every row out.
- [ ] AC2: An outer design that leaves some data row out of every assessment set is refused with class `nestedtune_augment_rows`. The message names those rows, up to the first five of them. A test asserts this on a Monte Carlo design with such a row, on a rolling-origin design, and on an overlapping sliding-window design.
- [ ] AC3: On a run where some folds failed, a row that only failed folds held out holds a missing value in every prediction column. The call warns once with class `nestedtune_partial_summary`. A test asserts both on a repeated v-fold design.
- [ ] AC4: On a design that holds each row out exactly once, `augment()` joins the saved predictions without averaging. It returns the same table as before this milestone. The existing `test-augment.R` tests for such designs pass.
- [ ] AC5: The `augment.nested_results` help page says which designs are accepted. It says that repeated predictions are averaged as `collect_predictions(summarize = TRUE)` averages them. It says that a design holding each row out once joins the saved predictions as they are. The `augment()` bullet in `NEWS.md` says so too. `devtools::check()` reports 0 errors, 0 warnings and 0 notes.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T2
- AC4 → T1, T2
- AC5 → T3, T4

## Tasks

- [x] T1: Write the AC1 to AC3 tests first in `tests/testthat/test-augment.R`. Rewrite the test at `test-augment.R:143`, which asserts that repeated and Monte Carlo designs are refused. Update the overlapping-design message assertion in `test-time-series-designs.R:345`. For AC3, break folds in every repeat that together hold one row (criteria audit). For example, break the first fold of repeat one with `break_fold()`, and the repeat-two folds holding its rows. Run the tests and record that they fail.
- [ ] T2: Change `check_held_out_once()` in `R/nested-results-collect.R` to refuse only rows held out never. For a row held out more than once, `augment.nested_results()` joins M124's averaged table. Append a D-entry that supersedes D-063's refusal clause. It says that M124's two oracles, tune's own average and a base R one, meet the precondition D-063 named. On the averaged path, refuse saved quantile predictions with class `nestedtune_summarize_quantile` (implement gate). The refusal names the first five rows never held out, not cli's first three and last two. It uses one message for every design, so `TIME_SERIES_SPLITS` and its test go (implement gate).
- [ ] T3: Update the `augment.nested_results` help page, the set help line at `R/nested-results-set.R:24`, and the `augment()` bullet in `NEWS.md`. Run `Rscript benchmarks/sweep-prose.R --plain` and `--roxygen --plain`.
- [ ] T4: Run `devtools::document()`, `devtools::test()`, `devtools::check()` and `pkgdown::check_pkgdown()`.

## Work log

- 2026-09-28: created by /milestone-plan, split from M124 at the plan gate.
- 2026-09-28: criteria audit (full mode, fresh [O] reader) read both drafts. Here it limited AC1 to designs that hold a row out more than once, so AC4 and AC1 cannot disagree on a postprocessed class. It pinned the five-row truncation in AC2 and named the tests to rewrite.
- 2026-09-28: plan gate chose refusing designs with rows never held out over tune's `NA` rows, keeping today's refusal; falsified by users needing them augmented.
- 2026-09-28: implement gate chose two things. The averaged path refuses quantile predictions with the existing class `nestedtune_summarize_quantile`. Every design gets one refusal message, with no time-series hint. Found that cli's truncation names the first three and last two rows, not AC2's first five. T2 now covers both (minor amendment).
- 2026-09-28: T1 done. Eight tests in `test-augment.R` (AC1 x4, AC2 x2, AC3, quantile refusal) and three rewritten in `test-time-series-designs.R`, with shared `never_held_rows()` and `expect_names_never_held()` in `helper-predictions.R`. All eleven fail on the old code. The `TIME_SERIES_SPLITS` test is removed.

## Decisions

## Review
