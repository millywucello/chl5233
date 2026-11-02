# Run from chl5233 with Rscript --vanilla week5/R/summarise_eda.R.
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(ggplot2))

paths <- c(sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)),
           unlist(lapply(sys.frames(), function(x) x$ofile)))
candidates <- c(file.path(getwd(), "week5"), getwd(), file.path(dirname(paths), ".."))
root <- candidates[file.exists(file.path(candidates, "data/processed/final_data.csv"))][1]
if (is.na(root)) stop("Cannot locate Week 5 data.")
root <- normalizePath(root)
tables <- file.path(root, "reports/tables")
figures <- file.path(root, "reports/figures")
dir.create(tables, recursive = TRUE, showWarnings = FALSE)
dir.create(figures, recursive = TRUE, showWarnings = FALSE)
save_table <- function(x, name) write.csv(x, file.path(tables, name), row.names = FALSE)
save_plot <- function(p, name, width = 9, height = 5.5) {
  ggsave(file.path(figures, name), p, width = width, height = height,
         dpi = 220, bg = "white")
}
theme_set(theme_minimal(base_size = 12) +
            theme(panel.grid.minor = element_blank(), legend.position = "bottom"))
d <- read.csv(file.path(root, "data/processed/final_data.csv"), fileEncoding = "UTF-8")
c <- read.csv(file.path(root, "data/raw/conflict.csv"))
stopifnot(!anyDuplicated(d[c("iso", "year")]), !anyNA(c[c("iso", "year")]))

# Conflict IDs identify conflicts; repeated rows are not necessarily duplicate events.
events <- c |> filter(!is.na(conflict_id))
annual <- c |> group_by(year) |> summarise(
  source_rows = n(), countries_covered = n_distinct(iso),
  no_event_placeholders = sum(is.na(conflict_id)), .groups = "drop") |>
  left_join(events |> group_by(year) |> summarise(
    event_records = n(), recorded_conflicts = n_distinct(conflict_id),
    countries_with_events = n_distinct(iso), .groups = "drop"), by = "year")
qualifying <- events |> group_by(iso, year, conflict_id) |>
  summarise(deaths = sum(best), .groups = "drop") |> filter(deaths >= 25)
annual <- annual |> left_join(qualifying |> group_by(year) |> summarise(
  qualifying_conflicts = n_distinct(conflict_id),
  qualifying_country_conflicts = n(), countries_with_conflict = n_distinct(iso),
  .groups = "drop"), by = "year") |> arrange(year)
stopifnot(all(annual$countries_covered == 186), identical(annual$year, 1999:2018),
          all(annual$qualifying_conflicts <= annual$recorded_conflicts),
          all(annual$countries_with_conflict <= annual$countries_with_events),
          sum(annual$countries_with_conflict) == sum(d$armed_conflict_lag1))
save_table(annual, "annual_conflict_counts.csv")
audit <- data.frame(
  item = c("Raw conflict rows", "Real event records", "No-event placeholders",
           "Repeated rows across all supplied fields", "Missing country/year keys",
           "Incomplete real event records", "Duplicate final country-year keys"),
  count = c(nrow(c), nrow(events), sum(is.na(c$conflict_id)), sum(duplicated(c)),
            sum(!complete.cases(c[c("iso", "year")])),
            sum(xor(is.na(c$conflict_id), is.na(c$best))),
            sum(duplicated(d[c("iso", "year")]))))
save_table(audit, "data_audit.csv")
p <- annual |> select(year, recorded_conflicts, qualifying_conflicts) |>
  pivot_longer(-year, names_to = "series", values_to = "count") |>
  mutate(series = recode(series, recorded_conflicts = "Recorded conflict IDs",
                         qualifying_conflicts = "IDs qualifying in at least one country")) |>
  ggplot(aes(year, count, color = series, linetype = series)) +
  geom_line(linewidth = 0.85) + geom_point(size = 1.7) +
  scale_color_manual(values = c("#BB5030", "#24708D")) +
  scale_x_continuous(breaks = c(1999, 2003, 2007, 2011, 2015, 2018)) +
  scale_y_continuous(limits = c(0, NA)) +
  labs(title = "Recorded armed conflicts over time", x = "Source conflict year",
       y = "Distinct conflict IDs", color = NULL, linetype = NULL,
       caption = "A conflict ID is counted once per year, even if it appears in several countries.\nQualifying: at least 25 deaths within one country-conflict-year. Course extract only.")
