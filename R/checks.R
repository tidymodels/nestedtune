# Argument validation for the orchestrators and the final fit.
#
# GP3: a provably invalid design is refused rather than warned about. Each of
# these fires before any fitting, so a misspecified call fails in a second
# rather than after the first fold.

check_workflow <- function(object, call = rlang::caller_env()) {
  if (!inherits(object, "workflow")) {
    cli::cli_abort(
      c(
        "{.arg object} must be a {.cls workflow}.",
        x = if (inherits(object, "model_spec")) {
          "Got a bare model specification."
        } else {
          "Got {.obj_type_friendly {object}}."
        },
        # The six orchestrators take a bare spec by their own method (D-069)
        # and never reach this with one. `nested_final_fit()` does, so the
        # hint spells out the wrapping that function needs.
        i = if (inherits(object, "model_spec")) {
          "Wrap it with its preprocessor: \\
           {.code workflows::workflow(preprocessor, spec)}."
        } else {
          "Wrap a model and a preprocessor with {.fn workflows::workflow}."
        }
      ),
      call = call
    )
  }
  # Trained-ness is a field on a workflow, not a class, so this asks rather
  # than tests inherits().
  if (workflows::is_trained_workflow(object)) {
    cli::cli_abort(
      c(
        "{.arg object} must not already be fitted.",
        x = "Nested cross-validation fits the workflow itself, once per outer \\
             fold, on that fold's analysis set."
      ),
      call = call
    )
  }
  # Asked before extract_spec_parsnip(), which raises its own error for this --
  # a fine message, but one whose conditionCall() is that internal call rather
  # than the user's, so the one bad-`object` shape a user is most likely to
  # produce was the one that did not name their call. `workflows` has a
  # has_spec() but does not export it, and `:::` is a check failure, so this
  # asks the structure directly; if that layout ever moved, the extraction
  # below still refuses, which is the behaviour this replaces.
  if (is.null(object$fit$actions$model)) {
    cli::cli_abort(
      c(
        "{.arg object} has no model specification.",
        # An empty workflow carries no preprocessor either, so the bullet says
        # which of the two shapes was actually handed over rather than assuming
        # the commoner one.
        x = if (has_preprocessor(object)) {
          "The workflow carries a preprocessor only."
        } else {
          "The workflow is empty."
        },
        i = "Add one with {.fn workflows::add_model}."
      ),
      call = call
    )
  }
  # The sibling of the branch above. A workflow needs both halves before it can
  # be fitted, and workflows raises for a missing preprocessor only once a fit
  # is attempted -- which here is inside a fold, so every fold failed alike and
  # the message was workflows', from a call the user never wrote.
  if (!has_preprocessor(object)) {
    cli::cli_abort(
      c(
        "{.arg object} has no preprocessor.",
        x = "The workflow carries a model specification only.",
        i = "Add one with {.fn workflows::add_formula}, \\
             {.fn workflows::add_recipe}, or {.fn workflows::add_variables}."
      ),
      call = call
    )
  }
  check_workflow_pkgs(object, call = call)
  invisible(object)
}

# Does the workflow carry one of the three things that can preprocess?
#
# Asked by name rather than as `length(object$pre$actions) > 0L`, which is not
# the same question: `workflows::add_case_weights()` also files an action under
# `pre`, so a workflow carrying a model and case weights but no formula, recipe
# or variables has a non-empty `pre$actions` and still cannot be fitted -- it
# slipped the guard below and every outer fold failed alike, the exact
# degradation that guard exists to prevent. The counting form also described
# such a workflow as carrying "a preprocessor only" in the branch above.
has_preprocessor <- function(object) {
  any(c("formula", "recipe", "variables") %in% names(object$pre$actions))
}

# A missing package would surface anyway, but only once the first fold starts
# fitting. Asking up front turns a wait-then-fail into an immediate answer,
# which matters when the fold that fails is the tenth. Asked of the whole
# workflow since M58 -- `workflow_pkgs()` (R/parallel.R), the list the daemon
# pre-flight and the attach step read -- so a recipe step's package is refused
# here as an engine's always was, under the class the tuner refusal carries
# (`check_tuner_installed()`): both state the same fact about this library.
# The mode is not checked here: workflows::workflow() already refuses a spec
# without one, so there is no path that reaches us with an unknown mode.
check_workflow_pkgs <- function(object, call = rlang::caller_env()) {
  needed <- workflow_pkgs(object)
  missing <- needed[!vapply(needed, rlang::is_installed, logical(1))]
  if (length(missing) > 0L) {
    hint <- paste0("install.packages(", deparse1(missing), ")")
    cli::cli_abort(
      c(
        "{.pkg {missing}} {?is/are} needed by the workflow but not installed.",
        i = "Install {cli::qty(missing)}{?it/them} with {.code {hint}}."
      ),
      class = "nestedtune_pkg_not_installed",
      call = call
    )
  }

  invisible(needed)
}

# The model-spec door of the six orchestrators (M107, D-069). tune's own
# `model_spec` methods take only a formula or a recipe and refuse a
# `workflow_variables()` object. Here it is refused with the other wrong
# types, and its hint names the workflow route that does take it.
is_formula_or_recipe <- function(x) {
  rlang::is_formula(x) || inherits(x, "recipe")
}

check_preprocessor <- function(preprocessor, call = rlang::caller_env()) {
  if (rlang::is_missing(preprocessor)) {
    cli::cli_abort(
      c(
        "{.arg preprocessor} is missing.",
        i = "A model specification needs a formula or a recipe as its \\
             second argument, before {.arg resamples}."
      ),
      class = "nestedtune_bad_preprocessor",
      call = call
    )
  }
  if (!is_formula_or_recipe(preprocessor)) {
    cli::cli_abort(
      c(
        "{.arg preprocessor} must be a formula or a recipe.",
        x = "Got {.obj_type_friendly {preprocessor}}.",
        i = if (inherits(preprocessor, "workflow_variables")) {
          "Add variables to a workflow with {.fn workflows::add_variables} \\
           and pass the workflow instead."
        } else if (inherits(preprocessor, "rset")) {
          "The resampling design is the third argument, after the \\
           preprocessor."
        }
      ),
      class = "nestedtune_bad_preprocessor",
      call = call
    )
  }
  invisible(preprocessor)
}

# The other side of the same door: a workflow carries its own preprocessor, so
# one given beside it is refused, whether it came by name (it lands in `...`),
# by position (it lands in `resamples`, and the design in `...`), or by
# position with `resamples` named (it lands in `...` unnamed). `dots` is the
# list `capture_dots()` returns. Asked before `check_dots_control()` and
# `check_nested()`, whose messages would name the symptom and not the cause.
check_no_preprocessor <- function(dots, resamples, call = rlang::caller_env()) {
  preprocessor_like <- function(x) {
    is_formula_or_recipe(x) || inherits(x, "workflow_variables")
  }
  by_name <- "preprocessor" %in% rlang::names2(dots)
  by_position <- !rlang::is_missing(resamples) && preprocessor_like(resamples)
  unnamed <- dots[!nzchar(rlang::names2(dots))]
  in_dots <- Filter(preprocessor_like, unnamed)
  if (!by_name && !by_position && length(in_dots) == 0L) {
    return(invisible())
  }
  cli::cli_abort(
    c(
      "A workflow carries its own preprocessor.",
      x = if (by_name) {
        "Got {.arg preprocessor} beside a workflow."
      } else if (by_position) {
        "Got {.obj_type_friendly {resamples}} where {.arg resamples} goes."
      } else {
        "Got {.obj_type_friendly {in_dots[[1]]}} as an unnamed argument \\
         beside a workflow."
      },
      i = "Pass the bare model specification with the preprocessor, or \\
           leave the preprocessor out and pass the workflow alone."
    ),
    class = "nestedtune_preprocessor_with_workflow",
    call = call
  )
}

# What the six orchestrators' default methods raise (D-069). A call with no
# `object` at all dispatches here too, and is refused as missing.
abort_bad_object <- function(object, call = rlang::caller_env()) {
  rlang::check_required(object, call = call)
  cli::cli_abort(
    c(
      "{.arg object} must be a {.cls workflow} or a parsnip model \\
       specification.",
      x = "Got {.obj_type_friendly {object}}."
    ),
    call = call
  )
}

# Runs a `model_spec` method's call of the generic on the built workflow. An
# error raised in that call's own frame records it as its call, so this puts
# back the call the user wrote, the one the spec method was dispatched from.
# That frame's call carries the method's name, so the generic's name, the
# head of the internal call, replaces it. Only a condition whose call is that
# internal call exactly is rewritten. The two are compared without their
# attributes: a package installed with its source kept records a `srcref` on
# the frame's call, which the substituted expression does not carry.
with_user_call <- function(expr, call = rlang::caller_env()) {
  inner <- substitute(expr)
  call <- rlang::frame_call(call)
  call[[1]] <- inner[[1]]
  bare <- function(x) {
    attributes(x) <- NULL
    x
  }
  withCallingHandlers(
    expr,
    error = function(cnd) {
      if (identical(bare(conditionCall(cnd)), bare(inner))) {
        cnd$call <- call
        stop(cnd)
      }
    }
  )
}

# The workflow's tuned parameter ids, or NULL where they cannot be read: a
# check that cannot be made is skipped, never turned into a false refusal, as
# `check_grid_params()` reads the same set.
tuned_parameter_ids <- function(object) {
  tryCatch(
    tune::extract_parameter_set_dials(object)$id,
    error = function(cnd) NULL
  )
}

# The two doors a workflow takes (M70, D-057), decided by whether anything in
# it is marked with `tune()`. The five tuning orchestrators refuse a workflow
# with nothing to tune: an inner loop over one candidate runs for nothing,
# tune warns once per fold, and the record would call it a search. Before
# this, an unmarked workflow ran through `nested_tune_grid()` with that
# warning on every fold and failed every fold on the iterating tuners (probed
# 2026-09-06). Refused at entry, before any fold runs (GP3), naming the export
# that scores a fixed workflow; the class is the check's own so a caller can
# catch the refusal as this one.
check_untuned_workflow <- function(object, call = rlang::caller_env()) {
  ids <- tuned_parameter_ids(object)
  if (is.null(ids) || length(ids) > 0L) {
    return(invisible(object))
  }
  cli::cli_abort(
    c(
      "{.arg object} has no parameter marked for tuning.",
      x = "Nothing in it is marked with {.fn tune::tune}, so there is \\
           nothing for the inner loop to search.",
      i = "Score a fixed workflow on the outer folds with \\
           {.fn nested_fit_resamples}, or mark a parameter with \\
           {.fn tune::tune} to tune it here."
    ),
    class = "nestedtune_untuned_workflow",
    call = call
  )
}

# The other door. `nested_fit_resamples()` runs no inner stage, so a marked
# parameter would reach the outer fit unfinalized and every fold would fail
# alike, one outer loop later; refused at entry instead, naming the five that
# tune. `nested_final_fit()` on a record that selected nothing asks the same
# of the workflow it is handed.
check_tuned_workflow <- function(object, call = rlang::caller_env()) {
  ids <- tuned_parameter_ids(object)
  if (is.null(ids) || length(ids) == 0L) {
    return(invisible(object))
  }
  cli::cli_abort(
    c(
      "{.arg object} has {length(ids)} parameter{?s} marked for tuning: \\
       {.val {ids}}.",
      x = "{.fn nested_fit_resamples} runs no inner tuning, so a marked \\
           parameter would never be finalized.",
      i = "Tune it with {.fn nested_tune_grid}, {.fn nested_tune_bayes}, \\
           {.fn nested_tune_race_anova}, {.fn nested_tune_race_win_loss} or \\
           {.fn nested_tune_sim_anneal}, or fix its value in the workflow."
    ),
    class = "nestedtune_tuned_workflow",
    call = call
  )
}

check_nested <- function(resamples, call = rlang::caller_env()) {
  # Every refusal here carries one class, so a caller can catch a malformed
  # design at any of the five drivers alike (M55); each names every offending
  # position or column rather than the first found, so one fix does not
  # merely reveal the next.
  if (
    !is.data.frame(resamples) ||
      !all(c("splits", "inner_resamples") %in% names(resamples))
  ) {
    cli::cli_abort(
      c(
        "{.arg resamples} must be a nested resampling design.",
        x = "Got {.obj_type_friendly {resamples}}.",
        i = "Build one with {.fn nested_resamples} or \\
             {.fn rsample::nested_cv}."
      ),
      class = "nestedtune_bad_design",
      call = call
    )
  }
  if (nrow(resamples) == 0L) {
    cli::cli_abort(
      "{.arg resamples} has no outer folds.",
      class = "nestedtune_bad_design",
      call = call
    )
  }
  # Every column beside the two list columns labels the outer folds: the
  # results object records exactly this set (D-036) and names its rows by it.
  labels <- setdiff(names(resamples), c("splits", "inner_resamples"))
  # Without one, the loop would run to completion and only then assemble a
  # malformed object -- the whole cost paid before anything complains, which
  # is what checking here prevents.
  if (!any(is_id_name(labels))) {
    cli::cli_abort(
      c(
        "{.arg resamples} has no {.field id} column naming its outer folds.",
        i = "Designs from {.fn nested_resamples} and {.fn rsample::nested_cv} \\
             always carry one."
      ),
      class = "nestedtune_bad_design",
      call = call
    )
  }
  # rsample builds a bootstrap here, with a warning at most. It warns when the
  # call text starts with bootstraps( and for any bootstrap rset, so an
  # rsample::bootstraps() or group_bootstraps() call builds with no bootstrap
  # warning. The same row can land in both the
  # inner analysis and the inner assessment set, which makes the estimate
  # invalid rather than merely unusual, so this refuses (GP3). nested_resamples()
  # already refuses at construction; this catches designs built elsewhere.
  if (inherits(resamples, "bootstraps")) {
    cli::cli_abort(
      c(
        "{.arg resamples} cannot use a bootstrap for the outer loop.",
        x = refused_design_reason(bootstrap_design(resamples), "outer"),
        i = "{.fn rsample::nested_cv} builds this design, with a warning at \\
             most; nestedtune refuses."
      ),
      class = "nestedtune_bad_design",
      call = call
    )
  }
  # The designs no nested estimate can use (D-096), which rsample::nested_cv()
  # builds without complaint. nested_resamples() refuses them at construction;
  # these catch designs built elsewhere, in both loops. The inner check reads
  # each element with inherits(), because the class checks below have not yet
  # vouched for it.
  refused <- refused_design(resamples)
  if (!is.na(refused)) {
    cli::cli_abort(
      c(
        "{.arg resamples} cannot use {.fn rsample::{refused}} for the outer \\
         loop.",
        x = refused_design_reason(refused, "outer")
      ),
      class = "nestedtune_bad_design",
      call = call
    )
  }
  # A row subset or a manual_rset() rebuild loses the rset class these read,
  # but each split keeps its own (D-097).
  check_outer_splits(resamples, "resamples", call = call)
  # Before the rules that read row indices, which would otherwise refuse a bad
  # index under another reason, with a coercion warning, or pass it (M138,
  # D-111; M141, D-114).
  check_split_indices(resamples, call = call)
  # A split rebuilt with make_splits() carries no class to read, so each
  # split's rows are read next (M134, D-103).
  check_outer_overlap(resamples, "resamples", call = call)
  check_inner_refused(resamples, call = call)
  # The same rule on the inner splits, before the id rules, so a rebuilt
  # apparent split under the id "Apparent" is not told to take another id.
  check_inner_overlap(resamples, call = call)
  check_inner_ids(resamples, call = call)
  check_inner_apparent_ids(resamples, call = call)
  # Next the two class checks, which judge each element of the list columns;
  # the checks above judge the whole object or read element classes, except
  # the two overlap rules, which read split indexes but skip any element
  # that is not a well-formed rsplit (split_shares_rows()).
  # Neither column is checked by anything upstream: a
  # design whose `inside` produced no rset is refused by nested_resamples()
  # (M18) but built without complaint by rsample::nested_cv(), and nothing at
  # all guards `splits`. Left to the drivers, both shapes cost a full run and
  # come back as tune's per-fold notes rather than as the call error they are
  # -- the same reason check_grid_params() refuses a malformed grid (GP3).
  check_column_class(
    resamples,
    "splits",
    "rsplit",
    hint = "Designs from {.fn nested_resamples} and {.fn rsample::nested_cv} \\
            carry one {.cls rsplit} per outer fold.",
    call = call
  )
  # A different hint, because the parallel sentence would be false here for the
  # commonest way of reaching this error: rsample builds the design whatever
  # `inside` returned. Only nestedtune's own constructor refuses it (M18).
  check_column_class(
    resamples,
    "inner_resamples",
    "rset",
    hint = "{.fn rsample::nested_cv} builds the design whatever its \\
            {.arg inside} argument returned; {.fn nested_resamples} refuses an \\
            {.arg inside} that produces no {.cls rset} when the design is built.",
    call = call
  )
  # Last, the three rules that hold the design to what rsample's and tune's
  # readers expect of it (D-047): after the class checks, so each may assume
  # the elements it reads are what they claim to be.
  check_inner_rows(resamples, call = call)
  check_label_columns(resamples, labels, call = call)
  check_label_values(resamples, labels, call = call)
  # And the three over each fold's inner splits (M59), last of all: they read
  # inside the inner rsets the class rules vouched for.
  check_inner_splits(resamples, call = call)
  invisible(resamples)
}

