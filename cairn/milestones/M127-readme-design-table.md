<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M127: README table of supported resampling designs

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP3, IP4
- **Resolves:** —
- **Surface tier:** user-facing — the README is the front page and tells users which designs they can run
- **Branch/PR:** m127-readme-design-table

## Goal

The README carries a table that says whether nestedtune supports each of 15 rsample resampling functions in the outer and the inner loop.

## Scope

**In:** a README section with the table and prose under it that defines the four cell values and gives the reason for each `No` cell. New tests under `nested_tune_grid()` for the cells that run but that no test covers on the terms of AC2. Tests that pin the behavior behind each `No` cell. A test for the outer `group_bootstraps()` refusal. The prose sweep's page path drops pipe-table lines, as its roxygen path does. A NEWS bullet.

**Out:** Refusing at entry the designs that the table marks `No` goes to a candidate row that this plan adds (GP3). The table claims `nested_tune_grid()` only. Testing the cross-sectional designs under the other functions is not planned. Time-series pairs beyond what `?nested_resamples` claims stay in the existing inner-designs candidate row. `validation_split()`, `group_validation_split()`, `manual_rset()`, spatialsample and other designs from outside rsample are not planned.

## Acceptance criteria

- [x] AC1: `README.Rmd` has a section that holds a markdown table with the columns Function, Outer loop and Inner loop. The table has exactly one row for each of these 15 rsample functions: `vfold_cv()`, `mc_cv()`, `group_vfold_cv()`, `group_mc_cv()`, `clustering_cv()`, `bootstraps()`, `group_bootstraps()`, `loo_cv()`, `apparent()`, `validation_set()`, `permutations()`, `rolling_origin()`, `sliding_window()`, `sliding_index()` and `sliding_period()`. Every Outer loop cell and Inner loop cell holds one of `Yes`, `Refused`, `No` or `Untested`, with at most a footnote marker. `README.md` is knit from `README.Rmd`, so `devtools::build_readme()` leaves no diff.
- [x] AC2: For every `Yes` cell, a test under `tests/testthat/` runs that function in that role through `nested_tune_grid()`. The test asserts that `.completed` is `TRUE` on every row of the result. The partner design in the other role is `vfold_cv()` for the eleven cross-sectional rows. It is one of the four time-series functions for the four time-series rows.
- [x] AC3: For every `Refused` cell, a test asserts that `nested_resamples()` or `nested_tune_grid()` refuses that function in that role. A refusal is an error of class `nestedtune_bad_design` or the bootstrap refusal of `nested_resamples()`. An error that `nested_resamples()` passes on from evaluating `inside` is not a refusal.
- [x] AC4: A `No` cell is one of three kinds. The design runs to an estimate that is not valid for that role, or every outer fold fails, or it errors outside a nestedtune refusal. For every `No` cell, the prose under the table states the reason in plain words, and a test under `tests/testthat/` asserts the behavior that the reason names. When this criterion applies to a cell, the cell is `No`, even if a test on the terms of AC2 passes. An `Untested` cell is one that no test meets on the terms of AC2, AC3 or AC4.
- [x] AC5: The prose under the table defines each of the four values. It says that the table covers these 15 functions and that `Yes` holds for the arguments the tests use. It says that the partner of a `Yes` cell is a v-fold design for a cross-sectional row and a time-series design for a time-series row. It says that an inner time-series design is tested only with a time-series outer design. It points to the "Time-series designs" section of `?nested_resamples`, which says which other functions are tested on each time-series design.
- [x] AC6: With the table in `README.Rmd`, every command that `Rscript benchmarks/sweep-prose.R --list-gating` prints exits 0. `tests/testthat/test-sweep-prose.R` has a test on a page with a pipe table. The table's lines join to more than 30 words, and it has a separator row and an indented row. The test shows that the table is not reported by the sentence mode or by `--spans`, and that a prose sentence over 30 words after the table is still reported.
- [x] AC7: `NEWS.md` has a bullet for the table, `devtools::test()` passes, and `devtools::check()` gives 0 errors and 0 warnings.

## Coverage

- AC1 → T1, T4
- AC2 → T1, T2
- AC3 → T1, T2
- AC4 → T1, T2, T4
- AC5 → T4
- AC6 → T3, T4
- AC7 → T5

## Tasks

