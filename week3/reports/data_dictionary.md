# Week 3 - Data dictionary

File: `data/processed/final_data.csv`

Unit of observation: one country in one outcome year

Unique key: `iso` + `year`

Coverage: 186 course-supplied countries, 2000-2019

Dimensions: 3,720 rows x 20 columns

Encoding: UTF-8; missing values are written as `NA`

| Variable | Type | Meaning and scale | Source |
|---|---|---|---|
| `iso` | Character | Supplied three-letter country identifier; used for all joins | `countries.txt` |
| `country_name` | Character | Country label from the supplied study list | `countries.txt` |
| `year` | Integer | Outcome/analysis calendar year, 2000-2019 | Constructed panel |
| `region` | Character | Supplied broad geographic region | `regions.txt` |
| `sub_region` | Character | Supplied geographic sub-region | `regions.txt` |
| `maternal_mortality` | Numeric | Maternal mortality ratio: deaths per 100,000 live births | `maternal_mortality.csv` |
| `infant_mortality` | Numeric | Infant mortality rate: deaths before age 1 per 1,000 live births | `infant_mortality.csv` |
| `neonatal_mortality` | Numeric | Neonatal mortality rate: deaths during the first 28 days per 1,000 live births | `neonatal_mortality.csv` |
| `under5_mortality` | Numeric | Under-5 mortality rate per 1,000 live births | `under5_mortality.csv` |
| `earthquake` | Integer, 0/1 | At least one recorded earthquake in the country during `year` | `disaster.csv` |
| `drought` | Integer, 0/1 | At least one recorded drought in the country during `year` | `disaster.csv` |
| `armed_conflict_lag1` | Integer, 0/1 | At least one conflict with at least 25 cumulative deaths in the country during `year - 1` | `conflict.csv` |
| `gdp_1000` | Numeric | Supplied GDP per capita variable, scaled in thousands | `covariates.csv`, unchanged |
| `oecd` | Integer, 0/1 | Supplied OECD membership indicator | `covariates.csv`, unchanged |
| `pop_dens` | Numeric | Supplied population density variable | `covariates.csv`, unchanged |
| `urban` | Numeric | Supplied urban residence variable | `covariates.csv`, unchanged |
| `age_dep` | Numeric | Supplied age dependency ratio | `covariates.csv`, unchanged |
| `male_edu` | Numeric | Supplied male educational attainment variable | `covariates.csv`, unchanged |
| `temp` | Numeric | Supplied population-weighted mean temperature variable | `covariates.csv`, unchanged |
| `rainfall_1000` | Numeric | Supplied population-weighted rainfall variable, scaled by 1,000 | `covariates.csv`, unchanged |

The mortality units are recorded in the raw files' `indicator` column. Covariates
are already processed by the course provider. Their names and values are retained
without rescaling. The supplied CSV has no full unit/denominator codebook for the
covariates; detailed measurement conventions should be confirmed before modeling.
The [paper's Methods](https://journals.plos.org/plosmedicine/article?id=10.1371/journal.pmed.1003810)
identifies the intended covariates and source agencies.

## Derived-variable rules

- Conflict event deaths are summed within **country + source year + conflict ID**.
  The threshold is applied to these totals; a country-year is positive if any
  conflict qualifies. The derived flag is joined to **source year + 1**.
- `earthquake` and `drought` refer to the **same year** as the outcome, not the
  previous year. Multiple events of the same type still yield a single 1.
- A zero event indicator means the supplied records do not contain a qualifying
  event under the documented rules. It does not imply zero deaths from all causes.
- Missing mortality and covariate values remain `NA`. Event placeholders are
  handled separately, as explained in the README.
- The final CSV deliberately contains only the lagged conflict indicator.
  Contemporaneous 2019 conflict is not available in the supplied input.

## Missingness

The machine-generated [missingness table](missingness.csv) reports each variable's
number and percentage of missing values. All identifiers, geographic labels, and
event indicators are complete. Do not remove all rows with any `NA` as a generic
data-preparation step; a later analysis should define its own outcome-specific
sample and missing-data approach.
