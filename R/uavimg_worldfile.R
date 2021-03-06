#' Create world and projection files for UAV images
#'
#' Create world files and projection files for UAV images
#'
#' @param x A list of class 'uavimg_info'
#' @param aux.xml Create an aux.xml file, logical. See details. 
#' @param wld Create a world file, logical. See details.
#' @param wldext Extension for the world file, character. Ignored if \code{wld = FALSE}.
#' @param prj Create a prj file, logical. See details.
#' @param rotated Compute parameters that replicate the camera Yaw.
#' @param quiet Show messages.
#'
#' @details
#' This function creates \href{https://en.wikipedia.org/wiki/Sidecar_file}{sidecard}
#' \href{https://en.wikipedia.org/wiki/World_file}{world files} and/or 
#' projection files that are required to view raw images in GIS software such as
#' ArcGIS and QGIS. 
#'
#' \emph{Note: this function has been tested with JPG files from several DJI cameras. It has not yet been adapted for TIF files from multispectral cameras, and may  not work with those format.}
#'   
#' Note that the parameters in the world file are taken exclusively from the image 
#' metadata, and will be \strong{approximate at best}. For a more accurate image placement, 
#' process the images with photogrammetry software.
#'
#' If your objective is to open the images in ArcGIS or QGIS, then generating the \code{aux.xml} files should be all you need. \code{aux.xml} files are \href{http://desktop.arcgis.com/en/arcmap/latest/manage-data/raster-and-images/auxiliary-files.htm}{ESRI auxillary files} for raster layers. To be read by GIS software, they should have the same name as the image file with 'aux.xml' added on. aux.xml files can contain a lot of info about a raster layer, including statistics, the rotation info, coordinate reference system, and other stuff. If generated by this function, they will contain projection and rotation info only. Note also \strong{any existing aux.xml files will be overwritten}. aux.xml files are the only sidecar file that ArcGIS software supports for reading the projection info. 
#' 
#' World files are small text files with extensions \code{jpw} and \code{tfw} for
#' JPG and TIF files respectively. To be read by GIS software, they must 
#' have the same basename as the image and be saved in the same directory. Both ArcGIS and QGIS read world files, however they are not needed if the same info is available in an aux.xml file.
#' 
#' \code{prj} files contain just the Coordinate Reference System info. They do not seem to be recognized for rasters by ArcGIS, however QGIS picks them up.
#'
#' @return A vector of filenames generated.
#'
#' @seealso \link{uavimg_info}
#'
#' @export

