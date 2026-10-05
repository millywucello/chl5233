# Run both implementations, test important edge cases, and write English reports.
# Run from the repository root: Rscript --vanilla week3/scripts/compare_outputs.R

run_comparison <- function() {
  paths <- c(unlist(lapply(sys.frames(), function(x) x$ofile)),
             sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)))
  candidates <- c(getwd(), file.path(getwd(), "week3"), file.path(getwd(), ".."),
                  file.path(dirname(paths), ".."))
  found <- candidates[file.exists(file.path(candidates, "data/raw/countries.txt"))]
  if (!length(found)) stop("Cannot locate week3/data/raw.")
  root <- normalizePath(found[1], winslash = "/", mustWork = TRUE)
  reports <- file.path(root, "reports")
  dir.create(reports, recursive = TRUE, showWarnings = FALSE)
  previous <- options(week3.functions_only = TRUE)
  on.exit(options(previous), add = TRUE)
  primary <- new.env(parent = globalenv())
  agent <- new.env(parent = globalenv())
  sys.source(file.path(root, "scripts/create_final_data.R"), envir = primary)
  sys.source(file.path(root, "scripts/create_final_data_agent.R"), envir = agent)
  primary_time <- system.time(primary$run_primary(root))[["elapsed"]]
  agent_time <- system.time(agent$run_agent(root))[["elapsed"]]

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

  missing_lines <- apply(missingness[missingness$missing_n > 0, ], 1, function(x)
    sprintf("| %s | %s | %s%% |", x[1], trimws(x[2]), trimws(x[3])))
  report <- c(
    "# Week 3 - Implementation comparison and validation", "",
    "## Provenance and comparison design", "",
    "Both scripts were prepared with Codex assistance for this assignment. The primary script is a teaching-oriented solution; the separate agent script is an alternative implementation. No pre-existing, independently student-authored complete solution was supplied, so this report does not claim a human-versus-AI experiment.", "",
    "The agent script reads the nine raw files directly. It does not source the primary script or read final_data.csv. Both implementations follow the same documented data specification; this is implementation diversity, not independent confirmation of the study definition.", "",
    "| Step | Primary script | Separate agent script |",
    "|---|---|---|",
    "| Mortality reshape | Reusable tidyr::pivot_longer() function | Reusable base R reshape() function |",
    "| Disaster indicators | Grouped any() after janitor::clean_names() | Country-year key membership after janitor::clean_names() |",
    "| Conflict aggregation | dplyr grouped sums, then any(total >= 25) | aggregate() and membership in qualifying conflict-country-years |",
    "| One-year lag | Increase the source-year join key by one | Complete the country calendar, then lag within country |",
    "| Merging | left_join() onto the course panel | merge(all.x = TRUE) onto the course panel |", "",
    "## Results", "",
    sprintf("Both exported CSV files contain **%s rows and %s columns**. All **%s cells**, including missing-value locations, match exactly after reading the UTF-8 CSV files back into R. There are **zero output differences**.",
            nrow(main), ncol(main), nrow(main) * ncol(main)), "",
    sprintf("All **%s validation checks passed**. Checks cover unique keys, complete years, binary flags, every supplied mortality/covariate value, both lag endpoints, and synthetic threshold, missing-event, duplicate-key, and disaster cases.", nrow(checks)), "",
    "| Measure | Result |", "|---|---:|",
    sprintf("| Countries | %s |", length(unique(main$iso))),
    "| Outcome years | 2000-2019 |", "| Source conflict years | 1999-2018 |",
    sprintf("| Country-years exposed to conflict in the previous year | %s |", sum(main$armed_conflict_lag1)),
    sprintf("| Country-years with an earthquake | %s |", sum(main$earthquake)),
    sprintf("| Country-years with a drought | %s |", sum(main$drought)),
    sprintf("| No-event conflict placeholders in the input | %s |", sum(is.na(conflict$conflict_id))), "",
    "## Conflict definition and competing implementation", "",
    "The paper's Data section defines a qualifying conflict using cumulative deaths within a calendar-conflict year. Its Measures section describes classification per conflict within a country-year. We therefore sum best within (iso, year, conflict_id), use a threshold of at least 25 deaths, and set the country-year flag to one if any conflict qualifies. The binary flag is then aligned to the following outcome year. See the [paper's Methods](https://journals.plos.org/plosmedicine/article?id=10.1371/journal.pmed.1003810).", "",
    sprintf("A competing implementation that first pools deaths across every conflict in a country-year changes **%s** exposure values. This is a definition comparison, not a disagreement between the two delivered scripts. See [the complete difference table](conflict_definition_differences.csv). For example, separate conflicts totaling 12 and 13 deaths must not jointly qualify as one 25-death conflict under the selected rule.", nrow(differences)), "",
    "The input has exactly one row with both conflict_id and best missing for each no-event country-year. These explicit placeholders are interpreted as no recorded conflict. A real event with an unknown death count, or a placeholder mixed with event records, triggers an error. A missing source country-year also triggers an error instead of silently becoming zero.", "",
    "## Correctness and efficiency", "",
    "Both implementations are correct under the documented specification and produce identical data. The primary script is preferred for this course because its reusable functions and explicit dplyr/tidyr steps closely follow the handout and are easier to inspect and extend. The agent implementation is useful as a cross-check and uses base R for most transformations.", "",
    sprintf("One local run, after loading the script definitions, took **%.3f seconds** for the primary pipeline and **%.3f seconds** for the agent pipeline. These are descriptive wall-clock timings, not a controlled benchmark; caching, execution order, and lazy package initialization affect them. Both are practical for this dataset, and the timings do not establish general superiority.", primary_time, agent_time), "",
    "Both approaches aggregate events before joining and avoid row-by-row iteration over the full conflict input. The primary script uses grouped operations; the agent script uses aggregate() and vectorized key membership. Neither performs a large event-level join against the outcome panel.", "",
    "## Missing data and scope", "",
    "Missing outcomes and covariates remain NA; there is no imputation or complete-case deletion. Maternal mortality is missing for all countries in 2018 and 2019, with additional earlier missing values. The supplied course sample is 186 countries, so the output is a course data-preparation panel and does not claim to reproduce the paper's final analytical sample or regression estimates.", "",
    "| Variable | Missing rows | Percent |", "|---|---:|---:|", missing_lines, "",
    "Disaster zeros mean no recorded earthquake/drought of the requested type and year in the supplied extract. The provided Year field defines occurrence; events are not expanded across their duration. Country names retain source encoding artifacts; joins use ISO codes. Region matches use the supplied lookup.", "",
    "## Reproduce", "", "From the chl5233 repository root:", "", "```sh",
    "Rscript --vanilla week3/scripts/compare_outputs.R", "```", "",
    "This reruns both scripts and replaces their respective CSV outputs, this report, and the validation CSVs. The primary output is never overwritten by the agent output. See [validation checks](validation_checks.csv), [missingness](missingness.csv), [input checksums](input_manifest.csv), and [R session information](session_info.txt)."
  )
  writeLines(report, file.path(reports, "comparison.md"), useBytes = TRUE)
  message("PASS: ", nrow(checks), " checks; all ", nrow(main) * ncol(main), " cells match.")
  invisible(checks)
}

run_comparison()
