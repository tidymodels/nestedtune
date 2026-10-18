# M146: DESCRIPTION's Title and Description say what the package does, in CRAN's form

**Status:** done (2026-10-17, PR #163 https://github.com/tidymodels/nestedtune/pull/163)

**Goal:** `DESCRIPTION`'s `Title` and `Description` fields say what the package does today, with package names quoted as CRAN asks.

**Outcome:** The Title is `Nested Cross-Validation for 'tidymodels'`. The Description names nested cross-validation as an estimate of a tuning procedure (IP3), the tuners, fixed models and workflow sets, the separate final fit, parallel outer folds through 'mirai', and the constructor's row-index storage. It cites Varma and Simon (2006) by the DOI `cairn/references/varma2006.md` records.
- The old sentence saying the constructor's size does not grow with the outer folds was false since M01. `test-nested-resamples-memory.R` records a slope of 0.18 data copies per fold, against rsample's 1.15. The claim audit caught it, and at the user's stop the sentence now says the object stores row indices in place of a copy per fold.
- `tests/testthat/test-description.R` fails on any unquoted word in Title or Description that names the package or a package in Depends, Imports or Suggests. It reads the source `DESCRIPTION`, or the installed one under `R CMD check`. Leading and trailing dots are dropped before matching.
- `man/nestedtune-package.Rd` carries the new title. No NEWS entry, since the fields change no behavior.

**Decisions:** none. The DOI is kept out of tracking files, because cairn's date check reads its digit groups as a malformed date.

**Review:** AC1 to AC3 passed at `e15b7bc`. `devtools::check(remote = TRUE)` gave 0 errors, 0 warnings and only the incoming NOTE (new submission, development version). The criteria audit moved the text off a refit-model reading and off an unquoted `workflows`. Three lenses reported 13 findings: diff-bug #3 (names after leading dots) fixed in `67bc867`, diff-bug #1, #2 and #4 to the row "DESCRIPTION quoting test word rules", 5 rejected and 4 noted. CI green on PR #163, with an empty PR conversation. The first CI wait reached its limit, and the resumed review merged. Nothing graduated or retired.
