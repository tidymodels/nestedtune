# Print a workflow-set run

Shows the orchestrator the set ran through, how many workflows it holds,
and for each workflow its id with how many of its outer folds completed
and the procedure that ran for it.

## Usage

``` r
# S3 method for class 'nested_results_set'
print(x, ...)
```

## Arguments

- x:

  A `nested_results_set` from
  [`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md).

- ...:

  Not used; must be empty.

## Value

`x`, invisibly.

## See also

[`nested_workflow_map()`](https://nestedtune.tidymodels.org/reference/nested_workflow_map.md),
[`collect_metrics.nested_results_set()`](https://nestedtune.tidymodels.org/reference/collect_metrics.nested_results_set.md)
