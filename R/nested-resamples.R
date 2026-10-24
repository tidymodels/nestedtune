#' Build a nested resampling design
#'
#' @description
#' `nested_resamples()` builds a nested resampling design: one row per outer
#' fold, with that fold's inner resamples beside it. It gives the same splits
#' as [rsample::nested_cv()], without a copy of the data for each outer fold.
#'
#' @param data A data frame.
#' @param outside The outer resampling, as an unevaluated call such as
#'   `vfold_cv(v = 5)` or as an `rset` already built on `data`.
#' @param inside The inner resampling, as an unevaluated call such as
#'   `vfold_cv(v = 5)`. It is evaluated on each outer fold's analysis set,
#'   so an `rset` is an error.
#' @param ... Not used, and must be empty.
#'
#' @return An object of class `nested_resamples`, which also carries the
#'   classes [rsample::nested_cv()] returns. It is the outer `rset` with an
#'   `inner_resamples` column, one inner `rset` per outer split.
#'
#' @section Differences from rsample:
#'
#' [rsample::analysis()] and [rsample::assessment()] return the same frames
#' as on rsample's splits, and each inner split keeps rsample's class and
#' id. These designs are an error, whether `nested_resamples()` or
#' [rsample::nested_cv()] built them:
#'
#' - An outer [rsample::bootstraps()] or [rsample::group_bootstraps()]. The
#'   same row can land in both the inner analysis and assessment sets.
#' - An outer [rsample::loo_cv()]. Each fold holds out one row, so
#'   R-squared cannot be computed and the averaged RMSE is the mean absolute
#'   error.
#' - An outer [rsample::apparent()], whose one fold is scored on the rows it
#'   trained on.
#' - An outer [rsample::permutations()], whose folds have no assessment set.
#' - An inner [rsample::loo_cv()] or [rsample::permutations()], which tune
#'   does not accept, or an inner [rsample::apparent()], for which tune
#'   reports no results.
#'
#' A design is known by the class of its splits as well as its own class, so
#' a design rebuilt with [rsample::manual_rset()] is caught too. An inner
#' [rsample::validation_set()] cannot be built, because it takes a split and
#' not a data frame.
#'
#' A single split is an error in either loop if its assessment set holds a
#' row of its analysis set. Inside an outer fold, two copies of one data row
#' count as the same row. The apparent split of a bootstrap with the id
#' "Apparent" is exempt, because tune leaves it out of its estimates. For
#' the same reason, an inner split with the id "Apparent" is an error
#' unless it is that split. So is an inner split with a missing `id`, or two
#' inner splits with the same values in every id column.
#'
#' An outer split is an error if its `in_id` or `out_id` holds an `NA`, is
#' not numeric, or holds a value outside integer range. So is an empty
#' `out_id`. The logical `NA` `out_id`, which tells rsample to use
#' [rsample::complement()], is accepted.
#'
#' @section Time-series designs:
#'
#' Below, the sliding designs are [rsample::sliding_window()],
#' [rsample::sliding_index()] and [rsample::sliding_period()], and the four
#' other tuners are [nested_tune_bayes()], the two racing functions and
#' [nested_tune_sim_anneal()]. Each pair of designs below is tested to give
#' the same splits as [rsample::nested_cv()]. Each bullet names the final fits
#' that are tested.
#'
#' - Outer [rsample::rolling_origin()] or a sliding design, with an inner
#'   [rsample::rolling_origin()]. [nested_tune_grid()],
#'   [nested_fit_resamples()] and the final fit of [nested_fit_resamples()]
#'   are tested on all four. The final fit of [nested_tune_grid()], the four
#'   other tuners, their final fits and [nested_workflow_map()] are tested on
#'   the rolling-origin outer design. The final fit of [nested_tune_bayes()]
#'   is also tested on the sliding-window outer design.
#' - Outer [rsample::rolling_origin()] with an inner sliding design.
#'   [nested_tune_grid()] and its final fit are tested on all three.
#'   [nested_workflow_map()] is tested on all three with its default `fn`.
#'   [nested_fit_resamples()] accepts these designs. It checks the inner
#'   design but fits nothing on it. The four other tuners are not tested on
#'   these designs. They are tested with an inner sliding design on the
#'   sliding-window pair below.
#' - A sliding design in both loops, which gives nine pairs.
#'   [nested_tune_grid()] is tested on all nine. On the sliding-window pair,
#'   the four other tuners, [nested_workflow_map()] with its default `fn`,
#'   and the final fit of [nested_tune_grid()] are tested, and
#'   [nested_fit_resamples()] accepts the design. On the other eight pairs,
#'   no function but `nested_resamples()` and [nested_tune_grid()] is tested.
#'
#' Any other inner design is not tested. A `lag` above 0 in
#' [rsample::rolling_origin()] is an error in either loop, because each
#' assessment set then holds the last `lag` rows of its analysis set. Build
#' lagged predictors before resampling.
#'
#' @section Memory:
#'
#' [rsample::nested_cv()] keeps a copy of each outer fold's analysis set.
#' `nested_resamples()` keeps only row indices that point back at `data`.
#' The sizes below are multiples of the source data. They were measured on
#' `mlbench::LetterRecognition` (20000 x 17) with five inner folds, under
#' rsample 1.3.2 and R 4.6.1, on 2026-07-25.
#' `tests/testthat/test-nested-resamples-memory.R` checks how fast each size
#' grows with the number of outer folds.
#'
#' | outer folds | `rsample::nested_cv()` | `nested_resamples()` |
#' |-:|-:|-:|
#' | 2 | 2.2x | 1.2x |
#' | 5 | 5.6x | 1.7x |
#' | 10 | 11.4x | 2.6x |
#' | 50 | 57.5x | 10.0x |
#'
#' @examples
#' data(mtcars)
#'
#' set.seed(1)
#' design <- nested_resamples(
#'   data = mtcars,
#'   outside = rsample::vfold_cv(v = 3),
#'   inside = rsample::vfold_cv(v = 3)
#' )
#' design
#'
#' # Each element of inner_resamples is an ordinary rset.
#' design$inner_resamples[[1]]
#'
#' @seealso [rsample::nested_cv()], [nested_tune_grid()], which takes the
#'   design and runs the outer loop
#' @export
nested_resamples <- function(data, outside, inside, ...) {
  rlang::check_dots_empty()
  cl <- match.call()
  env <- rlang::caller_env()

  if (!is.data.frame(data)) {
    cli::cli_abort(
      "{.arg data} must be a data frame, not {.obj_type_friendly {data}}.",
      class = "nestedtune_bad_data"
    )
  }

  outer_cl <- cl[["outside"]]
  if (rlang::is_call(outer_cl)) {
    outside <- eval_spec(outer_cl, data, env, "outside", call = environment())
  }
  if (!inherits(outside, "rset")) {
    cli::cli_abort(
      c(
        "{.arg outside} must be a resampling specification or an {.cls rset}.",
        x = "Got {.obj_type_friendly {outside}}."
      ),
      class = "nestedtune_bad_design"
    )
  }
  # Every check below reads each split as the list rsample builds.
  check_column_class(
    outside,
    "splits",
    "rsplit",
    hint = "Every element of an {.cls rset}'s {.field splits} column is one \\
            {.cls rsplit}, as {.fn rsample::vfold_cv} and its kin build them.",
    arg = "outside",
    call = environment()
  )
  # An rset carries the data its indices refer to. If that is not the data we
  # were handed, remapping those indices onto `data` would silently produce
  # inner splits drawn from rows the outer fold assigned to assessment -- a
  # leak across the outer boundary (IP1) that no inspection of the result would
  # reveal. rsample sidesteps this by ignoring `data` entirely for an rset;
  # refusing says so instead of quietly picking one.
  if (!identical(split_data(outside), data)) {
    cli::cli_abort(
      c(
        "{.arg outside} was built on different data than {.arg data}.",
        x = "Its row indices refer to that other data frame, so composing them \\
           with {.arg data} would draw inner splits from rows the outer fold \\
           holds out.",
        i = "Pass the same data frame {.arg outside} was built from, or give \\
           {.arg outside} as an unevaluated call such as \\
           {.code vfold_cv(v = 5)}."
      ),
      class = "nestedtune_bad_design"
    )
  }
  if (inherits(outside, "bootstraps")) {
    cli::cli_abort(
      c(
        "{.arg outside} cannot be a bootstrap.",
        x = refused_design_reason(bootstrap_design(outside), "outer"),
        i = "{.fn rsample::nested_cv} builds this design, with a warning at \\
             most; {.fn nested_resamples} refuses."
      ),
      class = "nestedtune_bad_design"
    )
  }
  # The three designs that give no valid nested estimate in the outer loop
  # (D-096). The inner three are refused per fold, in
  # inner_resamples_from_split().
  refused <- refused_design(outside)
  if (!is.na(refused)) {
    cli::cli_abort(
      c(
        "{.arg outside} cannot be an {.fn rsample::{refused}} design.",
        x = refused_design_reason(refused, "outer")
      ),
      class = "nestedtune_bad_design"
    )
  }
  # An rset whose own class names none of these, such as a manual_rset()
  # rebuild, is read by its split classes (D-097).
  check_outer_splits(outside, "outside", call = environment())
  # The outer half of the entry check's index rule, so the constructor does
  # not build a design every driver refuses (D-111, D-114).
  check_outer_indices(outside, "outside", call = environment())
  # A split rebuilt with make_splits() carries no class to read, so each
  # split's rows are read next (D-103).
  check_outer_overlap(outside, "outside", call = environment())

  inner_cl <- cl[["inside"]]
  if (!rlang::is_call(inner_cl)) {
    cli::cli_abort(
      c(
        "{.arg inside} must be an expression such as {.code vfold_cv(v = 5)}, \\
       not an existing object.",
        i = "It is evaluated once per outer fold, so it cannot be evaluated \\
           ahead of time."
      ),
      class = "nestedtune_bad_design"
    )
  }

  # By position rather than by Map(), which would evaluate the `inside` call
  # it was handed instead of passing it on.
  frame <- environment()
  inner <- lapply(seq_along(outside$splits), function(fold) {
    inner_resamples_from_split(
      outside$splits[[fold]],
      fold,
      cl = inner_cl,
      env = env,
      data = data,
      call = frame
    )
  })

  out <- outside
  out[["inner_resamples"]] <- inner
  class(out) <- c("nested_resamples", "nested_cv", class(outside))
  attr(out, "outside") <- cl$outside
  attr(out, "inside") <- cl$inside
  out
}

