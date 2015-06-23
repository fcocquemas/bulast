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
#'   (list of character), Results (data.table)
#' 
#' @examples
#' r <- bulast(c('LAUCN040010000000005', 'LAUCN040010000000006'))
#' r$Results
#' 

bulast <- function (seriesid, startyear = NULL, endyear = NULL, registrationKey = NULL, 
                    catalog = NULL, calculations = NULL, annualaverage = NULL) 
{
  # Build payload with non-NULL arguments only
  payload <- Filter(is.character, sapply(c("startyear", "endyear", "registrationKey", 
                      "catalog", "calculations", "annualaverage"), function(x) {
                        if(exists(x) & eval(parse(text=paste0("!is.null(", x, ")")))) {
                          tolower(as.character(eval(parse(text=x))))
                        }
                      }))
  payload[["seriesid"]] <- seriesid
  
  # Pick V2 url if registrationKey is present, V1 otherwise
  url <- ifelse("registrationKey" %in% names(payload),
    "http://api.bls.gov/publicAPI/v2/timeseries/data/",
    "http://api.bls.gov/publicAPI/v1/timeseries/data/")
  
  # Perform request
  r <- httr::content(httr::POST(url, body = rjson::toJSON(payload), 
                                httr::content_type_json()))
  
  # Put results into data.table format
  r$Results <- do.call("rbind", lapply(r$Results$series, function(s) {
    df <- do.call("rbind", lapply(s$data, function(d) {
      df <- data.table(year = as.integer(d[["year"]]), 
                       period = d[["period"]], periodName = d[["periodName"]], 
                       value = as.numeric(d[["value"]]), 
                       footnotes = paste(unlist(d[["footnotes"]]), collapse = " "))
      
      if ("calculations" %in% names(d)) {
        df$pct_ch_1 <- as.numeric(d[["calculations"]]$pct_changes$`1`)
        df$pct_ch_3 <- as.numeric(d[["calculations"]]$pct_changes$`3`)
        df$pct_ch_6 <- as.numeric(d[["calculations"]]$pct_changes$`6`)
        df$pct_ch_12 <- as.numeric(d[["calculations"]]$pct_changes$`12`)
      }

      df
    }), fill=TRUE)
    df$seriesID <- s[["seriesID"]]
    df
  }), fill=TRUE)
  
  # Add a date field
  r$Results[, date := 
    as.Date(paste(year, ifelse(period == "M13", 12, substr(period, 2, 3)), "01", sep = "-")) + months(1) - days(1),
    by="year,period"]
  
  # Remove year and period fields
  r$Results[, `:=`(year = NULL, period = NULL)]

  # Key by series, data
  setkey(r$Results, "seriesID", "date")
  
  r
}
