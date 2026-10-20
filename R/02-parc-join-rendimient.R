library(sf)
library(dplyr)
library(stringr)
library(janitor)

# 1. Definir rutas actualizadas
ruta_geojson <- "data/02_interim/01-parcelas-cebada.geojson"
ruta_csv <- "data/01_raw/ID_area_rendimiento_70_30_Reto_AgroCebada.csv"
ruta_geojson_final <- "data/02_interim/02-parcelas-cebada-rend.geojson"

# 2. Importar datos
parcelas_geo <- st_read(ruta_geojson)
datos_csv <- read.csv(ruta_csv)

# 3. Unir datos y limpiar el objeto resultante
parcelas_limpias <- parcelas_geo %>% 
  # Unir indicando que ID_POLIGON (del geojson) corresponde a ID_POLIGONO (del csv)
  left_join(datos_csv, by = join_by(id_poligon == ID_POLIGONO)) %>%   
  # Eliminar columnas redundantes (.y) o vacías (X) generadas tras el join o en el CSV original
  select(-X, -CONJUNTO, -AREA_HA) %>%
  # Limpiar nombres de columnas a snake_case
  clean_names() %>%
  # Mover la geometría al final por convención
  relocate(geometry, .after = last_col())


parcelas_limpias
glimpse(parcelas_limpias)

# 4. Exportar el GeoJSON final
st_write(parcelas_limpias, ruta_geojson_final, driver = "GeoJSON", delete_dsn = TRUE)
# exportar tambien a csv
# Definir la ruta de salida para el CSV
ruta_csv_salida <- "data/02_interim/02-parecelas-rend-atributos.csv"

library(readr)
# Dropear geometría y exportar
parcelas_limpias %>%
  st_drop_geometry() %>%
  write_csv(ruta_csv_salida)

