#' Weekly horoscopes from Chani Nicholas
#'
#' Returns horoscopes from \url{http://chaninicholas.com}. Includes data for
#' 2015-2017, with start dates between 2015-01-05 and 2017-02-06.All horoscopes
#' are written for one week, with the exception of the horoscopes starting on
#' 2015-03-23, which were written for two weeks.
#'
#' Horoscopes are missing for the weeks starting on 2015-06-29, 2016-10-31,
#' and 2016-12-26.
#'
#' @format A data frame with 1272 rows and 4 variables:
#' \describe{
#'   \item{\code{startdate}}{the start date that this weekly horoscope is for}
#'   \item{\code{zodiacsign}}{the zodiac sign this horoscope is for}
#'   \item{\code{horoscope}}{the horoscope itself}
#'   \item{\code{url}}{the URL that the horoscope is pulled from}
#' }
#' @source \url{http://chaninicholas.com}
"horoscopes"
