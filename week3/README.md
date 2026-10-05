# Week 3 - Functions and analytical data preparation

CHL5233: Statistical Programming and Computation in Health Data

Project owner: Milly Wu

This project prepares a country-year dataset for the armed-conflict assignment.
It reshapes four mortality files, derives earthquake and drought indicators,
constructs the previous year's binary conflict exposure, and merges the supplied
covariates and region information. All original input files are retained.

**Final result:** [final_data.csv](data/processed/final_data.csv) contains
**3,720 rows and 20 variables**, covering **186 countries during 2000-2019**.
The [primary R script](scripts/create_final_data.R) and
[separate coding-agent script](scripts/create_final_data_agent.R) produce exactly
the same data. All **30 validation checks pass**, including agreement across
all **74,400 cells** and their missing-value positions.

## Project structure

```text
week3/
  README.md
  data/
    raw/                         # Nine unchanged files from raw.zip
      maternal_mortality.csv
      infant_mortality.csv
      neonatal_mortality.csv
      under5_mortality.csv
      conflict.csv
      disaster.csv
      covariates.csv
      countries.txt
      regions.txt
    processed/
      final_data.csv             # Main dataset for subsequent coursework
      final_data_agent.csv       # Separate implementation's dataset
  scripts/
    create_final_data.R
    create_final_data_agent.R
    compare_outputs.R            # Runs both scripts and validates the outputs
  reports/
    comparison.md
    data_dictionary.md
    agent_specification.md
    validation_checks.csv
    missingness.csv
    conflict_definition_differences.csv
    input_manifest.csv
    session_info.txt
  reference/
    functions_inclass.pdf
    prepare_matmor.R
    prepare_mortality.R
```

The assignment suggests an `armed_conflict` repository. As requested, this work
is archived in **`chl5233/week3`**, retaining its required `data/raw`,
`data/processed`, `scripts`, and `reports` organization.

## Run the project

The project was tested with R 4.2.3. The scripts require R 4.1 or later and the
R packages `dplyr`, `tidyr`, and `janitor`. Install them once in the **R Console**:

```r
install.packages(c("dplyr", "tidyr", "janitor"),
                 repos = "https://cloud.r-project.org")
```

From a **Terminal** with `chl5233` as the working directory, run:

```sh
Rscript --vanilla week3/scripts/compare_outputs.R
```

This command runs both implementations, saves their separate datasets, validates
the results, and regenerates the comparison report and supporting audit files.
An error stops the run if a check fails. No internet connection is required
after the R packages are installed.

To run only the main data-preparation script:

```sh
Rscript --vanilla week3/scripts/create_final_data.R
```

To run only the comparison implementation:

```sh
Rscript --vanilla week3/scripts/create_final_data_agent.R
```

In **Positron or RStudio**, open the `chl5233` folder and enter this in the
**R Console**:

```r
source("week3/scripts/compare_outputs.R", encoding = "UTF-8")
```

Alternatively, open `week3/scripts/create_final_data.R` and use **Source** to
regenerate just the main CSV. When the working directory is already `week3`,
use `source("scripts/create_final_data.R", encoding = "UTF-8")`.
The scripts locate their project folder and always save inside `week3`.

If an R startup warning reports an unavailable locale on macOS, the validated
Terminal invocation for this machine is:

```sh
LC_ALL=en_US.UTF-8 Rscript --vanilla week3/scripts/compare_outputs.R
```

## Assignment steps and implementation

1. **Prepare World Bank data.** `prepare_mortality()` selects the supplied
   `X2000`-`X2019` columns and uses `tidyr::pivot_longer()` to create a numeric
   year and one outcome column. The same function is applied to all four files.
   Missing outcomes remain `NA`.
2. **Prepare disaster data.** `janitor::clean_names()` standardizes column names.
   Only `Earthquake` and `Drought` records with `Year` from 2000 through 2019 are
   retained. Grouped `any()` produces one binary indicator per type and
   country-year. Repeated events do not produce additional rows.
3. **Prepare conflict data.** Sum `best` within each `(iso, year, conflict_id)`.
   A country-year is exposed if at least one conflict totals **25 or more
   battle-related deaths**. Event rows are not deduplicated: repeated values in
   the reduced source columns can represent distinct events.
4. **Apply the one-year lag.** `armed_conflict_lag1` for outcome year `t` uses
   conflict status in `t - 1`. The supplied conflict data cover **1999-2018**,
   so 2000 uses 1999 exposure and 2019 uses 2018 exposure. The main script shifts
   the year key; the agent script lags a complete calendar within each country.
5. **Merge all inputs.** Use the 186 supplied countries crossed with 2000-2019
   as the master panel. Join mortality, disasters, conflict, and covariates by
   `iso` and `year`, and geography by `iso`. Save the sorted result as a UTF-8 CSV.
6. **Compare with a coding agent.** A separate implementation uses base R
   `reshape()`, `aggregate()`, and `merge()`. It reads the raw files itself and
   saves `final_data_agent.csv`. The comparison script checks both exported CSVs
   and tests important edge cases. The [comparison report](reports/comparison.md)
   explains correctness, efficiency, missingness, and the conflict definition.

## Definition choices and input limitations

- **Conflict threshold.** The [paper's Methods](https://journals.plos.org/plosmedicine/article?id=10.1371/journal.pmed.1003810)
  describes cumulative deaths within a calendar-conflict year and classification
  per conflict within a country-year. We use the per-conflict threshold above.
  Pooling deaths across unrelated conflicts first would change **13** exposure
  values; the [difference table](reports/conflict_definition_differences.csv)
  records every affected country and year.
- **No-event placeholders.** The conflict file has **2,696** country-years with
  a single row in which both `conflict_id` and `best` are missing. These are
  interpreted as explicit no-event placeholders. Partially missing event records,
  placeholders mixed with events, and missing required source years stop the run.
- **Missing outcomes and covariates.** These remain `NA`. Maternal mortality has
  **426** missing entries, including all countries in 2018-2019. There is no
  imputation, blanket replacement of missing values with zero, or complete-case
  deletion. See the [missingness audit](reports/missingness.csv).
- **Disaster zeros.** A zero means no recorded event of the selected type in the
  supplied extract. The code uses the supplied `Year` field and does not expand
  multi-year droughts across start/end years.
- **Country sample.** This course panel retains all **186 supplied countries**.
  It does not impose the paper's final country exclusions or reproduce its
  regression sample. The assignment requests data preparation only.
- **Names and encodings.** Raw bytes are unchanged. Text lookup files are read
  using `latin1`, as in Week 2; existing country-name encoding artifacts are not
  used for matching. Joins use the supplied ISO codes, and the output uses UTF-8.
- **Handout versus supplied files.** The handout mentions 1960-2021 and an
  `original` directory, but the supplied mortality files already contain
  `X2000`-`X2019`, and the required final structure uses `data/raw`. Also,
  `pivot_longer()` is a `tidyr` function. The reference R scripts are preserved
  unchanged for provenance; their old paths and schemas are not used by this
  project.

## Results and documentation

| Item | Result |
|---|---:|
| Countries | 186 |
| Outcome years | 2000-2019 |
| Country-year rows | 3,720 |
| Variables | 20 |
| Previous-year conflict indicator = 1 | 691 |
| Earthquake indicator = 1 | 310 |
| Drought indicator = 1 | 325 |
| Differences between delivered datasets | 0 |
| Validation checks passed | 30 |

See the [data dictionary](reports/data_dictionary.md) for the 20 variables,
[comparison report](reports/comparison.md) for the analytical decisions,
[agent specification](reports/agent_specification.md) for the comparison task,
and [session information](reports/session_info.txt) for tested package versions.
The [input manifest](reports/input_manifest.csv) records the size and MD5 checksum
of every raw file.

Both delivered implementations were prepared with Codex assistance. The comparison
is between two separate code implementations; it is not presented as a comparison
against independently student-authored code.

## Commit and push later updates

After editing, run the comparison script and review its results. Then use the
**Terminal** from the repository root:

```sh
git pull --ff-only origin main
git add week3 README.md
git diff --cached --stat
git commit -m "Update Week 3 data preparation and validation"
git push origin main
```

The submitted project is available in the
[Week 3 folder on GitHub](https://github.com/millywucello/chl5233/tree/main/week3).

## References

- [Week 3 assignment handout](reference/functions_inclass.pdf).
- Course-provided `raw.zip`, `prepare_matmor.R`, and `prepare_mortality.R`.
  Original data sources listed in the handout are the World Bank, UCDP, and EM-DAT.
- Jawad M, Hone T, Vamos EP, Cetorelli V, Millett C (2021).
  [Implications of armed conflict for maternal and child health: A regression analysis of data from 181 countries for 2000-2019](https://doi.org/10.1371/journal.pmed.1003810).
  PLOS Medicine 18(9): e1003810.
