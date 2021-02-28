
# tableauscraper

<!-- badges: start -->
<!-- badges: end -->

The goal of tableauscraper is to fetch the data behind a Tableau Dashboard.

## Installation

You can install the released version of tableauscraper from github with:

``` r
devtools::install_github("https://github.com/jtannen/tableauscraper")
```

## Example

`tableauscraper` provides functions to (1) create a config from a website with Tableau Dashboard, 
and then (2) download and extract the data:

``` r
library(tableascraper)

## optionally, save this config.
config <- gen_config(
  "https://www.phila.gov/programs/coronavirus-disease-2019-covid-19/vaccines/data/"
)

dfs <- scrape_tableau(config)
```

> NOTE: I haven't tested this on many dashboards, so have no idea if some dashboards have different setups. I make no guarantees.

Adapted from the amazing code at  
https://stackoverflow.com/questions/64094560/how-do-i-scrape-tableau-data-from-website-into-r

