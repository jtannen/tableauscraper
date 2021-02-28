library(tableauscraper)

# site <- "https://www.phila.gov/programs/coronavirus-disease-2019-covid-19/vaccines/data/"
# html <- xml2::read_html(site)
# xml2::write_html(html, file="vaccine_site.html")
# res <- gen_config(site)
# saveRDS(res, file="config.RDS")

test_that("gen_config", {
  ## TODO: Explore Snapshot Tests

  site <- "https://www.phila.gov/programs/coronavirus-disease-2019-covid-19/vaccines/data/"
  expected_config <- readRDS("data/config.RDS")

  res <- mockr::with_mock(
    read_html=function(x){
      expect_equal(x, site)
      xml2::read_html("data/vaccine_site.html")
    },
    gen_config(site)
  )

  expect_equal(res, expected_config)
})
