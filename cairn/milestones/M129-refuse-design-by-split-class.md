# M129: Recognize a refused design by its split classes

- **Status:** review
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP3
- **Resolves:** —
- **Surface tier:** user-facing — it changes which designs the exported functions refuse
- **Branch/PR:** m129-refuse-design-by-split-class

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

- [x] AC1: Take a design from `rsample::nested_cv()` with an outer `loo_cv()`, `permutations()`, `bootstraps()` or `group_bootstraps()` design. Cut it to its first two rows by `[`, `dplyr::slice()` and `vctrs::vec_slice()`. `nested_tune_grid()` refuses each of the 12 results with class `nestedtune_bad_design` before any fold runs. The message names the rsample function that built the outer design.
- [x] AC2: If one split among valid ones carries the split class of a refused design, the design is refused. A test runs `nested_tune_grid()` on three such designs. The first has an outer `manual_rset()` of three `vfold_cv()` splits and one `loo_cv()` split. The second has three outer `vfold_cv()` splits and one `apparent_split`. For these two, the message names the function and the outer row. The third has, in fold 2 alone, an inner `manual_rset()` of `vfold_cv()` splits and one `loo_cv()` split. Its message names the function and element 2 of `inner_resamples`. A fourth case is the last row of an outer `bootstraps(apparent = TRUE)` design, whose one split is an `apparent_split`. Its message names `apparent()`. Each of the four is refused with class `nestedtune_bad_design` before any fold runs.
- [x] AC3: Take a design from `rsample::nested_cv()` with an inner `loo_cv()` or `permutations()` design. Cut its inner designs to their first two rows by `[`, `dplyr::slice()` and `vctrs::vec_slice()`. `nested_tune_grid()` refuses each of the 6 results with class `nestedtune_bad_design` before any fold runs. The message names the rsample function and the outer folds that use it. It does not call the column malformed. A seventh case cuts the inner design of fold 2 alone, and its message names element 2 alone.
- [x] AC4: `rsample::manual_rset()` rebuilds the splits of `loo_cv()`, `permutations()`, `apparent()`, `bootstraps()` and `group_bootstraps()` designs. Each rebuild is refused as the `outside` argument of `nested_resamples()` and as the outer design at `nested_tune_grid()`. Rebuilds of `loo_cv()`, `permutations()` and `apparent()` splits are refused as every inner design at `nested_tune_grid()`. Each of the 13 refusals has class `nestedtune_bad_design` and names the rsample function. The `nested_tune_grid()` refusals come before any fold runs.
- [x] AC5: A test shows that each of these designs reaches the fold dispatch, so `nested_tune_grid()` raises the stand-in's `nestedtune_sentinel` error. The first is the first two rows of a `rsample::nested_cv()` design with outer and inner `vfold_cv()`. The second has an outer `manual_rset()` of `vfold_cv()` splits. The others have an inner `bootstraps(apparent = TRUE)` or `group_bootstraps(apparent = TRUE)`, plain and rebuilt with `manual_rset()`. The same test shows that `nested_resamples()` builds with `inside = rsample::bootstraps(times = 3, apparent = TRUE)`. It also builds with an outer `manual_rset()` of `vfold_cv()` splits. An inner element that is not a data frame still gets the malformed-column refusal.
- [x] AC6: The README's Refused paragraph, knitted into `README.md`, and one new `NEWS.md` bullet say three things. A row subset of a refused design is refused. So is a `manual_rset()` rebuilt from its splits, and a design with one such split among others.
- [x] AC7: `devtools::test()` gives 0 failures, `devtools::check()` gives 0 errors and 0 warnings, and `Rscript benchmarks/sweep-prose.R --plain` is clean.

## Coverage

- AC1 → T1
- AC2 → T1, T2
- AC3 → T2
- AC4 → T1, T2, T3
- AC5 → T1, T2, T3
- AC6 → T4
- AC7 → T4

## Tasks

