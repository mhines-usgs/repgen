#' Plot time series on additional y-axes
#' @title printWithMultipleYAxes
#' @param plot A gsplot, plot object.
#' @seealso \code{\link{log_tick_marks}}
printWithMultipleYAxes <- function(plot) {
  axisDistance <- 4.5
  
  mar_vals <- par(plot)$mar
  if(is.null(mar_vals)){
    mar_vals <- par('mar')
  } 
  mar_vals[4] <- mar_vals[4] + axisDistance
  par(mar=mar_vals)
  
  print(plot)
  plot
  minor.ticks <- pretty(ylim(plot,6))
  major.ticks <- log_tick_marks(ylim(plot,6)[[1]], ylim(plot,6)[[2]])
  major.ticks <- major.ticks[major.ticks <= ylim(plot, 6)[[2]]]
  ticks <- major.ticks[major.ticks >= ylim(plot, 6)[[1]]]

  #Only add additional tick marks if we don't have many generated by the log ticks function
  if(length(ticks) <= 3)
  {
    ticks <- unique(append(major.ticks, minor.ticks))
  }

  #Only remove decimals from tick marks if the y range is great enough that they're not necessary
  #Add points below and above the plot to extaned the axis bar to the full plot height
  if((ylim(plot,6)[[2]]-ylim(plot,6)[[1]]) >= 10)
  {
    ticks <- trunc(append(ticks, c(-1, ylim(plot,6)[[2]]*2)))
  } else {
    ticks <- append(ticks, c(-1, ylim(plot,6)[[2]]*2))
  }

  #Draw the 3rd axis
  par(new=TRUE)
  plot(NA, 0, ylim=ylim(plot, side=6), xlim=c(0,1), axes=FALSE, ylab="", xlab="")
  axis(side=4, at=ticks, line=axisDistance, las=0)
  
  #Only go through here if we have a 4th y-axis
  if(!isEmptyOrBlank(plot[['side.8']])) {
    #calculate ticks for 4th axis
    minor.ticks <- pretty(ylim(plot,8))
    major.ticks <- log_tick_marks(ylim(plot,8)[[1]], ylim(plot,8)[[2]])
    major.ticks <- major.ticks[major.ticks <= ylim(plot, 8)[[2]]]
    ticks <- major.ticks[major.ticks >= ylim(plot, 8)[[1]]]
  
    #Only add additional tick marks if we don't have many generated by the log ticks function
    if(length(ticks) <= 3)
    {
      ticks <- unique(append(major.ticks, minor.ticks))
    }
  
    #Only remove decimals from tick marks if the y range is great enough that they're not necessary
    #Add points below and above the plot to extaned the axis bar to the full plot height
    if((ylim(plot,8)[[2]]-ylim(plot,8)[[1]]) >= 10)
    {
      ticks <- trunc(append(ticks, c(-1, ylim(plot,8)[[2]]*2)))
    } else {
      ticks <- append(ticks, c(-1, ylim(plot,8)[[2]]*2))
    }
  
    #Draw the 4th
    par(new=TRUE)
    plot(NA, 0, ylim=ylim(plot, side=8), xlim=c(0,1), axes=FALSE, ylab="", xlab="")
    axis(side=4, at=ticks, line=axisDistance+4, las=0)
  }
  
  #add labels for left and right axes
  mtext(paste0(plot[['side.2']][['label']]), side=2, line=axisDistance-2.5, padj=0)
  mtext(paste0(plot[['side.4']][['label']]), side=4, line=axisDistance-2.5, padj=0)
  mtext(plot[['side.6']][['label']], side=4, line=axisDistance+1.25, padj=0)
  
  #Only add label for 3rd right axis if we have one
  if(!isEmptyOrBlank(plot[['side.8']])) {
    mtext(plot[['side.8']][['label']], side=4, line=axisDistance+5.25, padj=0)
  }
}

#' Add tick marks to logarithmic axis
#' @title log_tick_marks
#' @param min ylim function returning minimum axis range
#' @param max ylim function returning maximum axis range
log_tick_marks <- function(min,max)
{
  nsplit <- abs(round(log10(max-min)))
  i <- 0
  nurange <- c()
  while(i<=nsplit) {
    nurange <- c(nurange,sapply(c(1,2,5),function(x) x*(10^i)))
    i <- i+1;
  }
  nurange
}

