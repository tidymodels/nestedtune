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
# where it once stopped with an unrelated error as well.
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
    expect_match(
      one_line(cnd),
      "Split 1 of that fold's inner design is ",
      fixed = TRUE
    )
    expect_match(one_line(cnd), "not <rsplit>", fixed = TRUE)
  }
})

# rsample::complement() dispatches to a method in the global environment, as
# it does to a registered one, so the overlap rule reads the rows that
# method returns (M135). The method lasts for the calling test only.
local_global_complement <- function(class, method, env = parent.frame()) {
  name <- paste0("complement.", class)
  assign(name, method, envir = globalenv())
  do.call(
    base::on.exit,
    list(call("rm", list = name, envir = quote(globalenv())), add = TRUE),
    envir = env
  )
}

# `split` with `class` ahead of its own classes and a logical NA `out_id`,
# which leaves its assessment set to rsample::complement().
reclass_split <- function(split, class) {
  split$out_id <- NA
  class(split) <- c(class, class(split))
  split
}

# A complement() method that returns the split's own complement plus its
# first analysis row: every index lies in the frame, and one is a row the
# model trains on.
leaky_complement <- function(x, ...) {
  inside <- rep(FALSE, nrow(x$data))
  inside[x$in_id] <- TRUE
  c(which(!inside), x$in_id[[1]])
}

OUTER_SHARED <- paste(
  "`resamples` has a split whose analysis and assessment sets share rows."
)
INNER_SHARED <- paste(
  "`resamples` has an inner split whose analysis and assessment sets share",
  "rows."
)

test_that("an outer split whose global complement() shares a row is refused", {
  local_global_complement("leaky_split", leaky_complement)
  design <- split_design()
  split <- reclass_split(design$splits[[2]], "leaky_split")
  design$splits[[2]] <- split
  expect_true(any(rsample::complement(split) %in% split$in_id))
  cnd <- expect_error(check_nested(design), class = "nestedtune_bad_design")
  expect_match(one_line(cnd), OUTER_SHARED, fixed = TRUE)
  expect_match(one_line(cnd), "Row 2 of `resamples`", fixed = TRUE)
})

test_that("an inner split whose global complement() shares a row is refused", {
  local_global_complement("leaky_split", leaky_complement)
  design <- split_design()
  split <- reclass_split(design$inner_resamples[[3]]$splits[[2]], "leaky_split")
  design$inner_resamples[[3]]$splits[[2]] <- split
  expect_true(any(rsample::complement(split) %in% split$in_id))
  cnd <- expect_error(check_nested(design), class = "nestedtune_bad_design")
  expect_match(one_line(cnd), INNER_SHARED, fixed = TRUE)
  expect_match(
    one_line(cnd),
    "Element 3 of inner_resamples: split 2.",
    fixed = TRUE
  )
})

# R's dispatch skips the search path between the global environment and
# base, so neither rsample nor tune calls a method in an attached
# environment, and the rule does not read it.
test_that("a complement() method in an attached environment is not read", {
  methods <- new.env()
  methods$complement.leaky_split <- leaky_complement
  attach(methods, name = "nestedtune_test_methods", warn.conflicts = FALSE)
  on.exit(detach("nestedtune_test_methods", character.only = TRUE), add = TRUE)

  design <- split_design()
  split <- reclass_split(design$splits[[2]], "leaky_split")
  design$splits[[2]] <- split
  expect_false(any(rsample::complement(split) %in% split$in_id))
  expect_identical(check_nested(design), design)
})

# An inner split on the outer split's frame that puts a row the outer split
# holds out in both of its sets leaks that row into the tuning. The
# containment rule names that leak, so the shared-rows rule leaves such a row
# to it (M135, D-109). A shared row the outer split holds is still refused as
# shared.
CONTAINED <- paste(
  "`resamples` has an inner split indexing rows its outer fold does not",
  "hold."
)

# A nested_resamples() design, whose inner splits index the outer frame,
# with the first inner split of the first outer fold passed to `edit` along
# with a row that outer split holds out.
edit_whole_inner <- function(edit) {
  d <- shape_data()
  set.seed(3)
  design <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = 3),
    inside = rsample::vfold_cv(v = 2)
  )
  outer <- design$splits[[1]]
  held <- setdiff(seq_len(nrow(d)), outer$in_id)[[1]]
  split <- design$inner_resamples[[1]]$splits[[1]]
  stopifnot(identical(split$data, outer$data))
  design$inner_resamples[[1]]$splits[[1]] <- edit(split, held)
  design
}

expect_contained <- function(design) {
  cnd <- expect_error(check_nested(design), class = "nestedtune_bad_design")
  expect_match(one_line(cnd), CONTAINED, fixed = TRUE)
  expect_match(one_line(cnd), "Outer fold 1, inner split 1", fixed = TRUE)
  expect_no_match(one_line(cnd), INNER_SHARED, fixed = TRUE)
}

test_that("a held-out row in both sets of an inner split is refused as a leak", {
  design <- edit_whole_inner(function(split, held) {
    split$in_id <- c(split$in_id, held)
    split$out_id <- c(split$out_id, held)
    split
  })
  expect_contained(design)
})

test_that("a held-out row a global complement() adds is refused as a leak", {
  out <- NULL
  extra <- NULL
  local_global_complement("held_split", function(x, ...) c(out, extra))
  design <- edit_whole_inner(function(split, held) {
    out <<- split$out_id
    extra <<- held
    split$in_id <- c(split$in_id, held)
    reclass_split(split, "held_split")
  })
  split <- design$inner_resamples[[1]]$splits[[1]]
  expect_identical(split$out_id, NA)
  expect_true(extra %in% rsample::complement(split))
  expect_contained(design)
})

test_that("a held row in both sets of an inner split is still refused as shared", {
  design <- edit_whole_inner(function(split, held) {
    split$out_id <- c(split$out_id, split$in_id[[1]])
    split
  })
  cnd <- expect_error(check_nested(design), class = "nestedtune_bad_design")
  expect_match(one_line(cnd), INNER_SHARED, fixed = TRUE)
  expect_match(
    one_line(cnd),
    "Element 1 of inner_resamples: split 1.",
    fixed = TRUE
  )
})
