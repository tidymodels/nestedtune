# The named doors onto what selection saw.
#
# `nested_final_fit` has carried its tuning run since M05, reachable only as an
# undocumented list slot; D-014 shipped `extract_workflow()` and left this one
# as "a documented slot suffices pre-1.0" (RR02 Q7). D-023 gives it a name, and
# gives one to the candidate set that run scored -- the final fit's equivalent
# of the candidate set each fold's `.inner_metrics` describes on
# `nested_results` (M21's column, replaced at M49), derived by the same
# function from the run's metrics table so the two can never describe the
# same thing differently.
#
# Generics rather than plain functions: the `extract_*` family is generic
# everywhere in tidymodels, so a non-generic would leave no room for a second
# class to answer. They are generics this package OWNS rather than borrows,
# which is new here -- `collect_metrics()`, `extract_workflow()` and
# `autoplot()` are all methods on someone else's -- and it is forced: neither
# tune nor hardhat defines either name (verified 2026-07-30, tune 2.1.0), so
# there is no upstream generic to register against.
#
# Both carry a default method because R's bare "no applicable method" names
# neither what was handed over nor what would have answered. tune reaches for
# the same remedy on `show_best()` (M06).

#' Extract the tuning run a final fit was selected from
#'
#' Returns the tuning result that [nested_final_fit()] chose its parameters
#' from: the record of what selection saw when the procedure was re-run on the
#' complete dataset.
#'
#' @inheritParams print.nested_final_fit
#'
#' @return The stored `tune_results` object, unchanged. It is tune's own
#'   object, so tune's generics apply to it directly; a fit that ran no tuning
#'   is refused with condition class `nestedtune_no_tuning_run`.
#'
#' @section What its numbers are, and are not:
#'
#' The returned object answers `collect_metrics()` and hands its metrics over
#' unqualified. Each of them was computed on the resamples that chose the
#' candidate it describes, which makes it a selection-time quantity,
#' optimistically biased as a claim about the model this final fit produced.
#'
#' The nested estimate is the honest one, and [nested_final_fit()] says why.
#' This run is kept because it is the record of what selection saw, not
#' because it describes the model.
#'
#' @template example-setup
#' @template example-run
#' @template example-final
#' @examplesIf rlang::is_installed(c("recipes", "yardstick"))
#' extract_tune_results(final)
#'
#' @seealso [extract_scored_candidates()], [nested_final_fit()],
#'   [nested_tune_grid()]
#' @export
extract_tune_results <- function(x, ...) {
  UseMethod("extract_tune_results")
}

#' @export
extract_tune_results.default <- function(x, ...) {
  # No dots check here. A caller holding the wrong object is told so whatever
  # else they passed: a dots check before the refusal answered
  # `extract_tune_results(1, foo = 1)` with a complaint about `foo` and said
  # nothing of `1` (an M34 review finding, closed in M56). The abort never
  # returns, so a check after it would never run either; the methods check
  # their own dots.
  #
  # `current_env()` and not `caller_env()`: inside a method reached by
  # UseMethod() the former renders the generic's own call --
  # `extract_tune_results(x)` -- while the latter renders the call one frame
  # further out, naming whatever function the user happened to be inside.
  abort_no_extract_method(
    "extract_tune_results",
    x,
    classes = "nested_final_fit",
    call = rlang::current_env()
  )
}

#' @export
extract_tune_results.nested_final_fit <- function(x, ...) {
  rlang::check_dots_empty()
  check_tuning_run(x, "extract_tune_results", call = rlang::current_env())
  x$tuning
}

