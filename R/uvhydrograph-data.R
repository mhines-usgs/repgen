#' Get months
#' @description For a report, return a list of all months with data (sorted) in format 'YYMM'.
#' @param reportObject a UV Hydrograph report
#' @param timezone the timezone to parse read time series into
#' @return list of months, sorted, as 'YYMM'
#'@importFrom lubridate parse_date_time
getMonths <- function(reportObject, timezone){
  corr <- readTimeSeries(reportObject, "primarySeries", timezone)[['points']]
  uncorr <- readTimeSeries(reportObject, "primarySeriesRaw", timezone)[['points']]
  months <- unique(c(corr[['month']], uncorr[['month']]))
  return(sort(months))
}

#' Parse Corrections
#' @description Read corrections for a given series
#' @param reportObject entire UV Hydro report object
#' @param month subset only into this month
#' @param fieldName the field name of the corrections to pull from report
#' @return corrections subset by month
#' @importFrom stats na.omit
parseCorrectionsByMonth <- function(reportObject, fieldName, month) {
  corrections <- tryCatch({
       subsetByMonth(readCorrections(reportObject, fieldName), month)
     }, error = function(e) {
       stats::na.omit(data.frame(time=as.POSIXct(NA), value=NA, month=as.character(NA), comment=as.character(NA), stringsAsFactors=FALSE))
     })
  return(corrections)
}

#' Parse Rating Shifts
#' @description Read rating shifts for a given series
#' @param reportObject entire UV Hydro report object
#' @param month subset only into this month
#' @return rating shifts subset by month
#' @importFrom stats na.omit
parseRatingShiftsByMonth <- function(reportObject, month) {
  ratingShifts <- tryCatch({
    subsetByMonth(readRatingShiftsUvHydro(reportObject), month)
  }, error = function(e) {
    stats::na.omit(data.frame(time=as.POSIXct(NA), value=NA, month=as.character(NA), comment=as.character(NA), stringsAsFactors=FALSE))
  })
  return(ratingShifts)
}

#' Parse Secondary Corrections
#' @description depending on the report configuration, corrections might come from a reference or upchain series
#' @param reportObject the report to render
#' @param month filter data to this month
#' @return corrections list from the correct series
parseSecondaryCorrectionsByMonth <- function(reportObject, month) {
  hasReferenceSeries <- hasReferenceSeries(reportObject)
  hasUpchainSeries <- hasUpchainSeries(reportObject)
  
  if(hasReferenceSeries) {
    corrections <- parseCorrectionsByMonth(reportObject, "referenceSeriesCorrections", month)
  } else {
    corrections <- parseCorrectionsByMonth(reportObject, "upchainSeriesCorrections", month)
  }
  return(corrections)
}

#' Parse UV Comparison Series
#' @description Read entire comparison series
#' @param reportObject entire UV Hydro report object
#' @param month subset only into this month
#' @param timezone timezone to parse all data into
#' @return comparison series points subset by month
parseUvComparisonSeriesByMonth <- function(reportObject, month, timezone) {
  comparison <- tryCatch({
    readNonEstimatedTimeSeries(reportObject, "comparisonSeries", timezone, onlyMonth=month)
      }, error = function(e) {
        NULL
      })
  return(comparison)
}

#' Parse UV Estimated Comparison Series
#' @description Read entire comparison series
#' @param reportObject entire UV Hydro report object
#' @param month subset only into this month
#' @param timezone timezone to parse all data into
#' @return comparison series points subset by month
parseUvEstimatedComparisonSeriesByMonth <- function(reportObject, month, timezone) {
  estimated_comparison <- tryCatch({
    readEstimatedTimeSeries(reportObject, "comparisonSeries", timezone, onlyMonth=month)
  }, error = function(e) {
    NULL
  })
  return(estimated_comparison)
}

#' Parse UV Non-Estimated Series
#' @description Read non-estimated portion of a series
#' @param reportObject entire UV Hydro report object
#' @param seriesName series to read
#' @param month subset only into this month
#' @param timezone timezone to parse all data into
#' @return series points subset by month
parseUvNonEstimatedSeries <- function(reportObject, seriesName, month, timezone) {
  series <- tryCatch({
        readNonEstimatedTimeSeries(reportObject, seriesName, timezone, onlyMonth=month)
      }, error = function(e) {
        NULL
      })
  return(series)
}

