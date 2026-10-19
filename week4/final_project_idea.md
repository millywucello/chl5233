# Possible final project

Extend `pivotwbmilly` to prepare several World Bank health indicators in one
call. The Week 3 work used the same reshape for maternal, infant, neonatal,
and under-five mortality, then joined the results by country and year.

A `prepare_indicators()` function could accept a named list of tables and a
year range, reshape each table with `prepare_mortality()`, and join the results
on a complete country-year panel. A companion summary could report missing
values by indicator and year before the data enter a model.

The first version would use the supplied course files. Tests would cover
country lists that differ between files, absent years, duplicate country codes,
and preservation of missing values. Data downloads and country-name conversion
would be separate work; the current package expects the supplied ISO codes.

This is a proposal for discussion, not functionality included in version 0.1.0.
