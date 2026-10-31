# M163: Keep an oracle registry outside tests

**Status:** done (2026-10-31, PR #179 https://github.com/tidymodels/nestedtune/pull/179)

**Goal:** Record each oracle of the test suite in `cairn/ORACLES.md`, so that a committed record shows the oracle types behind each numeric result.

**Outcome:** Tracking files only; no package code, test or doc change.
- `cairn/ORACLES.md`: 71 typed rows, one per record that `git grep -E '^# +O[0-9]+[a-z]?( +--)? +type' 576c3d19 -- tests/testthat` lists, and 17 prose rows from the 20 files with prose oracle comments and no typed record, each file with one line. A row gives id (file stem plus label, `U<n>` for prose), doctrine type (the record's own word in brackets where it differs), source, and its tests at the head by file and `test_that()` name, mapped through `benchmarks/test-renames-576c3d19.csv`.
- A test counts as named only when its record quotes the name (wildcards `...` and `<...>`, `%s` and non-literal arguments in names built in code); 87 of 147 test lines carry "(found by reading)". Six rows say their "Pinned by" quote names no test.
- 26 named groups with type counts, stated as one cut of the results. Nine rest on one type, held by the new row "Settle oracle types for nine groups" with the finer one-type results review found.
- Type rules in the header: "analytic" is closed-form, "analytic by-hand" maps by what it does, and a reference that runs the package's own function by hand is invariant.
- The DESIGN.md oracle-records bullet names `cairn/ORACLES.md`, says which comments it reads, and says a milestone that adds or removes an oracle updates it.

**Decisions:** milestone-local: AC4 amended to named groups and AC1 to the quoted-name rule (the user chose it at the second-re-audit stop over a "Pinned by"-only rule and parking); upkeep by hand at review, no sync test (plan gate). None promoted.

**Review:** Four passes, each an Opus diff-bug and a Haiku ripple reviewer (internal tier, docs-only). Two defect returns (rows breaking AC1 and AC2, one group merging four results) and two amendment returns (AC4 grain, AC1 naming), each amendment audited by fresh Opus readers. 72 findings: 28 fixed, 27 rejected, 11 routed to the amendments, 5 to the new parked row "Point test oracle headers at the registry", 1 split. `devtools::check()` 0/0/0; `document()` bumped only the roxygen2 version stamp, reverted. CI: format-suggest passed, the other workflows skip a `cairn/`-only diff. Row "Keep an oracle registry outside tests" graduated. Lesson added on registry upkeep; the M86 lesson marked used.