#' Parse UV Estimated Series
#' @description Read estimated portion of a series
#' @param reportObject entire UV Hydro report object
#' @param seriesName series to read
#' @param month subset only into this month
#' @param timezone timezone to parse all data into
#' @return series points subste by month
parseUvEstimatedSeries <- function(reportObject, seriesName, month, timezone) {
  series <- tryCatch({
        readEstimatedTimeSeries(reportObject, seriesName, timezone, onlyMonth=month)
      }, error = function(e) {
        NULL
      })
  return(series)
}

#' Parse Primary Series List
#' @description Read all series including reference or comparison series
#' @param reportObject entire UV Hydro report object
#' @param month subset only into this month
#' @param timezone timezone to parse all data into
#' @return named list of timeseries objects (NULL if not in report object) as well as inverted, useEstimated and loggedAxis flags. useEstimated is set so that y-limits and labels use the estimated point data.  loggedAxis is set so that all series are supported on the same axis.
parsePrimarySeriesList <- function(reportObject, month, timezone) {
  correctedSeries <- readNonEstimatedTimeSeries(reportObject, "primarySeries", timezone, onlyMonth=month)
  estimatedSeries <- readEstimatedTimeSeries(reportObject, "primarySeries", timezone, onlyMonth=month)
  uncorrectedSeries <- readTimeSeries(reportObject, "primarySeriesRaw", timezone, onlyMonth=month)
  
  inverted <- isTimeSeriesInverted(correctedSeries)
  excludeZeroNegatives <- fetchReportMetadataField(reportObject, 'excludeZeroNegative')
  
  useEstimated <- (isEmptyOrBlank(correctedSeries) || isEmptyVar(correctedSeries[['points']])) && (!isEmptyOrBlank(estimatedSeries) && !isEmptyVar(estimatedSeries[['points']]))
  
  loggedAxis <- isLogged(correctedSeries[['points']], correctedSeries[["isVolumetricFlow"]], excludeZeroNegatives)
  
  #Add reference data to the plot if it is available and this is a Q plot type
  corrected_reference <- NULL
  estimated_reference <- NULL
  if(isPrimaryDischarge(reportObject))
  {
    #Reference Time Series Data
    corrected_reference <- parseUvNonEstimatedSeries(reportObject, "referenceSeries", month, timezone)
    if(!isEmptyOrBlank(corrected_reference)) {
      loggedAxis <- loggedAxis && isLogged(corrected_reference[['points']], corrected_reference[["isVolumetricFlow"]], excludeZeroNegatives)
    }
    
    estimated_reference <- parseUvEstimatedSeries(reportObject, "referenceSeries", month, timezone)
    if(!isEmptyOrBlank(estimated_reference)) {
      loggedAxis <- loggedAxis && isLogged(estimated_reference[['points']], estimated_reference[["isVolumetricFlow"]], excludeZeroNegatives)
    }
  }
  
  comparison <- parseUvComparisonSeriesByMonth(reportObject, month, timezone)
  if(!isEmptyOrBlank(comparison)) {
    loggedAxis <- loggedAxis && isLogged(comparison[['points']], comparison[["isVolumetricFlow"]], excludeZeroNegatives)
  }
  
  estimated_comparison <- parseUvEstimatedComparisonSeriesByMonth(reportObject, month, timezone)
  if(!isEmptyOrBlank(estimated_comparison)) {
    loggedAxis <- loggedAxis && isLogged(estimated_comparison[['points']], estimated_comparison[["isVolumetricFlow"]], excludeZeroNegatives)
  }
  
  return(list(
          corrected=correctedSeries, 
          estimated=estimatedSeries, 
          uncorrected=uncorrectedSeries, 
          corrected_reference=corrected_reference,
          estimated_reference=estimated_reference,
          comparison=comparison,
          estimated_comparison=estimated_comparison,
          inverted=inverted,
          loggedAxis=loggedAxis,
          useEstimated=useEstimated))
}