save_plot(p, "fig01_conflict_trends.png")
p <- annual |> select(year, event_records, countries_with_conflict, countries_covered) |>
  pivot_longer(-year, names_to = "measure", values_to = "count") |>
  mutate(measure = recode(measure, event_records = "Recorded event rows",
    countries_with_conflict = "Countries with qualifying conflict", countries_covered = "Countries represented in source")) |>
  ggplot(aes(year, count)) + geom_line(color = "#24708D", linewidth = 0.8) +
  geom_point(color = "#24708D", size = 1.5) + facet_wrap(~measure, ncol = 1, scales = "free_y") +
  scale_y_continuous(limits = c(0, NA)) +
  labs(x = "Source conflict year", y = "Count", title = "Event volume and source coverage",
       caption = "Panels use different y-axis ranges. Complete country coverage does not prove complete event reporting.")
save_plot(p, "fig02_source_coverage.png", height = 7)

outcomes <- c("maternal_mortality", "infant_mortality", "neonatal_mortality", "under5_mortality")
labels <- c(maternal_mortality = "Maternal (per 100,000 live births)",
  infant_mortality = "Infant (per 1,000 live births)", neonatal_mortality = "Neonatal (per 1,000 live births)",
  under5_mortality = "Under-five (per 1,000 live births)")
continuous <- c(outcomes, "gdp_1000", "pop_dens", "urban", "age_dep", "male_edu", "temp", "rainfall_1000")
summary <- bind_rows(lapply(continuous, function(v) {
  x <- d[[v]]
  data.frame(variable = v, observed_n = sum(!is.na(x)), missing_n = sum(is.na(x)),
    mean = mean(x, na.rm = TRUE), sd = sd(x, na.rm = TRUE), min = min(x, na.rm = TRUE),
    q1 = unname(quantile(x, .25, na.rm = TRUE)), median = median(x, na.rm = TRUE),
    q3 = unname(quantile(x, .75, na.rm = TRUE)), max = max(x, na.rm = TRUE))
}))
save_table(summary, "continuous_summary.csv")
missing <- data.frame(variable = names(d), missing_n = vapply(d, function(x) sum(is.na(x)), integer(1))) |>
  mutate(missing_percent = 100 * missing_n / nrow(d))
save_table(missing, "missingness.csv")
long <- d |> select(iso, year, region, armed_conflict_lag1, all_of(outcomes)) |>
  pivot_longer(all_of(outcomes), names_to = "outcome", values_to = "rate")
missing_year <- long |> group_by(outcome, year) |>
  summarise(missing_n = sum(is.na(rate)), observed_n = sum(!is.na(rate)), .groups = "drop")
save_table(missing_year, "mortality_missing_by_year.csv")
save_table(d |> filter(!complete.cases(pick(all_of(continuous)))) |>
  group_by(iso, country_name) |> summarise(rows_with_missing = n(), .groups = "drop"), "missingness_by_country.csv")
p <- long |> mutate(outcome = unname(labels[outcome])) |>
  ggplot(aes(year, iso, fill = is.na(rate))) + geom_tile() +
  facet_wrap(~outcome, ncol = 2) +
  scale_fill_manual(values = c("FALSE" = "#DCE9ED", "TRUE" = "#B94C35"),
    labels = c("Observed", "Missing"), name = NULL) +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(), panel.grid = element_blank()) +
  labs(title = "Mortality data availability", x = "Outcome year", y = "Countries (ISO order)",
       caption = "One tile per country-year. All maternal mortality values in 2018 and 2019 are missing.")
