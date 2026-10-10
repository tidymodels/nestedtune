#' @description
#' nestedtune runs nested cross-validation with tidymodels objects. Each
#' outer fold tunes with tune or finetune on its own inner resamples, or fits
#' a workflow with nothing to tune, and scores the result on rows it held
#' out.
#'
#' @details
#' [nested_resamples()] builds the design. [nested_tune_grid()] and the other
#' nested tuning functions run the loop, and [nested_workflow_map()] runs a
#' workflow set through it.
#' [collect_metrics()][collect_metrics.nested_results] gives the estimate, and
#' [agreement()] shows what the folds selected. [nested_final_fit()] fits
#' the model to deploy on all the data.
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL
