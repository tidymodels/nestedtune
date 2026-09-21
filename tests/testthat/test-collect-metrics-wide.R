# M106 AC2: collect_metrics(type = "wide").
#
# The reference pivot is written here with `stats::reshape()`, which shares
# no code with the package's pivot. It puts each metric in a column of its
# own, keyed on every column that is neither a metric field nor a summary
# field, the rule tune's `pivot_metrics()` follows.

wide_reference <- function(long) {
  value <- if ("mean" %in% names(long)) "mean" else ".estimate"
  dropped <- c(".metric", ".estimator", ".estimate", "mean", "n", "std_err")
  dropped <- c(dropped, ".weight")
  keys <- setdiff(names(long), dropped)
  frame <- as.data.frame(long)[c(keys, ".metric", value)]
  # reshape() merges rows whose id holds an NA, which a static metric's
  # `.eval_time` does, so the id is one string built from the keys, NA
  # spelled out. The keys ride along as columns constant within an id.
  frame$.row <- if (length(keys) == 0L) {
    "1"
  } else {
    do.call(paste, c(lapply(frame[keys], format, digits = 17), sep = "\r"))
  }
  out <- stats::reshape(
    frame,
    idvar = ".row",
    timevar = ".metric",
    v.names = value,
    direction = "wide",
    sep = "\r"
  )
  names(out) <- sub(paste0("^", value, "\r"), "", names(out))
  out$.row <- NULL
  attr(out, "reshapeWide") <- NULL
  rownames(out) <- NULL
  out
}

expect_wide_matches <- function(x, ...) {
  for (summarize in c(TRUE, FALSE)) {
    long <- suppressWarnings(collect_metrics(x, summarize = summarize, ...))
    wide <- suppressWarnings(
      collect_metrics(x, summarize = summarize, type = "wide", ...)
    )
    expect_s3_class(wide, "tbl_df")
    expect_equal(as.data.frame(wide), wide_reference(long))
  }
}

cls_run <- function() {
  d <- cls_data()
  set.seed(5)
  memoised(nested_tune_grid(
    cls_workflow(d),
    cls_nested(d),
    grid = cls_grid(),
    metrics = cls_metrics()
  ))
}

srv_run <- function() {
  data <- srv_data()
  nested <- srv_nested(data)
  workflow <- srv_workflow(data)
  set.seed(9)
  suppressWarnings(memoised(nested_tune_grid(
    workflow,
    nested,
    grid = srv_grid(),
    metrics = srv_set_metrics(),
    eval_time = srv_eval_times()
  )))
}

test_that("the long type is the call without a type", {
  skip_if_no_engines()

  res <- cls_run()
  for (summarize in c(TRUE, FALSE)) {
    expect_identical(
      collect_metrics(res, summarize = summarize, type = "long"),
      collect_metrics(res, summarize = summarize)
    )
  }
})

test_that("the wide type pivots a classification run's metrics", {
  skip_if_no_engines()

  res <- cls_run()
  expect_wide_matches(res)

  # Stated independently of the reference: three metrics, one column each,
  # one row summarized and one per outer fold unsummarized.
  wide <- collect_metrics(res, type = "wide")
  expect_setequal(names(wide), c("roc_auc", "sens", "spec"))
  expect_identical(nrow(wide), 1L)
  per_fold <- collect_metrics(res, summarize = FALSE, type = "wide")
  expect_identical(names(per_fold)[[1L]], "id")
  expect_setequal(names(per_fold)[-1L], c("roc_auc", "sens", "spec"))
  expect_identical(nrow(per_fold), nrow(res))
})

test_that("the wide type keeps the evaluation time as a key", {
  skip_if_no_censored()

  res <- srv_run()
  expect_wide_matches(res)

  wide <- collect_metrics(res, type = "wide")
  expect_identical(names(wide)[[1L]], ".eval_time")
  expect_setequal(
    names(wide)[-1L],
    c("brier_survival", "concordance_survival")
  )
  # One row per time, and the static metric's row keyed on NA.
  expect_setequal(wide$.eval_time, c(srv_eval_times(), NA))
})

test_that("the wide type pivots a set, keyed on the workflow", {
  skip_if_no_wset_fixture()
  skip_if_no_censored()

  res <- srv_set_results()
  expect_wide_matches(res)

  wide <- collect_metrics(res, type = "wide")
  expect_identical(names(wide)[1:2], c("wflow_id", ".eval_time"))
  expect_setequal(unique(wide$wflow_id), res$wflow_id)
})

test_that("an unknown type is refused", {
  skip_if_no_engines()

  res <- cls_run()
  expect_error(
    collect_metrics(res, type = "tall"),
    class = "nestedtune_bad_type"
  )
  expect_error(
    collect_metrics(res, type = c("long", "wide", "x")),
    class = "nestedtune_bad_type"
  )
  expect_snapshot(error = TRUE, collect_metrics(res, type = "tall"))
})

test_that("an unknown type is refused on a set", {
  skip_if_no_wset_fixture()
  skip_if_no_censored()

  expect_error(
    collect_metrics(srv_set_results(), type = "tall"),
    class = "nestedtune_bad_type"
  )
})
