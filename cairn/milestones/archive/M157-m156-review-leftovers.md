# M157: Test checks and names that M156's review flagged say only what they check

**Status:** done (2026-10-23, PR #174 https://github.com/tidymodels/nestedtune/pull/174)

**Goal:** Fix the test-code findings that M156's review filed, as the candidate row "Fix the leftovers of M156's review" lists them.

**Outcome:** Tests, one helper comment and the code inventory's provenance. No package code, help page or NEWS change.
- The final-fit blocks "the record refusals fire before anything is drawn" and "the all-failed refusal fires before anything is drawn" remove `.Random.seed` before the refusal and assert it still does not exist after. Seed identity could not fail there, since `nested_final_fit()` registers `restore_rng()` before its draw. Moving the draw above `check_workflow(object)` failed both blocks on the `exists()` check alone.
- Four untuned-workflow blocks (grid, bayes, race, sim-anneal) lost ", before any fold runs". The grid block "the new refusals ..." became "a malformed design or a workflow with no preprocessor is refused before the RNG is drawn from" and asserts each refusal by class and message (`nestedtune_bad_design` twice, `rlang_error` for the no-preprocessor one).
- The `min_n` comment moved above `bayes_stoch_param_info()` in `helper-orchestration.R`.
- `cairn/references/code-inventory.md` names `601cff7e` (M33's remap) as the commit its table's line numbers match, all 106 `F` rows checked (corrected M157).
- Plan gate: item 2 (existence checks for `nested_fit_resamples()` and `nested_workflow_map()` refusals) was dropped at the user's choice, since the map deletes the state it creates. Item 4 went to the row "Give the unclassed refusals a class" (19 unclassed refusals in `R/checks.R`). The plan merged the Posit and CODEOWNERS rows and cut nine repeated titles to stay under the ROADMAP caps.

**Decisions:** milestone-local only: the existence check over removing the final-fit seed checks; renaming the untuned blocks over a new dispatch check; fixing the inventory's provenance over editing two rows. None promoted.

**Review:** Four-lens fan-out, one pass, no return. 22 findings: 3 fixed (grid comments, the no-preprocessor class), 3 to the new row "Fix seed checks in four refusal tests", 16 rejected. `devtools::test()` 1152 blocks, 0 failed. `check()` 0/0/0. CI: `ubuntu-latest (devel)` failed 53 censored tests from an R-devel bug (r90747's `delete.response()` drops `NULL` specials, which breaks `prodlim::prodlim()` and so parsnip's censoring model). R core fixed it in r90749. It was reproduced in an r-hub R-devel container, and main failed the same job from 71e19150. The user chose to merge past that job, recorded as an override. Two other jobs were cancelled at 30-minute caps and passed on rerun. The local PR-record, resume and override commits after e1511550 were not pushed, and this summary carries them. Row "Fix the leftovers of M156's review" graduated. No lesson added; none retired; none unparked.
