# Argument order beside tune's and finetune's (M148).
#
# Arguments after `...` match by name only, so their order breaks no call. It
# still decides what the usage line on the help page shows, and a reader moving
# between `tune_bayes()` and `nested_tune_bayes()` reads the shared arguments
# in one order. Each test reads the counterpart's formals at test time, and
# also states the expected order of the moved arguments as written text, so a
# counterpart that drops an argument cannot make the comparison pass on a
# shorter list.

shared_order <- function(ours, theirs) {
  a <- names(formals(ours))
  b <- names(formals(theirs))
  list(ours = intersect(a, b), theirs = intersect(b, a))
}

test_that("nested_tune_bayes() orders its shared arguments as tune_bayes() does", {
  for (cl in c("workflow", "model_spec")) {
    o <- shared_order(
      getS3method("nested_tune_bayes", cl),
      getFromNamespace(paste0("tune_bayes.", cl), "tune")
    )
    expect_identical(o$ours, o$theirs, label = cl)
    expect_identical(
      o$ours[o$ours %in% c("metrics", "eval_time", "objective", "initial")],
      c("metrics", "eval_time", "objective", "initial"),
      label = cl
    )
  }
})

test_that("nested_tune_sim_anneal() orders its shared arguments as tune_sim_anneal() does", {
  skip_if_not_installed("finetune")
  for (cl in c("workflow", "model_spec")) {
    o <- shared_order(
      getS3method("nested_tune_sim_anneal", cl),
      getFromNamespace(paste0("tune_sim_anneal.", cl), "finetune")
    )
    expect_identical(o$ours, o$theirs, label = cl)
    expect_identical(
      o$ours[o$ours %in% c("metrics", "eval_time", "initial")],
      c("metrics", "eval_time", "initial"),
      label = cl
    )
  }
})
