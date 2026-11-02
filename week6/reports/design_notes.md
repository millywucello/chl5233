# Table and figure design

## Table 1: who is represented?

The table describes the validated course panel before outcome-specific model
exclusions. The observation is a country-year, not a person or an independent
country. It includes 3,720 rows covering 186 countries from 2000 through 2019.
That scope is stated in the title and notes because a future maternal model
cannot use all of those years without addressing the missing outcome.

Columns show the overall panel and the binary exposure groups. The exposure
is qualifying conflict in the previous year, so the 2000 row uses 1999 conflict
status. Overall and stratum-specific country counts are shown as well as row
counts. Seventy-five countries appear in both exposure strata over time, so the
stratum-specific country counts must not be added to estimate the sample size.
The years-per-country row describes the repeated-measure structure.

Rows cover calendar time, region, the four mortality outcomes, the seven
continuous covariates, OECD membership, earthquake, and drought. The country
identifiers and 17 sub-region categories are omitted from the display because
they would add considerable length; the broad region categories provide the
geographic summary. The input retains the full identifiers and categories.

Continuous variables use medians and quartiles, which describe the skewed
mortality and GDP distributions without relying on a mean alone. Year is shown
as a range. Binary and region rows show counts and column percentages. The
percent denominator is the number of non-missing observations for that variable
within the column group. Missing counts are explicit, including zeros.

There is no p-value column. Descriptive differences are not a test of whether
confounding exists, and repeated observations within countries violate a simple
independent-observation comparison. No weights are supplied, so all summaries
are unweighted. Covariate scales are left as supplied and labeled as such where
the course CSV lacks a complete unit codebook.

The table shows 426 missing maternal observations: 372 from the completely
missing 2018-2019 years and 54 from earlier years. Missingness is also displayed
within each exposure group. The table does not silently switch to a common
complete-case subset. Once a model and its missing-data method are specified,
a corresponding analytical-sample table should be regenerated.

## Figure 1: what counts as an increase?

Countries are selected only when both endpoints are observed and the 2017
maternal mortality ratio is strictly greater than the 2000 ratio. Three countries
lack endpoints. Of the remaining 183, 13 have an increase and 170 do not.
The selected countries contribute 234 observed annual values (13 times 18).
The final year is 2017 because every supplied maternal value in 2018 and 2019
is missing.

The figure plots the annual levels in deaths per 100,000 live births. It does
not plot the difference from 2000 or smooth the trajectories. Each country has
a unique color, with a direct label at the right endpoint. Points mark the two
selection years. The horizontal lines leading to labels are label connectors,
not extrapolated observations.

Rates differ by more than an order of magnitude. A logarithmic y-axis makes
the lower-rate trajectories readable while keeping all countries in one panel.
The axis and caption state this choice: equal vertical distances represent
ratios, not equal absolute changes. The saved endpoint table provides the
absolute differences. Haiti rises from 437 to 480 (+43), while Canada rises
from 9 to 10 (+1). Neither difference alone establishes statistical uncertainty
or an effect of conflict.

Selecting countries because their endpoint rose is a descriptive restriction.
The figure cannot support the conclusion that mortality rose globally, and it
does not identify conflict as the cause of any country's trend.

## How the readings informed the outputs

Hayes-Larson and colleagues connect Table 1 design to the study's observation
units, exposure, missing data, and potential confounding. That informed the
overall and exposure-stratified columns, explicit missing counts, country-level
counts alongside country-years, and omission of significance tests.

Franzblau and Chung emphasize choosing the display for the data, labeling units,
avoiding decorative elements that obscure values, and making a graphic
understandable on its own. The table uses restrained rules and rounded values.
The line figure uses actual annual observations, direct labels, an explicit
scale, and a caption that states the selection rule and time limit.

## Review status

The coding review checked values and denominators against the input, compared
the selected countries with an independent endpoint merge, and checked the
rendered one-page PDF and PNG for clipping and label overlap. Classmate review
has not yet occurred. Suggested trial questions are in `peer_review.md`.

## References

Hayes-Larson E, Kezios KL, Mooney SJ, Lovasi G. Who is in this study, anyway?
Guidelines for a useful Table 1. Journal of Clinical Epidemiology.
2019;114:125-132. https://doi.org/10.1016/j.jclinepi.2019.06.011

Franzblau LE, Chung KC. Graphs, tables, and figures in scientific publications:
The good, the bad, and how not to be the latter. Journal of Hand Surgery.
2012;37A:591-596. https://doi.org/10.1016/j.jhsa.2011.12.041
