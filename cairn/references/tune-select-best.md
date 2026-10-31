# tune-select-best — what tune's three selection rules pick, as its help page defines them

**Provenance.** Ingested 2026-10-31 by M164 from tune 2.1.0's installed help page `select_best.Rd` (`?tune::select_best`). It was read with `tools::Rd2txt(tools::Rd_db("tune")[["select_best.Rd"]])`. The method bodies `tune:::select_by_pct_loss.tune_results` and `tune:::select_by_one_std_err.tune_results` were printed in the same session.
Pagination: —.
Extraction: read directly 2026-10-31 from tune 2.1.0's installed help page and method bodies — observed 2026-10-31.

**Citation.** Kuhn, M., and others. tune: Tidy Tuning Tools. R package version 2.1.0. Help page "Investigate best tuning parameters" (`select_best.Rd`). The page cites Breiman, L., Friedman, J. H., Olshen, R. A., and Stone, C. J. (1984), *Classification and Regression Trees*, Wadsworth, for the one-standard-error rule.

**Role.** The definitions that the closed-form selection oracle recomputes by hand. Not a statistical source: it fixes what the three rules mean in tune, which this package's `selection_rule()` hands to.

## Extracted values

- `select_best()` "finds the tuning parameter combination with the best performance values" (Description).
- `select_by_one_std_err()` "selects the most simple model that is within one standard error of the numerically optimal results" (Description). The method body takes the bound from the best candidate's own `std_err`: `bound <- best + summary_res$std_err[best_index]` for a minimized metric, keeping `mean <= .bound`.
- `select_by_pct_loss()` "selects the most simple model whose loss of performance is within some acceptable limit" (Description). `limit` is "The limit of loss of performance that is acceptable (in percent units)" (Arguments).
- The page's percent-loss example: "suppose the best model has an RMSE of 0.75 and a simpler model has an RMSE of 1. The percent loss would be `(1.00 - 0.75)/1.00 * 100`, or 25 percent" (Details). It divides by the simpler model's value.
- The method body divides by the best value instead: `abs((abs(mean) - abs(.best))/.best) * 100`. It keeps only candidates at or before the best one in the simplicity order (`slice(1:best_index)`), then those with `.loss < limit`. On the example above the body gives 33 percent where the page gives 25.
- For both non-default rules, `...` "is passed directly to `dplyr::arrange()`" so that the user can sort the models from simplest to most complex (Arguments). The first row after the filter is the pick.

## Traces to

- `tests/testthat/test-nested-tune-grid-oracles.R:360` — the test "each selection rule picks the candidate its definition names in the fold's inner metrics". It writes the three rules from the Description and the percent-loss example, not from the method bodies.
- `cairn/ORACLES.md`, the selection group — the closed-form row for that test.

## Open questions

- The page's percent-loss example and tune 2.1.0's method body give different losses. The page also does not say that only candidates at or before the best are kept. The test's fixture is seed 20, the `df1` and `df2` grid, and `limit = 5`. On it, both readings pick the same candidate in each of the three folds, measured 2026-10-31. On a fixture where the two readings differ, the test fails while tune does what its code says — observed 2026-10-31.