#' Parse Secondary Series List
#' @description Depending on conditions, might be ref series or upchain series
#' @param reportObject entire UV Hydro report object
#' @param month subset only into this month
#' @param timezone timezone to parse all data into
#' @return named list of series to be included on secondary plot
parseSecondarySeriesList <- function(reportObject, month, timezone) {
  if(hasReferenceSeries(reportObject) && !isPrimaryDischarge(reportObject)) {
    #Reference Time Series Data
    correctedSeries <- readNonEstimatedTimeSeries(reportObject, "referenceSeries", timezone, onlyMonth=month)
    estimatedSeries <- readEstimatedTimeSeries(reportObject, "referenceSeries", timezone, onlyMonth=month)
    uncorrectedSeries <- NULL
  } else {
    #Upchain Time Series Data
    correctedSeries <- readNonEstimatedTimeSeries(reportObject, "upchainSeries", timezone, onlyMonth=month)
    estimatedSeries <- readEstimatedTimeSeries(reportObject, "upchainSeries", timezone, onlyMonth=month)
    uncorrectedSeries <- readTimeSeries(reportObject, "upchainSeriesRaw", timezone, onlyMonth=month)
  }
  
  useEstimated <- (isEmptyOrBlank(correctedSeries) || isEmptyVar(correctedSeries[['points']])) && (!isEmptyOrBlank(estimatedSeries) && !isEmptyVar(estimatedSeries[['points']]))
  
  inverted = isTimeSeriesInverted(correctedSeries)
  
  return(list(corrected=correctedSeries, estimated=estimatedSeries, uncorrected=uncorrectedSeries, inverted=inverted, useEstimated=useEstimated))
}

#' Parse primary dv lists
#' @description Read daily values subsetted by month and named by approval level for UV Hydrograph
#' @param reportObject entire UV Hydro report object
#' @param month subset only into this month
#' @param timezone timezone to parse all data into
#' @return subset list of DV points. Each point is named with or "approved_dv", "analyzed_dv", "working_dv"
parsePrimaryDvList <- function(reportObject, month, timezone) {
  paramPrefixes <- c("approved_dv", "analyzed_dv", "working_dv")
  all <- list()
  
  if(!isEmptyOrBlank(reportObject[["firstStatDerived"]])) {
    first_stat <- readApprovalPoints(
        fetchApprovalsForSeries(reportObject, "firstStatDerived"), 
        readTimeSeries(reportObject, "firstStatDerived", timezone, shiftTimeToNoon=TRUE, onlyMonth=month)[['points']], 
          timezone, legend_nm=paste("Stat 1:", fetchReportMetadataField(reportObject, "firstStatDerivedLabel")),
          appr_var_all=paramPrefixes, point_type=21)
  } else {
    first_stat <- list()
  }
  
  if(!isEmptyOrBlank(reportObject[["secondStatDerived"]])) {
    second_stat <- readApprovalPoints(
        fetchApprovalsForSeries(reportObject, "secondStatDerived"), 
        readTimeSeries(reportObject, "secondStatDerived", timezone, shiftTimeToNoon=TRUE, onlyMonth=month)[['points']], 
          timezone, legend_nm=paste("Stat 2:", fetchReportMetadataField(reportObject, "secondStatDerivedLabel")),
          appr_var_all=paramPrefixes, point_type=24)
  } else {
    second_stat <- list()
  }
  
  if(!isEmptyOrBlank(reportObject[["thirdStatDerived"]])) {
    third_stat <- readApprovalPoints(
        fetchApprovalsForSeries(reportObject, "thirdStatDerived"), 
        readTimeSeries(reportObject, "thirdStatDerived", timezone, shiftTimeToNoon=TRUE, onlyMonth=month)[['points']], 
          timezone, legend_nm=paste("Stat 3:", fetchReportMetadataField(reportObject, "thirdStatDerivedLabel")),
          appr_var_all=paramPrefixes, point_type=25)
  } else {
    third_stat <- list()
  }
  
  if(!isEmptyOrBlank(reportObject[["fourthStatDerived"]])) {
    fourth_stat <- readApprovalPoints(
        fetchApprovalsForSeries(reportObject, "fourthStatDerived"), 
        readTimeSeries(reportObject, "fourthStatDerived", timezone, shiftTimeToNoon=TRUE, onlyMonth=month)[['points']], 
          timezone, legend_nm=paste("Stat 4:", fetchReportMetadataField(reportObject, "fourthStatDerivedLabel")),
          appr_var_all=paramPrefixes, point_type=22)
  } else {
    fourth_stat <- list()
  }
  
  statList <- list(first_stat, second_stat, third_stat, fourth_stat)
  for(approvalLevel in paramPrefixes) {
    for(stat in statList) {
      if(!isEmptyOrBlank(stat[[approvalLevel]]) && nrow(stat[[approvalLevel]]) > 0) {
        if(isEmptyOrBlank(all[[approvalLevel]])) {
          all[[approvalLevel]] <- stat[[approvalLevel]]
        } else {
          all[[approvalLevel]] <- rbind(all[[approvalLevel]], stat[[approvalLevel]])
        }
      }
    }
  }
  
  return(all)
}

