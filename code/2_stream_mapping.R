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
                              algorithm = kriging())

wbt_breach_depressions_least_cost(
  dem = snoho_rast,
  output = "snoho_breach.tif"
)

wbt_fill_depressions_wang_and_liu(
  dem = "snoho_breach.tif",
  output = here("Data","Raters",paste("snoho_breach_fill.tif"))
)

wbt_d8_flow_accumulation(
  input = here("Data","Raters",paste("snoho_breach_fill.tif")),
  output = "snoho_FA.tif"
)

wbt_extract_streams(
  flow_accum = "snoho_FA.tif",
  output = here("Data","Rasters","snoho_streams.tif"),
  threshold = 2000
)