# The rsample designs refused in either loop (M128, D-096): each gives no
# valid nested estimate there, and most fail every fold only after the whole
# loop has run. rsample::nested_cv() builds all six pairings.
refused_designs <- c("loo_cv", "apparent", "permutations")

# The refused design an rset (or anything else) carries, or NA. Class
# inspection only, so it is safe on an element no class check has vouched for.
refused_design <- function(x) {
  hit <- refused_designs[vapply(refused_designs, inherits, logical(1), x = x)]
  if (length(hit) == 0L) NA_character_ else hit[[1L]]
}

# Which of the two bootstraps an rset of class "bootstraps" is, by the
# function that built it.
bootstrap_design <- function(x) {
  if (inherits(x, "group_bootstraps")) "group_bootstraps" else "bootstraps"
}

# The split classes that mark a design refused in some loop (D-097), each
# with the function that builds it. `group_boot_split` comes first, because
# a group bootstrap's splits also carry `boot_split`.
refused_split_classes <- c(
  group_boot_split = "group_bootstraps",
  boot_split = "bootstraps",
  perm_split = "permutations",
  loo_split = "loo_cv",
  apparent_split = "apparent"
)

# The design each split of `x` comes from, by the split's class, or NA for a
# split whose class marks none. Class inspection only, so it is safe on an
# element no class check has vouched for: anything but a data frame with a
# list column of splits gives no designs.
split_designs <- function(x) {
  splits <- if (is.data.frame(x)) x[["splits"]]
  if (!is.list(splits)) {
    return(character())
  }
  found <- vapply(
    splits,
    function(split) {
      hit <- Filter(
        function(cls) inherits(split, cls),
        names(refused_split_classes)
      )
      if (length(hit) == 0L) {
        NA_character_
      } else {
        refused_split_classes[[hit[[1L]]]]
      }
    },
    character(1),
    USE.NAMES = FALSE
  )
  # bootstraps(), group_bootstraps() and permutations() add an apparent split
  # as an option, under the id "Apparent". Beside their splits, an apparent
  # split with that id belongs to that design, not to apparent(). Under any
  # other id tune scores it on the rows it trained on, so it stays apparent()
  # (D-099).
  host <- intersect(
    c("group_bootstraps", "bootstraps", "permutations"),
    found
  )
  if (length(host) > 0L) {
    found[found %in% "apparent" & apparent_ids(x)] <- host[[1L]]
  }
  found
}

# Whether each row of `x` carries the id that tune leaves out of its
# estimates. tune 2.1.0 keeps only the rows whose id is not "Apparent"
# (tune:::estimate_tune_results()), and its comparison reads a factor by its
# labels. It drops a split of any class under that id, so
# misread_apparent_rows() reads this too.
# An NA id is no match, and an id column that is missing or not one value per
# split marks no row.
apparent_ids <- function(x) {
  n <- length(x[["splits"]])
  ids <- x[["id"]]
  if (!is.atomic(ids) || length(ids) != n) {
    return(rep(FALSE, n))
  }
  as.character(ids) %in% "Apparent"
}

# Whether `x` holds an apparent split that its id alone keeps apart from the
# bootstrap splits beside it, which the inner refusal then says how to keep.
# Only a refusal that names apparent() as `design` gets the hint, so it never
# follows a bullet naming another design.
renamed_apparent <- function(x, design) {
  if (!identical(design, "apparent")) {
    return(FALSE)
  }
  found <- split_designs(x)
  any(found %in% "apparent") &&
    any(found %in% c("bootstraps", "group_bootstraps"))
}

apparent_id_hint <- paste(
  'tune leaves out an apparent split whose id is "Apparent", so a bootstrap',
  "keeps its apparent split only under that id."
)

# The rows of `x` whose id is "Apparent" but whose split is not the apparent
# split of a bootstrap design. tune leaves every row under that id out of its
# estimates, so a fold tuning on `x` would use fewer resamples than it holds,
# and nothing would say so (M132, D-100). Only a bootstrap's own apparent
# split carries the id on purpose, and split_designs() names that split's
# design as its bootstrap. The rule stands alone, although at entry and in
# the final fit an apparent split beside no bootstrap splits is refused as
# apparent() first (M133). Class inspection only, like split_designs().
misread_apparent_rows <- function(x) {
  splits <- if (is.data.frame(x)) x[["splits"]]
  if (!is.list(splits)) {
    return(integer())
  }
  which(apparent_ids(x) & !bootstrap_apparent(x))
}

# Whether each split of `x` is a bootstrap's own apparent split: of class
# `apparent_split`, and joined to the bootstrap splits beside it, which
# split_designs() does only under the id "Apparent". tune leaves that split
# out of its estimates, so misread_apparent_rows() and the inner rule on
# shared rows both exempt it (D-100, D-104). Class inspection only.
bootstrap_apparent <- function(x) {
  splits <- if (is.data.frame(x)) x[["splits"]]
  if (!is.list(splits)) {
    return(logical())
  }
  is_apparent <- vapply(splits, inherits, logical(1), "apparent_split")
  is_apparent & split_designs(x) %in% c("bootstraps", "group_bootstraps")
}

apparent_id_reason <- paste(
  'tune leaves every split whose id is "Apparent" out of its estimates, so',
  "each outer fold that tunes on it would use fewer resamples than its",
  "design holds. Give the split another id."
)

# The rows of `x` whose `id` is missing. tune 2.1.0 keeps the rows whose id
# is not "Apparent" (tune:::estimate_tune_results()), and that comparison
# gives NA for a missing id, so the split drops out of its estimate and an
# empty metric row joins it (M133, D-102). A factor whose NA is a level
# answers FALSE to is.na(), the comparison gives TRUE, and tune keeps the
# split, so it is not refused (D-105). Only `id` is read: tune filters on no
# other id column. Class inspection only, like split_designs().
missing_id_rows <- function(x) {
  splits <- if (is.data.frame(x)) x[["splits"]]
  ids <- if (is.data.frame(x)) x[["id"]]
  if (!is.list(splits) || !is.atomic(ids) || length(ids) != length(splits)) {
    return(integer())
  }
  which(is.na(ids))
}

# The rows of `x` that share their values in every id column with another
# row, read as labels. tune miscounts the resamples of such a design (M133,
# D-102). A repeated design's `id` repeats across `id2`, so only the whole
# set of id columns tells its splits apart. Two missing values compare equal,
# as tune treats them when it assembles its results: two NA `id2` values
# under one `id` gave 8 result rows for 6 splits (probed at M133). A factor's
# NA level reads as missing here too. A row whose `id` is NA is left to
# missing_id_rows().
repeated_id_rows <- function(x) {
  splits <- if (is.data.frame(x)) x[["splits"]]
  if (!is.list(splits)) {
    return(integer())
  }
  cols <- names(x)[is_id_name(names(x))]
  labels <- lapply(cols, function(col) x[[col]])
  fits <- vapply(
    labels,
    function(v) is.atomic(v) && length(v) == length(splits),
    logical(1)
  )
  if (length(cols) == 0L || !all(fits)) {
    return(integer())
  }
  values <- lapply(labels, as.character)
  names(values) <- cols
  repeated <- vctrs::vec_duplicate_detect(vctrs::new_data_frame(values))
  repeated[seq_along(splits) %in% missing_id_rows(x)] <- FALSE
  which(repeated)
}

# Why each id rule refuses, and what it costs where the design is tuned: each
# outer fold at entry, or the one tuning run of the final fit (M133).
id_rule_reason <- function(rule, final = FALSE) {
  if (identical(rule, "apparent") && !final) {
    return(apparent_id_reason)
  }
  what <- switch(
    rule,
    missing = "tune leaves a split with a missing id out of its estimates,",
    repeated = "tune miscounts the resamples of a design whose ids repeat,",
    apparent = paste(
      'tune leaves every split whose id is "Apparent" out of its',
      "estimates,"
    )
  )
  cost <- if (final) {
    "so the final fit would tune on"
  } else {
    "so each outer fold that tunes on it would use"
  }
  count <- switch(
    rule,
    repeated = "the wrong number of resamples.",
    "fewer resamples than its design holds."
  )
  fix <- switch(
    rule,
    missing = "Give every split an id.",
    repeated = "Give every split its own ids.",
    apparent = "Give the split another id."
  )
  paste(what, cost, count, fix)
}

# Every inner element holding a split with a missing id, and then every one
# holding splits whose ids repeat, each named in one message (M133, D-102).
check_inner_ids <- function(resamples, call = rlang::caller_env()) {
  inner <- resamples[["inner_resamples"]]
  if (!is.list(inner)) {
    return(invisible(resamples))
  }
  rules <- list(
    missing = list(
      rows = missing_id_rows,
      header = "{.arg resamples} has an inner split with a missing id.",
      holds = "a split whose {.field id} is missing."
    ),
    repeated = list(
      rows = repeated_id_rows,
      header = "{.arg resamples} has an inner design whose ids repeat.",
      holds = "splits that carry the same ids."
    )
  )
  for (rule in names(rules)) {
    spec <- rules[[rule]]
    hit <- which(lengths(lapply(inner, spec$rows)) > 0L)
    if (length(hit) == 0L) {
      next
    }
    n <- length(hit)
    reason <- id_rule_reason(rule)
    where <- cli::format_inline(paste(
      "{cli::qty(n)}Element{?s} {hit} of {.field inner_resamples}",
      "{cli::qty(n)}{?holds/hold}",
      spec$holds
    ))
    # Handed over as values, so cli does not parse the text again.
    cli::cli_abort(
      c(spec$header, x = "{where}", i = "{reason}"),
      class = "nestedtune_bad_design",
      call = call
    )
  }
  invisible(resamples)
}

# The two racers. finetune 1.3.0 eliminates race candidates on
# `tune::collect_metrics(summarize = FALSE)` (test_parameters_gls() and
# test_parameters_bt(), read 2026-09-29), which keeps the split whose id is
# "Apparent". So a race drops candidates on a score from the rows the model
# trained on, although tune's estimate leaves that split out (M132, D-100).
racer_tuners <- c("tune_race_anova", "tune_race_win_loss")

# Whether `x` holds an apparent split. Any id counts, because the race
# misreads an apparent split under any id. At a racer's entry, one under
# another id has already been refused as apparent(), but the map and the
# final fit read this with no entry check before it. Class inspection only,
# like split_designs().
holds_apparent_split <- function(x) {
  splits <- if (is.data.frame(x)) x[["splits"]]
  is.list(splits) &&
    any(vapply(splits, inherits, logical(1), "apparent_split"))
}

race_apparent_reason <- paste(
  "A race eliminates candidates on the score of every split it has run, and",
  "the score of an apparent split comes from the rows the model trained on.",
  "Build the bootstrap with `apparent = FALSE`."
)

# Every inner element holding an apparent split, for a racer's entry and for
# `nested_workflow_map()` before its first workflow runs. `resamples` may be
# anything, since the map reads it before any class check.
check_race_apparent <- function(resamples, call = rlang::caller_env()) {
  inner <- if (is.data.frame(resamples)) resamples[["inner_resamples"]]
  if (!is.list(inner)) {
    return(invisible(resamples))
  }
  hit <- which(vapply(inner, holds_apparent_split, logical(1)))
  if (length(hit) == 0L) {
    return(invisible(resamples))
  }
  n <- length(hit)
  # The reason is handed over as a value, so cli does not parse it again.
  cli::cli_abort(
    c(
      "{.arg resamples} has an inner design that a race would misread.",
      x = "{cli::qty(n)}Element{?s} {hit} of {.field inner_resamples} \\
           {cli::qty(n)}{?holds/hold} an apparent split.",
      i = "{race_apparent_reason}"
    ),
    class = "nestedtune_bad_design",
    call = call
  )
}

