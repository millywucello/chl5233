# CHL5233 Week 3: primary, teaching-oriented implementation.
# Prepared with Codex assistance. See reports/comparison.md for provenance.
# Run from the repository root: Rscript --vanilla week3/scripts/create_final_data.R

locate_week3 <- function() {
  source_paths <- unlist(lapply(sys.frames(), function(x) x$ofile))
  cli_paths <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE))
  candidates <- unique(c(
    getwd(), file.path(getwd(), "week3"), file.path(getwd(), ".."),
    file.path(dirname(c(source_paths, cli_paths)), "..")
  ))
  found <- candidates[file.exists(file.path(candidates, "data/raw/countries.txt"))]
  if (!length(found)) stop("Cannot locate week3/data/raw. Open the chl5233 folder first.")
  normalizePath(found[1], winslash = "/", mustWork = TRUE)
}

required_packages <- c("dplyr", "tidyr", "janitor")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages)) {
  stop("Install these R packages before running: ", paste(missing_packages, collapse = ", "))
}
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tidyr))

assert_unique <- function(data, keys, label) {
  if (anyNA(data[keys]) || anyDuplicated(data[keys])) {
    stop(label, " must have non-missing, unique keys: ", paste(keys, collapse = ", "))
  }
  invisible(data)
}

# The same function is applied to all four World Bank mortality files.
# pivot_longer() belongs to tidyr (the handout calls it a dplyr function).
prepare_mortality <- function(data, outcome_name, years = 2000:2019) {
  year_columns <- paste0("X", years)
  stopifnot(all(c("iso", year_columns) %in% names(data)))
  assert_unique(data, "iso", outcome_name)
  data |>
    select(iso, all_of(year_columns)) |>
    pivot_longer(
      cols = all_of(year_columns), names_to = "year", names_prefix = "X",
      names_transform = list(year = as.integer), values_to = outcome_name
    ) |>
    arrange(iso, year)
}

prepare_disasters <- function(data) {
  selected <- data |>
    janitor::clean_names() |>
    filter(year >= 2000L, year <= 2019L,
           disaster_type %in% c("Earthquake", "Drought")) |>
    select(year, iso, disaster_type)
  if (anyNA(selected[c("iso", "year")])) stop("A selected disaster has a missing key.")
  selected |>
    group_by(iso, year) |>
    summarise(
      earthquake = as.integer(any(disaster_type == "Earthquake")),
      drought = as.integer(any(disaster_type == "Drought")), .groups = "drop"
    ) |>
    select(year, iso, earthquake, drought)
}

prepare_conflicts <- function(data) {
  stopifnot(all(c("conflict_id", "iso", "year", "best") %in% names(data)))
  if (anyNA(data[c("iso", "year")])) stop("Conflict data contain a missing key.")
  if (any(xor(is.na(data$conflict_id), is.na(data$best)))) {
    stop("A real conflict record has missing deaths or a missing conflict ID.")
  }
  if (any(!is.finite(data$best[!is.na(data$best)])) ||
      any(data$best < 0, na.rm = TRUE)) stop("Invalid battle-related death count.")
  # The supplied file explicitly represents no-event country-years as one row
  # with BOTH conflict_id and best missing. Never treat a partially missing
  # event record as zero, and never discard identical event rows as duplicates.
  invalid_placeholders <- data |>
    group_by(iso, year) |>
    summarise(invalid = any(is.na(conflict_id)) & n() != 1L, .groups = "drop")
  if (any(invalid_placeholders$invalid)) stop("Ambiguous no-event placeholder.")

  conflict_totals <- data |>
    filter(!is.na(conflict_id)) |>
    group_by(iso, year, conflict_id) |>
    summarise(conflict_deaths = sum(best), .groups = "drop")
  country_status <- conflict_totals |>
    group_by(iso, year) |>
    summarise(armed_conflict = as.integer(any(conflict_deaths >= 25)),
              .groups = "drop")
  data |>
    distinct(iso, year) |>
    left_join(country_status, by = c("iso", "year")) |>
    mutate(armed_conflict = replace_na(armed_conflict, 0L)) |>
    arrange(iso, year)
}