#' Read Primary Uv Hydro Approval Bars
#' @description will read the relevant approval bar from primary series
#' @param reportObject entire UV Hydro report object
#' @param timezone timezone to parse all data into
#' @param month filter data to this month
#' @return approval bar plotting info for primary series
readPrimaryUvHydroApprovalBars <- function(reportObject, timezone, month) {
  approvals <- readApprovalBar(readTimeSeries(reportObject, "primarySeries", timezone, onlyMonth=month), timezone, 
      legend_nm=paste("UV", getTimeSeriesLabel(reportObject, "primarySeries")))
  return(approvals)
}

#' Read Secondary Uv Hydro Approval Bars
#' @description will read the relevant approval bar to display depending on report configuration
#' @param reportObject entire UV Hydro report object
#' @param timezone timezone to parse all data into
#' @return approval bar plotting info from either reference or upchain series
readSecondaryUvHydroApprovalBars <- function(reportObject, timezone) {
  if(hasReferenceSeries(reportObject) && !isPrimaryDischarge(reportObject)) {
    #Reference Time Series Data
    approvals <- readApprovalBar(readTimeSeries(reportObject, "referenceSeries", timezone), timezone, 
        legend_nm=getTimeSeriesLabel(reportObject, "referenceSeries"))
  } else if(hasUpchainSeries(reportObject)) {
    #Upchain Time Series Data
    approvals <- readApprovalBar(readTimeSeries(reportObject, "upchainSeries", timezone), timezone, 
        legend_nm=getTimeSeriesLabel(reportObject, "upchainSeries"))
  } else {
    approvals <- list()
  }
  return(approvals)
}

#' Read Readings
#' @description Read readings subsetted by month and separated by type for UV Hydrograph
#' @param reportObject entire UV Hydro report object
#' @param month subset only into this month
#' @param jsonFieldName report field to read readings from
#' @return named list of readings by type and subsetted by month
readAllUvReadings <- function(reportObject, month, jsonFieldName) {
  ref_readings <- subsetByMonth(readReadings(reportObject, jsonFieldName, "reference"), month)
  csg_readings <- subsetByMonth(readReadings(reportObject, jsonFieldName, "crestStage"), month)
  hwm_readings <- subsetByMonth(readReadings(reportObject, jsonFieldName, "waterMark"), month)
  
  return(list(reference=ref_readings, crest_stage_gage=csg_readings, high_water_mark=hwm_readings))
}

#' Read Water Quality Measurements
#' @description Read WQ measurements subsetted by month for UV Hydrograph
#' @param reportObject entire UV Hydro report object
#' @param month subset only into this month
#' @return subset of WQ data, default to empty frame if none found
#' @importFrom stats na.omit
readUvWq <- function(reportObject, month) {
  water_qual <- tryCatch({
        subsetByMonth(readWaterQualityMeasurements(reportObject), month)
      }, error = function(e) {
        stats::na.omit(data.frame(time=as.POSIXct(NA), value=as.numeric(NA), month=as.character(NA)))
      })
  return(water_qual)
}

