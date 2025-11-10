library(tidyverse)
library(sf)
library(ggspatial)
library(here)
library(raster)
library(lidR)
library(osmdata)


#Load in lidar data (downloaded manually from Washington State Lidar Portal; https://lidarportal.dnr.wa.gov/)
snoho_path<-here("Data","kingco_sf_snoqualmie_river_2010","laz")

snoho_lascat<-readLAScatalog(snoho_path)

##Break catalog into 4km chunk with 1m buffers
opt_chunk_size(snoho_lascat)<-4000
opt_chunk_buffer(snoho_lascat)<-1


#Fetch roads within case area roads

##Set up bounding box (coordinates found manually on Washington state Lidar portal)
snoho_bbox<-c(-121.8272,47.4575,-121.7077,47.5395)

##Search for all roads (key = highway, level not specified)
snoho_roads<-opq(bbox = snoho_bbox)|>
  add_osm_feature(key = "highway")|>
  osmdata_sf()


##Buffer 15m around roads
snoho_roads_buffer<-st_buffer(snoho_roads$osm_lines,dist = 15)|>
  st_transform(crs = 32149)

snoho_roads_buffer<-st_union(snoho_roads_buffer$geometry)

#Clip out the roads buffer to leave us with only the areas outside the roads
anti_buffer<-st_bbox(snoho_roads_buffer)|>
  st_as_sfc()|>
  st_difference(snoho_roads_buffer)
  


#Now, filter our points 

##Here's the issue - clip_roi, which should fiter out the points, returns a null value because it doesn't recognize the overlap
clip_roi(snoho_lascat,anti_buffer)

##Lets check
snoho_lascat

anti_buffer

##They have the same crs, but R doesn't recognize the overlap because the Lidar points have been shifted to minimize noise in .laz file conversion
##I don't know how to fix it, I would love to snap them together but I don't know how to do that with these types of data