save_plot(p, "fig03_missingness.png", height = 6)
p <- long |> filter(!is.na(rate)) |> mutate(outcome = unname(labels[outcome])) |>
  ggplot(aes(rate)) + geom_histogram(bins = 35, fill = "#24708D", color = "white", linewidth = 0.15) +
  facet_wrap(~outcome, scales = "free", ncol = 2) +
  labs(title = "Mortality distributions across country-years", x = "Mortality measure (panel units)",
       y = "Observed country-years", caption = "Missing values excluded separately for each outcome; panels use different ranges.")
save_plot(p, "fig04_mortality_distributions.png", height = 6)
trends <- long |> group_by(outcome, year) |> summarise(observed_n = sum(!is.na(rate)),
  median = if (all(is.na(rate))) NA_real_ else median(rate, na.rm = TRUE),
  q1 = if (all(is.na(rate))) NA_real_ else quantile(rate, .25, na.rm = TRUE),
  q3 = if (all(is.na(rate))) NA_real_ else quantile(rate, .75, na.rm = TRUE), .groups = "drop")
save_table(trends, "mortality_time_trends.csv")
p <- trends |> filter(observed_n > 0) |> mutate(outcome = unname(labels[outcome])) |>
  ggplot(aes(year, median)) + geom_ribbon(aes(ymin = q1, ymax = q3), fill = "#C7DBE4") +
  geom_line(color = "#1D6079", linewidth = 0.9) + facet_wrap(~outcome, scales = "free_y", ncol = 2) +
  labs(title = "Mortality over time", x = "Outcome year", y = "Median across observed countries",
       caption = "Shading is the interquartile range, not a confidence interval. Countries receive equal weight.")
save_plot(p, "fig05_mortality_trends.png", height = 6)
by_conflict <- long |> group_by(armed_conflict_lag1, outcome) |>
  summarise(observed_n = sum(!is.na(rate)), missing_n = sum(is.na(rate)),
    median = median(rate, na.rm = TRUE), q1 = quantile(rate, .25, na.rm = TRUE),
    q3 = quantile(rate, .75, na.rm = TRUE), .groups = "drop")
save_table(by_conflict, "mortality_by_conflict.csv")
by_region <- d |> group_by(region) |> summarise(countries = n_distinct(iso),
  country_years = n(), conflict_years = sum(armed_conflict_lag1),
  percent_conflict = 100 * mean(armed_conflict_lag1),
  maternal_observed = sum(!is.na(maternal_mortality)),
  maternal_median = median(maternal_mortality, na.rm = TRUE), .groups = "drop")
save_table(by_region, "region_summary.csv")
p <- d |> filter(!is.na(maternal_mortality)) |>
  ggplot(aes(factor(armed_conflict_lag1, labels = c("No", "Yes")), maternal_mortality)) +
  geom_boxplot(fill = "#D8E6EC", color = "#205B73", outlier.alpha = .25) +
  facet_wrap(~region, ncol = 3) + scale_y_log10() +
  labs(title = "Maternal mortality by prior-year conflict and region",
    x = "Qualifying conflict in previous year", y = "Maternal deaths per 100,000 live births (log scale)",
    caption = "Observed country-years, 2000-2017. Repeated observations and unequal group sizes; no causal inference.")
save_plot(p, "fig06_conflict_region.png", height = 6)
checks <- data.frame(check = c("Unique final keys", "Complete source coverage", "Lagged exposure totals agree",
  "No negative mortality", "Mortality ordering", "No nonfinite observed numeric values"), passed = c(
  !anyDuplicated(d[c("iso", "year")]), all(annual$countries_covered == 186),
  sum(annual$countries_with_conflict) == sum(d$armed_conflict_lag1),
  all(unlist(d[outcomes]) >= 0, na.rm = TRUE),
  all(d$neonatal_mortality <= d$infant_mortality & d$infant_mortality <= d$under5_mortality, na.rm = TRUE),
  all(vapply(d[continuous], function(x) all(is.finite(x[!is.na(x)])), logical(1)))))
stopifnot(all(checks$passed))
save_table(checks, "eda_checks.csv")
message("EDA tables and six figures saved.")