#' Read Discharge Measurements
#' @description Read Q measurements subsetted by month for UV Hydrograph
#' @param reportObject entire UV Hydro report object
#' @param month subset only into this month
#' @return subset of Q data, default to empty frame if none found
#' @importFrom stats na.omit
readUvQMeasurements <- function(reportObject, month) {
  meas_Q <- tryCatch({
        subsetByMonth(readFieldVisitMeasurementsQPoints(reportObject), month) 
      }, error = function(e) {
        stats::na.omit(data.frame(time=as.POSIXct(NA), value=as.numeric(NA), minQ=as.numeric(NA), maxQ=as.numeric(NA), n=as.numeric(NA), month=as.character(NA), publish=as.character(NA), stringsAsFactors=FALSE))
      })
  return(meas_Q)
}

#' Read Ground Water level
#' @description Read gw level subsetted by month for UV Hydrograph
#' @param reportObject entire UV Hydro report object
#' @param timezone target timezone to parse data into
#' @param month subset only into this month
#' @return subset of gw level data, default to empty frame if none found
#' @importFrom stats na.omit
readEffectiveShifts <- function(reportObject, timezone, month) {
  effect_shift <- tryCatch({
      subsetByMonth(
        readTimeSeries(reportObject, "effectiveShifts", timezone,requiredFields=c("points"))[['points']], 
        month)
    }, error = function(e) {
      stats::na.omit(data.frame(time=as.POSIXct(NA), value=as.numeric(NA), month=as.character(NA)))
    })
  return(effect_shift)
}

#' Read Ground Water level
#' @description Read gw level subsetted by month for UV Hydrograph
#' @param reportObject entire UV Hydro report object
#' @param month subset only into this month
#' @return subset of gw level data, default to empty frame if none found
#' @importFrom stats na.omit
readUvGwLevel <- function(reportObject, month) {
  gw_level <- tryCatch({
        subsetByMonth(readGroundWaterLevels(reportObject), month)
      }, error = function(e) {
        stats::na.omit(data.frame(time=as.POSIXct(NA), value=as.numeric(NA), month=as.character(NA)))
      })
  return(gw_level)
}

#' Read Measured Shifts
#' @description Read measured shifts subsetted by month for UV Hydrograph
#' @param reportObject entire UV Hydro report object
#' @param month subset only into this month
#' @return subset of measured shifts data
#' @importFrom stats na.omit
readUvMeasurementShifts <- function(reportObject, month) {
  meas_shift <- tryCatch({
      subsetByMonth(readFieldVisitMeasurementsShifts(reportObject), month)
    }, error = function(e) {
      stats::na.omit(data.frame(time=as.POSIXct(NA), value=as.numeric(NA), minShift=as.numeric(NA), maxShift=as.numeric(NA), month=as.character(NA), stringsAsFactors=FALSE))
    })
  return(meas_shift)
}

#' Read Gage Height
#' @description Read gage height subsetted by month for UV Hydrograph
#' @param reportObject entire UV Hydro report object
#' @param month subset only into this month
#' @return subset of gage height data
readUvGageHeight <- function(reportObject, month) {
  gage_height <- subsetByMonth(readMeanGageHeights(reportObject), month)
  return(gage_height)
}

#' Is Primary Discharge
#' Determines if the primary series in the report is Discharge parameter
#' @param reportObject UV Hydro report object
#' @return true/false
isPrimaryDischarge <- function(reportObject) {
  return(any(grepl("Discharge", fetchReportMetadataField(reportObject,'primaryParameter'))))
}

#' Has Reference Series
#' Determines if the report has a reference series attached
#' @param reportObject UV Hydro report object
#' @return true/false
hasReferenceSeries <- function(reportObject) {
  return(any(grepl("referenceSeries", names(reportObject))))
}

#' Has Upchain Series
#' Determines if the report has a upchain series attached
#' @param reportObject UV Hydro report object
#' @return true/false
hasUpchainSeries <- function(reportObject) {
  return(any(grepl("upchainSeries", names(reportObject))))
}

