# The split checks read each split as the list rsample builds. An element
# that carries the rsplit class but is not a list is refused as malformed,
# at entry and at construction, rather than crashing the checks that read it
# (M135).

shape_data <- function() {
  set.seed(1)
  data.frame(x = seq_len(30), y = stats::rnorm(30))
}

split_design <- function(d = shape_data()) {
  set.seed(2)
  rsample::nested_cv(
    d,
    outside = rsample::vfold_cv(v = 3),
    inside = rsample::vfold_cv(v = 2)
  )
}

# The two atomic shapes that carry the class.
NOT_LIST <- list(
  integer = structure(1:3, class = "rsplit"),
  character = structure(c("a", "b"), class = "rsplit")
)

# The message on one line, so a sentence that cli wrapped is matched whole.
one_line <- function(cnd) {
  gsub("\\s+", " ", cli::ansi_strip(conditionMessage(cnd)))
}

expect_not_list <- function(cnd, where, info) {
  expect_s3_class(cnd, "nestedtune_bad_design")
  expect_match(one_line(cnd), where, fixed = TRUE, info = info)
  expect_match(one_line(cnd), "not a list", fixed = TRUE, info = info)
}

# An inner design for nested_resamples()'s `inside`, with its first split
# replaced by `element`.
planted_inside <- function(data, element) {
  rset <- rsample::vfold_cv(data, v = 2)
  rset$splits[[1]] <- element
  rset
}

test_that("check_nested() refuses an outer split that is not a list", {
  for (type in names(NOT_LIST)) {
    design <- split_design()
    design$splits[[2]] <- NOT_LIST[[type]]
    cnd <- expect_error(check_nested(design), class = "nestedtune_bad_design")
    expect_not_list(cnd, "Element 2 has class <rsplit>", type)
    expect_match(one_line(cnd), "malformed splits column", fixed = TRUE)
  }
})

test_that("check_nested() refuses an inner split that is not a list", {
  for (type in names(NOT_LIST)) {
    design <- split_design()
    design$inner_resamples[[2]]$splits[[1]] <- NOT_LIST[[type]]
    cnd <- expect_error(check_nested(design), class = "nestedtune_bad_design")
    expect_not_list(cnd, "Outer fold 2: inner split 1 has class <rsplit>", type)
  }
})

test_that("nested_resamples() refuses an outside split that is not a list", {
  d <- shape_data()
  for (type in names(NOT_LIST)) {
    set.seed(2)
    outside <- rsample::vfold_cv(d, v = 3)
    outside$splits[[2]] <- NOT_LIST[[type]]
    cnd <- expect_error(
      nested_resamples(d, outside = outside, inside = rsample::vfold_cv(v = 2)),
      class = "nestedtune_bad_design"
    )
    expect_not_list(cnd, "Element 2 has class <rsplit>", type)
    expect_match(one_line(cnd), "`outside` has a malformed", fixed = TRUE)
  }
})

test_that("nested_resamples() refuses an inside split that is not a list", {
  d <- shape_data()
  for (type in names(NOT_LIST)) {
    element <- NOT_LIST[[type]]
    set.seed(2)
    cnd <- expect_error(
      nested_resamples(
        d,
        outside = rsample::vfold_cv(v = 3),
        inside = planted_inside(element = element)
      ),
      class = "nestedtune_bad_design"
    )
    expect_not_list(cnd, "Split 1 of that fold's inner design has class", type)
    expect_match(one_line(cnd), "for outer fold 1", fixed = TRUE, info = type)
  }
})

test_that("two outer splits that are not lists are both named", {
  design <- split_design()
  design$splits[[1]] <- NOT_LIST$integer
  design$splits[[3]] <- NOT_LIST$character
  cnd <- expect_error(check_nested(design), class = "nestedtune_bad_design")
  expect_match(
    one_line(cnd),
    "Elements 1 and 3 have class <rsplit> but are not lists.",
    fixed = TRUE
  )
})

# nested_resamples() gives an element that lacks the class the same check,
# where it once crashed as well.
test_that("nested_resamples() refuses a split that is not an rsplit", {
  d <- shape_data()
  for (element in list(list(a = 1), 5L)) {
    set.seed(2)
    outside <- rsample::vfold_cv(d, v = 3)
    outside$splits[[3]] <- element
    cnd <- expect_error(
      nested_resamples(d, outside = outside, inside = rsample::vfold_cv(v = 2)),
      class = "nestedtune_bad_design"
    )
    expect_match(one_line(cnd), "Element 3 is ", fixed = TRUE)
    expect_match(one_line(cnd), "not <rsplit>", fixed = TRUE)

    set.seed(2)
    cnd <- expect_error(
      nested_resamples(
        d,
        outside = rsample::vfold_cv(v = 3),
        inside = planted_inside(element = element)
      ),
      class = "nestedtune_bad_design"
    )
    expect_match(one_line(cnd), "Split 1 of that fold's inner design is ", fixed = TRUE)
    expect_match(one_line(cnd), "not <rsplit>", fixed = TRUE)
  }
})
