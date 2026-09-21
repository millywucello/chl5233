# CHL5233 - Week 1 in-class assignment

`01-inclass.R` analyzes `openintro::yrbss` and produces a summary table, a plot of mean physical activity by grade and gender, and a plot of physical activity versus BMI among grade 12 female students.

## Run in Positron

1. Select **File > Open Folder...** and open this repository's `chl5233` folder.
2. Expand **week1**, open **01-inclass.R**, and select an **R** session.
3. Run the script from the top using **Source R File with Echo**. On macOS, **Command + Enter** runs selected code and **Command + S** saves the file.

Alternatively, run this in the R Console with the repository as the working directory:

```r
source("week1/01-inclass.R", encoding = "UTF-8")
```

To run from a Terminal:

```sh
Rscript --vanilla week1/01-inclass.R
```

If the working directory is already `week1`, use `source("01-inclass.R")` or `Rscript --vanilla 01-inclass.R` instead. Both starting directories save results inside `week1/results/01-inclass/`.

Required packages are installed if missing. The script requires flextable 0.9.6 or newer and attempts to update older versions. Restart R after updating a package that was already loaded.

## Analysis

### Summary table

Explicit factor levels order grades as `9`, `10`, `11`, `12`, and `Other`. Category labels use `Female`, `Male`, and `Other`. Missing values remain visible in the table. The full dataset contains **13,583** students.

### Mean physical activity

`aggregate()` calculates mean physically active days within each grade and gender, excluding missing activity responses. Other grades remain in the exported mean table, but only grades 9 through 12 appear in the line plot because Other has no ordinal position.

| Grade | Female | Male |
|---|---:|---:|
| 9 | 3.533 | 4.667 |
| 10 | 3.520 | 4.551 |
| 11 | 3.075 | 4.525 |
| 12 | 2.942 | 4.327 |

Activity is measured as the number of days with at least 60 minutes of physical activity during the preceding seven days. These are unweighted descriptive sample means, not national population estimates.

### Physical activity and BMI

The script selects female students in grade 12 and calculates `bmi = weight / height^2`, with weight in kilograms and height in meters. The plot uses **1,650** records with complete activity, height, and weight data and positive height and weight. Horizontal jitter reduces overplotting without changing BMI values, and a fixed seed makes the plot reproducible. The plot does not establish causation.

## Outputs

Running the script creates `week1/results/01-inclass/` in the repository, containing:

- `01-summary-table.html`: summary table, viewable in a browser.
- `02-activity-means.csv`: mean activity for every observed grade and gender group.
- `02-activity-by-grade-gender.png`: activity line plot.
- `03-activity-and-bmi.png`: BMI scatter plot.
- `session-info.txt`: R and package versions used for the run.

Generated results are excluded from Git by `.gitignore` and can be regenerated from the script.

## Upload later changes

Save the script and run the following in the **Terminal**, with `chl5233` as the working directory:

```sh
git status
git add week1/01-inclass.R
git commit -m "Update Week 1 in-class assignment"
git push
```

Saving a file changes the local copy. Committing records a local version. Pushing uploads the commit to [GitHub](https://github.com/millywucello/chl5233).

## Validation and troubleshooting

The script was run successfully with R 4.2.3, openintro 2.5.1, flextable 0.9.6, and ggplot2 4.0.3. Both plots and the summary table were checked.

- If R cannot find the script, use `getwd()` to check the working directory. From `chl5233`, use `week1/01-inclass.R`; from `week1`, use `01-inclass.R`.
- If an older flextable reports `by can not be empty`, update the package and restart R.
- On macOS, a binary installation can avoid compiler issues: `install.packages("flextable", repos = "https://cloud.r-project.org", type = "binary")`.
- If the R Console remains on Starting, restart the R session or run the script from the Terminal.

References: [OpenIntro dataset documentation](https://openintrostat.github.io/openintro/reference/yrbss.html), [flextable summarizor documentation](https://davidgohel.github.io/flextable/reference/summarizor.html), and [GitHub upload instructions](https://docs.github.com/en/repositories/working-with-files/managing-files/adding-a-file-to-a-repository).
