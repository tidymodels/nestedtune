# The export surface set beside its tidymodels counterparts (M148).
#
#   Rscript benchmarks/export-surface.R
#
# Part 1 reads `NAMESPACE` and keeps two kinds of item: each `export()` whose
# definition is in this package's `R/` (not a re-export), and each
# `S3method()` whose generic this package exports, re-exported generics
# included. Methods of generics the package does not export (print, summary,
# predict, format, `[`, `names<-`, rbind, the vctrs and dplyr methods) are
# left out, because the generic sets their arguments. Each item is paired
# with the tune, finetune, workflowsets or hardhat function or method it
# mirrors, or with none, through the `pairs` table below. For each pair the
# script prints the arguments only one side has, and the shared arguments
# whose order differs.
#
# Part 2 runs the workflow methods of the six `nested_*` generics and
# `nested_workflow_map()` on a small fixture with `save_pred = TRUE` and an
# `extract` function, runs each counterpart with the same control on the
# inner resamples of outer fold 1, and prints the column names one result has
# and the other lacks.
#
# Nothing here is asserted. The verdict on each difference is in
# cairn/references/export-surface-review.md. A package or upstream release
# that changes an answer is caught by running this again.

stopifnot(
  requireNamespace("pkgload", quietly = TRUE),
  requireNamespace("tune", quietly = TRUE),
  requireNamespace("finetune", quietly = TRUE),
  requireNamespace("workflowsets", quietly = TRUE),
  requireNamespace("hardhat", quietly = TRUE)
)
# The source tree, not an installed copy, so the review reads what `R/` holds.
pkgload::load_all(".", quiet = TRUE)

cat(
  "tune",
  format(packageVersion("tune")),
  "| finetune",
  format(packageVersion("finetune")),
  "| workflowsets",
  format(packageVersion("workflowsets")),
  "| hardhat",
  format(packageVersion("hardhat")),
  "\n\n"
)

# ---- Part 1: the domain, read from NAMESPACE -------------------------------

ns_lines <- readLines("NAMESPACE")
exports <- sub(
  "^export\\((.*)\\)$",
  "\\1",
  grep("^export\\(", ns_lines, value = TRUE)
)
exports <- gsub('"', "", exports)
ns <- asNamespace("nestedtune")
# A re-export is an object whose environment is another package's namespace.
is_owned <- function(name) {
  obj <- get(name, envir = ns)
  is.function(obj) && identical(environment(obj), ns)
}
owned <- exports[vapply(exports, is_owned, logical(1))]

s3 <- sub(
  "^S3method\\((.*)\\)$",
  "\\1",
  grep("^S3method\\(", ns_lines, value = TRUE)
)
s3 <- strsplit(gsub('"', "", s3), ",")
s3 <- data.frame(
  generic = vapply(s3, `[`, character(1), 1),
  class = vapply(s3, `[`, character(1), 2)
)
s3 <- s3[s3$generic %in% exports, ]
methods <- paste0(s3$generic, ".", s3$class)

domain <- c(owned, methods)

# ---- The pairing table -----------------------------------------------------
#
# One row per item. `counterpart` is "pkg::name" or NA for none. The page
# gives the reason for each pairing; the table only states it.

