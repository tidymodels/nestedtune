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

#' Choose the rule each fold selects its parameters by
#'
#' @description
#' Builds the object the `select` argument of [nested_tune_grid()] and its
#' siblings takes. It names one of tune's three selectors, or desirability2's
#' desirability selector, and carries what that selector needs.
#'
#' Every outer fold applies the rule to its own inner tuning run. tune's three
#' selectors rank on the first metric of that run. The result records the
#' rule, so [nested_final_fit()] selects the same way on the full data.
#'
#' @param rule The selector: `"best"` (the default), `"one_std_err"`,
#'   `"pct_loss"` or `"desirability"`. The section below says what each one
#'   picks.
#' @param ... For `"one_std_err"` and `"pct_loss"`, one or more bare
#'   expressions ordering the candidates from simplest to most complex, as
#'   tune's selectors take them. For `"desirability"`, one or more goals such
#'   as `maximize(rsq)` or `minimize(num_comp)`, as
#'   [desirability2::select_best_desirability()] takes them. At least one is
#'   required for those three rules, and `"best"` accepts none.
#' @param limit For `"pct_loss"` only, the acceptable loss against the best
#'   candidate, in percent, as a single non-negative number. Left `NULL` it
#'   takes tune's default of 2, and the other rules refuse it.
#'
#' @return A list of class `selection_rule` with elements `rule`, `order` and
#'   `limit`. `order` holds the expressions in `...`, empty for `"best"`.
#'   `limit` is `NULL` outside `"pct_loss"`. Printing shows the three on one
#'   line: the rule, then `by` and the orderings as written, then the limit
#'   in parentheses. That same label follows `Selected by:` in the printed
#'   [summary.nested_results()], [summary.nested_results_set()],
#'   [print.nested_final_fit()] and [summary.nested_final_fit()] when the
#'   rule is not `"best"`.
#'
#' @section The four rules:
#'
#' `"best"` takes the candidate with the best mean on the first metric, as
#' [tune::select_best()] does. `"one_std_err"` takes the simplest candidate
#' within one standard error of the best, as [tune::select_by_one_std_err()]
#' does. `"pct_loss"` takes the simplest candidate whose loss against the best
#' stays under `limit` percent, as [tune::select_by_pct_loss()] does.
#' `"desirability"` takes the candidate with the highest overall desirability
#' over the goals in `...`, as [desirability2::select_best_desirability()]
#' does.
#'
#' @section Writing a desirability goal:
#'
#' The `"desirability"` rule needs the desirability2 package, version 0.2.0
#' or later. Where it is not installed, the rule is refused when it is built,
#' when an orchestrator starts, and when [nested_final_fit()] is given a
#' result that recorded it.
#'
#' Each goal is a call to one of desirability2's goal functions, such as
#' `maximize()`, `minimize()` or `target()`, written without the
#' `desirability2::` prefix, which desirability2 refuses. Its first argument
#' names a metric or a tuned parameter. desirability2 checks each goal when
#' the rule is built. [nested_tune_grid()] and [nested_tune_bayes()] check at
#' entry that every name a goal uses is a metric in `metrics` or a parameter
#' `object` tunes. With `metrics` left `NULL`, the metrics are the ones tune
#' uses by default for the model's mode. desirability2 sets each limit a goal
#' leaves out from the tuning run it scores, so each fold and the final fit
#' scale those goals on their own inner run. A limit written into the goal
#' holds everywhere. [nested_tune_race_anova()],
#' [nested_tune_race_win_loss()] and [nested_tune_sim_anneal()] refuse the
#' rule.
#'
#' @section Writing an ordering:
#'
#' An ordering is a parameter name, wrapped in [dplyr::desc()] where a larger
#' value is the simpler model. Each must be a bare name or a call, never a
#' string or a number, which orders nothing. An ordering given a name is
#' refused. That way a misspelled `limit` is refused instead of read as an
#' ordering. Every name
#' must be a parameter the workflow tunes, which the orchestrators check when
#' the run starts.
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
#' # A high R-squared and few components, weighed together.
#' if (rlang::is_installed("desirability2", version = "0.2.0")) {
#'   selection_rule("desirability", maximize(rsq), minimize(num_comp))
#' }
#'
#' @seealso [nested_tune_grid()], [nested_final_fit()], [extract_procedure()],
#'   which reaches the recorded rule as `$select`.
#' @export
selection_rule <- function(
  rule = c("best", "one_std_err", "pct_loss", "desirability"),
  ...,
  limit = NULL
) {
  rule <- rlang::arg_match(rule)
  if (rule == "desirability") {
    check_desirability_installed()
  }
  rlang::check_dots_unnamed()
  order <- unname(rlang::enexprs(...))
  if (rule == "desirability") {
    check_desirability_terms(order, limit)
    return(new_selection_rule(rule, order, NULL))
  }
  literal <- !vapply(
    order,
    function(x) rlang::is_symbol(x) || rlang::is_call(x),
    logical(1L)
  )
  if (any(literal)) {
    cli::cli_abort(
      c(
        "Each ordering in {.arg ...} must be a bare parameter name, or one \
         wrapped in {.fn desc}, as {.fn tune::select_by_one_std_err} and \
         {.fn tune::select_by_pct_loss} take them.",
        x = "Got {.obj_type_friendly {order[[which(literal)[1L]]]}}, which \
             names no parameter and would order nothing.",
        i = "Write {.code num_comp}, not {.code \"num_comp\"}."
      ),
      class = "nestedtune_selection_rule_order"
    )
  }
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

# The desirability rule's terms (M109, D-073): at least one, no `limit`, and
# each judged by desirability2's own `desirability()`, which knows its goal
# functions and their arguments. Its errors carry no class, so each is raised
# again under this package's, with desirability2's message kept as the parent.
check_desirability_terms <- function(terms, limit, call = rlang::caller_env()) {
  if (length(terms) == 0L) {
    cli::cli_abort(
      c(
        "{.val desirability} needs at least one term in {.arg ...}.",
        i = "Write a goal such as {.code maximize(rsq)} or \\
             {.code minimize(num_comp)}, as \\
             {.fn desirability2::select_best_desirability} takes them."
      ),
      class = "nestedtune_selection_rule_no_order",
      call = call
    )
  }
  if (!is.null(limit)) {
    cli::cli_abort(
      c(
        "{.arg limit} belongs to {.val pct_loss} alone.",
        x = "Got {.arg limit} with {.val desirability}, which has no limit."
      ),
      class = "nestedtune_selection_rule_limit",
      call = call
    )
  }
  tryCatch(
    desirability2::desirability(!!!terms),
    error = function(cnd) {
      cli::cli_abort(
        "desirability2 refused the terms in {.arg ...}.",
        parent = cnd,
        class = "nestedtune_selection_rule_terms",
        call = call
      )
    }
  )
  invisible(terms)
}

# The names a desirability term reads: the variables of its first argument,
# where desirability2 itself reads them (`all.vars()` of the goal's `x`).
desirability_term_names <- function(terms) {
  unique(unlist(lapply(terms, function(term) {
    if (rlang::is_call(term) && length(term) >= 2L) all.vars(term[[2L]])
  })))
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

# The rule on one line: its name, then ` by ` and the orderings as written,
# then ` (limit = <limit>)` where the rule carries one. The one rendering the
# object's own print and the `Selected by:` line of the results and final-fit
# summaries share (M98), so a reader meets the same words in both places.
selection_rule_label <- function(x) {
  out <- x$rule
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

# Whether the rule is one the summaries name (M98): the default best-by-metric
# rule stays unnamed, so the line's presence is itself the signal, as the
# fold-failure and candidate-set lines are. `NULL` -- the record of a run that
# applied no rule -- is not named either.
names_selection_rule <- function(select) {
  is_selection_rule(select) && select$rule != "best"
}

#' @export
format.selection_rule <- function(x, ...) {
  rlang::check_dots_empty()
  paste0("<selection_rule> ", selection_rule_label(x))
}

#' @export
print.selection_rule <- function(x, ...) {
  rlang::check_dots_empty()
  cat(format(x), "\n", sep = "")
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
  selected <- switch(
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
    ),
    # Scored over the terms alone, so `metric_name` plays no part (M109).
    desirability = desirability2::select_best_desirability(
      tuned,
      !!!select$order
    )
  )
  # tune's one-standard-error rule filters on `std_err`, which a single inner
  # resample leaves NA, so the selector returns no row; left alone, the empty
  # selection fails the outer fit one step later with a note about the
  # preprocessor. Name the failure where it happens, so the fold's note does.
  if (nrow(selected) == 0L) {
    cli::cli_abort(
      c(
        "The {.val {select$rule}} selection rule chose no candidate on this \
         fold's inner run.",
        i = "{.fn tune::select_by_one_std_err} needs a standard error, \
             which one inner resample cannot give; use more inner resamples \
             or another rule."
      ),
      class = "nestedtune_selection_rule_empty"
    )
  }
  selected
}
