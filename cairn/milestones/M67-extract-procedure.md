# M67: `extract_procedure()` reaches the `procedure` record on both objects, and the em dashes leave the package's user-facing text

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP4
- **Resolves:** —
- **Surface tier:** user-facing — an exported generic, a print method's text and the published help, changelog and README pages
- **Branch/PR:** m067-extract-procedure · https://github.com/tidymodels/nestedtune/pull/77

## Goal

Give the `procedure` record an accessor on the two objects that hold it, so no page or help text tells the reader to reach an attribute or list slot by hand, and remove every em dash from the text the package publishes.

## Scope

**In:** a package-owned S3 generic `extract_procedure()` on D-023's pattern, with a `nested_results` method returning `attr(x, "procedure")`, a `nested_final_fit` method returning `x$procedure`, and a default that aborts with the classed condition the `extract_` family already uses; its help page, `_pkgdown.yml` row, NEWS entry and DESIGN.md Function Families line; every roxygen and vignette site that today spells `attr(x, "procedure")`, `fit$procedure` or "the `procedure` attribute" rewritten onto the accessor; the em dash removed from the results print's candidates line (`R/nested-results-print.R`, `print_candidate_sets()`) with its snapshot re-recorded, and from every roxygen line, string literal, `_pkgdown.yml`, `NEWS.md`, `README.Rmd` and the re-knit `README.md`. Absorbs the two candidate rows added 2026-09-05 (M66 T6 F23; M65 Out).

**Out:** a class or print method for the record itself → not planned; the record prints as the named list it is. Em dashes in code comments → stay; a comment reaches no user. `attr()` and `$procedure` reads inside package code and tests → stay; the accessor is the user's door, the constructor's own reads are not.

## Acceptance criteria

- [x] AC1: `extract_procedure()` is an exported S3 generic with a `nested_results` method returning `attr(x, "procedure")` unchanged and a `nested_final_fit` method returning `x$procedure` unchanged; a test asserts `identical()` for a grid result and for the final fit built from it.
- [x] AC2: The default method aborts with class `nestedtune_no_extract_method`, its message naming the generic, the object's type and both classes that answer; both methods refuse a non-empty `...` with class `rlib_error_dots_nonempty`; a test plants each of the three and a fourth, `extract_procedure(1, foo = 1)`, refused as `nestedtune_no_extract_method` rather than for its dots.
- [x] AC3: A case-insensitive grep of the pattern `attr\([A-Za-z_.]+, *"procedure"\)|\$procedure|`procedure` attribute|procedure slot` over `R/*.R` and `vignettes/**/*.Rmd` finds no hit on a roxygen line (a line beginning with `#'`) and no hit under `vignettes/`; the hits it leaves are in package code, tests aside.
- [x] AC4: A grep for the byte sequence U+2014 and for the escape `\u2014` (any case, with or without braces, with optional leading zeros) over `R/*.R`, `_pkgdown.yml`, `NEWS.md`, `README.Rmd`, `README.md` and `man/*.Rd` finds no hit on a roxygen line, in a string literal, or in any of the five non-`R/` targets; the hits it leaves in `R/*.R` are code-comment lines. `README.md` is re-knit from `README.Rmd` with `devtools::build_readme()`. The `print_candidate_sets()` bullet in `R/nested-results-print.R` is among the sites changed, and its snapshot in `tests/testthat/_snaps/nested-results-print.md` is re-recorded.
- [x] AC5: Each of the six `.Rmd` pages under `vignettes/` (recursive) rendered with `rmarkdown::render()` produces HTML in which a grep for U+2014, `&mdash;`, `&#8212;` and `&#x2014;` finds nothing.
- [x] AC6: `devtools::document()` leaves no diff; `pkgdown::check_pkgdown()` passes; `devtools::test()` is clean; `devtools::check()` reports 0 errors and 0 warnings.
- [x] AC7: A help page `man/extract_procedure.Rd` with an executed example, a `_pkgdown.yml` reference row, a NEWS entry with no milestone number, and a `cairn/DESIGN.md` Function Families line naming the generic exist.

## Coverage

- AC1 → T1
- AC2 → T1
- AC3 → T3
- AC4 → T4
- AC5 → T5
- AC6 → T5
- AC7 → T2

