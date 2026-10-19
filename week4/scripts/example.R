# Run from the chl5233 repository root after installing the package.
library(pivotwbmilly)

maternal_long <- prepare_mortality(maternal_mortality, "maternal_mortality")
print(head(maternal_long))
print(dim(maternal_long))
print(sum(is.na(maternal_long$maternal_mortality)))

recent <- prepare_mortality(maternal_mortality, "mmr", years = 2015:2017)
print(recent[recent$iso == "CAN", ])

stopifnot(nrow(maternal_long) == 3720L,
          sum(is.na(maternal_long$maternal_mortality)) == 426L)
