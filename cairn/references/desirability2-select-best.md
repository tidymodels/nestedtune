# desirability2-select-best — what desirability2's selection picks, as its help pages define it

**Provenance.** Ingested 2026-10-31 by M166 from desirability2 0.2.0's installed help pages `show_best_desirability.Rd` (`?desirability2::select_best_desirability`), `inline_desirability.Rd` (`?desirability2::d_max`) and `d_overall.Rd`. They were read with `tools::Rd2txt(tools::Rd_db("desirability2")[[...]])`. The bodies of `desirability2:::.comp_min` and `desirability2::d_overall` were printed in the same session.
Pagination: —.
Extraction: read directly 2026-10-31 from desirability2 0.2.0's installed help pages and function bodies — observed 2026-10-31.

**Citation.** Kuhn, M. desirability2: Desirability Functions for Multiparameter Optimization. R package version 0.2.0. Help pages "Investigate best tuning parameters" (`show_best_desirability.Rd`), "Desirability functions for in-line computations" (`inline_desirability.Rd`) and "Determine overall desirability" (`d_overall.Rd`). The pages cite Derringer, G., and Suich, R. (1980), Simultaneous Optimization of Several Response Variables, *Journal of Quality Technology*, 12, 214-219.

**Role.** The definitions that the closed-form desirability oracle recomputes by hand. Not a statistical source: it fixes what the `"desirability"` rule means in desirability2, which this package's `selection_rule()` hands to.

## Extracted values

- Each term maps a metric to [0, 1], "where 1.0 is most desirable and zero is unacceptable" (`show_best_desirability.Rd`, Details). The overall value is "the geometric mean of the individual desirabilities" (same paragraph).
- "If `low`, `high`, or `target` are not specified, the observed data are used to estimate their values" (same page, Details). The page's example sets `low` and `high` to the observed minimum and maximum of the column.
- Maximization: d = 1 above `high`, 0 below `low`, and ((data - low) / (high - low))^scale between them (`inline_desirability.Rd`, Equations). `scale` defaults to 1.
- Minimization: d = 0 above `high` and 1 below `low` (same page). Between them the page prints the fraction as "data = low" over "low - high", a typo. The body of `.comp_min` computes ((x - high) / (low - high))^scale. That is the one reading that gives 1 at `low` and 0 at `high`.
- `d_overall()` takes the geometric mean by default (`d_overall.Rd`, Usage, `geometric = TRUE`). If a term is 0, its internal `geomean()` returns 0. Otherwise it returns `exp(mean(log(x)))`, which can differ from `prod(x)^(1/k)` in the last bits. Only an exact tie at the top exposes that difference.
- `select_best_desirability()` "returns a single row" (`show_best_desirability.Rd`, Value). The page also says that the ranking can hold "more than one model configuration that has identical overall desirability" (Details). The pages do not say which tied row comes first.

## Traces to

- `tests/testthat/test-nested-tune-grid-oracles.R:493`: the test "the desirability rule picks the candidate its definition names in the fold's inner metrics". It writes the maximization and minimization terms with the observed range of each fold's candidates and takes their geometric mean. It asserts that one candidate holds the top value, so the pick does not rest on the unstated tie order.
- `cairn/ORACLES.md`, the selection group: the closed-form row for that test.

## Open questions

- None for the test's terms. `target()`, `constrain()` and `categories()` are not written out, since the test's rule uses none of them.
