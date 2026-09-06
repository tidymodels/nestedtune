# M67: `extract_procedure()` reaches the `procedure` record on both objects, and the em dashes leave the package's user-facing text

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP4
- **Resolves:** —
- **Surface tier:** user-facing — an exported generic, a print method's text and the published help, changelog and README pages
- **Branch/PR:** m067-extract-procedure

## Goal

Give the `procedure` record an accessor on the two objects that hold it, so no page or help text tells the reader to reach an attribute or list slot by hand, and remove every em dash from the text the package publishes.

## Scope

**In:** a package-owned S3 generic `extract_procedure()` on D-023's pattern, with a `nested_results` method returning `attr(x, "procedure")`, a `nested_final_fit` method returning `x$procedure`, and a default that aborts with the classed condition the `extract_` family already uses; its help page, `_pkgdown.yml` row, NEWS entry and DESIGN.md Function Families line; every roxygen and vignette site that today spells `attr(x, "procedure")`, `fit$procedure` or "the `procedure` attribute" rewritten onto the accessor; the em dash removed from the results print's candidates line (`R/nested-results-print.R`, `print_candidate_sets()`) with its snapshot re-recorded, and from every roxygen line, string literal, `_pkgdown.yml`, `NEWS.md`, `README.Rmd` and the re-knit `README.md`. Absorbs the two candidate rows added 2026-09-05 (M66 T6 F23; M65 Out).

**Out:** a class or print method for the record itself → not planned; the record prints as the named list it is. Em dashes in code comments → stay; a comment reaches no user. `attr()` and `$procedure` reads inside package code and tests → stay; the accessor is the user's door, the constructor's own reads are not.

## Acceptance criteria

- [ ] AC1: `extract_procedure()` is an exported S3 generic with a `nested_results` method returning `attr(x, "procedure")` unchanged and a `nested_final_fit` method returning `x$procedure` unchanged; a test asserts `identical()` for a grid result and for the final fit built from it.
- [ ] AC2: The default method aborts with class `nestedtune_no_extract_method`, its message naming the generic, the object's type and both classes that answer; both methods refuse a non-empty `...` with class `rlib_error_dots_nonempty`; a test plants each of the three and a fourth, `extract_procedure(1, foo = 1)`, refused as `nestedtune_no_extract_method` rather than for its dots.
- [ ] AC3: A case-insensitive grep of the pattern `attr\([A-Za-z_.]+, *"procedure"\)|\$procedure|`procedure` attribute|procedure slot` over `R/*.R` and `vignettes/**/*.Rmd` finds no hit on a roxygen line (a line beginning with `#'`) and no hit under `vignettes/`; the hits it leaves are in package code, tests aside.
- [ ] AC4: A grep for the byte sequence U+2014 and for the escape `\u2014` (any case, with or without braces, with optional leading zeros) over `R/*.R`, `_pkgdown.yml`, `NEWS.md`, `README.Rmd`, `README.md` and `man/*.Rd` finds no hit on a roxygen line, in a string literal, or in any of the five non-`R/` targets; the hits it leaves in `R/*.R` are code-comment lines. `README.md` is re-knit from `README.Rmd` with `devtools::build_readme()`. The `print_candidate_sets()` bullet in `R/nested-results-print.R` is among the sites changed, and its snapshot in `tests/testthat/_snaps/nested-results-print.md` is re-recorded.
- [ ] AC5: Each of the six `.Rmd` pages under `vignettes/` (recursive) rendered with `rmarkdown::render()` produces HTML in which a grep for U+2014, `&mdash;`, `&#8212;` and `&#x2014;` finds nothing.
- [ ] AC6: `devtools::document()` leaves no diff; `pkgdown::check_pkgdown()` passes; `devtools::test()` is clean; `devtools::check()` reports 0 errors and 0 warnings.
- [ ] AC7: A help page `man/extract_procedure.Rd` with an executed example, a `_pkgdown.yml` reference row, a NEWS entry with no milestone number, and a `cairn/DESIGN.md` Function Families line naming the generic exist.

## Coverage

- AC1 → T1
- AC2 → T1
- AC3 → T3
- AC4 → T4
- AC5 → T5
- AC6 → T5
- AC7 → T2

## Tasks

- [ ] T1: Tests first in `tests/testthat/test-extract-procedure.R`: identity to the attribute on a grid result and to the slot on its final fit; the default's class and message naming both answering classes; a dots refusal on each method; the no-method refusal winning over a dots complaint. Then the generic, two methods and default in a new `R/extract-procedure.R`, the default routed through `abort_no_extract_method()` (`R/nested-final-fit-extract.R:205`), which gains an argument naming the answering classes so its info bullet stops saying only `nested_final_fit`.
- [ ] T2: Roxygen page with `@examplesIf` on the D-023 pages' pattern; `_pkgdown.yml` row under "Running the loop" after `agreement`; NEWS entry; DESIGN.md Function Families line beside the D-052 readers. `devtools::document()`.
- [ ] T3: Rewrite the roxygen sites (`R/nested-tune-grid.R:154,243,436`, `R/nested-tune-bayes.R:95,121`, `R/nested-tune-race.R:58,81,111`, `R/nested-tune-sim-anneal.R:100,130`, `R/nested-final-fit.R:124,134`) and `vignettes/tuners.Rmd:324-328` onto `extract_procedure()`, then run AC3's grep until it is clean of roxygen and vignette hits.
- [ ] T4: Replace the `\u2014` in `print_candidate_sets()` with a colon or full stop, update the regex at `tests/testthat/test-nested-results-print.R:760`, re-record the snapshot; then sweep the roxygen lines (31 today), `_pkgdown.yml` (2), `NEWS.md` (41) and `README.Rmd` (4), re-knit `README.md`, `devtools::document()`, and run AC4's grep until clean.
- [ ] T5: Render the six pages on a quiet machine and grep the HTML (AC5); `air format --check` on the touched files; `devtools::document()` no-diff, `pkgdown::check_pkgdown()`, `devtools::test()`, `devtools::check()` (AC6).

## Work log

- 2026-09-05: created by /milestone-plan.
- 2026-09-05: plan gate chose `extract_procedure()` as a package-owned generic with methods on both classes over `procedure()` (collides with the variable `tuners.Rmd` binds; breaks the `extract_` idiom D-023 chose) and over a `nested_results`-only method (leaves `fit$procedure` the final fit's only door); falsified by hardhat or tune exporting a generic of that name, resolved by dropping ours (D-003).
- 2026-09-05: plan gate chose sweeping em dashes from help pages, `_pkgdown.yml`, `NEWS.md` and README as well as the print line over the print line alone (the candidate row's ask); falsified by nothing about behaviour — a style choice the user declared.
- 2026-09-05: criteria audit ran in full mode on a fresh [O] reader: four findings — AC2's shared abort helper names only `nested_final_fit`; AC3's grep missed prose spelling "the `procedure` attribute"; AC4 missed the `\u2014` escape spelling and left NEWS/README outside the set; AC5 lacked `&#x2014;` — all repaired in the wording above, the NEWS/README part settled at the gate.

## Decisions

## Review
