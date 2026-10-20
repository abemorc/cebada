library(tidyverse)
library(sf)
library(jsonlite)

# 1. Cargar el trabajo que ya lograste y los centroides originales
ruta_csv <- "data/02_interim/05-metricas-edafologicas.csv"
resultados_existentes <- read_csv(ruta_csv, show_col_types = FALSE)

ruta_geojson <- "data/02_interim/02-parcelas-cebada-rend.geojson"
parcelas_wgs84 <- st_transform(st_read(ruta_geojson, quiet = TRUE), crs = 4326)
centroides <- st_point_on_surface(parcelas_wgs84)

# 2. Encontrar matemáticamente las parcelas que fallaron
faltantes <- centroides %>% 
  filter(!id_poligon %in% resultados_existentes$id_poligon)

cat("Parcelas faltantes a procesar:", nrow(faltantes), "\n")

# 3. Función de extracción (la misma que ya usaste)
consultar_soilgrids <- function(lon, lat, id) {
  url <- sprintf("https://rest.isric.org/soilgrids/v2.0/properties/query?lon=%f&lat=%f&property=bdod&property=clay&property=sand&property=silt", lon, lat)
  req <- tryCatch(fromJSON(url), error = function(e) NULL)
  if (is.null(req)) return(NULL)
  
  capas <- req$properties$layers
  extraer_valor <- function(propiedad, profundidad) {
    df_prop <- capas %>% filter(name == propiedad) %>% pull(depths) %>% .[[1]]
    df_prop %>% filter(label == profundidad) %>% pull(values) %>% pull(mean)
  }
  
  tibble(
    id_poligon = id,
    bdod_15_30cm = extraer_valor("bdod", "15-30cm") / 100, 
    bdod_30_60cm = extraer_valor("bdod", "30-60cm") / 100,
    clay_15_30cm = extraer_valor("clay", "15-30cm") / 10,  
    sand_15_30cm = extraer_valor("sand", "15-30cm") / 10,
    silt_15_30cm = extraer_valor("silt", "15-30cm") / 10
  )
}

# 4. Ejecutar la extracción SOLO para los 3 faltantes
resultados_nuevos <- tibble()

for (i in 1:nrow(faltantes)) {
  lon <- st_coordinates(faltantes)[i, 1]
  lat <- st_coordinates(faltantes)[i, 2]
  id <- faltantes$id_poligon[i]
  
  cat("Consultando ID:", id, "...\n")
  datos_punto <- consultar_soilgrids(lon, lat, id)
  
  if (!is.null(datos_punto)) {
    resultados_nuevos <- bind_rows(resultados_nuevos, datos_punto)
    cat("  -> ¡Conseguido!\n")
  } else {
    cat("  -> Falló por Timeout. Vuelve a correr el script.\n")
  }
}

# 5. Unir y sobrescribir el archivo final si hubo éxito
if(nrow(resultados_nuevos) > 0) {
  resultados_completos <- bind_rows(resultados_existentes, resultados_nuevos)
  write_csv(resultados_completos, ruta_csv)
  cat("¡Éxito total! Archivo consolidado con", nrow(resultados_completos), "filas y guardado en disco.\n")
}

