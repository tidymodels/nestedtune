# Generator for `branch-point-results.rds`: a `nested_results` saved before
# the workflow identity read case weights or a postprocessor, so the suite
# can show that `nested_final_fit()` still accepts such a record under the
# workflow it ran under (test-nested-final-fit-identity.R). It is the
# `fit_resamples_results()` fixture of helper-orchestration.R, written out
# here in full so this file reads without the helpers: `make_reg_data()`
# (seed 4242, 90 rows), `fixed_workflow()` (PCA at two components, step id
# written out), `det_nested()` (3 by 3 folds, seed 11), `reg_metrics()`
# (rmse and rsq), and the run under entry seed 30.
#
# Run at commit a0837b5 (the default branch at the branch point) from the
# package root, with the package loaded from source:
#
#   Rscript tests/testthat/fixtures/make-branch-point-results.R
#
# The saved object's record then carries a `workflow` entry with the two
# parts of that version, `model` and `preprocessor`, and nothing else.

pkgload::load_all(".", quiet = TRUE)

set.seed(4242)
n <- 90
d <- data.frame(x1 = rnorm(n), x2 = rnorm(n), x3 = rnorm(n), x4 = rnorm(n))
d$y <- 2 * d$x1 - d$x2 + 0.5 * d$x3 + rnorm(n)

set.seed(30)
rec <- recipes::step_pca(
  recipes::recipe(y ~ x1 + x2 + x3 + x4, data = d),
  recipes::all_predictors(),
  num_comp = 2L,
  id = "pca_fixed"
)
wf <- workflows::workflow(rec, parsnip::linear_reg())
set.seed(11)
folds <- nested_resamples(
  d,
  outside = rsample::vfold_cv(v = 3),
  inside = rsample::vfold_cv(v = 3)
)
ms <- yardstick::metric_set(yardstick::rmse, yardstick::rsq)
set.seed(30)
res <- nested_fit_resamples(wf, folds, metrics = ms)

stopifnot(identical(
  names(extract_procedure(res)$workflow),
  c("model", "preprocessor")
))
saveRDS(res, "tests/testthat/fixtures/branch-point-results.rds", version = 3)
