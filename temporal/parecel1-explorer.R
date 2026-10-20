# Cargar librerías necesarias
library(tidyverse)
library(lubridate)

# 1. Cargar el archivo
df <- read_csv("data/01_raw/Conjunto_datos_PRO_AgroCebada_order.csv")

# 2. Limpieza y preparación para el polígono AGC_001
parcela_001 <- df %>%
  # Filtrar el polígono de interés
  filter(ID_POLIGONO == "AGC_001") %>%
  # Eliminar días con alta nubosidad (umbral estricto del 20%)
  filter(porcentaje_nubosidad <= 20) %>%
  # Convertir la fecha a formato Date (Día/Mes/Año)
  mutate(fecha = dmy(fecha_captura)) %>%
  # Ordenar cronológicamente
  arrange(fecha)

# 3. Transformar los datos a formato largo para graficar múltiples índices
parcela_larga <- parcela_001 %>%
  select(fecha, 
         NDVI = ndvi_promedio, 
         EVI = evi_promedio, 
         MSAVI = msavi_promedio) %>%
  # Pivotar para que ggplot pueda facetar por índice
  pivot_longer(cols = c(NDVI, EVI, MSAVI), 
               names_to = "Indice", 
               values_to = "Valor")

# 4. Generar la gráfica comparativa
ggplot(parcela_larga, aes(x = fecha, y = Valor, color = Indice)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2, alpha = 0.7) +
  # Crear un panel separado para cada índice con su propia escala
  facet_wrap(~ Indice, ncol = 1, scales = "free_y") +
  scale_x_date(date_breaks = "1 month", date_labels = "%b %Y") +
  labs(
    title = "Fenología Satelital: Polígono AGC_001",
    subtitle = "Comparativa de índices ópticos (PlanetScope)",
    x = "Fecha",
    y = "Valor del Índice"
  ) +
  theme_minimal() +
  theme(
    legend.position = "none",
    strip.text = element_text(face = "bold", size = 12),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )




# Cargar librerías
library(tidyverse)
library(lubridate)

# 1. Preparar los datos limpios para el polígono AGC_001
# df <- read_csv("Conjunto_datos_PRO_AgroCebada_order.csv")

parcela_001 <- df %>%
  filter(ID_POLIGONO == "AGC_001", porcentaje_nubosidad <= 20) %>%
  mutate(fecha = dmy(fecha_captura),
         # Convertir la fecha a una variable numérica continua para la regresión
         dia_numerico = as.numeric(fecha)) %>% 
  filter(!is.na(evi_promedio)) %>%
  arrange(fecha)

# 2. Ajustar el modelo de regresión local (LOESS)
# El parámetro 'span' controla qué tan suave es la curva. Valores entre 0.3 y 0.45 
# son ideales para no sobreajustar el ruido pero tampoco perder los picos reales.
modelo_loess <- loess(evi_promedio ~ dia_numerico, data = parcela_001, span = 0.3)

# 3. Interpolar la curva para obtener una predicción diaria
secuencia_dias <- data.frame(
  dia_numerico = seq(min(parcela_001$dia_numerico), max(parcela_001$dia_numerico), by = 1)
)

# Predecir los valores de EVI para cada día del calendario
secuencia_dias$evi_suavizado <- predict(modelo_loess, newdata = secuencia_dias)
secuencia_dias$fecha <- as_date(secuencia_dias$dia_numerico)

# 4. Encontrar matemáticamente el día de máximo verdor (Pico Fenológico)
dia_pico <- secuencia_dias %>%
  filter(evi_suavizado == max(evi_suavizado, na.rm = TRUE))

cat("El pico máximo de EVI se alcanzó el:", as.character(dia_pico$fecha), "\n")
cat("Valor EVI suavizado en el pico:", round(dia_pico$evi_suavizado, 3), "\n")

# 5. Visualizar los datos crudos vs la curva teórica
ggplot() +
  # Puntos reales observados por el satélite
  geom_point(data = parcela_001, aes(x = fecha, y = evi_promedio), 
             color = "gray50", alpha = 0.6, size = 2) +
  # Curva fenológica suavizada
  geom_line(data = secuencia_dias, aes(x = fecha, y = evi_suavizado), 
            color = "forestgreen", linewidth = 1.2) +
  # Línea vertical marcando el pico exacto
  geom_vline(xintercept = as.numeric(dia_pico$fecha), 
             linetype = "dashed", color = "darkred") +
  annotate("text", x = dia_pico$fecha + days(5), y = min(parcela_001$evi_promedio), 
           label = paste("Pico:", dia_pico$fecha), color = "darkred", hjust = 0) +
  labs(
    title = "Curva Fenológica Suavizada (LOESS) - Polígono AGC_001",
    subtitle = "Filtrado de ruido atmosférico y detección de máxima actividad fotosintética",
    x = "Fecha",
    y = "EVI (Índice de Vegetación Mejorado)"
  ) +
  theme_minimal()



