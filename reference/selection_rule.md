# Choose the rule each fold selects its parameters by

Builds the object the `select` argument of
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
and its siblings takes. It names one of tune's three selectors, or
desirability2's desirability selector, and carries what that selector
needs.

Every outer fold applies the rule to its own inner tuning run. tune's
three selectors rank on the first metric of that run. The result records
the rule, so
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
selects the same way on the full data.

## Usage

``` r
selection_rule(
  rule = c("best", "one_std_err", "pct_loss", "desirability"),
  ...,
  limit = NULL
)
```

## Arguments

- rule:

  The selector: `"best"` (the default), `"one_std_err"`, `"pct_loss"` or
  `"desirability"`. The section below says what each one picks.

- ...:

  For `"one_std_err"` and `"pct_loss"`, one or more bare expressions
  ordering the candidates from simplest to most complex, as tune's
  selectors take them. For `"desirability"`, one or more goals such as
  `maximize(rsq)` or `minimize(num_comp)`, as
  [`desirability2::select_best_desirability()`](https://desirability2.tidymodels.org/reference/show_best_desirability.html)
  takes them. At least one is required for those three rules, and
  `"best"` accepts none.

- limit:

  For `"pct_loss"` only, the acceptable loss against the best candidate,
  in percent, as a single non-negative number. Left `NULL` it takes
  tune's default of 2, and the other rules refuse it.

## Value

A list of class `selection_rule` with elements `rule`, `order` and
`limit`. `order` holds the expressions in `...`, empty for `"best"`.
`limit` is `NULL` outside `"pct_loss"`. Printing shows the three on one
line: the rule, then `by` and the orderings as written, then the limit
in parentheses. That same label follows `Selected by:` in the printed
[`summary.nested_results()`](https://nestedtune.tidymodels.org/reference/summary.nested_results.md),
[`summary.nested_results_set()`](https://nestedtune.tidymodels.org/reference/summary.nested_results_set.md),
[`print.nested_final_fit()`](https://nestedtune.tidymodels.org/reference/print.nested_final_fit.md)
and
[`summary.nested_final_fit()`](https://nestedtune.tidymodels.org/reference/summary.nested_final_fit.md)
when the rule is not `"best"`.

## The four rules

`"best"` takes the candidate with the best mean on the first metric, as
[`tune::select_best()`](https://tune.tidymodels.org/reference/show_best.html)
does. `"one_std_err"` takes the simplest candidate within one standard
error of the best, as
[`tune::select_by_one_std_err()`](https://tune.tidymodels.org/reference/show_best.html)
does. `"pct_loss"` takes the simplest candidate whose loss against the
best stays under `limit` percent, as
[`tune::select_by_pct_loss()`](https://tune.tidymodels.org/reference/show_best.html)
does. `"desirability"` takes the candidate with the highest overall
desirability over the goals in `...`, as
[`desirability2::select_best_desirability()`](https://desirability2.tidymodels.org/reference/show_best_desirability.html)
does.

## Writing a desirability goal

The `"desirability"` rule needs the desirability2 package, version 0.2.0
or later. Where it is not installed, the rule is refused when it is
built, when an orchestrator starts, and when
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
is given a result that recorded it.

Each goal is a call to one of desirability2's goal functions, such as
`maximize()`, `minimize()` or `target()`, written without the
`desirability2::` prefix, which desirability2 refuses. Its first
argument names a metric or a tuned parameter. Its other arguments must
be values, and a goal that names anything there is refused when the rule
is built. Write a variable's value into a goal with `!!`, as in
`maximize(rsq, low = !!lo)`. When the rule is built, desirability2
checks that each goal calls one of its goal functions with an unnamed
first argument and the other arguments named. It reads the values of
those arguments only when it scores a tuning run.
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
and
[`nested_tune_bayes()`](https://nestedtune.tidymodels.org/reference/nested_tune_bayes.md)
check at entry that every name in a goal's first argument is a metric in
`metrics` or a parameter `object` tunes. With `metrics` left `NULL`, the
metrics are the ones tune uses by default for the model's mode.
desirability2 sets each limit a goal leaves out from the tuning run it
scores, so each fold and the final fit scale those goals on their own
inner run. A limit written into the goal holds everywhere.
[`nested_tune_race_anova()`](https://nestedtune.tidymodels.org/reference/nested_tune_race.md),
[`nested_tune_race_win_loss()`](https://nestedtune.tidymodels.org/reference/nested_tune_race.md)
and
[`nested_tune_sim_anneal()`](https://nestedtune.tidymodels.org/reference/nested_tune_sim_anneal.md)
refuse the rule.
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
and
[`nested_tune_bayes()`](https://nestedtune.tidymodels.org/reference/nested_tune_bayes.md)
refuse it on a censored regression model.

## Writing an ordering

An ordering is a parameter name, wrapped in
[`dplyr::desc()`](https://dplyr.tidyverse.org/reference/desc.html) where
a larger value is the simpler model. Each must be a bare name or a call,
never a string or a number, which orders nothing. An ordering given a
name is refused. That way a misspelled `limit` is refused instead of
read as an ordering. Every name must be a parameter the workflow tunes,
which the orchestrators check when the run starts.

## See also

[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
[`extract_procedure()`](https://nestedtune.tidymodels.org/reference/extract_procedure.md),
which reaches the recorded rule as `$select`.

## Examples

``` r
selection_rule()
#> <selection_rule> best

# The simplest candidate within one standard error of the best, taking
# fewer components as simpler.
selection_rule("one_std_err", num_comp)
#> <selection_rule> one_std_err by num_comp

# A larger penalty is the simpler model, so its order is descending.
selection_rule("pct_loss", desc(penalty), limit = 5)
#> <selection_rule> pct_loss by desc(penalty) (limit = 5)

# A high R-squared and few components, weighed together.
if (rlang::is_installed("desirability2", version = "0.2.0")) {
  selection_rule("desirability", maximize(rsq), minimize(num_comp))
}
#> <selection_rule> desirability by maximize(rsq), minimize(num_comp)
```
