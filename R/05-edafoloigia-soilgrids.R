library(tidyverse)
library(sf)
library(jsonlite)

# 1. Cargar parcelas y obtener centroides geográficos (WGS84 - EPSG:4326)
ruta_geojson <- "data/02_interim/02-parcelas-cebada-rend.geojson"
parcelas_sf <- st_read(ruta_geojson, quiet = TRUE)

# Reproyectamos a coordenadas lat/lon puras, requeridas por la API de SoilGrids
parcelas_wgs84 <- st_transform(parcelas_sf, crs = 4326)

# Extraer el punto central de cada polígono
centroides <- st_point_on_surface(parcelas_wgs84)

# 2. Preparar el dataframe para almacenar los resultados
resultados_suelo <- tibble()

# 3. Función para consultar la API de SoilGrids REST
consultar_soilgrids <- function(lon, lat, id) {
  # Definir endpoint con las propiedades a extraer (densidad y textura)
  url <- sprintf("https://rest.isric.org/soilgrids/v2.0/properties/query?lon=%f&lat=%f&property=bdod&property=clay&property=sand&property=silt", lon, lat)
  
  # Manejo de errores (por si hay interrupciones de red)
  req <- tryCatch(fromJSON(url), error = function(e) NULL)
  
  if (is.null(req)) return(NULL)
  
  # Extraer las capas JSON
  capas <- req$properties$layers
  
  # Función interna para navegar el JSON y sacar la media de una profundidad específica
  extraer_valor <- function(propiedad, profundidad) {
    df_prop <- capas %>% filter(name == propiedad) %>% pull(depths) %>% .[[1]]
    val <- df_prop %>% filter(label == profundidad) %>% pull(values) %>% pull(mean)
    return(val)
  }
  
  # Compilar datos y hacer conversiones de unidades oficiales de SoilGrids
  tibble(
    id_poligon = id,
    # Densidad Aparente (bdod): SoilGrids devuelve en cg/cm3. Dividimos entre 100 para g/cm3.
    bdod_15_30cm = extraer_valor("bdod", "15-30cm") / 100, 
    bdod_30_60cm = extraer_valor("bdod", "30-60cm") / 100,
    
    # Textura: SoilGrids devuelve en g/kg. Dividimos entre 10 para obtener porcentaje (%).
    clay_15_30cm = extraer_valor("clay", "15-30cm") / 10,  
    sand_15_30cm = extraer_valor("sand", "15-30cm") / 10,
    silt_15_30cm = extraer_valor("silt", "15-30cm") / 10
  )
}

# 4. Iterar sobre las 197 parcelas (tarda aprox. 1-2 minutos en procesar todas)
cat("Consultando API de SoilGrids para 197 parcelas...\n")
pb <- txtProgressBar(min = 0, max = nrow(centroides), style = 3)

for (i in 1:nrow(centroides)) {
  lon <- st_coordinates(centroides)[i, 1]
  lat <- st_coordinates(centroides)[i, 2]
  id <- centroides$id_poligon[i]
  
  datos_punto <- consultar_soilgrids(lon, lat, id)
  
  if (!is.null(datos_punto)) {
    resultados_suelo <- bind_rows(resultados_suelo, datos_punto)
  }
  
  setTxtProgressBar(pb, i)
}
close(pb)


resultados_suelo
# 5. Guardar los resultados localmente
ruta_salida <- "data/02_interim/05-metricas-edafologicas.csv"
write_csv(resultados_suelo, ruta_salida)
cat("Análisis edafológico finalizado. Archivo guardado en:", ruta_salida, "\n")
