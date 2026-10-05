# Specification for the separate coding-agent implementation

Create `scripts/create_final_data_agent.R` as a separate implementation of the
Week 3 preparation task. Read the nine files in `data/raw` directly. Do not source
`create_final_data.R`, read its output, or overwrite the primary script or dataset.
Use a reusable function for reshaping the four mortality files, and use
`janitor::clean_names()` for the disaster column names. Prefer base R transformations
where practical so the implementation differs from the primary dplyr/tidyr code.

## Required output

Save `data/processed/final_data_agent.csv` as UTF-8, with no row names, explicit
`NA` values, and rows sorted by `iso` and `year`.

Use all 186 countries in `countries.txt` for all years 2000-2019. The result must
contain exactly 3,720 rows and these 20 columns in order:

```text
iso, country_name, year, region, sub_region,
maternal_mortality, infant_mortality, neonatal_mortality, under5_mortality,
earthquake, drought, armed_conflict_lag1,
gdp_1000, oecd, pop_dens, urban, age_dep, male_edu, temp, rainfall_1000
```

## Preparation rules

1. Reshape the `X2000`-`X2019` mortality columns with a reusable function. Preserve
   all values and missingness. Obtain country labels from the study list and
   regional labels from `regions.txt`, matching by country code.
2. Restrict disasters to the supplied `Year` field in 2000-2019 and types
   `Earthquake` and `Drought`. Create complete binary country-year indicators;
   repeated events of one type must still count as 1.
3. Sum `best` within `(iso, year, conflict_id)`. A country-year is exposed if
   **any** conflict total reaches 25 deaths. Do not pool unrelated conflicts before
   thresholding, and do not deduplicate event rows using the reduced columns.
4. Treat a single row with both `conflict_id` and `best` missing as an explicit
   no-event placeholder. Reject partially missing events and mixed placeholders.
   Require source-year coverage for every study country in 1999-2018.
5. Align conflict status from year `t - 1` to outcome year `t`. Use a complete
   country calendar before a row-based lag, so the first outcome year retains
   1999 exposure and the last retains 2018 exposure.
6. Merge the supplied covariates without rescaling, imputing, or dropping missing
   values. Reject duplicate country-year keys that could multiply records.

## Comparison requirements

Read both exported CSVs back into R and compare their dimensions, ordered column
names, keys, all values, and missing-value positions. Report differences honestly
and explain any methodological alternatives. Include source-value preservation
checks and threshold/lag edge cases. Record the R session and input checksums.

This specification documents the task used to construct the comparison script.
Both implementations were prepared with Codex assistance; it does not imply that
the primary code was independently written by a student or a different agent.
