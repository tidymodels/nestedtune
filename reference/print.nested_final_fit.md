# Print a final fit

Shows what the full-data search was, which parameters it selected, and
which number to report for this model. It also names the accessors that
reach what selection saw.

The number to report is the nested estimate
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
returns from the results object the fit was built from. For a fit built
from a workflow set, it is that workflow's rows of
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
on the set. The print says so. That estimate describes the procedure
that produced this model. The stored tuning run has metrics, but
selection consumed them. See
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
for why those metrics are not the number to report and the nested
estimate is.

## Usage

``` r
# S3 method for class 'nested_final_fit'
print(x, ...)
```

## Arguments

- x:

  A `nested_final_fit` object from
  [`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md).

- ...:

  Not used. It must be empty. Passing an argument here raises an error
  instead of leaving it silently ignored.

## Value

`x`, invisibly.

## The procedure line

The line under the heading tells you what ran: the procedure, which is
the tuner and its counts. A grid search or a race is named with the
number of candidates, parameter settings, it scored. An iterating search
is named with the initial candidates scored and requested and the
iterations completed and requested. It can score fewer initial
candidates than `initial` names and can stop short of `iter`.

Where nothing was tuned the line reads "no tuning", the selection line
reads "nothing to select", and the note says that
[`extract_tune_results()`](https://nestedtune.tidymodels.org/reference/extract_tune_results.md)
and
[`extract_scored_candidates()`](https://nestedtune.tidymodels.org/reference/extract_scored_candidates.md)
refuse the object.

## The selection rule

When the selection was made by a rule other than the default, a line
follows the `Selected:` line. It reads `Selected by:` and then the
rule's name, orderings and limit, in the words the print of
[`selection_rule()`](https://nestedtune.tidymodels.org/reference/selection_rule.md)
uses after its class tag, for example
`Selected by: pct_loss by num_comp (limit = 5)`. The line is absent
under the default rule and on a fit that tuned nothing. The summary's
`select` component holds the rule as a value.

Under the `"best"`, `"one_std_err"` and `"pct_loss"` rules, one more
line names the metric that chose the candidate. An example is
`Selecting metric: rmse`. Under the default rule it follows the
`Selected:` line, and otherwise the `Selected by:` line. It is absent
under the `"desirability"` rule, which chooses by its goals, on a fit
that tuned nothing, and on a fit whose record holds no `first_metric`.

## See also

[`summary.nested_final_fit()`](https://nestedtune.tidymodels.org/reference/summary.nested_final_fit.md),
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md),
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
[`extract_tune_results()`](https://nestedtune.tidymodels.org/reference/extract_tune_results.md),
[`extract_scored_candidates()`](https://nestedtune.tidymodels.org/reference/extract_scored_candidates.md)

## Examples

``` r
data(mtcars)

rec <- recipes::recipe(mpg ~ ., data = mtcars) |>
  recipes::step_pca(recipes::all_predictors(), num_comp = tune::tune())
wf <- workflows::workflow(rec, parsnip::linear_reg())

set.seed(1)
folds <- nested_resamples(
  mtcars,
  outside = rsample::vfold_cv(v = 2),
  inside = rsample::vfold_cv(v = 2)
)
set.seed(2)
res <- nested_tune_grid(wf, folds, grid = data.frame(num_comp = 1:2))
set.seed(3)
final <- nested_final_fit(wf, res)
final
#> 
#> ── Nested cross-validation final fit ──────────────────────────────────
#> Procedure: grid search, 2 candidates scored
#> Selected: num_comp = 1
#> Selecting metric: rmse
#> 
#> ℹ Report the nested estimate from `collect_metrics()` on the results
#>   object this fit was built from. For a fit built from a workflow set,
#>   that is this workflow's rows of `collect_metrics()` on the set. That
#>   holds for a workflow chosen before seeing the set's estimates. It
#>   describes the procedure that produced this model, and it is the
#>   number to report for this model.
#> ℹ Compare the parameters above with `.selected` from that run. Outer
#>   folds choosing differently is selection instability, and it is
#>   information about the procedure rather than noise.
#> ℹ `extract_tune_results()` returns the tuning run selection came from,
#>   and `extract_scored_candidates()` the candidates it scored. Any
#>   metric reachable through the first is a selection-time quantity,
#>   optimistically biased as a claim about this model.
```
