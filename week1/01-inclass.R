#--------------------------------------------------
# Week 1: In-class assignment
# Data: openintro::yrbss
#--------------------------------------------------
# Open the chl5233 folder in Positron, then open week1/01-inclass.R.
# On macOS, Command + Enter runs selected code; Command + S saves the file.
# Outputs are saved to week1/results/01-inclass/ in the repository.

# 0. Packages and data ---------------------------------------------
# Install only packages that are not already installed.
required_packages <- c("openintro", "dplyr", "ggplot2", "flextable")
missing_packages <- setdiff(required_packages, rownames(installed.packages()))
if (length(missing_packages) > 0) {
  install.packages(missing_packages, repos = "https://cloud.r-project.org")
}
# Use flextable >= 0.9.6 for summarizor() without a grouping variable.
if (packageVersion("flextable") < "0.9.6") {
  install.packages("flextable", repos = "https://cloud.r-project.org",
                  type = if (Sys.info()[["sysname"]] == "Darwin") "binary" else getOption("pkgType"))
}

library(openintro)
library(dplyr)
library(ggplot2)
library(flextable)

# Run ?yrbss in the Console to view the variable documentation.
# physically_active_7d: days with 60+ minutes of activity in the past 7 days.
# Documentation: https://openintrostat.github.io/openintro/reference/yrbss.html
data("yrbss", package = "openintro")
# Support running from either the repository root or the week1 folder.
week_dir <- if (file.exists(file.path("week1", "01-inclass.R"))) {
  "week1"
} else if (basename(getwd()) == "week1" && file.exists("01-inclass.R")) {
  "."
} else {
  stop("Open the chl5233 or week1 folder before running this script.")
}
out_dir <- file.path(week_dir, "results", "01-inclass")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# 1. Summary table: increasing grade order and capitalized labels ---
# The original grade variable is character, so 10 would sort before 9.
# Factor levels specify the order; labels capitalize Other, Female and Male.
# Retain Other and missing values in the summary table.
yrbss$Grade <- factor(
  yrbss$grade,
  levels = c("9", "10", "11", "12", "other"),
  labels = c("9", "10", "11", "12", "Other")
)
yrbss$Gender <- factor(
  yrbss$gender,
  levels = c("female", "male"),
  labels = c("Female", "Male")
)

z <- summarizor(yrbss[c("Grade", "Gender")], overall_label = NULL)
ft_1 <- as_flextable(z) |> autofit()
# Display and save an HTML table without requiring Pandoc.
summary_html <- htmltools_value(ft_1)
htmltools::save_html(summary_html,
                    file = file.path(out_dir, "01-summary-table.html"))
if (interactive()) print(htmltools::browsable(summary_html))

# 2. Mean physical activity by grade and gender ---------------------
# Exclude records with missing grade or gender. na.rm omits missing activity.
# Keep Other in the mean table so the full grouped summary can be checked.
activity_data <- yrbss |>
  filter(!is.na(Grade), !is.na(Gender))

activity_mean <- aggregate(
  x = list(mean_active_days = activity_data$physically_active_7d),
  by = list(Grade = activity_data$Grade, Gender = activity_data$Gender),
  FUN = mean,
  na.rm = TRUE
)
activity_mean <- activity_mean |>
  arrange(Gender, Grade)
print(activity_mean)

# Other has no ordinal position, so the line plot compares grades 9--12 only.
# group = Gender connects the points separately for each gender.
p_activity <- activity_mean |>
  filter(Grade != "Other") |>
  ggplot(aes(x = Grade, y = mean_active_days,
             color = Gender, shape = Gender, group = Gender)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 3) +
  scale_color_manual(values = c(Female = "#C05A24", Male = "#236B8E")) +
  scale_y_continuous(limits = c(0, 7), breaks = 0:7) +
  labs(
    title = "Physical activity by grade and gender",
    subtitle = "Days with at least 60 minutes of activity in the past 7 days",
    x = "Grade", y = "Mean physically active days (0-7)",
    color = "Gender", shape = "Gender",
    caption = "YRBSS, openintro package. Other/unknown grades are not plotted.\nMissing activity responses are omitted from each mean."
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom", panel.grid.minor = element_blank())
if (interactive()) print(p_activity)

# 3. Physical activity and BMI among grade 12 female students -------
# The original data have no bmi column. Weight is in kg; height is in m.
# BMI = weight / height^2. Keep complete, valid observations for this plot.
female_12 <- yrbss |>
  filter(grade == "12", gender == "female",
         !is.na(physically_active_7d),
         is.finite(height), height > 0,
         is.finite(weight), weight > 0) |>
  mutate(bmi = weight / height^2)

# Horizontal jitter reduces overplotting; height = 0 leaves BMI unchanged.
# A fixed seed makes the jittered positions reproducible.
p_bmi <- ggplot(female_12, aes(x = physically_active_7d, y = bmi)) +
  geom_point(aes(color = "Female, grade 12"), alpha = 0.3, size = 1.4,
             position = position_jitter(width = 0.15, height = 0, seed = 5233)) +
  scale_color_manual(values = c("Female, grade 12" = "#236B8E")) +
  scale_x_continuous(breaks = 0:7) +
  labs(
    title = "Physical activity and BMI among grade 12 female students",
    subtitle = paste("Students with complete data: n =", nrow(female_12)),
    x = "Physically active days in the past 7 days",
    y = "BMI (kg/m^2)", color = "Students",
    caption = "YRBSS, openintro package. Points are jittered horizontally for visibility.\nThis descriptive plot does not establish causation."
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom", panel.grid.minor = element_blank())
if (interactive()) print(p_bmi)

# 4. Save results --------------------------------------------------
write.csv(activity_mean, file.path(out_dir, "02-activity-means.csv"),
          row.names = FALSE)
ggsave(file.path(out_dir, "02-activity-by-grade-gender.png"),
       plot = p_activity, width = 9, height = 6, dpi = 200, bg = "white")
ggsave(file.path(out_dir, "03-activity-and-bmi.png"),
       plot = p_bmi, width = 10, height = 6, dpi = 200, bg = "white")
writeLines(capture.output(sessionInfo()), file.path(out_dir, "session-info.txt"))
message("Finished. Results saved in: ", normalizePath(out_dir))

# 5. GitHub --------------------------------------------------------
# Run these commands in the Positron Terminal from the repository root:
# git add week1/01-inclass.R
# git commit -m "Update Week 1 in-class assignment"
# git push
