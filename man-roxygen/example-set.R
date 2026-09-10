#' @examplesIf rlang::is_installed(c("recipes", "yardstick", "workflowsets"))
#' # One tuned workflow and one baseline, on the same nested design.
#' wset <- workflowsets::workflow_set(
#'   preproc = list(pca = rec, none = recipes::recipe(mpg ~ ., data = mtcars)),
#'   models = list(lm = parsnip::linear_reg())
#' )
#'
#' set.seed(2)
#' res <- nested_workflow_map(wset, resamples = folds, grid = data.frame(num_comp = 1:2))
