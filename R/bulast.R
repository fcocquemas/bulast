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
#' @return Returns a list with names status (character), responseTime (integer), message
#'   (list of character), Results (data.table). Results has a date field that marks the
#'   end of the month.
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
  
  # Check that we actually have data
  if(length(r$Results) > 0) {
    # Put results into data.table format
    dt <- data.table::rbindlist(lapply(r$Results$series, function(s) {
      dt <- data.table::rbindlist(lapply(s$data, function(d) {
        d[["footnotes"]] <- paste(unlist(d[["footnotes"]]), collapse = " ")
        if ("calculations" %in% names(d)) {
          d[["pct_ch_1"]] <- as.numeric(d[["calculations"]]$pct_changes$`1`)
          d[["pct_ch_3"]] <- as.numeric(d[["calculations"]]$pct_changes$`3`)
          d[["pct_ch_6"]] <- as.numeric(d[["calculations"]]$pct_changes$`6`)
          d[["pct_ch_12"]] <- as.numeric(d[["calculations"]]$pct_changes$`12`)
          d[["calculations"]] <- NULL
        }
        d <- lapply(lapply(d, unlist), paste, collapse=" ")
        
        d
      }), use.names = TRUE, fill=TRUE)
      
      if(nrow(dt) > 0) {
        dt[, seriesID := s[["seriesID"]]]
      }
      dt
    }), use.names = TRUE, fill=TRUE)

    if(nrow(dt) > 0) {

      # Make value a numeric
      dt[, value := as.numeric(value)]
      
      # Add a date field
      dt[, date := seq(as.Date(paste(year, ifelse(period == "M13", 12, substr(period, 2, 3)), "01", sep = "-")),
                       length = 2, by = "months")[2]-1,
         by="year,period"]
      
      # Remove year and period fields
      dt[, `:=`(year = NULL, period = NULL)]
      
      # Remove periodName but add periodType (monthly or annual)
      dt[, `:=`(periodType = factor(ifelse(periodName == "Annual", "Annual", "Monthly")), periodName = NULL)]
      
      # Reorder columns
      setcolorder(dt, c("seriesID", "date", "value", "periodType",
                        colnames(dt)[!colnames(dt) %in% 
                                       c("seriesID", "date", "value", "periodType")]))
      
      # Key by series, data
      setkey(dt, "seriesID", "date")
      
      # Replace Results with data.table
      r$Results <- dt

    }
  }
  
  
  r
}

