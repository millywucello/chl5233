week6_paths <- function() {
  paths <- c(sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)),
             unlist(lapply(sys.frames(), function(x) x$ofile)))
  candidates <- c(file.path(getwd(), "week6"), getwd(), file.path(getwd(), ".."),
                  file.path(dirname(paths), ".."))
  found <- candidates[file.exists(file.path(candidates, "R/paths.R"))]
  if (!length(found)) stop("Open the chl5233 or week6 folder first.")
  root <- normalizePath(found[1])
  input <- file.path(root, "..", "week5/data/processed/final_data.csv")
  if (!file.exists(input)) stop("Rebuild Week 5 first.")
  list(root = root, input = input, outputs = file.path(root, "outputs"))
}
