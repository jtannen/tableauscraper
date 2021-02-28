library(tableauscrape)


## SET UP DATA
if(FALSE){
  config <- list(
    host_url="https://healthviz.phila.gov/",
    path="t/PublicHealth/views/COVIDVaccineDashboard/COVID_Vaccine",
    req_url=":embed=y&:showVizHome=no&:host_url=https%3A%2F%2Fhealthviz.phila.gov%2F&:embed_code_version=3&:tabs=no&:toolbar=no&:alerts=no&:showShareOptions=false&:showAskData=false&:showAppBanner=false&:isGuestRedirectFromVizportal=y&:display_spinner=no&:loadOrderID=0"
  )

  req <- sprintf("%s/%s?%s", config$host_url, config$path, config$req_url)
  body <- xml2::read_html(req)
  saveRDS(req, "tests/testthat/req.RDS")
  xml2::write_xml(body, file="tests/testthat/body.xml")

  data <- body %>%
    rvest::html_nodes("textarea#tsConfigContainer") %>%
    rvest::html_text()

  json <- rjson::fromJSON(data)

  url <- httr::modify_url(
    config$host_url,
    path=paste0(json$vizql_root, "/bootstrapSession/sessions/", json$sessionid)
  )

  resp <- httr::POST(url, body = list(sheet_id = json$sheetId), encode = "form")
  saveRDS(url, "tests/testthat/url.RDS")
  saveRDS(resp, "tests/testthat/httr_post_resp.RDS")

  raw_data <- download_raw(CONFIG)
  saveRDS(raw_data, file="tests/testthat/raw_output.RDS")

  res <- extract_all_dfs(raw_data)
  saveRDS(res, "tests/testthat/res.RDS")
}


test_that("download_raw", {
  config <- list(
    host_url="https://healthviz.phila.gov/",
    path="t/PublicHealth/views/COVIDVaccineDashboard/COVID_Vaccine",
    req_url=":embed=y&:showVizHome=no&:host_url=https%3A%2F%2Fhealthviz.phila.gov%2F&:embed_code_version=3&:tabs=no&:toolbar=no&:alerts=no&:showShareOptions=false&:showAskData=false&:showAppBanner=false&:isGuestRedirectFromVizportal=y&:display_spinner=no&:loadOrderID=0"
  )

  req <- readRDS("req.RDS")
  body <- xml2::read_html(file("body.xml"))
  url <- readRDS("url.RDS")
  resp <- readRDS("httr_post_resp.RDS")
  expected_res <- readRDS("raw_output.RDS")

  res <- mockr::with_mock(
    read_html=function(x){expect_equal(x, req); body},
    POST=function(x, ...){expect_equal(x, url); resp},
    res <- download_raw(config)
  )
  expect_equal(res, expected_res)
})


test_that("extract_all_dfs", {
  ## TODO: Explore snapshot testing

  raw_data <- readRDS("raw_output.RDS")
  expected_res <- readRDS("res.RDS")

  expect_equal(extract_all_dfs(raw_data), expected_res)

})

test_that("scrape_tableau integration", {
  config <- list(
    host_url="https://healthviz.phila.gov/",
    path="t/PublicHealth/views/COVIDVaccineDashboard/COVID_Vaccine",
    req_url=":embed=y&:showVizHome=no&:host_url=https%3A%2F%2Fhealthviz.phila.gov%2F&:embed_code_version=3&:tabs=no&:toolbar=no&:alerts=no&:showShareOptions=false&:showAskData=false&:showAppBanner=false&:isGuestRedirectFromVizportal=y&:display_spinner=no&:loadOrderID=0"
  )

  expected_res <- readRDS("res.RDS")
  body <- xml2::read_html(file("body.xml"))
  resp <- readRDS("httr_post_resp.RDS")

  expect_equal(
    expected_res,
    mockr::with_mock(
      read_html=function(x){body},
      POST=function(x, ...){resp},
      scrape_tableau(config)
    )
  )
})