#' Add x-axis labels
#' @title XAxisLabels
#' @description Add x-axis labels to five year GW summary plots, and DV hydrographs
#' having time intervals of one year or more.
#' @param object A gsplot, plot object.
#' @param text Vector of month abbreviations.
#' @param at.months Vector of month dates to label month abbreviations (in
#'                  "text" vector) at.
#' @param at.years Vector of dates to label years at.
#' @return The passed-in gsplot object, with x-axis labeled.
XAxisLabels <- function(object, text, at.months, at.years) {
  return(
    mtext(
      object,
      text = text, at = at.months,
      cex = 0.5, side = 1
    ) %>%
      mtext(
        text = lubridate::year(at.years), at = at.years,
        line = 1, side = 1
      )
  )
}

#' Delineate year boundaries
#' @title DelineateYearBoundaries
#' @description Delineate year boundaries on five year GW summary plots, and DV hydrographs
#' having time intervals of one year or more.
#' @param object A gsplot, plot object.
#' @param years A sequence of year begin dates to draw the lines at.
#' @return The passed-in gsplot object, with year boundaries delineated.
DelineateYearBoundaries <- function(object, years) {
  return(
    abline(
      object,
      v = years, col = "gray47",
      lwd = 2, where = 'first'
    )
  )
}

#' Extend y-Axis Limits
#'
#' @description Extends the Y-Axis limits if the error bars extend further than the current limits.
#' Sets the y-limits to the smallest (and largest) value between the error bars and current plot limits.
#' @param gsplot The gsplot object to extend limits for
#' @param comparisonLims A vector containing minimum and maximum points to compare to Y-axis limits
#' @param side The axis to be changed/compared to (default is 2, the y-axis).
extendYaxisLimits <- function(gsplot, comparisonLims, side){
  side <- ifelse(!isEmptyOrBlank(side),side,2)
  side_nm <- paste0('side.', side)
  
  ##Compare error bar extrema with current plot lims.
  lowest_y <- min(ylim(gsplot, side=side), comparisonLims)
  highest_y <- max(ylim(gsplot, side=side), comparisonLims)
  
  ##lims added (lowest, highest) because gsplot does reversing on print automatically.
  gsplot[[side_nm]][['lim']] <- c(lowest_y, highest_y)
  return(gsplot)
}

#' Format time series for plotting
#'
#' @description Helper function that primes a time series for plotting
#' by extracing the points data frame from the list, adding the legend
#' name to that data frame, and removing zero/negative value rows if necessary
#' @param series The time series data to format for plotting
#' @param removeZeroNegativeFlag Whether or not to remove zero and negative values
#' @return A data frame representing the time series for plotting
formatTimeSeriesForPlotting <- function(series, removeZeroNegativeFlag=NULL){
  if(anyDataExist(series[['points']])){
    seriesLegend <- rep(series[['legend.name']], nrow(series[['points']]))
    series <- series[['points']]
    series[['legend.name']] <- seriesLegend
    
    if(!isEmptyOrBlank(removeZeroNegativeFlag) && removeZeroNegativeFlag){
      series <- removeZeroNegative(series)
    }
  }
  
  return(series)
}

#' Format split time series plotting
#'
#' @description Helper function for formating a spearated list of time series
#' that are all part of the same overall time series. This is primarily used for
#' time series that have been split up because of gaps caused by estimated periods
#' or actual gaps in data.
#' @param seriesList The time series list to format for plotting
#' @param excludeZeroNegativeFlag Whether or not zero and negative values should be removed
#' @return A list of formated time series data frames
formatSplitTimeSeriesForPlotting <- function(seriesList, excludeZeroNegativeFlag=NULL){
  if(!is.null(seriesList) && length(seriesList) > 0){
    dataFrameList <- lapply(seriesList, function(e){
      series <- e[['points']]

      if(!isEmptyOrBlank(excludeZeroNegativeFlag) && excludeZeroNegativeFlag){
        series <- removeZeroNegative(series)
      }

      if(nrow(series) == 0){
        return(NULL)
      }
      
      series[['legend.name']] <- e[['legend.name']]
      return(as.list(series))
    })

    dataFrameList <- dataFrameList[unname(unlist(lapply(dataFrameList, function(e) {return(!is.null(e))})))]
    return(dataFrameList)
  }

  return(NULL)
}

#' Compute the y lims, y-lims will ensure all of the corrected points are shown, but not necessarily all of these other points
#' @param lims current limits
#' @param buffer.value.sequence A sequence of y values from another time series.
#' @return The y-lim
bufferLims <- function(lims, buffer.value.sequence) {
  buffer.percent <- .30 #percent of corrected range allowed to extend to include these points. If lims of the buffer points within percent. 
  
  min.current.value <- lims[1]
  max.current.value <- lims[2]
  
  curr.range <- max.current.value - min.current.value
  buffer.size <- curr.range * buffer.percent
  
  min.new.value <- min(buffer.value.sequence, na.rm = TRUE)
  if (min.new.value < min.current.value - buffer.size || min.new.value > min.current.value) { #outside lower allowed range
    y.bottom <- min.current.value 
  } else {
    y.bottom <- min.new.value 
  }
  
  max.new.value <- max(buffer.value.sequence, na.rm = TRUE)
  if (max.new.value > max.current.value + buffer.size || max.new.value < max.current.value) { #outside upper allowed rang
    y.top <- max.current.value   
  } else {
    y.top <- max.new.value 
  }
  
  return(c(y.bottom, y.top))
}

