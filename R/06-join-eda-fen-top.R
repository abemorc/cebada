library(tidyverse)
library(sf)

# 1. Definir las rutas de todos los archivos generados
# (Asegúrate de que la ruta de edafología coincida con tu nombre de archivo real, 05 o 06)
ruta_base  <- "data/02_interim/02-parcelas-cebada-rend.geojson"
ruta_feno  <- "data/03_processed/01-metricas-fenologicas.csv"
ruta_topo  <- "data/02_interim/04-metricas-topograficas.csv"
ruta_edafo <- "data/02_interim/05-metricas-edafologicas.csv" 
ruta_clima <- "data/02_interim/06-metricas-climaticas.csv"

# 2. Cargar los datos a la memoria
cat("Cargando archivos intermedios...\n")
parcelas_sf <- st_read(ruta_base, quiet = TRUE)
df_feno     <- read_csv(ruta_feno, show_col_types = FALSE)
df_topo     <- read_csv(ruta_topo, show_col_types = FALSE)
df_edafo    <- read_csv(ruta_edafo, show_col_types = FALSE)
df_clima    <- read_csv(ruta_clima, show_col_types = FALSE)

# 3. Homologar nombres de llaves primarias
# En Python exportamos como 'id_parcela', aquí lo renombramos a 'id_poligon' 
# para que coincida exactamente con el GeoJSON base y facilite el join.
df_feno  <- df_feno  %>% rename(id_poligon = ID_POLIGONO)
df_clima <- df_clima %>% rename(id_poligon = id_parcela)

df_feno
df_clima
# 4. Consolidar el Dataset Maestro mediante uniones relacionales
cat("Ensamblando Dataset Maestro multivariado...\n")
dataset_maestro_sf <- parcelas_sf %>%
  left_join(df_feno, by = "id_poligon") %>%
  left_join(df_topo, by = "id_poligon") %>%
  left_join(df_edafo, by = "id_poligon") %>%
  left_join(df_clima, by = "id_poligon") %>% 
  select(-c(cultivo.y, area_ha.y, municipio.y, estado.y, 
    conjunto.y,rendimiento_t_ha.y)) %>% 
  rename(cultivo=cultivo.x,area_ha=area_ha.x,municipio=municipio.x,
    estado=estado.x,conjunto=conjunto.x,rendimiento_t_ha=rendimiento_t_ha.x)

glimpse(dataset_maestro_sf)

# Validar integridad final
cat("Dimensiones del dataset final:", dim(dataset_maestro_sf)[1], "parcelas x", dim(dataset_maestro_sf)[2], "variables\n")

# 5. Guardar archivos finales en la carpeta de datos procesados
# dir.create("data/03_processed", showWarnings = FALSE, recursive = TRUE)

# Exportar a GeoJSON (Mantiene la geometría)
# delete_dsn = TRUE permite sobrescribir el archivo si vuelves a correr el script
ruta_out_geojson <- "data/03_processed/dataset_maestro.geojson"
st_write(dataset_maestro_sf, ruta_out_geojson, delete_dsn = TRUE, quiet = TRUE)

# Exportar a CSV (Matriz de Machine Learning pura)
ruta_out_csv <- "data/03_processed/dataset_maestro.csv"
dataset_maestro_sf %>%
  st_drop_geometry() %>%
  write_csv(ruta_out_csv)

cat("¡Fase 5 Completada con Éxito!\n")
cat(" -> Archivo espacial (Mapas/Validación):", ruta_out_geojson, "\n")
cat(" -> Archivo tabular (Entrenamiento RF):", ruta_out_csv, "\n")