- [x] T1: Outer loop in the entry check. First write the AC1 tests and the outer cases of AC2, AC4 and AC5 in `tests/testthat/test-design-support.R`. Use the `entry_refusal()` stand-in (line 163). Then extend `refused_design()` (`R/checks.R:431`). If the rset class names no refused design, it infers one from the split classes. Map `group_boot_split`, `boot_split`, `perm_split` and `loo_split` to their functions. If the design carries no `boot_split` or `perm_split`, map `apparent_split` to `apparent()`. Fold the outer bootstrap check (`R/checks.R:353`) into this path. Its message names the function and the split positions.
- [x] T2: Inner loop in the entry check. First write the AC3 tests and the inner cases of AC2, AC4 and AC5. Then make `check_inner_refused()` (`R/checks.R:469`) read split classes from each element that is a data frame with a `splits` list column. Leave every other element to `check_column_class()`.
- [x] T3: The constructor. First write the `nested_resamples()` cases of AC4 and AC5. Then give `nested_resamples()` (`R/nested-resamples.R:157`, `:172`) and `inner_resamples_from_split()` (`:237`) the same inference. Make the bootstrap message name the function. Update the existing bootstrap tests (`test-design-support.R:86`) where the message text changes.
- [x] T4: Documentation and checks. Add the AC6 sentences to the Refused paragraph (`README.Rmd:112`) and run `devtools::build_readme()`. Add the NEWS bullet. Read the help text at `R/nested-resamples.R:40` and `R/nested-tune-grid.R:121`. Change it only where it says how a design is recognized. Run `devtools::document()`, the prose sweep, `devtools::test()` and `devtools::check()`.

## Work log

- 2026-09-29: created by /milestone-plan. It absorbs the row-subset candidate row from M128's review (findings O1, O6).
- 2026-09-29: criteria audit ran in full mode (fresh [O] reader) and found 13 items. Bootstrap messages named no function, and outer `group_bootstraps()` was missing. The lone `apparent_split` branch was untested, and AC3 did not separate old from new behavior. The controls missed the `apparent_split` exception and the constructor. A mixed-split gap was open, and AC6 over-promised on `make_splits()` rebuilds. All were fixed before the gate.
- 2026-09-29: plan gate chose inferring the design from split classes over restoring the rset class with subset methods. rsample owns that class, and a user can build the table any way. Falsified by an rsample release that keeps the rset class through a row subset.
- 2026-09-29: plan gate chose inferring the design from split classes over refusing any outer design with no rset class. A row subset of a supported design runs today. Falsified by a supported design refused by the new check.
- 2026-09-29: plan gate chose all three shapes (row subsets, `manual_rset()` rebuilds, mixed splits) over row subsets alone, at priority high.
- 2026-09-29: the revised criteria wording went back to the same reader for a recheck. Its result was still pending at the plan commit.
- 2026-09-29: the recheck found two items, both in AC2. "Comes from a refused design" also covered `make_splits()` rebuilds, and "the split's position" was unclear for the inner and one-split cases. AC2 was reworded to fix both. AC1 and AC3-AC7 gave no finding.
- 2026-09-29: implement started on branch m129-refuse-design-by-split-class. No question gate, because the plan left nothing open.
- 2026-09-29: checkpoint, T1 half-done. `check_outer_splits()` and the outer tests are written, and `test-design-support.R` passes in full mode. The full `devtools::test()` run is still going, so T1 stays unticked.
- 2026-09-29: T1 done. `devtools::test()` gave 0 failures, and `air format` reflowed the two touched files.
- 2026-09-29: checkpoint, T2 half-done. `inner_refused_design()` and the inner tests are written, and `test-design-support.R` passes in full mode. The inner message now says an element holds a design's splits. The full suite is still running.
- 2026-09-29: T2 done. `devtools::test()` gave 0 failures.
- 2026-09-29: checkpoint, T3 half-done. `nested_resamples()` reads the split classes of `outside` and of each inner rset, and the constructor tests pass in full mode. The bootstrap headlines are unchanged, so the existing bootstrap tests needed no edit. The full suite is still running.
- 2026-09-29: T3 done. `devtools::test()` gave 0 failures.
- 2026-09-29: checkpoint, T4 half-done. The README paragraph, the NEWS bullet and the help for `nested_resamples()` and `nested_tune_grid()` are updated. A test for one refused split in `outside` was added, because the new help text claims it. All six gating prose sweeps are clean. The full suite and `devtools::check()` are still running.
- 2026-09-29: claim audit: 52 claims read, 5 corrected — NEWS.md, README.Rmd, README.md, R/checks.R, R/nested-resamples.R, R/nested-tune-grid.R, tests/testthat/test-design-support.R
- 2026-09-29: the claim audit's fixes. `split_designs()` now counts an apparent split beside bootstrap or permutation splits as part of that design, so the message names its row, and a test checks this. The NEWS bullet separates `nested_resamples()` from the seven functions. The README and `?nested_tune_grid` explain the apparent split. Two comments were corrected. The first full-suite run was stopped because these fixes changed the code under test.
- 2026-09-29: the claim audit reader re-read the 5 corrected claims once, and all 5 hold.
- 2026-09-29: T4 done. `devtools::test()` gave 0 failures. `devtools::check()` gave 0 errors, 0 warnings and 0 notes. The six gating prose sweeps and `air format --check` are clean. Status set to review.
- 2026-09-29: review checkpoint. AC1 to AC6 have evidence and ticks. The three reviewers reported. The full suite and `devtools::check()` for AC7 are still running.
- 2026-09-29: review pre-gate checkpoint. All seven criteria have evidence and ticks, and the consistency gate passed. No finding shows a criterion failing. 17 findings go to the gate with proposed dispositions.
- 2026-09-29: triage gate. The maintainer chose to fix 8 findings, file 1 follow-up row and reject the rest. The fixes are committed. The full suite and `devtools::check()` rerun, and then the merge is put to the maintainer again.
- 2026-09-29: step-7 approval: m129-refuse-design-by-split-class approved for merge

