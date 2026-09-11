# Running the outer loop in parallel

A nested run fits many models, and you can make it finish sooner. The
outer folds do not depend on one another, so they can run at the same
time.
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
and its siblings run them on [mirai](https://mirai.r-lib.org/) daemons,
separate R processes, when a pool of daemons is connected. Without a
pool, the folds run one after another. Nothing in the call changes
between the two.

This page starts a pool of two daemons and runs the getting-started
guide’s loop on it. It then shows that the result is identical to the
same run made serially. Last, it says when a pool pays. The parallel
section of
[`?nested_tune_grid`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
says what the call checks before it dispatches, what it sends to each
daemon, and what happens on an interrupt.

``` r

library(tidymodels)
library(nestedtune)
```

## The design and the workflow

These are the guide’s, unchanged. There are five outer folds of
`mtcars`, five inner folds under each, and a random forest with two
parameters marked for tuning. The grid holds six candidates, the
settings to try.
[`vignette("nested-cv")`](https://nestedtune.tidymodels.org/articles/nested-cv.md)
walks through each of them.

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

## The pool

You switch parallelism on by connecting daemons and off by disconnecting
them. There is no argument on the loop functions for it.
[`mirai::daemons()`](https://mirai.r-lib.org/reference/daemons.html)
starts the pool, and
[`mirai::status()`](https://mirai.r-lib.org/reference/status.html)
reports how many daemons are connected. With two or more connected, the
folds go out to the daemons. With fewer, they run in the session, the
same rule tune uses.

``` r

mirai::daemons(2)

mirai::status()$connections
#> [1] 2
```

Each daemon is a separate R process. It loads nestedtune and the
packages the workflow needs from an installed library. So the first
parallel call after starting a pool is the slow one, because it makes
each daemon load the tidymodels stack.

## The same call

With a pool connected, the outer folds are sent to the daemons. Each
fold’s inner tuning runs serially on its daemon. Parallelism inside a
fold on top of parallelism across folds oversubscribes the cores.

``` r

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

The result carries no mark of how it was computed. `mirai::daemons(0)`
disconnects the daemons, and after it the same call runs serially.

``` r

mirai::daemons(0)

mirai::status()$connections
#> [1] 0
```

## The same result

Each outer fold’s seeds are drawn from the session state at entry,
before anything is dispatched. A fold’s seeds depend on its position in
the design, as
[`vignette("nested-cv")`](https://nestedtune.tidymodels.org/articles/nested-cv.md)
explains under Reproducibility. So a serial run under the same seed
repeats the parallel run: the same procedure, the same tune-and-fit
steps, on the same resamples.

``` r

set.seed(2)

ser_res <- nested_tune_grid(wf, folds, grid = grid)
```

``` r

same <- c(
  metrics = identical(par_res$.metrics, ser_res$.metrics),
  selected = identical(par_res$.selected, ser_res$.selected),
  tuning_seed = identical(par_res$.tuning_seed, ser_res$.tuning_seed)
)

same
#>     metrics    selected tuning_seed 
#>        TRUE        TRUE        TRUE
```

[`identical()`](https://rdrr.io/r/base/identical.html) on the outer
scores, the selections and the tuning seeds returns TRUE for each.
Neither result records whether daemons were used, so a script gives the
same answer on a laptop with no daemons and on a workstation with many.

## A pool’s payoff

`mtcars` has 32 rows and the grid has 6 points, so each fold takes a
fraction of a second. Two daemons loading the tidymodels stack cost more
than the folds save. This page shows the parallel path working and its
result matching the serial one, not a speedup. The speedup arrives where
the folds are expensive: larger data, a bigger grid, a slower engine, or
preprocessing the loop has to redo in every fold. The fit count in
[`vignette("nested-cv")`](https://nestedtune.tidymodels.org/articles/nested-cv.md)
says where the cost lives. A pool splits that cost across the outer
folds.
