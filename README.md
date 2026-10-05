# CHL5233 - Course assignments

Course materials are organized by week.

| Week | Contents |
|---|---|
| [Week 1](week1/) | [R script](week1/01-inclass.R) and [assignment guide](week1/README.md): YRBSS summaries, physical activity, and BMI |
| [Week 2](week2/) | [Quarto source](week2/reports/quarto_inclass.qmd), [PDF report](week2/reports/quarto_inclass.pdf), and [assignment guide](week2/README.md): country matching, regional summaries, and bar charts |
| [Week 3](week3/) | [R script](week3/scripts/create_final_data.R), [final dataset](week3/data/processed/final_data.csv), and [comparison report](week3/reports/comparison.md): reusable functions, mortality/disaster/conflict preparation, one-year lag, and validated country-year merges |

## Repository layout

```text
chl5233/
  .gitignore
  README.md
  week1/
    01-inclass.R
    README.md
    results/          # Generated locally; excluded from Git
  week2/
    README.md
    data/raw/
      countries.txt
      regions.txt
    reports/
      quarto_inclass.qmd
      quarto_inclass.pdf
  week3/
    README.md
    data/raw/
    data/processed/
      final_data.csv
      final_data_agent.csv
    scripts/
      create_final_data.R
      create_final_data_agent.R
      compare_outputs.R
    reports/
    reference/
```

Use `week4/` and subsequent folders for future assignments.

## Run Week 1

Open the `chl5233` folder in Positron, then open `week1/01-inclass.R`. Run the file using **Source R File with Echo**, or enter this in the R Console:

```r
source("week1/01-inclass.R", encoding = "UTF-8")
```

The script also supports running directly from the `week1` working directory. See the [Week 1 guide](week1/README.md) for analysis details and upload instructions.

## Render Week 2

Open `week2/reports/quarto_inclass.qmd` in Positron and click **Preview**, or run this in the Terminal from the repository root:

```sh
quarto render week2/reports/quarto_inclass.qmd --to pdf
```

See the [Week 2 guide](week2/README.md) for dependencies, data notes, and the bundled Quarto command if `quarto` is not on your PATH.

## Run Week 3

From the repository root, run both data-preparation implementations and their validation:

```sh
Rscript --vanilla week3/scripts/compare_outputs.R
```

The final dataset contains 3,720 country-year rows and 20 variables. The two implementations agree on all 74,400 cells, and all 30 checks pass. See the [Week 3 guide](week3/README.md) for R dependencies, Positron instructions, the conflict definition, and missing-data notes.
