library(tidyverse)
library(sf)
library(ggspatial)
library(here)
library(terra)
library(raster)
library(lidR)
library(osmdata)


#Load in lidar data (downloaded manually from Washington State Lidar Portal; https://lidarportal.dnr.wa.gov/)
snoho_path<-here("Data","kingco_sf_snoqualmie_river_2010","laz")

snoho_lascat<-readLAScatalog(snoho_path)

st_crs(snoho_lascat)<-2927

##Break catalog into 4km chunk with 1m buffers
opt_chunk_size(snoho_lascat)<-4000
opt_chunk_buffer(snoho_lascat)<-1


#Fetch roads within case area roads

##Set up bounding box (coordinates found manually on Washington state Lidar portal)
snoho_bbox<-st_as_sfc(st_bbox(snoho_lascat),crs = 2927)

snoho_bbox_latlon<-st_transform(snoho_bbox,4326)|>st_bbox()
##Search for all roads (key = highway, level not specified)
snoho_roads<-opq(bbox = snoho_bbox_latlon)|>
  add_osm_feature(key = "highway")|>
  osmdata_sf()


##Buffer 15m around roads
snoho_roads_buffer<-snoho_roads$osm_lines|>
  st_transform(crs = crs(snoho_lascat))|>
  st_buffer(dist = 15)|>
  st_union()


anti_buffer<-st_difference(snoho_bbox,
                         snoho_roads_buffer)
  
#Now, filter our points 

snoho_lascat_filter<-clip_roi(snoho_lascat,anti_buffer)


##And write out filtered lidar data
dir.create(path = here("Data","lidar_filter"))

catalog_apply(snoho_lascat_filter, FUN = writeLAS,
              file = here("Data", "lidar_filter",tempfile(fileext = ".laz")))


