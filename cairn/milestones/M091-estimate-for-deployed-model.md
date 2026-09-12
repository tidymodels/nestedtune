# M091: The docs give the nested estimate as the number to report for the deployed model

- **Status:** planned
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** IP3
- **Resolves:** —
- **Surface tier:** user-facing — README, the four guides, three help pages and a print method
- **Branch/PR:** —

## Goal

The README, the four guides, the final-fit help pages and the final-fit print method state the nested estimate as the number to report for the deployed model, with the procedure-not-model principle given as the reason for that number and not as a disclaimer.

## Scope

**In:** `README.Rmd` (re-knit to `README.md`), `vignettes/estimate.Rmd`, `vignettes/nested-cv.Rmd`, `vignettes/results.Rmd`, `vignettes/tuners.Rmd`. The roxygen text at the sites T5 names in `R/nested-final-fit.R`, `R/nested-final-fit-print.R`, `R/nested-tune-grid.R`, `R/nested-results.R` and `R/nested-results-agreement.R`. The Estimate section of `print.nested_final_fit()` and its tests. A new opening on README and `estimate.Rmd`. That opening says three things. Scoring the tuned winner once on a test set gives one score from one split. The outer folds give the mean and the spread. Each fold tunes on its own.

**Out:** the principle text of IP3 in `cairn/DESIGN.md` (unchanged, T6 checks). `NEWS.md`'s development bullets (the `[low]` NEWS candidate row). `vignettes/articles/parallel.Rmd`, which names the procedure once and makes no claim about the model. The wider #91 rewrite (its candidate row). The `$tuning` metrics warning at `R/nested-final-fit.R:150-154`, which stays as the reason those metrics are not the model's.

## Acceptance criteria