- [x] T1: Probe each of the 15 functions in each role through `nested_tune_grid()` on rsample 1.3.2 and tune 2.1.0, with a scratch script that is not committed. Read `.notes` for every run that fails. Set each cell by the rules in AC2 to AC4. Write the cell ledger to the Decisions section of this file: function, role, value, and the backing test. The plan-time probe on 2026-09-28 found these results. Inner `loo_cv()`, `apparent()` and `permutations()` fail on every outer fold. Outer `apparent()` runs one fold that is scored on its own training rows, so it is `No`. Outer `loo_cv()` runs, but each outer fold scores one row, so a metric such as R² is `NA`, and the cell is `No`. Outer `group_bootstraps()` is refused. The other cross-sectional cells ran. `validation_set()` was not probed.
- [x] T2: Add `tests/testthat/test-design-support.R` with a test for each cell that the T1 ledger finds without a test on the terms of AC2, AC3 or AC4. The list from the plan probe is provisional. Inner: `mc_cv()`, `bootstraps()`, `group_vfold_cv()`, `group_mc_cv()`, `group_bootstraps()`, `clustering_cv()`. Outer: `mc_cv()`, `group_vfold_cv()`, `group_mc_cv()`, `clustering_cv()`. Also the outer `group_bootstraps()` refusal and the `No` cells. Each test uses the existing deterministic fixtures through `memoised()`. Give the file a file-level `skip_heavy_on_cran()` and `skip_if_no_engines()`.
- [x] T3: Make the page path of `benchmarks/sweep-prose.R` drop a line that opens with `|`, as the roxygen path does at `benchmarks/sweep-prose.R:466`. Add it to the header's sentence on dropped lines. Add the AC6 test to `tests/testthat/test-sweep-prose.R`. Run it before the change to see it fail, and log the before and after results in the work log.
- [x] T4: Write the README section after the example and before "Learn more", with the table and the prose under it. Run `devtools::build_readme()` and every gating prose sweep.
- [x] T5: Add the NEWS bullet. Run `devtools::test()` and `devtools::check()`.

## Work log

- 2026-09-28: created by /milestone-plan.
- 2026-09-28: criteria audit (full mode, fresh [O] reader) returned 10 findings. Nine were fixed before the gate: cell-value rules, the AC2 assertion, `Untested` defined against AC2 and AC3, tests pinning each `No` reason, the AC6 fixture shape and failing control, the table's Notes column moved to swept prose, AC5 defining all four values, `Refused` limited to nestedtune's own refusals, and the time-series inner note narrowed. The tenth, the value of outer `loo_cv()`, went to the gate.
- 2026-09-28: criteria re-audit (full mode, same reader) returned 6 findings, all fixed: `Untested` excludes AC4 cells, `No` wins over `Yes`, the AC2 assertion is `.completed` on every row (the time-series tests already assert it), `Refused` excludes the `inside` evaluation wrapper, and the failing control moved from AC6 to T3.
- 2026-09-28: plan gate chose tests under `nested_tune_grid()` for the designs that run over a table read from today's tests, because the second leaves designs the package runs marked `Untested`. Falsified by a tested design that fails under another tuner in a way users meet.
- 2026-09-28: plan gate chose `No` for outer `loo_cv()` over `Untested`, because each outer fold scores one row and the averaged RMSE is the mean absolute error. Falsified by a source that validates one-row outer scoring for nested estimates.
- 2026-09-28: plan chose a sweep that skips pipe-table lines over a table built by `knitr::kable()` in a hidden chunk, because a literal table stays editable in `README.Rmd` and both leave the same text unswept. Falsified by a table cell that needs prose.
- 2026-09-28: implement started on branch `m127-readme-design-table`; no open choice, so no question gate.
- 2026-09-28: T1 done. The probe covered the 11 cross-sectional functions in both roles and read the fold notes. The Decisions ledger sets 20 `Yes`, 2 `Refused`, 8 `No` and 0 `Untested` over 30 cells, and the existing time-series grid tests back all 8 time-series cells.
- 2026-09-28: minor amendment to T2. The clause giving the file a row in the `helper-time-budget.R` ledger was dropped, because that ledger covers daemon waits only and the new file has none.
- 2026-09-28: T2 done. `tests/testthat/test-design-support.R` holds 10 `Yes` tests, the outer `group_bootstraps()` refusal, and 7 tests pinning the 8 `No` cells. The file passed with `NOT_CRAN=true`: 31 expectations in 23 s.
- 2026-09-28: T3 done. Before the change, the new sweep test failed twice: the sentence mode reported the table as `3: 46 words` beside the closing sentence, and `--spans` reported `3: 6 spans`. After the change, `test-sweep-prose.R` passed in full. `air format` left the changed files as written.
- 2026-09-28: T4 done. The README section follows the example chunk and holds the table and four paragraphs, with the `No` reasons worded from the observed fold notes. The six gating sweeps are clean, and `devtools::build_readme()` added only the new section to `README.md`.
- claim audit: 46 claims read, 2 corrected — NEWS.md, tests/testthat/test-design-support.R
- 2026-09-28: T5 done. The NEWS bullet is added. `devtools::test()` passed with no failures and no skips, and `devtools::check()` gave 0 errors, 0 warnings and 0 notes in 9 min. Status set to review.

