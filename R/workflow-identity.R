# The canonical identity of a workflow: what a results object records about
# the workflow it ran under, and what `nested_final_fit()` compares the
# workflow it is handed against (M83).
#
# The workflow object itself is not stored. Two workflows built from the same
# code are not `identical()`: a recipe step draws its `id` from the stream,
# and every quosure in a step's `terms` or a model's `args` captures the
# frame that built it. And a recipe's `template` holds the training rows, so
# storing it would copy the data onto every record (GP4). What is recorded
# instead is a deparsed description: the model specification's class, engine,
# mode and arguments, and the preprocessor by kind, with random ids, quosure
# environments and the data left out. A model argument is recorded as
# written, so `penalty = p` records `p` and not the value `p` was bound to:
# two workflows that differ only in what a name outside them was bound to
# read as one, deliberately, since the identity is a check on the code the
# user handed over and not a re-run of it. A recipe step's settings are the
# exception (see `preprocessor_identity()` below): recipes evaluates them
# when the step is added, so they are recorded by value.

workflow_identity <- function(object) {
  list(
    model = model_identity(workflows::extract_spec_parsnip(object)),
    preprocessor = preprocessor_identity(
      workflows::extract_preprocessor(object)
    )
  )
}

# The parsnip model: its class (the first, `linear_reg` ahead of
# `model_spec`), engine, mode, and the main and engine arguments. parsnip
# holds both argument sets as quosures whether they were given in the
# constructor or through `set_args()` and `set_engine()` afterwards, so the
# two routes deparse alike. `eng_args` is NULL on a fresh specification and
# a quosure list once `set_engine()` has been called -- empty when no engine
# argument was given; NULL and the empty list both read as no engine
# arguments. Engine arguments are held in call order, so they are sorted by
# name: two calls naming the same arguments in another order are one
# specification.
model_identity <- function(spec) {
  eng_args <- deparse_settings(spec$eng_args)
  list(
    class = class(spec)[[1L]],
    engine = spec$engine,
    mode = spec$mode,
    args = deparse_settings(spec$args),
    eng_args = eng_args[order(names(eng_args), method = "radix")]
  )
}

# The preprocessor by kind. A formula is deparsed whole. A variables
# selection is its two quosures deparsed. A recipe is the role of each
# variable its formula named, and each step in order as its class, its
# selectors (`terms`) and every other field it holds, deparsed; `id` is
# left out (drawn from the stream), and so is everything the recipe holds
# beyond the steps and the roles (`template` is the data; `term_info`,
# `levels` and `ptype` are read from it). A step holds its settings as
# values, not as the expressions written -- `num_comp = k` stores what `k`
# was bound to -- so a recipe setting is compared by value where a model
# argument is compared as written. A setting that is a function is the
# exception to that: it is deparsed as its body, and the values it closes
# over are not read, so two functions with one body read as one setting.
preprocessor_identity <- function(pre) {
  if (rlang::is_formula(pre)) {
    return(list(kind = "formula", formula = deparse_one(pre)))
  }
  if (inherits(pre, "workflow_variables")) {
    return(list(
      kind = "variables",
      outcomes = deparse_one(pre$outcomes),
      predictors = deparse_one(pre$predictors)
    ))
  }
  if (inherits(pre, "recipe")) {
    return(list(
      kind = "recipe",
      roles = recipe_roles(pre),
      steps = lapply(pre$steps, step_identity)
    ))
  }
  # workflows admits nothing else at the time of writing; recorded by class
  # rather than refused, so a new preprocessor kind upstream still records
  # something the check can compare.
  list(kind = class(pre)[[1L]])
}

recipe_roles <- function(rec) {
  info <- rec$var_info
  roles <- as.list(info$role)
  names(roles) <- info$variable
  roles
}

step_identity <- function(step) {
  fields <- unclass(step)
  fields$id <- NULL
  terms <- fields$terms
  fields$terms <- NULL
  list(
    type = class(step)[[1L]],
    terms = deparse_settings(terms),
    settings = deparse_settings(fields)
  )
}

# A named list of settings, each deparsed; NULL reads as none. Names are
# kept in the order held, since a step's or a specification's field order
# is fixed by its constructor.
deparse_settings <- function(x) {
  if (is.null(x)) {
    return(rlang::set_names(list(), character()))
  }
  lapply(unclass(x), deparse_one)
}

# One value in canonical deparsed form: a quosure is squashed first, so its
# environment is gone and only the expression is kept; an environment reads
# as one token, since its identity is never what the user wrote; an
# unclassed list, or a list of quosures (a `step_mutate()`'s `inputs`), is
# deparsed element by element, so a nested setting (a step's `options`)
# keeps its shape and each expression reads as written; anything else is
# `deparse()`d on one line, which keeps `2L` and `2` apart, as parsnip and
# recipes keep them.
deparse_one <- function(x) {
  if (rlang::is_quosure(x)) {
    x <- rlang::quo_squash(x)
  }
  if (is.environment(x)) {
    return("<environment>")
  }
  if (rlang::is_formula(x)) {
    attr(x, ".Environment") <- NULL
  }
  if (rlang::is_quosures(x)) {
    return(deparse_settings(unclass(x)))
  }
  if (is.list(x) && !is.object(x)) {
    return(deparse_settings(x))
  }
  paste(deparse(x, width.cutoff = 500L, backtick = TRUE), collapse = " ")
}
