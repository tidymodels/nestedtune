# Choose how each fold selects its candidate

`selection_rule()` builds the `select` argument of
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
and the other nested tuning functions. It names one of tune's three
selectors or desirability2's, with what that selector needs.

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
  `"desirability"`.

- ...:

  For `"one_std_err"` and `"pct_loss"`, the tuned parameters that order
  the candidates from simplest to most complex, as bare names. Wrap a
  name in
  [`dplyr::desc()`](https://dplyr.tidyverse.org/reference/desc.html)
  when a larger value is simpler. For `"desirability"`, one or more
  goals such as `maximize(rsq)` or `minimize(num_comp)`. Every rule but
  `"best"` needs at least one, and `"best"` takes none.

- limit:

  For `"pct_loss"` only, the acceptable loss against the best candidate,
  as a single non-negative number in percent. `NULL` takes tune's
  default of 2. The other rules take no `limit`.

## Value

A `selection_rule`: a list with the elements `rule`, `order` and
`limit`.

## Details

Each outer fold applies the rule to its own inner tuning run, and
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
applies it to its run on all the data. tune's three selectors rank on
the first metric of the `metrics` argument of the nested function, so
put the metric to rank on first.

- `"best"` takes the candidate with the best mean, as
  [`tune::select_best()`](https://tune.tidymodels.org/reference/show_best.html)
  does.

- `"one_std_err"` takes the simplest candidate within one standard error
  of the best, as
  [`tune::select_by_one_std_err()`](https://tune.tidymodels.org/reference/show_best.html)
  does.

- `"pct_loss"` takes the simplest candidate whose loss against the best
  stays under `limit` percent, as
  [`tune::select_by_pct_loss()`](https://tune.tidymodels.org/reference/show_best.html)
  does.

- `"desirability"` takes the candidate with the highest overall
  desirability, as
  [`desirability2::select_best_desirability()`](https://desirability2.tidymodels.org/reference/show_best_desirability.html)
  does.

## Desirability goals

The `"desirability"` rule needs desirability2 0.2.0 or later. Write each
goal without the `desirability2::` prefix, and name a metric or a tuned
parameter first, as in `maximize(rsq)`. Put a variable's value in with
`!!`, as in `maximize(rsq, low = !!lo)`.

A `low` or `high` bound that a goal leaves out is set from the tuning
run being scored, so each fold and the final fit scale the goal on their
own run. The racing and annealing functions do not take this rule, and
neither does a censored regression model.

## See also

[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
[`extract_procedure()`](https://nestedtune.tidymodels.org/reference/extract_procedure.md)
to read the rule a run used

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