# Evaluate the inner specification against one outer fold, keeping only indices.
#
# The analysis frame is built here and referenced by nothing that outlives this
# call, so the inner specification sees exactly what rsample would hand it --
# same rows, same order, same columns, so the same seed draws the same splits --
# while the returned splits reference `data` instead.
inner_resamples_from_split <- function(split, fold, cl, env, data, call) {
  outer_idx <- as.integer(split$in_id)
  analysis_frame <- as.data.frame(split)

  # This function runs once per outer fold, so the rset guard below it covers
  # every fold. A pre-pass over the first fold would be cheaper to write and
  # wrong: building an rset draws from the RNG, so the extra evaluation would
  # shift the stream and change every design this function returns.
  inner_rset <- eval_spec(cl, analysis_frame, env, "inside", call = call)
  if (!inherits(inner_rset, "rset")) {
    cli::cli_abort(
      c(
        "{.arg inside} did not produce an {.cls rset}.",
        x = "{.code {paste(deparse(cl), collapse = ' ')}} gave \\
             {.obj_type_friendly {inner_rset}}.",
        i = "It is evaluated once per outer fold, so it must return an \\
             {.cls rset} for every one of them."
      ),
      class = "nestedtune_bad_design",
      call = call
    )
  }
  refused <- inner_refused_design(inner_rset)
  if (!is.na(refused)) {
    # A design found by its split classes can be mixed, so the headline names
    # the splits and the outer fold rather than calling it that design.
    headline <- if (is.na(refused_design(inner_rset))) {
      "{.arg inside} gave {.fn rsample::{refused}} splits for outer fold {fold}."
    } else {
      "{.arg inside} cannot be an {.fn rsample::{refused}} design."
    }
    hint <- if (renamed_apparent(inner_rset, refused)) {
      c(i = "{apparent_id_hint}")
    }
    cli::cli_abort(
      c(headline, x = inner_refused_reason(inner_rset, refused), hint),
      class = "nestedtune_bad_design",
      call = call
    )
  }
  # The rule of check_inner_overlap(), for this one fold (D-103). The
  # inner splits index the analysis frame, so each index is read as the data
  # row the outer `in_id` puts there.
  shared <- inner_overlap_rows(inner_rset, outer_idx)
  if (length(shared) > 0L) {
    n <- length(shared)
    reason <- inner_overlap_reason()
    cli::cli_abort(
      c(
        "{.arg inside} gave a split for outer fold {fold} whose analysis and \\
         assessment sets share rows.",
        x = "{cli::qty(n)}Split{?s} {shared} of that fold's inner design \\
             {cli::qty(n)}{?shares/share} rows.",
        i = "{reason}",
        lag_hint(list(inner_rset))
      ),
      class = "nestedtune_bad_design",
      call = call
    )
  }
  # The two id rules of check_inner_ids(), for this one fold (D-102).
  if (length(missing_id_rows(inner_rset)) > 0L) {
    cli::cli_abort(
      c(
        "{.arg inside} gave a split with a missing id for outer fold {fold}.",
        x = "{id_rule_reason('missing')}"
      ),
      class = "nestedtune_bad_design",
      call = call
    )
  }
  if (length(repeated_id_rows(inner_rset)) > 0L) {
    cli::cli_abort(
      c(
        "{.arg inside} gave splits whose ids repeat for outer fold {fold}.",
        x = "{id_rule_reason('repeated')}"
      ),
      class = "nestedtune_bad_design",
      call = call
    )
  }
  if (length(misread_apparent_rows(inner_rset)) > 0L) {
    cli::cli_abort(
      c(
        "{.arg inside} gave a split under the id {.val Apparent} for outer \\
         fold {fold} that is not the apparent split of a bootstrap.",
        x = "{apparent_id_reason}"
      ),
      class = "nestedtune_bad_design",
      call = call
    )
  }

  # The remap below reads each split as the list rsample builds.
  lines <- malformed_lines(
    inner_rset[["splits"]],
    "rsplit",
    "Split",
    after = " of that fold's inner design"
  )
  if (length(lines) > 0L) {
    cli::cli_abort(
      c(
        "{.arg inside} gave a split for outer fold {fold} that is not an \\
         {.cls rsplit}.",
        value_bullets(lines)
      ),
      class = "nestedtune_bad_design",
      call = call
    )
  }

  # Rebuilding the splits from scratch would drop everything rsample attaches
  # beyond the indices -- the split subclass and the per-split `id` tibble that
  # labels()/add_resample_id() read. So the splits rsample just produced are
  # kept and only their three index-bearing fields are rewritten.
  #
  # `out_id` is made explicit rather than left as NA. rsample can leave it NA
  # because its inner splits index a frame that *is* the analysis set, so the
  # complement is derivable; ours index the whole data, where the complement
  # would sweep in the outer fold's assessment rows.
  #
  # Under an outer `in_id` that repeats a row, an inner bootstrap can draw
  # the copies of a row more times in total than the outer split holds it,
  # so `in_id` then mentions that row more often. analysis_framed_inner()
  # maps such an index back by cycling through the copies again from the
  # first.
  splits <- lapply(inner_rset$splits, function(inner_split) {
    assessment_idx <- outer_idx[as.integer(rsample::complement(inner_split))]
    inner_split$in_id <- outer_idx[as.integer(inner_split$in_id)]
    inner_split$out_id <- assessment_idx
    inner_split$data <- data
    inner_split
  })

  # Keep the inner rset the specification produced -- its class, its id columns
  # (id2 included, which manual_rset() would drop), and its spec attributes --
  # and swap in the remapped splits. The fingerprint is the one exception: it
  # describes rsample's indices, so it is recomputed rather than carried over.
  out <- inner_rset
  out[["splits"]] <- splits
  attr(out, "fingerprint") <-
    attr(rsample::manual_rset(splits, inner_rset$id), "fingerprint")
  out
}

