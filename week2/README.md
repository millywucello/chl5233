# Week 2 - Quarto in-class assignment

This folder contains the completed Quarto report, its rendered PDF, and the two original course data files. The report author is Milly Wu.

## Files

```text
week2/
  README.md
  data/
    raw/
      countries.txt
      regions.txt
  reports/
    quarto_inclass.qmd
    quarto_inclass.pdf
```

The assignment template proposes a separate repository named `armed_conflict`. These materials are organized in `chl5233/week2` as requested, retaining the `data/raw` and `reports` structure. If a separate repository is required for grading, that administrative requirement should be checked with the instructor.

## Open and render in Positron

1. Open the `chl5233` folder with **File > Open Folder...**.
2. Open `week2/reports/quarto_inclass.qmd` in the Explorer. A `.qmd` file is a document containing text and executable code; open it as a file, rather than importing it as tabular data.
3. Edit and save with **Command + S** on macOS.
4. Click **Preview** in the document toolbar. Its PDF output format is configured in the YAML header. Rendering executes the whole document and updates `quarto_inclass.pdf` beside the source file.
5. Review the PDF before committing both the source and PDF.

The Terminal command, run from the repository root, is:

```sh
quarto render week2/reports/quarto_inclass.qmd --to pdf
```

If `quarto` is not on the Terminal PATH, the Positron installation on this Mac includes it here:

```sh
"/Applications/Positron.app/Contents/Resources/app/quarto/bin/quarto" render week2/reports/quarto_inclass.qmd --to pdf
```

The document uses `../data/raw/` paths relative to its own `reports` folder. Quarto uses that folder when rendering. To run individual R chunks interactively from the repository root, first run `setwd("week2/reports")` in the R Console, then run chunks from the setup onward. Do not use `source()` on a `.qmd` document.

## How the assignment is completed

1. The setup chunk uses `#| include: false`, which executes the package loading while hiding its code and output. Global `warning: false` and `message: false` also keep diagnostics out of the final report; errors stop rendering.
2. `read.table()` reads each supplied file. `dim()` displays rows and columns, while inline R expressions insert the current counts into the prose.
3. `semi_join()` keeps region records whose `country_code` occurs in `countries$ISO`. `anti_join()` checks for unmatched codes. Assertions reject duplicate codes, missing region labels, or a mismatch in the analytical sample size.
4. `group_by()` and `summarise(Count = n())` produce region and sub-region counts. `knitr::kable()` gives the tables their requested column headers.
5. `geom_bar()` counts countries directly. Mapping sub-region to the y-axis produces horizontal bars; explicit factor levels put the largest count at the top. The `fill` aesthetic identifies the parent region. A second chart also shows the overall counts by region.

## Results and data notes

- `countries.txt`: **186 rows, 2 columns**, with 186 unique ISO codes.
- `regions.txt`: **249 rows, 6 columns**, including countries and territories.
- Analytical sample: **186 matched countries**, no unmatched codes, 5 regions, and 17 sub-regions.

| Region | Count |
|---|---:|
| Africa | 54 |
| Asia | 46 |
| Europe | 40 |
| Americas | 35 |
| Oceania | 11 |

The paper title supplied in the template mentions 181 countries, but the provided country list contains 186. The report analyzes all 186 provided entries and explicitly notes the discrepancy. It does not claim to reproduce the paper's final analytical sample.

Both raw files are copied unchanged from the course downloads. Some country names in the original files have encoding artifacts. They are read with `fileEncoding = "latin1"`; this permits import but does not repair damaged names. Matching relies on the intact three-letter ISO codes, and chart labels use the intact region and sub-region fields.

## Dependencies

Required R packages: `tidyverse`, `knitr`, and `kableExtra`. Install them once in the **R Console** if needed:

```r
install.packages(c("tidyverse", "knitr", "kableExtra"),
                 repos = "https://cloud.r-project.org")
```

PDF rendering requires Quarto and a LaTeX installation. This report was rendered with Positron's bundled Quarto 1.10.18, R 4.2.3, kableExtra 1.4.0, and XeLaTeX (TeX Live 2024). If LaTeX is missing on another computer, install TinyTeX using `quarto install tinytex` in the Terminal.

## Commit and push updates

After saving the document and rendering the PDF, run these commands in the **Terminal**, with `chl5233` as the working directory:

```sh
git status
git add week2/reports/quarto_inclass.qmd week2/reports/quarto_inclass.pdf
git commit -m "Update Week 2 Quarto report"
git push
```

Check the [Week 2 folder on GitHub](https://github.com/millywucello/chl5233/tree/main/week2) after pushing. The source, PDF, and raw data are tracked; temporary rendering files are ignored.

References: [Quarto authoring tutorial](https://quarto.org/docs/get-started/authoring/rstudio.html) and [Quarto PDF documentation](https://quarto.org/docs/output-formats/pdf-basics.html).