#' Plot Time Series
#' 
#' @description Function that takes a gsplot object and the necessary time series data and
#' formats the time series properly for plotting and then plots it.
#' @param plot_object The gsplot object to plot onto
#' @param ts The Time Series to plot
#' @param name The variable name to use for the time series (used for style and config matching)
#' @param timezone The timezone of the time series (used for calculating gaps)
#' @param configFunction The function to use for fetching the style and config data for this TS
#' @param configFunctionAdditionalParams additional params to pas into configFunction, config function will be called with (subsetOfSeries, name, and configFunctionAdditionalParams added at end) 
#' @param excludeZeroNegativeFlag Whether or not to remove zero and negative values from the ts
#' @param isDV Whether or not the plot is a daily value plot (default: FALSE)
plotTimeSeries <- function(plot_object, ts, name, timezone, configFunction, configFunctionAdditionalParams, excludeZeroNegativeFlag=FALSE, isDV=FALSE){
  if(!is.null(ts) && anyDataExist(ts[['points']])){
    series <- splitDataGapsTimeSeries(ts, name, timezone, excludeZeroNegativeFlag, isDV=isDV)
    series <- formatSplitTimeSeriesForPlotting(series, excludeZeroNegativeFlag)
    
    doLog <- isLogged(ts[['points']], ts[['isVolumetricFlow']], excludeZeroNegativeFlag)
    configFunctionAdditionalParams <- append(configFunctionAdditionalParams, list(doLog=doLog))
    
    for(i in seq_len(length(series))){
      plot_object <- plotItem(
          plot_object, 
          series[[i]], 
          configFunction, 
          append(list(series[[i]], name), configFunctionAdditionalParams), 
          isDV)
    }
  }
  
  return(plot_object)
}

#' Plot Item
#' 
#' @description Function that takes a gsplot object and the necessary item data and
#' then formats the item properly for plotting and plots it.
#' @param plot_object The gsplot object to plot onto
#' @param item The item to plot
#' @param configFunction The function to use for fetching the style and config data for this TS
#' @param configFunctionParams list of params to call pall configFunctionWith
#' @param isDV Whether or not the plot is a daily value plot (defulat: FALSE)
plotItem <- function(plot_object, item, configFunction, configFunctionParams, isDV=FALSE){

  if(!is.null(item) && anyDataExist(item)){
    plotItem <- do.call(configFunction, configFunctionParams)
    
    for(j in seq_len(length(plotItem))){
      if(isDV){
        plotItem[[j]] <- extendStep(plotItem[[j]])
      }
      
      plot_object <- do.call(names(plotItem[j]), append(list(object = plot_object), plotItem[[j]]))
    }
  }
  
  return(plot_object)
}

#' Add a feature to a gsplot object
#' @description helper function to add arbitrary list of gsplot calls to a gsplot. Has added feature of extending
#' the Y limits for any errors bars found.
#' @param gsplot A gsplot, plot object.
#' @param plotConfig list of gsplot calls to make
#' @return A modified gsplot, plot object, with everything in the plot config included.
addToGsplot <- function(gsplot, plotConfig) {
  
  
  for (j in seq_len(length(plotConfig))) {
    gsplot <-
        do.call(names(plotConfig[j]), append(list(object = gsplot), plotConfig[[j]]))
  }
  
  error_bars <- grep('error_bar', names(plotConfig))
  for (err in error_bars) {
    err_lims <- getErrorBarYLims(plotConfig[[err]])
    gsplot <- extendYaxisLimits(gsplot, err_lims[['comparisonLims']], err_lims[['side']])
  }
  
  return(gsplot)
}