## Tasks

- [x] T1: Tests first in `tests/testthat/test-extract-procedure.R`: identity to the attribute on a grid result and to the slot on its final fit; the default's class and message naming both answering classes; a dots refusal on each method; the no-method refusal winning over a dots complaint. Then the generic, two methods and default in a new `R/extract-procedure.R`, the default routed through `abort_no_extract_method()` (`R/nested-final-fit-extract.R:205`), which gains an argument naming the answering classes so its info bullet stops saying only `nested_final_fit`.
- [x] T2: Roxygen page with `@examplesIf` on the D-023 pages' pattern; `_pkgdown.yml` row under "Running the loop" after `agreement`; NEWS entry; DESIGN.md Function Families line beside the D-052 readers. `devtools::document()`.
- [x] T3: Rewrite the roxygen sites (`R/nested-tune-grid.R:154,243,436`, `R/nested-tune-bayes.R:95,121`, `R/nested-tune-race.R:58,81,111`, `R/nested-tune-sim-anneal.R:100,130`, `R/nested-final-fit.R:124,134`) and `vignettes/tuners.Rmd:324-328` onto `extract_procedure()`, then run AC3's grep until it is clean of roxygen and vignette hits.
- [x] T4: Replace the `\u2014` in `print_candidate_sets()` with a colon or full stop, update the regex at `tests/testthat/test-nested-results-print.R:760`, re-record the snapshot; then sweep the roxygen lines (31 today), `_pkgdown.yml` (2), `NEWS.md` (41) and `README.Rmd` (4), re-knit `README.md`, `devtools::document()`, and run AC4's grep until clean.
- [x] T5: Render the six pages on a quiet machine and grep the HTML (AC5); `air format --check` on the touched files; `devtools::document()` no-diff, `pkgdown::check_pkgdown()`, `devtools::test()`, `devtools::check()` (AC6).

## Work log

