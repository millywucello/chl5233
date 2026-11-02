# Run from chl5233 with Rscript --vanilla week6/R/table01_country_year_characteristics.R.
args <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE))
helper <- c("week6/R/paths.R", "R/paths.R", file.path(dirname(args), "paths.R"))
source(helper[file.exists(helper)][1])
p <- week6_paths()
d <- read.csv(p$input, fileEncoding = "UTF-8")
stopifnot(nrow(d) == 3720L, !anyDuplicated(d[c("iso", "year")]),
          !anyNA(d$armed_conflict_lag1), all(d$armed_conflict_lag1 %in% 0:1))
dir.create(p$outputs, showWarnings = FALSE)
groups <- list(overall = d, no_conflict = d[d$armed_conflict_lag1 == 0, ],
               conflict = d[d$armed_conflict_lag1 == 1, ])
fmt_n <- function(x) format(x, big.mark = ",", trim = TRUE, scientific = FALSE)
fmt_cont <- function(x, digits = 1) {
  q <- quantile(x, c(.5, .25, .75), na.rm = TRUE, names = FALSE)
  paste0(formatC(q[1], digits = digits, format = "f", big.mark = ","), " [",
         formatC(q[2], digits = digits, format = "f", big.mark = ","), ", ",
         formatC(q[3], digits = digits, format = "f", big.mark = ","), "]")
}
fmt_cat <- function(x, value) {
  n <- sum(x == value, na.rm = TRUE)
  paste0(fmt_n(n), " (", sprintf("%.1f", 100 * n / sum(!is.na(x))), ")")
}
rows <- list()
add_row <- function(label, variable = NULL, kind = "continuous", value = NULL, digits = 1) {
  row <- list(characteristic = label)
  for (g in names(groups)) {
    sub <- groups[[g]]
    x <- if (!is.null(variable)) sub[[variable]] else NULL
    row[[g]] <- switch(kind,
      continuous = fmt_cont(x, digits), categorical = fmt_cat(x, value),
      countries = fmt_n(length(unique(sub$iso))), rows = fmt_n(nrow(sub)),
      year_range = paste(range(x), collapse = "-"),
      region_header = "", years_per_country = fmt_cont(as.numeric(table(sub$iso)), 0))
    row[[paste0(g, "_missing")]] <- if (kind %in% c("countries", "rows", "years_per_country"))
      "-" else if (kind == "categorical" && variable == "region") "-" else as.character(sum(is.na(x)))
  }
  rows[[length(rows) + 1L]] <<- as.data.frame(row, stringsAsFactors = FALSE)
}
add_row("Country-years, n", kind = "rows")
add_row("Countries contributing, n", kind = "countries")
add_row("Years per contributing country", kind = "years_per_country")
add_row("Calendar years, range", "year", kind = "year_range")
add_row("Region, n (%)", "region", kind = "region_header")
for (r in c("Africa", "Americas", "Asia", "Europe", "Oceania"))
  add_row(paste0("  ", r), "region", "categorical", r)
add_row("Maternal mortality (per 100,000 live births)", "maternal_mortality")
add_row("Infant mortality (per 1,000 live births)", "infant_mortality")
add_row("Neonatal mortality (per 1,000 live births)", "neonatal_mortality")
add_row("Under-five mortality (per 1,000 live births)", "under5_mortality")
add_row("GDP per capita (supplied thousands scale)", "gdp_1000")
add_row("Population density (supplied scale)", "pop_dens")
add_row("Urban residence (supplied scale)", "urban")
add_row("Age dependency ratio (supplied scale)", "age_dep")
add_row("Male education (supplied scale)", "male_edu")
add_row("Temperature (supplied scale)", "temp")
add_row("Rainfall (supplied thousands scale)", "rainfall_1000", digits = 2)
add_row("OECD member: yes, n (%)", "oecd", "categorical", 1)
add_row("Earthquake in outcome year: yes, n (%)", "earthquake", "categorical", 1)
add_row("Drought in outcome year: yes, n (%)", "drought", "categorical", 1)
tab <- do.call(rbind, rows)
write.csv(tab, file.path(p$outputs, "table01_country_year_characteristics.csv"), row.names = FALSE)

# Save numeric statistics as an audit trail before display rounding.
continuous <- c("year", "maternal_mortality", "infant_mortality", "neonatal_mortality",
  "under5_mortality", "gdp_1000", "pop_dens", "urban", "age_dep", "male_edu", "temp", "rainfall_1000")
numeric_rows <- list()
for (g in names(groups)) for (v in continuous) {
  x <- groups[[g]][[v]]
  numeric_rows[[length(numeric_rows) + 1L]] <- data.frame(group = g, variable = v,
    total_n = length(x), observed_n = sum(!is.na(x)), missing_n = sum(is.na(x)),
    median = median(x, na.rm = TRUE), q1 = unname(quantile(x, .25, na.rm = TRUE)),
    q3 = unname(quantile(x, .75, na.rm = TRUE)))
}
write.csv(do.call(rbind, numeric_rows), file.path(p$outputs, "table01_numeric_audit.csv"), row.names = FALSE)
manifest <- data.frame(input = "week5/data/processed/final_data.csv", md5 = unname(tools::md5sum(p$input)))
write.csv(manifest, file.path(p$outputs, "input_manifest.csv"), row.names = FALSE)

quarto <- Sys.which("quarto")
if (!nzchar(quarto)) quarto <- "/Applications/Positron.app/Contents/Resources/app/quarto/bin/quarto"
if (!file.exists(quarto)) stop("Quarto is needed to render Table 1.")
status <- system2(quarto, c("render", shQuote(file.path(p$root, "reports/table01_country_year_characteristics.qmd")),
                           "--to", "pdf"))
if (status != 0L) stop("Table 1 PDF rendering failed.")
file.copy(file.path(p$root, "reports/table01_country_year_characteristics.pdf"),
          file.path(p$outputs, "table01_country_year_characteristics.pdf"), overwrite = TRUE)
