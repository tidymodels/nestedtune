# The map's `verbose` log (M149, AC1). One set holds a tuned and a fixed
# workflow, so both route words are drawn. The time each workflow took is
# masked in the snapshot, since it varies from run to run.

mask_map_time <- function(lines) {
  gsub("\\([0-9]+\\.[0-9]s\\)", "(<time>)", lines)
}

test_that("AC1: verbose = TRUE logs each workflow's start and finish, and the result does not change", {
  skip_if_no_wset_fixture()
  d <- make_reg_data()
  wset <- wset_two(d)
  folds <- det_nested(d)

  set.seed(11)
  expect_snapshot(
    loud <- nested_workflow_map(
      wset,
      verbose = TRUE,
      resamples = folds,
      grid = det_grid()
    ),
    transform = mask_map_time
  )

  set.seed(11)
  expect_no_message(
    quiet <- nested_workflow_map(
      wset,
      verbose = FALSE,
      resamples = folds,
      grid = det_grid()
    )
  )
  expect_identical(loud, quiet)
})
