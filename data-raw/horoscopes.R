library(rvest)
library(stringr)
library(dplyr)
library(tidytext)
library(lubridate)
library(httr)
library(forcats)
library(purrr)
library(tidyr)
library(forcats)

# Check which URLs exist for all year/month combinations
horoscopes <- crossing(year = 2015:2017,
                       month = c("01", "02", "03", "04", "05", "06",
                                 "07", "08", "09", "10", "11", "12")) %>%
  mutate(date_url = map2_chr(year, month,
                             ~ str_c("http://chaninicholas.com/", .x, "/", .y)),
         url_exists = map_lgl(date_url,
                              ~ (status_code(GET(.x)) >= 300) == FALSE)) %>%
  filter(url_exists)

# Get page 2 of horoscopes for year/month combinations that exist (if it exists too!)
horoscopes <- horoscopes %>%
  bind_rows(horoscopes %>%
              mutate(date_url = str_c(date_url, "/page/2"),
                     url_exists = NA)) %>%
  mutate(url_exists = if_else(is.na(url_exists),
                              map_lgl(date_url,
                                      ~ (status_code(GET(.x)) >= 300) == FALSE),
                              url_exists)) %>%
  filter(url_exists)

# Extract horoscope links from each date link
horoscopes <- horoscopes %>%
  mutate(url = pmap(list(date_url, year, month),
                    function(date_url, year, month)
                      date_url %>%
                      read_html() %>%
                      html_nodes("a") %>%
                      html_attr("href") %>%
                      str_subset('scope') %>% # only horoscope links -- sometimes written weirdly!
                      str_subset(str_c(year, "/", month)) %>% # for that year/month only
                      unique())) %>%
  unnest(url) %>%
  select(-date_url) %>%
  unique()

# Extract start date for each horoscope
horoscopes <- horoscopes %>%
  mutate(day = map_dbl(url,
                       ~ str_match(str_match(.x, "scope(.*?)/")[,2], "[0-9]+") %>%
                         as.numeric()),
         startdate = ymd(str_c(year, "/", month, "/", day)))

# Fill in missing dates
horoscopes <- horoscopes %>%
  mutate(date_manual = case_when(.$url == "http://chaninicholas.com/2015/01/new-moon-aquariusmercury-retrograde-horoscopes/" ~ ymd("2015-01-19"),
                                 .$url == "http://chaninicholas.com/2015/02/new-moon-aquarius-horoscopes/" ~ ymd("2015-02-16"),
                                 .$url == "http://chaninicholas.com/2015/12/horoscopes-for-the-winter-solstice-and-the-full-moon-in-cancer/" ~ ymd("2015-12-21"),
                                 .$url == "http://chaninicholas.com/2017/01/2017-your-horoscope-for-the-year-ahead/" ~ ymd("2017-01-02")),
         startdate = if_else(is.na(startdate), date_manual, startdate)) %>%
  select(-day, -date_manual)


# Extract horoscope text, split into paragraphs
horoscopes <- horoscopes %>%
  mutate(text = map_chr(url,
                        ~ .x %>%
                          read_html() %>%
                          html_nodes('.entry-content') %>%
                          html_text() %>%
                          iconv(to = 'UTF-8') %>%
                          str_replace_all(c("[\r]" = " ", "[“‘’”]" = "'"))),
         text_split = map(text,
                          ~ .x %>%
                            strsplit('\n') %>%
                            unlist() %>%
                            str_trim()),
         text_split = map(text_split,
                          ~ .x[.x != ""]))

# Remove duplicate elements within each horoscope (ads, etc)
horoscopes <- horoscopes %>%
  mutate(text_split = map(text_split,
                          ~ .x[!(duplicated(.x)) & !(duplicated(.x, fromLast = TRUE))]),
         text_length = map_dbl(text_split, ~length(.x)))

# Get the horoscope that corresponds to each sign
horoscopes <- horoscopes %>%
  mutate(join = TRUE) %>%
  left_join(tibble(zodiacsign = c("Aries", "Taurus", "Gemini" ,"Cancer",
                            "Leo", "Virgo", "Libra", "Scorpio",
                            "Sagittarius", "Capricorn", "Aquarius", "Pisces"),
                   join = TRUE),
            by = "join") %>%
  group_by(startdate, zodiacsign) %>%
  mutate(start_of_sign = map2(text_split, zodiacsign,
                              ~ which(str_detect(.x, str_c("^", .y, ".*Rising")) |
                                        str_detect(.x, str_c("^", .y, " &")) |
                                        .x == .y)),
         start_of_sign = ifelse(length(unlist(start_of_sign)) != 0,
                                unlist(start_of_sign) + 1,
                                NA)) %>%
  ungroup() %>%
  mutate(end_of_sign = ifelse(zodiacsign != 'Pisces',
                              lead(start_of_sign) - 2,
                              text_length),
         horoscope = pmap_chr(list(text_split, start_of_sign, end_of_sign),
                              function(text_split, start_of_sign, end_of_sign)
                                str_c(text_split[start_of_sign:end_of_sign], collapse = " ")))

# Remove exta variables, order by date/signs
horoscopes <- horoscopes %>%
  select(startdate, zodiacsign, horoscope, url)  %>%
  mutate(zodiacsign = fct_relevel(zodiacsign, c("Aries", "Taurus", "Gemini", "Cancer",
                                                "Leo", "Virgo", "Libra", "Scorpio",
                                                "Sagittarius", "Capricorn", "Aquarius", "Pisces"))) %>%
  arrange(startdate, zodiacsign)


# Add data files to package
devtools::use_data(horoscopes, overwrite = TRUE)
