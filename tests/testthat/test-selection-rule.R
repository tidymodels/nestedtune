# `selection_rule()` (M69): the object the orchestrators' `select` argument
# takes, holding the rule name, the parameter orderings as bare expressions and
# the percent-loss limit. It travels to every daemon and into the fixture cache
# as part of the call, so the orderings are captured as expressions and never as
# quosures: nothing here may carry an environment.

test_that("AC3: the default rule is best-by-metric with no ordering and no limit", {
  rule <- selection_rule()
  expect_s3_class(rule, "selection_rule")
  expect_identical(rule$rule, "best")
  expect_identical(rule$order, list())
  expect_null(rule$limit)
  expect_identical(selection_rule("best"), rule)
})

test_that("AC3: the orderings are captured as bare expressions, never quosures", {
  rule <- selection_rule("one_std_err", desc(df1), df2)
  expect_identical(rule$rule, "one_std_err")
  expect_length(rule$order, 2L)
  expect_identical(rule$order[[1L]], quote(desc(df1)))
  expect_identical(rule$order[[2L]], quote(df2))
  expect_false(any(vapply(rule$order, rlang::is_quosure, logical(1L))))
  # The expression is captured, not evaluated: `df1` is not bound here.
  expect_false(exists("df1", inherits = FALSE))
})

test_that("AC3: `limit` defaults to tune's 2 for the percent-loss rule only", {
  expect_identical(selection_rule("pct_loss", df1)$limit, 2)
  expect_identical(selection_rule("pct_loss", df1, limit = 5)$limit, 5)
  expect_identical(selection_rule("pct_loss", df1, limit = 0)$limit, 0)
  expect_identical(selection_rule("pct_loss", df1, limit = 5L)$limit, 5L)
  expect_null(selection_rule("one_std_err", df1)$limit)
  expect_null(selection_rule("best")$limit)
})

test_that("AC3: a rule outside tune's three is refused by arg_match()", {
  expect_error(selection_rule("worst"), class = "rlang_error")
  expect_error(selection_rule("best", rule = "one_std"), class = "rlang_error")
  expect_error(selection_rule(1), class = "rlang_error")
})

test_that("AC3: one_std_err and pct_loss need at least one ordering", {
  for (rule in c("one_std_err", "pct_loss")) {
    cnd <- rlang::catch_cnd(selection_rule(rule))
    expect_s3_class(cnd, "nestedtune_selection_rule_no_order")
    msg <- cli::ansi_strip(conditionMessage(cnd))
    expect_match(msg, rule, fixed = TRUE)
    expect_match(msg, "ordering", fixed = TRUE)
  }
  # And no limit rescues the percent-loss rule from the same refusal.
  expect_error(
    selection_rule("pct_loss", limit = 5),
    class = "nestedtune_selection_rule_no_order"
  )
})

test_that("an ordering given with best is refused, as tune::select_best() refuses one", {
  cnd <- rlang::catch_cnd(selection_rule("best", df1))
  expect_s3_class(cnd, "nestedtune_selection_rule_order")
  expect_match(cli::ansi_strip(conditionMessage(cnd)), "best", fixed = TRUE)
})

test_that("AC3: a limit is refused with best and with one_std_err", {
  cnd <- rlang::catch_cnd(selection_rule("best", limit = 2))
  expect_s3_class(cnd, "nestedtune_selection_rule_limit")
  expect_match(cli::ansi_strip(conditionMessage(cnd)), "pct_loss", fixed = TRUE)
  expect_error(
    selection_rule("one_std_err", df1, limit = 2),
    class = "nestedtune_selection_rule_limit"
  )
})

test_that("AC3: each malformed limit is refused with the percent-loss rule", {
  bad <- list(-1, NA_real_, c(1, 2), "2")
  for (limit in bad) {
    cnd <- rlang::catch_cnd(selection_rule("pct_loss", df1, limit = limit))
    expect_s3_class(cnd, "nestedtune_selection_rule_limit")
    expect_match(cli::ansi_strip(conditionMessage(cnd)), "limit", fixed = TRUE)
  }
  expect_error(
    selection_rule("pct_loss", df1, limit = Inf),
    class = "nestedtune_selection_rule_limit"
  )
})

test_that("the object prints on one line naming the rule, orderings and limit", {
  expect_identical(format(selection_rule()), "<selection_rule> best")
  expect_identical(
    format(selection_rule("one_std_err", desc(df1), df2)),
    "<selection_rule> one_std_err by desc(df1), df2"
  )
  expect_identical(
    format(selection_rule("pct_loss", df1, limit = 5)),
    "<selection_rule> pct_loss by df1 (limit = 5)"
  )
  expect_snapshot({
    selection_rule()
    selection_rule("one_std_err", desc(df1), df2)
    selection_rule("pct_loss", df1, limit = 5)
  })
})

test_that("is_selection_rule() answers for the class alone", {
  expect_true(is_selection_rule(selection_rule()))
  expect_false(is_selection_rule("best"))
  expect_false(is_selection_rule(list(
    rule = "best",
    order = list(),
    limit = NULL
  )))
  expect_false(is_selection_rule(NULL))
})
