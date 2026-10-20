

library(sf)
library(mapview)

ruta_geojson <- "data/02_interim/02-parcelas-cebada-rend.geojson"

# Importar datos
parcelas_geo <- st_read(ruta_geojson)

# Mostrar todos los atributos en el mapa interactivo
mapview(
  parcelas_geo,
  zcol = 'rendimiento_t_ha'
)
