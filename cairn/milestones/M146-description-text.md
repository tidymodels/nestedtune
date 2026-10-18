# M146: DESCRIPTION's Title and Description say what the package does, in CRAN's form

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP3
- **Resolves:** —
- **Surface tier:** user-facing — CRAN and the package page show these two fields to users
- **Branch/PR:** m146-description-text

## Goal

`DESCRIPTION`'s `Title` and `Description` fields say what the package does today, with package names quoted as CRAN asks.

## Scope

**In:** the two fields are replaced by the text below, approved at the plan gate. A new test checks that every package name in them is in single quotes.

Title:

    Nested Cross-Validation for 'tidymodels'

Description:

    Estimates how well a model tuning procedure performs on new data, by
    nested cross-validation. An inner resampling loop tunes the model with
    'tune' or 'finetune'. An outer loop scores each tuned model on rows that
    the tuning did not see, as in Varma and Simon (2006)
    <doi:DOI>. The package supports grid search, Bayesian
    optimization, racing, simulated annealing, fixed models and sets of
    models from 'workflowsets'. A separate function runs the procedure on all
    the data to fit the final model. The outer folds can run in parallel with
    'mirai'. The nested resampling constructor makes the same splits as
    nested_cv() from 'rsample', but it stores row indices in place of a copy
    of the data for each outer fold.

`DOI` stands for the DOI that `cairn/references/varma2006.md` records on its citation line. It is not written out here because cairn's date check reads its last three parts as a malformed date.

**Out:** `Authors@R` and the Posit copyright and funder question stay with the "Posit attribution" candidate row. The version bump, `cran-comments.md`, the NEWS consolidation and `urlchecker` over the whole package belong to the release walk (`/cairn-release`). The README and the site's home page are not changed.

## Acceptance criteria

- [x] AC1: `DESCRIPTION`'s `Title` field reads `Nested Cross-Validation for 'tidymodels'`, and its `Description` field reads the text in this file's Scope word for word, with `DOI` replaced as Scope says, and with line breaks and indentation free.
- [x] AC2: In `DESCRIPTION`'s `Title` and `Description` fields, every word that equals, ignoring case, the package's own name or the name of a package in its `Depends`, `Imports` or `Suggests` field (R excepted) is enclosed in single quotes. A word is a maximal run of letters, digits and dots. `tests/testthat/test-description.R` checks this with `read.dcf()` on those fields.
- [x] AC3: `devtools::check(remote = TRUE, manual = FALSE)` on the branch head reports 0 errors and 0 warnings, and none of its NOTEs reports an invalid DOI or URL in `DESCRIPTION`.

## Coverage

- AC1 → T2
- AC2 → T1, T2
- AC3 → T3

## Tasks

- [x] T1: Write `tests/testthat/test-description.R`. It reads the source tree's `DESCRIPTION` when one is there and the installed package's otherwise, builds the name set from `Depends`, `Imports`, `Suggests` and `Package`, and fails on any unquoted word in that set. Confirm it fails on today's text (`tidymodels` unquoted), and on a copy with one planted unquoted name in each field.
- [x] T2: Replace the two fields with the Scope text. Run the new test, `devtools::test()` and `devtools::check()`.
- [x] T3: Run `devtools::check(remote = TRUE, manual = FALSE)` and note each `DESCRIPTION` NOTE in the work log, the possibly misspelled words included.

## Work log