## Decisions

- 2026-09-28 (T1): cell ledger from the probe on rsample 1.3.2 and tune 2.1.0, partner `vfold_cv(v = 3)` for the cross-sectional rows. No cell is `Untested`. New tests go to `test-design-support.R` (T2).
  - `vfold_cv()`: outer `Yes`, inner `Yes`. Backed by `test-nested-tune-grid-oracles.R` "an integer grid records the candidates that fold actually expanded".
  - `mc_cv()`, `group_vfold_cv()`, `group_mc_cv()`, `clustering_cv()`: outer `Yes`, inner `Yes`. New tests.
  - `bootstraps()`: outer `Refused`, backed by `test-nested-resamples-specs.R` "an outer bootstrap is refused, as a call and as an object". Inner `Yes`, new test.
  - `group_bootstraps()`: outer `Refused` by the same bootstrap refusal, new test. Inner `Yes`, new test.
  - `loo_cv()`: outer `No`, because each outer fold holds out one row, so R² is `NA` and the averaged RMSE is the mean absolute error. Inner `No`, because every outer fold fails with tune's note that leave-one-out is not supported. New tests.
  - `apparent()`: outer `No`, because its one outer fold scores the rows it trained on. Inner `No`, because every outer fold fails with tune's note that no results are available. New tests.
  - `validation_set()`: outer `No` and inner `No`, because it takes a split from `initial_validation_split()` rather than data, so `nested_resamples()` cannot evaluate it. The error is the `could not be evaluated` wrapper, which AC3 does not count as a refusal. A validation set built beforehand is refused as built on different data, which is not an AC3 refusal either. New tests.
  - `permutations()`: outer `No`, because every outer fold fails, since a permutation split has no assessment set. Inner `No`, because every outer fold fails with tune's note that permutation samples are not suitable for tuning. New tests.
  - `rolling_origin()`: outer `Yes` and inner `Yes` with a time-series outer design. Backed by `test-time-series-designs.R` "a rolling-origin design matches a hand-rolled reference loop".
  - `sliding_window()`, `sliding_index()`, `sliding_period()`: outer `Yes`, backed by `test-time-series-designs.R` ("a sliding-window design matches a hand-rolled reference loop" and the two `sprintf` tests). Inner `Yes` with an outer `rolling_origin()`, backed by the three `test-time-series-inner.R` tests "nested_tune_grid() on an inner %s design matches a hand-rolled reference loop". Each asserts `.completed` through `expect_ts_matches_reference()`.

## Review

The branch held `origin/main` at review start on 2026-09-28, so no merge was needed.

- AC1: `README.Rmd` has the section "Supported resampling designs". Its table has the columns Function, Outer loop and Inner loop, and one row for each of the 15 listed functions. Every cell is `Yes`, `Refused` or `No`, with no footnote markers. A fresh `devtools::build_readme()` left `git status` clean.
- AC2: The table has 20 `Yes` cells. Ten are the loops in `test-design-support.R`, each with a `vfold_cv(v = 3)` partner and `all(run$res$.completed)`. Outer and inner `vfold_cv()` rest on `test-nested-tune-grid-oracles.R:245`. The eight time-series cells rest on `test-time-series-designs.R:79` and `:104` and on `expect_ts_matches_reference()`, which asserts `.completed` first. The inner sliding cells use an outer `rolling_origin()` and the rolling-origin cells use `rolling_origin()` in both loops. The full suite with `NOT_CRAN=true` gave 13227 passes, 0 failures and 0 skips.
- AC3: The two `Refused` cells are outer `bootstraps()` and outer `group_bootstraps()`. `test-nested-resamples-specs.R:175` and `test-design-support.R:81` assert the error "cannot be a bootstrap" for the call and the built object. That error is the `cli_abort()` at `R/nested-resamples.R:150`, which runs after `outside` is evaluated, so it is not the `could not be evaluated` wrapper. Both tests passed in the full suite.
- AC4: The eight `No` cells are `loo_cv()`, `apparent()`, `validation_set()` and `permutations()` in both loops, and the README gives a reason for each. `test-design-support.R:107` to `:211` pins each reason. Outer `loo_cv()` holds one row per fold, R² is `NA` and RMSE equals the mean absolute error. The inner `loo_cv()`, `apparent()` and `permutations()` runs and the outer `permutations()` run fail every fold with the named note. Outer `apparent()` has an assessment set equal to its analysis set. `validation_set()` as a call fails with the `could not be evaluated` wrapper and the parent "must be empty". No cell is `Untested`. All passed in the full suite. The criterion holds for the call form the table tests. Finding O1 below shows that the README reason for outer `validation_set()` is false for a set built beforehand.
- AC5: The four paragraphs under the table define `Yes`, `Refused`, `No` and `Untested`. They say that the table covers 15 rsample functions and that `Yes` holds for the arguments the tests use. They name a v-fold partner for the first eleven functions and a time-series partner for the four time-series functions. They say that an inner time-series design is tested only with a time-series outer design. They point to the "Time-series designs" section of `?nested_resamples`. That section exists at `man/nested_resamples.Rd:53` and names the functions tested on each time-series design.
- AC6: Each of the six commands that `--list-gating` prints exited 0 with `clean`. The new test at `test-sweep-prose.R:178` writes a page with a table. The table has a separator row and an indented row, and its lines join to 46 words. The test expects only the 33-word sentence at line 12 from the sentence mode and `clean` from `--spans`. It passed in the full suite. As a control, the script on `main` reported the table as `3: 46 words` and `3: 6 spans` on the same page. The branch script reported only line 12.
- AC7: `NEWS.md` has the bullet for the table. `devtools::test()` passed as recorded under AC2. `devtools::check()` gave 0 errors, 0 warnings and 0 notes in 10 min 11 s.
- Consistency gate: `cairn_validate.py` exited 0 with 18 advisory warnings on reference staleness, none of them a gate failure. No principle changed, so `cairn_impact.py` was skipped. `devtools::document()` left no diff, `pkgdown::check_pkgdown()` found no problems, and `README.md` matches `README.Rmd`. The branch adds no top-level file. The gating sweeps are clean as recorded under AC6.

### Findings

Three fresh reviewers ran: [O] diff-bug, [S] blame-history and [S] prior-review. The prior-review lens found prior-review evidence on the touched files and no regression of it. Findings are ranked by each reviewer, and dispositions are set at the merge gate.

- O1: The outer `validation_set()` cell reads `No`, and the README says that `nested_resamples()` "cannot build it in either loop". A set built beforehand with `data` holding its training and validation rows is accepted as the outer loop. The review session reproduced this. The one outer fold completed with no row in both sets, which is a valid single-holdout estimate.
- O2: No test ties the README cells to the tests. The NEWS and README claim that a working design is a tested one is kept by hand.
- O3: The inner `Yes` tests at `test-design-support.R:72` do not check the row count, so an empty result passes `all(.completed)`.
- O4: `expect_every_fold_fails()` at `test-design-support.R:100` asserts nothing on an empty result.
- O5: The bootstrap refusal tests match the message text, because the refusal has no condition class.
- O6: The page sweep now drops a pandoc line block, which also opens with `|`. No swept page uses one.
- O7: README "it is another time-series design" is wrong for `rolling_origin()`, whose partner is also `rolling_origin()`.
- O8: The README definition of `Untested` ("no test runs the design") is looser than the AC4 definition.
- O9: T2 asked for a file-level `skip_if_no_engines()`, and the file calls it in each test that needs engines.
- S1: The README defines `Untested` although no cell uses it. The prior-review lens noted the same thing.
- S2: The README sentence on the v-fold partner of the first eleven functions also seems to cover their `Refused` and `No` cells.
- S3: The fixture test in `test-sweep-prose.R` plants one leak per dropped line class, and it has no pipe-table plant or `--paragraphs` check.
- S4: `suppressWarnings()` around the outer `loo_cv()` run can hide an unrelated warning.
