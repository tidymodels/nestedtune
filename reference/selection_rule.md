# Choose the rule each fold selects its candidate by

Builds the object the `select` argument of
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
[`nested_tune_bayes()`](https://nestedtune.tidymodels.org/reference/nested_tune_bayes.md),
[`nested_tune_race_anova()`](https://nestedtune.tidymodels.org/reference/nested_tune_race.md),
[`nested_tune_race_win_loss()`](https://nestedtune.tidymodels.org/reference/nested_tune_race.md)
and
[`nested_tune_sim_anneal()`](https://nestedtune.tidymodels.org/reference/nested_tune_sim_anneal.md)
takes. It names one of tune's three selectors and carries what that
selector needs. Every outer fold applies the rule to its own inner
tuning run, with `metric` the first metric of the run, and the results
object records the rule so
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
applies the same one to the full-data run.

## Usage

``` r
selection_rule(rule = c("best", "one_std_err", "pct_loss"), ..., limit = NULL)
```

## Arguments

- rule:

  The selector, one of `"best"`
  ([`tune::select_best()`](https://tune.tidymodels.org/reference/show_best.html),
  the default: the candidate with the best mean on the first metric),
  `"one_std_err"`
  ([`tune::select_by_one_std_err()`](https://tune.tidymodels.org/reference/show_best.html):
  the simplest candidate within one standard error of the best) or
  `"pct_loss"`
  ([`tune::select_by_pct_loss()`](https://tune.tidymodels.org/reference/show_best.html):
  the simplest candidate whose loss against the best is under `limit`
  percent).

- ...:

  For `"one_std_err"` and `"pct_loss"`, one or more bare expressions
  ordering the candidates from simplest to most complex, as tune's
  selectors take them: parameter names, wrapped in
  [`dplyr::desc()`](https://dplyr.tidyverse.org/reference/desc.html)
  where a larger value is simpler. At least one is required for those
  two rules, and none is accepted for `"best"`, which
  [`tune::select_best()`](https://tune.tidymodels.org/reference/show_best.html)
  refuses. Each must be a bare name or a call, never a string or a
  number, which would order nothing; and none may be named, so a
  misspelled `limit` is refused rather than taken as an ordering. Each
  name must be a parameter the workflow tunes; the orchestrators check
  that at entry.

- limit:

  For `"pct_loss"` only, the acceptable loss of performance against the
  best candidate, in percent, a single non-negative number; left `NULL`
  it takes tune's default of 2. Refused with the other two rules, which
  have no limit.

## Value

A list of class `selection_rule` with elements `rule`, the name given;
`order`, the expressions in `...` as a list, empty for `"best"`; and
`limit`, the limit for `"pct_loss"` and `NULL` otherwise. The
expressions are captured, not evaluated, and carry no environment, so
the object is the same wherever it is built. Printing shows the three on
one line.

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