# Re-point one outer fold's inner splits at that fold's analysis frame, so the
# frame tune reads holds only the rows the fold may see.
#
# tune finalizes an unknown parameter range on `resamples$splits[[1]]$data`,
# the whole frame the first inner split carries, molded through the workflow's
# preprocessor (`tune_grid_workflow()`, tune 2.1.0; the racers through the
# `tune_grid()` they call, `tune_sim_anneal()` through its own
# `check_parameters()`). The inner splits `inner_resamples_from_split()` builds
# index the caller's one frame, assessment rows included, so read that way the
# range is finalized on rows IP1 keeps out of the inner loop -- a `min_n` bound
# of 100 on a 200-row frame where the fold's 160 analysis rows give 80 --
# while a `nested_cv()` design, whose inner splits carry the analysis set as
# their own frame, gets it right by construction. This is the inverse of that
# remap: the indices come back onto the analysis frame, so the inner call no
# longer receives the object the design holds (the GP1 divergence DESIGN
# records), while the design itself and the wire payload do not change -- the
# analysis frame is materialized once per fold, in the worker, for the tune
# call's duration (GP4). Nothing here draws from the RNG.
#
# An inner rset whose frame is not the outer split's is left as it is, since
# the inverse does not apply: a `nested_cv()` design, whose splits
# `is_fold_payload()`'s shared-frame check also passes, which is why the test
# here is against the outer frame.
#
# Each inner index maps by occurrence (occurrence_map()): the r-th mention of
# a data row, within one `in_id` or one explicit `out_id`, goes to the r-th
# position of that row in the outer `in_id`. Without repeats that is
# `match()`, which runs in its place. Under an outer `in_id` that repeats a
# row (an evaluated `manual_rset()`), `match()` would collapse the copies
# onto one position, while the occurrence map keeps the rows, their order
# and multiplicity, and gives distinct `.row` values to the copies tune
# assesses. The positions are rsample's own when each split that holds a
# copy of a row holds every earlier copy of it, in ascending order, as a
# grouped or v-fold inner does once the overlap rule has refused a split
# that parts the copies. Any other inner, such as `mc_cv()`, a bootstrap, or
# a rolling or sliding window that holds only a later copy, gets the same
# rows at other positions, which nothing downstream reads. Past the last copy
# the map cycles through the copies again from the first. An inner bootstrap
# from `nested_resamples()` reaches that, and so does a hand-built split that
# mentions a row more often than the outer split holds it.
#
# A logical `NA` `out_id` is rsample's "the complement". Without repeats it
# stays as it is, since the complement over the analysis frame is the right
# set. Under repeats it would also take the copies of the rows the inner
# split trains on, so it becomes every position whose data row lies in
# `rsample::complement()` of the split read over the whole frame: each copy
# the outer split holds, and no outer held-out row.
#
# Some designs keep the whole frame. One is an outer `in_id` that holds an
# `NA`, a fractional index, or one below 1 or past the data, left for
# `last_fit()` to refuse as the fold's outer-fit failure rather than raised
# here as its inner one. Another is an inner split whose complement rsample
# cannot derive, left for tune to fail on. A third is an inner index the
# outer split does not hold, which the entry check has already refused. No
# index is mapped to `NA`. The fold can still report inner metrics, so every
# other logical `NA` `out_id` is made explicit on the whole frame
# (whole_frame_inner()).
analysis_framed_inner <- function(inner, split) {
  outer_idx <- as.integer(split$in_id)
  shared <- vapply(
    inner$splits,
    function(inner_split) identical(inner_split$data, split$data),
    logical(1)
  )
  if (!all(shared)) {
    return(inner)
  }
  repeats <- anyDuplicated(outer_idx) > 0L
  whole_frame <- function() whole_frame_inner(inner, outer_idx)
  if (
    anyNA(outer_idx) ||
      !all(split$in_id == outer_idx) ||
      any(outer_idx < 1L) ||
      max(outer_idx) > nrow(split$data)
  ) {
    return(whole_frame())
  }
  map <- if (repeats) {
    occurrence_map(outer_idx)
  } else {
    function(idx) {
      out <- match(as.integer(idx), outer_idx)
      if (anyNA(out)) NULL else out
    }
  }

  splits <- vector("list", length(inner$splits))
  for (i in seq_along(splits)) {
    inner_split <- inner$splits[[i]]
    in_id <- map(inner_split$in_id)
    out_id <- inner_split$out_id
    if (!identical(out_id, NA)) {
      out_id <- map(out_id)
    } else if (repeats) {
      held <- outer_complement(inner_split)
      out_id <- if (is.null(held)) NULL else which(outer_idx %in% held)
    }
    if (is.null(in_id) || is.null(out_id)) {
      return(whole_frame())
    }
    inner_split$in_id <- in_id
    inner_split$out_id <- out_id
    splits[[i]] <- inner_split
  }
  # Materialized only once every index is known to map.
  analysis_frame <- rsample::analysis(split)
  splits <- lapply(splits, function(inner_split) {
    inner_split$data <- analysis_frame
    inner_split
  })
  replace_splits(inner, splits)
}

