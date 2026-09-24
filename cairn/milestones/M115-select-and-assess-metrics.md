# M115: The help and the guide say which metric selects and which metrics the outer loop scores

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** GP1, GP3, GP5
- **Resolves:** —
- **Surface tier:** user-facing — help pages and a guide that users read
- **Branch/PR:** m115-select-and-assess-metrics

## Goal

The help and the guide tell a user how to choose each fold's candidate under one metric and report another (Stone 1974a, p. 116).

## Scope

**In:** Each orchestrator passes one `metrics` set to the inner tune call and to the outer `tune::last_fit()`. tune's three selectors choose on the first metric in the set (`R/nested-tune-grid.R:717`, `R/selection-rule.R:366`). The outer loop scores every metric in the set. So `metric_set(mae, rmse)` already chooses under `mae` and assesses under `rmse`. No help page or guide says so. The tuning pages inherit tune's one-line `metrics` text. This milestone writes the help text and the guide's prose, and adds tests on the `sep_*` fixture. The API does not change.

**Out:** A `metric` argument on `selection_rule()` and a separate assessment metric set. The plan gate rejected both (work log). Under the `"best"` rule, `summary()` and the final fit's print do not name the selecting metric, and that goes to a candidate row. The gate declined a worked guide chunk, so it leaves no remainder.

## Acceptance criteria

- [x] AC1: The fixture is `sep_*`, and the two rules are `selection_rule()` and `selection_rule("one_std_err", desc(num_comp))`. Under each rule, `nested_tune_grid()` given `metrics = metric_set(mae, rmse)` selects in each outer fold the candidate that tune's selector picks on the `mae` column of that fold's inner run. Under each rule, each fold's outer `rmse` equals the `rmse` that `tune::last_fit()` gives the workflow finalized with that candidate on that fold's split. Under each rule, the same call with `metrics = metric_set(rmse, mae)` selects a different candidate in at least one outer fold.
- [x] AC2: The `metrics` entry of each help page that `grep -l '\\item{metrics}' man/nested_tune_*.Rd` lists states four things. (1) Under the `"best"`, `"one_std_err"` and `"pct_loss"` rules, each fold's candidate comes from the first metric in the set. Where the tuner accepts `"desirability"`, that rule chooses by its goals. (2) `nested_tune_bayes()`, the two racing tuners and `nested_tune_sim_anneal()` also steer their inner search on that first metric. (3) The outer loop scores every metric in the set. (4) If the first metric is not the one the user reads, the run chooses under one loss and assesses under another. Stone (1974a, p. 116) says the two losses need not match. The `metrics` entry of `man/nested_fit_resamples.Rd` states (3) and none of (1), (2) or (4).
- [x] AC3: The "Running the loop" section of `vignettes/nested-cv.Rmd` states three things in prose. tune's three selectors choose on the first metric in the set. The outer loop scores every metric in the set. If the first metric is not the one the user reads, the run chooses under one loss and assesses under another, citing Stone (1974a, p. 116). The milestone adds no code chunk to the guide.
- [x] AC4: The `r-package` profile's `verify` slot is clean (`cairn/PROFILE.md`).

## Coverage

- AC1 → T1
- AC2 → T2, T4
- AC3 → T3, T4
- AC4 → T4

## Tasks

- [x] T1: Add a test block to `tests/testthat/test-metrics-argument.R` on `sep_data()`, `sep_workflow()`, `sep_nested()` and `sep_grid()`. For each rule, compare every fold's `.selected` and outer `rmse` with `reference_nested_loop(metric_name = "mae", select = ...)` (`helper-orchestration.R:130`). Under each rule, assert that `metric_set(rmse, mae)` changes `.selected` in at least one fold. A comment says why the ordering is `desc(num_comp)`: with `num_comp` both orders choose one component in every fold. Use `memoised()` and pin the seeds as the file's other blocks do.
- [x] T2: Give `nested_tune_grid()` its own `@param metrics` with AC2's four statements. Name the tuners that refuse `"desirability"` (`R/tuner.R:117-158`). A source comment cites the `first_metric()` calls in tune's `tune_bayes()` and in finetune's racers and annealer. `nested_fit_resamples()` inherits from `nested_tune_grid` first (`R/nested-fit-resamples.R:23`). So give it its own `@param metrics` that states only (3). Make sure that the bayes, race and sim_anneal pages inherit the grid text (`R/nested-tune-bayes.R:25`, `R/nested-tune-race.R:32`, `R/nested-tune-sim-anneal.R:24`). Run `devtools::document()`.
- [x] T3: Extend the "Running the loop" paragraph (`vignettes/nested-cv.Rmd:131-140`) with AC3's prose. Keep it to plain sentences with no em dashes.
- [x] T4: Run `benchmarks/sweep-prose.R` over the changed help and guide, read the rendered `metrics` entries of all five pages, and run the profile's `verify` slot.

