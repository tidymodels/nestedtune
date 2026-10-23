# Whether renaming test blocks lost or changed any of them.
#
# Reads two `benchmarks/test-blocks.R` tables, one from the tree before the
# rename and one from the tree after, and a rename map with the columns
# `file`, `old` and `new`. A name absent from the map maps to itself.
#
#   Rscript benchmarks/test-renames-check.R <ref> before.csv after.csv map.csv
#
# Blocks: every row of the earlier table is in the later one under its mapped
# name, with the same expectation count, and the later table has as many rows.
# Snapshots: each `tests/testthat/_snaps/*.md` file, read at `<ref>` through
# `git show` and from the working tree, splits into sections at its `# name`
# lines. Every earlier section is in the later file under its mapped name with
# an identical body, and the later file has no other sections. Every `.svg`
# under `_snaps/` is byte-identical at both trees. Prints one line per
# mismatch and a summary; exits 1 on any mismatch.

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 4L)
ref <- args[1L]
before <- utils::read.csv(args[2L], stringsAsFactors = FALSE)
after <- utils::read.csv(args[3L], stringsAsFactors = FALSE)
map <- utils::read.csv(args[4L], stringsAsFactors = FALSE)
stopifnot(nrow(before) > 0L, nrow(after) > 0L, nrow(map) > 0L)
stopifnot(!anyDuplicated(map[c("file", "old")]))

mapped <- function(file, name) {
  key <- match(paste(file, name), paste(map$file, map$old))
  ifelse(is.na(key), name, map$new[key])
}

bad <- 0L
report <- function(...) {
  cat(sprintf(...), "\n", sep = "")
  bad <<- bad + 1L
}

# Blocks.
before$new <- mapped(before$file, before$test)
hit <- match(paste(before$file, before$new), paste(after$file, after$test))
for (i in which(is.na(hit))) {
  report("block missing: %s: %s", before$file[i], before$test[i])
}
moved <- which(
  !is.na(hit) & before$expectations != after$expectations[hit]
)
for (i in moved) {
  report(
    "expectations moved: %s: %s: %d -> %d",
    before$file[i],
    before$new[i],
    before$expectations[i],
    after$expectations[hit[i]]
  )
}
if (nrow(after) != nrow(before)) {
  report("row count: %d -> %d", nrow(before), nrow(after))
}

# Snapshots.
sections <- function(lines) {
  head <- grep("^# ", lines)
  if (!length(head)) {
    return(list())
  }
  ends <- c(head[-1L] - 1L, length(lines))
  out <- lapply(seq_along(head), function(k) {
    paste(
      lines[seq.int(head[k] + 1L, length.out = ends[k] - head[k])],
      collapse = "\n"
    )
  })
  stats::setNames(out, sub("^# ", "", lines[head]))
}
git_lines <- function(path) {
  system2("git", c("show", paste0(ref, ":", path)), stdout = TRUE)
}
snap_dir <- "tests/testthat/_snaps"
listed <- system2(
  "git",
  c("ls-tree", "-r", "--name-only", ref, paste0(snap_dir, "/")),
  stdout = TRUE
)
md <- grep("\\.md$", listed, value = TRUE)
svg <- grep("\\.svg$", listed, value = TRUE)
stopifnot(length(md) > 0L)
n_sections <- 0L
for (path in md) {
  test_file <- paste0("test-", sub("\\.md$", ".R", basename(path)))
  old <- sections(git_lines(path))
  now <- if (file.exists(path)) sections(readLines(path)) else list()
  n_sections <- n_sections + length(old)
  want <- mapped(rep(test_file, length(old)), names(old))
  for (k in seq_along(old)) {
    if (!want[k] %in% names(now)) {
      report("snapshot missing: %s: %s", path, names(old)[k])
    } else if (!identical(now[[want[k]]], old[[k]])) {
      report("snapshot body differs: %s: %s", path, want[k])
    }
  }
  for (extra in setdiff(names(now), want)) {
    report("snapshot added: %s: %s", path, extra)
  }
}
now_md <- list.files(snap_dir, "\\.md$", recursive = TRUE, full.names = TRUE)
for (path in setdiff(now_md, md)) {
  report("snapshot file added: %s", path)
}
for (path in svg) {
  old <- system2("git", c("show", paste0(ref, ":", path)), stdout = TRUE)
  if (!file.exists(path) || !identical(readLines(path, warn = FALSE), old)) {
    report("svg differs: %s", path)
  }
}

cat(sprintf(
  "%d blocks before, %d after | %d snapshot sections in %d files | %d svg files | %d mismatches\n",
  nrow(before),
  nrow(after),
  n_sections,
  length(md),
  length(svg),
  bad
))
quit(status = as.integer(bad > 0L))
