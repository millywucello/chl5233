# Week 3 - Implementation comparison and validation

## Provenance and comparison design

Both scripts were prepared with Codex assistance for this assignment. The primary script is a teaching-oriented solution; the separate agent script is an alternative implementation. No pre-existing, independently student-authored complete solution was supplied, so this report does not claim a human-versus-AI experiment.

The agent script reads the nine raw files directly. It does not source the primary script or read final_data.csv. Both implementations follow the same documented data specification; this is implementation diversity, not independent confirmation of the study definition.

| Step | Primary script | Separate agent script |
|---|---|---|
| Mortality reshape | Reusable tidyr::pivot_longer() function | Reusable base R reshape() function |
| Disaster indicators | Grouped any() after janitor::clean_names() | Country-year key membership after janitor::clean_names() |
| Conflict aggregation | dplyr grouped sums, then any(total >= 25) | aggregate() and membership in qualifying conflict-country-years |
| One-year lag | Increase the source-year join key by one | Complete the country calendar, then lag within country |
| Merging | left_join() onto the course panel | merge(all.x = TRUE) onto the course panel |

## Results

Both exported CSV files contain **3720 rows and 20 columns**. All **74400 cells**, including missing-value locations, match exactly after reading the UTF-8 CSV files back into R. There are **zero output differences**.

All **30 validation checks passed**. Checks cover unique keys, complete years, binary flags, every supplied mortality/covariate value, both lag endpoints, and synthetic threshold, missing-event, duplicate-key, and disaster cases.

| Measure | Result |
|---|---:|
| Countries | 186 |
| Outcome years | 2000-2019 |
| Source conflict years | 1999-2018 |
| Country-years exposed to conflict in the previous year | 691 |
| Country-years with an earthquake | 310 |
| Country-years with a drought | 325 |
| No-event conflict placeholders in the input | 2696 |

## Conflict definition and competing implementation

The paper's Data section defines a qualifying conflict using cumulative deaths within a calendar-conflict year. Its Measures section describes classification per conflict within a country-year. We therefore sum best within (iso, year, conflict_id), use a threshold of at least 25 deaths, and set the country-year flag to one if any conflict qualifies. The binary flag is then aligned to the following outcome year. See the [paper's Methods](https://journals.plos.org/plosmedicine/article?id=10.1371/journal.pmed.1003810).

A competing implementation that first pools deaths across every conflict in a country-year changes **13** exposure values. This is a definition comparison, not a disagreement between the two delivered scripts. See [the complete difference table](conflict_definition_differences.csv). For example, separate conflicts totaling 12 and 13 deaths must not jointly qualify as one 25-death conflict under the selected rule.

The input has exactly one row with both conflict_id and best missing for each no-event country-year. These explicit placeholders are interpreted as no recorded conflict. A real event with an unknown death count, or a placeholder mixed with event records, triggers an error. A missing source country-year also triggers an error instead of silently becoming zero.

## Correctness and efficiency

Both implementations are correct under the documented specification and produce identical data. The primary script is preferred for this course because its reusable functions and explicit dplyr/tidyr steps closely follow the handout and are easier to inspect and extend. The agent implementation is useful as a cross-check and uses base R for most transformations.

One local run, after loading the script definitions, took **0.303 seconds** for the primary pipeline and **0.375 seconds** for the agent pipeline. These are descriptive wall-clock timings, not a controlled benchmark; caching, execution order, and lazy package initialization affect them. Both are practical for this dataset, and the timings do not establish general superiority.

Both approaches aggregate events before joining and avoid row-by-row iteration over the full conflict input. The primary script uses grouped operations; the agent script uses aggregate() and vectorized key membership. Neither performs a large event-level join against the outcome panel.

## Missing data and scope

Missing outcomes and covariates remain NA; there is no imputation or complete-case deletion. Maternal mortality is missing for all countries in 2018 and 2019, with additional earlier missing values. The supplied course sample is 186 countries, so the output is a course data-preparation panel and does not claim to reproduce the paper's final analytical sample or regression estimates.

| Variable | Missing rows | Percent |
|---|---:|---:|
| maternal_mortality | 426 | 11.45% |
| infant_mortality | 20 | 0.54% |
| neonatal_mortality | 20 | 0.54% |
| under5_mortality | 20 | 0.54% |
| gdp_1000 | 62 | 1.67% |
| pop_dens | 20 | 0.54% |
| urban | 20 | 0.54% |
| male_edu | 20 | 0.54% |
| temp | 20 | 0.54% |
| rainfall_1000 | 20 | 0.54% |

Disaster zeros mean no recorded earthquake/drought of the requested type and year in the supplied extract. The provided Year field defines occurrence; events are not expanded across their duration. Country names retain source encoding artifacts; joins use ISO codes. Region matches use the supplied lookup.

## Reproduce

From the chl5233 repository root:

```sh
Rscript --vanilla week3/scripts/compare_outputs.R
```

This reruns both scripts and replaces their respective CSV outputs, this report, and the validation CSVs. The primary output is never overwritten by the agent output. See [validation checks](validation_checks.csv), [missingness](missingness.csv), [input checksums](input_manifest.csv), and [R session information](session_info.txt).
