library(dplyr)

# req <- "https://healthviz.phila.gov/t/PublicHealth/views/COVIDVaccineDashboard/COVID_Vaccine?:embed=y&:showVizHome=no&:host_url=https%3A%2F%2Fhealthviz.phila.gov%2F&:embed_code_version=3&:tabs=no&:toolbar=no&:alerts=no&:showShareOptions=false&:showAskData=false&:showAppBanner=false&:isGuestRedirectFromVizportal=y&:display_spinner=no&:loadOrderID=0"

# for Mocking
read_html <- function(...) xml2::read_html(...)
POST <- function(...) httr::POST(...)

download_data <- function(config){
  session_json <- fetch_session_info(config)
  data <- fetch_data_json(config$host_url, session_json)
  return(data)
}

fetch_session_info <- function(config){
  req <- sprintf("%s/%s?%s", config$host_url, config$path, config$req_url)
  body <- read_html(req)

  data <- body %>%
    rvest::html_nodes("textarea#tsConfigContainer") %>%
    rvest::html_text()

  return(rjson::fromJSON(data))
}

fetch_data_json <- function(host_url, session_json){
  url <- httr::modify_url(
    host_url,
    path=paste0(
      session_json$vizql_root,
      "/bootstrapSession/sessions/",
      session_json$sessionid
    )
  )

  resp <- POST(
    url,
    body = list(sheet_id = session_json$sheetId),
    encode = "form"
  )
  raw_download <- httr::content(resp, "text")
  extract <- stringr::str_match(
    raw_download,
    "\\d+;(\\{.*\\})\\d+;(\\{.*\\})"
  )
  data_json <- extract[1,3]
  return(rjson::fromJSON(data_json))
}

get_worksheets <- function(data){
  data$secondaryInfo$presModelMap$vizData$presModelHolder$genPresModelMapPresModel$presModelMap
}

extract_all_dfs <- function(data){
  worksheets = names(get_worksheets(data))

  res <- list()
  for(w in worksheets){
    res[[w]] <- get_df_for_worksheet(w, data)
  }

  return(res)
}

get_df_for_worksheet <- function(w, data){
  columnsData <- get_worksheets(data)[[w]]$presModelHolder$genVizDataPresModel$paneColumnsData

  dataFull = data$secondaryInfo$presModelMap$dataDictionary$presModelHolder$genDataDictionaryPresModel$dataSegments[["0"]]$dataColumns
  data_types <- sapply(dataFull, function(x) x$dataType)
  if(any(duplicated(data_types))) stop("Invalid duplicated dataType")
  names(dataFull) <- data_types

  valid_columns <- sapply(
    columnsData$vizDataColumns,
    function(x) !is.null(x[["fieldCaption"]])
  )

  extract_all_frames <- function(col){
    paneIndex <- col$paneIndices
    columnIndex <- col$columnIndices
    if (length(paneIndex) > 1){
      paneIndex <- paneIndex[1]
    }
    if (length(columnIndex) > 1){
      columnIndex <- columnIndex[1]
    }

    paneColumn <- columnsData$paneColumnsList[[paneIndex + 1]]$vizPaneColumns[[columnIndex + 1]]

    res <- list()
    get_frame_name <- function(type) paste(col$fieldCaption, type, sep="-")

    if (length(paneColumn$valueIndices) > 0) {
      frame_name <- get_frame_name("value")
      res[[frame_name]] <- extract_frame(paneColumn$valueIndices, col$dataType)
    }
    if (length(paneColumn$aliasIndices) > 0) {
      frame_name <- get_frame_name("alias")
      res[[frame_name]] <- extract_frame(paneColumn$aliasIndices, col$dataType)
    }
    return(res)
  }

  extract_frame <- function(indices, data_type){
    if(all(indices >= 0)){
      vector <- as.character(dataFull[[data_type]]$dataValues[indices + 1])
    } else if(all(indices < 0)){
      vector <- as.character(dataFull[["cstring"]]$dataValues[abs(indices)])
    } else {
      stop("Assumed indices were all positive or all negative. This wasn't true.")
    }
    return(vector)
  }

  frameData <- lapply(
    columnsData$vizDataColumns[valid_columns],
    extract_all_frames
  )
  frameData <- do.call(c, frameData)
  frameData <- extend_frames(frameData)

  df <- as.data.frame(frameData, stringsAsFactors=FALSE)
  return(df)
}

extend_frames <- function(frameData){
  max_len <- max(sapply(frameData, length))
  extend_frame <- function(frame){
    if(length(frame) < max_len){
      frame[(length(frame)+1):max_len] <- ""
    }
    return(frame)
  }

  lapply(frameData, extend_frame)
}

scrape_tableau <- function(config){
  data <- download_data(config)
  dfs <- extract_all_dfs(data)
  return(dfs)
}
