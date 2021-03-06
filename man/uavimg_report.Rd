% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/uavimg_report.R
\name{uavimg_report}
\alias{uavimg_report}
\title{Create report(s) of UAV Images}
\usage{
uavimg_report(x, col = NULL, output_dir = NULL, create_dir = TRUE,
  output_file = NULL, report_rmd = NULL, open_report = TRUE,
  self_contained = TRUE, png_map = FALSE, png_exp = 0.2,
  google_api = NULL, quiet = FALSE)
}
\arguments{
\item{x}{A list of class 'uavimg_info'}

\item{col}{Color value(s) of the centroids and/or footprints}

\item{output_dir}{If NULL, then will be placed in a 'map' sub-directory of the images}

\item{create_dir}{Create the output directory if it doesn't exist}

\item{output_file}{Name of the HTML file. If NULL a default based on the name of the input directory is chosen.}

\item{report_rmd}{Rmd template used to generate the HTML file. See details.}

\item{open_report}{Open the HTML file in a browser}

\item{self_contained}{Make the output HTML file self-contained}

\item{png_map}{Whether to create a PNG version of the map. May be T/F, or dimensions of the output image in pixels (see Details)}

\item{png_exp}{A proportion to expand the bounding box of the PNG map, see Details.}

\item{google_api}{API key for Google Static Maps, see Details.}

\item{quiet}{TRUE to supress printing of the pandoc command line}
}
\value{
The filename of the HTML report generated
}
\description{
Creates HTML report(s) of a directory of UAV images
}
\details{
This will generate HTML report(s) of the images in the UAV metadata object based. 

If no value for \code{output_dir} is passed, the report will be saved in a sub-directory of the image directory 
called 'map'. This sub-directory will be created if \code{create_dir = TRUE}.

\code{self_contained} determines whether the HTML file(s) created will have all the JavaScript and CSS files
embedded in the HTML file itself, or saved in a subdirectory called 'libs'. If saving several reports to one output directory,
If saving multiple HTML reports to the same output directory, passing \code{self_contained = FALSE} is more efficient   

The HTML report is generated from a RMarkdown file. If you know how to edit RMarkdown, you can modify the default template and pass the filename
of your preferred template using the \code{report_rmd} argument. 

\code{png_map} controls whether a PNG version of the map will be created in \code{output_dir}. If TRUE, a PNG file at the default dimensions (480x480) will be created. If a single integer is passed, it will be taken to be the width and height on the PNG file in pixels. \code{png_exp} is a percentage of the points bounding box that will be used as a buffer for the background map. If the map seems too cropped, or you get a warning message about rows removed, try increasing it. By default, the background image will be a satellite photo from Google Maps. However this requires a valid API Key for the Google Maps Static service (for details see \url{https://developers.google.com/maps/documentation/maps-static/} as well as \link[ggmap]{register_google}), which you pass with the \code{google_api} argument. If this is not passed, you'll probably get a terrain map from Stamen.
}
\seealso{
\link{uavimg_info}
}