- 2026-09-05: created by /milestone-plan.
- 2026-09-05: plan gate chose `extract_procedure()` as a package-owned generic with methods on both classes over `procedure()` (collides with the variable `tuners.Rmd` binds; breaks the `extract_` idiom D-023 chose) and over a `nested_results`-only method (leaves `fit$procedure` the final fit's only door); falsified by hardhat or tune exporting a generic of that name, resolved by dropping ours (D-003).
- 2026-09-05: plan gate chose sweeping em dashes from help pages, `_pkgdown.yml`, `NEWS.md` and README as well as the print line over the print line alone (the candidate row's ask); falsified by nothing about behaviour — a style choice the user declared.
- 2026-09-05: criteria audit ran in full mode on a fresh [O] reader: four findings — AC2's shared abort helper names only `nested_final_fit`; AC3's grep missed prose spelling "the `procedure` attribute"; AC4 missed the `\u2014` escape spelling and left NEWS/README outside the set; AC5 lacked `&#x2014;` — all repaired in the wording above, the NEWS/README part settled at the gate.

- 2026-09-05: implement gate chose a full stop for the print line (`Candidates searched: 5, 5, 5. The folds did not search the same grid`) over a colon or a reorder, and a per-site rewording for the prose sweep over nearest-punctuation replacement; the sweep of roxygen, NEWS, README and pkgdown delegated to one [S] subagent.
- 2026-09-05: T1 done: `extract_procedure()` generic, two methods and default in `R/extract-procedure.R`; `abort_no_extract_method()` takes a `classes` argument, its bullet naming each class with its origin, the two existing callers passing `nested_final_fit` so their snapshot is unchanged; five tests in `test-extract-procedure.R` (AC1, AC2) plus the new default and methods registered in `test-dots-barrier.R`'s probe lists.
- 2026-09-05: T2 done: help page with an executed example, `_pkgdown.yml` row after `agreement`, NEWS entry, DESIGN Function Families line; the `@return` names the four shared arguments the record holds (`param_info`, `event_level`, `eval_time`, `control`), read from `new_procedure()`.
- 2026-09-05: T3 done: the twelve roxygen sites and the two `tuners.Rmd` sites rewritten onto `extract_procedure()`; AC3's grep finds no roxygen or vignette hit.
- 2026-09-05: checkpoint with the full `devtools::test()` run still in progress and the [S] prose sweep mid-flight; T1 to T3 are ticked on their file-level checks and the next commit records the suite result.
- 2026-09-05: full `devtools::test()` on the checkpoint: one failure, the Bayesian oracles' method-coverage table lacking a call for `extract_procedure.nested_results`; the call added, the file re-run clean, the rest of the suite green. T1 to T3 stand verified.
- 2026-09-05: T4 part: the print's candidates line reads `Candidates searched: 5, 5, 5. The folds did not search the same grid`; the regex at `test-nested-results-print.R:759` follows it and the snapshot line is re-recorded, the print file passing; the prose sweep still with the subagent.
- 2026-09-05: T4 done: the [S] sweep reworded 59 roxygen lines (the plan's count of 31 was low), 39 NEWS sites, 4 in README.Rmd and 2 in `_pkgdown.yml`, its diff read here in full with no meaning change found; `document()` and `build_readme()` re-run; AC4's grep finds no hit in any target, and no comment line in `R/` carries one either.
- 2026-09-05: T5 done: the branch package installed (the tuners page attaches the installed nestedtune, and the first render found no `extract_procedure()` there), the six pages rendered and their HTML free of U+2014 and the three entities (AC5); `devtools::test()` 0 failures, `devtools::check()` 0 errors, 0 warnings, 0 notes, `document()` leaving no diff, `check_pkgdown()` clean (AC6). Status to review.
- 2026-09-05: review checkpoint: PR #77 opened as draft; AC1, AC2, AC3, AC4 and AC7 verified with evidence recorded; AC5 and AC6 runs and the three reviewers still in flight.
- 2026-09-05: review fix-now, from the [O] lens: the extract family's `nested_results` origin phrase aligned with `agreement()`'s (`nested_tune_grid()` or one of its siblings) and the snapshot re-recorded; `abort_no_extract_method()` refuses an unknown class instead of printing NA; the `@return` names the Bayesian record's dropped `seed`; the NEWS fragment at the malformed-design entry repunctuated; `results.Rmd` and the DESIGN final-fit line name the accessor; a comment's plurality fixed. Full chain re-run on this tree for AC5 and AC6.
- 2026-09-05: review checkpoint: AC6 verified on 31f751d, gate and the three lenses recorded, six fix-now findings landed; AC5's render run in flight.
- 2026-09-05: review pre-gate checkpoint: all seven criteria verified with evidence; PR #77 conversation empty; approval chip posed.
- 2026-09-05: step-7 approval: PR #77 approved for merge.
- 2026-09-05: CI wait hit the harness ceiling at step 8 with the six R CMD check legs and test-coverage pending on aa85d66 (format-suggest and pkgdown green); watcher stopped, marker written, session stops here; resume re-derives the check state.

## Decisions

## Review

### Acceptance evidence (2026-09-05, branch head fb5fc01 on PR #77)

- AC1: `NAMESPACE` exports `extract_procedure` with S3 methods for `default`, `nested_final_fit` and `nested_results`; the `nested_results` method returns `attr(x, "procedure")` and the `nested_final_fit` method `x$procedure` (`R/extract-procedure.R`); `test-extract-procedure.R` asserts `expect_identical()` against the raw read on a grid result and on the final fit built from it. Fresh run of `test-extract-procedure.R` and `test-dots-barrier.R`: 62 passed, 0 failed, 0 skipped. PASS.
- AC2: the default routes through `abort_no_extract_method()` with class `nestedtune_no_extract_method`; the test asserts the message names `extract_procedure()`, the friendly type (`an integer vector`), `nested_results` and `nested_final_fit`, with a snapshot; both methods call `rlang::check_dots_empty()` and the test asserts `rlib_error_dots_nonempty` on each; `extract_procedure(1, foo = 1)` is asserted `nestedtune_no_extract_method` and not `rlib_error_dots_nonempty`. Same fresh run, green. PASS.
- AC3: the case-insensitive grep over `R/*.R` and `vignettes/**/*.Rmd` finds 9 hits, none on a `#'` line and none under `vignettes/`: the two method bodies, `checks.R`, `nested-final-fit.R`, `nested-final-fit-print.R` (2), `nested-results.R` (2) and one code comment in `tuner.R`. PASS.
- AC7: `man/extract_procedure.Rd` exists with an `\examples` block under `@examplesIf` (executed by `check()`, AC6); `_pkgdown.yml:52` carries the row; `NEWS.md:3` carries the entry and a grep for `M67`/`M067` over NEWS, README, `man/` and `_pkgdown.yml` finds nothing; `cairn/DESIGN.md:77` names the generic in Function Families. PASS.
- AC4: the byte grep for U+2014 and the escape grep (`\\u\{?0*2014\}?`, case-insensitive) over `R/*.R`, `_pkgdown.yml`, `NEWS.md`, `README.Rmd`, `README.md` and `man/*.Rd` each find zero hits, so no roxygen line, string literal or comment carries one. `devtools::build_readme()` re-run at review leaves `README.md` unchanged. `print_candidate_sets()` (`R/nested-results-print.R:364`) reads `Candidates searched: {shown}. The folds did not search the same grid`, the regex at `test-nested-results-print.R:759` follows it, and `_snaps/nested-results-print.md:52` holds the re-recorded line. PASS.
- AC6: on the fix-now tree (31f751d), `devtools::document()` left `git status` empty; `pkgdown::check_pkgdown()` reported no problems; `devtools::test()` 7192 passed, 0 failed, 0 warnings, 0 skipped; `devtools::check()` 0 errors, 0 warnings, 0 notes (6m 54s). PASS.
- AC5: the branch package installed and all six pages under `vignettes/` (recursive: `estimate`, `nested-cv`, `results`, `tuners`, `articles/parallel`, `articles/why-nest`) rendered with `rmarkdown::render()` on the fix-now tree; a grep of the six HTML files for U+2014, `&mdash;`, `&#8212;` and `&#x2014;` finds nothing. PASS.

### Consistency gate (2026-09-05, 31f751d)

- `cairn_validate.py`: all checks passed, exit 0; the 18 `references staleness` lines are the standing advisory, not gate failures.
- `cairn_impact.py`: skipped, no IP/GP principle changed.
- r-package slot: `document()` no diff; `NAMESPACE` and `man/` regenerated, not hand-edited; `build_readme()` leaves `README.md` unchanged; `check_pkgdown()` passes; `NEWS.md` carries the `extract_procedure()` entry with no milestone number; no new top-level file; `check()` 0/0/0 (AC6).

### Independent review (three lenses, fresh context, 2026-09-05)

- [S] blame-history: no findings; every reworded site checked against the milestone that wrote it, the two pre-existing `abort_no_extract_method()` callers' snapshot unchanged.
- [S] prior-review record: no prior-review evidence of regression; the GitHub probe found two real inline comments, both on workflow files this diff does not touch.
- [O] diff-bug, ranked, with disposition:
  - F1 `abort_no_agreement_method()` promises to say what `abort_no_extract_method()` says, and the extract family's `nested_results` origin phrase had drifted from it. Fix now: the extract helper takes agreement's phrase; snapshot re-recorded.
  - F2 `origins[classes]` on an unknown class would print `from NA`. Fix now: `stopifnot(all(classes %in% names(origins)))`.
  - F3 `vignettes/results.Rmd:164` pointed at the `procedure` attribute without naming the accessor. Fix now: the sentence names `extract_procedure()`.
  - F4 `NEWS.md:594` left a subject-less fragment after the em dash became a semicolon. Fix now: a comma.
  - F5 the `@return` did not say a Bayesian record's `control` drops `seed`. Fix now: one clause added; `man/` regenerated.
  - F6 DESIGN's Final-fit bullet named `extract_workflow()` as its only accessor. Fix now: names `extract_procedure()` too.
  - F7 ragged roxygen rewraps and one 140-char generated Rd line. Rejected: cosmetic, renders identically.
  - F8 a comment's "the other default gives" under-counted. Fix now, plural.
  - F9 an 81-character comment line. Rejected: `air` passes, precedent exists.
  - F10 AC1's identity pinned for the grid tuner only. Rejected: AC1 as written names a grid result; the Bayesian shape is exercised by the oracles' coverage table.
  - F11 AC5/AC6 unticked while the work log said green. Resolved by this review's own evidence lines.

### PR conversation (read 2026-09-05 before the gate)

- conversation: PR #77 — no reviews, no comments, no review threads.

