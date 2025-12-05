library(tidyverse)
library(sf)
library(here)
library(terra)
library(raster)
library(lidR)
library(whitebox)


snoho_path<-here("Data","lidar_filter")

snoho_lascat<-readLAScatalog(snoho_path)


st_crs(snoho_lascat)<-2927

opt_chunk_buffer(snoho_lascat)<-1


snoho_rast<-rasterize_terrain(snoho_lascat, 
                              res = 0.5,
                              algorithm = tin())


