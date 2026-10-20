
library(sf)
library(dplyr)

ruta_shp <- "data/01_raw/Parcelas_Reto_AGC_CONJUNTO_70_30/Parcelas_Reto_AGC_CONJUNTO.shp"
ruta_geojson <- "data/02_interim/01-parcelas-cebada.geojson"

parcelas <- st_read(ruta_shp)

# dropear dim z vacia
parcelas <- st_zm(parcelas)

parcelas %<>% 
  mutate(Cultivo = stringr::str_to_upper(Cultivo)) %>%
  # Limpiar nombres de columnas a snake_case
  janitor::clean_names()

parcelas
st_write(parcelas, ruta_geojson, driver = "GeoJSON", delete_dsn = TRUE)