# The entry check's design rules, id rules and "Apparent" rules on the one
# inner rset `nested_final_fit()` rebuilds on the whole data (M132, D-100;
# M133, D-102). No entry check reads it: it comes from the
# recorded `inside`, which a record made before the rules, or an `inside`
# that labels the whole data differently, can turn into such a design.
check_final_inner <- function(inner, tuner, call = rlang::caller_env()) {
  # The entry check's rules, in its order (M133, D-102): the refused designs
  # and the rule on an apparent split beside bootstrap splits, then the rule
  # on shared rows (M134, D-103), then the two id rules, then the two
  # "Apparent" rules. No reason names an outer fold, since
  # the rebuilt design belongs to none: a design refused by its rset class
  # and each id rule speak of the final fit's one tuning run, and a design
  # found by its split classes gets its own flaw, as at entry.
  refused <- inner_refused_design(inner)
  if (!is.na(refused)) {
    hint <- if (renamed_apparent(inner, refused)) {
      c(i = "{apparent_id_hint}")
    }
    reason <- inner_refused_reason(inner, refused, final = TRUE)
    cli::cli_abort(
      c(
        "The design's inner resampling specification gave \\
         {.fn rsample::{refused}} splits.",
        x = reason,
        hint
      ),
      class = "nestedtune_bad_design",
      call = call
    )
  }
  # The rebuilt design indexes the whole data, so its indexes are data rows.
  shared <- inner_overlap_rows(inner)
  if (length(shared) > 0L) {
    n <- length(shared)
    reason <- inner_overlap_reason(final = TRUE)
    cli::cli_abort(
      c(
        "The design's inner resampling specification gave a split whose \\
         analysis and assessment sets share rows.",
        x = "{cli::qty(n)}Split{?s} {shared} of the rebuilt design \\
             {cli::qty(n)}{?shares/share} rows.",
        i = "{reason}",
        lag_hint(list(inner))
      ),
      class = "nestedtune_bad_design",
      call = call
    )
  }
  if (length(missing_id_rows(inner)) > 0L) {
    cli::cli_abort(
      c(
        "The design's inner resampling specification gave a split with a \\
         missing id.",
        x = "{id_rule_reason('missing', final = TRUE)}"
      ),
      class = "nestedtune_bad_design",
      call = call
    )
  }
  if (length(repeated_id_rows(inner)) > 0L) {
    cli::cli_abort(
      c(
        "The design's inner resampling specification gave splits whose ids \\
         repeat.",
        x = "{id_rule_reason('repeated', final = TRUE)}"
      ),
      class = "nestedtune_bad_design",
      call = call
    )
  }
  if (length(misread_apparent_rows(inner)) > 0L) {
    cli::cli_abort(
      c(
        "The design's inner resampling specification gave a split under the \\
         id {.val Apparent} that is not the apparent split of a bootstrap.",
        x = "{id_rule_reason('apparent', final = TRUE)}"
      ),
      class = "nestedtune_bad_design",
      call = call
    )
  }
  if (tuner %in% racer_tuners && holds_apparent_split(inner)) {
    cli::cli_abort(
      c(
        "The design's inner resampling specification gave an apparent split, \\
         which the race cannot use.",
        x = "{race_apparent_reason}"
      ),
      class = "nestedtune_bad_design",
      call = call
    )
  }
  invisible(inner)
}

# Every inner element holding a split that misread_apparent_rows() finds, so
# one message names every offending outer fold.
check_inner_apparent_ids <- function(resamples, call = rlang::caller_env()) {
  inner <- resamples[["inner_resamples"]]
  hit <- which(lengths(lapply(inner, misread_apparent_rows)) > 0L)
  if (length(hit) == 0L) {
    return(invisible(resamples))
  }
  n <- length(hit)
  # The reason is handed over as a value, so cli does not parse it again.
  cli::cli_abort(
    c(
      "{.arg resamples} has an inner split that tune would leave out of its \\
       estimates.",
      x = "{cli::qty(n)}Element{?s} {hit} of {.field inner_resamples} \\
           {cli::qty(n)}{?holds/hold} a split under the id {.val Apparent} \\
           that is not the apparent split of a bootstrap.",
      i = "{apparent_id_reason}"
    ),
    class = "nestedtune_bad_design",
    call = call
  )
}

# The design an inner rset (or anything else) carries that the inner loop
# refuses, or NA. The rset class decides first; only if it names none are the
# split classes read (D-097), the first refused one naming the design.
inner_refused_design <- function(x) {
  by_class <- refused_design(x)
  if (!is.na(by_class)) {
    return(by_class)
  }
  found <- split_designs(x)
  found <- found[found %in% refused_designs]
  if (length(found) == 0L) NA_character_ else found[[1L]]
}

# Why the inner loop refuses `design` in `x`. tune refuses these designs by
# their rset class alone, so a design found by its split classes would run in
# tune. For such a design the reason is the design's own flaw, which is the
# one the outer loop gives.
inner_refused_reason <- function(x, design, final = FALSE) {
  role <- if (is.na(refused_design(x))) {
    "outer"
  } else if (final) {
    "final"
  } else {
    "inner"
  }
  refused_design_reason(design, role)
}

# Every outer split whose class marks a design the outer loop refuses, grouped
# by design, so one message names every offending row. `arg` names the
# argument the design came in as.
check_outer_splits <- function(x, arg, call = rlang::caller_env()) {
  found <- split_designs(x)
  if (all(is.na(found))) {
    return(invisible(x))
  }
  lines <- vapply(
    unique(found[!is.na(found)]),
    function(design) {
      rows <- which(found == design)
      n <- length(rows)
      where <- paste(
        "{cli::qty(n)}Row{?s} {rows} of {.arg {arg}}",
        "{cli::qty(n)}{?holds a/hold} {.fn rsample::{design}}",
        "{cli::qty(n)}split{?s}."
      )
      paste(
        cli::format_inline(where),
        cli::format_inline(refused_design_reason(design, "outer"))
      )
    },
    character(1)
  )
  # Handed over as values, so cli does not parse the formatted text again.
  bullets <- rlang::set_names(
    sprintf("{lines[[%d]]}", seq_along(lines)),
    rep("x", length(lines))
  )
  cli::cli_abort(
    c(
      "{.arg {arg}} has splits from a design the outer loop cannot use.",
      bullets
    ),
    class = "nestedtune_bad_design",
    call = call
  )
}

# Whether the assessment set of `split` holds a row of its analysis set (M134,
# D-103). `rows` gives the data row each index of the split's frame stands
# for: NULL when the frame is the data, or the outer split's `in_id` when it
# is that split's analysis set, so a row the outer split repeats is caught
# under both of its positions. The assessment set is rsample::complement()'s,
# which reads each split class's own rule. Anything malformed shares no row
# here and is left to the checks that judge it. `hold`, when given, marks the
# data rows the outer split holds, and a shared row outside it is left to the
# containment rule of check_inner_splits(), which names the leak (M135,
# D-109).
split_shares_rows <- function(
  split,
  rows = NULL,
  hold = NULL,
  repeats = !is.null(rows) && anyDuplicated(rows) > 0L
) {
  if (
    !inherits(split, "rsplit") ||
      !is.list(split) ||
      !is.data.frame(split[["data"]])
  ) {
    return(FALSE)
  }
  n <- nrow(split[["data"]])
  # An NA in `rows`, from an outer `in_id` holding NA, names no data row, so
  # such a fold is left as found (M134 review, S1).
  if (!is.null(rows) && (length(rows) != n || anyNA(rows))) {
    return(FALSE)
  }
  default <- identical(split[["out_id"]], NA) && complement_is_default(split)
  # rsample's rsplit method gives every frame row outside `in_id` here,
  # which shares no frame row with it; only a row that `rows` repeats can.
  # `repeats` says whether `rows` repeats one, which overlap_rows() finds once
  # for a fold rather than once for each split (M135, T5).
  if (default && !repeats) {
    return(FALSE)
  }
  in_frame <- function(idx) {
    is.numeric(idx) && !anyNA(idx) && all(idx >= 1L & idx <= n)
  }
  trained <- split[["in_id"]]
  if (!in_frame(trained)) {
    return(FALSE)
  }
  if (default) {
    # The same set for any nonempty `in_id`, which rsample::rsplit()
    # requires, found without the unique() that method hashes the training
    # rows with, which dominated this check's time (M134, T5). An empty
    # `in_id` gives FALSE either way.
    outside <- rep(TRUE, n)
    outside[trained] <- FALSE
    held_out <- which(outside)
  } else {
    held_out <- tryCatch(
      rsample::complement(split),
      error = function(cnd) NULL
    )
  }
  if (!in_frame(held_out)) {
    return(FALSE)
  }
  if (!is.null(rows)) {
    trained <- rows[trained]
    held_out <- rows[held_out]
  }
  # A marked vector rather than %in%, which hashes the training rows anew
  # for every split (M134, T5).
  seen <- logical(max(c(0L, trained, held_out)))
  seen[trained] <- TRUE
  if (is.null(hold)) {
    return(any(seen[held_out]))
  }
  shared <- held_out[seen[held_out]]
  any(hold[shared] %in% TRUE)
}

# Whether rsample::complement() reaches its rsplit method for `split`: no
# class ahead of "rsplit" has a complement method where dispatch looks for
# one (complement_envs()).
complement_is_default <- function(split) {
  cls <- class(split)
  ahead <- cls[seq_len(match("rsplit", cls) - 1L)]
  if (length(ahead) == 0L) {
    return(TRUE)
  }
  envs <- complement_envs()
  !any(vapply(
    paste0("complement.", ahead),
    function(name) {
      any(vapply(
        envs,
        function(env) {
          exists(name, envir = env, mode = "function", inherits = FALSE)
        },
        logical(1)
      ))
    },
    logical(1)
  ))
}

# The environments where S3 dispatch finds a complement() method for a call
# from rsample's code, as the one assessment() makes for tune: rsample's
# namespace and the parents of it up to the global environment, rsample's
# table of registered methods (the apparent, rolling-origin and sliding
# splits, and any other package's), and base. Dispatch skips the search path
# between the global environment and base, so a method in an attached
# environment is never called and is not looked for (M135).
complement_envs <- function() {
  ns <- asNamespace("rsample")
  envs <- list(ns[[".__S3MethodsTable__."]])
  env <- ns
  while (!identical(env, globalenv()) && !identical(env, emptyenv())) {
    envs <- c(envs, env)
    env <- parent.env(env)
  }
  c(envs, globalenv(), baseenv())
}

# The positions of the splits of `x` that share rows, for split_shares_rows()
# with the same `rows` and `hold`. It reads each split's indexes, but like
# split_designs() it is safe on an element no class check has vouched for.
overlap_rows <- function(x, rows = NULL, hold = NULL) {
  splits <- if (is.data.frame(x)) x[["splits"]]
  if (!is.list(splits)) {
    return(integer())
  }
  which(vapply(
    splits,
    split_shares_rows,
    logical(1),
    rows = rows,
    hold = hold,
    repeats = !is.null(rows) && anyDuplicated(rows) > 0L
  ))
}

# rsample::rolling_origin() starts each assessment set `lag` rows before its
# analysis set ends, so it holds `assess + lag` rows (rsample 1.3.2). With
# `lag` above 0 each split shares its last `lag` analysis rows. tune scores
# them, so the rule refuses it, and the message says how to keep the lagged
# predictors (M134, R1).
lag_advice <- paste(
  "A `rsample::rolling_origin()` design with `lag` above 0 puts the last",
  "`lag` analysis rows of each split in its assessment set. Use `lag = 0`,",
  "and build the lagged predictors before resampling."
)

# The hint for `rsets`, the designs whose splits a refusal names: NULL unless
# one is a rolling_origin() design whose `lag` attribute is above 0. A
# design rebuilt with manual_rset() carries no lag, so it gets no hint.
lag_hint <- function(rsets) {
  lagged <- vapply(
    rsets,
    function(x) {
      lag <- attr(x, "lag", exact = TRUE)
      inherits(x, "rolling_origin") && is.numeric(lag) && isTRUE(lag > 0)
    },
    logical(1)
  )
  if (any(lagged)) {
    c(i = "{lag_advice}")
  }
}

outer_overlap_reason <- paste(
  "Such a fold scores the model on rows it trained on, so the nested",
  "estimate would not measure performance on new data."
)

# Why an inner split that shares rows is refused: at entry, for every outer
# fold, which nested_fit_resamples() fits without tuning, or for the one
# tuning run of the final fit.
inner_overlap_reason <- function(final = FALSE) {
  cost <- if (final) {
    "so the final fit would rank candidates partly on those rows."
  } else {
    paste(
      "so the inner results of each outer fold that uses it would rest",
      "partly on those rows."
    )
  }
  paste("Such a split scores the model on rows it trained on,", cost)
}

# The inner splits of `x` that share rows, less a bootstrap's own apparent
# split, which tune leaves out of its estimates (D-104). Under the two
# racers the race rule still refuses that split.
inner_overlap_rows <- function(x, rows = NULL, hold = NULL) {
  setdiff(overlap_rows(x, rows, hold), which(bootstrap_apparent(x)))
}

# The same, for the inner design of one outer fold of a design that may have
# been built anywhere. Its splits index the outer split's own frame or that
# split's analysis set, told apart as check_inner_splits() tells them, and
# the second are read through the outer `in_id`. On the outer frame, only a
# shared row the outer `in_id` holds counts: a held-out row is left to the
# containment rule, which names the leak (M135, D-109). A fold whose splits
# are not all rsplits, or whose frames are another or disagree, is left to
# check_inner_splits().
fold_overlap_rows <- function(split, inner) {
  splits <- if (is.data.frame(inner)) inner[["splits"]]
  is_split <- function(s) inherits(s, "rsplit") && is.list(s)
  if (
    !is_split(split) ||
      !is.list(splits) ||
      !all(vapply(splits, is_split, logical(1)))
  ) {
    return(integer())
  }
  kind <- unique(inner_frame_kinds(split, lapply(splits, `[[`, "data")))
  if (length(kind) != 1L || identical(kind, "other")) {
    return(integer())
  }
  if (identical(kind, "analysis")) {
    return(inner_overlap_rows(inner, as.integer(split[["in_id"]])))
  }
  frame <- split[["data"]]
  if (!is.data.frame(frame)) {
    return(integer())
  }
  outer_in <- suppressWarnings(as.integer(split[["in_id"]]))
  outer_in <- outer_in[!is.na(outer_in) & outer_in >= 1L]
  hold <- logical(nrow(frame))
  hold[outer_in[outer_in <= nrow(frame)]] <- TRUE
  inner_overlap_rows(inner, hold = hold)
}

# Every inner element holding a split that shares rows, grouped by the
# splits found, so one message names every offending outer fold.
check_inner_overlap <- function(resamples, call = rlang::caller_env()) {
  outer <- resamples[["splits"]]
  inner <- resamples[["inner_resamples"]]
  if (!is.list(outer) || !is.list(inner)) {
    return(invisible(resamples))
  }
  found <- Map(fold_overlap_rows, outer, inner)
  hit <- which(lengths(found) > 0L)
  if (length(hit) == 0L) {
    return(invisible(resamples))
  }
  key <- vapply(found[hit], paste, character(1), collapse = " ")
  lines <- vapply(
    unique(key),
    function(k) {
      elements <- hit[key == k]
      pos <- found[[elements[[1L]]]]
      cli::format_inline(paste(
        "{cli::qty(length(elements))}Element{?s} {elements} of",
        "{.field inner_resamples}: {cli::qty(length(pos))}split{?s} {pos}."
      ))
    },
    character(1),
    USE.NAMES = FALSE
  )
  # Handed over as values, so cli does not parse the formatted text again.
  bullets <- rlang::set_names(
    sprintf("{lines[[%d]]}", seq_along(lines)),
    rep("x", length(lines))
  )
  reason <- inner_overlap_reason()
  cli::cli_abort(
    c(
      "{.arg resamples} has an inner split whose analysis and assessment \\
       sets share rows.",
      bullets,
      i = "{reason}",
      lag_hint(inner[hit])
    ),
    class = "nestedtune_bad_design",
    call = call
  )
}