# Match exact calendar years: exposure in outcome year t comes from year t - 1.
# Shifting the year key avoids accidentally lagging across gaps in event rows.
lag_conflicts <- function(data) {
  data |>
    transmute(iso, year = as.integer(year) + 1L,
              armed_conflict_lag1 = armed_conflict)
}

run_primary <- function(root = locate_week3()) {
  raw <- file.path(root, "data", "raw")
  processed <- file.path(root, "data", "processed")
  dir.create(processed, recursive = TRUE, showWarnings = FALSE)
  read_raw <- function(name) read.csv(file.path(raw, name), stringsAsFactors = FALSE)
  countries <- read.table(file.path(raw, "countries.txt"), header = TRUE,
                          stringsAsFactors = FALSE, fileEncoding = "latin1") |>
    rename(iso = ISO)
  regions <- read.table(file.path(raw, "regions.txt"), header = TRUE,
                        stringsAsFactors = FALSE, fileEncoding = "latin1") |>
    transmute(iso = country_code, region, sub_region)
  assert_unique(countries, "iso", "Country list")
  assert_unique(regions, "iso", "Region lookup")
  stopifnot(nrow(countries) == 186L,
            all(countries$iso %in% regions$iso))

  # Keep the complete course-supplied country-year frame; outcome-specific
  # missingness must not decide the sample for all future analyses.
  panel <- crossing(iso = countries$iso, year = 2000:2019) |>
    left_join(countries, by = "iso") |>
    left_join(regions, by = "iso")

  mortality_names <- c("maternal_mortality", "infant_mortality",
                       "neonatal_mortality", "under5_mortality")
  for (outcome in mortality_names) {
    mortality <- prepare_mortality(read_raw(paste0(outcome, ".csv")), outcome)
    assert_unique(mortality, c("iso", "year"), outcome)
    stopifnot(setequal(mortality$iso, countries$iso), nrow(mortality) == nrow(panel))
    panel <- left_join(panel, mortality, by = c("iso", "year"))
  }

  disaster <- prepare_disasters(read_raw("disaster.csv"))
  assert_unique(disaster, c("iso", "year"), "Disaster indicators")
  # Only absence of a recorded selected event becomes zero. Missing mortality
  # and covariate values are retained as NA throughout the pipeline.
  panel <- panel |>
    left_join(disaster, by = c("iso", "year")) |>
    mutate(earthquake = replace_na(earthquake, 0L), drought = replace_na(drought, 0L))

  conflict <- prepare_conflicts(read_raw("conflict.csv"))
  assert_unique(conflict, c("iso", "year"), "Conflict status")
  lagged <- lag_conflicts(conflict)
  stopifnot(nrow(anti_join(panel, lagged, by = c("iso", "year"))) == 0L)
  panel <- left_join(panel, lagged, by = c("iso", "year"))

  covariates <- read_raw("covariates.csv")
  assert_unique(covariates, c("iso", "year"), "Covariates")
  stopifnot(nrow(anti_join(panel, covariates, by = c("iso", "year"))) == 0L)
  final <- panel |>
    left_join(covariates, by = c("iso", "year")) |>
    select(iso, country_name, year, region, sub_region, all_of(mortality_names),
           earthquake, drought, armed_conflict_lag1, all_of(setdiff(names(covariates), c("iso", "year")))) |>
    arrange(iso, year)
  assert_unique(final, c("iso", "year"), "Final data")
  stopifnot(nrow(final) == 3720L, ncol(final) == 20L,
            all(final$armed_conflict_lag1 %in% 0:1),
            all(final$earthquake %in% 0:1), all(final$drought %in% 0:1))
  write.csv(final, file.path(processed, "final_data.csv"), row.names = FALSE,
            na = "NA", fileEncoding = "UTF-8")
  message("Primary output: ", nrow(final), " rows x ", ncol(final), " columns.")
  invisible(final)
}

if (!isTRUE(getOption("week3.functions_only", FALSE))) run_primary()
