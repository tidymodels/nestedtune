# M125: augment() on repeated and Monte Carlo designs

- **Status:** review
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

- [x] AC1: The design under test holds some data row out more than once and every row at least once. On it, `augment()` returns one row per data row, in the data's order. Each prediction column holds the value `collect_predictions(res, summarize = TRUE)` gives for that row's `.row`. A test asserts this on a repeated v-fold design for a regression, a probability classification and a censored regression. A second test asserts it for a regression on a Monte Carlo design, after it shows that the design holds every row out.
- [x] AC2: An outer design that leaves some data row out of every assessment set is refused with class `nestedtune_augment_rows`. The message names those rows, up to the first five of them. A test asserts this on a Monte Carlo design with such a row, on a rolling-origin design, and on an overlapping sliding-window design.
- [x] AC3: On a run where some folds failed, a row that only failed folds held out holds a missing value in every prediction column. The call warns once with class `nestedtune_partial_summary`. A test asserts both on a repeated v-fold design.
- [x] AC4: On a design that holds each row out exactly once, `augment()` joins the saved predictions without averaging. It returns the same table as before this milestone. The existing `test-augment.R` tests for such designs pass.
- [x] AC5: The `augment.nested_results` help page says which designs are accepted. It says that repeated predictions are averaged as `collect_predictions(summarize = TRUE)` averages them. It says that a design holding each row out once joins the saved predictions as they are. The `augment()` bullet in `NEWS.md` says so too. `devtools::check()` reports 0 errors, 0 warnings and 0 notes.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T2
- AC4 → T1, T2
- AC5 → T3, T4

## Tasks

- [x] T1: Write the AC1 to AC3 tests first in `tests/testthat/test-augment.R`. Rewrite the test at `test-augment.R:143`, which asserts that repeated and Monte Carlo designs are refused. Update the overlapping-design message assertion in `test-time-series-designs.R:345`. For AC3, break folds in every repeat that together hold one row (criteria audit). For example, break the first fold of repeat one with `break_fold()`, and the repeat-two folds holding its rows. Run the tests and record that they fail.
- [x] T2: Change `check_held_out_once()` in `R/nested-results-collect.R` to refuse only rows held out never. For a row held out more than once, `augment.nested_results()` joins M124's averaged table. Append a D-entry that supersedes D-063's refusal clause. It says that M124's two oracles, tune's own average and a base R one, meet the precondition D-063 named. On the averaged path, refuse saved quantile predictions with class `nestedtune_summarize_quantile` (implement gate). The refusal names the first five rows never held out, not cli's first three and last two. It uses one message for every design, so `TIME_SERIES_SPLITS` and its test go (implement gate).
- [x] T3: Update the `augment.nested_results` help page, the set help line at `R/nested-results-set.R:24`, and the `augment()` bullet in `NEWS.md`. Run `Rscript benchmarks/sweep-prose.R --plain` and `--roxygen --plain`.
- [x] T4: Run `devtools::document()`, `devtools::test()`, `devtools::check()` and `pkgdown::check_pkgdown()`.

## Work log