# Every outer split that shares rows, in one message. `arg` names the
# argument the design came in as. An apparent split shares every row, but
# check_outer_splits() has refused it by its class before this runs.
check_outer_overlap <- function(x, arg, call = rlang::caller_env()) {
  rows <- overlap_rows(x)
  if (length(rows) == 0L) {
    return(invisible(x))
  }
  n <- length(rows)
  # The reason is handed over as a value, so cli does not parse it again.
  cli::cli_abort(
    c(
      "{.arg {arg}} has a split whose analysis and assessment sets share \\
       rows.",
      x = "{cli::qty(n)}Row{?s} {rows} of {.arg {arg}} \\
           {cli::qty(n)}{?holds such a split/hold such splits}.",
      i = "{outer_overlap_reason}",
      lag_hint(list(x))
    ),
    class = "nestedtune_bad_design",
    call = call
  )
}

# The shape of index slot `x`, which is `slot` of a split, if the index rule
# refuses it, or NA. The first shape that applies names it: an NA, an empty
# `out_id`, a vector that is not numeric, a value outside integer range. An
# `out_id` identical to the logical NA is rsample's mark for the complement
# and is exempt (M138, D-111; M141, D-114).
index_shape <- function(x, slot) {
  if (slot == "out_id" && identical(x, NA)) {
    return(NA_character_)
  }
  if (anyNA(x)) {
    return("na")
  }
  if (slot == "out_id" && length(x) == 0L) {
    return("empty")
  }
  if (!is.numeric(x)) {
    return("type")
  }
  if (anyNA(suppressWarnings(as.integer(x)))) {
    return("range")
  }
  NA_character_
}

# The refused shape of each slot of `split`, named by slot, for the slots the
# rule refuses. An element that is not a list with the rsplit class gives
# none: the class rules refuse it later.
bad_index_slots <- function(split) {
  if (!inherits(split, "rsplit") || !is.list(split)) {
    return(character())
  }
  shapes <- c(
    in_id = index_shape(split[["in_id"]], "in_id"),
    out_id = index_shape(split[["out_id"]], "out_id")
  )
  shapes[!is.na(shapes)]
}

# The line naming the refused slots of `split`, after `pos`, or nothing when
# the rule refuses none. Slots with one shape share a clause. `pos` is handed
# over as a value.
index_line <- function(split, pos) {
  shapes <- bad_index_slots(split)
  if (length(shapes) == 0L) {
    return(character())
  }
  parts <- character()
  for (shape in c("na", "empty", "type", "range")) {
    slots <- names(shapes)[shapes == shape]
    n <- length(slots)
    if (n == 0L) {
      next
    }
    words <- switch(
      shape,
      na = "{cli::qty(n)}hold{?s/} an {.code NA}",
      empty = "{cli::qty(n)}{?is/are} empty",
      type = "{cli::qty(n)}{?is not a numeric vector/are not numeric vectors}",
      range = "{cli::qty(n)}{?holds a value/hold values} outside integer range"
    )
    parts <- c(parts, cli::format_inline(paste("{.field {slots}}", words)))
  }
  paste0(pos, ": ", paste(parts, collapse = ", and "), ".")
}

index_reason <- paste(
  "Each row index must be a number within integer range. An NA index names",
  "no data row: rsample reads it as rows of NAs, or fails when it builds the",
  "assessment set. An empty `out_id` leaves the split no assessment set. The",
  "one exception is an `out_id` that is the logical NA, which tells rsample",
  "to find the assessment set with `rsample::complement()`."
)

abort_bad_indices <- function(lines, arg, call) {
  if (length(lines) == 0L) {
    return(invisible())
  }
  # The reason is handed over as a value, so cli does not parse it again.
  cli::cli_abort(
    c(
      "{.arg {arg}} has a split whose row indices are not valid row numbers.",
      value_bullets(lines),
      i = "{index_reason}"
    ),
    class = "nestedtune_bad_design",
    call = call
  )
}

# Every outer and inner split the index rule refuses, in one message, each
# named by its outer fold and, for an inner split, its position in that fold.
check_split_indices <- function(resamples, call = rlang::caller_env()) {
  outer <- resamples[["splits"]]
  inner <- resamples[["inner_resamples"]]
  if (!is.list(outer)) {
    return(invisible(resamples))
  }
  lines <- lapply(seq_along(outer), function(f) {
    rs <- if (is.list(inner)) inner[[f]]
    splits <- if (is.data.frame(rs)) rs[["splits"]]
    inner_lines <- if (is.list(splits)) {
      lapply(seq_along(splits), function(s) {
        index_line(splits[[s]], paste0("Outer fold ", f, ", inner split ", s))
      })
    }
    c(index_line(outer[[f]], paste("Outer fold", f)), unlist(inner_lines))
  })
  abort_bad_indices(unlist(lines), "resamples", call)
  invisible(resamples)
}

# The outer half of the rule, for the design `nested_resamples()` takes as
# `outside`, whose splits are named by row as check_outer_overlap() names
# them.
check_outer_indices <- function(x, arg, call = rlang::caller_env()) {
  splits <- x[["splits"]]
  lines <- lapply(seq_along(splits), function(f) {
    index_line(splits[[f]], cli::format_inline("Row {f} of {.arg {arg}}"))
  })
  abort_bad_indices(unlist(lines), arg, call)
  invisible(x)
}

# Why `design` is refused in `role`, naming the rsample function. The reasons
# are the ones the "Differences from rsample" section of ?nested_resamples
# gives. Built with paste(), not a line continuation, because
# cli::format_inline() keeps the backslash.
refused_design_reason <- function(design, role) {
  switch(
    paste(role, design),
    "outer loo_cv" = paste(
      "{.fn rsample::loo_cv} holds out one row per fold, so R-squared cannot",
      "be computed and the averaged RMSE is the mean absolute error."
    ),
    "outer apparent" = paste(
      "{.fn rsample::apparent} scores its one fold on the rows it trained on."
    ),
    "outer permutations" = paste(
      "{.fn rsample::permutations} gives each fold no assessment set."
    ),
    "outer bootstraps" = paste(
      "{.fn rsample::bootstraps} can put the same row in both the inner",
      "analysis and inner assessment set, so the nested estimate would be",
      "invalid."
    ),
    "outer group_bootstraps" = paste(
      "{.fn rsample::group_bootstraps} can put the same row in both the inner",
      "analysis and inner assessment set, so the nested estimate would be",
      "invalid."
    ),
    "inner loo_cv" = paste(
      "tune refuses {.fn rsample::loo_cv} as a tuning design, so each outer",
      "fold that tunes on it would fail."
    ),
    "inner apparent" = paste(
      "tune reports no results for {.fn rsample::apparent}, so each outer",
      "fold that tunes on it would fail."
    ),
    "inner permutations" = paste(
      "tune refuses {.fn rsample::permutations} as a tuning design, so each",
      "outer fold that tunes on it would fail."
    ),
    # The design nested_final_fit() rebuilds on the whole data (M133).
    "final loo_cv" = paste(
      "tune refuses {.fn rsample::loo_cv} as a tuning design, so the final",
      "fit would fail."
    ),
    "final apparent" = paste(
      "tune reports no results for {.fn rsample::apparent}, so the final fit",
      "would fail."
    ),
    "final permutations" = paste(
      "tune refuses {.fn rsample::permutations} as a tuning design, so the",
      "final fit would fail."
    )
  )
}

# Every inner element carrying a refused design, by its rset class or by its
# split classes, grouped by design and by the reason given, so one message
# names every offending outer fold. An element that is not a data frame of
# splits carries none and is left to the column class check below.
check_inner_refused <- function(resamples, call = rlang::caller_env()) {
  inner <- resamples[["inner_resamples"]]
  found <- vapply(inner, inner_refused_design, character(1))
  if (all(is.na(found))) {
    return(invisible(resamples))
  }
  reasons <- rep(NA_character_, length(found))
  hit <- which(!is.na(found))
  reasons[hit] <- vapply(
    hit,
    function(i) inner_refused_reason(inner[[i]], found[[i]]),
    character(1)
  )
  key <- paste(found, reasons)
  lines <- vapply(
    unique(key[hit]),
    function(k) {
      bad <- which(key == k)
      n <- length(bad)
      design <- found[[bad[[1L]]]]
      where <- paste(
        "{cli::qty(n)}Element{?s} {bad} of {.field inner_resamples}",
        "{cli::qty(n)}{?holds/hold} {.fn rsample::{design}} splits."
      )
      paste(
        cli::format_inline(where),
        cli::format_inline(reasons[[bad[[1L]]]])
      )
    },
    character(1)
  )
  # Handed over as values, so cli does not parse the formatted text again.
  bullets <- rlang::set_names(
    sprintf("{lines[[%d]]}", seq_along(lines)),
    rep("x", length(lines))
  )
  # The hint is handed over as a value too, since it holds no cli markup.
  hint <- if (any(mapply(renamed_apparent, inner[hit], found[hit]))) {
    c(i = "{apparent_id_hint}")
  }
  cli::cli_abort(
    c(
      "{.arg resamples} has an inner design that tuning cannot use.",
      bullets,
      hint
    ),
    class = "nestedtune_bad_design",
    call = call
  )
}

# The names under which rsample's and tune's readers find a design's id
# columns: both packages' col_starts_with_id() is grepl() on this pattern
# (rsample 1.3.2, tune 2.1.0), so a label column named outside it is one
# tune's own summaries would ignore. Used by the entry check and by the
# inner repeated-id rule, which `nested_resamples()` and the final fit also
# run; the results class reads its labels from the record D-036 fixed, never
# by name.
is_id_name <- function(x) {
  grepl("(^id$)|(^id[1-9]$)", x)
}

# One list column, every element, reporting all that are wrong. Class
# inspection only -- nothing here evaluates or draws, so it stays safe to run
# before the seeds are taken.
check_column_class <- function(
  resamples,
  column,
  class,
  hint,
  arg = "resamples",
  call = rlang::caller_env()
) {
  lines <- malformed_lines(resamples[[column]], class, "Element")
  if (length(lines) == 0L) {
    return(invisible(resamples))
  }
  cli::cli_abort(
    c(
      "{.arg {arg}} has a malformed {.field {column}} column.",
      value_bullets(lines),
      i = hint
    ),
    class = "nestedtune_bad_design",
    call = call
  )
}

# The lines naming each element of `elements` that is not a well-formed
# `class` object, `noun` naming one element and `after` following its
# position: first those that lack the class, then those that carry it but
# are not a list. Every reader of a split takes it to be the list rsample
# builds, so such an element would crash the first one (M135). Empty when
# every element is well formed.
malformed_lines <- function(elements, class, noun, after = "") {
  has_class <- vapply(elements, inherits, logical(1), class)
  wrong <- which(!has_class)
  atomic <- which(has_class & !vapply(elements, is.list, logical(1)))
  types <- vapply(
    elements[wrong],
    function(e) cli::format_inline("{.obj_type_friendly {e}}"),
    character(1)
  )
  n <- length(wrong)
  m <- length(atomic)
  c(
    if (n > 0L) {
      cli::format_inline(paste0(
        "{noun}{cli::qty(n)}{?s} {wrong}{after} {cli::qty(n)}{?is/are} ",
        "{types}, not {.cls {class}}."
      ))
    },
    if (m > 0L) {
      cli::format_inline(paste0(
        "{noun}{cli::qty(m)}{?s} {atomic}{after} {cli::qty(m)}{?has/have} ",
        "class {.cls {class}} but {cli::qty(m)}{?is not a list/are not lists}."
      ))
    }
  )
}

# Formatted `lines` as "x" bullets, their braces doubled so cli does not
# parse the text again.
value_bullets <- function(lines) {
  rlang::set_names(gsub("([{}])", "\\1\\1", lines), rep("x", length(lines)))
}

# An inner design with no rows gives its fold nothing to tune on; tune would
# fail that fold after the run with its own message rather than at the call.
check_inner_rows <- function(resamples, call = rlang::caller_env()) {
  rows <- vapply(resamples[["inner_resamples"]], nrow, integer(1))
  bad <- which(rows == 0L)
  if (length(bad) == 0L) {
    return(invisible(resamples))
  }
  n <- length(bad)
  cli::cli_abort(
    c(
      "{.arg resamples} has an inner design with no rows.",
      x = "{cli::qty(n)}Element{?s} {bad} of {.field inner_resamples} \\
           {cli::qty(n)}{?holds/hold} no resamples, so \\
           {cli::qty(n)}{?that outer fold has/those outer folds have} \\
           nothing to tune on.",
      i = "Every outer fold needs an inner {.cls rset} with at least one row."
    ),
    class = "nestedtune_bad_design",
    call = call
  )
}

# Every label column must be one rsample's readers would find (is_id_name())
# and hold the character or factor values a fold label is. A column failing
# either rule would otherwise be pasted into every fold's label, or ignored by
# tune's summaries, without a word (D-047).
check_label_columns <- function(
  resamples,
  labels,
  call = rlang::caller_env()
) {
  bad_name <- !is_id_name(labels)
  bad_type <- !vapply(
    labels,
    function(col) is.character(resamples[[col]]) || is.factor(resamples[[col]]),
    logical(1)
  )
  offenders <- which(bad_name | bad_type)
  if (length(offenders) == 0L) {
    return(invisible(resamples))
  }
  n <- length(offenders)
  bullets <- vapply(
    offenders,
    function(i) {
      col <- labels[[i]]
      reasons <- c(
        if (bad_name[[i]]) "is not named as rsample names an id column",
        if (bad_type[[i]]) {
          cli::format_inline(
            "is {.obj_type_friendly {resamples[[col]]}}, not character or factor"
          )
        }
      )
      cli::format_inline("{.field {col}} {paste(reasons, collapse = ' and ')}.")
    },
    character(1)
  )
  cli::cli_abort(
    c(
      "{.arg resamples} has {cli::qty(n)}{?a column/columns} that cannot \\
       label its outer folds.",
      stats::setNames(bullets, rep("x", n)),
      i = "Every column beside {.field splits} and {.field inner_resamples} \\
           labels the outer folds. A label column is named {.code id}, or \\
           {.code id2} through {.code id9}, as rsample's readers find them, \\
           and holds character or factor values."
    ),
    class = "nestedtune_bad_design",
    call = call
  )
}

# An NA label leaves a fold's rows unattributable in the results object, and
# a label two rows share makes autoplot() abort on the fitted run (D-047);
# both are refused before anything is fitted.
check_label_values <- function(
  resamples,
  labels,
  call = rlang::caller_env()
) {
  # Read as labels, not as factors: a factor whose NA is a level (addNA())
  # answers FALSE to is.na() but labels the fold with nothing all the same.
  values <- lapply(labels, function(col) as.character(resamples[[col]]))
  names(values) <- labels
  missing <- Reduce(`|`, lapply(values, is.na))
  repeated <- vctrs::vec_duplicate_detect(vctrs::new_data_frame(values))
  # A row with an NA is reported as such, not also as a repeat of another.
  repeated[missing] <- FALSE
  if (!any(missing) && !any(repeated)) {
    return(invisible(resamples))
  }
  na_rows <- which(missing)
  n_na <- length(na_rows)
  n_labels <- length(labels)
  # Headed by what was found: missingness alone is not a uniqueness failure.
  header <- if (n_na > 0L && any(repeated)) {
    "{.arg resamples} has missing and repeated outer fold labels."
  } else if (n_na > 0L) {
    "{.arg resamples} has {cli::qty(n_na)}{?a missing outer fold label/missing \\
     outer fold labels}."
  } else {
    "{.arg resamples} does not label every outer fold uniquely."
  }
  cli::cli_abort(
    c(
      header,
      x = if (n_na > 0L) {
        "{cli::qty(n_na)}Row{?s} {na_rows} {cli::qty(n_na)}{?has/have} an \\
         {.code NA} label."
      },
      x = if (any(repeated)) {
        "Rows {which(repeated)} carry the same label as another row."
      },
      i = "Each outer fold's label -- its {.field {labels}} \\
           {cli::qty(n_labels)}{?value/values together} -- must be distinct \\
           and not missing: the results object names the fold by it."
    ),
    class = "nestedtune_bad_design",
    call = call
  )
}

