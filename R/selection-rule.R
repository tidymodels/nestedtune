# The rule each outer fold selects its candidate by (M69).
#
# The orchestrators took the best candidate by the first metric, full stop,
# until M69: `tune::select_best()` on the fold's inner run. A caller who wants
# tune's one-standard-error or percent-loss rule needs to say so once, in a
# form that reaches every fold and is recorded so the final fit applies the
# same rule. That form is a small classed list rather than a function: a
# user's closure would carry its frame to every daemon (the M12 lesson) and
# defeat the fixture cache (the M68 lesson), while a string plus ordering and
# limit formals would put three new arguments on five signatures. The
# orderings are captured as bare expressions with `rlang::enexprs()`, never as
# quosures, for the same reason: an expression carries no environment onto
# the wire or into the cache.

#' Choose the rule each fold selects its candidate by
#'
#' Builds the object the `select` argument of [nested_tune_grid()],
#' [nested_tune_bayes()], [nested_tune_race_anova()],
#' [nested_tune_race_win_loss()] and [nested_tune_sim_anneal()] takes. It
#' names one of tune's three selectors and carries what that selector needs.
#' Every outer fold applies the rule to its own inner tuning run, with
#' `metric` the first metric of the run, and the results object records the
#' rule so [nested_final_fit()] applies the same one to the full-data run.
#'
#' @param rule The selector, one of `"best"` ([tune::select_best()], the
#'   default: the candidate with the best mean on the first metric),
#'   `"one_std_err"` ([tune::select_by_one_std_err()]: the simplest candidate
#'   within one standard error of the best) or `"pct_loss"`
#'   ([tune::select_by_pct_loss()]: the simplest candidate whose loss against
#'   the best is under `limit` percent).
#' @param ... For `"one_std_err"` and `"pct_loss"`, one or more bare
#'   expressions ordering the candidates from simplest to most complex, as
#'   tune's selectors take them: parameter names, wrapped in [dplyr::desc()]
#'   where a larger value is simpler. At least one is required for those two
#'   rules, and none is accepted for `"best"`, which [tune::select_best()]
#'   refuses. Each name must be a parameter the workflow tunes; the
#'   orchestrators check that at entry.
#' @param limit For `"pct_loss"` only, the acceptable loss of performance
#'   against the best candidate, in percent, a single non-negative number;
#'   left `NULL` it takes tune's default of 2. Refused with the other two
#'   rules, which have no limit.
#'
#' @return A list of class `selection_rule` with elements `rule`, the name
#'   given; `order`, the expressions in `...` as a list, empty for `"best"`;
#'   and `limit`, the limit for `"pct_loss"` and `NULL` otherwise. The
#'   expressions are captured, not evaluated, and carry no environment, so
#'   the object is the same wherever it is built. Printing shows the three on
#'   one line.
#'
#' @examples
#' selection_rule()
#'
#' # The simplest candidate within one standard error of the best, taking
#' # fewer components as simpler.
#' selection_rule("one_std_err", num_comp)
#'
#' # A larger penalty is the simpler model, so its order is descending.
#' selection_rule("pct_loss", desc(penalty), limit = 5)
#'
#' @seealso [nested_tune_grid()], [nested_final_fit()], [extract_procedure()],
#'   which reaches the recorded rule as `$select`.
#' @export
selection_rule <- function(
  rule = c("best", "one_std_err", "pct_loss"),
  ...,
  limit = NULL
) {
  rule <- rlang::arg_match(rule)
  order <- unname(rlang::enexprs(...))
  if (rule == "best" && length(order) > 0L) {
    cli::cli_abort(
      c(
        "{.val best} takes no ordering: {.fn tune::select_best} ranks on \\
         the metric alone.",
        x = "Got {length(order)} expression{?s} in {.arg ...}.",
        i = "Order the candidates under {.val one_std_err} or \\
             {.val pct_loss}."
      ),
      class = "nestedtune_selection_rule_order"
    )
  }
  if (rule != "best" && length(order) == 0L) {
    selector <- paste0("tune::select_by_", rule)
    cli::cli_abort(
      c(
        "{.val {rule}} needs at least one ordering in {.arg ...}.",
        i = "Name the tuned parameters from simplest to most complex, as \\
             {.fn {selector}} takes them, wrapping one in \\
             {.fn desc} where a larger value is the simpler model."
      ),
      class = "nestedtune_selection_rule_no_order"
    )
  }
  if (rule != "pct_loss") {
    if (!is.null(limit)) {
      cli::cli_abort(
        c(
          "{.arg limit} belongs to {.val pct_loss} alone.",
          x = "Got {.arg limit} with {.val {rule}}, which has no limit."
        ),
        class = "nestedtune_selection_rule_limit"
      )
    }
  } else {
    if (is.null(limit)) {
      limit <- 2
    }
    if (
      !is.numeric(limit) ||
        length(limit) != 1L ||
        is.na(limit) ||
        !is.finite(limit) ||
        limit < 0
    ) {
      got <- if (is.numeric(limit) && length(limit) == 1L) {
        format(limit)
      } else {
        cli::format_inline("{.obj_type_friendly {limit}}")
      }
      cli::cli_abort(
        c(
          "{.arg limit} must be a single non-negative number, the percent \\
           loss {.fn tune::select_by_pct_loss} accepts.",
          x = "Got {got}."
        ),
        class = "nestedtune_selection_rule_limit"
      )
    }
  }
  new_selection_rule(rule, order, limit)
}

# The constructor behind the checks: what the object is, with nothing judged.
new_selection_rule <- function(rule, order, limit) {
  structure(
    list(rule = rule, order = order, limit = limit),
    class = "selection_rule"
  )
}

is_selection_rule <- function(x) {
  inherits(x, "selection_rule")
}

#' @export
format.selection_rule <- function(x, ...) {
  out <- paste0("<selection_rule> ", x$rule)
  if (length(x$order) > 0L) {
    out <- paste0(
      out,
      " by ",
      paste(vapply(x$order, rlang::as_label, character(1L)), collapse = ", ")
    )
  }
  if (!is.null(x$limit)) {
    out <- paste0(out, " (limit = ", format(x$limit), ")")
  }
  out
}

#' @export
print.selection_rule <- function(x, ...) {
  cat(format(x, ...), "\n", sep = "")
  invisible(x)
}

# The recorded rule applied to one tuning run: the three tune selectors behind
# one call, `metric` the first metric name (resolved off the run by the
# caller), the orderings spliced in as the bare expressions they were captured
# as, and `limit` for the percent-loss rule. `eval_time` stays unpassed, for
# the reason `nested_fold_fit()` gives (D-038). Called inside the fold's
# tryCatch and in the final fit's worker, so both apply the one rule the
# record names.
apply_selection_rule <- function(tuned, select, metric_name) {
  switch(
    select$rule,
    best = tune::select_best(tuned, metric = metric_name),
    one_std_err = tune::select_by_one_std_err(
      tuned,
      !!!select$order,
      metric = metric_name
    ),
    pct_loss = tune::select_by_pct_loss(
      tuned,
      !!!select$order,
      metric = metric_name,
      limit = select$limit
    )
  )
}
