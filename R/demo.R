
if(FALSE){
  library(tableascrape)
  config <- gen_config(
    "https://www.phila.gov/programs/coronavirus-disease-2019-covid-19/vaccines/data/"
  )
  dfs <- scrape_tableau(config)
}
