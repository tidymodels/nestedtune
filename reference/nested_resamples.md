# Build a nested resampling design

`nested_resamples()` builds a nested resampling design: one row per
outer fold, with that fold's inner resamples beside it. It gives the
same splits as
[`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html),
without a copy of the data for each outer fold.

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
  `vfold_cv(v = 5)`. It is evaluated on each outer fold's analysis set,
  so an `rset` is an error.

- ...:

  Not used, and must be empty.

## Value

An object of class `nested_resamples`, which also carries the classes
[`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html)
returns. It is the outer `rset` with an `inner_resamples` column, one
inner `rset` per outer split.

## Differences from rsample

[`rsample::analysis()`](https://rsample.tidymodels.org/reference/as.data.frame.rsplit.html)
and
[`rsample::assessment()`](https://rsample.tidymodels.org/reference/as.data.frame.rsplit.html)
return the same frames as on rsample's splits, and each inner split
keeps rsample's class and id. These designs are an error, whether
`nested_resamples()` or
[`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html)
built them:

- An outer
  [`rsample::bootstraps()`](https://rsample.tidymodels.org/reference/bootstraps.html)
  or
  [`rsample::group_bootstraps()`](https://rsample.tidymodels.org/reference/group_bootstraps.html).
  The same row can land in both the inner analysis and assessment sets.

- An outer
  [`rsample::loo_cv()`](https://rsample.tidymodels.org/reference/loo_cv.html).
  Each fold holds out one row, so R-squared cannot be computed and the
  averaged RMSE is the mean absolute error.

- An outer
  [`rsample::apparent()`](https://rsample.tidymodels.org/reference/apparent.html),
  whose one fold is scored on the rows it trained on.

- An outer
  [`rsample::permutations()`](https://rsample.tidymodels.org/reference/permutations.html),
  whose folds have no assessment set.

- An inner
  [`rsample::loo_cv()`](https://rsample.tidymodels.org/reference/loo_cv.html)
  or
  [`rsample::permutations()`](https://rsample.tidymodels.org/reference/permutations.html),
  which tune does not accept, or an inner
  [`rsample::apparent()`](https://rsample.tidymodels.org/reference/apparent.html),
  for which tune reports no results.

A design is known by the class of its splits as well as its own class,
so a design rebuilt with
[`rsample::manual_rset()`](https://rsample.tidymodels.org/reference/manual_rset.html)
is caught too. An inner
[`rsample::validation_set()`](https://rsample.tidymodels.org/reference/validation_set.html)
cannot be built, because it takes a split and not a data frame.

A single split is an error in either loop if its assessment set holds a
row of its analysis set. Inside an outer fold, two copies of one data
row count as the same row. The apparent split of a bootstrap with the id
"Apparent" is exempt, because tune leaves it out of its estimates. For
the same reason, an inner split with the id "Apparent" is an error
unless it is that split. So is an inner split with a missing `id`, or
two inner splits with the same values in every id column.

An outer split is an error if its `in_id` or `out_id` holds an `NA`, is
not numeric, or holds a value outside integer range. So is an empty
`out_id`. The logical `NA` `out_id`, which tells rsample to use
[`rsample::complement()`](https://rsample.tidymodels.org/reference/complement.html),
is accepted.

## Time-series designs

Below, the sliding designs are
[`rsample::sliding_window()`](https://rsample.tidymodels.org/reference/slide-resampling.html),
[`rsample::sliding_index()`](https://rsample.tidymodels.org/reference/slide-resampling.html)
and
[`rsample::sliding_period()`](https://rsample.tidymodels.org/reference/slide-resampling.html),
and the four other tuners are
[`nested_tune_bayes()`](https://nestedtune.tidymodels.org/reference/nested_tune_bayes.md),
the two racing functions and
[`nested_tune_sim_anneal()`](https://nestedtune.tidymodels.org/reference/nested_tune_sim_anneal.md).
Each pair of designs below is tested to give the same splits as
[`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html).
A final fit is tested on the results of the functions named with it.

- Outer
  [`rsample::rolling_origin()`](https://rsample.tidymodels.org/reference/rolling_origin.html)
  or a sliding design, with an inner
  [`rsample::rolling_origin()`](https://rsample.tidymodels.org/reference/rolling_origin.html).
  [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
  [`nested_fit_resamples()`](https://nestedtune.tidymodels.org/reference/nested_fit_resamples.md)
  and their final fits are tested on all four. The four other tuners,
  their final fits and
  [`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md)
  are tested on the rolling-origin outer design. The final fit of
  [`nested_tune_bayes()`](https://nestedtune.tidymodels.org/reference/nested_tune_bayes.md)
  is also tested on the sliding-window outer design.

- Outer
  [`rsample::rolling_origin()`](https://rsample.tidymodels.org/reference/rolling_origin.html)
  with an inner sliding design. All five tuners and their final fits are
  tested on all three.
  [`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md)
  is tested on all three with its default `fn`, and with each of the
  four other tuners on sliding-period alone.
  [`nested_fit_resamples()`](https://nestedtune.tidymodels.org/reference/nested_fit_resamples.md)
  accepts these designs. It checks the inner design but fits nothing on
  it.

- A sliding design in both loops, which gives nine pairs.
  [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  is tested on all nine. On the sliding-window pair, the four other
  tuners,
  [`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md)
  with its default `fn`, and the final fit of
  [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  are tested, and
  [`nested_fit_resamples()`](https://nestedtune.tidymodels.org/reference/nested_fit_resamples.md)
  accepts the design. On the other eight pairs, no function but
  `nested_resamples()` and
  [`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
  is tested.

Any other inner design is not tested. A `lag` above 0 in
[`rsample::rolling_origin()`](https://rsample.tidymodels.org/reference/rolling_origin.html)
is an error in either loop, because each assessment set then holds the
last `lag` rows of its analysis set. Build lagged predictors before
resampling.

## Memory

[`rsample::nested_cv()`](https://rsample.tidymodels.org/reference/nested_cv.html)
keeps a copy of each outer fold's analysis set. `nested_resamples()`
keeps only row indices that point back at `data`. The sizes below are
multiples of the source data. They were measured on
[`mlbench::LetterRecognition`](https://rdrr.io/pkg/mlbench/man/LetterRecognition.html)
(20000 x 17) with five inner folds, under rsample 1.3.2 and R 4.6.1, on
2026-07-25. `tests/testthat/test-nested-resamples-memory.R` checks how
fast each size grows with the number of outer folds.

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
