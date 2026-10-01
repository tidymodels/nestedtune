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

# The same design passed to nested_tune_grid() is refused there with the
# class and message that `cnd`, check_nested()'s refusal, carries, and the
# refusal names nested_tune_grid() as its call. recipes comes with tune, so
# the workflow needs no skip.
expect_grid_refuses <- function(design, cnd, info = NULL) {
  data <- shape_data()
  rec <- recipes::step_poly(
    recipes::recipe(y ~ x, data = data),
    x,
    degree = tune::tune()
  )
  wf <- workflows::workflow(rec, parsnip::linear_reg())
  grid_cnd <- expect_error(
    nested_tune_grid(wf, design, grid = 2),
    class = "nestedtune_bad_design",
    info = info
  )
  expect_identical(class(grid_cnd), class(cnd), info = info)
  expect_identical(one_line(grid_cnd), one_line(cnd), info = info)
  expect_identical(
    rlang::call_name(conditionCall(grid_cnd)),
    "nested_tune_grid",
    info = info
  )
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
    expect_grid_refuses(design, cnd, type)
  }
})

test_that("check_nested() refuses an inner split that is not a list", {
  for (type in names(NOT_LIST)) {
    design <- split_design()
    design$inner_resamples[[2]]$splits[[1]] <- NOT_LIST[[type]]
    cnd <- expect_error(check_nested(design), class = "nestedtune_bad_design")
    expect_not_list(cnd, "Outer fold 2: inner split 1 has class <rsplit>", type)
    expect_grid_refuses(design, cnd, type)
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
    expect_identical(
      rlang::call_name(conditionCall(cnd)),
      "nested_resamples",
      info = type
    )
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
    expect_identical(
      rlang::call_name(conditionCall(cnd)),
      "nested_resamples",
      info = type
    )
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
  expect_grid_refuses(design, cnd)
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
    expect_identical(rlang::call_name(conditionCall(cnd)), "nested_resamples")

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
    expect_identical(rlang::call_name(conditionCall(cnd)), "nested_resamples")
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
  expect_grid_refuses(design, cnd)
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
  expect_grid_refuses(design, cnd)
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

# A nested_resamples() design, whose inner splits index the outer frame.
whole_design <- function() {
  set.seed(3)
  nested_resamples(
    shape_data(),
    outside = rsample::vfold_cv(v = 3),
    inside = rsample::vfold_cv(v = 2)
  )
}

# That design, with the first inner split of the first outer fold passed to
# `edit` along with a row that outer split holds out.
edit_whole_inner <- function(edit) {
  design <- whole_design()
  outer <- design$splits[[1]]
  held <- setdiff(seq_len(nrow(outer$data)), outer$in_id)[[1]]
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
  expect_grid_refuses(design, cnd)
}

test_that("a held-out row in both sets of an inner split is refused as a leak", {
  design <- edit_whole_inner(function(split, held) {
    split$in_id <- c(split$in_id, held)
    split$out_id <- c(split$out_id, held)
    split
  })
  expect_contained(design)
})

# An index outside the frame is not a row the outer split holds, whichever
# side of the frame it falls on. An NA index is refused before this rule
# reads it (M138).
test_that("an inner index outside the frame is refused as a leak", {
  # An `in_id` index beyond integer range coerces to NA. The outer `in_id`
  # holds no such index, so held() counts it as a row not held (M138).
  design <- edit_whole_inner(function(split, held) {
    split$in_id <- c(split$in_id, 1e10)
    split
  })
  cnd <- expect_error(
    suppressWarnings(check_nested(design)),
    class = "nestedtune_bad_design"
  )
  expect_match(one_line(cnd), CONTAINED, fixed = TRUE)
  expect_match(
    one_line(cnd),
    "Outer fold 1, inner split 1: in_id holds NA,",
    fixed = TRUE
  )
  suppressWarnings(expect_grid_refuses(design, cnd))

  n <- nrow(shape_data())
  plants <- list(in_id = c(0L, -1L, n + 1L), out_id = c(0L, -1L, n + 1L))
  for (slot in names(plants)) {
    for (value in plants[[slot]]) {
      info <- paste(slot, value)
      design <- edit_whole_inner(function(split, held) {
        stopifnot(!anyNA(split$out_id))
        split[[slot]] <- c(split[[slot]], value)
        split
      })
      cnd <- expect_error(
        check_nested(design),
        class = "nestedtune_bad_design",
        info = info
      )
      expect_match(one_line(cnd), CONTAINED, fixed = TRUE, info = info)
      expect_match(
        one_line(cnd),
        paste0("Outer fold 1, inner split 1: ", slot, " holds ", value, ","),
        fixed = TRUE,
        info = info
      )
      expect_grid_refuses(design, cnd, info)
    }
  }
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
  expect_grid_refuses(design, cnd)
})

# An NA in a split's row indices names no data row. rsample reads it as
# rows of NAs, or fails when it builds the assessment set. Both loops refuse it,
# except an `out_id` that is the logical NA, which rsample reads as the
# complement (M138, D-111).
NA_REFUSED <- "`resamples` has a split whose row indices hold an `NA`."

# `split` with a logical NA `out_id` replaced by the complement it stands
# for, so a plant beside real indices has indices to go beside.
explicit_out <- function(split) {
  if (identical(split$out_id, NA)) {
    split$out_id <- as.integer(rsample::complement(split))
  }
  split
}

# `design` with `edit` applied to the outer split of fold `fold`, or to its
# inner split `inner` when that is given.
edit_split <- function(design, fold, inner, edit) {
  if (is.null(inner)) {
    design$splits[[fold]] <- edit(design$splits[[fold]])
  } else {
    splits <- design$inner_resamples[[fold]]$splits
    splits[[inner]] <- edit(splits[[inner]])
    design$inner_resamples[[fold]]$splits <- splits
  }
  design
}

# The bullet naming `slots` of the split at that position.
na_where <- function(fold, inner, slots) {
  pos <- if (is.null(inner)) {
    paste0("Outer fold ", fold)
  } else {
    paste0("Outer fold ", fold, ", inner split ", inner)
  }
  verb <- if (length(slots) == 1L) "holds" else "hold"
  paste0(pos, ": ", paste(slots, collapse = " and "), " ", verb, " an `NA`.")
}

expect_na_refused <- function(design, where, info = NULL) {
  cnd <- expect_error(
    check_nested(design),
    class = "nestedtune_bad_design",
    info = info
  )
  for (w in c(NA_REFUSED, where)) {
    expect_match(one_line(cnd), w, fixed = TRUE, info = info)
  }
  # No position but the planted ones is named.
  named <- gregexpr("Outer fold [0-9]+(, inner split [0-9]+)?: ", one_line(cnd))
  expect_identical(sum(named[[1]] > 0L), length(where), info = info)
  expect_grid_refuses(design, cnd, info)
  invisible(cnd)
}

# Each plant gives a slot's new value from its old one.
NA_PLANTS <- list(
  list(slot = "in_id", value = function(x) c(x, NA), label = "beside"),
  list(slot = "out_id", value = function(x) c(x, NA), label = "beside"),
  list(slot = "in_id", value = function(x) NA, label = "lone NA"),
  list(slot = "out_id", value = function(x) NA_integer_, label = "NA_integer_"),
  list(slot = "out_id", value = function(x) c(NA, NA), label = "c(NA, NA)")
)

test_that("check_nested() refuses an NA in each slot of a nested_resamples() design", {
  for (plant in NA_PLANTS) {
    for (inner in list(NULL, 2L)) {
      info <- paste(plant$slot, plant$label, if (is.null(inner)) "outer")
      design <- edit_split(whole_design(), 2L, inner, function(split) {
        split <- explicit_out(split)
        split[[plant$slot]] <- plant$value(split[[plant$slot]])
        split
      })
      expect_na_refused(design, na_where(2L, inner, plant$slot), info)
    }
  }
})

test_that("check_nested() refuses an NA in each in_id of a nested_cv() design", {
  for (inner in list(NULL, 1L)) {
    info <- if (is.null(inner)) "outer" else "inner"
    design <- edit_split(split_design(), 2L, inner, function(split) {
      split$in_id <- c(split$in_id, NA)
      split
    })
    expect_na_refused(design, na_where(2L, inner, "in_id"), info)
  }
})

test_that("the NA refusal names every position and slot that holds one", {
  design <- edit_split(whole_design(), 1L, NULL, function(split) {
    split$in_id <- c(split$in_id, NA)
    split
  })
  design <- edit_split(design, 3L, 2L, function(split) {
    split$out_id <- NA_integer_
    split
  })
  expect_na_refused(
    design,
    c(na_where(1L, NULL, "in_id"), na_where(3L, 2L, "out_id"))
  )

  design <- edit_split(whole_design(), 2L, 1L, function(split) {
    split$in_id <- c(split$in_id, NA)
    split$out_id <- c(NA, NA)
    split
  })
  expect_na_refused(design, na_where(2L, 1L, c("in_id", "out_id")))
})

# Before M138, an NA in an outer `in_id` and in an inner `in_id` of the same
# fold passed the containment rule, because %in% matches the two NAs (M137
# review B2, B3).
test_that("an NA in the outer and an inner in_id of one fold is refused", {
  design <- edit_split(whole_design(), 1L, NULL, function(split) {
    split$in_id <- c(split$in_id, NA)
    split
  })
  design <- edit_split(design, 1L, 1L, function(split) {
    split$in_id <- c(split$in_id, NA)
    split
  })
  expect_na_refused(
    design,
    c(na_where(1L, NULL, "in_id"), na_where(1L, 1L, "in_id"))
  )
})

# Without the NA rule, a later rule would refuse each of these designs, so
# each refusal shows the NA rule runs first.
test_that("the NA rule runs before the containment and shared-rows rules", {
  contained <- edit_whole_inner(function(split, held) {
    split$in_id <- c(split$in_id, NA)
    split
  })
  shared <- edit_split(whole_design(), 1L, NULL, function(split) {
    split$in_id <- c(split$in_id, NA)
    split
  })
  shared <- edit_split(shared, 2L, NULL, function(split) {
    split <- explicit_out(split)
    split$out_id <- c(split$out_id, split$in_id[[1]])
    split
  })

  cnd <- expect_na_refused(contained, na_where(1L, 1L, "in_id"))
  expect_no_match(one_line(cnd), CONTAINED, fixed = TRUE)
  cnd <- expect_na_refused(shared, na_where(1L, NULL, "in_id"))
  expect_no_match(one_line(cnd), OUTER_SHARED, fixed = TRUE)

  local_mocked_bindings(check_na_indices = function(...) invisible())
  cnd <- expect_error(check_nested(contained), class = "nestedtune_bad_design")
  expect_match(one_line(cnd), CONTAINED, fixed = TRUE)
  cnd <- expect_error(check_nested(shared), class = "nestedtune_bad_design")
  expect_match(one_line(cnd), OUTER_SHARED, fixed = TRUE)
  expect_match(one_line(cnd), "Row 2 of `resamples`", fixed = TRUE)
})

# Both constructors store each outer split's complement as the logical NA,
# which the rule exempts. rsample::nested_cv() stores each inner one so too,
# and nested_resamples() stores its inner indices explicitly.
test_that("check_nested() accepts the logical NA out_id of both constructors", {
  designs <- list(nested_resamples = whole_design(), nested_cv = split_design())
  for (name in names(designs)) {
    design <- designs[[name]]
    for (split in design$splits) {
      expect_identical(split$out_id, NA, info = name)
    }
    expect_identical(check_nested(design), design, info = name)
  }
  for (split in designs$nested_cv$inner_resamples[[1]]$splits) {
    expect_identical(split$out_id, NA, info = "nested_cv inner")
  }
})

# nested_resamples() runs the outer half of the rule on `outside`, so it does
# not build a design every driver refuses (M138, D-111).
test_that("nested_resamples() refuses an NA in an outside split", {
  d <- shape_data()
  for (plant in NA_PLANTS) {
    info <- paste(plant$slot, plant$label)
    set.seed(2)
    outside <- rsample::vfold_cv(d, v = 3)
    split <- explicit_out(outside$splits[[2]])
    split[[plant$slot]] <- plant$value(split[[plant$slot]])
    outside$splits[[2]] <- split
    cnd <- expect_error(
      nested_resamples(d, outside = outside, inside = rsample::vfold_cv(v = 2)),
      class = "nestedtune_bad_design",
      info = info
    )
    expect_match(
      one_line(cnd),
      "`outside` has a split whose row indices hold an `NA`.",
      fixed = TRUE,
      info = info
    )
    expect_match(
      one_line(cnd),
      paste0("Row 2 of `outside`: ", plant$slot, " holds an `NA`."),
      fixed = TRUE,
      info = info
    )
    expect_identical(
      rlang::call_name(conditionCall(cnd)),
      "nested_resamples",
      info = info
    )
  }
})
