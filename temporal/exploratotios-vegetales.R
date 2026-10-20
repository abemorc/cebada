# Cargar librerías
library(tidyverse)
library(corrplot) # Para la visualización de la matriz

# 1. Cargar el dataset consolidado
df <- read_csv("data/03_processed/05-metricas-fenologicas-planet.csv")

# 2. Filtrar el conjunto de entrenamiento y seleccionar solo numéricas
datos_corr <- df %>%
  filter(conjunto == "ENTRENAMIENTO") %>%
  # Asegurar que no haya NAs en el rendimiento
  drop_na(rendimiento_t_ha) %>%
  select(
    doy_inicio, doy_pico, doy_fin, duracion_dias, 
    evi_max, evi_integral, lai_pico, vigor_emergencia_msavi, 
    heterogeneidad_espacial, tasa_senescencia, rendimiento_t_ha
  )

# 3. Calcular las matrices matemáticas
# Usamos "pairwise.complete.obs" por si quedó algún NA perdido en otra variable
matriz_pearson <- cor(datos_corr, use = "pairwise.complete.obs", method = "pearson")
matriz_spearman <- cor(datos_corr, use = "pairwise.complete.obs", method = "spearman")

# 4. Imprimir en consola la relación directa con el rendimiento (Spearman)
cat("--- Correlación de Spearman con el Rendimiento (t/ha) ---\n")
corr_rendimiento <- sort(matriz_spearman[, "rendimiento_t_ha"], decreasing = TRUE)
print(round(corr_rendimiento, 3))

# 5. Generar el Correlograma Visual
# Visualizamos Spearman porque capta mejor las relaciones no lineales comunes en agronomía
corrplot(matriz_spearman, 
         method = "color",          # Dibuja cuadros de color
         type = "lower",            # Muestra solo el triángulo inferior para no duplicar
         addCoef.col = "black",     # Imprime el valor numérico de la correlación dentro del cuadro
         number.cex = 0.7,          # Tamaño de la fuente de los números
         tl.col = "black",          # Color del texto de las variables
         tl.srt = 45,               # Rotación a 45 grados de las etiquetas
         diag = FALSE,              # Oculta la diagonal principal (siempre es 1 entre la misma variable)
         # Paleta de colores: Naranja (negativo) -> Blanco (cero) -> Azul (positivo)
         col = colorRampPalette(c("#E46726", "white", "#6D9EC1"))(200),
         title = "Matriz de Correlación Fenológica (Spearman)",
         mar = c(0,0,2,0))          # Ajuste de margen superior para que el título no se corte
