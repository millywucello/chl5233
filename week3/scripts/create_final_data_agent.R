# CHL5233 Week 3: separate Codex comparison implementation.
# This script does not source the primary script or read its output.
# It uses base R reshape/aggregate/merge and janitor::clean_names().
# Run: Rscript --vanilla week3/scripts/create_final_data_agent.R

agent_root <- function() {
  paths <- c(unlist(lapply(sys.frames(), function(x) x$ofile)),
             sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)))
  candidates <- c(getwd(), file.path(getwd(), "week3"), file.path(getwd(), ".."),
                  file.path(dirname(paths), ".."))
  found <- candidates[file.exists(file.path(candidates, "data/raw/countries.txt"))]
  if (!length(found)) stop("Cannot locate the Week 3 raw data.")
  normalizePath(found[1], winslash = "/", mustWork = TRUE)
}

agent_unique <- function(data, keys) {
  stopifnot(!anyNA(data[keys]), !anyDuplicated(data[keys]))
}

agent_mortality <- function(data, outcome) {
  agent_unique(data, "iso")
  years <- 2000:2019
  long <- reshape(data[c("iso", paste0("X", years))],
                  varying = paste0("X", years), v.names = outcome,
                  timevar = "year", times = years, idvar = "iso", direction = "long")
  rownames(long) <- NULL
  long[c("iso", "year", outcome)]
}

run_agent <- function(root = agent_root()) {
  if (!requireNamespace("janitor", quietly = TRUE)) stop("Install the janitor package.")
  raw <- file.path(root, "data/raw")
  read_raw <- function(name) read.csv(file.path(raw, name), stringsAsFactors = FALSE)
  countries <- read.table(file.path(raw, "countries.txt"), header = TRUE,
                          stringsAsFactors = FALSE, fileEncoding = "latin1")
  names(countries)[names(countries) == "ISO"] <- "iso"
  regions <- read.table(file.path(raw, "regions.txt"), header = TRUE,
                        stringsAsFactors = FALSE, fileEncoding = "latin1")
  names(regions)[names(regions) == "country_code"] <- "iso"
  agent_unique(countries, "iso")
  agent_unique(regions, "iso")
  stopifnot(nrow(countries) == 186L, all(countries$iso %in% regions$iso))
  result <- expand.grid(iso = countries$iso, year = 2000:2019, stringsAsFactors = FALSE)
  result <- merge(result, countries, by = "iso", all.x = TRUE)
  result <- merge(result, regions[c("iso", "region", "sub_region")], by = "iso", all.x = TRUE)
  outcomes <- c("maternal_mortality", "infant_mortality", "neonatal_mortality", "under5_mortality")
  for (outcome in outcomes) {
    long <- agent_mortality(read_raw(paste0(outcome, ".csv")), outcome)
    agent_unique(long, c("iso", "year"))
    stopifnot(setequal(long$iso, countries$iso), nrow(long) == 3720L)
    result <- merge(result, long, by = c("iso", "year"), all.x = TRUE)
  }

  disaster <- janitor::clean_names(read_raw("disaster.csv"))
  selected <- disaster[disaster$year %in% 2000:2019 &
                         disaster$disaster_type %in% c("Earthquake", "Drought"),
                       c("iso", "year", "disaster_type")]
  stopifnot(!anyNA(selected[c("iso", "year")]))
  result_key <- paste(result$iso, result$year, sep = ":")
  # Membership makes repeated events binary and also fills absent events with 0.
  for (event in c("Earthquake", "Drought")) {
    event_rows <- selected[selected$disaster_type == event, ]
    keys <- paste(event_rows$iso, event_rows$year, sep = ":")
    result[[tolower(event)]] <- as.integer(result_key %in% keys)
  }

  conflict <- read_raw("conflict.csv")
  stopifnot(!anyNA(conflict[c("iso", "year")]),
            identical(is.na(conflict$best), is.na(conflict$conflict_id)),
            all(is.finite(conflict$best[!is.na(conflict$best)])),
            all(conflict$best[!is.na(conflict$best)] >= 0))
  raw_key <- paste(conflict$iso, conflict$year, sep = ":")
  placeholders <- is.na(conflict$conflict_id)
  key_counts <- table(raw_key)
  stopifnot(all(key_counts[raw_key[placeholders]] == 1L))
  events <- conflict[!placeholders, ]
  totals <- aggregate(best ~ iso + year + conflict_id, data = events, FUN = sum)
  qualifying <- totals[totals$best >= 25, c("iso", "year")]
  # Complete the observed source-year grid before applying a within-country lag.
  timeline <- expand.grid(iso = countries$iso, year = 1999:2019, stringsAsFactors = FALSE)
  timeline <- timeline[order(timeline$iso, timeline$year), ]
  timeline_key <- paste(timeline$iso, timeline$year, sep = ":")
  required_key <- timeline_key[timeline$year < 2019L]
  stopifnot(all(required_key %in% raw_key))
  timeline$status <- as.integer(timeline_key %in% paste(qualifying$iso, qualifying$year, sep = ":"))
  # 2019 is a structural row only: contemporaneous 2019 exposure was not supplied.
  timeline$status[timeline$year == 2019L] <- NA_integer_
  timeline$armed_conflict_lag1 <- as.integer(ave(timeline$status, timeline$iso,
    FUN = function(x) c(NA_integer_, head(x, -1L))))
  lagged <- timeline[timeline$year %in% 2000:2019, c("iso", "year", "armed_conflict_lag1")]
  result <- merge(result, lagged, by = c("iso", "year"), all.x = TRUE)

  covariates <- read_raw("covariates.csv")
  agent_unique(covariates, c("iso", "year"))
  stopifnot(all(paste(result$iso, result$year) %in% paste(covariates$iso, covariates$year)))
  result <- merge(result, covariates, by = c("iso", "year"), all.x = TRUE)
  columns <- c("iso", "country_name", "year", "region", "sub_region", outcomes,
               "earthquake", "drought", "armed_conflict_lag1",
               setdiff(names(covariates), c("iso", "year")))
  result <- result[order(result$iso, result$year), columns]
  rownames(result) <- NULL
  agent_unique(result, c("iso", "year"))
  stopifnot(nrow(result) == 3720L, ncol(result) == 20L,
            all(result$armed_conflict_lag1 %in% 0:1))
  dir.create(file.path(root, "data/processed"), recursive = TRUE, showWarnings = FALSE)
  write.csv(result, file.path(root, "data/processed/final_data_agent.csv"),
            row.names = FALSE, na = "NA", fileEncoding = "UTF-8")
  message("Agent output: ", nrow(result), " rows x ", ncol(result), " columns.")
  invisible(result)
}

if (!isTRUE(getOption("week3.functions_only", FALSE))) run_agent()
