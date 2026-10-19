# Week 4 - Building an R package

The package [pivotwbmilly](pivotwbmilly/) contains the Week 3
`prepare_mortality()` function, the course maternal mortality data, roxygen help
pages, a worked tutorial, and `testthat` tests.

```text
week4/
  pivotwbmilly/
    DESCRIPTION
    NAMESPACE
    R/
    man/
    data/maternal_mortality.rda
    data-raw/
    tests/
    vignettes/
  scripts/
    check_assignment.R
    example.R
  reports/
  peer_review.md
  final_project_idea.md
```

The public function keeps the Week 3 arguments:

```r
prepare_mortality(data, outcome_name, years = 2000:2019)
```

Input checks now give errors for duplicate or missing country codes, absent
year columns, and invalid arguments. The reshape still uses `dplyr::select()`,
`tidyr::pivot_longer()`, and `dplyr::arrange()`. It keeps all missing outcomes.
The maternal example returns 3,720 rows, three columns, and 426 missing measures.

## Use in Positron

Open `chl5233` and run in the R Console:

```r
devtools::load_all("week4/pivotwbmilly")
maternal_long <- prepare_mortality(maternal_mortality, "maternal_mortality")
head(maternal_long)
?prepare_mortality
```

For an installed copy, follow the [package installation instructions](pivotwbmilly/README.md).
The GitHub install uses `subdir = "week4/pivotwbmilly"`. The package also installs
locally with `R CMD INSTALL week4/pivotwbmilly` from the repository root.

## Check the assignment

From a Terminal in `chl5233`:

```sh
Rscript --vanilla week4/scripts/check_assignment.R
```

This regenerates the help pages and bundled data, runs the tests, compares the
output with Week 3 for all four mortality files, and builds and checks the
package, including its tutorial. Results are saved in `week4/reports/`.
Install `devtools`, `roxygen2`, `testthat`, `rcmdcheck`, `knitr`, and `rmarkdown`
before running this development script. Runtime dependencies are listed in
`DESCRIPTION`.

The recorded run passed 40 test expectations across six test blocks and all
eight assignment checks. The outputs match the Week 3 function for each of the
four mortality files. `R CMD check --no-manual` finished with 0 errors,
0 warnings, and 0 notes, including example and vignette checks. Local
installation and the standalone example also ran successfully. See
[validation_checks.csv](reports/validation_checks.csv) and
[package_check.txt](reports/package_check.txt) for the results.

## Peer review and repository layout

The assignment calls for a separate repository containing only the package.
This copy is in `chl5233/week4` as requested. Its package directory can be copied
to the root of a separate repository if that layout is required for submission.

The [peer review notes](peer_review.md) give installation and trial tasks for a
classmate. No classmate feedback has been received yet. The automated tests and
package check are recorded separately from peer review.

A possible extension for the final project is described in
[final_project_idea.md](final_project_idea.md).
