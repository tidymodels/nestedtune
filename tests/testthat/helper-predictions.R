# Edits to a run's saved predictions, shared by the `augment()` tests (M93)
# and the `compute_metrics()` tests (M100).

# The run with fold `i`'s saved predictions replaced by `edit()` of them, the
# way a user editing the object would leave it.
edit_fold_predictions <- function(x, i, edit) {
  x$.predictions[[i]] <- edit(x$.predictions[[i]])
  x
}

# The five mismatches. Each changes one thing about `.row`: `missing` drops
# the last entry, `repeated` appends a copy of the first, `na` appends an
# entry whose `.row` is NA, `foreign` appends an entry for a row the fold
# analysed rather than held out, and `no_row` removes the column.
plant_row_mismatch <- function(x, i, case) {
  held <- rsample::complement(x$splits[[i]])
  analysed <- setdiff(seq_len(nrow(x$splits[[i]]$data)), held)
  edit_fold_predictions(x, i, function(p) {
    switch(
      case,
      missing = p[-nrow(p), ],
      repeated = vctrs::vec_rbind(p, p[1L, ]),
      na = {
        extra <- p[1L, ]
        extra$.row <- NA
        vctrs::vec_rbind(p, extra)
      },
      foreign = {
        extra <- p[1L, ]
        extra$.row <- analysed[[1L]]
        vctrs::vec_rbind(p, extra)
      },
      no_row = p[setdiff(names(p), ".row")]
    )
  })
}

row_mismatch_cases <- c("missing", "repeated", "na", "foreign", "no_row")

# The data rows no outer assessment set of `x` holds, read off the splits.
never_held_rows <- function(x) {
  n <- nrow(x$splits[[1L]]$data)
  setdiff(seq_len(n), unlist(lapply(x$splits, rsample::complement)))
}

# `augment()`'s refusal of a design that leaves rows out of every
# assessment set (M125): it counts them and names the first five, or all of
# them when there are five or fewer. `never` comes from never_held_rows().
expect_names_never_held <- function(x, never) {
  cnd <- rlang::catch_cnd(augment(x), "error")
  expect_s3_class(cnd, "nestedtune_augment_rows")
  expect_identical(conditionCall(cnd)[[1L]], as.name("augment"))
  # cli wraps the message at the console width.
  msg <- gsub("\\s+", " ", cli::ansi_strip(conditionMessage(cnd)))
  expect_match(msg, "every data row at least once", fixed = TRUE)
  if (length(never) > 5L) {
    shown <- never[1:5]
    expected <- sprintf(
      "No outer fold holds out %d rows. The first five are %s, and %d.",
      length(never),
      paste(shown[1:4], collapse = ", "),
      shown[[5L]]
    )
  } else {
    expected <- sprintf(
      "No outer fold holds out %s %s.",
      if (length(never) == 1L) "row" else "rows",
      if (length(never) == 1L) {
        never
      } else {
        paste0(
          paste(never[-length(never)], collapse = ", "),
          if (length(never) > 2L) "," else "",
          " and ",
          never[[length(never)]]
        )
      }
    )
  }
  expect_match(msg, expected, fixed = TRUE)
  invisible(msg)
}
