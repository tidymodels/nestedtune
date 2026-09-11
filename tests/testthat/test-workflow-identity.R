# The canonical workflow identity (M83 T1): what two workflows built from
# the same code share, what a workflow built on more rows leaves out, and
# what a workflow built from different code does not share.
#
# The identity is what `nested_final_fit()` compares (test-nested-final-fit-
# identity.R exercises that door). These tests pin the function itself, on
# the properties the door's acceptance rests on: a rebuilt fixture reads as
# the same workflow even though its step ids and quosure frames differ (AC3),
# and no data rows enter the record (AC5).

test_that("AC3: a workflow rebuilt from the same code has the same identity", {
  skip_if_no_engines()
  d <- make_reg_data()

  # Built at two stream positions, so the recipe's step id differs, and in
  # two frames, so every quosure's environment differs; neither is in the
  # identity.
  set.seed(1)
  a <- det_workflow(d)
  set.seed(2)
  b <- local({
    frame_local <- d
    det_workflow(frame_local)
  })
  expect_false(identical(a, b))
  expect_identical(workflow_identity(a), workflow_identity(b))

  # Two steps, each with its own drawn id.
  expect_identical(
    workflow_identity(bayes_workflow(d)),
    workflow_identity(bayes_workflow(d))
  )
})

test_that("AC3: arguments given through set_args() and set_engine() read as those given in the constructor", {
  skip_if_no_engines()
  d <- make_reg_data()

  in_call <- workflows::workflow(
    y ~ x1 + x2,
    parsnip::set_engine(parsnip::linear_reg(penalty = 1), "lm")
  )
  after <- workflows::workflow(
    y ~ x1 + x2,
    parsnip::set_args(parsnip::set_engine(parsnip::linear_reg(), "lm"), penalty = 1)
  )
  expect_identical(workflow_identity(in_call), workflow_identity(after))

  # Engine arguments and a tune() marker by both routes, on the stochastic
  # fixture's specification; nothing is fitted, so ranger need not be
  # installed.
  assembled <- workflows::workflow(
    y ~ x1 + x2 + x3 + x4,
    parsnip::set_engine(
      parsnip::set_args(
        parsnip::set_mode(parsnip::rand_forest(), "regression"),
        min_n = tune::tune(),
        trees = 25
      ),
      "ranger",
      num.threads = 1
    )
  )
  expect_identical(
    workflow_identity(stoch_workflow(d)),
    workflow_identity(assembled)
  )
})

test_that("AC5: the identity carries no data rows", {
  skip_if_no_engines()

  small <- workflow_identity(det_workflow(make_reg_data(n = 90)))
  large <- workflow_identity(det_workflow(make_reg_data(n = 900)))
  expect_identical(small, large)
  expect_identical(object.size(small), object.size(large))

  # And no leaf is a frame or a column of one: every leaf is a string.
  leaves <- rapply(small, function(x) x, how = "unlist")
  expect_type(leaves, "character")
})

test_that("the identity names the model and the preprocessor as the criteria describe", {
  skip_if_no_engines()
  d <- make_reg_data()

  id <- workflow_identity(det_workflow(d))
  expect_named(id, c("model", "preprocessor"))
  expect_identical(id$model$class, "linear_reg")
  expect_identical(id$model$engine, "lm")
  expect_identical(id$model$mode, "regression")
  expect_identical(id$model$args, list(penalty = "NULL", mixture = "NULL"))
  expect_length(id$model$eng_args, 0L)

  expect_identical(id$preprocessor$kind, "recipe")
  expect_identical(
    id$preprocessor$roles,
    list(x1 = "predictor", x2 = "predictor", x3 = "predictor", x4 = "predictor", y = "outcome")
  )
  step <- id$preprocessor$steps[[1L]]
  expect_identical(step$type, "step_pca")
  expect_identical(unname(step$terms), list("recipes::all_predictors()"))
  expect_identical(step$settings$num_comp, "tune()")
  expect_false("id" %in% names(step$settings))

  # The other two preprocessor kinds.
  f <- workflow_identity(plain_workflow(d))$preprocessor
  expect_identical(f, list(kind = "formula", formula = "y ~ x1 + x2 + x3 + x4"))
  v <- workflow_identity(workflows::workflow(
    workflows::workflow_variables(y, c(x1, x2)),
    parsnip::linear_reg()
  ))$preprocessor
  expect_identical(
    v,
    list(kind = "variables", outcomes = "y", predictors = "c(x1, x2)")
  )
})

test_that("a model argument is recorded as written, and a recipe setting as the value the step holds", {
  skip_if_no_engines()
  d <- make_reg_data()

  # parsnip keeps an argument as the expression given, so a name bound
  # outside the workflow is recorded as that name and two bindings of it
  # are not distinguished (the help page says so).
  model <- function(p) {
    workflows::workflow(y ~ x1 + x2, parsnip::linear_reg(penalty = p))
  }
  expect_identical(workflow_identity(model(1)), workflow_identity(model(2)))
  expect_identical(workflow_identity(model(1))$model$args$penalty, "p")

  # recipes evaluates a step's setting when the step is added, so the same
  # name reaches the identity as the value it held.
  step <- function(k) {
    rec <- recipes::step_pca(
      recipes::recipe(y ~ x1 + x2 + x3 + x4, data = d),
      recipes::all_predictors(),
      num_comp = k
    )
    workflows::workflow(rec, parsnip::linear_reg())
  }
  expect_identical(
    workflow_identity(step(1L))$preprocessor$steps[[1L]]$settings$num_comp,
    "1L"
  )
  expect_false(identical(workflow_identity(step(1L)), workflow_identity(step(2L))))
  expect_false(identical(
    workflow_identity(fixed_workflow(d)),
    workflow_identity(det_workflow(d))
  ))
})
