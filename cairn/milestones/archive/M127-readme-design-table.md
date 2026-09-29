# M127: README table of supported resampling designs

**Status:** done (2026-09-29, PR #142 https://github.com/tidymodels/nestedtune/pull/142)

**Goal:** The README carries a table that says whether nestedtune supports each of 15 rsample resampling functions in the outer and the inner loop.

**Outcome:** `README.Rmd` has a "Supported resampling designs" section after the example. Its table has 21 `Yes`, 2 `Refused` and 7 `No` cells, and no cell is `Untested`. Four paragraphs define the values and give the reason for each `No` cell. A footnote says how to build an outer `validation_set()`: build it from `initial_validation_split()` first, then pass its training and validation rows as `data`. `tests/testthat/test-design-support.R` runs through `nested_tune_grid()` each `Yes` design that no earlier test covered. Each test asserts `.completed` on every row. It also pins the outer `group_bootstraps()` refusal and the behavior behind each `No` cell. The page path of `benchmarks/sweep-prose.R` drops a line that opens with `|`, as its roxygen path does. `test-sweep-prose.R` and `fixtures/sweep-prose-parse.Rmd` each carry a pipe-table case. NEWS has a bullet for the table.

**Decisions:** D-095. The T1 cell ledger lives in git. At review, outer `validation_set()` moved from `No` to `Yes` with a footnote.

**Review:** Three reviewers ran. The diff-bug reader found that a validation set built beforehand runs as the outer loop, so the README's `No` and its reason were false. The review session reproduced it. At the gate, the maintainer chose `Yes` with a footnote and a new test. Also fixed: row-count checks in the inner `Yes` tests and the all-folds-fail helper, three README wording slips, and a pipe-table plant in the sweep fixture. A check that ties the README cells to the tests went to a candidate row. Five findings were rejected with reasons. After the fixes, 13256 expectations passed with 0 failures and 0 skips, and `devtools::check()` gave 0 errors, 0 warnings and 0 notes. CI passed 14 checks. Nothing was graduated or retired.
