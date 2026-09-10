#' @examplesIf rlang::is_installed(c("recipes", "yardstick"))
#' data(mtcars)
#'
#' rec <- recipes::recipe(mpg ~ ., data = mtcars) |>
#'   recipes::step_pca(recipes::all_predictors(), num_comp = tune::tune())
#' wf <- workflows::workflow(rec, parsnip::linear_reg())
#'
#' set.seed(1)
#' folds <- nested_resamples(
#'   mtcars,
#'   outside = rsample::vfold_cv(v = 2),
#'   inside = rsample::vfold_cv(v = 2)
#' )
