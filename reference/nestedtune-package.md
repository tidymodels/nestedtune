# nestedtune: Nested Cross-Validation for Tidymodels

nestedtune runs nested cross-validation with tidymodels objects. The
outer loop scores the whole tune-and-fit procedure on data that
procedure never saw, and the inner tuning on each outer fold is done by
tune and finetune. What this package adds is the loop, the seeds, and a
result that keeps what every fold chose.

## Details

[`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md)
builds the design, one outer fold per row with its own inner resamples,
without copying the data per fold.

[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md),
[`nested_tune_bayes()`](https://nestedtune.tidymodels.org/reference/nested_tune_bayes.md),
[`nested_tune_race_anova()`](https://nestedtune.tidymodels.org/reference/nested_tune_race.md),
[`nested_tune_race_win_loss()`](https://nestedtune.tidymodels.org/reference/nested_tune_race.md)
and
[`nested_tune_sim_anneal()`](https://nestedtune.tidymodels.org/reference/nested_tune_sim_anneal.md)
run the outer loop with one of tune's or finetune's search methods
inside;
[`nested_fit_resamples()`](https://nestedtune.tidymodels.org/reference/nested_fit_resamples.md)
scores a workflow with nothing to tune on the same design, and
[`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md)
runs a whole workflow set through it.

[`collect_metrics()`](https://tune.tidymodels.org/reference/collect_predictions.html)
gives the estimate, [`summary()`](https://rdrr.io/r/base/summary.html)
and
[autoplot()](https://nestedtune.tidymodels.org/reference/autoplot.nested_results.md)
describe the run, and
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md),
[`collect_selections()`](https://nestedtune.tidymodels.org/reference/collect_selections.md)
and
[`extract_procedure()`](https://nestedtune.tidymodels.org/reference/extract_procedure.md)
say what the folds chose and how they were told to choose.

[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
runs the recorded procedure once more with the whole dataset in hand and
returns the model to deploy.

## See also

Useful links:

- <https://github.com/tidymodels/nestedtune>

- <https://nestedtune.tidymodels.org/>

- Report bugs at <https://github.com/tidymodels/nestedtune/issues>

## Author

**Maintainer**: Jeffrey Girard <jeffgirard@gmail.com>

Authors:

- Jeffrey Girard <jeffgirard@gmail.com>