- 2026-09-28: created by /milestone-plan, split from M124 at the plan gate.
- 2026-09-28: criteria audit (full mode, fresh [O] reader) read both drafts. Here it limited AC1 to designs that hold a row out more than once, so AC4 and AC1 cannot disagree on a postprocessed class. It pinned the five-row truncation in AC2 and named the tests to rewrite.
- 2026-09-28: plan gate chose refusing designs with rows never held out over tune's `NA` rows, keeping today's refusal; falsified by users needing them augmented.
- 2026-09-28: implement gate chose two things. The averaged path refuses quantile predictions with the existing class `nestedtune_summarize_quantile`. Every design gets one refusal message, with no time-series hint. Found that cli's truncation names the first three and last two rows, not AC2's first five. T2 now covers both (minor amendment).
- 2026-09-28: T1 done. Eight tests in `test-augment.R` (AC1 x4, AC2 x2, AC3, quantile refusal) and three rewritten in `test-time-series-designs.R`, with shared `never_held_rows()` and `expect_names_never_held()` in `helper-predictions.R`. All eleven fail on the old code. The `TIME_SERIES_SPLITS` test is removed.
- 2026-09-28: checkpoint, T2 and T3 written but not ticked. `check_held_out()` replaces `check_held_out_once()`, `augment()` averages on repeated designs, D-092 appended, help pages and NEWS updated. `test-augment.R`, `test-time-series-designs.R`, `test-collect-predictions-summarize.R`, the doc-reading test files, both prose sweeps and `check_pkgdown()` are clean. The full `devtools::test()` run is still pending.
- 2026-09-28: T2 and T3 done. Full `devtools::test()`: 13054 expectations, 0 failed, 0 errors.
- 2026-09-28: checkpoint, T4 started. `devtools::check()` and the claim audit ([O] fresh reader) are running.
- claim audit: 50 claims read, 3 corrected — R/nested-tune-grid.R, tests/testthat/helper-predictions.R, NEWS.md
- 2026-09-28: the same reader re-read the three corrections and the singular "that row" wording in `check_held_out()`, and all held. `test-augment.R`, `test-time-series-designs.R`, `test-help-structure.R`, `test-sweep-prose.R` and both prose sweeps are clean after the fixes.
- 2026-09-28: T4 done on 332efcf0. `devtools::check()`: 0 errors, 0 warnings, 0 notes. `document()` left no diff, and `check_pkgdown()` found no problems. Full `devtools::test()` passed on the T2 code, and only docs, a comment and one message line changed after it. Status set to review.
- 2026-09-28: review checkpoint. AC1 to AC4 are verified and ticked. `devtools::check()` for AC5 is still running. The three reviewers reported, and their findings await triage at the gate.
- 2026-09-28: step-7 approval: m125-augment-repeated-designs approved for merge, after the gate fixes pass.

## Decisions

## Review

Evidence gathered 2026-09-28 on 7f3b8058. `main` had not moved since the branch was cut, so no merge was needed. Test runs set `NESTEDTUNE_FULL_SUITE=true` and `NOT_CRAN=true`: without them both files skip whole.

- AC1: `test-augment.R` and `test-time-series-designs.R` ran together, 52 blocks and 595 expectations, 0 failed, 0 errors, 0 skipped. The four AC1 tests pass (repeated v-fold regression, probability classification and censored regression, and Monte Carlo regression). `expect_averaged_augment()` checks that every row is held out and some row more than once. It then compares each prediction column with `collect_predictions(summarize = TRUE)` matched on `.row`, in data order. The Monte Carlo test first asserts `never_held_rows()` is empty.
- AC2: the same run. The Monte Carlo test passes, with more than five rows left out and some rows held out twice. The rolling-origin and overlapping sliding-window tests in `test-time-series-designs.R` pass too. Each asserts class `nestedtune_augment_rows` and the exact "first five" text through `expect_names_never_held()`. A second test covers two rows and one row named in full.
- AC3: the same run. The failed-fold test breaks fold 1 and the repeat-two fold holding its first row. It asserts one warning of class `nestedtune_partial_summary` and `NA` in every prediction column for exactly the rows only those folds held out. The other rows equal the averaged table.
- AC4: the `test-augment.R` tests for once-designs (lines 57 to 139 and 376 on) are unchanged by the branch and pass in the same run. A direct check also ran. Three saved runs on once-designs went through `augment()` under `main`'s source and under the branch. They were a regression, a probability classification, and a regression with one failed fold. The output was `identical()` for all three.
- AC5: `man/augment.nested_results.Rd` says the design must hold every row out at least once (line 48). It says a design holding each row out once joins the saved predictions as they are (line 51). It says repeated predictions take the `collect_predictions(summarize = TRUE)` average (line 57). The `augment()` bullet in `NEWS.md` (lines 227 to 237) says the same three things. `devtools::check()` on 7f3b8058 reported 0 errors, 0 warnings and 0 notes in 7m 59s. It sets `NOT_CRAN=true`, so the full suite ran.
- Consistency gate: `cairn_validate.py` passed, with 18 advisory WARNs on reference-page staleness only. `devtools::document()` left no diff. `pkgdown::check_pkgdown()` found no problems. All six gating prose sweeps are clean. `NEWS.md` has the entry. The branch adds no top-level file, does not touch README, and changes no DESIGN.md principle, so `cairn_impact` was skipped.

