# pivotwbmilly

`pivotwbmilly` packages the `prepare_mortality()` function from CHL5233 Week 3.
It reshapes wide World Bank mortality tables into country-year data and includes
the maternal mortality file used in class.

## Install

```r
install.packages("remotes")
remotes::install_github(
  "millywucello/pivotwbmilly",
  upgrade = "never",
  build_vignettes = TRUE
)
```

Runtime dependencies are `dplyr`, `tidyr`, and `rlang`. Building the tutorial also needs
`knitr`, `rmarkdown`, and Pandoc.

## Example

```r
library(pivotwbmilly)

maternal_long <- prepare_mortality(maternal_mortality, "maternal_mortality")
dim(maternal_long)
# [1] 3720    3

sum(is.na(maternal_long$maternal_mortality))
# [1] 426

recent <- prepare_mortality(maternal_mortality, "mmr", years = 2015:2017)
recent[recent$iso == "CAN", ]
```

The input needs one row per country, an `iso` column, and year columns such as
`X2000`. The output contains `iso`, integer `year`, and the requested measure,
sorted by country and year. Missing values stay missing. Extra columns such as
`indicator` are omitted, and the input is left unchanged.

Use the same function for the infant, neonatal, or under-five mortality files
from Week 3 by changing `outcome_name`.

## Help and development

```r
?prepare_mortality
?maternal_mortality
vignette("maternal-mortality", package = "pivotwbmilly")
```

From the package directory:

```r
devtools::document()
devtools::test()
devtools::check()
```

Help pages and `NAMESPACE` are generated from the roxygen comments in `R/`.
The tests check known country-year values, missing outcomes, year selection,
duplicate keys, and invalid inputs.

The bundled data are the unchanged course extract, not a current download from
the World Bank. `data-raw/build_data.R` recreates the `.rda` file from the CSV.
All 2018 and 2019 measures are missing in this extract. The software license
applies to the package code; the data retain their original source attribution.
