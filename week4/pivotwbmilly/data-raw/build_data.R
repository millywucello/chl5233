# Run from the pivotwbmilly package directory.
maternal_mortality <- read.csv(
  "data-raw/maternal_mortality.csv", stringsAsFactors = FALSE
)
stopifnot(nrow(maternal_mortality) == 186L,
          ncol(maternal_mortality) == 22L,
          !anyDuplicated(maternal_mortality$iso))
save(maternal_mortality, file = "data/maternal_mortality.rda",
     compress = "xz", version = 2)
