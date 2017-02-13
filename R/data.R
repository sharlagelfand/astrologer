#' Weekly horoscopes from Chani Nicholas
#'
#' Returns weekly horoscopes from \url{http://chaninicholas.com}. Includes data
#' for 2015-2017, all weeks that horoscopes were written for (start dates
#' between January 5, 2015 and February 6, 2017).
#'
#' @format A data frame with 1260 rows and 4 variables:
#' \describe{
#'   \item{startdate}{the start date that this weekly horoscope is for}
#'   \item{zodiacsign}{the zodiac sign this horoscope is for}
#'   \item{horoscope}{the horoscope itself}
#'   \item{url}{the URL that the horoscope is pulled from}
#' }
#' @source \url{http://chaninicholas.com}
"horoscopes"
