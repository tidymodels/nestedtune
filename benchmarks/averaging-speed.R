# Speed of the average behind `collect_predictions(summarize = TRUE)` and
# `augment()` (M126).
#
# Not a test: wall-clock times vary with the machine. The script compares the
# working tree's `average_fold_predictions()` with a frozen copy of the M124
# version, in one R session on one machine, so the ratio is what it reports.
# It also checks that the two agree on each table: numeric columns within
# `all.equal(tolerance = 1e-12)`, factor columns `identical()`. The rewrite
# uses grouped sums with `mean()`'s second pass. Where `long double` is wider
# than `double`, their rounding can differ from `mean()`'s in the last bits.
#
#   Rscript benchmarks/averaging-speed.R
#
# Three stacked tables in which each of 3 folds holds each of 33,334 data
# rows out once (100,002 rows): 10 class probabilities with a class, a class
# alone, and a censored `.pred` with `.pred_time`. The script stops if a row
# is not held out by 3 distinct folds. A few values are missing, so the rules
# that ignore them run.

suppressMessages(pkgload::load_all(".", quiet = TRUE))

cat(R.version.string, "|", R.version$platform, "\n")

# ---- The frozen copy (R/nested-results-collect.R at 383e7a13) ------------

frozen <- new.env(parent = baseenv())
local(
  envir = frozen,
  {
    new_tbl <- function(cols) {
      structure(
        cols,
        class = c("tbl_df", "tbl", "data.frame"),
        row.names = .set_row_names(length(cols[[1L]]))
      )
    }

    average_fold_predictions <- function(preds, drop) {
      preds <- preds[setdiff(names(preds), drop)]
      rows <- sort(unique(preds$.row))
      group <- factor(match(preds$.row, rows), levels = seq_along(rows))
      first <- match(rows, preds$.row)
      per_row <- function(v, fn) {
        vapply(split(v, group), fn, numeric(1), USE.NAMES = FALSE)
      }
      mean_na_rm <- function(v) mean(v, na.rm = TRUE)

      nms <- names(preds)
      others <- nms[!startsWith(nms, ".pred") & nms != ".row"]
      outcome <- Filter(function(nm) is.factor(preds[[nm]]), others)
      prob_cols <- if (length(outcome) == 1L) {
        intersect(paste0(".pred_", levels(preds[[outcome]])), nms)
      } else {
        character(0)
      }
      if (length(prob_cols) > 0L) {
        probs <- matrix(
          unlist(lapply(prob_cols, function(nm) {
            per_row(preds[[nm]], mean_na_rm)
          })),
          ncol = length(prob_cols)
        )
        probs <- probs / rowSums(probs)
      }

      cols <- lapply(nms, function(nm) {
        v <- preds[[nm]]
        if (nm %in% prob_cols) {
          return(probs[, match(nm, prob_cols)])
        }
        if (nm == ".pred_class" && length(prob_cols) > 0L) {
          return(class_from_probs(probs, prob_cols, v, preds[[outcome]]))
        }
        if (nm == ".pred_class") {
          return(class_by_vote(v, group))
        }
        if (nm == ".pred_time") {
          return(per_row(v, stats::median))
        }
        if (nm == ".pred" && is.list(v)) {
          return(average_survival(v, group))
        }
        if (startsWith(nm, ".pred") && is.numeric(v)) {
          return(per_row(v, mean_na_rm))
        }
        vctrs::vec_slice(v, first)
      })
      names(cols) <- nms
      new_tbl(cols)
    }

    class_from_probs <- function(probs, prob_cols, saved, outcome) {
      idx <- apply(probs, 1L, function(r) {
        if (all(is.na(r))) NA_integer_ else which.max(r)
      })
      labels <- substring(prob_cols, nchar(".pred_") + 1L)
      factor(
        labels[idx],
        levels = levels(saved),
        ordered = is.ordered(outcome)
      )
    }

    class_by_vote <- function(v, group) {
      counts <- unclass(table(group, addNA(v, ifany = FALSE)))
      idx <- max.col(counts, ties.method = "first")
      idx[idx > nlevels(v)] <- NA_integer_
      factor(levels(v)[idx], levels = levels(v), ordered = is.ordered(v))
    }

    average_survival <- function(v, group) {
      sizes <- vapply(
        v,
        function(t) if (is.null(t)) 0L else nrow(t),
        integer(1)
      )
      long <- vctrs::vec_rbind(!!!v)
      long_group <- rep(as.integer(group), sizes)
      key <- vctrs::vec_group_id(
        vctrs::new_data_frame(list(g = long_group, t = long$.eval_time))
      )
      first <- match(seq_len(attr(key, "n")), key)
      averaged <- lapply(names(long), function(nm) {
        if (nm == ".eval_time") {
          return(long$.eval_time[first])
        }
        vapply(
          split(long[[nm]], factor(key, levels = seq_along(first))),
          function(x) mean(x, na.rm = TRUE),
          numeric(1),
          USE.NAMES = FALSE
        )
      })
      names(averaged) <- names(long)
      averaged <- new_tbl(averaged)
      owner <- factor(long_group[first], levels = seq_len(nlevels(group)))
      unname(lapply(split(seq_along(first), owner), function(i) {
        vctrs::vec_slice(averaged, i)
      }))
    }
  }
)