## Decisions

## Review

Evidence run 2026-09-29 on the branch head `689b24ac`, which already contains `origin/main`. `test-design-support.R` ran with `NOT_CRAN=true`: 39 blocks, 0 failures, 0 skipped. For discrimination, the branch's test file also ran against an `origin/main` tree from `git archive`. Every new refusal block failed there (blocks 23 to 28, 30 to 34, 37 and 38). The four control blocks (29, 35, 36, 39) passed there.

- AC1: the four "a row subset of an outer ... design is refused" blocks pass, with 15 expectations each. Each block cuts by `[`, `dplyr::slice()` and `vctrs::vec_slice()`, so there are 12 results. Each result has no rset class, and its error has class `nestedtune_bad_design`. The message names `rsample::<fn>()` and "Rows 1 and 2", and the call is `nested_tune_grid`. The test mocks `dispatch_folds()` to a sentinel, so the refusal comes before any fold. On main, 12 of 15 fail in each block.
- AC2: "one outer split from a refused design refuses the whole design" passes (10 expectations). It covers one `loo_cv()` split and one `apparent_split` beside three `vfold_cv()` splits, both at "Row 4 of". It also covers the last row of `bootstraps(apparent = TRUE)`, named `apparent()`. "one inner split from a refused design refuses its fold" passes (4) and names `loo_cv()` and "Element 2 of". On main, 8 of 10 and 3 of 4 fail.
- AC3: the two "a row subset of an inner ... design is refused" blocks pass (15 each, 6 results). Each result names the function and "Elements 1, 2, and 3", without "malformed". "a row subset of one fold's inner design names that fold alone" passes (4). It finds "Element 2 of" and no "Elements". On main, 6, 6 and 2 fail.
- AC4: three blocks pass. "an outer manual_rset() rebuilt from refused splits is refused at entry" covers 5 designs (19). "nested_resamples() refuses an outside rebuilt from refused splits" covers 5 designs (19). "an inner manual_rset() rebuilt from refused splits is refused at entry" covers `loo_cv()`, `permutations()` and `apparent()` (12). Each of the 13 refusals has the class and the function name. On main, 13 of 19, both constructor blocks, and 9 of 12 fail.
- AC5: four control blocks pass on the branch and on main. The first is "the entry check still admits a subset or rebuild of a v-fold design" (2). The second is "an inner bootstrap with its apparent split still reaches the folds" (6). The third is "nested_resamples() still builds a bootstrap inside and a rebuilt v-fold outside" (3). The fourth is "an inner element that is not a data frame is still malformed" (2).
- AC6: `README.Rmd` lines 116 to 121 and the knitted `README.md` lines 117 to 120 carry the three statements. A row subset is refused, a `manual_rset()` rebuild is refused, and one such split among valid ones is refused. `devtools::build_readme()` gave no diff. The one new `NEWS.md` bullet says the same three things.
- AC7: `devtools::test()` gave 0 failures, 0 warnings, 0 skips and 13474 passes. `devtools::check()` gave 0 errors, 0 warnings and 0 notes in 12m 44s. `Rscript benchmarks/sweep-prose.R --plain` exits 0.

Consistency gate, 2026-09-29: `cairn_validate.py` exits 0, with 18 references-staleness advisories and no FAIL. No `DESIGN.md` principle changed, so `cairn_impact` was skipped. `devtools::document()` left no diff. `build_readme()` left no diff. `pkgdown::check_pkgdown()` found no problems. All six gating prose sweeps exit 0, and `air format --check .` exits 0. NEWS has the bullet, and no new top-level file was added.

Independent review, three fresh reviewers: [O] diff, [S] blame history, [S] prior review record. Findings, most severe first, each with its proposed disposition:

