#' Course-supplied maternal mortality data
#'
#' Wide maternal mortality table from the CHL5233 Week 3 data files. Values are
#' modeled maternal deaths per 100,000 live births. The data are included in
#' their original order, with missing values unchanged.
#'
#' @format A data frame with 186 rows and 22 columns:
#' \describe{
#'   \item{iso}{Three-letter country code. One row per country.}
#'   \item{indicator}{Description of the maternal mortality measure and unit.}
#'   \item{X2000, X2001, X2002, X2003, X2004, X2005, X2006, X2007, X2008,
#'     X2009, X2010, X2011, X2012, X2013, X2014, X2015, X2016, X2017}{Annual
#'     maternal mortality ratios. Some country-year values are missing.}
#'   \item{X2018, X2019}{Entirely missing in this course extract. Imported as
#'     logical columns by `read.csv()`.}
#' }
#' @details There are 426 missing values across the 20 year columns. The file
#'   covers the 186 countries supplied for class, rather than the final sample
#'   of the published armed-conflict analysis.
#' @source CHL5233 Week 3 course file `maternal_mortality.csv`, copied unchanged
#'   from `week3/data/raw` in the course repository. The indicator is World Bank
#'   maternal mortality ratio (modeled estimate, per 100,000 live births).
#' @seealso [prepare_mortality()]
#' @examples
#' dim(maternal_mortality)
#' maternal_mortality[maternal_mortality$iso == "CAN",
#'                    c("iso", "X2000", "X2017", "X2018", "X2019")]
"maternal_mortality"
