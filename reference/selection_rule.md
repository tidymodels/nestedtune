# Choose the rule each fold selects its parameters by

Builds the object the `select` argument of
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
and its siblings takes. It names one of tune's three selectors and
carries what that selector needs.

Every outer fold applies the rule to its own inner tuning run, on the
first metric of that run. The result records the rule, so
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
selects the same way on the full data.

## Usage

``` r
selection_rule(rule = c("best", "one_std_err", "pct_loss"), ..., limit = NULL)
```

## Arguments

- rule:

  The selector: `"best"` (the default), `"one_std_err"` or `"pct_loss"`.
  The section below says what each one picks.

- ...:

  For `"one_std_err"` and `"pct_loss"`, one or more bare expressions
  ordering the candidates from simplest to most complex, as tune's
  selectors take them. At least one is required for those rules, and
  `"best"` accepts none.

- limit:

  For `"pct_loss"` only, the acceptable loss against the best candidate,
  in percent, as a single non-negative number. Left `NULL` it takes
  tune's default of 2, and the other rules refuse it.

## Value

A list of class `selection_rule` with elements `rule`, `order` and
`limit`. `order` holds the expressions in `...`, empty for `"best"`.
`limit` is `NULL` outside `"pct_loss"`. Printing shows the three on one
line.

## The three rules

`"best"` takes the candidate with the best mean on the first metric, as
[`tune::select_best()`](https://tune.tidymodels.org/reference/show_best.html)
does. `"one_std_err"` takes the simplest candidate within one standard
error of the best, as
[`tune::select_by_one_std_err()`](https://tune.tidymodels.org/reference/show_best.html)
does. `"pct_loss"` takes the simplest candidate whose loss against the
best stays under `limit` percent, as
[`tune::select_by_pct_loss()`](https://tune.tidymodels.org/reference/show_best.html)
does.

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
```