# The rows of the whole frame an inner split assesses, or NULL when rsample
# cannot derive them.
outer_complement <- function(inner_split) {
  tryCatch(rsample::complement(inner_split), error = function(cnd) NULL)
}

# The inner rset on the whole frame, where analysis_framed_inner() cannot
# re-point it. Each logical `NA` `out_id` whose complement rsample can derive
# becomes the data rows of that complement that the outer split holds, each
# copy once, so it holds no outer held-out row (IP1). A split whose
# complement rsample cannot derive is left as it is, and the others are
# still made explicit.
whole_frame_inner <- function(inner, outer_idx) {
  splits <- inner$splits
  changed <- FALSE
  for (i in seq_along(splits)) {
    if (!identical(splits[[i]]$out_id, NA)) {
      next
    }
    held <- outer_complement(splits[[i]])
    if (is.null(held)) {
      next
    }
    splits[[i]]$out_id <- outer_idx[outer_idx %in% held]
    changed <- TRUE
  }
  if (changed) replace_splits(inner, splits) else inner
}

# The occurrence map of an outer `in_id` that repeats a row, as a function of
# one inner index vector (analysis_framed_inner()). It returns the analysis
# frame positions, or NULL when an index has no position. Indices are read
# with `as.integer()`, as the entry check reads them. Memory is linear in
# the two vectors.
occurrence_map <- function(outer_idx) {
  # The positions of the outer `in_id` sorted by data row. order() keeps
  # ties in their original order, so each row's copies stay in order.
  by_row <- order(outer_idx)
  runs <- rle(outer_idx[by_row])
  start <- cumsum(c(0L, runs$lengths[-length(runs$lengths)]))
  function(idx) {
    idx <- as.integer(idx)
    if (length(idx) == 0L) {
      return(integer(0))
    }
    if (anyNA(idx)) {
      return(NULL)
    }
    row <- match(idx, runs$values)
    if (anyNA(row)) {
      return(NULL)
    }
    # The 0-based rank of each mention among the mentions of its row, in the
    # order of `idx`.
    o <- order(idx)
    sorted <- idx[o]
    first <- c(TRUE, sorted[-1L] != sorted[-length(sorted)])
    run <- seq_along(sorted)
    mention <- integer(length(idx))
    mention[o] <- run - cummax(ifelse(first, run, 0L))
    by_row[start[row] + mention %% runs$lengths[row] + 1L]
  }
}