uavimg_worldfile <- function(x, aux.xml = TRUE, wld = FALSE, wldext = "auto", prj = FALSE, rotated = TRUE, quiet = FALSE) {

    if (!inherits(x, "uavimg_info")) stop("x should be of class \"uavimg_info\"")
    reslt <- list()
    
    wldext_lst <- list("jpg" ="jpw", "tif" = "tfw", "bil" = "blw")
  
    for (iinfo_idx in 1:length(x)) {
      files_gen <- NULL
      
      ## Get the CRS which will be used to generate the prj files.
      img_crs <- x[[iinfo_idx]]$pts@proj4string
      img_wkt <- showWKT(img_crs@projargs)
      
      for (i in 1:nrow(x[[iinfo_idx]]$pts)) {
        ## Get the input file name (minus path)
        img_fn_in <- x[[iinfo_idx]]$pts@data[i, "file_name"]
        img_ext <- tolower(substr(img_fn_in, nchar(img_fn_in)-2, nchar(img_fn_in)))
        img_fnfull <- x[[iinfo_idx]]$pts@data[i, "img_fn"]

        ## Extract the GSD in map units (meter)
        img_gsd_m <- x[[iinfo_idx]]$pts@data[i, "gsd"] / 100
        
        ## Extract the footprint width, height, and center
        img_fp_width <- x[[iinfo_idx]]$fp@data[i, "fp_width"]
        img_fp_height <- x[[iinfo_idx]]$fp@data[i, "fp_height"]
        img_ctr <- coordinates(x[[iinfo_idx]]$pts[i,])
        
        if (rotated) {
          ## Extract the yaw
          img_yaw <- x[[iinfo_idx]]$pts@data[i, "yaw"]
          
          ## Convert compass angle to radians of rotation on the Cartesian plane
          theta <- (180 - img_yaw) *  pi / 180
          
          ## Define the rotation matrix
          (rot_mat <- matrix(data=c(cos(theta), -sin(theta), sin(theta), 
                                    cos(theta)), 
                             nrow=2, byrow=TRUE))
        } else {
          theta <- 0
        }
        
        ## Find the coordinates of the lower right corner relative to the ctr
        lr_unrotated_xy <- matrix(data=c((img_fp_width / 2) - (img_gsd_m / 2),
                                          (- img_fp_height / 2) + (img_gsd_m / 2)),
                                   byrow=TRUE, ncol=2)
        
        if (rotated) {
          ## Compute rotated coordinates of the lower right
          lr_rotated_xy <- t(rot_mat %*% t(lr_unrotated_xy))
          
          ## Compute the absolute coordinates of the LR
          lr_rot_ctr_x <- img_ctr[1] + lr_rotated_xy[1]
          lr_rot_ctr_y <- img_ctr[2] + lr_rotated_xy[2]
        
        } else {
          ## Compute the absolute coordinates of the LR
          lr_rot_ctr_x <- img_ctr[1] + lr_unrotated_xy[1]
          lr_rot_ctr_y <- img_ctr[2] + lr_unrotated_xy[2]
        }
        
        wld_params <- c(- img_gsd_m * cos(theta),
                        - img_gsd_m * sin(theta),
                        - img_gsd_m * sin(theta),
                        img_gsd_m * cos(theta),
                        lr_rot_ctr_x,
                        lr_rot_ctr_y)
                
        # Line 1: A: x-component of the pixel width (x-scale)
        # Line 2: D: y-component of the pixel width (y-skew)
        # Line 3: B: x-component of the pixel height (x-skew)
        # Line 4: E: y-component of the pixel height (y-scale), typically negative
        # Line 5: C: x-coordinate of the center of the original 
        #            image's upper left pixel transformed to the map
        # Line 6: F: y-coordinate of the center of the original image's
        #            upper left pixel transformed to the map

        if (aux.xml) {
          ## Write the aux.xml
          xml_fn <- paste0(img_fnfull, ".aux.xml")
          
          ## Note the contents of the GeoTransform tag are the same as the 
          ## six coefficients from the world file, but in a different order
          ## c(5, 1, 3, 6, 2, 4)
          writeLines(paste0("<PAMDataset>\n<SRS>", img_wkt, "</SRS>\n", 
                            "<GeoTransform>", paste(wld_params[c(5, 1, 3, 6, 2, 4)], 
                                                    collapse=", "), "</GeoTransform>\n",
                            "</PAMDataset>"),
                     xml_fn)
          files_gen <- c(files_gen, xml_fn)
        }

        if (wld) {
          # Write the world file
          if (wldext == "auto") {
            if (img_ext %in% names(wldext_lst)) {
              wld_fn_ext <- wldext_lst[[img_ext]]
            } else {
              warning(paste0("World file extension for ", img_ext, " files not known. Resorting to '.wld'."))
              wld_fn_ext <- "wld"
            }
          } else {
            wld_fn_ext <- wldext
          }
          
          wld_fn <- paste0(substr(img_fnfull, 0, nchar(img_fnfull) - 3),
                           wld_fn_ext) 
          writeLines(as.character(wld_params), wld_fn)
          files_gen <- c(files_gen, wld_fn)
        }
        
        if (prj) {
          ## Write the prj file
          prj_fn <- paste0(substr(img_fnfull, 0, nchar(img_fnfull) - 3), "prj")
          writeLines(img_wkt, prj_fn)
          files_gen <- c(files_gen, prj_fn)
        }

        
      } # for 1 in 1:nrow

      ## Append this list of world files to the result
      reslt[[names(x)[iinfo_idx]]] <- files_gen
      
    } #for (iinfo_idx in 1:length(x))
  
  
    if (!quiet) cat("Done.\n")
    
    invisible(reslt)
}
