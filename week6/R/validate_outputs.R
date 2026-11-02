# Run after the table and figure scripts.
args <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE))
helper <- c("week6/R/paths.R", "R/paths.R", file.path(dirname(args), "paths.R"))
source(helper[file.exists(helper)][1])
p <- week6_paths()
d <- read.csv(p$input, fileEncoding = "UTF-8")
tab <- read.csv(file.path(p$outputs, "table01_country_year_characteristics.csv"), check.names = FALSE)
audit <- read.csv(file.path(p$outputs, "table01_numeric_audit.csv"))
selected <- read.csv(file.path(p$outputs, "fig01_selected_countries.csv"))
plotted <- read.csv(file.path(p$outputs, "fig01_plot_data.csv"))
checks <- data.frame(check = character(), passed = logical())
check <- function(label, condition) {
  checks[nrow(checks) + 1L, ] <<- list(label, isTRUE(condition))
  if (!isTRUE(condition)) stop("Failed: ", label)
}
check("Observation count is 3720 and country-year keys are unique", nrow(d) == 3720L && !anyDuplicated(d[c("iso", "year")]))
check("Exposure groups partition all country-years", sum(d$armed_conflict_lag1 == 0) == 3029L && sum(d$armed_conflict_lag1 == 1) == 691L)
groups <- list(overall = d, no_conflict = d[d$armed_conflict_lag1 == 0, ], conflict = d[d$armed_conflict_lag1 == 1, ])
for (g in names(groups)) {
  a <- audit[audit$group == g, ]
  input <- groups[[g]]
  good <- vapply(seq_len(nrow(a)), function(i) {
    x <- input[[a$variable[i]]]
    q <- quantile(x, c(.25, .5, .75), na.rm = TRUE, names = FALSE)
    a$total_n[i] == length(x) && a$observed_n[i] + a$missing_n[i] == length(x) &&
      a$missing_n[i] == sum(is.na(x)) &&
      isTRUE(all.equal(c(a$q1[i], a$median[i], a$q3[i]), q, tolerance = 1e-12))
  }, logical(1))
  check(paste("Numeric cells and denominators:", g), all(good))
  display <- tab[[g]]
  missing <- as.integer(tab[[paste0(g, "_missing")]][grepl("Maternal mortality", tab$characteristic)])
  check(paste("Maternal missing cell:", g), missing == sum(is.na(input$maternal_mortality)))
  region_counts <- sub(" .*", "", display[trimws(tab$characteristic) %in% unique(d$region)])
  check(paste("Regional counts sum to group size:", g), sum(as.numeric(gsub(",", "", region_counts))) == nrow(input))
  for (v in c("oecd", "earthquake", "drought")) {
    label <- c(oecd = "OECD member", earthquake = "Earthquake in", drought = "Drought in")[[v]]
    count <- as.integer(gsub(",", "", sub(" .*", "", display[grepl(label, tab$characteristic, fixed = TRUE)])))
    check(paste("Binary count:", g, v), count == sum(input[[v]] == 1, na.rm = TRUE))
  }
}
check("Country overlap is stated correctly", length(intersect(groups$no_conflict$iso, groups$conflict$iso)) == 75L)
a <- d[d$year == 2000, c("iso", "maternal_mortality")]
b <- d[d$year == 2017, c("iso", "maternal_mortality")]
names(a)[2] <- "start"; names(b)[2] <- "end"
e <- merge(a, b, by = "iso")
expected <- e$iso[!is.na(e$start) & !is.na(e$end) & e$end > e$start]
check("Exactly the 13 endpoint-increase countries are plotted", setequal(selected$iso, expected) && length(expected) == 13L)
check("Three countries are excluded for missing endpoints", sum(is.na(e$start) | is.na(e$end)) == 3L)
check("Every plotted country has all 18 annual observations", nrow(plotted) == 234L && all(table(plotted$iso) == 18L) && identical(sort(unique(plotted$year)), 2000:2017))
key <- paste(plotted$iso, plotted$year)
input_key <- paste(d$iso, d$year)
check("Plotted values equal final data", identical(plotted$maternal_mortality, d$maternal_mortality[match(key, input_key)]))
check("2018-2019 maternal values are entirely missing", all(is.na(d$maternal_mortality[d$year >= 2018])))
check("PDF and PNG deliverables exist", all(file.exists(file.path(p$outputs,
  c("table01_country_year_characteristics.pdf", "fig01_maternal_mortality_increase.png")))))
write.csv(checks, file.path(p$root, "reports/validation_checks.csv"), row.names = FALSE)
writeLines(trimws(capture.output(sessionInfo()), which = "right"), file.path(p$root, "reports/session_info.txt"))
message("PASS: ", nrow(checks), " checks.")