- 2026-10-17: created by /milestone-plan.
- 2026-10-17: tier check: milestone — the request (items 1, 4 and 5 of the release-readiness list) includes CI jobs and an export review, and asked for a plan.
- 2026-10-17: question set: use the drafted Title and Description — use this text.
- 2026-10-17: criteria audit (full mode) returned two findings. The first opening ("how a tuned model performs", then "refits the chosen procedure") could read as describing the refit model, against IP3. The text now names the procedure and says a separate function fits the final model. "untuned workflows" put `workflows`, an Import, unquoted, so AC1 and AC2 could not both pass. The text now says "fixed models and sets of models from 'workflowsets'", and AC2 defines a word. AC3 had no finding.
- 2026-10-17: plan gate chose a test over every declared dependency's name over a fixed list of the five names the text quotes, because a later edit that adds a package name is caught; falsified by a false positive on a common word that is also a package name.
- 2026-10-17: no NEWS entry. The fields describe the package and change no behavior.
- 2026-10-17: inbox sweep: 1 open issue (#91, the maintainers' pass over the guides), no overlap with this milestone.
- 2026-10-17: checkpoint, T1 and T2 written and not yet ticked. `test-description.R` failed on the old fields (`Tidymodels` and `tidymodels` unquoted) and passes on the new ones. Its checker self-test plants unquoted names. Words with trailing dots are also matched with the dots dropped, which checks more than AC2 asks. `man/nestedtune-package.Rd` is regenerated for the new Title. The full suite and `devtools::check()` are running.
- 2026-10-17: T1 and T2 done. `devtools::test()` passed with no failures and no skips. `devtools::check(manual = FALSE)` gave 0 errors, 0 warnings and 0 notes. `air format` reflowed one call in the new test.
- 2026-10-17: T3 done at `309142f`. `devtools::check(remote = TRUE, manual = FALSE)` gave 0 errors, 0 warnings and 1 NOTE, the CRAN incoming feasibility NOTE. It names the maintainer, "New submission" and "Version contains large components (0.0.0.9000)", and no DOI, URL or misspelled word. The version line goes away at the release walk's version bump.
- 2026-10-17: claim audit: 19 claims read, 1 corrected — DESCRIPTION. The sentence "its size does not grow with the number of outer folds" was false: `test-nested-resamples-memory.R:100-120` records 1.2x to 10.0x the data for 2 to 50 outer folds, a slope of 0.18 per fold against rsample's 1.15. The old Description on main made the same claim.
- 2026-10-17: substantive amendment: Scope's Description text, at the user's choice at a stop. The last sentence now reads "The nested resampling constructor makes the same splits as nested_cv() from 'rsample', but it stores row indices in place of a copy of the data for each outer fold." AC1's wording is unchanged, so no criterion re-audit is owed. DESCRIPTION carries the same sentence.
- 2026-10-17: implement done, status set to review. AC3's remote check ran at `309142f`, before the amended sentence, so review re-runs it on the head.

## Decisions

## Review

Review pass 1, 2026-10-17, at `e15b7bc`.

- AC1: a script compared `DESCRIPTION`'s fields with this file's Scope text, whitespace-normalized and with `DOI` replaced by `cairn/references/varma2006.md`'s DOI. Title and Description both matched. A control copy with "row indices" changed to "row numbers" did not match.
- AC2: `test-description.R` passed (7 expectations) on the head. Its checker, run on the 33 declared names (the package, 9 Imports and 23 Suggests), found no unquoted name in either field. The same checker on `main`'s fields found `Tidymodels` in Title and `tidymodels` in Description. The test also passed inside `R CMD check`, where it reads the installed `DESCRIPTION` (AC3's run, whose tests step reported OK).
- AC3: `devtools::check(remote = TRUE, manual = FALSE)` at `e15b7bc` gave 0 errors, 0 warnings and 1 NOTE, the CRAN incoming feasibility NOTE: the maintainer line, "New submission" and "Version contains large components (0.0.0.9000)". No NOTE named a DOI, a URL or a misspelled word. `DESCRIPTION` is unchanged from `e15b7bc` to the review head.
- Consistency gate: `cairn_validate.py` passed. The same check run is the profile's full check (0 errors, 0 warnings, and the incoming NOTE, which the release's version bump and first submission account for). All six gating prose sweeps were clean. No new top-level file. No NEWS entry, by the plan's decision: the two fields describe the package and change no behavior.
- spawned: diff-bug, blame-history, prior-review
- diff-bug #1: `tune` inside `tune_grid()` and `rsample` inside `rsample::nested_cv()` count as bare names, since a word excludes `_` and `:` — follow-up, new candidate row "DESCRIPTION quoting test word rules". AC2's own word definition makes this the required behavior, and the current text has no such case.
- diff-bug #2: Suggests names that are common words (`survival`, `censored`, `recipes`, `tailor`, `dials`) would demand wrong quotes in later prose — follow-up, same row. It is the plan gate's recorded falsifier.
- diff-bug #3: a name after leading dots (`.tune`, `...tune`) is missed, since only trailing dots are dropped — fix now, fixed `67bc867`. The checker now drops leading dots too, and a planted "...tune" is caught; the old checker returned nothing for it.
- diff-bug #4: the quote check reads only the next character on each side (`x'tune'y` passes), and a name inside a DOI would be flagged — follow-up, same row.
- diff-bug #5: curly quotes, double quotes and backticks count as unquoted — reject (false): CRAN asks for straight single quotes, so this is the intended behavior.
- diff-bug #6: "An inner resampling loop tunes the model" does not fit fixed models, which the text also lists — reject (planned change): the user approved this wording at the plan gate.
- diff-bug #7: AC3's evidence and the AC2 and AC3 ticks were pending when the reviewer read the file — noted. This pass's check supplies them.
- diff-bug #8: D-024 forbids a CRAN submission — reject (false): D-025 lapsed that clause, and this milestone submits nothing.
- blame-history #1: the new text drops "memory-lean" and "orchestrates", which carried D-005's and D-002's framing — reject (planned change): the user approved the text, and no D-entry pins DESCRIPTION wording.
- blame-history #2: the removed "does not grow" clause was M01's goal wording, contradicted by M01's own measured slope — noted. It confirms the claim-audit correction.
- blame-history #3 to #6: no decision covers the Title, the DOI matches the reference page, the Rd change is roxygen's, and the new wording matches DESIGN.md and IP3 — noted.
- prior-review #1: no prior finding is reintroduced. Its residual note, that "in place of a copy" may overstate, is rejected (false): `R/nested-resamples.R:92` says the object keeps only row indices pointing back at `data`.
