# What an operation may and may not do to a `nested_results_set` (M73,
# D-059).
#
# The set's record is per row: each row's `nested_results` describes its own
# run whole, so a row dropped or reordered leaves every row still true of
# itself, where the single class (test-dplyr-compat.R) sheds on any row
# change. What the set cannot vouch for is a row that is not one of the
# run's own -- repeated, added from elsewhere, or with its `result` swapped
# -- a record column gone or renamed, or no row at all. Those come back a
# bare tibble.
#
# As in test-dplyr-compat.R, every entry names the branch it must take, and
# every door AC1 names appears by its own literal name.

# The suite's two-workflow grid run, served from the cache: `tuned` then
# `fixed`, two outer folds each.
compat_set <- function() {
  wset_results("nested_tune_grid")
}

# Branch (a): the class is back, still a tibble, the orchestrator attribute
# the source's, and every row in hand is one of the source's rows under its
# own id.
expect_kept_set <- function(out, src, name = NULL) {
  what <- if (is.null(name)) "the result" else name
  testthat::expect_s3_class(out, "nested_results_set")
  testthat::expect_s3_class(out, "tbl_df")
  testthat::expect_identical(
    attr(out, "fn"),
    attr(src, "fn"),
    label = paste0(what, "'s fn attribute")
  )
  rows <- match(out$wflow_id, src$wflow_id)
  testthat::expect_false(anyNA(rows), label = paste0(what, " holds a foreign id"))
  testthat::expect_identical(out$workflow, src$workflow[rows])
  testthat::expect_identical(out$result, src$result[rows])
  invisible(out)
}

# Branch (b): no claim to be a set at all, the orchestrator attribute gone
# with the class, and still a tibble.
expect_bare_set <- function(out, name = NULL) {
  what <- if (is.null(name)) "the result" else name
  testthat::expect_false(
    inherits(out, "nested_results_set"),
    label = paste0(what, " keeps the class")
  )
  testthat::expect_null(attr(out, "fn"), label = paste0(what, " keeps fn"))
  testthat::expect_true(
    inherits(out, "tbl_df"),
    label = paste0(what, " is a tibble")
  )
  invisible(out)
}