#' Get UV time information from lims
#' Returns time information for the lims
#' @param lims the lims to describe
#' @param timezone the timezone to convert all data to
#' @return named list of metadata about the lims (dates, days, start, end)
#' @importFrom lubridate hours
#' @importFrom lubridate minutes
#' @importFrom lubridate ymd
parseUvTimeInformationFromLims <- function(lims, timezone) {
  sec_dates <- seq(lims[['xlim']][1], lims[['xlim']][2], by="days")
  days <- seq(days_in_month(sec_dates[1]))
  year <- year(sec_dates[1])
  month <- month(sec_dates[1])
  plotDates <- seq(as.POSIXct(lubridate::ymd(paste(year, month, days[1], sep="-"),tz=timezone)), length=tail(days,1), by="days")
  
  start <- plotDates[1]
  end <- tail(plotDates,1) + hours(23) + minutes(45)
  
  return(list(dates=plotDates, days=days, start=start, end=end))
}

#' Read Time Series UV Info
#' @description Returns metadata for a TS.
#' @param reportObject full UV Hydro object
#' @param seriesName name of ts field to get info from
#' @return named list of metadata (label, unit, type)
readTimeSeriesUvInfo <- function(reportObject, seriesName) {
  label <- getTimeSeriesLabel(reportObject, seriesName)
  unit <- reportObject[[seriesName]][['unit']]
  type <- reportObject[[seriesName]][['type']]
  return(list(label=label, unit=unit, type=type))
}

#' Read Secondary Time Series UV INFO
#' Decides where or not the report wants reference or upchain series as it's main secondary series and returns metadata for that.
#' @param reportObject full UV Hydro object
#' @return timeseries metadata see readTimeSeriesUvInfo
readSecondaryTimeSeriesUvInfo <- function(reportObject) {
  if(hasReferenceSeries(reportObject) && !isPrimaryDischarge(reportObject)) {
    infos <- readTimeSeriesUvInfo(reportObject, "referenceSeries")
  } else if(hasUpchainSeries(reportObject)) {
    infos <- readTimeSeriesUvInfo(reportObject, "upchainSeries")
  }
  return(infos)
}

#' Corrections as table
#' @description Given a list of corrections, will create a table structure with unique entries for all corrections that appear in the list.
#' @param corrections list of corrections
#' @return table structure with unique row entries for each correction type found
parseCorrectionsAsTable <- function(corrections) {
  if(!is.null(corrections) && nrow(corrections) > 0) {
    corrections_table <- as.data.frame(cbind(seq(nrow(corrections)), as.character(corrections[['time']]), corrections[['comment']]), stringsAsFactors=FALSE)
    colnames(corrections_table) <- c("", "Time", "Correction Comments")
    return(corrections_table)
  } else {
    return(corrections_table <- NULL)
  }
}

#' Rating Shifts as a table
#' @description Given a list of rating shifts, will create a table with unique entries for all rating shifts that appear in the list
#' @param ratingShifts list of ratingShifts
#' @return table structure with unique row entries for each rating shift found
parseRatingShiftsAsTable <- function(ratingShifts) {
  if(!is.null(ratingShifts) && nrow(ratingShifts) > 0) {
    ratingShifts_table <- as.data.frame(cbind(seq(nrow(ratingShifts)), as.character(ratingShifts[['time']]), ratingShifts[['comment']]), stringsAsFactors=FALSE)
    colnames(ratingShifts_table) <- c("", "Time", "Rating shift Comments")
    return(ratingShifts_table)
  } else {
    return(ratingShifts_table <- NULL)
  }
}