pairs <- c(
  # Functions defined here.
  agreement = NA,
  collect_inner_metrics = NA,
  collect_selections = NA,
  extract_procedure = NA,
  extract_scored_candidates = NA,
  extract_tune_results = NA,
  nested_final_fit = "tune::fit_best.tune_results",
  nested_fit_resamples = "tune::fit_resamples",
  nested_resamples = NA,
  nested_tune_bayes = "tune::tune_bayes",
  nested_tune_grid = "tune::tune_grid",
  nested_tune_race_anova = "finetune::tune_race_anova",
  nested_tune_race_win_loss = "finetune::tune_race_win_loss",
  nested_tune_sim_anneal = "finetune::tune_sim_anneal",
  nested_workflow_map = "workflowsets::workflow_map",
  selection_rule = NA,
  # Methods of generics this package owns.
  agreement.default = NA,
  agreement.nested_results = NA,
  agreement.nested_results_set = NA,
  collect_inner_metrics.default = NA,
  collect_inner_metrics.nested_results = "tune::collect_metrics.tune_results",
  collect_inner_metrics.nested_results_set = "workflowsets::collect_metrics.workflow_set",
  collect_selections.default = NA,
  collect_selections.nested_results = NA,
  collect_selections.nested_results_set = NA,
  extract_procedure.default = NA,
  extract_procedure.nested_final_fit = NA,
  extract_procedure.nested_results = NA,
  extract_scored_candidates.default = NA,
  extract_scored_candidates.nested_final_fit = NA,
  extract_tune_results.default = NA,
  extract_tune_results.nested_final_fit = NA,
  nested_fit_resamples.default = "tune::fit_resamples.default",
  nested_fit_resamples.model_spec = "tune::fit_resamples.model_spec",
  nested_fit_resamples.workflow = "tune::fit_resamples.workflow",
  nested_tune_bayes.default = "tune::tune_bayes.default",
  nested_tune_bayes.model_spec = "tune::tune_bayes.model_spec",
  nested_tune_bayes.workflow = "tune::tune_bayes.workflow",
  nested_tune_grid.default = "tune::tune_grid.default",
  nested_tune_grid.model_spec = "tune::tune_grid.model_spec",
  nested_tune_grid.workflow = "tune::tune_grid.workflow",
  nested_tune_race_anova.default = "finetune::tune_race_anova.default",
  nested_tune_race_anova.model_spec = "finetune::tune_race_anova.model_spec",
  nested_tune_race_anova.workflow = "finetune::tune_race_anova.workflow",
  nested_tune_race_win_loss.default = "finetune::tune_race_win_loss.default",
  nested_tune_race_win_loss.model_spec = "finetune::tune_race_win_loss.model_spec",
  nested_tune_race_win_loss.workflow = "finetune::tune_race_win_loss.workflow",
  nested_tune_sim_anneal.default = "finetune::tune_sim_anneal.default",
  nested_tune_sim_anneal.model_spec = "finetune::tune_sim_anneal.model_spec",
  nested_tune_sim_anneal.workflow = "finetune::tune_sim_anneal.workflow",
  # Methods of re-exported generics.
  augment.nested_final_fit = NA,
  augment.nested_results = "tune::augment.tune_results",
  augment.nested_results_set = NA,
  autoplot.nested_results = "tune::autoplot.tune_results",
  autoplot.nested_results_set = "workflowsets::autoplot.workflow_set",
  collect_extracts.nested_results = "tune::collect_extracts.tune_results",
  collect_extracts.nested_results_set = "workflowsets::collect_extracts.workflow_set",
  collect_metrics.nested_results = "tune::collect_metrics.tune_results",
  collect_metrics.nested_results_set = "workflowsets::collect_metrics.workflow_set",
  collect_notes.nested_results = "tune::collect_notes.tune_results",
  collect_notes.nested_results_set = "workflowsets::collect_notes.workflow_set",
  collect_predictions.nested_results = "tune::collect_predictions.tune_results",
  collect_predictions.nested_results_set = "workflowsets::collect_predictions.workflow_set",
  compute_metrics.nested_results = "tune::compute_metrics.tune_results",
  compute_metrics.nested_results_set = NA,
  extract_fit_engine.nested_final_fit = "tune::extract_fit_engine.tune_results",
  extract_fit_parsnip.nested_final_fit = "tune::extract_fit_parsnip.tune_results",
  extract_mold.nested_final_fit = "tune::extract_mold.tune_results",
  extract_parameter_set_dials.nested_final_fit = "hardhat::extract_parameter_set_dials",
  extract_preprocessor.nested_final_fit = "tune::extract_preprocessor.tune_results",
  extract_recipe.nested_final_fit = "tune::extract_recipe.tune_results",
  extract_spec_parsnip.nested_final_fit = "tune::extract_spec_parsnip.tune_results",
  extract_workflow.nested_final_fit = "tune::extract_workflow.tune_results",
  extract_workflow.nested_results_set = "workflowsets::extract_workflow.workflow_set",
  outcome_names.nested_final_fit = "tune::outcome_names.tune_results"
)

# The table and NAMESPACE must name the same items, so a new export or method
# cannot pass unreviewed.
unpaired <- setdiff(domain, names(pairs))
stale <- setdiff(names(pairs), domain)
if (length(unpaired) || length(stale)) {
  stop(
    "Pairing table out of step with NAMESPACE.",
    if (length(unpaired)) {
      paste0("\n  Not in the table: ", paste(unpaired, collapse = ", "))
    },
    if (length(stale)) {
      paste0("\n  Not in NAMESPACE: ", paste(stale, collapse = ", "))
    },
    call. = FALSE
  )
}

get_counterpart <- function(spec) {
  parts <- strsplit(spec, "::", fixed = TRUE)[[1]]
  getFromNamespace(parts[2], parts[1])
}
get_ours <- function(name) {
  obj <- get0(name, envir = ns, inherits = FALSE)
  if (is.null(obj)) {
    i <- match(name, methods)
    obj <- getS3method(s3$generic[i], s3$class[i], envir = ns)
  }
  obj
}

arg_diff <- function(ours, theirs) {
  a <- names(formals(ours))
  b <- names(formals(theirs))
  shared <- intersect(a, b)
  list(
    ours = a,
    theirs = b,
    only_ours = setdiff(a, b),
    only_theirs = setdiff(b, a),
    order_ours = shared,
    order_theirs = intersect(b, a),
    order_differs = !identical(shared, intersect(b, a))
  )
}

cat("== Part 1: arguments ==\n")
cat(
  length(owned),
  "functions defined here,",
  length(methods),
  "methods of exported generics\n\n"
)
n_diff <- 0L
for (item in domain) {
  spec <- pairs[[item]]
  ours <- get_ours(item)
  if (is.na(spec)) {
    cat(
      sprintf("%-45s none  (%s)\n", item, toString(names(formals(ours))))
    )
    next
  }
  d <- arg_diff(ours, get_counterpart(spec))
  same <- !length(d$only_ours) && !length(d$only_theirs) && !d$order_differs
  cat(sprintf("%-45s %s%s\n", item, spec, if (same) "  same" else ""))
  if (same) {
    next
  }
  n_diff <- n_diff + 1L
  cat("    ours:   ", toString(d$ours), "\n")
  cat("    theirs: ", toString(d$theirs), "\n")
  if (length(d$only_ours)) {
    cat("    only ours:   ", toString(d$only_ours), "\n")
  }
  if (length(d$only_theirs)) {
    cat("    only theirs: ", toString(d$only_theirs), "\n")
  }
  if (d$order_differs) {
    cat(
      "    shared order differs: ours (",
      toString(d$order_ours),
      ") theirs (",
      toString(d$order_theirs),
      ")\n",
      sep = ""
    )
  }
}
cat("\n", n_diff, "pairs differ\n\n")
