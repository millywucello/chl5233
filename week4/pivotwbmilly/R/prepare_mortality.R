#' Reshape a World Bank mortality table
#'
#' Convert selected `XYYYY` columns to one row per country and year.
#' Country codes and missing outcome values are retained. Other input columns,
#' such as the indicator description, are omitted.
#'
#' @param data A data frame with one row per country, an `iso` column, and
#'   numeric year columns named `X2000`, `X2001`, and so on. A year column
#'   containing only missing values may be logical, as returned by `read.csv()`.
#' @param outcome_name A single non-empty string naming the output measure.
#'   Must differ from `iso` and `year`.
#' @param years A non-empty numeric vector of distinct whole calendar years
#'   between 0 and 9999. Defaults to `2000:2019`.
#'
#' @return A tibble sorted by `iso` and `year`, with three columns: the original
#'   country code, an integer year, and the measure named by `outcome_name`.
#'   Every input country contributes one row per selected year, including years
#'   with missing outcomes. The input data are not changed.
#'
#' @details This is the `prepare_mortality()` function used in the Week 3
#'   coursework, with input checks added for use outside that script. Missing
#'   year columns and missing or repeated country codes cause an error.
#'   Missing measures are kept as `NA`; they are not replaced or imputed.
#'
#' @examples
#' maternal_long <- prepare_mortality(maternal_mortality, "maternal_mortality")
#' dim(maternal_long)
#' head(maternal_long)
#' sum(is.na(maternal_long$maternal_mortality))
#'
#' prepare_mortality(maternal_mortality, "mmr", years = 2015:2017)
#'
#' @importFrom rlang .data
#' @export
prepare_mortality <- function(data, outcome_name, years = 2000:2019) {
  if (!is.data.frame(data) || anyDuplicated(names(data))) {
    stop("data must be a data frame with unique column names.", call. = FALSE)
  }
  if (!is.character(outcome_name) || length(outcome_name) != 1L ||
      is.na(outcome_name) || !nzchar(trimws(outcome_name)) ||
      outcome_name %in% c("iso", "year")) {
    stop("outcome_name must be one non-empty name other than iso or year.",
         call. = FALSE)
  }
  if (!is.numeric(years) || !length(years) || anyNA(years) ||
      any(!is.finite(years)) || any(years != trunc(years)) ||
      any(years < 0 | years > 9999) || anyDuplicated(years)) {
    stop("years must contain distinct whole years between 0 and 9999.",
         call. = FALSE)
  }
  year_columns <- paste0("X", as.integer(years))
  missing_columns <- setdiff(c("iso", year_columns), names(data))
  if (length(missing_columns)) {
    stop("Missing required columns: ", paste(missing_columns, collapse = ", "),
         call. = FALSE)
  }
  if (!(is.character(data$iso) || is.factor(data$iso)) ||
      anyNA(data$iso) || any(!nzchar(trimws(as.character(data$iso)))) ||
      anyDuplicated(data$iso)) {
    stop("iso must contain non-missing, non-empty, unique country codes.",
         call. = FALSE)
  }
  valid_values <- vapply(data[year_columns], function(x) {
    is.numeric(x) || (is.logical(x) && all(is.na(x)))
  }, logical(1))
  if (any(!valid_values)) {
    stop("Year columns must be numeric or entirely missing: ",
         paste(year_columns[!valid_values], collapse = ", "), call. = FALSE)
  }

  # Select exact years so indicator metadata cannot enter the reshape.
  data |>
    dplyr::select(dplyr::all_of(c("iso", year_columns))) |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(year_columns), names_to = "year", names_prefix = "X",
      names_transform = list(year = as.integer), values_to = outcome_name
    ) |>
    dplyr::arrange(.data$iso, .data$year)
}
