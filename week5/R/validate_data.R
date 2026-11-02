# Run both implementations, test important edge cases, and write English reports.
# Run from the repository root: Rscript --vanilla week5/R/validate_data.R

run_comparison <- function() {
  paths <- c(unlist(lapply(sys.frames(), function(x) x$ofile)),
             sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)))
  candidates <- c(getwd(), file.path(getwd(), "week5"), file.path(getwd(), ".."),
                  file.path(dirname(paths), ".."))
  found <- candidates[file.exists(file.path(candidates, "data/raw/countries.txt"))]
  if (!length(found)) stop("Cannot locate week5/data/raw.")
  root <- normalizePath(found[1], winslash = "/", mustWork = TRUE)
  reports <- file.path(root, "reports", "validation")
  dir.create(reports, recursive = TRUE, showWarnings = FALSE)
  previous <- options(week5.functions_only = TRUE)
  on.exit(options(previous), add = TRUE)
  primary <- new.env(parent = globalenv())
  agent <- new.env(parent = globalenv())
  sys.source(file.path(root, "R/create_final_data.R"), envir = primary)
  sys.source(file.path(root, "R/create_final_data_agent.R"), envir = agent)
  run_clean <- function(script, log) {
    status <- system2(file.path(R.home("bin"), "Rscript"),
      c("--vanilla", shQuote(file.path(root, "R", script))),
      stdout = file.path(reports, log), stderr = file.path(reports, log))
    if (status != 0L) stop("Clean-session run failed: ", script)
  }
  primary_time <- system.time(run_clean("create_final_data.R", "primary_run.log"))[["elapsed"]]
  agent_time <- system.time(run_clean("create_final_data_agent.R", "agent_run.log"))[["elapsed"]]

  read_result <- function(file) read.csv(file.path(root, "data/processed", file),
    stringsAsFactors = FALSE, fileEncoding = "UTF-8")
  main <- read_result("final_data.csv")
  alternative <- read_result("final_data_agent.csv")
  checks <- data.frame(check = character(), passed = logical())
  check <- function(label, condition) {
    passed <- isTRUE(condition)
    checks <<- rbind(checks, data.frame(check = label, passed = passed))
    if (!passed) stop("Validation failed: ", label)
  }
  check("Both implementations have the same dimensions", identical(dim(main), dim(alternative)))
  check("Both implementations have the same ordered column names", identical(names(main), names(alternative)))
  check("All 74400 output cells and missing-value positions match exactly", identical(main, alternative))
  check("Exactly 3720 country-years and 20 variables", identical(dim(main), c(3720L, 20L)))
  check("Exactly 186 countries and years 2000 through 2019", length(unique(main$iso)) == 186L &&
          identical(sort(unique(main$year)), 2000:2019))
  check("One row per country-year", !anyNA(main[c("iso", "year")]) &&
          !anyDuplicated(main[c("iso", "year")]))
  check("Every country has 20 years", all(table(main$iso) == 20L))
  check("Country and region labels are present", !anyNA(main[c("country_name", "region", "sub_region")]))
  flags <- c("armed_conflict_lag1", "earthquake", "drought")
  check("All three event indicators are complete and binary", all(vapply(main[flags],
    function(x) !anyNA(x) && all(x %in% 0:1), logical(1))))

  raw_file <- function(name) file.path(root, "data/raw", name)
  conflict <- read.csv(raw_file("conflict.csv"))
  source_status <- primary$prepare_conflicts(conflict)
  for (year in c(2000L, 2019L)) {
    expected <- source_status[source_status$year == year - 1L, ]
    actual <- main[main$year == year, ]
    check(paste("Exposure in", year, "matches all source-country statuses in", year - 1L),
      identical(actual$armed_conflict_lag1, expected$armed_conflict[match(actual$iso, expected$iso)]))
  }
  outcomes <- c("maternal_mortality", "infant_mortality", "neonatal_mortality", "under5_mortality")
  for (outcome in outcomes) {
    wide <- read.csv(raw_file(paste0(outcome, ".csv")))
    expected <- as.matrix(wide[paste0("X", 2000:2019)])[
      cbind(match(main$iso, wide$iso), match(main$year, 2000:2019))]
    check(paste("All source values and NAs preserved:", outcome),
          isTRUE(all.equal(main[[outcome]], expected, check.attributes = FALSE, tolerance = 0)))
  }
  covariates <- read.csv(raw_file("covariates.csv"))
  order_in_source <- match(paste(main$iso, main$year), paste(covariates$iso, covariates$year))
  for (column in setdiff(names(covariates), c("iso", "year"))) {
    check(paste("All source values and NAs preserved:", column),
          identical(main[[column]], covariates[[column]][order_in_source]))
  }

  # Tiny, deliberately chosen cases exercise the statistical definitions.
  toy <- data.frame(
    conflict_id = c(1, 1, 1, 2, 1, NA, 1), iso = "AAA",
    year = c(1999, 1999, 2000, 2000, 2001, 2002, 2003),
    best = c(12, 13, 12, 13, 24, NA, 26)
  )
  toy_status <- primary$prepare_conflicts(toy)
  check("Sum events within a conflict; 25 qualifies; separate 12 and 13 do not",
        identical(toy_status$armed_conflict, c(1L, 0L, 0L, 0L, 1L)))
  gap <- data.frame(iso = "AAA", year = c(1999L, 2001L), armed_conflict = c(1L, 0L))
  shifted <- primary$lag_conflicts(gap)
  check("Lag uses calendar years even when source years have gaps",
        identical(shifted$year, c(2000L, 2002L)) &&
          identical(shifted$armed_conflict_lag1, c(1L, 0L)))
  broken <- data.frame(conflict_id = 1, iso = "AAA", year = 2000L, best = NA_real_)
  check("Missing death counts on real conflicts stop processing",
        inherits(try(primary$prepare_conflicts(broken), silent = TRUE), "try-error"))
  ambiguous <- rbind(toy[toy$year == 1999L, ],
                     data.frame(conflict_id = NA, iso = "AAA", year = 1999, best = NA))
  check("A no-event placeholder mixed with events stops processing",
        inherits(try(primary$prepare_conflicts(ambiguous), silent = TRUE), "try-error"))
  duplicate <- data.frame(iso = c("AAA", "AAA"), year = 2000L)
  check("Duplicate country-year keys stop processing",
        inherits(try(primary$assert_unique(duplicate, c("iso", "year"), "Test"), silent = TRUE), "try-error"))
  toy_disaster <- data.frame(Year = c(1999, 2000, 2000, 2000, 2000, 2001, 2020),
    ISO = "AAA", type = c("Drought", "Earthquake", "Earthquake", "Drought", "Flood", "Drought", "Earthquake"))
  names(toy_disaster)[3] <- "Disaster Type"
  toy_disaster <- primary$prepare_disasters(toy_disaster)
  check("Disasters use selected years/types, with repeated events counted once",
        identical(toy_disaster$year, c(2000, 2001)) &&
          identical(toy_disaster$earthquake, c(1L, 0L)) &&
          identical(toy_disaster$drought, c(1L, 1L)))

  # Explain an actual methodological difference using the supplied raw data.
  # This alternative sums across unrelated conflict IDs before thresholding.
  events <- conflict[!is.na(conflict$conflict_id), ]
  pooled <- aggregate(best ~ iso + year, events, sum)
  pooled <- merge(pooled, source_status, by = c("iso", "year"))
  differences <- pooled[as.integer(pooled$best >= 25) != pooled$armed_conflict, ]
  names(differences)[names(differences) == "year"] <- "conflict_year"
  names(differences)[names(differences) == "best"] <- "pooled_deaths"
  differences$outcome_year <- differences$conflict_year + 1L
  differences$pooled_indicator <- as.integer(differences$pooled_deaths >= 25)
  differences <- differences[order(differences$iso, differences$conflict_year),
    c("iso", "conflict_year", "outcome_year", "pooled_deaths", "armed_conflict", "pooled_indicator")]
  check("Pooled country totals would change 13 supplied country-years", nrow(differences) == 13L)
  write.csv(differences, file.path(reports, "conflict_definition_differences.csv"), row.names = FALSE)

  missingness <- data.frame(variable = names(main),
    missing_n = vapply(main, function(x) sum(is.na(x)), integer(1)))
  missingness$missing_percent <- round(100 * missingness$missing_n / nrow(main), 2)
  rownames(missingness) <- NULL
  write.csv(missingness, file.path(reports, "missingness.csv"), row.names = FALSE)
  write.csv(checks, file.path(reports, "validation_checks.csv"), row.names = FALSE)
  inventory <- list.files(file.path(root, "data/raw"), full.names = TRUE)
  manifest <- data.frame(file = basename(inventory), bytes = file.info(inventory)$size,
                         md5 = unname(tools::md5sum(inventory)))
  write.csv(manifest, file.path(reports, "input_manifest.csv"), row.names = FALSE)
  writeLines(trimws(capture.output(sessionInfo()), which = "right"),
             file.path(reports, "session_info.txt"))

  for (file in c("final_data.csv", "final_data_agent.csv")) {
    baseline <- read.csv(file.path(root, "..", "week3", "data/processed", file),
                         stringsAsFactors = FALSE, fileEncoding = "UTF-8")
    check(paste("Unchanged from Week 3:", file), identical(read_result(file), baseline))
  }
  write.csv(checks, file.path(reports, "validation_checks.csv"), row.names = FALSE)
  write.csv(data.frame(implementation = c("Primary", "Agent"),
                      elapsed_seconds = c(primary_time, agent_time)),
            file.path(reports, "runtime.csv"), row.names = FALSE)
  message("PASS: ", nrow(checks), " checks; all ", nrow(main) * ncol(main), " cells match.")
  invisible(checks)
}

run_comparison()
