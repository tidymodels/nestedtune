# Reading the results

You have a results object and want to know what is in it. Every tuning
function in this package returns the same kind of object, a
`nested_results`. The getting-started guide,
[`vignette("nested-cv")`](https://nestedtune.tidymodels.org/articles/nested-cv.md),
prints it, summarizes it, and reads the estimate, the selections and
both plots off it. This page reads the whole object. It goes through the
columns one at a time, then the readers, the functions such as
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
that turn the columns into tables. It then shows what a run looks like
when one outer fold fails, and which dplyr verbs keep the class and
which shed it.

``` r

library(tidymodels)
library(nestedtune)
```

## The run

The design, the workflow and the grid are the guide’s, unchanged. There
are five outer folds of `mtcars`, five inner folds under each, and a
random forest with two parameters marked for tuning. The grid’s six rows
are the candidates, the settings each fold’s inner tuning tries. One
thing is added. A `control_grid()` with `save_pred = TRUE` asks each
fold’s outer fit to keep its predictions, so this page can show that
column and the function that stacks it.

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

``` r

set.seed(2)

res <- nested_tune_grid(
  wf,
  folds,
  grid = grid,
  control = control_grid(save_pred = TRUE)
)

res
#> 
#> ── Nested cross-validation results ────────────────────────────────────
#> Outer resamples: 5-fold cross-validation
#> # A tibble: 5 × 10
#>   splits         id    .metrics .selected .inner_metrics    .notes  
#>   <list>         <chr> <list>   <list>    <list>            <list>  
#> 1 <split [25/7]> Fold1 <tibble> <tibble>  <tibble [12 × 8]> <tibble>
#> 2 <split [25/7]> Fold2 <tibble> <tibble>  <tibble [12 × 8]> <tibble>
#> 3 <split [26/6]> Fold3 <tibble> <tibble>  <tibble [12 × 8]> <tibble>
#> 4 <split [26/6]> Fold4 <tibble> <tibble>  <tibble [12 × 8]> <tibble>
#> 5 <split [26/6]> Fold5 <tibble> <tibble>  <tibble [12 × 8]> <tibble>
#> # ℹ 4 more variables: .predictions <list>, .completed <lgl>,
#> #   .tuning_seed <int>, .outer_fit_seed <int>
#> ℹ Use `summary()` for what the run means: which folds failed, what
#>   each one selected, and the estimate across them.
```

## The columns

The object is a tibble with one row per outer fold. The print above
shows the columns that fit its width, and its footer names the rest.
Each column holds one piece of what that fold did.

``` r

names(res)
#>  [1] "splits"          "id"              ".metrics"       
#>  [4] ".selected"       ".inner_metrics"  ".notes"         
#>  [7] ".predictions"    ".completed"      ".tuning_seed"   
#> [10] ".outer_fit_seed"
```

`splits` is the fold’s outer split, an ordinary rsample split. The
tuning saw its analysis rows, and its assessment rows scored the fold’s
model.

``` r

res$splits[[1]]
#> <Analysis/Assess/Total>
#> <25/7/32>
```

`id` is the fold’s label, copied from the design. A repeated design
carries more than one label column, and the object records which columns
they are.

``` r

res$id
#> [1] "Fold1" "Fold2" "Fold3" "Fold4" "Fold5"
```

`.metrics` is the score of the fold’s finalized model on its assessment
rows, one row per metric, in the shape
[`tune::last_fit()`](https://tune.tidymodels.org/reference/last_fit.html)
produces. It is what
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
averages.

``` r

res$.metrics[[1]]
#> # A tibble: 2 × 4
#>   .metric .estimator .estimate .config        
#>   <chr>   <chr>          <dbl> <chr>          
#> 1 rmse    standard       1.23  pre0_mod0_post0
#> 2 rsq     standard       0.911 pre0_mod0_post0
```

`.selected` is the candidate the fold’s inner tuning chose, a one-row
tibble of the tuned parameters. It is what
[`collect_selections()`](https://nestedtune.tidymodels.org/reference/collect_selections.md),
[`summary()`](https://rdrr.io/r/base/summary.html),
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
and the default
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
read.

``` r

res$.selected[[1]]
#> # A tibble: 1 × 3
#>    mtry min_n .config        
#>   <int> <int> <chr>          
#> 1     8     2 pre0_mod5_post0
```

`.inner_metrics` is the whole table the inner search scored: one row per
candidate and metric, its score averaged over the inner resamples. It is
what the fold’s selection was made from.
[`collect_inner_metrics()`](https://nestedtune.tidymodels.org/reference/collect_selections.md)
stacks it across folds, and
[`vignette("tuners")`](https://nestedtune.tidymodels.org/articles/tuners.md)
shows how its shape differs by search.

``` r

res$.inner_metrics[[1]]
#> # A tibble: 12 × 8
#>     mtry min_n .metric .estimator  mean     n std_err .config        
#>    <int> <int> <chr>   <chr>      <dbl> <int>   <dbl> <chr>          
#>  1     2     2 rmse    standard   2.87      5  0.435  pre0_mod1_post0
#>  2     2     2 rsq     standard   0.814     5  0.0935 pre0_mod1_post0
#>  3     2    10 rmse    standard   3.09      5  0.548  pre0_mod2_post0
#>  4     2    10 rsq     standard   0.776     5  0.115  pre0_mod2_post0
#>  5     5     2 rmse    standard   2.88      5  0.446  pre0_mod3_post0
#>  6     5     2 rsq     standard   0.834     5  0.0900 pre0_mod3_post0
#>  7     5    10 rmse    standard   2.88      5  0.510  pre0_mod4_post0
#>  8     5    10 rsq     standard   0.803     5  0.115  pre0_mod4_post0
#>  9     8     2 rmse    standard   2.85      5  0.419  pre0_mod5_post0
#> 10     8     2 rsq     standard   0.834     5  0.0942 pre0_mod5_post0
#> 11     8    10 rmse    standard   2.89      5  0.497  pre0_mod6_post0
#> 12     8    10 rsq     standard   0.805     5  0.115  pre0_mod6_post0
```

`.notes` holds what went wrong inside the fold, in tune’s shape with a
`location` naming the stage. A fold that ran cleanly has no rows.

``` r

res$.notes[[1]]
#> # A tibble: 0 × 4
#> # ℹ 4 variables: location <chr>, type <chr>, note <chr>, trace <list>
```

`.completed` says whether the fold produced a score. The section on a
failed fold below shows a `FALSE`.

``` r

res$.completed
#> [1] TRUE TRUE TRUE TRUE TRUE
```

`.tuning_seed` and `.outer_fit_seed` are the two seeds each fold ran
under, drawn at entry and fixed by the fold’s position in the design, as
[`vignette("nested-cv")`](https://nestedtune.tidymodels.org/articles/nested-cv.md)
explains under Reproducibility.

``` r

select(res, .tuning_seed, .outer_fit_seed)
#> # A tibble: 5 × 2
#>   .tuning_seed .outer_fit_seed
#>          <int>           <int>
#> 1    794080207       314911494
#> 2   1906307464       554751325
#> 3   2010156236       226245929
#> 4   1118907979      1740692099
#> 5   2046114256      1910444850
```

`.predictions` is there because the control above set
`save_pred = TRUE`. It holds each completed fold’s predictions on its
assessment rows, as
[`tune::last_fit()`](https://tune.tidymodels.org/reference/last_fit.html)
returns them, with `.row` naming the row of the data. A run under the
default control has no such column.

A control that sets `extract` to a function adds an `.extracts` column
the same way. It holds what that function returned for each fold’s
fitted workflow. A fold that failed holds `NULL` in either column.

``` r

res$.predictions[[1]]
#> # A tibble: 7 × 4
#>     mpg .pred  .row .config        
#>   <dbl> <dbl> <int> <chr>          
#> 1  21.4  18.7     4 pre0_mod0_post0
#> 2  14.3  14.7     7 pre0_mod0_post0
#> 3  16.4  16.1    12 pre0_mod0_post0
#> 4  21.5  22.9    21 pre0_mod0_post0
#> 5  26    25.2    27 pre0_mod0_post0
#> 6  15.8  16.1    29 pre0_mod0_post0
#> 7  15    15.0    31 pre0_mod0_post0
```

You will sometimes want to know exactly what ran: which tuner, its own
arguments such as the grid, and the control as it took effect. That
description is stored on the object as attributes rather than columns.
[`extract_procedure()`](https://nestedtune.tidymodels.org/reference/extract_procedure.md)
returns that description, which this package calls the procedure.
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
reruns what it describes on the whole dataset.

## The readers

Printing describes the object in hand.
[`summary()`](https://rdrr.io/r/base/summary.html) says what the run
means: how much of the design ran, what each fold chose, and the
estimate.

``` r

summary(res)
#> 
#> ── Nested cross-validation results ────────────────────────────────────
#> Outer resamples: 5-fold cross-validation
#> Outer folds: 5 requested, 5 completed
#> 
#> ── Selected parameters ──
#> 
#> ! mtry: 8, 8, 5, 8, 5 (folds disagree)
#> ✔ min_n: 2 (all 5 completed folds agree)
#> 
#> ── Estimate (5 of 5 outer folds) ──
#> 
#> rmse (standard): 2.49
#> rsq (standard): 0.842
#> 
#> ℹ A nested estimate describes the tune-and-fit procedure, not a model
#>   you can deploy. Build that with `nested_final_fit()`, and report
#>   this estimate as what its procedure achieves.
```

[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
is the estimate as a table, the mean and standard error of the outer
scores. With `summarize = FALSE` it is the outer scores themselves, one
row per fold and metric, with the fold label beside them.

``` r

collect_metrics(res)
#> # A tibble: 2 × 5
#>   .metric .estimator  mean     n std_err
#>   <chr>   <chr>      <dbl> <int>   <dbl>
#> 1 rmse    standard   2.49      5  0.447 
#> 2 rsq     standard   0.842     5  0.0293

collect_metrics(res, summarize = FALSE)
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
```

[`collect_selections()`](https://nestedtune.tidymodels.org/reference/collect_selections.md)
stacks `.selected` over the folds that completed, with the fold label
beside each row, so what every fold chose is one table.
[`collect_inner_metrics()`](https://nestedtune.tidymodels.org/reference/collect_selections.md)
does the same for `.inner_metrics`, so everything every fold scored is
one table.
[`collect_notes()`](https://tune.tidymodels.org/reference/collect_predictions.html),
further down, does the same for `.notes` over every fold.

``` r

collect_selections(res)
#> # A tibble: 5 × 4
#>   id     mtry min_n .config        
#>   <chr> <int> <int> <chr>          
#> 1 Fold1     8     2 pre0_mod5_post0
#> 2 Fold2     8     2 pre0_mod5_post0
#> 3 Fold3     5     2 pre0_mod3_post0
#> 4 Fold4     8     2 pre0_mod5_post0
#> 5 Fold5     5     2 pre0_mod3_post0

collect_inner_metrics(res)
#> # A tibble: 60 × 9
#>    id     mtry min_n .metric .estimator  mean     n std_err .config    
#>    <chr> <int> <int> <chr>   <chr>      <dbl> <int>   <dbl> <chr>      
#>  1 Fold1     2     2 rmse    standard   2.87      5  0.435  pre0_mod1_…
#>  2 Fold1     2     2 rsq     standard   0.814     5  0.0935 pre0_mod1_…
#>  3 Fold1     2    10 rmse    standard   3.09      5  0.548  pre0_mod2_…
#>  4 Fold1     2    10 rsq     standard   0.776     5  0.115  pre0_mod2_…
#>  5 Fold1     5     2 rmse    standard   2.88      5  0.446  pre0_mod3_…
#>  6 Fold1     5     2 rsq     standard   0.834     5  0.0900 pre0_mod3_…
#>  7 Fold1     5    10 rmse    standard   2.88      5  0.510  pre0_mod4_…
#>  8 Fold1     5    10 rsq     standard   0.803     5  0.115  pre0_mod4_…
#>  9 Fold1     8     2 rmse    standard   2.85      5  0.419  pre0_mod5_…
#> 10 Fold1     8     2 rsq     standard   0.834     5  0.0942 pre0_mod5_…
#> # ℹ 50 more rows
```

[`collect_predictions()`](https://tune.tidymodels.org/reference/collect_predictions.html)
stacks `.predictions` the same way, one row per held-out row of every
completed fold. That table is where a plot of predicted against
observed, or a per-observation loss, would start. It refuses a run that
did not save predictions, naming the control slot to set.
[`collect_extracts()`](https://tune.tidymodels.org/reference/collect_predictions.html)
does the same for `.extracts`, one row per fold.

``` r

collect_predictions(res)
#> # A tibble: 32 × 5
#>    id      mpg .pred  .row .config        
#>    <chr> <dbl> <dbl> <int> <chr>          
#>  1 Fold1  21.4  18.7     4 pre0_mod0_post0
#>  2 Fold1  14.3  14.7     7 pre0_mod0_post0
#>  3 Fold1  16.4  16.1    12 pre0_mod0_post0
#>  4 Fold1  21.5  22.9    21 pre0_mod0_post0
#>  5 Fold1  26    25.2    27 pre0_mod0_post0
#>  6 Fold1  15.8  16.1    29 pre0_mod0_post0
#>  7 Fold1  15    15.0    31 pre0_mod0_post0
#>  8 Fold2  22.8  25.2     3 pre0_mod0_post0
#>  9 Fold2  18.7  17.0     5 pre0_mod0_post0
#> 10 Fold2  15.2  16.6    14 pre0_mod0_post0
#> # ℹ 22 more rows
```

[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
counts the selections. Each row is one distinct combination the folds
chose. `n` is how many completed folds chose it, and `prop` is that
count as a share of the completed folds. The most frequent row describes
how stable the tuning procedure’s choice was on this data. It is not the
final model’s parameters, which come from
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
running the procedure once more on the whole dataset.

``` r

agreement(res)
#> # A tibble: 2 × 4
#>    mtry min_n     n  prop
#>   <int> <int> <int> <dbl>
#> 1     8     2     3   0.6
#> 2     5     2     2   0.4
```

## The plots

[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
draws the same two facts. The default view is the selections, one panel
per tuned parameter and one point per outer fold.

``` r

autoplot(res)
```

![One panel per tuned parameter, mtry and min_n, with one point per
outer fold at the value that fold's inner tuning
selected.](results_files/figure-html/autoplot-parameters-1.png)

The other view is the outer scores, one panel per metric and one point
per fold, with a dashed line at the mean that
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
reports.

``` r

autoplot(res, type = "performance")
```

![One panel per metric, rmse and rsq, with one point per outer fold's
score on its assessment rows and a dashed line at the mean across
folds.](results_files/figure-html/autoplot-performance-1.png)

## A failed fold

A fold that fails does not end the run. The other folds keep their
results, and the fold that failed is recorded rather than dropped. To
show that, the workflow below adds a range check on horsepower. The
check refuses to predict for a car whose horsepower is outside the range
seen in training. One car, the Maserati Bora, has far more horsepower
than any other in `mtcars`. The fold that holds it out cannot score it,
so that fold fails. The chunk mutes tune’s progress messages and keeps
its warnings.

``` r

rec <- recipe(mpg ~ ., data = mtcars) |>
  check_range(hp)

wf_checked <- workflow(rec, rf)
```

``` r

set.seed(2)

failed <- nested_tune_grid(wf_checked, folds, grid = grid)
#> Warning: All models failed. Run `show_notes(.Last.tune.result)` for more
#> information.
#> Warning in nested_tune_grid(wf_checked, folds, grid = grid): ! 1 of 5 outer folds failed.
#> ✖ Failed: "Fold1".
#> ℹ See `x$.notes` for what went wrong.

failed
```

The print counts the failure. `.completed` is `FALSE` for the fold that
failed, and its `.notes` say where.
[`collect_notes()`](https://tune.tidymodels.org/reference/collect_predictions.html)
stacks every fold’s `.notes` into one table with the fold label beside
them. The first row for the failed fold is this package’s own note, its
`location` naming the stage. The rows after it are tune’s notes about
the cause.

``` r

failed_id <- failed |>
  filter(!.completed) |>
  pull(id)

collect_notes(failed) |>
  filter(id == failed_id) |>
  select(location, type, note)
#> # A tibble: 2 × 3
#>   location                                      type  note             
#>   <chr>                                         <chr> <chr>            
#> 1 outer fit                                     error "The outer fit p…
#> 2 outer fit: preprocessor 1/1 (prediction data) error "\u001b[1m\u001b…
```

A fold can also complete and still carry notes. That happens when an
inner resample failed but tuning still returned a candidate from the
resamples that ran.

On a run with a failed fold, the readers answer over the folds that
completed. [`summary()`](https://rdrr.io/r/base/summary.html), the
collect functions and
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
each warn once, saying how many folds the answer covers;
[`?collect_selections`](https://nestedtune.tidymodels.org/reference/collect_selections.md)
names the warning’s class. The one collect function that does not warn
is
[`collect_notes()`](https://tune.tidymodels.org/reference/collect_predictions.html),
which reads every fold.
[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
leaves the failed fold’s place on its axis empty.

A run in which no fold completed is a different case. It has no estimate
to report. The print and
[`summary()`](https://rdrr.io/r/base/summary.html) still describe it,
and
[`collect_notes()`](https://tune.tidymodels.org/reference/collect_predictions.html)
still lists its notes. Every other reader refuses it, and so does
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md).

## Subsetting with dplyr

The object is a tibble, so dplyr’s verbs work on it. One rule decides
what they hand back: an object that no longer holds what the run
produced cannot answer for the run. So a verb that only reorders the
rows, or adds or reorders columns, returns a `nested_results`. A verb
that adds or removes a row, or drops or overwrites one of the columns
above, returns a bare tibble. Adding a column, as below, keeps the
class.

``` r

with_position <- mutate(res, position = row_number())

class(with_position)
#> [1] "nested_results" "tbl_df"         "tbl"            "data.frame"
```

Dropping a fold sheds it. The natural case is keeping only the folds
that completed on the run above, which removes one row.

``` r

completed_only <- filter(failed, .completed)

class(completed_only)
#> [1] "tbl_df"     "tbl"        "data.frame"
```

Dropping the columns the run wrote sheds it too, here through base `[`
rather than a dplyr verb, since the same rule governs it.

``` r

class(res[, "id"])
#> [1] "tbl_df"     "tbl"        "data.frame"
```

Both of those hand back the data and nothing more: a plain tibble print,
no summary of the run, no
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html).
A table that has lost a fold, or lost the columns the run wrote, cannot
describe itself as a five-fold design, so it stops describing itself. To
read a partial run, read the run itself: `collect_metrics(failed)`
already averages the folds that completed, and warns that it did.

If your outcome has two classes, or your model is scored at censoring
times, two arguments this page did not use apply. `event_level` names
which level of a two-class outcome is the event. `eval_time` names the
times at which a censored-regression run is scored. Both are described
on
[`?nested_tune_grid`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md).
The second adds an `.eval_time` column to `.metrics` and to everything
[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
reports.
