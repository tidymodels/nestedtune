# `extract_procedure()` is the user's door onto the `procedure` record, which
# lives as an attribute on a `nested_results` and as a list slot on a
# `nested_final_fit`. Identity is the whole contract: the accessor hands back
# the record the constructor stored, and nothing else, so it is asserted with
# identical() against the raw read on both objects.

procedure_pair <- function() {
  d <- make_reg_data()
  wf <- det_workflow(d)
  res <- final_results(d)
  set.seed(31)
  final <- memoised(nested_final_fit(wf, res))
  list(res = res, final = final)
}

test_that("AC1: the accessor returns the record the results object carries", {
  skip_if_no_engines()
  objs <- procedure_pair()

  got <- extract_procedure(objs$res)
  expect_identical(got, attr(objs$res, "procedure"))
  # The record is what a final fit re-runs, so it names the tuner and carries
  # the control as it took effect; asserted so a stand-in list could not pass.
  expect_identical(got$tuner, "tune_grid")
  expect_s3_class(got$control, "control_grid")
})

test_that("AC1: the accessor returns the record the final fit carries", {
  skip_if_no_engines()
  objs <- procedure_pair()

  got <- extract_procedure(objs$final)
  expect_identical(got, objs$final$procedure)
  # The final fit re-runs the procedure the results object recorded (D-041),
  # so the two doors open onto records that agree on the tuner.
  expect_identical(got$tuner, extract_procedure(objs$res)$tuner)
})

test_that("AC2: an object with no method is refused, naming both that answer", {
  cnd <- rlang::catch_cnd(extract_procedure(1:3))
  expect_s3_class(cnd, "nestedtune_no_extract_method")
  msg <- cli::ansi_strip(conditionMessage(cnd))
  expect_match(msg, "extract_procedure()", fixed = TRUE)
  expect_match(msg, "an integer vector", fixed = TRUE)
  expect_match(msg, "nested_results", fixed = TRUE)
  expect_match(msg, "nested_final_fit", fixed = TRUE)
  # R's bare dispatch failure never reaches the user here.
  expect_no_match(msg, "applicable method")

  expect_snapshot(error = TRUE, extract_procedure(1:3))
})

test_that("AC2: both methods refuse a stray argument in the dots", {
  skip_if_no_engines()
  objs <- procedure_pair()

  expect_error(
    extract_procedure(objs$res, foo = 1),
    class = "rlib_error_dots_nonempty"
  )
  expect_error(
    extract_procedure(objs$final, foo = 1),
    class = "rlib_error_dots_nonempty"
  )
})

test_that("AC2: the no-method refusal wins over a dots complaint", {
  cnd <- rlang::catch_cnd(extract_procedure(1, foo = 1))
  expect_s3_class(cnd, "nestedtune_no_extract_method")
  expect_false(inherits(cnd, "rlib_error_dots_nonempty"))
})

test_that("the record's `select` is the selection_rule() the call was given, on both objects (M69, AC2)", {
  skip_if_no_engines()

  d <- make_reg_data()
  wf <- det_workflow(d)
  rule <- selection_rule("one_std_err", num_comp)
  set.seed(22)
  res <- memoised(nested_tune_grid(
    wf,
    final_nested(d),
    grid = det_grid(),
    metrics = reg_metrics(),
    select = rule
  ))
  expect_identical(extract_procedure(res)$select, rule)

  set.seed(31)
  final <- memoised(nested_final_fit(wf, res))
  expect_identical(extract_procedure(final)$select, rule)

  # The default is recorded too, as the constructor's default object.
  expect_identical(
    extract_procedure(final_results(d))$select,
    selection_rule("best")
  )
})
