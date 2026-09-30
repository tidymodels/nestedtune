# M130: Raise the testthat minimum to 3.3.0

**Status:** done (2026-09-29, PR #145 https://github.com/tidymodels/nestedtune/pull/145)

**Goal:** `DESCRIPTION` declares `testthat (>= 3.3.0)`, and the package's tests pass at that version both with `NOT_CRAN` unset and with it set to true.

**Outcome:** The testthat entry in `DESCRIPTION` Suggests moved from `>= 3.0.0` to `>= 3.3.0`. The first plan aimed at 3.2.3. Releases 3.2.3 and older fail to compile under R 4.6.1 (`SET_FORMALS` in `reassign.c`), so the milestone was re-planned at 3.3.0. A probe with a control showed that `R_LIBS` puts 3.3.0 in the check's runner and its test workers. With 3.3.0 first on `R_LIBS`, `R CMD check --as-cran` passed its tests under CRAN's conditions and with `NOT_CRAN=true`. The new floor made a `skip_if_not_installed("testthat", "3.2.0")` in `test-nested-tune-grid-failures.R` dead. Review removed it and its stale comment. `NEWS.md` has no entry, as Scope decided. The CI job at the floor stays a `[low]` candidate row.

**Decisions:** D-098, recorded at implement.

**Review:** The review ran AC1 to AC4 again at `3c7eae33`. The CRAN-conditions run reported FAIL 0 with 6554 passing, and the full run reported FAIL 0 with 13390 passing. `devtools::check()` gave 0 errors, 0 warnings and 0 notes. Three reviewers reported 12 items. The maintainer chose to fix one (O1, the dead skip). The others were rejected or noted. Review builds refuted O2 and O4: testthat 3.2.1 and 3.1.10 also fail to compile, and #2038 is the `skip()` issue that PR #2039 fixed. The PR had no review comments, and CI passed 14 checks. Nothing was graduated or retired, and no lesson was added, because D-098 records the compile fact.
