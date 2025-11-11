# Validate CRS alignment and clipping for LiDAR data ----

library(sf)
library(osmdata)
library(lidR)
library(here)

# Load LiDAR catalog ----

snoho_path <- here("Data", "kingco_sf_snoqualmie_river_2010", "laz")
snoho_lascat <- readLAScatalog(snoho_path)

opt_chunk_size(snoho_lascat)  <- 4000
opt_chunk_buffer(snoho_lascat) <- 1

# Get LiDAR bounding box and convert to lat/lon for OSM query ----

lidar_bbox_m <- st_as_sfc(st_bbox(snoho_lascat), crs = 32149)

lidar_bbox_latlon <- st_transform(lidar_bbox_m, 4326) |> st_bbox()

# Shrink bounding box for faster testing ----

shrink_bbox <- function(bbox, factor = 20) {
  dx <- (bbox$xmax - bbox$xmin) / factor
  dy <- (bbox$ymax - bbox$ymin) / factor
  c(
    xmin = bbox$xmin + dx,
    ymin = bbox$ymin + dy,
    xmax = bbox$xmin + 2 * dx,
    ymax = bbox$ymin + 2 * dy
  )
}

small_bbox <- shrink_bbox(lidar_bbox_latlon)

# Query OSM for a small sample of roads ----

roads_test <- opq(bbox = small_bbox) |>
  add_osm_feature(key = "highway") |>
  osmdata_sf()

# Transform and buffer roads ----

roads_buffer <- roads_test$osm_lines |>
  st_transform(crs = 32149) |>
  st_buffer(dist = 15) |>
  st_union()

# Create anti-buffer area (inside LiDAR extent but outside roads) ----

anti_buffer <- st_difference(
  st_as_sfc(st_bbox(snoho_lascat), crs = 32149),
  roads_buffer
)

# Clip LiDAR points to anti-road area ----

test_clip <- clip_roi(snoho_lascat, anti_buffer)
print(test_clip)