- O1: the inner reasons say tune refuses `loo_cv()` and `permutations()`, and that tune reports no results for `apparent()`. That holds only for the rset class. The session reran it: tune runs a `manual_rset()` of `loo_cv()` splits and averages RMSE over 20 one-row folds. So a rebuilt or mixed inner design is refused with a false reason. Proposed: fix now.
- O2: `nested_resamples()` calls a mixed inner design "an `rsample::X` design" and names no fold. Proposed: fix now, with O1.
- P1: the plain outer `bootstraps()` and `group_bootstraps()` refusals now name the function, which the Scope promises, but no test asserts it. Proposed: fix now.
- O7: the NEWS bullet does not say that inner rebuilds used to run unrefused, or that `nested_resamples()` refuses an `inside` that returns refused splits. The roxygen at `R/nested-resamples.R:44` does not say it either. Proposed: fix now.
- O6: the entry check's bootstrap hint says "`nested_tune_grid()` refuses" for every caller of `check_nested()`. This is older than M129, next to an edited line. Proposed: fix now.
- P2 and S4: the Conventions bullet in `cairn/DESIGN.md` does not say that the refusals also read split classes. Proposed: fix now.
- O9: in `check_outer_splits()`, the line that sets non-refused designs to `NA` never changes anything. Proposed: fix now.
- O3: an apparent split beside bootstrap splits in an inner `manual_rset()` counts as part of the bootstrap. If its id is not "Apparent", tune scores it. This follows the D-097 rule. Proposed: follow-up, with O4.
- O4: in a mixed outer design, an apparent split from a separate `apparent()` call is named as a bootstrap row. This follows the D-097 rule. Proposed: follow-up, with O3.
- P3: the new README sentences sit between the paragraph's list of per-design reasons. Proposed: fix now, by moving them after the reasons.
- O5: for an element with one refused split, the inner message still says "splits". It does not give the inner split's position. Proposed: reject, because AC2 and AC3 fix the element as the unit the message names.
- O10: the rebuild tests do not check `conditionCall()`. No test covers an inner data frame without `splits`, or a zero-row inner subset. The reviewer ran both, and each gets the malformed refusal. Proposed: reject, because the sentinel check already shows the refusal comes before any fold.
- S1: a whole outer bootstrap design and a row subset of it give different headlines. Proposed: reject, because the class is the same and both name the function.
- S2: the last row of a `bootstraps(apparent = TRUE)` design is named `apparent()`, but the whole design is named `bootstraps()`. Proposed: reject, because AC2 asks for this.
- S3: the inner message changed from "is `rsample::X`" to "holds `rsample::X` splits". Proposed: reject, because the work log records this as intended.
- S5: the NEWS claim that a row-subset `outside` is refused as before rests on rsample dropping the rset class. Proposed: noted, with nothing to do.
- O8: after `boots[4, ]`, the message says "Row 1", which counts rows of the object passed in. Proposed: reject, because that is correct.

Triage at the gate, 2026-09-29: the maintainer accepted every proposed disposition. The results follow.

- O1 fixed. `inner_refused_reason()` gives the outer loop's reason for a design found by its split classes. It keeps the tune reason for an rset class. The session reran tune on a `manual_rset()` of `loo_cv()` splits, and it ran.
- O2 fixed. `nested_resamples()` now says "`inside` gave `rsample::X()` splits for outer fold N" for a design found by its split classes.
- P1 fixed. The new test "the plain outer bootstrap refusals name the function" covers both bootstraps at the constructor and at entry.
- O6 fixed. The entry hint now says "nestedtune refuses", and the same test asserts it.
- O7 fixed. The NEWS bullet and `?nested_resamples` now cover the inner loop and the `inside` refusal.
- P2 and S4 fixed. The `cairn/DESIGN.md` Conventions bullet cites D-097.
- O9 fixed. The line and `outer_refused_designs` were removed.
- P3 fixed. The README sentences now come after the per-design reasons, still in the Refused paragraph.
- O3 and O4 became one candidate row in `cairn/ROADMAP.md`. No existing row overlapped.
- O5, O8, O10, S1, S2 and S3 were rejected, and S5 was noted, for the reasons above.

The three new test blocks fail on the pre-fix code (4, 5 and 4 failures), and they pass on the branch.

Rerun after the fixes, 2026-09-29, on `89335d9f`: `devtools::test()` gave 0 failures, 0 warnings, 0 skips and 13508 passes. `devtools::check()` gave 0 errors, 0 warnings and 0 notes. The six prose sweeps, `air format --check`, `pkgdown::check_pkgdown()` and the `document()` no-diff check are clean. `cairn_validate.py` passes, after the M126 done row was pruned to keep `ROADMAP.md` under 60 lines.
