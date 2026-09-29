# M129: Recognize a refused design by its split classes

- **Status:** planned
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP3
- **Resolves:** —
- **Surface tier:** user-facing — it changes which designs the exported functions refuse
- **Branch/PR:** —

## Goal

If any split of a nested design carries the class of a refused rsample design, the call refuses the design.

## Scope

**In:** A design inferred from split classes, beside the rset class, in `check_nested()`, `check_inner_refused()`, `nested_resamples()` and `inner_resamples_from_split()`. This covers row subsets, `manual_rset()` rebuilds and designs with mixed splits. Both bootstrap refusals name the rsample function. The README's Refused paragraph and a NEWS bullet say what is refused.

**Out:**
- A split rebuilt with `rsample::make_splits()` carries no trace of its design, so nothing can recognize it. No row, because no check can read it.
- A row subset passed as `outside` to `nested_resamples()` keeps today's refusal as not an rset. No row, because it is already refused.
- A row subset of a supported inner design stays refused by the column class check, as today. No row, because nothing asks for it.
- The other six entry functions are tested through `nested_tune_grid()` alone. They share `check_nested()`, and M128 tested each one.
- The test that reads the README table against its tests stays a `[low]` candidate row.

## Acceptance criteria

- [ ] AC1: Take a design from `rsample::nested_cv()` with an outer `loo_cv()`, `permutations()`, `bootstraps()` or `group_bootstraps()` design. Cut it to its first two rows by `[`, `dplyr::slice()` and `vctrs::vec_slice()`. `nested_tune_grid()` refuses each of the 12 results with class `nestedtune_bad_design` before any fold runs. The message names the rsample function that built the outer design.
- [ ] AC2: If one split among valid ones carries the split class of a refused design, the design is refused. A test runs `nested_tune_grid()` on three such designs. The first has an outer `manual_rset()` of three `vfold_cv()` splits and one `loo_cv()` split. The second has three outer `vfold_cv()` splits and one `apparent_split`. For these two, the message names the function and the outer row. The third has, in fold 2 alone, an inner `manual_rset()` of `vfold_cv()` splits and one `loo_cv()` split. Its message names the function and element 2 of `inner_resamples`. A fourth case is the last row of an outer `bootstraps(apparent = TRUE)` design, whose one split is an `apparent_split`. Its message names `apparent()`. Each of the four is refused with class `nestedtune_bad_design` before any fold runs.
- [ ] AC3: Take a design from `rsample::nested_cv()` with an inner `loo_cv()` or `permutations()` design. Cut its inner designs to their first two rows by `[`, `dplyr::slice()` and `vctrs::vec_slice()`. `nested_tune_grid()` refuses each of the 6 results with class `nestedtune_bad_design` before any fold runs. The message names the rsample function and the outer folds that use it. It does not call the column malformed. A seventh case cuts the inner design of fold 2 alone, and its message names element 2 alone.
- [ ] AC4: `rsample::manual_rset()` rebuilds the splits of `loo_cv()`, `permutations()`, `apparent()`, `bootstraps()` and `group_bootstraps()` designs. Each rebuild is refused as the `outside` argument of `nested_resamples()` and as the outer design at `nested_tune_grid()`. Rebuilds of `loo_cv()`, `permutations()` and `apparent()` splits are refused as every inner design at `nested_tune_grid()`. Each of the 13 refusals has class `nestedtune_bad_design` and names the rsample function. The `nested_tune_grid()` refusals come before any fold runs.
- [ ] AC5: A test shows that each of these designs reaches the fold dispatch, so `nested_tune_grid()` raises the stand-in's `nestedtune_sentinel` error. The first is the first two rows of a `rsample::nested_cv()` design with outer and inner `vfold_cv()`. The second has an outer `manual_rset()` of `vfold_cv()` splits. The others have an inner `bootstraps(apparent = TRUE)` or `group_bootstraps(apparent = TRUE)`, plain and rebuilt with `manual_rset()`. The same test shows that `nested_resamples()` builds with `inside = rsample::bootstraps(times = 3, apparent = TRUE)`. It also builds with an outer `manual_rset()` of `vfold_cv()` splits. An inner element that is not a data frame still gets the malformed-column refusal.
- [ ] AC6: The README's Refused paragraph, knitted into `README.md`, and one new `NEWS.md` bullet say three things. A row subset of a refused design is refused. So is a `manual_rset()` rebuilt from its splits, and a design with one such split among others.
- [ ] AC7: `devtools::test()` gives 0 failures, `devtools::check()` gives 0 errors and 0 warnings, and `Rscript benchmarks/sweep-prose.R --plain` is clean.

## Coverage

- AC1 → T1
- AC2 → T1, T2
- AC3 → T2
- AC4 → T1, T2, T3
- AC5 → T1, T2, T3
- AC6 → T4
- AC7 → T4

## Tasks

- [ ] T1: Outer loop in the entry check. First write the AC1 tests and the outer cases of AC2, AC4 and AC5 in `tests/testthat/test-design-support.R`. Use the `entry_refusal()` stand-in (line 163). Then extend `refused_design()` (`R/checks.R:431`). If the rset class names no refused design, it infers one from the split classes. Map `group_boot_split`, `boot_split`, `perm_split` and `loo_split` to their functions. If the design carries no `boot_split` or `perm_split`, map `apparent_split` to `apparent()`. Fold the outer bootstrap check (`R/checks.R:353`) into this path. Its message names the function and the split positions.
- [ ] T2: Inner loop in the entry check. First write the AC3 tests and the inner cases of AC2, AC4 and AC5. Then make `check_inner_refused()` (`R/checks.R:469`) read split classes from each element that is a data frame with a `splits` list column. Leave every other element to `check_column_class()`.
- [ ] T3: The constructor. First write the `nested_resamples()` cases of AC4 and AC5. Then give `nested_resamples()` (`R/nested-resamples.R:157`, `:172`) and `inner_resamples_from_split()` (`:237`) the same inference. Make the bootstrap message name the function. Update the existing bootstrap tests (`test-design-support.R:86`) where the message text changes.
- [ ] T4: Documentation and checks. Add the AC6 sentences to the Refused paragraph (`README.Rmd:112`) and run `devtools::build_readme()`. Add the NEWS bullet. Read the help text at `R/nested-resamples.R:40` and `R/nested-tune-grid.R:121`. Change it only where it says how a design is recognized. Run `devtools::document()`, the prose sweep, `devtools::test()` and `devtools::check()`.

## Work log

- 2026-09-29: created by /milestone-plan. It absorbs the row-subset candidate row from M128's review (findings O1, O6).
- 2026-09-29: criteria audit ran in full mode (fresh [O] reader) and found 13 items. Bootstrap messages named no function, and outer `group_bootstraps()` was missing. The lone `apparent_split` branch was untested, and AC3 did not separate old from new behavior. The controls missed the `apparent_split` exception and the constructor. A mixed-split gap was open, and AC6 over-promised on `make_splits()` rebuilds. All were fixed before the gate.
- 2026-09-29: plan gate chose inferring the design from split classes over restoring the rset class with subset methods. rsample owns that class, and a user can build the table any way. Falsified by an rsample release that keeps the rset class through a row subset.
- 2026-09-29: plan gate chose inferring the design from split classes over refusing any outer design with no rset class. A row subset of a supported design runs today. Falsified by a supported design refused by the new check.
- 2026-09-29: plan gate chose all three shapes (row subsets, `manual_rset()` rebuilds, mixed splits) over row subsets alone, at priority high.
- 2026-09-29: the revised criteria wording went back to the same reader for a recheck. Its result was still pending at the plan commit.
- 2026-09-29: the recheck found two items, both in AC2. "Comes from a refused design" also covered `make_splits()` rebuilds, and "the split's position" was unclear for the inner and one-split cases. AC2 was reworded to fix both. AC1 and AC3-AC7 gave no finding.

## Decisions

## Review
