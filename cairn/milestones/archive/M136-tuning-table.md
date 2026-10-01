# M136: README table of supported tuning functions, and shorter table prose

**Status:** done (2026-09-30, PR #151 https://github.com/tidymodels/nestedtune/pull/151)

**Goal:** The README says which tidymodels tuning functions nestedtune supports, and both of its support tables read in a short space.

**Outcome:** `README.Rmd` has a "Supported tuning functions" section with eight rows. Seven tuners read `Yes` and name their nested counterpart, and `tidyclust::tune_cluster()` reads `No`. The prose defines `Yes` and `No` and points to the "Time-series designs" help section and the tuners article. The prose under the resampling table fell from 789 to about 200 words, and its 17 table lines did not change. The two sections hold 378 words by the AC4 command. The "Differences from rsample" section of `?nested_resamples` now gives the reason for each `Refused` cell and the inner `validation_set()` `No` cell. The outer bootstrap hint in `nested_resamples()` and `check_nested()` now reads "builds this design, with a warning at most". rsample builds `group_bootstraps()` and `rsample::bootstraps()` calls with no warning. `test-design-support.R` asserts the new hint, and the workflow-map oracle test asserts `all(.completed)` directly. NEWS has one bullet.

**Decisions:** D-110 at plan. The plan gate chose a separate tuning table over per-tuner columns, eight rows over six or ten, and a 400-word limit.

**Review:** Three fresh reviewers found no failing criterion, and all seven criteria had fresh evidence. `devtools::check()` gave 0 errors, 0 warnings and 0 notes before and after the gate fixes. CI passed 14 checks with 1 skipped. Of 15 findings, F1 to F6 were fixed at the gate. They were a stale `DESIGN.md` line about rsample warnings (corrected in place), a README pointer to the racers' apparent-split rule, and a stale test header. The others were an overstated `R/checks.R` comment, one unclear README sentence, and two reflows. F7 to F15 were rejected with reasons in the milestone file in git. No lesson was added or retired. `LESSONS.md` is at its byte budget, and the rsample warning fact lives in the `R/checks.R` comment and its test.