## Work log

- 2026-09-24: created by /milestone-plan. Absorbs the candidate row "Let the metric that selects differ from the metric that scores" (added 2026-07-31), promoted on the user's request.
- 2026-09-24: criteria audit (full mode, fresh reader) returned six findings. Fixed: AC2's text would reach `nested_fit_resamples()` by inheritance, so AC2 now bounds that page. The desirability clause now covers only the tuners that accept it. AC1's test-file sentence moved to T1. AC3 leaves desirability out. Posed at the gate: AC1 probed one tuner and one rule. Nothing to change: separation depends on the fixture's pinned seeds, which AC1 already names.
- 2026-09-24: plan gate chose documenting the set's order over a `metric` argument on `selection_rule()`, because the searches optimize the first metric whatever the selector reads and GP3 prefers one path; falsified by a user needing to select on a metric other than the one their search optimizes.
- 2026-09-24: plan gate chose documenting the set's order over a second assessment metric set, because it adds one argument to six signatures (D-030); falsified by a metric too costly for the inner loop and wanted only in the outer one.
- 2026-09-24: re-audit of the changed AC1 (full mode, same fresh reader) found that `"one_std_err"` by `num_comp` might not separate the two orders. Measured on `sep_*` with seed 20, `mae` first against `rmse` first: `"best"` 1 2 2 against 3 1 3, `"one_std_err"` by `num_comp` 1 1 1 against 1 1 1, by `desc(num_comp)` 5 5 4 against 5 5 5. AC1 now uses `desc(num_comp)` and claims separation under both rules.
- 2026-09-24: plan gate chose probes under `"best"` and `"one_std_err"` on `nested_tune_grid()` over a `nested_tune_bayes()` probe, because the first-metric lookup is fold code every tuner shares and Bayesian tests are the suite's slowest (M114); falsified by a tuner resolving its selecting metric by its own path.
- 2026-09-24: implement started on branch `m115-select-and-assess-metrics`. Read the sources: tune 2.1.0 `tune_bayes_workflow()` and finetune 1.3.0's two racers and annealer each set `opt_metric` from `first_metric(metrics)`. Question gate chose the citation form recorded under Decisions.
- 2026-09-24: T1 done. The new block replaces the file's "selects under the metrics it was given" block, whose one assertion it repeats. With both blocks, the reference loop built twice, which is the cache-key gap the M42 candidate row records. A planted `[[2L]]` for the first-metric lookup turned 9 checks red. Full suite 0 failures, 11406 passes.
- 2026-09-24: T2 done. `nested_tune_grid()` has its own `@param metrics`, which the Bayes, race and annealing pages inherit. `nested_fit_resamples()` has a one-statement entry. The grid page has a references entry that the other three inherit. A source comment at the first-metric lookup cites the four `first_metric()` calls.
- 2026-09-24: T3 done. A second paragraph in "Running the loop" and a References section in `vignettes/nested-cv.Rmd`. No code chunk added.
- 2026-09-24: claim audit: 17 claims read, 0 corrected — R/nested-tune-grid.R, R/nested-fit-resamples.R, R/nested-tune-bayes.R, R/nested-tune-race.R, R/nested-tune-sim-anneal.R, tests/testthat/test-metrics-argument.R, vignettes/nested-cv.Rmd
- 2026-09-24: T4 done. The six gating sweeps are clean. The five rendered `metrics` entries were read. Full suite 0 failures, 11406 passes, and `document()` leaves no diff. Added a `NEWS.md` entry, a sub-task the review gate's changelog check needs. Status set to review.
- 2026-09-24: review gate fixes committed (NEWS wording, en dash, one comment rewrapped). The test file ran 0 failures, and the sweeps and `cairn_validate` were clean.
- step-7 approval: m115-select-and-assess-metrics approved for merge

## Decisions

- 2026-09-24 (implement question gate): user-facing text cites the source AC2 and AC3 name as "Stone (1974, p. 116)". The full reference goes in a references entry on `nested_tune_grid()`, which the Bayes, race and annealing pages inherit. It also goes in a new References section of `vignettes/nested-cv.Rmd`. The "a" in `stone1974a` tells two papers apart on the internal shelf only, and a reader sees one Stone paper. AC2's and AC3's "Stone (1974a, p. 116)" is read as naming that source.

## Review

- AC1 (2026-09-24): `test-metrics-argument.R` block "the first metric in the set selects, and the outer loop scores every metric" ran 23 expectations with 0 failures on `sep_*`. Under `selection_rule()` and `selection_rule("one_std_err", desc(num_comp))`, it compares each fold's `.selected` with tune's selector on the reference run's `mae` column. It compares each fold's outer `rmse` row with `tune::last_fit()` on the finalized workflow. It asserts that `metric_set(rmse, mae)` changes `.selected` in at least one fold. With `[[2L]]` planted at the first-metric lookup, the block failed 8 of 23. The source was restored.
- AC4 (2026-09-24): `devtools::check()` gave 0 errors, 0 warnings and 0 notes, its test run included. `devtools::document()` left no diff. `sweep-prose.R --plain` and `--roxygen --plain` were clean.
- Gate (2026-09-24): `cairn_validate.py` exit 0, with 18 references-staleness advisories on pages this milestone did not touch. The six gating sweeps were clean. `pkgdown::check_pkgdown()` found no problems. README.Rmd is unchanged. The `NEWS.md` entry is present. No principle changed, so `cairn_impact` was skipped.
- Triage at the gate (2026-09-24). O1 (NEWS said the first metric chooses with no rule named): fixed, the entry names the three rules. O2 (NEWS line break and no mention of the `nested_fit_resamples()` help): fixed. O3 (p. 116 not checked against the paper): rejected, `cairn/references/stone1974a.md` quotes the sentence at p. 116. O4 (hyphen in the roxygen page range): fixed to an en dash. O5 (two roxygen lines over 80 characters): rejected, they are unmodified `@templateVar` lines. O6 (two test lines over 80): the comment was rewrapped, and the `test_that()` name was kept because 408 names in the suite exceed 80. O7 (self-links in the shared text): rejected as a result of inheritance. O8 (the reversed run checks only that the choice changes): noted, AC1 asks for no more. O9 (`nested_workflow_map()` help): follow-up candidate row. S1 (AC1 and AC4 unticked): resolved by their evidence lines.
- Reviewers: [O] diff-bug found 9 minor findings and no correctness defect. [S] blame-history found 1 finding (AC1 and AC4 unticked, since resolved). [S] prior-review found no finding that repeats a past review, and GitHub threads had no comments on the touched files.

- AC2 (2026-09-24): `grep -l '\\item{metrics}' man/nested_tune_*.Rd` lists the grid, bayes, race and sim_anneal pages. Their full `metrics` entries hash identically, and the grid entry, read in full, states the four things. (1) The three rules choose on the first metric, and the desirability rule chooses by its goals, accepted by grid and Bayes. (2) The Bayes, two racing and annealing tuners steer on the first metric. (3) The outer loop scores every metric. (4) A first metric other than the one read chooses under one loss and assesses under another, citing Stone (1974, p. 116) per the implement Decision. `man/nested_fit_resamples.Rd`'s entry states (3) alone.
- AC3 (2026-09-24): the "Running the loop" section of `vignettes/nested-cv.Rmd` states the three things in prose. tune's three selectors choose on the first metric. The outer loop scores every metric. The one-loss-and-another sentence cites Stone (1974, p. 116). `git diff main...HEAD -- vignettes/` adds no fence line.
