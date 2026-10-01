# Time of the entry check `check_nested()` on two large nested designs
# (M135).
#
# Not a test: wall-clock times vary with the machine. The script times the
# code at a base commit and the working tree in one R session, so the drop
# between them is what it reports. Laptop throttling can spread separate
# runs of one tree far apart (M113), and one session keeps both trees under
# the same conditions.
#
#   Rscript benchmarks/split-check-speed.R            # base and working tree
#   Rscript benchmarks/split-check-speed.R base       # the base commit alone
#   Rscript benchmarks/split-check-speed.R both <ref> # another base commit
#
# The base commit defaults to e499a7f3, the commit that planned M135. The
# script exports it with `git archive` into a temporary directory and loads
# that tree and the working tree in turn with `pkgload::load_all()`.
#
# Both designs have 10^5 rows, 10 outer v-folds and 50 inner bootstraps.
# `rsample::nested_cv()` builds one, so its inner splits index each outer
# analysis set. `nested_resamples()` builds the other, so its inner splits
# index the whole data. Each tree builds both designs from the same seeds,
# then times `check_nested()` 5 times on each and prints the median.

args <- commandArgs(trailingOnly = TRUE)
which_trees <- if (length(args) >= 1L) args[[1L]] else "both"
base_ref <- if (length(args) >= 2L) args[[2L]] else "e499a7f3"
stopifnot(which_trees %in% c("both", "base"))

N_ROWS <- 1e5
OUTER_V <- 10
INNER_TIMES <- 50
REPS <- 5

cat(R.version.string, "|", R.version$platform, "\n")

export_tree <- function(ref) {
  dir <- tempfile("nestedtune-")
  dir.create(dir)
  archive <- file.path(dir, "tree.tar")
  status <- system2("git", c("archive", "--format=tar", "-o", archive, ref))
  stopifnot(status == 0L)
  utils::untar(archive, exdir = dir)
  unlink(archive)
  dir
}

build_designs <- function() {
  set.seed(135)
  d <- data.frame(x = stats::rnorm(N_ROWS), y = stats::rnorm(N_ROWS))
  set.seed(1)
  cv <- rsample::nested_cv(
    d,
    outside = rsample::vfold_cv(v = OUTER_V),
    inside = rsample::bootstraps(times = INNER_TIMES)
  )
  set.seed(1)
  nr <- nested_resamples(
    d,
    outside = rsample::vfold_cv(v = OUTER_V),
    inside = rsample::bootstraps(times = INNER_TIMES)
  )
  list(nested_cv = cv, nested_resamples = nr)
}

time_tree <- function(path, label) {
  suppressMessages(pkgload::load_all(path, quiet = TRUE))
  designs <- build_designs()
  medians <- vapply(
    designs,
    function(design) {
      check_nested(design)
      times <- vapply(
        seq_len(REPS),
        function(i) system.time(check_nested(design))[["elapsed"]],
        numeric(1)
      )
      stats::median(times)
    },
    numeric(1)
  )
  cat(
    sprintf("%-12s %-18s median %.3f s\n", label, names(medians), medians),
    sep = ""
  )
  medians
}

base <- time_tree(export_tree(base_ref), paste0("base ", base_ref))
if (identical(which_trees, "both")) {
  work <- time_tree(".", "working tree")
  drop <- 100 * (1 - work / base)
  cat(sprintf("drop on %-18s %.1f%%\n", names(drop), drop), sep = "")
}
