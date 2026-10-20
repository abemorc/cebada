library(tidyverse)
library(sf)

# 1. Cargar el Dataset Maestro actual y la red de caminos
ruta_maestro <- "data/03_processed/dataset_maestro.geojson"
# Sustituye con la ruta real de tu archivo de nodos de caminos
ruta_nodos <- "data/01_raw/layers-gobierno/layers/inegi-rnc-union.geojson" 

parcelas <- st_read(ruta_maestro, quiet = TRUE)
nodos <- st_read(ruta_nodos, quiet = TRUE)

nodos 

cat("Proyectando geometrías a UTM Zona 14N para cálculos en metros...\n")
# 2. Transformar ambos conjuntos al mismo sistema de coordenadas métrico (EPSG:32614)
parcelas_utm <- st_transform(parcelas, crs = 32614)
nodos_utm <- st_transform(nodos, crs = 32614)

cat("Calculando búfers de 1000 metros y distancias mínimas...\n")
# 3. Crear el búfer de 1 km alrededor de CADA parcela
parcelas_buffer <- st_buffer(parcelas_utm, dist = 1000)

parcelas_buffer %>% plot

# 4. Conteo de nodos dentro del búfer (st_intersects devuelve una lista de índices)
# lengths() cuenta cuántos elementos hay en cada lista

conteo_nodos <- lengths(st_intersects(parcelas_buffer, nodos_utm))

nodos_utm
conteo_nodos

# 5. Distancia al nodo más cercano (para tener una métrica continua de aislamiento)
# st_distance genera una matriz, apply extrae el valor mínimo por fila
matriz_distancias <- st_distance(parcelas_utm, nodos_utm)
matriz_distancias %>% str
distancia_minima_m <- apply(matriz_distancias, 1, min)

# 6. Integrar las nuevas variables al dataset original
parcelas_enriquecidas <- parcelas_utm %>%
  mutate(
    nodos_en_1km = conteo_nodos,
    distancia_a_camino_m = as.numeric(distancia_minima_m) # as.numeric elimina la clase 'units'
  )

glimpse(parcelas_enriquecidas)
parcelas_enriquecidas

cat("Guardando el Dataset Maestro actualizado...\n")
# 7. Sobrescribir los archivos finales
st_write(parcelas_enriquecidas, ruta_maestro, delete_dsn = TRUE, quiet = TRUE)

parcelas_enriquecidas %>%
  st_drop_geometry() %>%
  write_csv("data/03_processed/dataset_maestro.csv")


