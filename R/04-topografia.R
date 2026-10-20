library(tidyverse)
library(sf)
library(terra)
library(elevatr)

# 1. Cargar las parcelas de entrenamiento
ruta_geojson <- "data/02_interim/02-parcelas-cebada-rend.geojson"
parcelas_sf <- st_read(ruta_geojson, quiet = TRUE)

# Es estrictamente necesario proyectar los polígonos a un sistema métrico para 
# calcular pendientes y distancias. El EPSG:32614 (UTM Zona 14N) es el 
# correcto para la región de Puebla, Tlaxcala e Hidalgo.
parcelas_utm <- st_transform(parcelas_sf, crs = 32614)

cat("Descargando el Modelo Digital de Elevación (DEM) para el Bounding Box...\n")
# 2. Descargar el DEM de AWS
# z = 13 nos da una resolución espacial aproximada de 20-30 metros (similar a Copernicus)
dem_raster <- get_elev_raster(locations = parcelas_sf, z = 13, clip = "bbox", verbose = FALSE)
dem_raster
# Convertir el formato antiguo de raster a un objeto SpatRaster de terra
dem <- rast(dem_raster)

# Reproyectar el DEM al mismo sistema UTM que las parcelas para hacer la superposición
dem_utm <- project(dem, "EPSG:32614", method = "bilinear")
names(dem_utm) <- "elevacion"

cat("Calculando superficies topológicas (Pendiente y TPI)...\n")
# 3. Derivar variables del terreno con terra
# Pendiente en grados (peligro de erosión y pérdida de retención hídrica)
pendiente <- terrain(dem_utm, v = "slope", unit = "degrees", neighbors = 8)
names(pendiente) <- "pendiente_grados"

# Índice de Posición Topográfica (TPI)
# Valores > 0 indican crestas/lomas. Valores < 0 indican depresiones (sumideros térmicos/encharcamiento).
tpi <- terrain(dem_utm, v = "TPI", neighbors = 8)
names(tpi) <- "tpi_depresiones"

# Apilar todas las capas rasters en un solo objeto para extraerlas simultáneamente
topografia_stack <- c(dem_utm, pendiente, tpi)

cat("Extrayendo estadísticas zonales por parcela...\n")
# 4. Extracción de estadísticas zonales
# Calculamos la media de las variables topográficas dentro de cada polígono
stats_zonal <- terra::extract(
  x = topografia_stack, 
  y = vect(parcelas_utm), 
  fun = mean, 
  na.rm = TRUE, 
  exact = TRUE # Considera la fracción del pixel si cruza el límite del polígono
)

str(stats_zonal)
# 5. Integración y guardado
# Unimos los resultados con los IDs originales de las parcelas
resultados_topo <- parcelas_sf %>%
  st_drop_geometry() %>%
  select(id_poligon) %>% # Asumiendo que esta es tu columna identificadora
  bind_cols(stats_zonal %>% select(-ID)) # Descartamos la columna de ID interno de terra

ruta_salida <- "data/02_interim/04-metricas-topograficas.csv"
write_csv(resultados_topo, ruta_salida)
cat("Análisis topográfico finalizado. Archivo guardado en:", ruta_salida, "\n")


#  guardar objetos
# 1. Crear el directorio si no existe
dir.create("outputs/rasters_locales", showWarnings = FALSE, recursive = TRUE)

# 2. Guardar el raster individual de elevación base (el que ya tienes en UTM)
# Es mejor usar GeoTIFF (.tif) ya que mantiene la georreferenciación (CRS) intacta
terra::writeRaster(dem_utm, 
                   filename = "outputs/rasters_locales/05_elevacion_utm.tif", 
                   overwrite = TRUE)

# 3. Guardar el "stack" completo (Elevación, Pendiente y TPI)
# terra puede guardar archivos multi-banda sin problema
terra::writeRaster(topografia_stack, 
                   filename = "outputs/rasters_locales/05_stack_topografico.tif", 
                   overwrite = TRUE)

cat("Archivos raster guardados exitosamente en data/02_interim/rasters_locales/\n")
