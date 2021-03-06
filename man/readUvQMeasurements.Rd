% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/uvhydrograph-data.R
\name{readUvQMeasurements}
\alias{readUvQMeasurements}
\title{Read Discharge Measurements}
\usage{
readUvQMeasurements(reportObject, month)
}
\arguments{
\item{reportObject}{entire UV Hydro report object}

\item{month}{subset only into this month}
}
\value{
subset of Q data, default to empty frame if none found
}
\description{
Read Q measurements subsetted by month for UV Hydrograph
}
