# M139: Frame the inner splits on the analysis set under a repeated outer row

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP1, GP1
- **Resolves:** —
- **Surface tier:** user-facing — it changes the tuning results of the exported nested tuning functions
- **Branch/PR:** m139-repeated-row-inner-frame

## Goal

Under an outer split whose `in_id` repeats a row, each inner tuning call gets its inner splits on the outer fold's analysis set. So tune finalizes an unknown parameter range without the outer held-out rows, as it does for every other design since M54.

## Scope

**In:** remove the early return in `analysis_framed_inner()` (`R/nested-resamples.R:470-472`) for a repeated outer `in_id`. Re-point each inner index at `rsample::analysis(split)` by occurrence. Set a logical `NA` inner `out_id` to every analysis-frame position whose data row lies in `rsample::complement()` of the split, read over the whole frame (RR09 R1). This replaces the hotfix rule of each row once (`complement_within_outer()`, `:519-545`). Rewrite the two tests that pin the old frame. Add the O1 and O2 oracle tests for this shape. Update the help, the code comments, DESIGN.md and NEWS. The change ships with no deprecation period, named in NEWS (plan gate 2026-10-01, pre-1.0).

**Out:** the final fit. It has no outer split and finalizes on the full data, its own training data (IP1's final-fit clause). An outer `in_id` that reaches past its frame stays for `last_fit()` to refuse (M54). Outer bootstrap designs stay refused (D-096, D-097). Running every tuner on this shape is not done, because RR09 Q5 found the grid run enough: one call site serves every tuner, and M54 pinned that each tuner finalizes on the frame it gets.

## Acceptance criteria

- [ ] AC1: Take an outer split whose `in_id` repeats a row and lies inside its frame, with inner splits on that frame. The `resamples` that each fold's `run_tuner()` gets carry `rsample::analysis(split)` as the frame of every inner split. Each inner analysis set holds the same data rows, in the same order and multiplicity, as the design's split read over the whole frame. So does each assessment set whose `out_id` the design holds explicitly. Shown on two fixtures: the grouped-inner design of the AC4 test in `test-nested-tune-finalize.R`, and a hand-built whole-frame inner design. (RB tripwire: ip-touching)
- [ ] AC2: Each inner index maps by occurrence. Within one split's `in_id`, and separately within its explicit `out_id`, the r-th mention of a data row maps to the r-th position of that row in the outer `in_id`. Past the last copy, the map starts again at the first copy. The grouped-inner reference sets the seed once and then evaluates `inside` on each fold's `rsample::analysis(split)` in fold order. Against it, with the rows identical first, each rebuilt `in_id` is identical to the reference `in_id`. Each rebuilt `out_id` is identical to `rsample::complement()` of the reference split. On the hand-built fixture, an inner `in_id` of `c(1L, 1L, 1L, 2:30)` maps its three mentions of row 1 to positions 1, 61 and 1.
- [ ] AC3: A logical `NA` inner `out_id` becomes every position of the analysis frame whose data row lies in `rsample::complement()` of the split, read over the whole frame. The hand-built fixture has outer `in_id` `c(1:60, 1:5)`, held-out rows 61 to 90, and inner `in_id` `1:30` and `31:60`. There the assessment set of the second split holds rows 1 to 5 twice. No assessment set holds a row of 61 to 90 or a row of its own `in_id`. (RB tripwire: ip-touching)
- [ ] AC4: Oracle O1 is analytic, from `dials::get_n_frac_range()`, the source of the O1 record in the test file. Take the AC4 repeated outer split with `stoch_workflow()` and `frac_min_n()`. `nested_tune_grid()` gives the finalizer each fold's analysis frame, 65 rows with the repeats. Every `min_n` candidate of a fold lies inside `floor(65 * FINALIZE_FRAC)`, which is 6 to 32. The whole frame gives 9 to 45.
- [ ] AC5: Oracle O2 is a live reference. One design is the grouped-inner `nested_resamples()` design. The other holds the same outer splits with the AC2 reference inner rsets. With `stoch_workflow()` and `frac_min_n()` under one seed, their inner rows are identical (asserted first). `nested_tune_grid()` returns identical `.inner_metrics` and `.metrics` for both.
- [ ] AC6: Take every hit of `grep -rniE "repeat|more than once|twice|duplicat" R/ man-roxygen/ vignettes/ README.Rmd cairn/DESIGN.md` that describes the frame of an inner tuning call. Each one states the new behavior. `devtools::document()` leaves `man/` matching the roxygen. `NEWS.md` carries one entry that names the change in results for such designs.
- [ ] AC7: `devtools::test()` and `devtools::check()` are clean (0 errors, 0 warnings, 0 notes). `Rscript benchmarks/sweep-prose.R --plain` and `--roxygen --plain` are clean.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T2
- AC4 → T3
- AC5 → T3
- AC6 → T4
- AC7 → T5

## Tasks

- [x] T1: Write the tests first in `tests/testthat/test-nested-tune-finalize.R`. Rewrite the repeated half of the AC4 test (`:349-371`), which asserts that the design's own rset reaches `run_tuner()`. Rewrite the hotfix test (`:375-417`), which asserts that the frame is the whole data. Both then assert AC1 to AC3. Add the third hand-built inner split, `c(1L, 1L, 1L, 2:30)`. Show that each new expectation fails on the plan-commit code.
- [x] T2: In `analysis_framed_inner()` (`R/nested-resamples.R:460`), replace the early return with the occurrence map. Read indices with `as.integer()`, and leave the rset unmapped when an index has no position, never writing an `NA` position. Give a logical `NA` `out_id`, tested with `identical(out_id, NA)`, the complement as `which(outer_idx %in% held)`, keeping the hotfix's `tryCatch` around `rsample::complement()`. Fold `complement_within_outer()` in or remove it. The comment names the inner bootstrap from `nested_resamples()` as the design that reaches the wrap, and says the map is exact in positions only for ascending analysis positions (RR09 R2, R3). Keep the shared-frame check and the out-of-range guard. Draw nothing from the RNG.
- [ ] T3: Add the O1 and O2 tests for the repeated shape (AC4, AC5), and name them in the oracle header of the file. Both fixture folds hold one split, and `expect_frames_are_analysis_rows()` needs one matching fold. So assert the recorded `n` of each frame and match frames by fold position. Assert `.Random.seed` identical before and after `analysis_framed_inner()` on the repeated fixture (RR09 R4). Show that O1 fails on the plan-commit code.
- [ ] T4: Update the docs. These are the `@section Finalizing a parameter range` passage (`R/nested-tune-grid.R:193-206`), the comments at `R/nested-resamples.R:431-458` and `:519-526`, and the DESIGN.md Architecture paragraph (`:341-351`). Also read the "Reproducing one fold by hand" section (`R/nested-tune-grid.R:323-327`) and the hotfix NEWS bullet, which RR09 found stay true. Add a NEWS entry. Run the AC6 grep and record the hit ledger in one work-log line. Run `devtools::document()`.
- [ ] T5: Run the verify slot: `devtools::test()`, `devtools::check()`, and both prose sweeps.

## Work log

- 2026-10-01: created by /milestone-plan from the ROADMAP candidate on the repeated-row inner frame. The full criteria audit returned nine findings, all fixed before the gate: the `out_id` comparison, the seed wording, a wrap fixture, the out-of-frame scope, the O1 fixture and row count, the O2 row check, and the reach of the grep. AC7 needed no change.
- 2026-10-01: plan gate chose mapping by occurrence over mapping to the first copy of a row. It gives the rsample indices on designs from `nested_resamples()` and keeps the assessment `.row` values distinct. Falsified by a design where the occurrence map gives an index that the outer split does not hold.
- 2026-10-01: plan gate chose to assess each copy that the outer split holds over each row once (the hotfix rule of 2026-10-01). It matches what `nested_resamples()` writes and what a design built on the analysis set gives. Falsified by a hand-built design whose scores then differ from its `nested_resamples()` equivalent.
- 2026-10-01: plan gate chose the stronger review before it set the test bar. Blocked on RB09.
- 2026-10-01: RR09 ingested. Correction to the occurrence-map line above: the map gives the rsample indices only for designs with ascending analysis positions (vfold, grouped, rolling and sliding). For `mc_cv()` and inner bootstraps it gives the same rows, order and multiplicity at other positions (RR09 R3). AC3 and the Scope rule were restated through `rsample::complement()` (R1), and RR09, a fresh reader, checked that wording on the fixture. Status set back to planned, not in-progress, because no work had started.
- 2026-10-01: implement started on branch m139-repeated-row-inner-frame. No question gate, because RR09 settled the open choices. A new NEWS bullet sits beside the hotfix bullet, and `complement_within_outer()` is folded into the map.
- 2026-10-01: T1 done. The repeated half of the old AC4 test and the hotfix test became two tests: the grouped design against its seeded reference, and the hand-built design with the third split `c(1L, 1L, 1L, 2:30)`. On the plan-commit code they fail 18 expectations, all on the frame, the mapped `in_id` or the `out_id`.
- 2026-10-01: T2 done. `occurrence_positions()` maps every index, `match()` being its case without repeats. `complement_within_outer()` is gone, and `replace_splits()` holds the shared rset rebuild. Discovered sub-task: under repeats with an outer `in_id` past the data, the frame stays whole, but a logical `NA` `out_id` still becomes explicit rows, so the hotfix guarantee holds on that path. A new test pins it, and it failed with the branch planted to return the rset unchanged. Full suite: 1223 tests, 0 failed.

## Decisions

- 2026-10-01 (RR09 Q1, Q3): keep the occurrence map and its wrap. Designs that mention a row more often than the outer split holds it pass the entry checks, through an inner bootstrap from `nested_resamples()` or a hand-built split. The wrap gives them the right rows. Refusing them needs a new entry rule against the overlap rule's acceptance (R2 apply).
- 2026-10-01 (RR09 Q2): ship the by-copy complement, stated through `rsample::complement()` so that an apparent split with a logical `NA` `out_id` keeps every position (R1 apply). Rejected: each row once, which reweights the assessment and differs from `nested_resamples()` on the same design, and the positional complement over the analysis frame, which scores trained rows (R6 reject).
- 2026-10-01 (RR09 Q4, Q5): test with `nested_tune_grid()` and the recorded `run_tuner()` frame only. tune and finetune read an inner split through four accessors and the first split's frame, and the copy matters only through `.row`. Rejected: running every tuner, which re-tests code this change does not touch (R5 reject). The `.Random.seed` assertion is added to T3 (R4 apply).

## Review