Independent review: three fresh lenses ran, [O] diff-bug, [S] blame-history and [S] prior-review. The prior-review lens found one real PR comment, on an unrelated file. None of the findings shows a criterion failing, so none moves status back. The proposed dispositions below go to the gate.

- O2, S-blame 1 and S-prior 2 (one finding): D-092 names only D-063, but M125 also removes what D-078 decided, the time-series overlap message and `TIME_SERIES_SPLITS`. Proposed: fix now, with a new D-entry that corrects D-092 to supersede D-078's `augment()` message clause.
- S-prior 1: `check_no_quantile()` gives `verb` a default through `arg_match()`, and the `collect_predictions()` call omits it. M100's review made `verb` required on the sibling `check_predictions_rows()`. Proposed: fix now, with `verb` required and passed at both calls.
- O3: on a repeated design, a postprocessed `.pred_class` is recomputed from the averaged probabilities. The help says so, but no `augment()` test covers it. Proposed: fix now, with a planted-class test.
- O4: AC4's "without averaging" is caught only by the classification test, because forced averaging leaves regression output identical. Proposed: fix now, with a planted `.pred_class` on a once-design that must survive `augment()`.
- O5: the "held out more than once" count includes failed folds, and the help does not say so. Proposed: fix now, with one help sentence.
- O11: "A v-fold or grouped v-fold design holds out each row once" is false for `group_vfold_cv(repeats = 2)`. Proposed: fix now, adding "without repeats".
- O14: the quantile test tells the two messages apart only by the word "augment". Proposed: fix now, matching the x-bullet text.
- O1: the ROADMAP candidate row on `collect_predictions(summarize = TRUE)` edge cases says to promote it "when M125 reuses the helper", and M125 does. Proposed: follow-up, rewriting that row at hygiene to say `augment()` now shares the edge cases.
- O8: the censored `NULL` for a row only failed folds held out is untested on the averaged path. Proposed: follow-up, into the same row.
- O9: the name-collision check runs after averaging, so an averaging edge case errors first. Proposed: follow-up, into the same row.
- O6: the AC1 oracle calls the same averaging helper as the code. Proposed: reject, because AC1 names this oracle and M124 checked it against tune's average and a base R one.
- O7: the set help's averaging claim has no repeated-design set test. Proposed: reject, because the set method binds each workflow's `augment()`, which the existing bind test pins.
- O10: the separate NEWS bullet on the five-row naming describes a change to an unreleased feature. Proposed: reject, because NEWS keeps such bullets within the development version.
- O12: the quantile test uses a plain column in place of hardhat's `quantile_pred`. Proposed: reject, because this predates M125 and D-091 records why.
- O13: `hold_counts()` and two inline counts repeat `never_held_rows()`. Proposed: reject as style.

Gate triage, 2026-09-28: the maintainer accepted every proposed disposition.

- Fixed on the branch. D-093 appended, correcting D-092. `check_no_quantile()` takes a required `verb`, passed at both calls. Two tests in `test-augment.R` plant a class that disagrees with the probabilities. On a once-design it survives. On a repeated design it is recomputed, with ties going to the first level. Forcing the averaged path on in the namespace failed the once-design test. The help now says "without repeats" and that the hold-out count reads failed folds too. The quantile test matches the x-bullet text.
- After the fixes: `test-augment.R` ran 198 expectations with 0 failed, and `test-time-series-designs.R`, `test-collect-predictions-summarize.R`, `test-help-structure.R` and `test-sweep-prose.R` were clean. The six prose sweeps, `document()` with no further diff, `check_pkgdown()` and `air format --check` were clean.
- `devtools::check()` on the fixed tree (5b36f377) reported 0 errors, 0 warnings and 0 notes in 8m 2s.
- Follow-up (O1, O8, O9): the averaging edge-case candidate row is rewritten at hygiene.
- Rejected (O6, O7, O10, O12, O13), with the reasons above.
