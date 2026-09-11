
<!-- README.md is generated from README.Rmd. Please edit that file -->

# nestedtune <a href="https://nestedtune.tidymodels.org"><img src="man/figures/logo.png" align="right" height="138" alt="nestedtune website" /></a>

<!-- badges: start -->

[![R-CMD-check](https://github.com/tidymodels/nestedtune/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/tidymodels/nestedtune/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/tidymodels/nestedtune/graph/badge.svg)](https://app.codecov.io/gh/tidymodels/nestedtune)
<!-- badges: end -->

nestedtune runs nested cross-validation for tidymodels workflows. It
builds a nested resampling design. It tunes each outer fold on its own
inner resamples with tune or finetune, then scores the fold’s winner on
rows the tuning never saw. It keeps what every fold chose. The procedure
is every step above: resample, tune, select, fit. The mean of the outer
scores estimates how well that whole procedure performs on new data. The
model to deploy is fitted afterwards by the same procedure on all the
data. It is a separate object with no performance number of its own.

## Installation

``` r
# install.packages("pak")
pak::pak("tidymodels/nestedtune")
```

## Example

``` r
library(tidymodels)
library(nestedtune)

set.seed(1)
folds <- nested_resamples(
  mtcars,
  outside = vfold_cv(v = 5),
  inside = vfold_cv(v = 5)
)

wf <- workflow(
  mpg ~ .,
  rand_forest(mtry = tune(), min_n = tune()) |>
    set_engine("ranger") |>
    set_mode("regression")
)
grid <- expand.grid(mtry = c(2L, 5L, 8L), min_n = c(2L, 10L))

set.seed(2)
res <- nested_tune_grid(wf, folds, grid = grid)

# The estimate for the procedure. Report this.
collect_metrics(res)
#> # A tibble: 2 × 5
#>   .metric .estimator  mean     n std_err
#>   <chr>   <chr>      <dbl> <int>   <dbl>
#> 1 rmse    standard   2.46      5  0.445 
#> 2 rsq     standard   0.844     5  0.0267

# The model to deploy, fitted by the same procedure on all the data.
set.seed(3)
final <- nested_final_fit(wf, res)
predict(final, new_data = mtcars[1:3, ])
#> # A tibble: 3 × 1
#>   .pred
#>   <dbl>
#> 1  20.9
#> 2  20.9
#> 3  23.8
```

Learn more:

- [Nested
  cross-validation](https://nestedtune.tidymodels.org/articles/nested-cv.html),
  the path from a design to a write-up.
- [What the estimate
  means](https://nestedtune.tidymodels.org/articles/estimate.html),
  which quantity the nested number is and what it is not.
- [Choosing the inner
  tuner](https://nestedtune.tidymodels.org/articles/tuners.html), the
  Bayesian, racing and annealing searches and a set of workflows on one
  design.
- [Reading the
  results](https://nestedtune.tidymodels.org/articles/results.html),
  every column of the results object and every function that reads it.
- [Running the outer loop in
  parallel](https://nestedtune.tidymodels.org/articles/parallel.html),
  the same call on a pool of mirai daemons.
