% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils-validation.R
\name{isEmptyOrBlank}
\alias{isEmptyOrBlank}
\title{isEmptyOrBlank}
\usage{
isEmptyOrBlank(val = NULL, listObjects = NULL, objectName = NULL)
}
\arguments{
\item{val}{any R object.}

\item{listObjects}{R list of objects.}

\item{objectName}{R object.}
}
\description{
Check if a value is NULL or NA or empty string or not in a list of objects.
}
\details{
Check for empty or blank values

Be careful what you pass in as \code{val},
e.g. a list will return a vector of logicals.
}
\seealso{
\code{\link{isEmpty}}
}