# One entry per door and direction.
set_compat_table <- function() {
  list(
    # `[` ----------------------------------------------------------------
    list(name = "[ (row index)", branch = "kept", f = function(x) x[2, ]),
    list(name = "[ (reversed rows)", branch = "kept", f = function(x) x[2:1, ]),
    list(name = "[ (logical mask)", branch = "kept", f = function(x) {
      x[c(FALSE, TRUE), ]
    }),
    list(name = "[ (negative index)", branch = "kept", f = function(x) x[-1, ]),
    list(name = "[ (column index, reordered)", branch = "kept", f = function(x) {
      x[, 3:1]
    }),
    list(name = "[ (column index, record column dropped)", branch = "bare", f = function(x) {
      x[, c("wflow_id", "result")]
    }),
    list(name = "[ (single column)", branch = "bare", f = function(x) x["wflow_id"]),
    list(name = "[ (zero rows)", branch = "bare", f = function(x) x[0, ]),
    list(name = "[ (repeated index)", branch = "bare", f = function(x) x[c(1, 1), ]),
    # dplyr verbs ---------------------------------------------------------
    list(name = "filter (one row kept)", branch = "kept", f = function(x) {
      dplyr::filter(x, wflow_id == "fixed")
    }),
    list(name = "filter (no row kept)", branch = "bare", f = function(x) {
      dplyr::filter(x, wflow_id == "nonesuch")
    }),
    list(name = "slice", branch = "kept", f = function(x) dplyr::slice(x, 2)),
    list(name = "slice (repeated row)", branch = "bare", f = function(x) {
      dplyr::slice(x, c(1, 1))
    }),
    list(name = "head", branch = "kept", f = function(x) head(x, 1)),
    list(name = "arrange", branch = "kept", f = function(x) {
      dplyr::arrange(x, dplyr::desc(wflow_id))
    }),
    list(name = "mutate (column added)", branch = "kept", f = function(x) {
      dplyr::mutate(x, extra = 1)
    }),
    # Each row still carries a `result`, and the wrong one: the workflow's
    # id now stands beside another workflow's run.
    list(name = "mutate (result swapped)", branch = "bare", f = function(x) {
      dplyr::mutate(x, result = rev(result))
    }),
    list(name = "mutate (id rewritten)", branch = "bare", f = function(x) {
      dplyr::mutate(x, wflow_id = toupper(wflow_id))
    }),
    list(name = "select (all columns)", branch = "kept", f = function(x) {
      dplyr::select(x, dplyr::everything())
    }),
    list(name = "select (reordered)", branch = "kept", f = function(x) {
      dplyr::select(x, result, wflow_id, workflow)
    }),
    list(name = "select (record column dropped)", branch = "bare", f = function(x) {
      dplyr::select(x, -workflow)
    }),
    list(name = "relocate", branch = "kept", f = function(x) {
      dplyr::relocate(x, result)
    }),
    list(name = "rename (added column)", branch = "kept", f = function(x) {
      dplyr::rename(dplyr::mutate(x, extra = 1), other = extra)
    }),
    list(name = "rename (record column)", branch = "bare", f = function(x) {
      dplyr::rename(x, id = wflow_id)
    }),
    list(name = "bind_rows (row-doubling)", branch = "bare", f = function(x) {
      dplyr::bind_rows(x, x)
    }),
    list(name = "bind_rows (bare tibble)", branch = "bare", f = function(x) {
      dplyr::bind_rows(x, tibble::tibble(other = 1))
    }),
    # The template is the first argument, and the second row is not one of
    # its rows: two subsets are not rejoined into a set (D-059).
    list(name = "bind_rows (two subsets)", branch = "bare", f = function(x) {
      dplyr::bind_rows(x[1, ], x[2, ])
    }),
    list(name = "bind_cols (set first)", branch = "kept", f = function(x) {
      dplyr::bind_cols(x, tibble::tibble(extra = 1:2))
    }),
    list(name = "bind_cols (tibble first)", branch = "bare", f = function(x) {
      dplyr::bind_cols(tibble::tibble(extra = 1:2), x)
    }),
    list(name = "bind_cols (second wflow_id, minimal repair)", branch = "bare", f = function(x) {
      dplyr::bind_cols(
        x,
        tibble::tibble(wflow_id = 1:2),
        .name_repair = "minimal"
      )
    }),
    # base `rbind()` -----------------------------------------------------
    list(name = "rbind (row-doubling)", branch = "bare", f = function(x) {
      rbind(x, x)
    }),
    list(name = "rbind (two subsets)", branch = "bare", f = function(x) {
      rbind(x[2, ], x[1, ])
    }),
    list(name = "rbind (zero-row second)", branch = "kept", f = function(x) {
      rbind(x, x[0, ])
    }),
    # `names<-` ----------------------------------------------------------
    list(name = "names<- (added column)", branch = "kept", f = function(x) {
      x <- dplyr::mutate(x, extra = 1)
      names(x)[[4L]] <- "other"
      x
    }),
    list(name = "names<- (record column)", branch = "bare", f = function(x) {
      names(x)[[1L]] <- "id"
      x
    }),
    list(name = "names<- (second wflow_id)", branch = "bare", f = function(x) {
      x <- dplyr::mutate(x, extra = 1)
      names(x)[[4L]] <- "wflow_id"
      x
    }),
    # vctrs --------------------------------------------------------------
    list(name = "vec_slice (one row)", branch = "kept", f = function(x) {
      vctrs::vec_slice(x, 2)
    }),
    list(name = "vec_slice (reversed)", branch = "kept", f = function(x) {
      vctrs::vec_slice(x, 2:1)
    }),
    list(name = "vec_slice (repeated)", branch = "bare", f = function(x) {
      vctrs::vec_slice(x, c(1, 1))
    }),
    list(name = "vec_slice (zero rows)", branch = "bare", f = function(x) {
      vctrs::vec_slice(x, integer())
    }),
    list(name = "vec_rbind (row-doubling)", branch = "bare", f = function(x) {
      vctrs::vec_rbind(x, x)
    }),
    list(name = "vec_rbind (bare tibble)", branch = "bare", f = function(x) {
      vctrs::vec_rbind(x, tibble::tibble(other = 1))
    }),
    # No `vec_ptype2()` lattice is registered, so a direct column bind
    # finalizes to a bare tibble before the rule is asked (D-059, documented
    # on the help page).
    list(name = "vec_cbind (set first)", branch = "bare", f = function(x) {
      vctrs::vec_cbind(x, tibble::tibble(extra = 1:2))
    })
  )
}

test_that("AC1: every door keeps the class exactly when every row is one of the run's own", {
  skip_if_no_wset_fixture()
  src <- compat_set()
  expect_s3_class(src, "nested_results_set")
  expect_identical(src$wflow_id, c("tuned", "fixed"))

  for (entry in set_compat_table()) {
    out <- entry$f(src)
    if (entry$branch == "kept") {
      expect_kept_set(out, src, name = entry$name)
    } else {
      expect_bare_set(out, name = entry$name)
    }
  }
})

test_that("AC1: a kept subset carries the operation's own rows, columns and order", {
  skip_if_no_wset_fixture()
  src <- compat_set()

  one <- src[2, ]
  expect_identical(one$wflow_id, "fixed")
  expect_identical(nrow(one), 1L)

  rev <- dplyr::arrange(src, dplyr::desc(wflow_id))
  expect_identical(rev$wflow_id, c("tuned", "fixed"))
  rev <- src[2:1, ]
  expect_identical(rev$wflow_id, c("fixed", "tuned"))

  wide <- dplyr::mutate(src, extra = 1)
  expect_identical(names(wide), c("wflow_id", "workflow", "result", "extra"))
  expect_identical(names(src[, 3:1]), c("result", "workflow", "wflow_id"))
})

test_that("AC1: a bare result sheds the record with the class", {
  skip_if_no_wset_fixture()
  src <- compat_set()
  out <- src[0, ]
  expect_identical(class(out), c("tbl_df", "tbl", "data.frame"))
  expect_null(attr(out, "fn"))
  out <- dplyr::bind_rows(src, src)
  expect_identical(nrow(out), 4L)
  expect_null(attr(out, "fn"))
})
