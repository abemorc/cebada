library(signal) # Para el filtro Savitzky-Golay
library(tidyverse)
library(lubridate)
library(zoo)

# 1. Cargar la serie temporal en bruto
input_path <- "data/02_interim/03-data-indices-vegetales.csv"
df <- read_csv(input_path, show_col_types = FALSE) %>%
  mutate(fecha = as.Date(fecha))
df

# Definir el umbral de amplitud (20%) para marcar el Inicio (SOS) y Fin (EOS)
PORCENTAJE_UMBRAL <- 0.20

# 2. Función núcleo para procesar la curva de CADA parcela individualmente
extraer_fenologia <- function(datos_parcela) {
  
  # Crear secuencia diaria estricta del 1 de febrero al 31 de diciembre
  fecha_min <- as.Date("2025-02-01")
  fecha_max <- as.Date("2025-12-31")
  
  datos_diarios <- datos_parcela %>%
    # Eliminar posibles lecturas duplicadas el mismo día
    distinct(fecha, .keep_all = TRUE) %>%
    # Completar la serie temporal para tener una fila por cada día
    complete(fecha = seq.Date(fecha_min, fecha_max, by = "day")) %>%
    arrange(fecha) %>%
    # Interpolar (lineal) huecos de nubes y rellenar los extremos (rule = 2)
    mutate(
      NDVI = na.approx(NDVI, na.rm = FALSE, rule = 2),
      NDWI = na.approx(NDWI, na.rm = FALSE, rule = 2),
      EVI  = na.approx(EVI, na.rm = FALSE, rule = 2)
    )
  
  # 3. Aplicar Filtro Savitzky-Golay (ventana de 45 días, polinomio orden 3)
  datos_diarios <- datos_diarios %>%
    mutate(
      NDVI_smooth = sgolayfilt(NDVI, p = 3, n = 45),
      EVI_smooth  = sgolayfilt(EVI, p = 3, n = 45),
      NDWI_smooth = sgolayfilt(NDWI, p = 3, n = 45)
    )
  
  
  # 4. Extracción de Métricas Fenológicas basadas en NDVI suavizado
  
  # Peak of Season (POS): El pico máximo de biomasa
  pos_row <- datos_diarios %>% filter(NDVI_smooth == max(NDVI_smooth)) %>% slice(1)
  pos_fecha <- pos_row$fecha
  pos_doy <- yday(pos_fecha)
  pos_val <- pos_row$NDVI_smooth
  
  # Calcular el umbral del 20%
  base_val <- min(datos_diarios$NDVI_smooth)
  amplitud <- pos_val - base_val
  umbral <- base_val + (amplitud * PORCENTAJE_UMBRAL)
  
  # Start of Season (SOS): Búsqueda INVERSA desde el POS
  # Encontrar el último día ANTES del POS donde el NDVI estuvo por debajo del umbral
  dias_bajo_umbral <- datos_diarios %>% 
    filter(fecha < pos_fecha, NDVI_smooth < umbral)
  
  # Si encontró días por debajo del umbral, el SOS es el día siguiente a la última caída.
  # Si no, por seguridad toma el día mínimo de la serie.
  if(nrow(dias_bajo_umbral) > 0) {
    sos_fecha <- max(dias_bajo_umbral$fecha) + days(1)
    sos_doy <- yday(sos_fecha)
  } else {
    sos_doy <- yday(min(datos_diarios$fecha))
  }
  
  # End of Season (EOS): Búsqueda HACIA ADELANTE desde el POS
  # Encontrar el primer día DESPUÉS del POS donde el NDVI cae por debajo del umbral
  fase_senescencia <- datos_diarios %>% filter(fecha > pos_fecha)
  eos_row <- fase_senescencia %>% filter(NDVI_smooth <= umbral) %>% slice(1)
  eos_doy <- ifelse(nrow(eos_row) > 0, yday(eos_row$fecha), yday(max(fase_senescencia$fecha)))
  

  # Length of Season (LOS)
  los <- eos_doy - sos_doy
  
  # 5. Extraer valores de estrés hídrico y vigor en la etapa crítica (POS)
  max_ndwi <- pos_row$NDWI_smooth
  max_evi <- max(datos_diarios$EVI_smooth)
  
  # Retornar una fila con los predictores calculados
  tibble(
    SOS_DOY = sos_doy,
    POS_DOY = pos_doy,
    EOS_DOY = eos_doy,
    LOS_dias = los,
    NDVI_max = pos_val,
    NDWI_en_POS = max_ndwi,
    EVI_max = max_evi
  )
}

# 6. Agrupar por parcela y mapear la función (Iteración limpia con dplyr)
cat("Suavizando curvas y calculando métricas fenológicas por parcela...\n")
metricas <- df %>%
  group_by(id_parcela) %>%
  group_modify(~ extraer_fenologia(.x)) %>%
  ungroup()

# 7. Guardar el dataset resultante
output_path <- "data/03_processed/04-r-metricas-fenologicas.csv"
write_csv(metricas, output_path)
cat("Métricas extraídas exitosamente en:", output_path, "\n")