# The three rules over a fold's inner splits (M59). Every element of a fold's
# inner `splits` list is an rsplit; every inner split of a fold carries one
# frame, either the outer split's own (`nested_resamples()` remaps its inner
# indices onto the caller's data) or that split's analysis set
# (`rsample::nested_cv()` builds the inner design on it); and an inner split
# carrying the outer frame indexes only rows in the outer `in_id` -- an inner
# analysis or assessment set reaching an outer assessment row is the leak IP1
# forbids, and a hand-built one ran to completion unrefused before this
# (probed 2026-09-04). Before, an inner design over another frame was admitted
# and sent down the parallel fat path (D-047's consequence, superseded by
# D-049); `is_fold_payload()` keeps that gate for the stand-in payloads the
# dispatch tests drive, and as defence in depth.
#
# `identical()` against the outer frame first -- pointer equality on a
# `nested_resamples()` design, so the common case costs nothing -- and against
# `rsample::analysis()` only for a fold whose outer indices lie in its frame:
# an outer `in_id` reaching past the data is left to `last_fit()` (M54), and
# `analysis()` would raise here instead. No frame reaches a message (the
# M05/M45 lesson); every bullet names positions. A rule that finds an offender
# refuses before the next rule reads what it would have judged.
check_inner_splits <- function(resamples, call = rlang::caller_env()) {
  outer <- resamples[["splits"]]
  inner <- resamples[["inner_resamples"]]
  n <- length(outer)
  x_bullets <- function(bullets) {
    stats::setNames(bullets, rep("x", length(bullets)))
  }

  # An element that carries the class but is not a list counts as not an
  # rsplit, since every rule below reads it as one (M135).
  not_rsplit <- lapply(inner, function(rs) {
    malformed_lines(rs[["splits"]], "rsplit", "inner split")
  })
  bad <- which(lengths(not_rsplit) > 0L)
  if (length(bad) > 0L) {
    bullets <- unlist(lapply(bad, function(f) {
      paste0("Outer fold ", f, ": ", not_rsplit[[f]])
    }))
    cli::cli_abort(
      c(
        "{.arg resamples} has an inner split that is not an {.cls rsplit}.",
        value_bullets(bullets),
        i = "Every element of an inner design's {.field splits} column is one \\
             {.cls rsplit}, as {.fn rsample::vfold_cv} and its kin build them."
      ),
      class = "nestedtune_bad_design",
      call = call
    )
  }

  # Which frame each inner split carries (inner_frame_kinds()). A fold's
  # splits must all carry the outer split's own frame or its analysis set.
  # A fold whose splits all carry another frame gets one bullet; a fold whose
  # splits disagree names every split with what it carries, the ones on
  # another frame first.
  whole <- vector("list", n)
  kind <- vector("list", n)
  for (f in seq_len(n)) {
    split <- outer[[f]]
    frames <- lapply(inner[[f]][["splits"]], function(s) s[["data"]])
    whole[[f]] <- vapply(frames, identical, logical(1), split[["data"]])
    kind[[f]] <- inner_frame_kinds(split, frames)
  }
  disagrees <- function(k) {
    !is.null(k) && (any(k == "other") || length(unique(k)) > 1L)
  }
  bad <- which(vapply(kind, disagrees, logical(1)))
  if (length(bad) > 0L) {
    carries <- c(
      other = "a frame that is neither the outer split's own nor its analysis set",
      analysis = "the outer split's analysis set",
      whole = "the outer split's own frame"
    )
    bullets <- vapply(
      bad,
      function(f) {
        k <- kind[[f]]
        if (all(k == "other")) {
          return(cli::format_inline(paste(
            "Outer fold {f}: every inner split carries a frame that is",
            "neither the outer split's own nor its analysis set."
          )))
        }
        parts <- vapply(
          names(carries)[names(carries) %in% k],
          function(name) {
            pos <- which(k == name)
            cli::format_inline(paste0(
              "inner {cli::qty(length(pos))}split{?s} {pos} ",
              "{cli::qty(length(pos))}carr{?ies/y} {carries[[name]]}"
            ))
          },
          character(1)
        )
        cli::format_inline("Outer fold {f}: {paste(parts, collapse = '; ')}.")
      },
      character(1)
    )
    cli::cli_abort(
      c(
        "{.arg resamples} has inner splits built on a frame that is not their \\
         outer fold's.",
        x_bullets(bullets),
        i = "Every inner split of an outer fold indexes one frame: the data \\
             the outer split holds, as {.fn nested_resamples} builds them, or \\
             that split's analysis set, as {.fn rsample::nested_cv} does."
      ),
      class = "nestedtune_bad_design",
      call = call
    )
  }

  # Containment, for the folds whose inner splits carry the outer frame. The
  # logical `NA` `out_id` is rsample's "the complement", left as it is; every
  # other index in either slot must be one the outer split's `in_id` holds.
  bullets <- character(0)
  for (f in seq_len(n)) {
    if (!all(whole[[f]])) {
      next
    }
    outer_in <- as.integer(outer[[f]][["in_id"]])
    # The rows the outer split holds, marked once for the fold rather than
    # hashed by %in% for every split (M135, T5). An index outside the frame
    # is read with %in%, so every index gets the answer %in% gives.
    # check_split_indices() has refused every index that is not numeric, is
    # NA, or lies outside integer range, so as.integer() gives no NA here but
    # the logical NA `out_id`, dropped below (M138, M141).
    mark <- logical(NROW(outer[[f]][["data"]]))
    marked <- outer_in[!is.na(outer_in) & outer_in >= 1L]
    mark[marked[marked <= length(mark)]] <- TRUE
    held <- function(idx) {
      inside <- !is.na(idx) & idx >= 1L & idx <= length(mark)
      out <- logical(length(idx))
      out[inside] <- mark[idx[inside]]
      out[!inside] <- idx[!inside] %in% outer_in
      out
    }
    splits <- inner[[f]][["splits"]]
    for (s in seq_along(splits)) {
      in_id <- as.integer(splits[[s]][["in_id"]])
      out_id <- as.integer(splits[[s]][["out_id"]])
      out_id <- out_id[!is.na(out_id)]
      in_bad <- unique(in_id[!held(in_id)])
      out_bad <- unique(out_id[!held(out_id)])
      if (length(in_bad) == 0L && length(out_bad) == 0L) {
        next
      }
      # As character, so cli names the indices rather than counting them.
      parts <- c(
        if (length(in_bad) > 0L) {
          cli::format_inline("{.field in_id} holds {as.character(in_bad)}")
        },
        if (length(out_bad) > 0L) {
          cli::format_inline("{.field out_id} holds {as.character(out_bad)}")
        }
      )
      n_bad <- length(unique(c(in_bad, out_bad)))
      bullets <- c(
        bullets,
        cli::format_inline(paste(
          "Outer fold {f}, inner split {s}: {paste(parts, collapse = ' and ')},",
          "{cli::qty(n_bad)}{?a row/rows} the outer split does not hold."
        ))
      )
    }
  }
  if (length(bullets) > 0L) {
    cli::cli_abort(
      c(
        "{.arg resamples} has an inner split indexing rows its outer fold \\
         does not hold.",
        x_bullets(bullets),
        i = "An inner split built on the outer split's frame may index only \\
             the rows in that split's {.field in_id}: an inner analysis or \\
             assessment set reaching an outer assessment row leaks it into \\
             the tuning."
      ),
      class = "nestedtune_bad_design",
      call = call
    )
  }
  invisible(resamples)
}

# Which frame each of an outer split's inner splits carries, given their
# frames: the outer split's own ("whole"), its analysis set ("analysis"), or
# neither ("other"). NULL when the analysis set cannot be built (an outer
# `in_id` past the frame, M54): the splits not on the outer frame are then
# left to `last_fit()` rather than judged against nothing. Read by
# check_inner_splits() and by the rule on shared rows.
inner_frame_kinds <- function(split, frames) {
  is_whole <- vapply(frames, identical, logical(1), split[["data"]])
  if (all(is_whole)) {
    return(rep("whole", length(frames)))
  }
  analysis <- outer_analysis(split)
  if (is.null(analysis)) {
    return(NULL)
  }
  # One deep compare per distinct frame: the first split not on the outer
  # frame is compared against the analysis set, and the others share its
  # verdict when they carry the same frame (a pointer compare when it is the
  # same object, as `nested_cv()` builds them).
  is_analysis <- rep(FALSE, length(frames))
  rest <- which(!is_whole)
  first <- rest[[1L]]
  is_analysis[[first]] <- identical(frames[[first]], analysis)
  for (s in rest[-1L]) {
    is_analysis[[s]] <- if (identical(frames[[s]], frames[[first]])) {
      is_analysis[[first]]
    } else {
      identical(frames[[s]], analysis)
    }
  }
  ifelse(is_whole, "whole", ifelse(is_analysis, "analysis", "other"))
}

# The outer split's analysis set, or NULL when it cannot be built: an outer
# `in_id` reaching past the frame is `last_fit()`'s to refuse (M54), not this
# check's.
outer_analysis <- function(split) {
  idx <- split[["in_id"]]
  data <- split[["data"]]
  if (
    !is.data.frame(data) ||
      !is.numeric(idx) ||
      length(idx) == 0L ||
      anyNA(idx) ||
      any(idx < 1L) ||
      max(idx) > nrow(data)
  ) {
    return(NULL)
  }
  rsample::analysis(split)
}

check_grid <- function(grid, call = rlang::caller_env()) {
  if (is.data.frame(grid)) {
    if (nrow(grid) == 0L) {
      cli::cli_abort(
        "{.arg grid} must have at least one candidate row.",
        call = call
      )
    }
    return(invisible(grid))
  }
  if (
    !is.numeric(grid) ||
      length(grid) != 1L ||
      is.na(grid) ||
      grid < 1 ||
      grid != trunc(grid)
  ) {
    cli::cli_abort(
      c(
        "{.arg grid} must be a data frame of candidates or a single positive \\
         whole number.",
        x = "Got {.obj_type_friendly {grid}}."
      ),
      call = call
    )
  }
  invisible(grid)
}

# A grid can be judged against the workflow before any fitting: tune knows which
# parameters are marked for tuning, and a column that is not one of them -- or a
# tuned parameter with no column -- is wrong for every fold rather than for this
# one. tune raises exactly this, but per fold, and M03 records fold failures
# instead of re-raising them; without this check a malformed grid would surface
# as an entire design failing rather than as the call error it is (GP3).
# `recorded = TRUE` is the final fit's reading: the grid came off the results
# object and is the fixed side, so the message names `object` -- the workflow
# handed over -- rather than a `grid` argument the caller never wrote (D-041).
check_grid_params <- function(
  object,
  grid,
  call = rlang::caller_env(),
  recorded = FALSE
) {
  if (!is.data.frame(grid)) {
    return(invisible(grid))
  }
  # A check that cannot be made is skipped, never turned into a false refusal:
  # extraction can fail for reasons that are not the caller's doing.
  ids <- tryCatch(
    tune::extract_parameter_set_dials(object)$id,
    error = function(cnd) NULL
  )
  if (is.null(ids)) {
    return(invisible(grid))
  }

  unknown <- setdiff(names(grid), ids)
  if (length(unknown) > 0L) {
    if (recorded) {
      cli::cli_abort(
        c(
          "{.arg object} does not tune {length(unknown)} parameter{?s} the \\
           recorded grid has {?a column/columns} for: {.val {unknown}}.",
          i = "Hand over the workflow the nested run in {.arg results} was \\
               built around."
        ),
        call = call
      )
    }
    cli::cli_abort(
      c(
        "{.arg grid} has {length(unknown)} column{?s} not marked for tuning: \\
         {.val {unknown}}.",
        i = "Mark {cli::qty(unknown)}{?it/them} with {.fn tune::tune}, or drop \\
             {cli::qty(unknown)}{?it/them} from the grid."
      ),
      call = call
    )
  }

  missing <- setdiff(ids, names(grid))
  if (length(missing) > 0L) {
    if (recorded) {
      cli::cli_abort(
        c(
          "{.arg object} tunes {length(missing)} parameter{?s} the recorded \\
           grid has no column for: {.val {missing}}.",
          i = "Hand over the workflow the nested run in {.arg results} was \\
               built around."
        ),
        call = call
      )
    }
    cli::cli_abort(
      c(
        "{.arg grid} has no column for {length(missing)} tuned parameter{?s}: \\
         {.val {missing}}.",
        i = "Every parameter marked with {.fn tune::tune} needs candidate values."
      ),
      call = call
    )
  }

  invisible(grid)
}