#' Add Group Col for Corrections
#' @description helper function to create table of information for placing corrections labels
#' @param data existing table data (for corrections)
#' @param newColumnName name of column to place new data derived
#' @param isNewCol function to determine if new column should be created for derived data
#' @param newGroupValue function for deriving new data from existing data
#' @param groupChildValue function to ??? TODO
#' @param vars variables to pass into newGroupValue and groupChildValue
#' @return mutated data table (with added columns/rows)
addGroupCol <- function(data, newColumnName, isNewCol, newGroupValue=NULL, groupChildValue=NULL, vars=NULL){
  build_vec <- c()
  prev <- NULL
  for(r in 1:nrow(data)){
    if(r == 1 || isNewCol(data, r, vars)){
      if(typeof(newGroupValue) != "closure"){
        newVal <- newGroupValue
      } else {
        newData <- newGroupValue(data, prev, r, build_vec, vars)
        newVal <- newData[['value']]
        vars <- c(vars, newData[['vars']])
      }
      
      build_vec <- c(build_vec, newVal)
      prev <- newVal
    } else {
      if(typeof(groupChildValue) != "closure"){
        childVal <- groupChildValue
      } else {
        childVal <- groupChildValue(data, build_vec, r, vars)
      }

      build_vec <- c(build_vec, childVal)
    }
  }
  
  data[newColumnName] <- build_vec
  
  return(data)
}

#' X Position of Group Value
#' @description helper function to figure out the x value (time) of where to place group value ???
#' @param data TODO 
#' @param prev TODO 
#' @param r TODO 
#' @param build_vec TODO 
#' @param vars TODO 
xposGroupValue <- function(data, prev, r, build_vec, vars) {
  colData <- data[which(data['colNum'] == data[r, 'colNum']),]
  # work around warnings from devtools::check()
  time <- ""
  label <- ""
  colData <- colData %>% arrange(desc(time), desc(label))
  shift <- head(colData,1)['time'] + vars[['secondOffset']] + data[r, 'boxWidth'] / 2 > vars[['limits']][['xlim']][[2]]

  if(shift){
    colData <- colData %>% arrange(time, desc(label))
  }

  value <- ifelse(shift, head(colData,1)['time'] - vars[['secondOffset']] - data[r, 'boxWidth'] / 2, head(colData,1)['time'] + vars[['secondOffset']] + data[r, 'boxWidth'] / 2)
  
  value <- unname(unlist(value))
  
  return(c(value=value, vars=list()))
}

#' Y position of Group Value
#' @description helper function to figure out the y value of where to place group value ???
#' @param data TODO 
#' @param prev TODO 
#' @param r TODO 
#' @param build_vec TODO 
#' @param vars TODO 
yposGroupValue <- function(data, prev, r, build_vec, vars) {
  if(data[r,'xpos'] > data[r,'time']){
    value <- vars[['limits']][['ylim']][[2]]
  } else {
    if(r > 1 && abs(data[r,'xpos'] - data[r-1, 'xpos']) < vars[['secondOffset']] + data[r,'boxWidth']){
      value <- build_vec[r-1] - vars[['subtractor']]
    } else {
      value <- vars[['limits']][['ylim']][[2]]
    }
  }

  return(c(value=value, vars=list()))
}

