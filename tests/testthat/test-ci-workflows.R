# The publishing step needs a git working tree it does not create by itself.
#
# `JamesIves/github-pages-deploy-action` runs `git config user.name` inside the
# workspace before it does anything else, so a job that only unpacks an artifact
# into an otherwise empty runner directory dies with `fatal: not in a git
# directory`. That is what the first run of `pkgdown.yaml` on the default branch
# did: every pull-request run before it was green because the step's `if:` guard
# skips deploying off that branch, so it had never once executed.
#
# `pkgdown.yaml` builds and deploys in two jobs, `build` and `deploy`, so the
# checkout the deploy step needs is `deploy`'s own first step rather than a step
# of the job that built the site. The assertion is the same one either way: a
# checkout precedes the deploy action in the steps the job runs.
#
# `.github/` is `.Rbuildignore`d, so this file has nothing to read when the suite
# runs from a built tarball and skips there. It runs under `devtools::test()` in
# the source tree, which is where a workflow is edited in the first place.

workflow_path <- function(name) {
  test_path("..", "..", ".github", "workflows", name)
}

# The `uses:` values of one job's steps, in the order the job runs them.
#
# Read by indentation rather than with a YAML parser, because `yaml` is not a
# dependency of this package and adding one to assert a property of two lines
# would cost more than the check is worth. The boundary is findable this way
# only below `jobs:`, where job names are the sole keys at two-space indent
# carrying no value -- above it, `on:`'s `push:` and `pull_request:` look
# identical, which is why the search starts there and not at line one.
job_uses <- function(path, job) {
  lines <- readLines(path, warn = FALSE)

  jobs_at <- grep("^jobs:\\s*$", lines)
  headers <- grep("^  [A-Za-z0-9_-]+:\\s*$", lines)
  headers <- headers[headers > jobs_at[[1]]]

  start <- headers[lines[headers] == paste0("  ", job, ":")]
  if (length(start) != 1L) {
    return(NULL)
  }

  later <- headers[headers > start]
  end <- if (length(later)) later[[1]] - 1L else length(lines)

  block <- lines[start:end]
  hits <- grep("^\\s*(- )?uses:\\s*\\S+", block, value = TRUE)
  trimws(sub("^\\s*(- )?uses:\\s*", "", hits))
}

test_that("the pkgdown deploy job checks out before it deploys", {
  path <- workflow_path("pkgdown.yaml")
  skip_if_not(
    file.exists(path),
    "workflow sources are not in the built package"
  )

  uses <- job_uses(path, "deploy")
  expect_false(is.null(uses))

  checkout <- grep("^actions/checkout", uses)
  deploy <- grep("github-pages-deploy-action", uses)

  expect_length(deploy, 1L)
  expect_gte(length(checkout), 1L)
  expect_lt(checkout[[1]], deploy[[1]])
})

# `deploy` is `pkgdown.yaml`'s last job, so nothing there can tell a read that
# stops at the job boundary from one that runs off the end.
# `pr-commands.yaml` still has two jobs in sequence, which is what makes the
# boundary observable at all -- without it the ordering test above would pass
# just as well over a reader that swept in a neighbouring job's checkout.
test_that("job_uses() reads a job's steps in order and stops at the next job", {
  path <- workflow_path("pr-commands.yaml")
  skip_if_not(
    file.exists(path),
    "workflow sources are not in the built package"
  )

  uses <- job_uses(path, "document")

  expect_match(uses[[1]], "^actions/checkout")

  # `style` follows `document` and ends with the same `pr-push` step. A block
  # boundary that ran past `document` would report that step twice.
  expect_length(grep("pr-push", uses), 1L)

  expect_null(job_uses(path, "no-such-job"))
})

# The value of `key:` on the line after the one matching `anchor`'s step, read
# up to that step's end. A step starts at a `- ` line, so the block runs from
# the anchor to the next line at the same or smaller indent that starts one.
step_value <- function(lines, anchor, key) {
  start <- grep(anchor, lines, fixed = TRUE)
  if (length(start) != 1L) {
    return(NULL)
  }
  indent <- nchar(sub("-.*$", "", lines[[start]]))
  later <- which(
    seq_along(lines) > start &
      grepl("^\\s*- ", lines) &
      nchar(sub("-.*$", "", lines)) <= indent
  )
  end <- if (length(later)) later[[1]] - 1L else length(lines)
  hit <- grep(paste0("^\\s*", key, ":\\s"), lines[start:end], value = TRUE)
  if (length(hit) != 1L) {
    return(NULL)
  }
  trimws(sub(paste0("^\\s*", key, ":\\s*"), "", hit))
}

# The two string arms of `${{ matrix.config.os == '<os>' && '<a>' || '<b>' }}`,
# or NULL when the value is not that one expression.
os_arms <- function(value, os) {
  pattern <- paste0(
    "^\\$\\{\\{ matrix\\.config\\.os == '",
    os,
    "' && '([^']+)' \\|\\| '([^']+)' \\}\\}$"
  )
  if (is.null(value) || !grepl(pattern, value)) {
    return(NULL)
  }
  c(on = sub(pattern, "\\1", value), off = sub(pattern, "\\2", value))
}

# Only the macOS leg builds and checks the vignettes, which buys the other four
# legs' check step the time the vignettes cost them. `args` is written out on
# both arms because setting it replaces the action's default of
# `c("--no-manual","--as-cran")`, which would otherwise drop `--as-cran`.
test_that("R-CMD-check.yaml builds and checks the vignettes on macOS alone", {
  path <- workflow_path("R-CMD-check.yaml")
  skip_if_not(
    file.exists(path),
    "workflow sources are not in the built package"
  )
  lines <- readLines(path, warn = FALSE)

  expect_length(grep("^\\s*- \\{os: macos-latest,", lines), 1L)

  anchor <- "uses: r-lib/actions/check-r-package@"
  build_args <- os_arms(step_value(lines, anchor, "build_args"), "macos-latest")
  args <- os_arms(step_value(lines, anchor, "args"), "macos-latest")

  expect_identical(
    build_args,
    c(
      on = 'c("--no-manual","--compact-vignettes=gs+qpdf")',
      off = 'c("--no-manual","--no-build-vignettes")'
    )
  )
  expect_identical(
    args,
    c(
      on = 'c("--no-manual","--as-cran")',
      off = 'c("--no-manual","--as-cran","--ignore-vignettes")'
    )
  )
})