# The record a final fit re-runs (D-041, RR05 Q3): a `nested_results` carrying
# the design's inner resampling specification and the procedure that ran, with
# at least one row to read the data off. One class for every shape, as the
# Bayesian arguments are refused (`nestedtune_bad_<arg>`): what a caller does
# is the same on each -- stop, and go back to an object the orchestrator
# produced -- and the message carries which shape it was.
#
# Four origins reach here, and the messages name them. An operation outside
# the class's invariants -- rows added or removed -- returns a bare tibble
# (R/nested-results.R), so `res[0, ]` and `filter(res, ...)` arrive as "not a
# nested_results", never as a classed object missing its record. A classed
# object with no `inside` has two indistinguishable origins, because an
# attribute cannot hold NULL: a result built before the specification was
# recorded, and one built from a design that carried none. A record whose
# procedure holds no selection rule, or no workflow identity, was built
# before that entry was recorded (M69, M83), and is refused the same way
# rather than fitted under a rule or a workflow the folds may not have used
# (D-041 declined migration). And a classed object
# with the record and no rows is a prototype: it describes a run and holds
# no data to re-run it on.
check_results_record <- function(results, call = rlang::caller_env()) {
  if (!inherits(results, "nested_results")) {
    cli::cli_abort(
      c(
        "{.arg results} must be a {.cls nested_results} from \\
         {.fn nested_tune_grid} or one of its siblings.",
        x = "Got {.obj_type_friendly {results}}.",
        i = "An operation that adds or removes rows returns a plain tibble \\
             without the run's record; hand over the object the \\
             orchestrator returned."
      ),
      class = "nestedtune_bad_results",
      call = call
    )
  }
  inside <- attr(results, "inside")
  procedure <- attr(results, "procedure")
  # The selection rule is an entry of the procedure (M69), so it is asked
  # for only where there is a procedure to hold it: a record with none has
  # one absence to report, not two. A tuner the registry says selects
  # nothing (M70, D-057) records no rule, and is not asked for one.
  has_select <- is.list(procedure) &&
    (!tuner_selects(procedure$tuner) || is_selection_rule(procedure$select))
  # The workflow identity (M83) is the same shape of absence as the rule: an
  # entry of the procedure that an earlier version did not record.
  has_workflow <- is.list(procedure) && is.list(procedure[["workflow"]])
  if (
    !rlang::is_call(inside) ||
      !is.list(procedure) ||
      !has_select ||
      !has_workflow
  ) {
    absent <- c(
      if (!rlang::is_call(inside)) "inner resampling specification",
      if (!is.list(procedure)) {
        "tuning procedure"
      } else {
        c(
          if (!has_select) "selection rule",
          if (!has_workflow) "record of the workflow"
        )
      }
    )
    later_entries <- c("selection rule", "record of the workflow")
    origin <- if (all(absent %in% later_entries)) {
      "It was built by an earlier version of nestedtune, before the \\
       {absent} {?was/were} recorded."
    } else {
      "It was built by an earlier version of nestedtune, or from a design \\
       assembled by hand rather than by {.fn nested_resamples} or \\
       {.fn rsample::nested_cv}, which store the specification as a call."
    }
    cli::cli_abort(
      c(
        "{.arg results} carries no {absent} to re-run.",
        x = origin,
        i = "Re-run {.fn nested_tune_grid} or the sibling that built it on \\
             this version, on a design from one of those constructors; a \\
             results object is not migrated."
      ),
      class = "nestedtune_bad_results",
      call = call
    )
  }
  if (nrow(results) == 0L) {
    cli::cli_abort(
      c(
        "{.arg results} has no rows, so there is no data to re-run the \\
         procedure on.",
        x = "A prototype describes a run but cannot re-run it."
      ),
      class = "nestedtune_bad_results",
      call = call
    )
  }
  invisible(results)
}

# A run in which no outer fold completed has no estimate, and the estimate is
# the number a final model is reported with (IP3): fitting one from such a
# record would hand back a model with no companion figure, so the request is
# refused (GP3). Read from `.completed`, the column every tuner's worker writes
# through one constructor, as `check_any_completed()` (R/nested-results.R)
# reads it for the summary doors -- and under the same class, so one fact is
# catchable one way whichever door asked. A partial run is not refused: the
# final fit is not the estimate, and `collect_metrics()`'s warning already
# sits where the estimate is. This is a refusal of the run, not of the
# object's shape, so it is not `nestedtune_bad_results`.
check_completed_folds <- function(results, call = rlang::caller_env()) {
  if (any(results$.completed)) {
    return(invisible(results))
  }
  n <- nrow(results)
  cli::cli_abort(
    c(
      "{.arg results} carries no estimate to report a model with: no outer \\
       fold completed.",
      x = "All {n} outer fold{?s} failed.",
      i = "Call {.fn summary} on {.arg results} for the stage each fold \\
           failed at, and re-run {.fn nested_tune_grid} or the sibling that \\
           built it once the cause is fixed."
    ),
    class = "nestedtune_no_completed_folds",
    call = call
  )
}

# Re-evaluate that specification against the whole data.
#
# The stored call travels without its environment, so it is evaluated wherever
# the caller stands now rather than where the design was built. A specification
# written against a variable -- `vfold_cv(v = k)` -- therefore resolves to
# whatever `k` means here: to a different design if `k` changed, and to nothing
# at all if `k` is gone. The first case is undetectable from the design alone
# and the documentation is what defends against it by asking for literals. This
# is the second case, turned into an error naming the call that was attempted
# instead of one from inside rsample.
eval_inside_spec <- function(inside, data, env, call = rlang::caller_env()) {
  spec <- paste(deparse(inside), collapse = " ")
  # The data is bound to a name in a child environment rather than inlined into
  # the call, because any condition raised downstream deparses the call it was
  # raised from -- and a call carrying the whole data frame produces an error
  # message thousands of lines long, which is the opposite of what this wrapper
  # is for. `nested_resamples()` took the same shape at M18 (`eval_spec()`);
  # before that it inlined, and this comment said so.
  eval_env <- rlang::new_environment(
    list(.nestedtune_data = data),
    parent = env
  )
  out <- tryCatch(
    eval(rlang::call_modify(inside, data = quote(.nestedtune_data)), eval_env),
    error = function(cnd) cnd
  )
  if (inherits(out, "condition")) {
    cli::cli_abort(
      c(
        "The design's inner resampling specification could not be \\
         re-evaluated.",
        x = "Tried to run {.code {spec}}.",
        i = "It is re-evaluated when {.fn nested_final_fit} is called, so \\
             every variable in it must still be in scope. Literal arguments \\
             such as {.code vfold_cv(v = 5)} always are."
      ),
      parent = out,
      call = call
    )
  }
  if (!inherits(out, "rset")) {
    cli::cli_abort(
      c(
        "The design's inner resampling specification did not produce an \\
         {.cls rset}.",
        x = "{.code {spec}} gave {.obj_type_friendly {out}}."
      ),
      call = call
    )
  }
  out
}

# Which table shape `collect_metrics()` was asked for, read the way
# check_plot_type() reads its view below.
check_metrics_type <- function(type, call = rlang::caller_env()) {
  allowed <- c("long", "wide")
  if (identical(type, allowed)) {
    return(allowed[[1L]])
  }
  if (
    is.character(type) &&
      length(type) == 1L &&
      !is.na(type) &&
      type %in% allowed
  ) {
    return(type)
  }
  cli::cli_abort(
    c(
      "{.arg type} must be {.or {.val {allowed}}}.",
      x = if (is.character(type) && length(type) == 1L) {
        "Got {.val {type}}."
      } else {
        "Got {.obj_type_friendly {type}}."
      }
    ),
    class = "nestedtune_bad_type",
    call = call
  )
}

# `metric` and `eval_time` choose panels of the performance view. The
# parameters view has no metric panels, so either argument there is refused
# rather than ignored (GP3). The values are checked against the run later,
# once its rows are read.
check_plot_filter <- function(
  type,
  metric,
  eval_time,
  call = rlang::caller_env()
) {
  if (identical(type, "parameters")) {
    given <- c("metric", "eval_time")[
      c(!is.null(metric), !is.null(eval_time))
    ]
    if (length(given) > 0L) {
      cli::cli_abort(
        c(
          "{.arg {given}} {?is/are} only used with \\
           {.code type = \"performance\"}.",
          i = "The parameters view draws what each fold selected, not \\
               its metrics."
        ),
        class = "nestedtune_bad_plot_filter",
        call = call
      )
    }
  }
  if (
    !is.null(metric) &&
      (!is.character(metric) || length(metric) == 0L || anyNA(metric))
  ) {
    cli::cli_abort(
      c(
        "{.arg metric} must be a character vector of metric names.",
        x = "Got {.obj_type_friendly {metric}}."
      ),
      class = "nestedtune_bad_plot_filter",
      call = call
    )
  }
  if (
    !is.null(eval_time) &&
      (!is.numeric(eval_time) || length(eval_time) == 0L || anyNA(eval_time))
  ) {
    cli::cli_abort(
      c(
        "{.arg eval_time} must be a numeric vector of evaluation times.",
        x = "Got {.obj_type_friendly {eval_time}}."
      ),
      class = "nestedtune_bad_plot_filter",
      call = call
    )
  }
}

# Which of the two views `autoplot()` was asked for.
#
# The default is the whole vector, as the signature spells it out, and the first
# element wins -- so this accepts it, accepts either name on its own, and
# refuses anything else by naming both.
check_plot_type <- function(type, call = rlang::caller_env()) {
  allowed <- c("parameters", "performance")
  if (identical(type, allowed)) {
    return(allowed[[1L]])
  }
  if (
    is.character(type) &&
      length(type) == 1L &&
      !is.na(type) &&
      type %in% allowed
  ) {
    return(type)
  }
  cli::cli_abort(
    c(
      "{.arg type} must be one of {.val {allowed}}.",
      x = if (is.character(type) && length(type) == 1L) {
        "Got {.val {type}}."
      } else {
        "Got {.obj_type_friendly {type}}."
      }
    ),
    call = call
  )
}

check_metrics <- function(metrics, call = rlang::caller_env()) {
  if (!is.null(metrics) && !inherits(metrics, "metric_set")) {
    cli::cli_abort(
      c(
        "{.arg metrics} must be a {.fn yardstick::metric_set} or {.code NULL}.",
        x = "Got {.obj_type_friendly {metrics}}."
      ),
      call = call
    )
  }
  invisible(metrics)
}

# The first metric's name, as tune resolves the set for the workflow (M116),
# or a refusal where it cannot, as for a set made for another model mode.
# `nested_loop()` calls it for every tuner, a tuner that selects nothing
# included (D-082), and keeps the name only where the tuner selects.
# Every fold's run would fail on the same set, so refusing
# here saves the whole loop and names the function the user called. tune's
# own message is kept as the parent.
check_metrics_mode <- function(metrics, object, call = rlang::caller_env()) {
  rlang::try_fetch(
    first_metric_name(metrics, object, call = call),
    error = function(cnd) {
      cli::cli_abort(
        c(
          "tune refused {.arg metrics} for this workflow.",
          i = "Each fold's run would fail on it, so no fold was run."
        ),
        parent = cnd,
        class = "nestedtune_metrics_mode",
        call = call
      )
    }
  )
}

# `param_info` is tune's, and it is passed through untouched -- so the only
# thing worth checking here is the one mistake that would otherwise be paid for
# by a whole outer loop before tune saw it.
check_param_info <- function(param_info, call = rlang::caller_env()) {
  if (!is.null(param_info) && !inherits(param_info, "parameters")) {
    cli::cli_abort(
      c(
        "{.arg param_info} must be a {.fn dials::parameters} object or {.code NULL}.",
        x = "Got {.obj_type_friendly {param_info}}."
      ),
      call = call
    )
  }
  invisible(param_info)
}

# `eval_time` is tune's too, and like `event_level` it is passed through
# untouched (D-038). What is refused here is only what tune has no use for:
# `tune:::.filter_eval_time()` coerces with `as.numeric()`, drops missing
# values, keeps what is finite and `>= 0`, uniques the rest, warns about what it
# dropped, and aborts only when nothing survives. So `0`, duplicates and
# unsorted times are accepted here and left for tune to normalize -- refusing
# them would invent a second, stricter rule for tune's own argument -- while a
# value tune would have thrown away is refused before a whole outer loop is paid
# for, and before a mirai daemon can raise it in a frame naming tune rather than
# the function the user called.
#
# Whether the mode is one `eval_time` applies to is not consulted, for the
# reason `check_event_level()` gives below: tune warns about that itself, on its
# own argument.
check_eval_time <- function(eval_time, call = rlang::caller_env()) {
  if (is.null(eval_time)) {
    return(invisible(eval_time))
  }

  if (!is.numeric(eval_time) || length(eval_time) == 0L) {
    cli::cli_abort(
      c(
        "{.arg eval_time} must be a numeric vector of evaluation times, or {.code NULL}.",
        x = if (is.numeric(eval_time)) {
          "Got an empty vector."
        } else {
          "Got {.obj_type_friendly {eval_time}}."
        }
      ),
      call = call
    )
  }

  # Every offending position, not the first: a caller who passed a vector wants
  # to know which of its times is the problem.
  unusable <- is.na(eval_time) | !is.finite(eval_time) | eval_time < 0
  if (any(unusable)) {
    # As character, so cli reads them as a list of items to name rather
    # than as the quantity a numeric interpolation would set.
    positions <- as.character(which(unusable))
    cli::cli_abort(
      c(
        "Every element of {.arg eval_time} must be finite, non-missing, and non-negative.",
        x = "{cli::qty(length(positions))}Element{?s} {positions} {?is/are} not."
      ),
      call = call
    )
  }

  invisible(eval_time)
}

# `event_level` is tune's, and it is passed through untouched. tune accepts the
# setting on a regression workflow and ignores it, so the mode is not consulted
# here (plan gate, 2026-08-31) -- refusing it there would diverge from tune for
# the same argument and would punish one wrapper written for both kinds of
# model. What is refused is a value that names no level at all, before a whole
# outer loop is paid for.
check_event_level <- function(event_level, call = rlang::caller_env()) {
  named_a_level <- is.character(event_level) &&
    length(event_level) == 1L &&
    !is.na(event_level)

  if (named_a_level && event_level %in% c("first", "second")) {
    return(invisible(event_level))
  }

  cli::cli_abort(
    c(
      "{.arg event_level} must be {.val first} or {.val second}.",
      x = if (named_a_level) {
        "Got {.val {event_level}}."
      } else {
        "Got {.obj_type_friendly {event_level}}."
      }
    ),
    call = call
  )
}

# The iterating orchestrators' own arguments (D-040, D-046). All are tune's
# or finetune's, and each is refused here only where the upstream check is
# looser than a whole outer loop can afford: tune's `check_iter()` accepts
# `2.5`, and its `check_initial()` accepts a `tune_results` in place of a
# count. The classes are this package's, so a caller can catch the refusal as
# a refusal of that argument rather than by matching its message.
#
# `floor` is the smallest value the calling sibling accepts. `iter` is 0 for
# `nested_tune_bayes()` -- the initial candidates alone -- and 1 for
# `nested_tune_sim_anneal()`, because finetune 1.3.0 loops `(existing_iter +
# 1):iter`, which at `iter = 0` is `1:0`: two iterations, not none (measured
# 2026-09-02, M51). `initial` is 2 for Bayes, `tune_bayes()`'s own
# requirement, and 1 for annealing, finetune's default.

check_iter <- function(iter, floor = 0, call = rlang::caller_env()) {
  if (is_whole_number(iter) && iter >= floor) {
    return(invisible(iter))
  }
  cli::cli_abort(
    c(
      if (floor > 0) {
        "{.arg iter} must be a single whole number of at least {floor}."
      } else {
        "{.arg iter} must be a single non-negative whole number."
      },
      x = if (is_single_number(iter)) {
        "Got {.val {iter}}."
      } else {
        "Got {.obj_type_friendly {iter}}."
      }
    ),
    class = "nestedtune_bad_iter",
    call = call
  )
}

# A count only. tune also takes the result of an earlier `tune_grid()` run
# here, and that is refused rather than passed on: one tuning run cannot serve
# every outer fold, and its candidates were scored on resamples of data that
# may hold a fold's assessment rows -- the leak IP1 exists to forbid (D-040).
check_initial <- function(initial, floor = 2, call = rlang::caller_env()) {
  if (inherits(initial, "tune_results")) {
    cli::cli_abort(
      c(
        "{.arg initial} must be a number of candidates, not a \\
         {.cls tune_results}.",
        x = "One tuning run cannot serve every outer fold: its candidates \\
             were scored on resamples that may hold a fold's assessment rows.",
        i = "Give the number of candidates to score before the first \\
             iteration, and each fold generates and scores its own."
      ),
      class = "nestedtune_bad_initial",
      call = call
    )
  }
  if (is_whole_number(initial) && initial >= floor) {
    return(invisible(initial))
  }
  cli::cli_abort(
    c(
      "{.arg initial} must be a single whole number of at least {floor}.",
      x = if (is_single_number(initial)) {
        "Got {.val {initial}}."
      } else {
        "Got {.obj_type_friendly {initial}}."
      }
    ),
    class = "nestedtune_bad_initial",
    call = call
  )
}

check_objective <- function(objective, call = rlang::caller_env()) {
  if (inherits(objective, "acquisition_function")) {
    return(invisible(objective))
  }
  cli::cli_abort(
    c(
      "{.arg objective} must be an acquisition function from tune.",
      x = "Got {.obj_type_friendly {objective}}.",
      i = "Use {.fn tune::exp_improve}, {.fn tune::prob_improve} or \\
           {.fn tune::conf_bound}."
    ),
    class = "nestedtune_bad_objective",
    call = call
  )
}

is_whole_number <- function(x) {
  is_single_number(x) && is.finite(x) && x == trunc(x)
}

# Whether there is a value worth naming in the refusal: `2.5` is, a data frame
# is not.
is_single_number <- function(x) {
  is.numeric(x) && length(x) == 1L && !is.na(x)
}

# The dots, forced (D-042). The one formal is `...` itself, so a name a
# caller puts in the dots -- `call`, say -- has nothing else to bind to and
# reaches `check_dots_control()` as the argument it is. Forcing is where a
# control the caller built inline runs -- `control = tune::control_bayes()`
# draws its `seed` slot when it is built -- and that happens here, before the
# loop's own RNG snapshot; the draw is discarded by `effective_control()`, so
# the stream is put back where the caller left it (D-011's net-zero entry),
# and a run under an inline control is the run under the same control built
# beforehand. Unlike the loop's `restore_rng()`, a session that had no state
# is left with none: a state the forcing created is removed rather than kept,
# because the refusals downstream promise to fire before anything is drawn,
# and `RNGkind()` is never called here, since setting a kind is itself a
# draw. Assigning `.Random.seed` restores the kind with it.
capture_dots <- function(...) {
  had_seed <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  old_seed <- if (had_seed) get(".Random.seed", envir = globalenv())
  on.exit(
    if (had_seed) {
      assign(".Random.seed", old_seed, envir = globalenv())
    } else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
      rm(".Random.seed", envir = globalenv())
    },
    add = TRUE
  )
  rlang::list2(...)
}

