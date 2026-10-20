library(tidyverse)
library(lubridate)

# 1. Cargar y preparar los datos iniciales
df_raw <- read_csv("data/01_raw/Conjunto_datos_PRO_AgroCebada_order.csv")

datos_limpios <- df_raw %>%
  filter(porcentaje_nubosidad <= 20) %>%
  mutate(fecha = dmy(fecha_captura),
         dia_numerico = as.numeric(fecha),
         doy = yday(fecha)) %>% # yday obtiene el "Día del Año" (1-365)
  filter(!is.na(evi_promedio)) %>%
  arrange(ID_POLIGONO, fecha)

# 2. Agrupar los datos por polígono en una lista
lista_parcelas <- datos_limpios %>%
  group_split(ID_POLIGONO)

# 3. Definir la función de extracción fenológica
extraer_metricas <- function(df_parcela) {
  
  # Si hay muy pocos datos limpios para hacer la curva, devolver NAs
  if(nrow(df_parcela) < 10) {
    return(tibble(
      ID_POLIGONO = unique(df_parcela$ID_POLIGONO),
      evi_max_val = NA, doy_pico = NA, 
      doy_inicio = NA, doy_fin = NA, duracion_dias = NA
    ))
  }
  
  # A. Ajustar el modelo LOESS
  # Usamos span = 0.3 como base para suavizar
  modelo <- tryCatch(
    loess(evi_promedio ~ dia_numerico, data = df_parcela, span = 0.3),
    error = function(e) return(NULL)
  )
  
  if(is.null(modelo)) return(NULL)
  
  # B. Interpolar para todos los días del periodo
  seq_dias <- tibble(
    dia_numerico = seq(min(df_parcela$dia_numerico), max(df_parcela$dia_numerico), by = 1)
  )
  seq_dias$evi_smooth <- predict(modelo, newdata = seq_dias)
  seq_dias$fecha <- as_date(seq_dias$dia_numerico)
  seq_dias$doy <- yday(seq_dias$fecha)
  
  # C. Calcular el Pico (Peak of Season)
  fila_pico <- seq_dias %>% filter(evi_smooth == max(evi_smooth, na.rm = TRUE)) %>% slice(1)
  evi_max_val <- fila_pico$evi_smooth
  doy_pico <- fila_pico$doy
  fecha_pico <- fila_pico$fecha
  
  

  # ... (Código previo igual: A, B y C para calcular el Pico) ...
  
  # D. Calcular el Inicio de Temporada (SOS) - CORREGIDO
  # 1. Ventana agronómica: ignorar todo lo que pase antes de mayo (doy 120)
  # ya que no hay siembra de temporal en invierno en el Altiplano.
  dias_pre_pico <- seq_dias %>% filter(fecha <= fecha_pico, doy > 90)
  
  if(nrow(dias_pre_pico) == 0) {
     doy_inicio <- NA
  } else {
    # 2. Encontrar el "valle" (mínimo) justo antes del gran crecimiento
    min_pre_pico <- min(dias_pre_pico$evi_smooth, na.rm = TRUE)
    amplitud_pre <- evi_max_val - min_pre_pico
    
    # Subimos el umbral al 30% de la amplitud para evitar falsos positivos por maleza temprana
    umbral_sos <- min_pre_pico + (amplitud_pre * 0.3) 
    
    fila_inicio <- dias_pre_pico %>% 
      filter(evi_smooth >= umbral_sos) %>% 
      slice(1)
    
    doy_inicio <- ifelse(nrow(fila_inicio) > 0, fila_inicio$doy, min(dias_pre_pico$doy))
    fecha_inicio <- ifelse(nrow(fila_inicio) > 0, fila_inicio$fecha, min(dias_pre_pico$fecha))
  }
  
  # E. Calcular el Fin de Temporada (EOS) - CORREGIDO
  # El mismo principio: limitamos la búsqueda a los meses posteriores al pico
  dias_post_pico <- seq_dias %>% filter(fecha >= fecha_pico)
  
  min_post_pico <- min(dias_post_pico$evi_smooth, na.rm = TRUE)
  amplitud_post <- evi_max_val - min_post_pico
  
  # Usamos un umbral del 30% en la caída para marcar la cosecha
  umbral_eos <- min_post_pico + (amplitud_post * 0.3)
  
  fila_fin <- dias_post_pico %>% 
    filter(evi_smooth <= umbral_eos) %>% 
    slice(1)
  
  doy_fin <- ifelse(nrow(fila_fin) > 0, fila_fin$doy, max(dias_post_pico$doy))
  fecha_fin <- as_date(ifelse(nrow(fila_fin) > 0, fila_fin$fecha, max(dias_post_pico$fecha)))

  # ... (Código posterior igual: F. Calcular duración y retornar el tibble) ...
  # F. Calcular la duración (Length of Season)
  duracion_dias <- as.numeric(as_date(fecha_fin) - as_date(fecha_inicio))
  
  # Devolver una fila consolidada
  tibble(
    ID_POLIGONO = unique(df_parcela$ID_POLIGONO),
    evi_max_val = round(evi_max_val, 3),
    doy_pico = doy_pico,
    doy_inicio = doy_inicio,
    doy_fin = doy_fin,
    duracion_dias = duracion_dias
  )
}

# 4. Aplicar la función iterativamente a todas las parcelas
# map_dfr ejecuta la función para cada elemento de la lista y une los resultados en un solo dataframe
df_metricas_fenologicas <- map_dfr(lista_parcelas, extraer_metricas)

# Ver las primeras filas de nuestro nuevo set de variables
head(df_metricas_fenologicas)


write_csv(df_metricas_fenologicas, 'data/03_processed/04.1-metricas-fenologicas.csv')
