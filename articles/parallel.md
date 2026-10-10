# Running the outer loop in parallel

The outer folds of a nested run do not depend on one another, so they
can run at the same time. The nested functions send them to
[mirai](https://mirai.r-lib.org/) daemons (separate R processes) when
two or more are connected, and run them one after another otherwise.

``` r

library(tidymodels)
library(nestedtune)
```

## The setup

We reuse the design, the random forest and the grid from
[`vignette("nested-cv")`](https://nestedtune.tidymodels.org/articles/nested-cv.md).

``` r

set.seed(1)

folds <- nested_resamples(
  mtcars,
  outside = vfold_cv(v = 5),
  inside = vfold_cv(v = 5)
)

rf <- rand_forest(mtry = tune(), min_n = tune(), trees = 500) |>
  set_engine("ranger") |>
  set_mode("regression")

wf <- workflow(mpg ~ ., rf)

grid <- expand.grid(mtry = c(2L, 5L, 8L), min_n = c(2L, 10L))
```

## Running in parallel

We start a pool of two daemons with
[`mirai::daemons()`](https://mirai.r-lib.org/reference/daemons.html).
The call to
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
does not change.

``` r

mirai::daemons(2)

set.seed(2)
par_res <- nested_tune_grid(wf, folds, grid = grid)

par_res
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

Each fold’s inner tuning runs serially on its daemon, so the two loops
do not compete for cores. The first call after starting a pool is
slower, because each daemon loads the packages the workflow needs.

`mirai::daemons(0)` stops the pool, and the same call then runs
serially. The parallel section of
[`?nested_tune_grid`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
says what the daemons load, how to use them under
`devtools::load_all()`, and what an interrupt does.

``` r

mirai::daemons(0)
```

## The same result

Each fold takes its seeds by its position in the design, so one seed
gives one result serially and in parallel, as
[`?nested_tune_grid`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
explains.

``` r

set.seed(2)
ser_res <- nested_tune_grid(wf, folds, grid = grid)

c(
  metrics = identical(par_res$.metrics, ser_res$.metrics),
  selected = identical(par_res$.selected, ser_res$.selected)
)
#>  metrics selected 
#>     TRUE     TRUE
```

## When a pool pays

On `mtcars` each fold takes under a second, so two daemons save little
time. A pool pays when the folds are expensive: more data, a bigger
grid, a slower engine or a costly recipe.
