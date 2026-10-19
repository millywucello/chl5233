# Peer review

Status: awaiting a classmate's trial and feedback.

## Installation and trial

Run in a fresh R session:

```r
install.packages("remotes")
remotes::install_github("millywucello/chl5233",
                        subdir = "week4/pivotwbmilly", upgrade = "never")
library(pivotwbmilly)
example("prepare_mortality", package = "pivotwbmilly")
?prepare_mortality

result <- prepare_mortality(maternal_mortality, "mmr")
stopifnot(nrow(result) == 3720L, sum(is.na(result$mmr)) == 426L)
prepare_mortality(maternal_mortality, "mmr", years = 2015:2017)
```

Try a missing year, such as 2020, and check whether the error identifies the
problem. Try a different output name and a different selection of years.

Please record the R version, whether installation worked, any confusing help
text, and any unexpected output. Include the smallest example that reproduces
an error. Feedback and changes can be added below after the trial.

## Feedback received

None recorded.

## Changes after review

None recorded.