#' Parse vertical flag label spacing
#' @description each vertical flag is a time/comment pair. This will deterimine how to place labels so they do not overlap each other.
#' @param flags list of vertical flags (time/comment pairs)
#' @param limits the lims that the vertical flag labels should not leave
#' @return list of named items (x, xorigin, y, r, label) which desribes where/how to to place each label
#' @importFrom dplyr row_number
#' @importFrom dplyr desc
#' @importFrom dplyr select
parseVerticalFlagLabelSpacing <- function(flags, limits) {
  #Number of seconds to offset labels by for display
  secondOffset <- 4 * 60 * 60

  #Width of one digit in hours
  digitSeconds <- 4 * 60 * 60

  #Total width of both bounding box left and right margins 
  baseBoxSize <- 4 * 60 * 60

  #Minimum space between the right side of a label box and the next vertical flag line to not merge columns
  minSpacerSize <- 2 * 60 * 60

  #The percentage of the y-range to subtract each time we add a new label to a column
  subtractor <- (limits[['ylim']][[2]] - limits[['ylim']][[1]]) * 0.065

  # work around warnings from devtools::check()
  time <- ""
  label <- ""
  
  #Save original order as label and re-order by time and then by label (descending)
  vertFlags <- flags %>% dplyr::select(time) %>% mutate(label = row_number()) %>% arrange(time, desc(label))
  
  #Calculate the largest width label for the current time
  vertFlags <- addGroupCol(vertFlags, 'boxWidth',  isNewCol = function(data, r, vars){data[r-1, 'time'] != data[r, 'time']}, 
                                           newGroupValue=function(data, prev, r, build_vec, vars){c(value=vars[['baseBoxSize']] + vars[['digitSeconds']] * nchar(as.character(data[r, 'label'])), vars=list())},
                                           vars = list(baseBoxSize=baseBoxSize,digitSeconds=digitSeconds),
                                           groupChildValue=function(data,build_vec,r,vars){build_vec[r-1]})

  #Calculate the column number of each row by looking for column breaks
  vertFlags <- addGroupCol(vertFlags, 'colNum', isNewCol = function(data, r, vars){difftime(data[r, 'time'], data[r-1, 'time'], units="secs") >= vars[['secondOffset']] + data[r-1, 'boxWidth'] + vars[['minSpacerSize']]}, 
                                        newGroupValue = function(data, prev, r, build_vec, vars){c(value=ifelse(isEmptyOrBlank(prev), 1, prev + 1), vars=list())},
                                        vars = list(secondOffset=secondOffset, minSpacerSize=minSpacerSize),
                                        groupChildValue=function(data,build_vec,r,vars){build_vec[r-1]})
      
  #Calculate the x-position of new columns
  vertFlags <- addGroupCol(vertFlags, 'xpos', isNewCol = function(data, r, vars){data[r-1, 'colNum'] != data[r, 'colNum']}, 
                                      newGroupValue=xposGroupValue,
                                      vars=list(secondOffset=secondOffset, limits=limits),
                                      groupChildValue=function(data,build_vec,r,vars){build_vec[r-1]})

  #Calculate the y-position of each label in each column
  vertFlags <- addGroupCol(vertFlags, 'ypos', isNewCol = function(data, r, vars){data[r-1, 'colNum'] != data[r, 'colNum']}, 
                                      newGroupValue=yposGroupValue,
                                      groupChildValue=function(data,build_vec,r,vars){build_vec[r-1] - vars[['subtractor']]},
                                      vars=list(subtractor=subtractor, limits=limits, secondOffset=secondOffset))

  ##The scaling factor for the bounding shape of this label in inches. Scaling factor is fairly arbitrary but is relative the cex value used for the text for these labels in the styles and the colWidth
  vertFlags <- vertFlags %>% mutate(r = 1+0.525*nchar(as.character(label)))
    
  spacingInfo <- list(x=vertFlags[['xpos']], xorigin=vertFlags[['time']], y=vertFlags[['ypos']], r=vertFlags[['r']], label=vertFlags[['label']])
  
  return(spacingInfo)
}

#' Get Vertical Flag Arrows
#' For a set of vertical flag labels, will return a list of arrows to connect label to vertical line.
#' @param flagLabels list of labels with positioning information already calculated/attached
#' @return list of data describing how to draw lines to corresponding labels
#' @importFrom dplyr select
getVerticalFlagArrows <- function(flagLabels) {
  flagArrows <- list()
  
  #Make the vertical flag label lines connect to the outside of the bounding box and not to the center of the label
  if(!isEmptyOrBlank(flagLabels)){
    lengthAdjustments <- 60 * 60 * 2.85 * flagLabels[['r']]
    
    x <- NULL
    xorigin <- NULL
    y <- NULL
    
    flagArrows <- flagLabels %>% as.data.frame() %>% dplyr::select(x, xorigin, y) %>%
        mutate(x = ifelse(x > xorigin, x - lengthAdjustments, x + lengthAdjustments)) %>% 
        as.list()
  }
  
  return(flagArrows)
}

#' Get positions for vertical flags
#' Given a list of flags, will return a list of times (with duplicates removed) which are the x position of vertical lines
#' @param flags a list of vertical flags
#' @return list of time/x for each flag 
getVerticalFlagPositions <- function(flags) {
  flagAblinePositions <- list()
  
  #Remove overlapping correction ablinesmy assum
  if(!isEmptyOrBlank(flags) && !isEmptyVar(flags)){
    flagAblinePositions <- flags[which(!duplicated(flags[['time']])),][['time']]
  }
  
  return(flagAblinePositions)
}
