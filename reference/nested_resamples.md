# Build a nested resampling design without copying the data per outer fold

`nested_resamples()` builds the nested resampling design
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
and its siblings take: one row per outer fold, with that fold's inner
resamples beside it. It is
[`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html)'s
structure, and for the same seed and the same specifications it selects
the same rows.

What differs is what the splits point at. rsample's inner splits index a
fresh copy of each outer fold's analysis set. These index the one data
frame you already have, so the design's size barely grows with the fold
count.

## Usage

``` r
nested_resamples(data, outside, inside, ...)
```

## Arguments

- data:

  A data frame.

- outside:

  The outer resampling, as an unevaluated call such as `vfold_cv(v = 5)`
  or as an `rset` already built on `data`.

- inside:

  The inner resampling, as an unevaluated call such as
  `vfold_cv(v = 5)`. It is evaluated once per outer fold, so an existing
  object is refused.

- ...:

  Not used. It must be empty. The three arguments above are all
  required, so a mistyped fourth is an error here.

## Value

An object of class `nested_resamples`, which also carries the classes
[`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html)
returns, so methods written against those keep working. It is the outer
`rset` with an `inner_resamples` list column added, one inner `rset` per
outer split.

## Differences from rsample

Code written for an rsample split keeps working.
[`rsample::analysis()`](https://rsample.tidymodels.org/reference/as.data.frame.rsplit.html)
and
[`rsample::assessment()`](https://rsample.tidymodels.org/reference/as.data.frame.rsplit.html)
return identical frames, attributes included. Each inner split keeps the
class and the resample id rsample gives it, so
[`labels()`](https://rdrr.io/r/base/labels.html) and
[`rsample::add_resample_id()`](https://rsample.tidymodels.org/reference/add_resample_id.html)
behave the same.

One behavior differs on purpose: an outer bootstrap is refused rather
than warned about. The same row can otherwise land in both the inner
analysis and the inner assessment set, which makes the estimate invalid.

## Memory

What you save is one copy of the analysis set per outer fold.
[`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html)
evaluates the inner specification against `as.data.frame(split)`, so
every outer fold holds its own copy of that fold's analysis set.
`nested_resamples()` runs the same specification against the same frame,
keeps only the row indices it produces, and points them back at `data`.
The index vectors remain, as they do in rsample, but the copies are
gone.

Sizes below are multiples of the source data, measured on
[`mlbench::LetterRecognition`](https://rdrr.io/pkg/mlbench/man/LetterRecognition.html)
(20000 x 17) with five inner folds under rsample 1.3.2 and R 4.6.1. They
were recorded on 2026-07-25 beside the check
`tests/testthat/test-nested-resamples-memory.R` makes of them:

|  |  |  |
|----|----|----|
| outer folds | [`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html) | `nested_resamples()` |
| 2 | 2.2x | 1.2x |
| 5 | 5.6x | 1.7x |
| 10 | 11.4x | 2.6x |
| 50 | 57.5x | 10.0x |

## See also

[`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html),
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
which takes the design and runs the outer loop

## Examples

``` r
data(mtcars)

set.seed(1)
design <- nested_resamples(
  data = mtcars,
  outside = rsample::vfold_cv(v = 3),
  inside = rsample::vfold_cv(v = 3)
)
design
#> # Nested resampling:
#> #  outer: 3-fold cross-validation
#> #  inner: 3-fold cross-validation
#> # A tibble: 3 × 3
#>   splits          id    inner_resamples
#>   <list>          <chr> <list>         
#> 1 <split [21/11]> Fold1 <vfold [3 × 2]>
#> 2 <split [21/11]> Fold2 <vfold [3 × 2]>
#> 3 <split [22/10]> Fold3 <vfold [3 × 2]>

# Each element of inner_resamples is an ordinary rset.
design$inner_resamples[[1]]
#> #  3-fold cross-validation 
#> # A tibble: 3 × 2
#>   splits         id   
#>   <list>         <chr>
#> 1 <split [14/7]> Fold1
#> 2 <split [14/7]> Fold2
#> 3 <split [14/7]> Fold3
```
