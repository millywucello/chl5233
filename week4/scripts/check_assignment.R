# Run with Rscript --vanilla week4/scripts/check_assignment.R.
locate_week4 <- function() {
  cli <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE))
  sourced <- unlist(lapply(sys.frames(), function(x) x$ofile))
  candidates <- unique(c(file.path(getwd(), "week4"), getwd(),
                         file.path(dirname(c(cli, sourced)), "..")))
  found <- candidates[file.exists(file.path(candidates, "pivotwbmilly", "DESCRIPTION"))]
  if (!length(found)) stop("Open the chl5233 or week4 folder first.")
  normalizePath(found[1], winslash = "/")
}

run_checks <- function() {
  root <- locate_week4()
  package_dir <- file.path(root, "pivotwbmilly")
  reports <- file.path(root, "reports")
  dir.create(reports, showWarnings = FALSE)
  required <- c("roxygen2", "testthat", "rcmdcheck", "knitr", "rmarkdown")
  missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) stop("Install: ", paste(missing, collapse = ", "))

  # Use Positron's bundled Pandoc when it is not on the shell PATH.
  if (!rmarkdown::pandoc_available()) {
    pandoc_dir <- "/Applications/Positron.app/Contents/Resources/app/quarto/bin/tools/aarch64"
    if (file.exists(file.path(pandoc_dir, "pandoc"))) {
      old_pandoc <- Sys.getenv("RSTUDIO_PANDOC", unset = NA_character_)
      on.exit(if (is.na(old_pandoc)) Sys.unsetenv("RSTUDIO_PANDOC") else
        Sys.setenv(RSTUDIO_PANDOC = old_pandoc), add = TRUE)
      Sys.setenv(RSTUDIO_PANDOC = pandoc_dir)
      rmarkdown::find_pandoc(cache = FALSE)
    }
  }
  if (!rmarkdown::pandoc_available()) stop("Install Pandoc to build the tutorial.")

  original_data <- file.path(root, "..", "week3", "data", "raw")
  data_env <- new.env(parent = baseenv())
  data_env$maternal_mortality <- read.csv(
    file.path(package_dir, "data-raw", "maternal_mortality.csv"),
    stringsAsFactors = FALSE
  )
  save(list = "maternal_mortality", envir = data_env,
       file = file.path(package_dir, "data", "maternal_mortality.rda"),
       compress = "xz", version = 2)
  roxygen2::roxygenise(package_dir)
  test_results <- testthat::test_local(package_dir, reporter = "summary")
  test_details <- as.data.frame(test_results)
  if (any(test_details$failed > 0 | test_details$error | test_details$warning > 0 |
          test_details$skipped)) stop("Tests did not finish cleanly.")

  checks <- data.frame(check = character(), passed = logical(), detail = character())
  record <- function(label, ok, detail) {
    checks[nrow(checks) + 1L, ] <<- list(label, isTRUE(ok), detail)
    if (!isTRUE(ok)) stop("Validation failed: ", label)
  }
  record("Package tests", all(test_details$failed == 0),
         paste(nrow(test_details), "test blocks;", sum(test_details$passed),
               "expectations passed"))

  old_option <- getOption("week3.functions_only")
  on.exit(options(week3.functions_only = old_option), add = TRUE)
  options(week3.functions_only = TRUE)
  reference <- new.env(parent = globalenv())
  sys.source(file.path(root, "..", "week3", "scripts", "create_final_data.R"),
             envir = reference)

  measures <- c("maternal_mortality", "infant_mortality",
                "neonatal_mortality", "under5_mortality")
  for (measure in measures) {
    input <- read.csv(file.path(original_data, paste0(measure, ".csv")),
                      stringsAsFactors = FALSE)
    expected <- reference$prepare_mortality(input, measure)
    actual <- pivotwbmilly::prepare_mortality(input, measure)
    record(paste("Week 3 agreement:", measure), identical(actual, expected),
           paste(nrow(actual), "rows; all values, types, and missing positions agree"))
  }
  source_csv <- file.path(original_data, "maternal_mortality.csv")
  bundled_csv <- file.path(package_dir, "data-raw", "maternal_mortality.csv")
  record("Maternal source file unchanged",
         identical(unname(tools::md5sum(source_csv)), unname(tools::md5sum(bundled_csv))),
         unname(tools::md5sum(bundled_csv)))
  record("Bundled data match the source",
         identical(pivotwbmilly::maternal_mortality,
                   read.csv(source_csv, stringsAsFactors = FALSE)),
         "186 rows and 22 columns; no recoding")

  check_dir <- tempfile("pivotwbmilly-check-")
  build <- rcmdcheck::rcmdcheck(
    package_dir, args = "--no-manual", build_args = "--no-manual",
    check_dir = check_dir, error_on = "never", quiet = FALSE
  )
  writeLines(readLines(file.path(check_dir, "pivotwbmilly.Rcheck", "00check.log"),
                      warn = FALSE),
             file.path(reports, "package_check.txt"))
  record("R CMD check", !length(build$errors) && !length(build$warnings) &&
           !length(build$notes),
         paste(length(build$errors), "errors,", length(build$warnings), "warnings,",
               length(build$notes), "notes; examples, tests, and vignette checked"))
  write.csv(checks, file.path(reports, "validation_checks.csv"), row.names = FALSE)
  writeLines(trimws(capture.output(sessionInfo()), which = "right"),
             file.path(reports, "session_info.txt"))
  message("All ", nrow(checks), " assignment checks passed.")
  invisible(checks)
}

run_checks()
