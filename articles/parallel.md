# Running the outer loop in parallel

Nested cross-validation fits many models, and the outer folds are
independent of one another.
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
and its siblings run those folds on [mirai](https://mirai.r-lib.org/)
daemons when a pool is connected, and serially otherwise. Nothing in the
call changes between the two. This page starts a pool of two daemons,
runs the getting-started guide’s loop on it, shows the result identical
to the same run made serially, and says when a pool pays. What the call
checks before it dispatches, what it sends to each daemon, and what
happens on an interrupt are under the parallel section of
[`?nested_tune_grid`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md).

``` r

library(tidymodels)
library(nestedtune)
```

## The design and the workflow

These are the guide’s, unchanged: five outer folds of `mtcars`, five
inner folds under each, a random forest with two parameters marked for
tuning, and a grid of six candidates.
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

Parallelism is switched on by connecting daemons and off by
disconnecting them. There is no argument on the loop functions for it.
[`mirai::daemons()`](https://mirai.r-lib.org/reference/daemons.html)
starts the pool, and
[`mirai::status()`](https://mirai.r-lib.org/reference/status.html)
reports how many daemons are connected. Two or more is the threshold,
the same one tune uses.

``` r

mirai::daemons(2)

mirai::status()$connections
#> [1] 2
```

Each daemon is a separate R process. It loads nestedtune and the
packages the workflow needs from an installed library, and the first
parallel call after starting a pool is the slow one, since it is what
makes each daemon load the tidymodels stack.

## The same call

With a pool connected the outer folds are dispatched to the daemons, and
each fold’s inner tuning runs serially on its daemon, because
parallelism inside a fold on top of parallelism across folds would
oversubscribe the cores.

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

Each outer fold’s seeds are drawn from the session state at entry, fixed
by the fold’s position in the design, before anything is dispatched, as
[`vignette("nested-cv")`](https://nestedtune.tidymodels.org/articles/nested-cv.md)
explains under Reproducibility. So the serial run under the same seed is
the same procedure on the same resamples.

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
scores, the selections and the tuning seeds returns TRUE for each, and
which run used daemons is not recoverable from either. That is what lets
a pool be a matter of the session rather than of the analysis: a script
gives the same answer on a laptop with no daemons and on a workstation
with many.

## A pool’s payoff

`mtcars` has 32 rows and the grid has 6 points, so each fold takes a
fraction of a second, and two daemons loading the tidymodels stack cost
more than the folds save. This page shows the parallel path working and
its result matching the serial one, not a speedup. The speedup arrives
where the folds are expensive: larger data, a bigger grid, a slower
engine, or preprocessing the loop has to redo in every fold. The fit
count in
[`vignette("nested-cv")`](https://nestedtune.tidymodels.org/articles/nested-cv.md)
says where the cost lives, and what is parallel here is the outer loop
over that cost.