# What `...` accepts on the two orchestrators (D-042): `control` and nothing
# else. There is no `control` formal -- tune's maintainer reserves that name
# for a future control of the outer work -- so the object comes through the
# dots, and every other name is refused here, at entry, with the argument
# named. An unnamed argument is refused too: everything after `resamples` is
# matched by name, so a positional value is a call that meant something else.
# `dots` is the list `capture_dots()` returns, never the dots themselves: a
# `call` in the caller's dots would bind to this function's `call` formal.
check_dots_control <- function(dots, call = rlang::caller_env()) {
  nms <- rlang::names2(dots)
  unknown <- nms[nms != "control"]
  if (length(unknown) > 0L) {
    named <- unknown[nzchar(unknown)]
    n_unnamed <- sum(!nzchar(unknown))
    cli::cli_abort(
      c(
        "{.arg ...} accepts {.arg control} and nothing else.",
        x = if (length(named) > 0L) "Got {.arg {named}}.",
        x = if (n_unnamed > 0L) {
          "Got {n_unnamed} unnamed argument{?s}; everything after {.arg resamples} is matched by name."
        }
      ),
      class = "nestedtune_bad_dots",
      call = call
    )
  }
  if (sum(nms == "control") > 1L) {
    cli::cli_abort(
      c(
        "{.arg ...} accepts {.arg control} and nothing else.",
        x = "Got {.arg control} {sum(nms == 'control')} times."
      ),
      class = "nestedtune_bad_dots",
      call = call
    )
  }
  dots[["control"]]
}

# The selection rule (M69): what `selection_rule()` returns and nothing
# else, so a string or NULL is refused at entry rather than inside every fold,
# and every symbol its orderings name is a parameter the workflow tunes, read
# off the workflow as `check_grid_params()` reads it. `all.vars()` rather than
# `all.names()`, so `desc(df1)` contributes `df1` and not the function it is
# wrapped in. As there, an extraction that fails skips the check rather than
# turning into a false refusal.
#
# The desirability rule (M109, D-073) is held to more: the tuner must be one
# the registry says applies it, desirability2 must be installed, and every
# name in a term's first argument must be a metric of the run's set or a
# tuned parameter. `selection_rule()` already refuses a name in the later
# arguments.
# With no `metrics` the set is the one tune picks for the model's mode,
# read through `tune::check_metrics_arg()` so the two cannot disagree.
check_selection_rule <- function(
  select,
  object,
  tuner,
  metrics = NULL,
  call = rlang::caller_env()
) {
  if (!is_selection_rule(select)) {
    cli::cli_abort(
      c(
        "{.arg select} must be what {.fn selection_rule} returns.",
        x = "Got {.obj_type_friendly {select}}.",
        i = "The default, {.code selection_rule(\"best\")}, takes the \\
             candidate with the best mean on the first metric."
      ),
      class = "nestedtune_bad_selection_rule",
      call = call
    )
  }
  if (select$rule == "desirability") {
    return(check_desirability_rule(select, object, tuner, metrics, call))
  }
  if (length(select$order) == 0L) {
    return(invisible(select))
  }
  ids <- tryCatch(
    tune::extract_parameter_set_dials(object)$id,
    error = function(cnd) NULL
  )
  if (is.null(ids)) {
    return(invisible(select))
  }
  symbols <- unique(unlist(lapply(select$order, all.vars)))
  unknown <- setdiff(symbols, ids)
  if (length(unknown) > 0L) {
    cli::cli_abort(
      c(
        "{.arg select} orders the candidates by {length(unknown)} name{?s} \\
         {.arg object} does not tune: {.val {unknown}}.",
        i = "{.arg object} tunes {.val {ids}}."
      ),
      class = "nestedtune_selection_rule_unknown_param",
      call = call
    )
  }
  invisible(select)
}

check_desirability_rule <- function(
  select,
  object,
  tuner,
  metrics,
  call = rlang::caller_env()
) {
  if (!tuner_takes_desirability(tuner)) {
    # The user called the orchestrator, so the message names it, not the
    # tuner it wraps (M109 review finding 4).
    orchestrator <- paste0("nested_", tuner)
    supported <- paste0(
      "nested_",
      names(Filter(
        function(entry) isTRUE(entry$desirability),
        tuner_registry
      ))
    )
    cli::cli_abort(
      c(
        "The {.val desirability} selection rule is not supported under \\
         {.fn {orchestrator}}.",
        i = "It is applied under {.fn {supported}}."
      ),
      class = "nestedtune_selection_rule_unsupported",
      call = call
    )
  }
  check_desirability_installed(call = call)
  # On a censored regression model, desirability2 ranks one row per
  # candidate per evaluation time, where tune's selectors use the first time
  # alone, so the rule is refused there (M109 review finding 2).
  mode <- tryCatch(
    workflows::extract_spec_parsnip(object)$mode,
    error = function(cnd) NULL
  )
  if (identical(mode, "censored regression")) {
    cli::cli_abort(
      c(
        "The {.val desirability} selection rule is not supported on a \\
         censored regression model.",
        i = "Choose one of tune's selectors with {.fn selection_rule}, \\
             which rank on the first evaluation time."
      ),
      class = "nestedtune_selection_rule_unsupported",
      call = call
    )
  }
  # As for the orderings, an extraction that fails skips the check rather
  # than turning into a false refusal; tune then fails the folds itself.
  known <- tryCatch(
    c(
      tune::extract_parameter_set_dials(object)$id,
      names(attr(tune::check_metrics_arg(metrics, object), "metrics"))
    ),
    error = function(cnd) NULL
  )
  if (is.null(known)) {
    return(invisible(select))
  }
  unknown <- setdiff(desirability_term_names(select$order), known)
  if (length(unknown) > 0L) {
    cli::cli_abort(
      c(
        "{.arg select} scores the candidates on {length(unknown)} name{?s} \\
         that {?is/are} neither a metric of the run nor a parameter \\
         {.arg object} tunes: {.val {unknown}}.",
        i = "The run's metrics and tuned parameters are {.val {known}}."
      ),
      class = "nestedtune_selection_rule_unknown_term",
      call = call
    )
  }
  invisible(select)
}

# desirability2 at the version the rule was written against (D-072), asked
# where the rule is built, where an orchestrator starts, and where
# `nested_final_fit()` starts on a result that recorded the rule.
# Through `rlang::is_installed()`, as `check_tuner_installed()`
# asks, so a test can mock the absence.
check_desirability_installed <- function(call = rlang::caller_env()) {
  if (!rlang::is_installed("desirability2", version = "0.2.0")) {
    cli::cli_abort(
      c(
        "The {.val desirability} selection rule needs {.pkg desirability2} \\
         (>= 0.2.0), which is not installed.",
        i = "Install it with {.code install.packages(\"desirability2\")}."
      ),
      class = "nestedtune_pkg_not_installed",
      call = call
    )
  }
  invisible(TRUE)
}

# The control, held to the tuner and to the `event_level` argument, and
# returned in its effective form (D-042). `tuner` is the tune function's name.
#
# Class first: tune's own `condense_control()` reads slots by name and would
# run `tune_grid()` under a `control_bayes()` without complaint, so what the
# matching `tune::control_*()` returns is the contract. Then `event_level`:
# the argument is the one place the level is set, and a control naming a
# level that is neither tune's default nor the argument's is a visible
# conflict, refused rather than silently overwritten. A control left at tune's
# default takes the argument's level -- a control object cannot tell a default
# "first" from a typed one, and refusing every disagreement would refuse
# `event_level = "second"` beside every untouched control (M48 gate).
check_control <- function(
  control,
  tuner,
  event_level,
  call = rlang::caller_env()
) {
  expected <- control_class(tuner)
  pkg <- tuner_entry(tuner)$package
  if (!is.null(control) && !inherits(control, expected)) {
    cli::cli_abort(
      c(
        "{.arg control} must be what {.fn {pkg}::{expected}} returns.",
        x = "Got {.obj_type_friendly {control}}."
      ),
      class = "nestedtune_bad_control",
      call = call
    )
  }
  level <- control[["event_level"]]
  if (
    !is.null(control) &&
      !identical(level, "first") &&
      !identical(level, event_level)
  ) {
    cli::cli_abort(
      c(
        "{.arg control} carries {.code event_level = {.val {level}}} while {.arg event_level} is {.val {event_level}}.",
        i = "Set the level once, as the {.arg event_level} argument; a control left at tune's default takes it."
      ),
      class = "nestedtune_bad_control",
      call = call
    )
  }
  effective_control(tuner, control, event_level)
}

# The packages a tuner needs, required before anything else is judged (M50,
# GP3): the registry's `requires` for the tuner -- finetune for the racers,
# and the package each race calls `rlang::check_installed()` on inside the
# first fold, which would otherwise prompt or fail there, one outer loop's
# worth of checks later. Asked through `rlang::is_installed()` so a test can
# mock the absence.
check_tuner_installed <- function(tuner, call = rlang::caller_env()) {
  pkgs <- tuner_entry(tuner)$requires
  missing <- pkgs[!vapply(pkgs, rlang::is_installed, logical(1))]
  if (length(missing) > 0L) {
    # One call the user can paste: `deparse()` gives `"pkg"` for one package
    # and `c("a", "b")` for several, where cli's collapse would give `"a" and "b"`.
    hint <- paste0("install.packages(", deparse1(missing), ")")
    cli::cli_abort(
      c(
        "{.fn {tuner}} needs {.pkg {missing}}, which {?is/are} not installed.",
        i = "Install {?it/them} with {.code {hint}}."
      ),
      class = "nestedtune_pkg_not_installed",
      call = call
    )
  }
  invisible(pkgs)
}

# A race scores every candidate on `burn_in` inner resamples before it
# eliminates any, and finetune refuses a design whose resample count is not
# greater than that -- per fold, inside the loop, where M03 records it as a
# fold failure. Every outer fold's inner `rset` is judged here instead, at
# entry, so a design no fold can race is refused before any work is spent
# (GP3, M50 plan). `control` is the effective control, so `burn_in` is what
# will run; the failing folds are named by position with their counts.
check_race_burn_in <- function(resamples, control, call = rlang::caller_env()) {
  burn_in <- control[["burn_in"]]
  counts <- vapply(
    resamples$inner_resamples,
    function(inner) as.integer(NROW(inner)),
    integer(1)
  )
  short <- which(counts <= burn_in)
  if (length(short) > 0L) {
    detail <- paste(
      sprintf(
        "Outer fold %d holds %d inner resample%s",
        short,
        counts[short],
        ifelse(counts[short] == 1L, "", "s")
      ),
      collapse = "; "
    )
    cli::cli_abort(
      c(
        "A race needs more inner resamples than its {.arg burn_in} of \\
         {burn_in}.",
        x = "{detail}: not more than {burn_in}.",
        i = "Pass {.code control = control_race(burn_in = <fewer>)} \\
             or build the design with more inner resamples."
      ),
      class = "nestedtune_bad_burn_in",
      call = call
    )
  }
  invisible(counts)
}

# The entry checks `nested_workflow_map()` runs over a workflow set (M71,
# D-058), each before the first workflow runs (GP3). The set is read by its
# columns and never through a workflowsets function, which is what keeps
# that package in Suggests.

check_workflow_set <- function(object, call = rlang::caller_env()) {
  needed <- c("wflow_id", "info", "option", "result")
  if (!inherits(object, "workflow_set") || !is.data.frame(object)) {
    cli::cli_abort(
      c(
        "{.arg object} must be a {.cls workflow_set}.",
        x = "Got {.obj_type_friendly {object}}.",
        i = "Build one with {.fn workflowsets::workflow_set} or \\
             {.fn workflowsets::as_workflow_set}; a single workflow runs \\
             through {.fn nested_tune_grid} or one of its siblings."
      ),
      class = "nestedtune_bad_workflow_set",
      call = call
    )
  }
  missing <- setdiff(needed, names(object))
  if (length(missing) > 0L) {
    cli::cli_abort(
      c(
        "{.arg object} must be a {.cls workflow_set} carrying the \\
         {.field {needed}} columns.",
        x = "It lacks {.field {missing}}.",
        i = "Build one with {.fn workflowsets::workflow_set} or \\
             {.fn workflowsets::as_workflow_set}."
      ),
      class = "nestedtune_bad_workflow_set",
      call = call
    )
  }
  if (nrow(object) == 0L) {
    cli::cli_abort(
      "{.arg object} holds no workflows.",
      class = "nestedtune_bad_workflow_set",
      call = call
    )
  }
  invisible(object)
}