# ---- The tables ---------------------------------------------------------

n_rows <- 33334L
n_folds <- 3L
set.seed(126)
# Stacked fold by fold: each fold holds every data row once, in its own
# random order.
row <- unlist(lapply(seq_len(n_folds), function(f) sample(n_rows)))
fold <- rep(seq_len(n_folds), each = n_rows)
folds_per_row <- vapply(
  split(fold, row),
  function(f) length(unique(f)),
  integer(1)
)
stopifnot(
  all(tabulate(row, n_rows) == n_folds),
  all(folds_per_row == n_folds)
)
lv <- paste0("c", 1:10)
outcome <- factor(sample(lv, n_rows, replace = TRUE), levels = lv)

prob_table <- local({
  p <- matrix(stats::rexp(length(row) * length(lv)), ncol = length(lv))
  p <- p / rowSums(p)
  p[sample(length(p), 50L)] <- NA
  cols <- c(
    list(id = paste0("Fold", fold), y = outcome[row]),
    stats::setNames(as.list(as.data.frame(p)), paste0(".pred_", lv)),
    list(
      .pred_class = factor(lv[max.col(replace(p, is.na(p), 0))], levels = lv),
      .row = row
    )
  )
  tibble::new_tibble(cols)
})

class_table <- local({
  cls <- factor(sample(lv, length(row), replace = TRUE), levels = lv)
  cls[sample(length(cls), 50L)] <- NA
  tibble::new_tibble(list(
    id = paste0("Fold", fold),
    y = outcome[row],
    .pred_class = cls,
    .row = row
  ))
})

srv_table <- local({
  times <- c(0.5, 10)
  surv <- matrix(stats::runif(length(row) * 2L), ncol = 2L)
  wt <- matrix(stats::runif(length(row) * 2L, 1, 2), ncol = 2L)
  surv[sample(length(surv), 50L)] <- NA
  entries <- lapply(seq_along(row), function(i) {
    tibble::new_tibble(list(
      .eval_time = times,
      .pred_survival = surv[i, ],
      .weight_censored = wt[i, ]
    ))
  })
  tibble::new_tibble(list(
    id = paste0("Fold", fold),
    .pred = entries,
    .row = row,
    .pred_time = stats::rexp(length(row)),
    `survival::Surv(time, event)` = survival::Surv(
      stats::rexp(n_rows),
      stats::rbinom(n_rows, 1, 0.7)
    )[row]
  ))
})

# ---- Agreement and timing -------------------------------------------------

branch_avg <- function(tbl) {
  average_fold_predictions(tbl, drop = "id", verb = "collect_predictions")
}
frozen_avg <- function(tbl) frozen$average_fold_predictions(tbl, drop = "id")

# Numeric columns, and the numeric columns of each censored entry, within
# 1e-12. Everything else identical.
agree <- function(a, b) {
  if (!identical(names(a), names(b)) || nrow(a) != nrow(b)) {
    return(FALSE)
  }
  all(vapply(
    names(a),
    function(nm) {
      x <- a[[nm]]
      y <- b[[nm]]
      if (is.list(x) && !is.data.frame(x)) {
        return(
          identical(lengths(x), lengths(y)) &&
            isTRUE(all.equal(
              as.data.frame(vctrs::vec_rbind(!!!x)),
              as.data.frame(vctrs::vec_rbind(!!!y)),
              tolerance = 1e-12
            ))
        )
      }
      if (is.double(x)) {
        return(isTRUE(all.equal(x, y, tolerance = 1e-12)))
      }
      identical(x, y)
    },
    logical(1)
  ))
}

median_time <- function(f, tbl, times = 5L) {
  stats::median(vapply(
    seq_len(times),
    function(i) system.time(f(tbl))[["elapsed"]],
    numeric(1)
  ))
}

tables <- list(
  probabilities = prob_table,
  class = class_table,
  censored = srv_table
)
cat("stacked rows per table:", nrow(prob_table), "\n")
cat(
  "data rows held out by",
  n_folds,
  "distinct folds:",
  sum(folds_per_row == n_folds),
  "of",
  n_rows,
  "\n\n"
)
for (nm in names(tables)) {
  tbl <- tables[[nm]]
  ok <- agree(branch_avg(tbl), frozen_avg(tbl))
  t_frozen <- median_time(frozen_avg, tbl)
  t_branch <- median_time(branch_avg, tbl)
  cat(sprintf(
    "%-13s agree: %-5s  frozen M124: %6.3f s  branch: %6.3f s  ratio: %.3f\n",
    nm,
    ok,
    t_frozen,
    t_branch,
    t_branch / t_frozen
  ))
}
