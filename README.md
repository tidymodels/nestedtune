
<!-- README.md is generated from README.Rmd. Please edit that file -->

# nestedtune <a href="https://nestedtune.tidymodels.org"><img src="man/figures/logo.png" align="right" height="138" alt="nestedtune website" /></a>

<!-- badges: start -->

[![R-CMD-check](https://github.com/tidymodels/nestedtune/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/tidymodels/nestedtune/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/tidymodels/nestedtune/graph/badge.svg)](https://app.codecov.io/gh/tidymodels/nestedtune)
<!-- badges: end -->

You tune a model with cross-validation, keep the setting with the best
score, and then score that setting once on a held-out test set. That
test score is one number from one split of the data, and nothing in it
says whether the split is representative. nestedtune scores the whole
tune-and-fit procedure on several outer splits instead. The outer scores
give the mean across those splits and show how far the score moves from
one split to the next. Each outer fold tunes on its own inner resamples
with tune or finetune, so no outer score is the score that picked its
fold’s winner. The score that picks a winner tends to be optimistic,
because the winner was picked for scoring well. nestedtune keeps what
every fold chose.

The mean of the outer scores is the number to report for the model you
deploy. That model is the same procedure run once more on all the data,
so there is no second number to compute for it.

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

# The number to report for the model you deploy.
collect_metrics(res)
#> # A tibble: 2 × 5
#>   .metric .estimator  mean     n std_err
#>   <chr>   <chr>      <dbl> <int>   <dbl>
#> 1 rmse    standard   2.46      5  0.445 
#> 2 rsq     standard   0.844     5  0.0267

# The model to deploy, the same procedure run once more on all the data.
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
  which quantity the nested number is and how far to trust it.
- [Choosing the inner
  tuner](https://nestedtune.tidymodels.org/articles/tuners.html), the
  Bayesian search, the two racing searches, simulated annealing and a
  set of workflows on one design.
- [Reading the
  results](https://nestedtune.tidymodels.org/articles/results.html),
  every column of the results object and every function that reads it.
- [Running the outer loop in
  parallel](https://nestedtune.tidymodels.org/articles/parallel.html),
  the same call on a pool of mirai daemons.
