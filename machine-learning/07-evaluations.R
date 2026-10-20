# ==============================================================================
# GUARDADO DE MODELOS Y GENERACIÓN DE GRÁFICAS PARA EL REPORTE
# ==============================================================================
library(sf)
library(dplyr)
library(ggplot2)

cat("Guardando el modelo entrenado y los resultados del AutoTuner...\n")

# # 1. Crear directorio para modelos si no existe
# dir.create("models", showWarnings = FALSE)

# 2. Guardar el AutoTuner completo (Contiene el modelo final y el historial de tuning)
# Se guarda como .rds (R Data Serialization)
saveRDS(at_rf_final, "models/rf_autotuner_final-test.rds")
saveRDS(at_rf, "models/rf_autotuner-test.rds")


# Si en el futuro necesitas cargar el modelo sin volver a entrenar, solo haces:
# mi_modelo_cargado <- readRDS("models/rf_autotuner_final.rds")

# 3. Guardar el objeto de resultados del Benchmark original (el que reportaremos)
# Esto es útil si quieres extraer más métricas después sin correr el benchmark de 5 minutos
# Descomenta la siguiente línea si aún tienes el objeto 'bmr' de la Fase 4 original en memoria
# saveRDS(bmr, "models/benchmark_resultados.rds")

cat("Modelos guardados exitosamente en la carpeta 'models/'.\n")

# ==============================================================================
# GRÁFICAS PARA EL APARTADO DE "ANEXOS" (ggplot2)
# ==============================================================================
cat("\nGenerando gráficas para el reporte...\n")

# A) Gráfica 1: Importancia de Variables (Feature Importance)
# Dado que usamos ranger, podemos extraer la importancia si configuramos el learner para calcularla.
# Como el AutoTuner ya entrenó el modelo final, extraemos el modelo base así:
modelo_base_rf <- at_rf_final$learner$model
modelo_base_rf

# Si ranger calculó la importancia (depende de la configuración por defecto), podemos graficarla:
if (!is.null(modelo_base_rf$variable.importance)) {
  importancia <- data.frame(
    Variable = names(modelo_base_rf$variable.importance),
    Importancia = as.numeric(modelo_base_rf$variable.importance)
  ) %>%
    arrange(Importancia) %>%
    # Tomar el Top 15 para no saturar la gráfica
    tail(15) 
  
  grafico_importancia <- ggplot(importancia, aes(x = reorder(Variable, Importancia), y = Importancia)) +
    geom_bar(stat = "identity", fill = "steelblue") +
    coord_flip() +
    theme_minimal() +
    labs(
      title = "Importancia de Variables (Top 15)",
      subtitle = "Modelo Random Forest - Reto AgroCebada 2026",
      x = "Variable Biofísica / Climática",
      y = "Nivel de Importancia (Reducción de Varianza)"
    )
  
  # Guardar la gráfica en alta calidad para el PDF
  ggsave("data/04_results/grafico_importancia.png", grafico_importancia, width = 8, height = 6, dpi = 300)
  cat("Gráfico de importancia de variables guardado.\n")
} else {
  cat("Nota: El modelo ranger no fue configurado con 'importance' activa. Omite esta gráfica.\n")
}

# B) Gráfica 2: Histograma Comparativo de Rendimientos (Real vs Predicho)
# Esto es excelente para la sección de Resultados y Discusión
df_real <- st_drop_geometry(st_read("data/02_interim/02-parcelas-cebada-rend.geojson", quiet = TRUE)) %>%
  filter(conjunto == "ENTRENAMIENTO") %>%
  select(rendimiento = rendimiento_t_ha) %>%
  mutate(Tipo = "Real (Train)")

df_pred <- st_drop_geometry(st_read("data/04_results/04-predicciones-cebada.geojson", quiet = TRUE)) %>%
  select(rendimiento = rendimiento_t_ha) %>%
  mutate(Tipo = "Predicho (Test)")

df_comparativo <- bind_rows(df_real, df_pred)

grafico_distribucion <- ggplot(df_comparativo, aes(x = rendimiento, fill = Tipo)) +
  geom_density(alpha = 0.5) +
  theme_minimal() +
  scale_fill_manual(values = c("Real (Train)" = "#2c3e50", "Predicho (Test)" = "#e74c3c")) +
  labs(
    title = "Distribución del Rendimiento Agrícola",
    subtitle = "Comparación entre la densidad observada y las predicciones generadas",
    x = "Rendimiento (t/ha)",
    y = "Densidad",
    fill = "Conjunto de Datos"
  )

ggsave("data/04_results/grafico_distribucion.png", grafico_distribucion, width = 8, height = 5, dpi = 300)
cat("Gráfico de distribución guardado.\n")