#' Extract the candidates a final fit actually scored
#'
#' Returns the candidate parameter settings [nested_final_fit()]'s tuning run
#' evaluated. It is the full-data counterpart of the candidate set each outer
#' fold's `.inner_metrics` table describes, derived the same way, so the two
#' can be compared directly.
#'
#' @inheritParams print.nested_final_fit
#' @return A tibble with one row per candidate scored, carrying one column per
#'   tuned parameter plus tune's `.config` label, and `.iter` where the search
#'   iterated. It is the distinct parameter rows of the run's
#'   [tune::collect_metrics()] table: everything tune wrote per metric is
#'   dropped (`.metric`, `.estimator`, `mean`, `n`, `std_err`, and
#'   `.eval_time` where a dynamic survival metric was scored), so a candidate
#'   has one row here however many evaluation times it was scored at. The
#'   times and the scores are in `collect_metrics(extract_tune_results(x))`. A
#'   fit that ran no tuning scored no candidate and is refused with condition
#'   class `nestedtune_no_tuning_run`.
#'
#' @section Scored, not asked for:
#'
#' A `grid` given as a size is expanded by tune and may reach fewer candidates
#' than the number requested, and a candidate that failed everywhere scored
#' nothing. [nested_tune_grid()] gives the full account of how the two records
#' diverge under `.inner_metrics`, and it holds here too.
#'
#' One pointer there does not carry over. A candidate that failed on every
#' inner resample is missing from this table, and a `nested_final_fit` has no
#' `.notes` column to record it in. Look inside the run itself:
#' `tune::collect_notes(extract_tune_results(x))`.
#'
#' @template example-setup
#' @template example-run
#' @template example-final
#' @examplesIf rlang::is_installed(c("recipes", "yardstick"))
#' extract_scored_candidates(final)
#'
#' @seealso [extract_tune_results()], [nested_final_fit()],
#'   [nested_tune_grid()]
#' @export
extract_scored_candidates <- function(x, ...) {
  UseMethod("extract_scored_candidates")
}

#' @export
extract_scored_candidates.default <- function(x, ...) {
  # No dots check before the refusal, for the reason the other defaults give.
  abort_no_extract_method(
    "extract_scored_candidates",
    x,
    classes = "nested_final_fit",
    call = rlang::current_env()
  )
}

#' @export
extract_scored_candidates.nested_final_fit <- function(x, ...) {
  rlang::check_dots_empty()
  check_tuning_run(x, "extract_scored_candidates", call = rlang::current_env())
  # The same derivation the fold readers apply to `.inner_metrics`,
  # deliberately: two functions deriving one thing is two chances to describe
  # it differently, and the `@return` above promises a reader they can compare
  # this against a fold's candidate set directly (D-043).
  scored_candidates(x$tuning)
}

# A fit that ran no tuning has no run and no candidates to hand over (M70):
# the record names a tuner that selects nothing, and both accessors refuse
# rather than returning NULL or an empty table a caller might read as a run
# that scored nothing. Read off the procedure, not off `tuning` being NULL,
# so a hand-built object with no procedure is answered as before.
check_tuning_run <- function(x, fn, call = rlang::caller_env()) {
  if (tuner_selects(x$procedure$tuner)) {
    return(invisible(x))
  }
  cli::cli_abort(
    c(
      "{.fn {fn}} has no tuning run to reach: this fit ran none.",
      x = "It was built from a {.fn nested_fit_resamples} result, which \\
           fits the workflow as given; there is no run and no scored \\
           candidate set.",
      i = "{.fn extract_workflow} returns the fitted workflow, and \\
           {.fn extract_procedure} the record."
    ),
    class = "nestedtune_no_tuning_run",
    call = call
  )
}

# One refusal serving every accessor here, so their wording cannot drift apart.
#
# Classed, so a caller can catch it as this package's own rather than by
# matching the message -- the convention M18 established for the argument
# checks.
abort_no_extract_method <- function(
  fn,
  x,
  classes,
  call = rlang::caller_env()
) {
  # `classes` names the classes the generic answers for, each paired with
  # where such an object comes from (M67 added `nested_results`). The
  # `nested_results` phrase is abort_no_agreement_method()'s, so the two
  # families say the same thing about the same object.
  origins <- c(
    nested_results = "{.fn nested_tune_grid} or one of its siblings",
    nested_final_fit = "{.fn nested_final_fit}"
  )
  stopifnot(all(classes %in% names(origins)))
  answers <- sprintf("a {.cls %s} object, from %s", classes, origins[classes])
  cli::cli_abort(
    c(
      "{.fn {fn}} has no method for {.obj_type_friendly {x}}.",
      i = paste0("It answers for ", paste(answers, collapse = ", or "), ".")
    ),
    class = "nestedtune_no_extract_method",
    call = call
  )
}
