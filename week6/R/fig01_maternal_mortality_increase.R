# Run from chl5233 with Rscript --vanilla week6/R/fig01_maternal_mortality_increase.R.
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(ggplot2))
args <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE))
helper <- c("week6/R/paths.R", "R/paths.R", file.path(dirname(args), "paths.R"))
source(helper[file.exists(helper)][1])
p <- week6_paths()
d <- read.csv(p$input, fileEncoding = "UTF-8")
stopifnot(!anyDuplicated(d[c("iso", "year")]))
endpoints <- d |> filter(year %in% c(2000L, 2017L)) |>
  select(iso, country_name, year, maternal_mortality) |>
  pivot_wider(names_from = year, values_from = maternal_mortality, names_prefix = "y") |>
  mutate(change = y2017 - y2000,
    selection = case_when(is.na(y2000) | is.na(y2017) ~ "Missing endpoint",
                          change > 0 ~ "Increase", TRUE ~ "No increase"))
selected <- endpoints |> filter(selection == "Increase") |> arrange(desc(change), country_name)
plot_data <- d |> semi_join(selected, by = "iso") |> filter(year <= 2017) |>
  select(iso, country_name, year, maternal_mortality) |> arrange(iso, year)
stopifnot(nrow(selected) == 13L, nrow(plot_data) == 13L * 18L,
          !anyNA(plot_data$maternal_mortality), all(plot_data$maternal_mortality > 0),
          all(selected$change > 0), all(is.na(d$maternal_mortality[d$year >= 2018])))
colors <- setNames(colorspace::qualitative_hcl(nrow(selected), palette = "Dark 3"), selected$country_name)
last <- plot_data |> filter(year == 2017)
fig <- ggplot(plot_data, aes(year, maternal_mortality, color = country_name, group = iso)) +
  geom_line(linewidth = 0.85) +
  geom_point(data = plot_data |> filter(year %in% c(2000, 2017)), size = 2) +
  ggrepel::geom_text_repel(data = last, aes(label = country_name),
    nudge_x = 1.1, direction = "y", hjust = 0, size = 3.5,
    min.segment.length = 0, box.padding = .3, point.padding = .15,
    seed = 5233, max.overlaps = Inf, max.iter = 20000, max.time = 5) +
  scale_color_manual(values = colors, guide = "none") +
  scale_y_log10(breaks = c(5, 10, 20, 50, 100, 200, 500, 1000)) +
  scale_x_continuous(breaks = c(2000, 2004, 2008, 2012, 2017), expand = expansion(mult = c(.01, 0))) +
  coord_cartesian(xlim = c(2000, 2022.5), clip = "off") +
  labs(title = "Maternal mortality in countries with a net increase, 2000-2017",
    subtitle = "13 countries with observed endpoints and a higher value in 2017 than in 2000",
    x = "Year", y = "Maternal deaths per 100,000 live births (log scale)",
    caption = paste0("Selection compares endpoints; individual trajectories need not increase every year. Lines join annual modeled estimates.\n",
      "Logarithmic y-axis separates lower-rate countries; equal vertical distances represent equal ratios.\n",
      "Source: course maternal mortality extract. All 2018-2019 values are missing; 3 countries lack an endpoint and are excluded.")) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
        plot.title.position = "plot", plot.caption.position = "plot",
        plot.caption = element_text(hjust = 0, size = 9),
        plot.margin = margin(12, 25, 12, 12))
dir.create(p$outputs, showWarnings = FALSE)
ggsave(file.path(p$outputs, "fig01_maternal_mortality_increase.png"), fig,
       width = 12, height = 8, dpi = 300, bg = "white")
write.csv(selected, file.path(p$outputs, "fig01_selected_countries.csv"), row.names = FALSE)
write.csv(endpoints, file.path(p$outputs, "fig01_endpoint_audit.csv"), row.names = FALSE)
write.csv(plot_data, file.path(p$outputs, "fig01_plot_data.csv"), row.names = FALSE)
message("Saved Figure 1 for ", nrow(selected), " countries.")
