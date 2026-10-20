library(tidyverse)
library(sf)
library(terra)

# 1. Cargar el Dataset Maestro actual
ruta_maestro <- "data/03_processed/dataset_maestro.geojson"
parcelas_sf <- st_read(ruta_maestro, quiet = TRUE)

cat("Cargando punteros a los rasters pesados (BIO6 y BIO15)...\n")
# 2. Conectar a los rasters TIF de la Dra. Cuervo SIN cargarlos a la RAM
# Sustituye estas rutas por la ubicación real de los archivos descargados
ruta_bio6  <- "C:/Users/abemo/Documents/GitHub/IdoneidadHabitat/BioClimMex/Bio06.tif" 
ruta_bio15 <- "C:/Users/abemo/Documents/GitHub/IdoneidadHabitat/BioClimMex/Bio15.tif"

raster_bio6  <- rast(ruta_bio6)
raster_bio15 <- rast(ruta_bio15)

cat("Reproyectando parcelas al CRS original del raster...\n")
# 3. Transformar parcelas al CRS del raster nacional (Suele ser LCC o WGS84)
crs_raster <- crs(raster_bio6)
parcelas_raster_crs <- st_transform(parcelas_sf, crs = crs_raster)

cat("Extrayendo estadísticas zonales (Esto tomará unos minutos por el tamaño a 90m)...\n")
# 4. Extraer el valor promedio dentro de cada parcela usando el motor de terra en C++
# (Al usar exact=TRUE, pondera los píxeles cortados por el borde del polígono)
stats_bio6 <- terra::extract(raster_bio6, vect(parcelas_raster_crs), fun = mean, na.rm = TRUE, exact = TRUE)
stats_bio15 <- terra::extract(raster_bio15, vect(parcelas_raster_crs), fun = mean, na.rm = TRUE, exact = TRUE)

stats_bio6
# 5. Limpiar nombres de columnas para que sean claros en el modelo
# Asumiendo que terra devuelve la columna con el nombre del archivo raster
nombres_cols <- c("ID", "bio6_temp_min_historica", "bio15_estacionalidad_precip")
stats_consolidadas <- bind_cols(
  stats_bio6, 
  stats_bio15 %>% select(-ID) # Evitamos duplicar la columna ID
) %>%
  setNames(nombres_cols)

stats_consolidadas

cat("Integrando al Dataset Maestro...\n")
# 6. Unir los resultados bioclimáticos al dataset
parcelas_finales <- parcelas_sf %>%
  bind_cols(stats_consolidadas %>% select(-ID))

# 7. Sobrescribir los archivos maestros
st_write(parcelas_finales, 
  'data/03_processed/dataset_maestro_bioambiental.geojson',
   delete_dsn = TRUE, quiet = TRUE)

parcelas_finales %>%
  st_drop_geometry() %>%
  write_csv("data/03_processed/dataset_maestro_bioambiental.csv")

cat("¡Extracción bioclimática exitosa! Dataset Maestro listo para Machine Learning.\n")