# As in `inner_resamples_from_split()`: the rset's class, id columns and
# attributes are kept, the splits swapped, and the fingerprint recomputed
# because it describes the indices.
replace_splits <- function(inner, splits) {
  out <- inner
  out[["splits"]] <- splits
  attr(out, "fingerprint") <-
    attr(rsample::manual_rset(splits, inner$id), "fingerprint")
  out
}

# Evaluate a resampling specification against a data frame.
#
# The frame is bound to a name in a child environment rather than inlined into
# the call. The two are equivalent whenever the call succeeds -- verified
# identical down to the fingerprint -- but any condition raised downstream
# deparses the call it came from, and a call carrying the frame produces a
# message that is the data: 1,194 characters on a 30x2 frame, and growing with
# it. `eval_inside_spec()` (R/checks.R) already takes this shape on the
# final-fit path for the same reason; construction did not.
eval_spec <- function(cl, data, env, arg, call) {
  eval_env <- rlang::new_environment(
    list(.nestedtune_data = data),
    parent = env
  )
  out <- tryCatch(
    eval(rlang::call_modify(cl, data = quote(.nestedtune_data)), eval_env),
    error = function(cnd) cnd
  )
  if (inherits(out, "condition")) {
    cli::cli_abort(
      c(
        "{.arg {arg}} could not be evaluated.",
        x = "Tried to run {.code {paste(deparse(cl), collapse = ' ')}}."
      ),
      parent = out,
      class = "nestedtune_bad_design",
      call = call
    )
  }
  out
}

# The data an rset's indices refer to. Every split in an rset shares one data
# frame, so the first split answers for all of them.
split_data <- function(x) {
  x$splits[[1]]$data
}
