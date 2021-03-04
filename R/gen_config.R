# site <- "https://www.phila.gov/programs/coronavirus-disease-2019-covid-19/vaccines/data/"

requireNamespace("dplyr")

## For Mocking
read_html <- function(...) xml2::read_html(...)

#' Generate a config from a site with a Tableau Dashboard.
#'
#' @param site The url of a site that has an embedded dashboard.
#'
#' @return A list of parameters to be used by `scrape_tableau()`.
#' If the site has more than one dashboard, only the first is returned, with a warning.
#' @examples
#' \dontrun{
#' config <- gen_config(
#'   "https://www.phila.gov/programs/coronavirus-disease-2019-covid-19/vaccines/data/"
#' )
#' dfs <- scrape_tableau(config)
#' }
#'
#' @export
gen_config <- function(site, which=1){
  html <- read_html(site)
  obj_nodes <- xml2::xml_find_all(html, ".//object")
  tableau_nodes <- obj_nodes[xml2::xml_attr(obj_nodes, "class")=="tableauViz"]

  if(length(tableau_nodes) > 1 && which==1) warning("More than one Tableau found. Using first.")
  tableau_node <- tableau_nodes[which]

  attrs <- mapply(
    tableau_node %>% xml2::xml_children(),
    FUN=function(node){
      val <- xml2::xml_attr(node, "value")
      names(val) <- xml2::xml_attr(node, "name")
      val
    }
  ) %>% as.list()

  path <- paste0(attrs$site_root, "/views/", attrs$name)

  attrs <- attrs[!names(attrs) %in% c("site_root", "name")]
  attrs$embed <- "y"
  attrs$showVizHome <- "no"
  attrs$loadOrderID <- 0
  attrs$display_spinner <- 'no'

  req <- paste0(
    ':', names(attrs), "=", attrs,
    collapse="&"
  )

  list(
    host_url=URLdecode(attrs$host_url),
    path=path,
    req_url=req
  )
}

if(FALSE){
  config <- gen_config(
    "https://www.phila.gov/programs/coronavirus-disease-2019-covid-19/vaccines/data/"
  )
}
