#' @description
#' nestedtune runs nested cross-validation with tidymodels objects. The outer
#' loop scores the whole tune-and-fit procedure on data that procedure never
#' saw, and the inner tuning on each outer fold is done by tune and finetune.
#' What this package adds is the loop, the seeds, and a result that keeps what
#' every fold chose.
#'
#' @details
#' [nested_resamples()] builds the design, one outer fold per row with its own
#' inner resamples, without copying the data per fold.
#'
#' [nested_tune_grid()], [nested_tune_bayes()], [nested_tune_race_anova()],
#' [nested_tune_race_win_loss()] and [nested_tune_sim_anneal()] run the outer
#' loop with one of tune's or finetune's search methods inside;
#' [nested_fit_resamples()] scores a workflow with nothing to tune on the same
#' design, and [nested_workflow_map()] runs a whole workflow set through it.
#'
#' [collect_metrics()] gives the estimate, `summary()` and
#' [autoplot()][autoplot.nested_results] describe the run, and [agreement()],
#' [collect_selections()] and [extract_procedure()] say what the folds chose
#' and how they were told to choose.
#'
#' [nested_final_fit()] runs the recorded procedure once more with the whole
#' dataset in hand and returns the model to deploy.
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL
