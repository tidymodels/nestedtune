# M123: The parameter set a final fit searched

**Status:** done (2026-09-28, PR #138 https://github.com/tidymodels/nestedtune/pull/138)

**Goal:** A final fit answers tune's `extract_parameter_set_dials()` with the parameter set its tuning run searched.

**Outcome:** `extract_parameter_set_dials.nested_final_fit()` in `R/nested-final-fit.R` returns `attr(x$tuning, "parameters")`, the set tune stored on the tuning run. The trained workflow holds no `tune()` placeholder, so the method does not read the workflow. It refuses a fit from `nested_fit_resamples()` with `check_tuning_run()` and a non-empty `...` with `rlang::check_dots_empty()`. The generic is imported from tune and re-exported in `R/reexports.R`. The method is on the `extract-nested_final_fit` help topic. The topic states that tune finalizes any unknown range for candidates it builds itself. It also states that a data-frame `grid` can keep an unknown range. `NEWS.md` has one bullet. `tests/testthat/test-nested-final-fit-extract.R` has five new tests, for AC1's cases (a) to (d), both refusals and the re-export. After a probe on tune 2.1.0, a gated amendment added case (d), a data-frame `grid`.

**Decisions:** D-089 extends D-068 with this eighth extractor.

**Review:** Three fresh reviewers found no code bug. The diff reviewer ranked O1 to O8. O1 to O3 were fixed in the help at the gate: racing and annealing also finalize, a `param_info` with an unknown range comes back finalized, and the description now names the exception. O7 was a wrong work-log claim about `nested_tune_bayes()`, corrected by a new line. O4, O5, O6 and O8 were rejected with reasons. A planted defect turned all five new tests red. `devtools::check()` gave 0 errors, 0 warnings and 0 notes after the fixes. A timed-out CI wait resumed and merged on green.
