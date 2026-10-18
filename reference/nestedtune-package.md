# nestedtune: Nested Cross-Validation for 'tidymodels'

nestedtune runs nested cross-validation with tidymodels objects. Each
outer fold tunes with tune or finetune on its own inner resamples, or
fits a workflow with nothing to tune, and scores the result on rows it
held out.

## Details

[`nested_resamples()`](https://nestedtune.tidymodels.org/reference/nested_resamples.md)
builds the design.
[`nested_tune_grid()`](https://nestedtune.tidymodels.org/reference/nested_tune_grid.md)
and the other nested tuning functions run the loop, and
[`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md)
runs a workflow set through it.
[collect_metrics()](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results.md)
gives the estimate, and
[`agreement()`](https://nestedtune.tidymodels.org/reference/agreement.md)
shows what the folds selected.
[`nested_final_fit()`](https://nestedtune.tidymodels.org/reference/nested_final_fit.md)
fits the model to deploy on all the data.

## See also

Useful links:

- <https://github.com/tidymodels/nestedtune>

- <https://nestedtune.tidymodels.org/>

- Report bugs at <https://github.com/tidymodels/nestedtune/issues>

## Author

**Maintainer**: Jeffrey Girard <jeffgirard@gmail.com>

Authors:

- Jeffrey Girard <jeffgirard@gmail.com>
