# Week 6 - Reproducible tables and figures

This work uses the Week 5 data after its validation and GitHub push. The input
has 3,720 country-years from 186 countries. No rows are removed or imputed for
Table 1. Figure 1 applies its own endpoint-based country selection.

## Deliverables

- [Table 1 (PDF)](outputs/table01_country_year_characteristics.pdf): overall
  characteristics and strata defined by prior-year conflict, with missing
  counts for every variable.
- [Figure 1 (PNG)](outputs/fig01_maternal_mortality_increase.png): maternal
  mortality trajectories for the 13 countries whose value increased between
  2000 and 2017.
- [Design notes](reports/design_notes.md): observation units, denominators,
  choice of summaries and scales, interpretation, and the reading references.
- [Validation](reports/validation_checks.csv): checks against the input data.

The supplied lecture file is numbered 06; its final submission slide calls the
course-site assignment "Week 7 - Tables and Figures". This repository uses
`week6` to follow the requested weekly organization.

## Reproduce from the repository root

```sh
Rscript --vanilla week6/R/table01_country_year_characteristics.R
Rscript --vanilla week6/R/fig01_maternal_mortality_increase.R
Rscript --vanilla week6/R/validate_outputs.R
```

Each output has its own script. The table script calculates the table, saves
an unrounded audit CSV, and renders the PDF using the accompanying Quarto
file. The figure script selects countries, creates the plot, and saves the
endpoint audit and exact plotted observations. `R/paths.R` locates the input
and output directories.

Required R packages are `dplyr`, `tidyr`, `ggplot2`, `ggrepel`, `colorspace`,
`knitr`, `kableExtra`, and `rmarkdown`. Table rendering also needs Quarto and
XeLaTeX. The script uses Positron's bundled Quarto on this Mac if it is not
on PATH. Input data are read from `../week5/data/processed/final_data.csv`.

## Read the results

Table 1 has three summary groups: overall (3,720 country-years), no prior-year
conflict (3,029), and prior-year conflict (691). Each has a separate missing-count
column. Countries can contribute to both exposure groups in different years:
173 contribute to the no-conflict group and 88 to the conflict group, with
75 in both. The table is descriptive; no model or significance test is fitted.

Figure 1 compares observed 2000 and 2017 values, then plots every intervening
year for the selected countries. A net increase does not require a monotonic
trajectory. The y-axis is logarithmic and is labeled accordingly; colors and
direct country labels identify the lines. The three countries with a missing
endpoint are excluded. Later years are unavailable for maternal mortality.

The PDF and PNG are the files requested for the course submission. Peer review
by a classmate and upload to Quercus remain to be completed; see
[peer_review.md](reports/peer_review.md). No classmate feedback is claimed.