- [ ] AC1: Each of the ten prose extents T1 to T4 name, by file and line range at `27b4efd`, differs in prose from its text at that commit. Evidence: for each extent, its lines from `git show 27b4efd:<file>` and the paragraph at HEAD in its place are shown with whitespace collapsed, and are unequal. The HEAD paragraph is the run `Rscript benchmarks/sweep-prose.R --paragraphs` prints for that line.
- [ ] AC2: On `README.Rmd`, `vignettes/estimate.Rmd` and `vignettes/nested-cv.Rmd`, the first prose sentence saying what the reader reports for the deployed model comes before the first prose line matching `grep -nE -i 'is not|has no|no performance'`. On `vignettes/results.Rmd` and `vignettes/tuners.Rmd`, the first prose sentence mentioning the deployed model says what number to report for it. Prose is the output of `awk '/^```/{f=!f;next} !f' <file>` with the YAML header dropped (the first two `^---$` lines and what lies between). Evidence: `file:line` and the quoted sentence at each site.
- [ ] AC3: `README.Rmd`'s opening and the first paragraph of `vignettes/estimate.Rmd`'s case-for-nesting section each state three facts before the selection-bias explanation. Tuning with cross-validation and then scoring the winner once on a test set gives one score from one split. The outer folds give the mean and how far the score moves between splits. Each outer fold tunes on its own, so no outer score is a winner's own score. Every sentence names its referent (no "the usual path" without saying of what) and carries no interpolated list of steps. Evidence: the sentences quoted with `file:line`.
- [ ] AC4: `vignettes/nested-cv.Rmd` and `vignettes/estimate.Rmd` each keep one paragraph that says three things (IP3's documentation obligation). The estimate describes the tune-and-fit procedure. It is the number to report for the model the user deploys. The deployed model is that same procedure run on all the data, so there is no second number to compute for it. Evidence: the two paragraphs quoted. (RB tripwire: ip-touching)
- [ ] AC5: Over the five AC2 pages and the five R files T5 names, `grep -nE -i 'estimated by nothing|no performance (number|claim|estimate)|nothing above produced|things it is not|what it is not|that is deliberate|separate object with no' <file>` prints no line. The claim is exactly what the grep sweeps: these phrasings are gone from those ten files. Evidence: the command's output per file.
- [ ] AC6: The Estimate section `print()` shows for a `nested_final_fit` says two things. The number to report for this model is the nested estimate from `collect_metrics()` on the results object the fit was built from. That estimate describes the procedure that produced the model. The `?nested_final_fit`, `?print.nested_final_fit` and `?nested_tune_grid` pages say the same. Evidence: the printed output and the three rendered sections quoted, and `devtools::test()` clean on `test-nested-final-fit-print.R` with its snapshot re-accepted.
- [ ] AC7: Each command `Rscript benchmarks/sweep-prose.R --list-gating` prints exits 0. The word counts by `awk '/^```/{f=!f;next} !f' <file> | wc -w` (a count that includes the YAML header) are at most 350 / 1450 / 1500 / 1500 / 1500 in the AC2 file order. `pkgdown::build_articles()` renders every page without error. A second `devtools::build_readme()` leaves `README.md` unchanged. `devtools::check()` reports 0 errors, 0 warnings, 0 notes. One reader with no authorship of the text reads the five AC2 pages and answers two questions: after reading, what number do you report for the model you deploy, and would you run nested cross-validation rather than report the tuned score. The reader also lists every paragraph that made nested cross-validation sound not worth running, with one line of reason each. Every entry is triaged at the review gate as fixed, rejected with a reason, or deferred to a ROADMAP candidate row, and the triage is recorded in this file's Review section. The report is taken once per review pass and not rerun after its fixes. No criterion binds the report's contents (D-061).

## Coverage

- AC1 → T1, T2, T3, T4
- AC2 → T1, T2, T3, T4
- AC3 → T1, T3
- AC4 → T1, T2
- AC5 → T1, T2, T3, T4, T5
- AC6 → T5
- AC7 → T6, T7

## Tasks

- [ ] T1: `vignettes/estimate.Rmd`: rewrite four extents at `27b4efd`. Lines 22-28: the case for nesting opens with the AC3 facts, then the selection-bias paragraph. Lines 40-44: the IP3 paragraph (AC4). Lines 49-52: the quantity estimated leads with what the reader reports. Lines 54-64: the "Four things it is not" list becomes a scope paragraph after the positive claim, its four facts kept. Keep every citation. `Rscript benchmarks/sweep-prose.R --plain` clean.
- [ ] T2: `vignettes/nested-cv.Rmd`: rewrite 235-238 (the final-fit section opens with what the reader now has and reports) and 352-355 (the honesty paragraph, AC4). Read 322-345, the write-up template. Change it only if its "for the procedure" sentence contradicts the new paragraphs. Sweep clean.
- [ ] T3: `README.Rmd`: rewrite 25-34 (the two opening paragraphs, AC3 and the report sentence), the chunk comments at 67 and 70, and the link blurb at 81-82 ("what it is not"). `devtools::build_readme()`, and commit `README.md` with it. Sweep clean.
- [ ] T4: `vignettes/results.Rmd` 233-238 and `vignettes/tuners.Rmd` 436-439: the first mention of the deployed model on each page says what to report for it. Sweep clean.
- [ ] T5: Help pages and print. Roxygen at `R/nested-final-fit.R:24-26` and `:146-150`, `R/nested-final-fit-print.R:14-19` and `:101`, `R/nested-tune-grid.R:14-18`, `R/nested-results.R:705`, `R/nested-results-agreement.R:19`. The printed message at `R/nested-final-fit-print.R:58-60` and `:365-367` is one string used twice, so hoist it to one constant. Update `tests/testthat/test-nested-final-fit-print.R:19`, `:100` and `:158` to the new message, re-accept `_snaps/nested-final-fit-print.md`, run `devtools::document()`. `Rscript benchmarks/sweep-prose.R --roxygen --plain` clean.
- [ ] T6: Run every AC7 command and record each result in the work log. Make sure that `git diff 27b4efd -- cairn/DESIGN.md` is empty.
- [ ] T7: Write the reader prompt as one work-log line: the two AC7 questions, the five page paths, and the instruction to list paragraphs with one line of reason each. Review takes the report from it unchanged.

## Work log

- 2026-09-12: created by /milestone-plan. Criteria audit ran in full mode ([O] reader) and returned five findings, fixed before the gate. AC1's blame probe became a prose comparison and the two README chunk comments moved to T3. AC2 narrowed to prose, dropped `nothing` and `never`, and binds ordering on three pages. The DESIGN.md diff moved to T6. AC5's phrase list keeps the IP3 discharge phrasing banned, which AC4 states another way. The estimate.Rmd word cap rose to 1450 with the recipe's YAML count stated. The reader-report criterion was clean.
- 2026-09-12: plan gate chose the paired framing (one test split versus several outer splits, tied to each fold tuning on its own) over the split contrast alone because alone it argues for plain repeated cross-validation, not nesting. Falsified by a reader report finding the tuning half redundant. The user rejected the gate's draft sentences for unclear referents and interpolated step lists, so the text is written at implement under AC3's referent rule and the sweep.
- 2026-09-12: plan gate chose the help pages and print message in scope over a candidate row. This was the user's decision against the plan's recommendation, so the pages, the help and the print say one thing.
- 2026-09-12: plan gate declined Fable escalation on the ip-touching tripwire (AC4). IP3's text is unchanged and the paragraph states its three facts in a positive order. M082 declined the same.

## Decisions

## Review