# The six orchestrator names `fn` accepts: this package's exports, never
# tune's own names for the functions they wrap, so `"tune_grid"` is refused
# naming the six rather than silently read as the grid orchestrator.
MAP_ORCHESTRATORS <- c(
  "nested_tune_grid",
  "nested_tune_bayes",
  "nested_tune_race_anova",
  "nested_tune_race_win_loss",
  "nested_tune_sim_anneal",
  "nested_fit_resamples"
)

check_map_fn <- function(fn, call = rlang::caller_env()) {
  if (rlang::is_string(fn) && fn %in% MAP_ORCHESTRATORS) {
    return(invisible(fn))
  }
  cli::cli_abort(
    c(
      "{.arg fn} must name one of the six orchestrators: \\
       {.fn {MAP_ORCHESTRATORS}}.",
      x = if (rlang::is_string(fn)) {
        "Got {.val {fn}}."
      } else {
        "Got {.obj_type_friendly {fn}}."
      }
    ),
    class = "nestedtune_bad_fn",
    call = call
  )
}

# What an orchestrator accepts beyond the workflow: its formals other than
# `object` (so `resamples` and everything behind the dots), and the `control`
# every one of the six takes through `...` (D-042). Read off the function
# itself, so a formal added to an orchestrator is accepted here the day it
# lands.
orchestrator_args <- function(fn) {
  # The export is a generic `(object, ...)` since M107, so the arguments are
  # the `workflow` method's, the one a set's workflows dispatch to.
  method <- paste0(fn, ".workflow")
  formals <- names(formals(get(method, envir = asNamespace("nestedtune"))))
  c(setdiff(formals, c("object", "...")), "control")
}

# The map's `...` (M71): every name must be one the orchestrator `fn` names
# accepts, so a typo is refused rather than narrowed away for every
# workflow; `object` is the set's to bind, never the caller's; everything
# after `fn` is matched by name; and the design is the one argument every
# route needs, so its absence is refused here rather than as a missing
# argument two frames down. `dots` is the list `capture_dots()` returns.
check_map_dots <- function(dots, fn, call = rlang::caller_env()) {
  nms <- rlang::names2(dots)
  n_unnamed <- sum(!nzchar(nms))
  if (n_unnamed > 0L) {
    cli::cli_abort(
      c(
        "Every argument in {.arg ...} must be named.",
        x = "Got {n_unnamed} unnamed argument{?s}; everything after \\
             {.arg fn} is matched by name."
      ),
      class = "nestedtune_bad_dots",
      call = call
    )
  }
  accepted <- orchestrator_args(fn)
  unknown <- unique(nms[!nms %in% accepted])
  if (length(unknown) > 0L) {
    cli::cli_abort(
      c(
        "{.arg ...} carries {length(unknown)} argument{?s} {.fn {fn}} does \\
         not take: {.arg {unknown}}.",
        i = if ("object" %in% unknown) {
          "The workflow is the set's own; {.arg object} is the set."
        },
        i = "{.fn {fn}} takes {.arg {setdiff(accepted, 'object')}}; an \\
             argument for one workflow alone goes in the set's \\
             {.field option} column ({.fn workflowsets::option_add})."
      ),
      class = "nestedtune_bad_dots",
      call = call
    )
  }
  repeated <- unique(nms[duplicated(nms)])
  if (length(repeated) > 0L) {
    cli::cli_abort(
      "{.arg ...} carries {.arg {repeated}} more than once.",
      class = "nestedtune_bad_dots",
      call = call
    )
  }
  if (!"resamples" %in% nms) {
    cli::cli_abort(
      c(
        "{.arg ...} must carry the nested design as {.arg resamples}.",
        i = "Every workflow of the set runs on the same design; build one \\
             with {.fn nested_resamples}."
      ),
      class = "nestedtune_bad_dots",
      call = call
    )
  }
  invisible(dots)
}

# Which orchestrator a workflow of the set takes (D-057, D-058): the plain
# resampling one when nothing in it is marked with `tune()`, whatever `fn`
# names, and `fn` otherwise. A workflow whose parameters cannot be read
# keeps `fn`, as `check_untuned_workflow()` lets it pass: a check that
# cannot be made is never turned into a route.
route_workflow <- function(workflow, fn) {
  ids <- tuned_parameter_ids(workflow)
  if (!is.null(ids) && length(ids) == 0L) {
    return("nested_fit_resamples")
  }
  fn
}

# Each workflow's `option` entry, held to the orchestrator that workflow
# routes to (M71): a name that orchestrator does not take is refused naming
# the workflow, and `object` and `resamples` are refused whatever the route,
# since the workflow and the design come from the set and the call. Checked
# over the whole set before the first workflow runs, so a bad entry on the
# last workflow does not cost the runs before it.
check_map_options <- function(object, routes, call = rlang::caller_env()) {
  for (i in seq_len(nrow(object))) {
    option <- object$option[[i]]
    nms <- rlang::names2(option)
    if (length(nms) == 0L) {
      next
    }
    id <- object$wflow_id[[i]]
    route <- routes[[i]]
    accepted <- setdiff(orchestrator_args(route), c("object", "resamples"))
    reserved <- intersect(nms, c("object", "resamples"))
    if (length(reserved) > 0L) {
      cli::cli_abort(
        c(
          "Workflow {.val {id}} carries {.arg {reserved}} as an option.",
          x = "The workflow and the design are the set's and the call's; \\
               neither can be replaced per workflow."
        ),
        class = "nestedtune_bad_option",
        call = call
      )
    }
    unknown <- unique(nms[!nms %in% accepted])
    if (length(unknown) > 0L) {
      cli::cli_abort(
        c(
          "Workflow {.val {id}} carries {length(unknown)} option{?s} \\
           {.fn {route}} does not take: {.arg {unknown}}.",
          i = "It runs through {.fn {route}}, which takes {.arg {accepted}}."
        ),
        class = "nestedtune_bad_option",
        call = call
      )
    }
  }
  invisible(object)
}

# The final fit's two shapes (M71): a workflow with its results, or a
# workflow-set run with an `id`. Anything between the two -- a set with
# `results` supplied, a set with no `id`, a workflow with an `id` -- is a
# call that meant one shape and wrote the other, refused naming both.
check_final_fit_set_args <- function(
  object,
  has_results,
  id,
  call = rlang::caller_env()
) {
  is_set <- inherits(object, "nested_results_set")
  problem <- if (is_set && has_results) {
    "A {.cls nested_results_set} holds each workflow's results beside it, \\
     so {.arg results} is not given with one."
  } else if (is_set && is.null(id)) {
    "A {.cls nested_results_set} needs {.arg id} to name the workflow to fit."
  } else if (!is_set && !is.null(id)) {
    "{.arg id} names a workflow of a {.cls nested_results_set}; with a \\
     workflow as {.arg object}, hand its results over as {.arg results}."
  }
  if (is.null(problem)) {
    return(invisible(object))
  }
  cli::cli_abort(
    c(
      "{.fn nested_final_fit} takes a workflow with its {.arg results}, or a \\
       {.cls nested_results_set} with an {.arg id}.",
      x = problem
    ),
    class = "nestedtune_bad_final_fit_args",
    call = call
  )
}

# The workflow handed to the final fit, against the identity the run
# recorded (M83). The grid-column and tune() marker checks run first and
# catch a workflow tuning different names, naming the column or the marker;
# this catches every other difference -- model type, engine, mode, an
# argument, the preprocessor's kind or any part of it -- and names the first
# part that differs, with the recorded and the given form beside it. The
# identity is a deparsed description (R/workflow-identity.R), so a model
# argument is compared as the code it was written as, and not as what a
# name outside the workflow was bound to. A recipe step's settings are the
# exception: recipes evaluates them when the step is added, so they are
# compared by value, save a function, which is compared as its body.
check_workflow_identity <- function(
  object,
  recorded,
  call = rlang::caller_env()
) {
  given <- workflow_identity(object)
  if (identical(given, recorded)) {
    return(invisible(object))
  }
  d <- identity_difference(recorded, given)
  # `d` is interpolated as a value, never spliced into the message: a
  # deparsed setting can hold a brace, which cli would otherwise read as an
  # expression of its own.
  cli::cli_abort(
    c(
      "{.arg object} is not the workflow the nested run in {.arg results} \\
       was built around.",
      x = "{d}",
      i = "Hand over the workflow the nested run in {.arg results} was \\
           built around."
    ),
    class = "nestedtune_workflow_mismatch",
    call = call
  )
}

# The first part of the identity that differs, as one sentence: its name in
# the user's terms, then the recorded and the given form. The two identities
# are walked in parallel; a list whose element names or count differ is
# reported at that level (an argument set on one side only, a step added or
# removed), and otherwise the walk descends to the first leaf that differs.
# A preprocessor of another kind is reported as the kind, since nothing
# below it is comparable.
identity_difference <- function(recorded, given) {
  rk <- preprocessor_kind_label(recorded$preprocessor$kind)
  gk <- preprocessor_kind_label(given$preprocessor$kind)
  if (!identical(rk, gk)) {
    return(cli::format_inline(
      "The preprocessor differs: {rk} was recorded, and {gk} was given."
    ))
  }
  d <- first_difference(recorded, given)
  if (!is.null(d) && length(d$path) == 0L && identical(d$kind, "names")) {
    # A part present on one side only: the case weights or the
    # postprocessor (M103), which the identity leaves out when the workflow
    # carries none, so a record built without one and a workflow with one
    # differ in their parts' names.
    return(optional_part_difference(recorded, given))
  }
  if (is.null(d)) {
    # `identical()` told the two apart on something the walk does not read
    # (an attribute, or NULL against empty names); named rather than left
    # as a sentence with empty slots.
    return(paste(
      "The workflow differs from the recorded one in a part the comparison",
      "cannot name."
    ))
  }
  part <- identity_part(d$path, recorded)
  if (identical(d$kind, "value")) {
    return(cli::format_inline(
      "{part} differs: recorded {.val {d$recorded}}, given {.val {d$given}}."
    ))
  }
  if (identical(d$kind, "count")) {
    return(cli::format_inline(
      "{part} differs: {d$recorded} recorded, {d$given} given."
    ))
  }
  only_recorded <- setdiff(d$recorded, d$given)
  only_given <- setdiff(d$given, d$recorded)
  cli::format_inline(paste0(
    "{part} differ: ",
    if (length(only_recorded) > 0L) {
      "{.val {only_recorded}} {?is/are} recorded and not given"
    },
    if (length(only_recorded) > 0L && length(only_given) > 0L) ", and ",
    if (length(only_given) > 0L) {
      "{.val {only_given}} {?is/are} given and not recorded"
    },
    if (length(only_recorded) == 0L && length(only_given) == 0L) {
      paste(
        "recorded in the order {.val {d$recorded}},",
        "given in the order {.val {d$given}}"
      )
    },
    "."
  ))
}

# The sentence for a part one side carries and the other does not; the
# case weights are named ahead of the postprocessor, the order the identity
# holds them in. A parts difference with neither on one side only is
# something the walk was not written for, and is named as such.
optional_part_difference <- function(recorded, given) {
  side <- function(part) {
    c(recorded = part %in% names(recorded), given = part %in% names(given))
  }
  weights <- side("case_weights")
  if (xor(weights[["recorded"]], weights[["given"]])) {
    col <- function(id) {
      if (is.null(id$case_weights)) {
        "none"
      } else {
        cli::format_inline("the column {.code {id$case_weights}}")
      }
    }
    return(cli::format_inline(paste(
      "The case weights differ: {col(recorded)} recorded, and {col(given)}",
      "given."
    )))
  }
  post <- side("postprocessor")
  if (xor(post[["recorded"]], post[["given"]])) {
    one <- function(id) if (is.null(id$postprocessor)) "none" else "one"
    return(cli::format_inline(paste(
      "The postprocessor differs: {one(recorded)} recorded, and {one(given)}",
      "given."
    )))
  }
  paste(
    "The workflow differs from the recorded one in a part the comparison",
    "cannot name."
  )
}

preprocessor_kind_label <- function(kind) {
  switch(
    kind,
    formula = "a formula",
    variables = "a variables selection",
    recipe = "a recipe",
    paste("a", kind)
  )
}

first_difference <- function(recorded, given, path = character()) {
  if (is.list(recorded) && is.list(given)) {
    rn <- names(recorded)
    gn <- names(given)
    named <- !is.null(rn) && any(nzchar(rn)) || !is.null(gn) && any(nzchar(gn))
    if (named && !identical(rn, gn)) {
      return(list(path = path, kind = "names", recorded = rn, given = gn))
    }
    if (length(recorded) != length(given)) {
      return(list(
        path = path,
        kind = "count",
        recorded = length(recorded),
        given = length(given)
      ))
    }
    for (i in seq_along(recorded)) {
      label <- if (named) rn[[i]] else as.character(i)
      d <- first_difference(recorded[[i]], given[[i]], c(path, label))
      if (!is.null(d)) {
        return(d)
      }
    }
    return(NULL)
  }
  if (identical(recorded, given)) {
    return(NULL)
  }
  list(path = path, kind = "value", recorded = recorded, given = given)
}

# The user's name for a path into the identity. `recorded` supplies a
# step's type, so a step is named as "step 2 (step_pca)" rather than by
# position alone.
identity_part <- function(path, recorded) {
  at <- function(i) if (length(path) >= i) path[[i]] else NA_character_
  if (identical(at(1L), "model")) {
    return(switch(
      at(2L),
      class = "The model type",
      engine = "The model's engine",
      mode = "The model's mode",
      args = if (is.na(at(3L))) {
        "The model's arguments"
      } else {
        sprintf("The model's argument `%s`", at(3L))
      },
      eng_args = if (is.na(at(3L))) {
        "The model's engine arguments"
      } else {
        sprintf("The model's engine argument `%s`", at(3L))
      },
      "The model"
    ))
  }
  if (identical(at(1L), "case_weights")) {
    return("The case-weights column")
  }
  if (identical(at(1L), "postprocessor")) {
    if (is.na(at(3L))) {
      return("The postprocessor's adjustment count")
    }
    i <- as.integer(at(3L))
    type <- recorded$postprocessor$adjustments[[i]]$type
    adjustment <- sprintf("The postprocessor's adjustment %d (%s)", i, type)
    return(switch(
      at(4L),
      type = sprintf("The postprocessor's adjustment %d's type", i),
      arguments = if (is.na(at(5L))) {
        paste(adjustment, "arguments")
      } else {
        sprintf("%s argument `%s`", adjustment, at(5L))
      },
      adjustment
    ))
  }
  switch(
    at(2L),
    formula = "The formula",
    outcomes = "The variables selection's outcomes",
    predictors = "The variables selection's predictors",
    roles = "The recipe's variables and roles",
    steps = {
      if (is.na(at(3L))) {
        return("The recipe's step count")
      }
      i <- as.integer(at(3L))
      type <- recorded$preprocessor$steps[[i]]$type
      step <- sprintf("The recipe's step %d (%s)", i, type)
      switch(
        at(4L),
        type = sprintf("The recipe's step %d's type", i),
        terms = paste(step, "selector"),
        settings = if (is.na(at(5L))) {
          paste(step, "settings")
        } else {
          sprintf("%s setting `%s`", step, at(5L))
        },
        step
      )
    },
    "The preprocessor"
  )
}
