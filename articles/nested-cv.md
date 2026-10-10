# Nested cross-validation

Nested resampling estimates how well a tuning procedure (tune, select,
fit) performs on new data. It runs two loops. The inner loop tunes the
model, and the outer loop scores the tuned model on rows that the tuning
never saw.

The best score from ordinary tuning is optimistic. The same resamples
that score the candidates (the settings tried) also pick the winner, so
part of its score is luck.
[`vignette("estimate")`](https://nestedtune.tidymodels.org/articles/estimate.md)
explains this in more detail.

``` r

library(tidymodels)
library(nestedtune)
```

## The design

We start with the design.
[`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md)
builds an outer resampling and attaches an inner resampling to each
outer fold. `mtcars` has 32 rows, too few for real nested resampling,
but it keeps this example fast.

``` r

set.seed(1)

folds <- nested_resamples(
  mtcars,
  outside = vfold_cv(v = 5),
  inside = vfold_cv(v = 5)
)

folds
#> # Nested resampling:
#> #  outer: 5-fold cross-validation
#> #  inner: 5-fold cross-validation
#> # A tibble: 5 × 3
#>   splits         id    inner_resamples
#>   <list>         <chr> <list>         
#> 1 <split [25/7]> Fold1 <vfold [5 × 2]>
#> 2 <split [25/7]> Fold2 <vfold [5 × 2]>
#> 3 <split [26/6]> Fold3 <vfold [5 × 2]>
#> 4 <split [26/6]> Fold4 <vfold [5 × 2]>
#> 5 <split [26/6]> Fold5 <vfold [5 × 2]>
```

Each row is one outer fold. `splits` holds the outer split.
`inner_resamples` holds an ordinary rset built from that fold’s analysis
set alone, so the tuning in that fold never sees the fold’s held-out
rows.

``` r

folds$inner_resamples[[1]]
#> #  5-fold cross-validation 
#> # A tibble: 5 × 2
#>   splits         id   
#>   <list>         <chr>
#> 1 <split [20/5]> Fold1
#> 2 <split [20/5]> Fold2
#> 3 <split [20/5]> Fold3
#> 4 <split [20/5]> Fold4
#> 5 <split [20/5]> Fold5
```

## The model and the grid

We tune two parameters of a random forest over a grid of candidates, the
settings to try.

``` r

rf <- rand_forest(mtry = tune(), min_n = tune(), trees = 500) |>
  set_engine("ranger") |>
  set_mode("regression")

wf <- workflow(mpg ~ ., rf)

grid <- expand.grid(mtry = c(2L, 5L, 8L), min_n = c(2L, 10L))
grid
#>   mtry min_n
#> 1    2     2
#> 2    5     2
#> 3    8     2
#> 4    2    10
#> 5    5    10
#> 6    8    10
```

The grid has 6 candidates. Each of the 5 outer folds scores all of them
on 5 inner resamples. That is 150 fits for tuning, plus one fit per
outer fold for scoring.

## Running the loop

[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
runs the outer loop. For each outer fold, it calls
[`tune::tune_grid()`](https://tune.tidymodels.org/reference/tune_grid.html)
on the fold’s inner resamples and picks the best candidate. It then fits
that candidate on the fold’s analysis set and scores it on the
assessment set.

We pass no metric set, so the run uses tune’s default for regression and
selects by `rmse`. To select another way, pass a
[`selection_rule()`](https://nestedtune.tidymodels.org/reference/selection_rule.md)
as `select`. We call [`set.seed()`](https://rdrr.io/r/base/Random.html)
first, as elsewhere in tidymodels. The same seed gives the same result
whether the folds run serially or in parallel.

``` r

set.seed(2)

res <- nested_tune_grid(wf, folds, grid = grid)

res
#> 
#> ── Nested cross-validation results ────────────────────────────────────
#> Outer resamples: 5-fold cross-validation
#> # A tibble: 5 × 9
#>   splits         id    .metrics .selected .inner_metrics    .notes  
#>   <list>         <chr> <list>   <list>    <list>            <list>  
#> 1 <split [25/7]> Fold1 <tibble> <tibble>  <tibble [12 × 8]> <tibble>
#> 2 <split [25/7]> Fold2 <tibble> <tibble>  <tibble [12 × 8]> <tibble>
#> 3 <split [26/6]> Fold3 <tibble> <tibble>  <tibble [12 × 8]> <tibble>
#> 4 <split [26/6]> Fold4 <tibble> <tibble>  <tibble [12 × 8]> <tibble>
#> 5 <split [26/6]> Fold5 <tibble> <tibble>  <tibble [12 × 8]> <tibble>
#> # ℹ 3 more variables: .completed <lgl>, .tuning_seed <int>,
#> #   .outer_fit_seed <int>
#> ℹ Use `summary()` for what the run means: which folds failed, what
#>   each one selected, and the estimate across them.
```

[`summary()`](https://rdrr.io/r/base/summary.html) describes the run in
words.

``` r

summary(res)
#> 
#> ── Nested cross-validation results ────────────────────────────────────
#> Outer resamples: 5-fold cross-validation
#> Outer folds: 5 requested, 5 completed
#> 
#> ── Selected parameters ──
#> 
#> Selecting metric: rmse
#> ! mtry: 8, 8, 5, 8, 5 (folds disagree)
#> ✔ min_n: 2 (all 5 completed folds agree)
#> 
#> ── Estimate (5 of 5 outer folds) ──
#> 
#> rmse (standard): 2.49
#> rsq (standard): 0.842
#> 
#> ℹ A nested estimate describes the tune-and-fit procedure. For a
#>   procedure chosen before seeing this estimate, it is the number to
#>   report for the model `nested_final_fit()` builds.
```

## The number to report

``` r

est <- collect_metrics(res)
est
#> # A tibble: 2 × 5
#>   .metric .estimator  mean     n std_err
#>   <chr>   <chr>      <dbl> <int>   <dbl>
#> 1 rmse    standard   2.49      5  0.447 
#> 2 rsq     standard   0.842     5  0.0293

rmse_row <- filter(est, .metric == "rmse")
```

The RMSE of 2.49 is the mean of 5 outer scores. Each one was measured on
rows that the tuning never saw. `std_err` is the standard error of that
mean.

This estimate describes the whole procedure (tune, select, fit) and not
one fitted model. It is still the number to report for the model that
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
fits below, because that model comes from the same procedure.

## Each fold’s selection

Each outer fold tunes on its own, so the folds can choose different
settings.
[`collect_selections()`](https://nestedtune.tidymodels.org/reference/collect_selections.md)
lists what each fold chose.

``` r

selected <- collect_selections(res)

selected
#> # A tibble: 5 × 4
#>   id     mtry min_n .config        
#>   <chr> <int> <int> <chr>          
#> 1 Fold1     8     2 pre0_mod5_post0
#> 2 Fold2     8     2 pre0_mod5_post0
#> 3 Fold3     5     2 pre0_mod3_post0
#> 4 Fold4     8     2 pre0_mod5_post0
#> 5 Fold5     5     2 pre0_mod3_post0
```

``` r

n_mtry <- n_distinct(selected$mtry)
n_min_n <- n_distinct(selected$min_n)
```

Across 5 outer folds, `mtry` took 2 distinct values and `min_n` took 1.
When the folds disagree on a parameter, the data does not pin its value
down, so read little into the value chosen. The nested estimate still
holds, because it scores the whole procedure.

[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
draws the selections, one point per outer fold. A flat row means that
the folds agreed.

``` r

autoplot(res)
```

![One panel per tuned parameter, with one point per outer fold at the
value that fold's inner tuning
selected.](nested-cv_files/figure-html/autoplot-parameters-1.png)

The per-fold scores show how much the folds differ.

``` r

per_fold <- collect_metrics(res, summarize = FALSE)
per_fold
#> # A tibble: 10 × 4
#>    id    .metric .estimator .estimate
#>    <chr> <chr>   <chr>          <dbl>
#>  1 Fold1 rmse    standard       1.23 
#>  2 Fold1 rsq     standard       0.911
#>  3 Fold2 rmse    standard       3.22 
#>  4 Fold2 rsq     standard       0.819
#>  5 Fold3 rmse    standard       2.48 
#>  6 Fold3 rsq     standard       0.805
#>  7 Fold4 rmse    standard       1.83 
#>  8 Fold4 rsq     standard       0.766
#>  9 Fold5 rmse    standard       3.69 
#> 10 Fold5 rsq     standard       0.911

fold_rmse <- per_fold |>
  filter(.metric == "rmse") |>
  pull(.estimate)

c(sd = sd(fold_rmse), std_err = sd(fold_rmse) / sqrt(length(fold_rmse)))
#>        sd   std_err 
#> 1.0002719 0.4473352
```

The first number is the spread of the folds. The second is the `std_err`
that
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
reports, which is the precision of their mean. Quoting the second as the
spread understates how much the folds disagree.

The other
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
view draws the per-fold scores, with a dashed line at the nested
estimate.

``` r

autoplot(res, type = "performance")
```

![One panel per metric, with one point per outer fold's score and a
dashed line at the mean across
folds.](nested-cv_files/figure-html/autoplot-performance-1.png)

## The model to deploy

Now we build the model to deploy.
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
runs the same procedure once more on all the data. It takes the inner
resampling, grid, metrics and selection rule from `res`, so the model
and the estimate come from one search.

``` r

set.seed(3)

final <- nested_final_fit(wf, res)

final
#> 
#> ── Nested cross-validation final fit ──────────────────────────────────
#> Procedure: grid search, 6 candidates scored
#> Selected: mtry = 2, min_n = 2
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

The outer folds play no part here. The object predicts directly, and
[`extract_workflow()`](https://hardhat.tidymodels.org/reference/hardhat-extract.html)
returns the fitted workflow to save.

``` r

predict(final, new_data = mtcars[1:3, ])
#> # A tibble: 3 × 1
#>   .pred
#>   <dbl>
#> 1  20.9
#> 2  20.9
#> 3  24.0
```

[`extract_tune_results()`](https://nestedtune.tidymodels.org/reference/extract_tune_results.md)
returns the tuning run behind this model, and `show_best()` gives its
best inner score. That is the number that `tune_grid()` alone reports.

``` r

best_inner <- extract_tune_results(final) |>
  show_best(metric = "rmse", n = 1)

tibble(
  quantity = c("nested estimate (report this)", "best inner score"),
  rmse = c(rmse_row$mean, best_inner$mean)
)
#> # A tibble: 2 × 2
#>   quantity                       rmse
#>   <chr>                         <dbl>
#> 1 nested estimate (report this)  2.49
#> 2 best inner score               2.58
```

The best inner score is not an estimate of performance on new data,
because the same resamples chose the model. It is optimistic on average.
On one small dataset, it can land on either side of the nested estimate.

## The write-up

Here is a short report of this run.

> Hyperparameters (`mtry`, `min_n`) were tuned over a 6-point grid by
> 5-fold cross-validation, nested inside a 5-fold outer cross-validation
> (n = 32). The outer folds give an estimated RMSE of 2.49 (SE 0.45) for
> the tuning procedure. The folds selected 2 distinct values of `mtry`
> and 1 of `min_n`. The deployed model applies the same procedure to the
> full dataset, which selected mtry = 2 and min_n = 2. That RMSE is the
> number reported for the deployed model, because the model comes from
> the same procedure.
