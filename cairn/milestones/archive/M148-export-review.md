# M148: Each export and result column is set beside its tidymodels counterpart, with a verdict for each difference

**Status:** done (2026-10-18, PR #165 https://github.com/tidymodels/nestedtune/pull/165)

**Goal:** Before the first release, every package-owned export, every method of an exported generic, and every result column is compared with its tidymodels counterpart, and each difference is kept for a stated reason, changed where the change breaks no call, or proposed for a later decision.

**Outcome:** `benchmarks/export-surface.R` reads `NAMESPACE` (16 package-owned functions, 59 methods of exported generics), pairs each through a table it checks against `NAMESPACE`, and prints argument and order differences. Its second half runs the six orchestrators and `nested_workflow_map()` on a 3-by-4 `mtcars` design and compares result columns with each counterpart on fold 1's inner resamples.
- `cairn/references/export-surface-review.md` names each item's counterpart or none (75 rows) and gives a verdict on each of 20 one-side arguments, the order differences and 10 one-side columns: 2 changed, 3 proposed, the rest kept with a D-entry or a stated reason.
- The changed verdicts: the `workflow` and `model_spec` methods of `nested_tune_bayes()` and `nested_tune_sim_anneal()` list `eval_time` before `objective` and `initial`, in tune's and finetune's order. `test-argument-order.R` checks it (skipped on CRAN), with a NEWS entry.
- The proposed verdicts and the uncompared defaults are the candidate row "Argument gaps beside tidymodels".

**Decisions:** D-117 records the reorder and narrows D-069's clause that the `workflow` method keeps each function's formals.

**Review:** Pass 1 returned AC1, because 56 of 75 items were named only through grouping rules; T7 added the per-item table. Pass 2 passed AC1 to AC3. `devtools::test()` gave 15533 passes and 0 failures, and `devtools::check()` gave 0 errors, 0 warnings, 0 notes. The claim audit corrected 1 of 27 claims (the script header). Three lenses reported 15 findings: 9 fixed (CRAN skip, D-117, six page reasons and citations), 1 sent to the candidate row (defaults not compared), 5 rejected (two style, three that reported no defect). The first CI wait reached its limit; the resumed review merged with all 17 checks green. No lesson was captured or retired.