#' Calculate Lims
#' For a data frame of points, will calculate a lims object. X and Y field names can be configured for the points.
#' @param pts data frame of points
#' @param xMinField name of the field which will contain the min x value (default "time")
#' @param xMaxField name of the field which will contain the max x value (default "value")
#' @param yMinField name of the field which will contain the min y value (default "time")
#' @param yMaxField name of the field which will contain the max y value (default "value")
calculateLims <- function(pts = NULL, xMinField = 'time', xMaxField = 'time', yMinField = 'value', yMaxField = 'value'){
  x_mx <- max(pts[[xMaxField]], na.rm = TRUE)
  x_mn <- min(pts[[xMinField]], na.rm = TRUE)
  y_mx <- max(pts[[yMaxField]], na.rm = TRUE)
  y_mn <- min(pts[[yMinField]], na.rm = TRUE)
  if (any(is.na(c(x_mx, x_mn, y_mx, y_mn)))){
    stop('missing or NA values in points. check input json.')
  }
  ylim = c(y_mn, y_mx)
  xlim = c(x_mn, x_mx)
  return(list(xlim = xlim, ylim = ylim))
}

#' X-Axis Label style
#'
#' @description Given a plot object and date range parameters,
#' creates proper X-Axis labels based on the duration of the
#' date range. Including Year and Month subsets.
#' @param object the plot object to create labels for
#' @param start the start date of the date range
#' @param end the end date of the date range
#' @param timezone the timezone of the date range
#' @param plotDates the dates to create the labels at
#' @importFrom lubridate interval
#' @importFrom lubridate as.period
#' @importFrom lubridate days_in_month
#' @importFrom lubridate month
#' @importFrom lubridate year
#' @importFrom lubridate ceiling_date
#' @importFrom lubridate floor_date
#' @importFrom lubridate %m+%
#' @importFrom lubridate %m-%
#' @importFrom lubridate day
#' @importFrom lubridate days
#' @importFrom lubridate weeks
#' @importFrom stats median
XAxisLabelStyle <- function(object, start, end, timezone, plotDates) {
  i <- interval(start, end, tzone = attr(start, timezone))
  
  # remove repgendate class so that ceiling_date and floor_date can be used
  start <- remove_repgendate(start)
  end <- remove_repgendate(end)
  
  # if chart interval is less than 1 year
  if (as.period(i) < years(1)) {
    
    #if chart interval is less than or = 2 weeks, show daily ticks/labels
    if (as.period(i) <= weeks(2)) {
      plotDates <- toStartOfDay(seq(start, end, by = "1 day"))
    }  
      # x-axis
      object <- axis(
        object,
        1, at = plotDates,
        labels = format(plotDates, "%b\n%d"),
        padj = 0.5
      )
  }
  else {
    months <-
      seq(
        from = ceiling_date(start, "month"),
        to = floor_date(end, "month"),
        by = "month"
      )
    
    # [start:end] is interval here, because [from:to] above could be abbreviated
    # to omit month-letter-labeling of partial months at beginning/end of x-axis
    years <- seq(from = floor_date(start, "year"), to = floor_date(end, "year"), by = "year")

    object <- axis(object, side = 1, at = months, labels = FALSE) # x-axis
    
    month_label_split <- strsplit(as.character(lubridate::month(months, label = TRUE)), "")
    text <- unlist(lapply(month_label_split, function(x) { x[1] }))
    
    #Remove start and end labels if they won't fit on the plot
    if(day(ceiling_date(start, "day")) >= lubridate::days_in_month(ceiling_date(start, "day"))/2){
      text[[1]] = ""
    }
    
    if(day(floor_date(end, "day")) <= lubridate::days_in_month(floor_date(end, "day"))/2){
      text[[length(text)]] = ""
    }
    
    at.months <- months + days(15) # position label at 15th of month
    
    at.years <-
      do.call(c, lapply(lubridate::year(years), function(y, plotDates) {
        which.yr.dates <- which(lubridate::year(plotDates) == y)
        return(median(plotDates[which.yr.dates]))
      }, plotDates = plotDates))
    
    # add year labels to x-axis
    object <- XAxisLabels(object, text, at.months, at.years)
    
    # add vertical lines to delineate calendar year boundaries
    object <- DelineateYearBoundaries(object, years)
  }
  
  return(object)
}

#' Format Min Max Labels (DV hYdro and Five YR)
#'
#' @description Formats a min/max IV as a lable to be put on the
#' top of the plot.
#' @param ml The min / max IV label object to format
#' @param units the units to use for the IV label
formatMinMaxLabel <- function(ml, units){
  formatted_label <- ""

  if(!isEmptyOrBlank(ml) && !isEmptyOrBlank(units)){
    #Format Time
    time <- formatUTCTimeLabel(ml[['time']])
    #Create Label
    formatted_label <- paste0(ml[['legend.name']], units, time)
  }
  
  return(formatted_label)
}

#' Camel Case String
#' 
#' @description Formats the supplied string in CamelCasing
#' @param string The string to format
toSentenceCase <- function(string) {
  returnString <- paste0(toupper(substring(string, 1, 1)), tolower(substring(string, 2, nchar(string))))
  return(returnString)
}