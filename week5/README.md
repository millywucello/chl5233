# Week 5 - Reproducibility and exploratory analysis

The first EDA question follows the quiz plan: how do recorded armed conflicts
change over time? The analysis distinguishes conflict IDs from event records
and affected countries before examining mortality and missingness.

## Files

- `data/raw/`: unchanged copies of the nine Week 3 input files.
- `data/processed/`: final data from the primary and comparison scripts.
- `R/`: data preparation, validation, and EDA scripts.
- `reports/compare_final_data.qmd` and `.html`: dataset comparison.
- `reports/eda.qmd` and `.html`: exploratory analysis and interpretation.
- `reports/tables/`, `reports/figures/`, `reports/validation/`: reproducible outputs.

The course work remains in `chl5233`, with the requested `data`, `R`, and
`reports` structure under `week5`. The handout uses the name `armed_conflict`
for this study repository.

## Reproduce

Install `dplyr`, `tidyr`, `janitor`, `ggplot2`, `knitr`, and `rmarkdown` if needed.
From the repository root:

```sh
Rscript --vanilla week5/R/validate_data.R
Rscript --vanilla week5/R/summarise_eda.R
quarto render week5/reports/compare_final_data.qmd
quarto render week5/reports/eda.qmd
```

On this Mac, Quarto is bundled with Positron. If `quarto` is not on PATH, use
`"/Applications/Positron.app/Contents/Resources/app/quarto/bin/quarto"` instead.
The `.qmd` files can also be opened in Positron and rendered with Preview.
Generate the data and EDA outputs before rendering the documents.

Validation starts each data-preparation script in a separate clean R process.
All 32 checks pass, including agreement across 74,400 cells and agreement with
the saved Week 3 outputs. Six further EDA checks pass. The final data retain
186 countries, 20 years, and all original missing measures.

The two Week 3 scripts were prepared with coding-agent assistance. Their
agreement checks implementation consistency, not independent confirmation of
the study design. Full data definitions are in `reports/data_dictionary.md`.
