library(tidyverse)
library(lubridate)

# 1. Cargar y preparar los datos iniciales
df_raw <- read_csv("data/01_raw/Conjunto_datos_PRO_AgroCebada_order.csv")

datos_limpios <- df_raw %>%
  filter(porcentaje_nubosidad <= 20) %>%
  mutate(fecha = dmy(fecha_captura),
         dia_numerico = as.numeric(fecha),
         doy = yday(fecha)) %>% 
  filter(!is.na(evi_promedio)) %>%
  arrange(ID_POLIGONO, fecha)

lista_parcelas <- datos_limpios %>% group_split(ID_POLIGONO)

# 2. Función actualizada con variables avanzadas
extraer_metricas_completas <- function(df_parcela) {
  
  if(nrow(df_parcela) < 10) return(NULL) # Ignorar parcelas sin suficientes datos
  
  # A. Ajuste LOESS e Interpolación
  modelo <- tryCatch(
    loess(evi_promedio ~ dia_numerico, data = df_parcela, span = 0.2),
    error = function(e) return(NULL)
  )
  if(is.null(modelo)) return(NULL)
  
  seq_dias <- tibble(
    dia_numerico = seq(min(df_parcela$dia_numerico), max(df_parcela$dia_numerico), by = 1)
  )
  seq_dias$evi_smooth <- predict(modelo, newdata = seq_dias)
  seq_dias$fecha <- as_date(seq_dias$dia_numerico)
  seq_dias$doy <- yday(seq_dias$fecha)
  
  # B. Pico Máximo (POS)
  fila_pico <- seq_dias %>% filter(evi_smooth == max(evi_smooth, na.rm = TRUE)) %>% slice(1)
  evi_max_val <- fila_pico$evi_smooth
  fecha_pico <- fila_pico$fecha
  doy_pico <- fila_pico$doy
  
  # calcular el treshold de 0.2
  # C. Inicio de Temporada (SOS) - Restringido a temporal (mayo en adelante)(100)
  dias_pre <- seq_dias %>% filter(fecha <= fecha_pico, doy > 100)
  if(nrow(dias_pre) == 0) return(NULL)
  
  min_pre <- min(dias_pre$evi_smooth, na.rm = TRUE)
  umbral_sos <- min_pre + ((evi_max_val - min_pre) * 0.2)
  
  fila_inicio <- dias_pre %>% filter(evi_smooth >= umbral_sos) %>% slice(1)
  fecha_inicio <- ifelse(nrow(fila_inicio) > 0, fila_inicio$fecha, min(dias_pre$fecha))
  doy_inicio <- yday(as_date(fecha_inicio))
  
  # D. Fin de Temporada (EOS)
  dias_post <- seq_dias %>% filter(fecha >= fecha_pico)
  min_post <- min(dias_post$evi_smooth, na.rm = TRUE)
  umbral_eos <- min_post + ((evi_max_val - min_post) * 0.2)
  
  fila_fin <- dias_post %>% filter(evi_smooth <= umbral_eos) %>% slice(1)
  fecha_fin <- as_date(ifelse(nrow(fila_fin) > 0, fila_fin$fecha, max(dias_post$fecha)))
  doy_fin <- yday(fecha_fin)
  
  # ---------------------------------------------------------
  # E. CÁLCULO DE VARIABLES AVANZADAS PARA MACHINE LEARNING
  # ---------------------------------------------------------
  
  # 1. Integral Fenológica (Área bajo la curva del EVI)
  integral_evi <- sum(seq_dias$evi_smooth[seq_dias$fecha >= as_date(fecha_inicio) & 
                                            seq_dias$fecha <= fecha_fin], na.rm = TRUE)
  
  # 2. Heterogeneidad Espacial (Promedio de la desviación estándar en la etapa pico)
  ventana_pico <- df_parcela %>% filter(fecha >= (fecha_pico - days(15)) & fecha <= (fecha_pico + days(15)))
  heterogeneidad_ndvi <- ifelse(nrow(ventana_pico) > 0, mean(ventana_pico$ndvi_std, na.rm = TRUE), NA)
  
  # 3. Máximo de Estructura de Dosel (LAI máximo en la etapa de espigado)
  ventana_lai <- df_parcela %>% filter(fecha >= (fecha_pico - days(10)) & fecha <= (fecha_pico + days(10)))
  lai_pico <- ifelse(nrow(ventana_lai) > 0, max(ventana_lai$lai_promedio, na.rm = TRUE), NA)
  
  # 4. Vigor de Emergencia (MSAVI promedio en los primeros 25 días)
  ventana_emergencia <- df_parcela %>% filter(fecha >= as_date(fecha_inicio) & fecha <= (as_date(fecha_inicio) + days(25)))
  vigor_msavi_temprano <- ifelse(nrow(ventana_emergencia) > 0, mean(ventana_emergencia$msavi_promedio, na.rm = TRUE), NA)
  
  # 5. Tasa de Senescencia (Caída del EVI por día tras el pico)
  dias_bajada <- as.numeric(fecha_fin - fecha_pico)
  tasa_secado <- ifelse(dias_bajada > 0, (evi_max_val - umbral_eos) / dias_bajada, NA)
  
  # Devolver el registro estructurado
  tibble(
    ID_POLIGONO = unique(df_parcela$ID_POLIGONO),
    doy_inicio = doy_inicio,
    doy_pico = doy_pico,
    doy_fin = doy_fin,
    duracion_dias = as.numeric(fecha_fin - as_date(fecha_inicio)),
    evi_max = round(evi_max_val, 3),
    evi_integral = round(integral_evi, 2),
    lai_pico = round(lai_pico, 3),
    vigor_emergencia_msavi = round(vigor_msavi_temprano, 3),
    heterogeneidad_espacial = round(heterogeneidad_ndvi, 4),
    tasa_senescencia = round(tasa_secado, 4)
  )
}

# 3. Ejecutar y consolidar
dataset_entrenamiento <- map_dfr(lista_parcelas, extraer_metricas_completas)

# Ver el resultado enriquecido
head(dataset_entrenamiento)

dfrend <- read_csv('data/02_interim/02-parecelas-rend-atributos.csv')

dataset_entrenamiento <- dataset_entrenamiento %>% 
  left_join(dfrend, by = join_by(ID_POLIGONO == id_poligon))



write_csv(dataset_entrenamiento, 'data/03_processed/01-metricas-fenologicas.csv')

