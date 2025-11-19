library(tidyverse)
library(sf)
library(here)
library(lidR)
library(osmdata)


#Load in lidar data (downloaded manually from Washington State Lidar Portal; https://lidarportal.dnr.wa.gov/)
snoho_path<-here("Data","las_test")

snoho_lascat<-readLAScatalog(snoho_path)

#Edit the crs to drop points in their proper location (listed crs is incorrect)
st_crs(snoho_lascat)<-2927

#Break catalog into chunks with 1m buffers 
opt_chunk_buffer(snoho_lascat)<-1


#Create a new directory to store filtered las files
dir.create(here("Data","lidar_filter"))

#Write out a loop to process each file in the LASCatalog (instead of merging to 1 las object)
for(i in 1:nrow(snoho_lascat@data)){
##Select each file name and reset the laspath to read to that file
  laspath<-snoho_lascat@data[["filename"]][[i]]
##Read in each selected file
  las<-readLAS(laspath)
##Reset crs
  st_crs(las)<-2927
##Build a bbox for each file and convert back to latlon
  bbox<-st_as_sfc(st_bbox(las),crs = 2927)
  bbox_latlon<-st_transform(bbox,crs = 4326)|>st_bbox()
##Select openstreetmaps roads from within each bbox
  roads<-opq(bbox = bbox_latlon)|>add_osm_feature(key = "highway")|>osmdata_sf()
##Build a 15m buffer around each road
  roads_buffer<-roads$osm_lines|>st_transform(crs = crs(las))|>st_buffer(dist = 15)|>st_union()
##Select for only those areas not within the 15m buffer
  anti_buffer<-st_difference(bbox,roads_buffer)
##Clip las file to only areas not within the 15m road buffer
  las_filter<-clip_roi(las,anti_buffer)
##Write new las file with filtered data
  writeLAS(las_filter,file.path(here("Data","lidar_filter"),paste0("filter",i,".laz")))
}



