#' Request data from the Bureau of Labor Statistics API
#' 
#' @export
#' 
#' @param seriesid character vector of series identifiers
#' @param startyear integer start year for the data
#' @param endyear integer end year for the data (maximum of 20 years returned) 
#' @param registrationKey BLS API registration key, required for V2 API. Freely
#'   available from here: http://data.bls.gov/registrationEngine/
#' @param catalog boolean include catalog data (currently not returned); requires
#'   registrationKey
#' @param calculations boolean include calculations data; requires registrationKey
#' @param annualaverage boolean include annual average ("M13") data; requires
#'   registrationKey
#'   
#' @return list with names status (character), responseTime (integer), message
#'   (list of character), Results (data.frame, or data.table if available)
#' 
#' @examples
#' r <- bulast(c('LAUCN040010000000005', 'LAUCN040010000000006'))
#' r$Results
#' 

bulast <- function(seriesid, startyear = NULL, endyear = NULL, registrationKey = NULL,
                   catalog = FALSE, calculations = FALSE, annualaverage = FALSE) {
    
  # Build payload
  payload <- list(seriesid = seriesid)
  
  if (exists("startyear") & !is.null(startyear)) {
    payload["startyear"] <- as.character(startyear)
  }
  
  if (exists("endyear") & !is.null(endyear)) {
    payload["endyear"] <- as.character(endyear)
  }  
  
  if (exists("registrationKey") & !is.null(registrationKey)) {
    if (exists("catalog") & !is.null(catalog)) {
      payload["catalog"] <- tolower(as.character(catalog))
    }
    
    if (exists("calculations") & !is.null(calculations)) {
      payload["calculations"] <- tolower(as.character(calculations))
    }
    
    if (exists("annualaverage") & !is.null(annualaverage)) {
      payload["annualaverage"] <- tolower(as.character(annualaverage))
    }
    
    payload["registrationKey"] <- as.character(registrationKey)
    
    url <- "http://api.bls.gov/publicAPI/v2/timeseries/data/"
  } else {
    url <- "http://api.bls.gov/publicAPI/v1/timeseries/data/"
  }
  
  # Get content
  r <- httr::content(httr::POST(url, body = rjson::toJSON(payload), httr::content_type_json()))
  
  # Unlist results and make a nice data.frame
  r$Results <- do.call("rbind", lapply(r$Results$series, function(s) {
    df <- do.call("rbind", lapply(s$data, function(d) {
      df <- data.frame(year = as.integer(d[["year"]]), 
                       period = d[["period"]], periodName = d[["periodName"]],
                       value = as.numeric(d[["value"]]), 
                       footnotes = paste(unlist(d[["footnotes"]]), collapse = " "), 
                       stringsAsFactors = FALSE)
      if ("calculations" %in% names(d)) {
        df$pct_ch_1 <- as.numeric(d[["calculations"]]$pct_changes$`1`)
        df$pct_ch_3 <- as.numeric(d[["calculations"]]$pct_changes$`3`)
        df$pct_ch_6 <- as.numeric(d[["calculations"]]$pct_changes$`6`)
        df$pct_ch_12 <- as.numeric(d[["calculations"]]$pct_changes$`12`)
      }
      # TODO: add date field if lubridate is present
      #             if (requireNamespace("lubridate", quietly = TRUE)) {
      #                 df$date <- sapply(df, 1, function(x) {
      #                   browser()
      #                   if (x["period"] != "M13") {
      #                     lubridate::"%m+%"(lubridate::ymd(paste(x["year"], substr(x["period"], 2, 3), "01", sep = "-")), 
      #                       months(1)) - lubridate::days(1)
      #                   } else {
      #                     NA }})
      #             }
      
      df
    }))
    df$seriesID <- s[["seriesID"]]
    df
  }))
  
  # Make a data.table if package is available
  if (requireNamespace("data.table", quietly = TRUE)) {
    r[["Results"]] <- data.table::as.data.table(r[["Results"]])
  }
  
  r
} 
