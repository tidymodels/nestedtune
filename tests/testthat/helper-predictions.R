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
