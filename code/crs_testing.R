library(sf)
library(mapview)
library(osmdata)
library(lidR)
library(here)

# --- 1. Path to LiDAR files ---
snoho_path <- here("Data", "kingco_sf_snoqualmie_river_2010", "laz")

# List LAS/LAZ files and pick one small file for testing
las_files <- list.files(snoho_path, pattern = "\\.laz$", full.names = TRUE)
test_file <- las_files[1]  # choose the first file

# --- 2. Read only one file instead of the catalog ---
test_las <- readLAS(test_file)

# Assign correct CRS (NAD83 / Washington South (ftUS))
st_crs(test_las) <- 2927

# --- 3. Make a bounding box for the test file ---
lidar_bbox <- st_as_sfc(st_bbox(test_las), crs = 2927)
lidar_bbox_latlon <- st_transform(lidar_bbox, 4326) |> st_bbox()

# --- 4. Get nearby roads from OpenStreetMap ---
roads <- opq(bbox = lidar_bbox_latlon) |>
  add_osm_feature(key = "highway") |>
  osmdata_sf()

roads_buffer <- roads$osm_lines |>
  st_transform(crs = 2927) |>
  st_buffer(dist = 15) |>
  st_union()

# --- 5. Create anti-buffer (inside lidar extent but outside roads) ---
anti_buffer <- st_difference(
  lidar_bbox,
  roads_buffer
)

# --- 6. Clip LiDAR points just for this small area ---
lidar_clip <- clip_roi(test_las, anti_buffer)

# --- 7. Randomly sample 500 points ---
set.seed(42)
n_points <- npoints(lidar_clip)
sample_idx <- sample(seq_len(n_points), size = min(500, n_points))
lidar_sample <- lidar_clip[sample_idx, ]

# Convert to sf
xyz <- data.frame(
  X = lidar_sample@data$X,
  Y = lidar_sample@data$Y,
  Z = lidar_sample@data$Z
)

points_sf <- st_as_sf(xyz, coords = c("X", "Y"), crs = st_crs(lidar_clip))

# --- 8. Visualize in mapview ---
mapview(anti_buffer, col.region = "blue", alpha = 0.3) +
  mapview(points_sf, col.regions = "red", cex = 3)
