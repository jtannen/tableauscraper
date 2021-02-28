library(tableauscraper)


## SET UP DATA
if(FALSE){
  config <- list(
    host_url="https://healthviz.phila.gov/",
    path="t/PublicHealth/views/COVIDVaccineDashboard/COVID_Vaccine",
    req_url=":embed=y&:showVizHome=no&:host_url=https%3A%2F%2Fhealthviz.phila.gov%2F&:embed_code_version=3&:tabs=no&:toolbar=no&:alerts=no&:showShareOptions=false&:showAskData=false&:showAppBanner=false&:isGuestRedirectFromVizportal=y&:display_spinner=no&:loadOrderID=0"
  )

  req <- sprintf("%s/%s?%s", config$host_url, config$path, config$req_url)
  body <- xml2::read_html(req)
  saveRDS(req, "tests/testthat/data/req.RDS")
  xml2::write_xml(body, file="tests/testthat/data/body.xml")

  data <- body %>%
    rvest::html_nodes("textarea#tsConfigContainer") %>%
    rvest::html_text()

  json <- rjson::fromJSON(data)

  url <- httr::modify_url(
    config$host_url,
    path=paste0(json$vizql_root, "/bootstrapSession/sessions/", json$sessionid)
  )

  resp <- httr::POST(url, body = list(sheet_id = json$sheetId), encode = "form")
  saveRDS(url, "tests/testthat/data/url.RDS")
  saveRDS(resp, "tests/testthat/data/httr_post_resp.RDS")

  raw_data <- download_data(CONFIG)
  saveRDS(raw_data, file="tests/testthat/data/raw_output.RDS")

  res <- extract_all_dfs(raw_data)
  saveRDS(res, "tests/testthat/data/res.RDS")
}


test_that("download_data", {
  config <- list(
    host_url="https://healthviz.phila.gov/",
    path="t/PublicHealth/views/COVIDVaccineDashboard/COVID_Vaccine",
    req_url=":embed=y&:showVizHome=no&:host_url=https%3A%2F%2Fhealthviz.phila.gov%2F&:embed_code_version=3&:tabs=no&:toolbar=no&:alerts=no&:showShareOptions=false&:showAskData=false&:showAppBanner=false&:isGuestRedirectFromVizportal=y&:display_spinner=no&:loadOrderID=0"
  )

  req <- readRDS("data/req.RDS")
  body <- xml2::read_html(file("body.xml"))
  url <- readRDS("data/url.RDS")
  resp <- readRDS("data/httr_post_resp.RDS")
  expected_res <- readRDS("data/raw_output.RDS")

  res <- mockr::with_mock(
    read_html=function(x){expect_equal(x, req); body},
    POST=function(x, ...){expect_equal(x, url); resp},
    res <- download_data(config)
  )
  expect_equal(res, expected_res)
})


test_that("extract_all_dfs", {
  ## TODO: Explore snapshot testing

  raw_data <- readRDS("data/raw_output.RDS")
  expected_res <- readRDS("data/res.RDS")

  expect_equal(extract_all_dfs(raw_data), expected_res)

})

test_that("scrape_tableau integration", {
  config <- list(
    host_url="https://healthviz.phila.gov/",
    path="t/PublicHealth/views/COVIDVaccineDashboard/COVID_Vaccine",
    req_url=":embed=y&:showVizHome=no&:host_url=https%3A%2F%2Fhealthviz.phila.gov%2F&:embed_code_version=3&:tabs=no&:toolbar=no&:alerts=no&:showShareOptions=false&:showAskData=false&:showAppBanner=false&:isGuestRedirectFromVizportal=y&:display_spinner=no&:loadOrderID=0"
  )

  expected_res <- readRDS("data/res.RDS")
  body <- xml2::read_html(file("body.xml"))
  resp <- readRDS("data/httr_post_resp.RDS")

  expect_equal(
    expected_res,
    mockr::with_mock(
      read_html=function(x){body},
      POST=function(x, ...){resp},
      scrape_tableau(config)
    )
  )
})
