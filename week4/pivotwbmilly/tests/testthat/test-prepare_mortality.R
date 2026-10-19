test_that("country-year values and missing outcomes stay in place", {
  input <- data.frame(
    iso = c("BBB", "AAA"), indicator = "Example",
    X2000 = c(12, NA_real_), X2001 = c(8, 5)
  )
  original <- input
  result <- prepare_mortality(input, "rate", 2000:2001)
  expected <- data.frame(
    iso = c("AAA", "AAA", "BBB", "BBB"),
    year = c(2000L, 2001L, 2000L, 2001L), rate = c(NA_real_, 5, 12, 8)
  )
  expect_equal(as.data.frame(result), expected)
  expect_identical(input, original)
})

test_that("requested years are selected exactly and sorted numerically", {
  input <- data.frame(iso = "CAN", X1999 = 50, X2000 = 9, X2001 = 7,
                      X2002 = 6, X2000_note = "Metadata")
  result <- prepare_mortality(input, "rate", c(2002, 2000))
  expect_identical(result$year, c(2000L, 2002L))
  expect_equal(result$rate, c(9, 6))
  expect_named(result, c("iso", "year", "rate"))
})

test_that("the bundled course data preserve the known sample and missingness", {
  result <- prepare_mortality(maternal_mortality, "mmr")
  expect_equal(dim(maternal_mortality), c(186L, 22L))
  expect_equal(dim(result), c(3720L, 3L))
  expect_equal(length(unique(result$iso)), 186L)
  expect_equal(sum(is.na(result$mmr)), 426L)
  expect_equal(anyDuplicated(result[c("iso", "year")]), 0L)
  expect_true(all(is.na(result$mmr[result$year %in% 2018:2019])))
  expect_equal(result$mmr[result$iso == "CAN" & result$year == 2000L], 9)
  expect_equal(result$mmr[result$iso == "CAN" & result$year == 2017L], 10)
})

test_that("entirely missing years and empty input are supported", {
  input <- data.frame(iso = "CAN", X2018 = NA, X2019 = NA)
  result <- prepare_mortality(input, "rate", 2018:2019)
  expect_equal(nrow(result), 2L)
  expect_true(all(is.na(result$rate)))
  empty <- prepare_mortality(input[FALSE, ], "rate", 2018:2019)
  expect_equal(nrow(empty), 0L)
  expect_named(empty, c("iso", "year", "rate"))
})

test_that("invalid country keys and missing columns fail before reshaping", {
  input <- data.frame(iso = c("CAN", "CAN"), X2000 = c(9, 10))
  expect_error(prepare_mortality(input, "rate", 2000), "unique country codes")
  input$iso <- c("CAN", NA_character_)
  expect_error(prepare_mortality(input, "rate", 2000), "non-missing")
  input$iso <- c("CAN", " ")
  expect_error(prepare_mortality(input, "rate", 2000), "non-empty")
  input$iso <- c("CAN", "USA")
  expect_error(prepare_mortality(input, "rate", 2000:2001), "X2001")
  expect_error(prepare_mortality(input["X2000"], "rate", 2000), "iso")
})

test_that("invalid names, year arguments, and value types are rejected", {
  input <- data.frame(iso = "CAN", X2000 = 9)
  for (name in list("iso", "year", "", " ", NA_character_, c("a", "b"), 1)) {
    expect_error(prepare_mortality(input, name, 2000), "outcome_name")
  }
  for (years in list(numeric(), "2000", c(2000, 2000), 2000.5, NA_real_,
                    Inf, -1, 10000)) {
    expect_error(prepare_mortality(input, "rate", years), "whole years")
  }
  input$X2000 <- "unavailable"
  expect_error(prepare_mortality(input, "rate", 2000), "Year columns")
  expect_error(prepare_mortality(matrix(1), "rate", 2000), "data frame")
  names(input)[2] <- "iso"
  expect_error(prepare_mortality(input, "rate", 2000), "unique column names")
})
