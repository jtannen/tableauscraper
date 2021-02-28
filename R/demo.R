
if(FALSE){
  CONFIG <- list(
    host_url="https://healthviz.phila.gov/",
    path="t/PublicHealth/views/COVIDVaccineDashboard/COVID_Vaccine",
    req_url=":embed=y&:showVizHome=no&:host_url=https%3A%2F%2Fhealthviz.phila.gov%2F&:embed_code_version=3&:tabs=no&:toolbar=no&:alerts=no&:showShareOptions=false&:showAskData=false&:showAppBanner=false&:isGuestRedirectFromVizportal=y&:display_spinner=no&:loadOrderID=0"
  )

  dfs <- scrape_tableau(CONFIG)
}
