



cat("\n--- EXTRACCIÓN DE IMPORTANCIA DE VARIABLES (CORREGIDA) ---\n")
library(dplyr)
library(ggplot2)

# 1. Extraer el algoritmo base navegando a través del pipeline (GraphLearner)
rf_learner <- at_rf_final$learner$base_learner()

# (Camino alternativo por si usas una versión antigua de mlr3pipelines)
if (is.null(rf_learner)) {
  rf_learner <- at_rf_final$learner$graph_model$pipeops$regr.ranger$learner
}

# 2. Extraer el vector de importancia usando el método oficial de mlr3
importancia_vector <- rf_learner$importance()
importancia_vector
# 3. Graficar si el vector existe
if (!is.null(importancia_vector) && length(importancia_vector) > 0) {
  
  # Convertir el vector nombrado a un DataFrame para ggplot
  importancia_df <- data.frame(
    Variable = names(importancia_vector),
    Importancia = as.numeric(importancia_vector)
  ) %>%
    arrange(Importancia) %>%
    tail(15) # Seleccionar solo el Top 15 para un gráfico limpio
  
  grafico_importancia <- ggplot(importancia_df, aes(x = reorder(Variable, Importancia), y = Importancia)) +
    geom_bar(stat = "identity", fill = "#2c3e50") +
    coord_flip() +
    theme_minimal(base_size = 14) +
    labs(
      title = "Top 15 Variables de Mayor Impacto Predictivo",
      subtitle = "Importancia por Reducción de Varianza (Permutation)",
      x = "Variable Biofísica / Climática",
      y = "Importancia Relativa"
    )
  
  # Mostrar en la consola/visor
  print(grafico_importancia)
  
  # Guardar en alta calidad
  ggsave("data/04_results/grafico_importancia.png", grafico_importancia, width = 9, height = 6, dpi = 300, bg = "white")
  cat("\n¡Gráfico de importancia generado y guardado exitosamente en 04_results!\n")
  
} else {
  cat("\nError: No se encontró el vector de importancia. Revisa la configuración del modelo base.\n")
}








# B) Gráfica de Distribución (Densidad)
df_real <- st_drop_geometry(st_read("data/02_interim/02-parcelas-cebada-rend.geojson", quiet = TRUE)) %>%
  filter(conjunto == "ENTRENAMIENTO") %>%
  select(rendimiento = rendimiento_t_ha) %>%
  mutate(Tipo = "Real (Entrenamiento)")

df_pred <- st_drop_geometry(df_pred_sf_final) %>%
  select(rendimiento = rendimiento_t_ha) %>%
  mutate(Tipo = "Estimado (Predicción)")

df_comparativo <- bind_rows(df_real, df_pred)

grafico_distribucion <- ggplot(df_comparativo, aes(x = rendimiento, fill = Tipo)) +
  geom_density(alpha = 0.6, color = NA) +
  theme_minimal(base_size = 14) +
  scale_fill_manual(values = c("Real (Entrenamiento)" = "#34495e", "Estimado (Predicción)" = "#e67e22")) +
  labs(
    title = "Distribución del Rendimiento Agrícola: Real vs Estimado",
    subtitle = "Comparación de densidades para validar la estabilidad de interpolación",
    x = "Rendimiento (t/ha)",
    y = "Densidad",
    fill = "Conjunto"
  ) +
  theme(legend.position = "bottom")

grafico_distribucion
grafico_importancia
grafica_importancia

ggsave("data/04_results/grafico_distribucion.png", grafico_distribucion, width = 9, height = 6, dpi = 300, bg = "white")
cat("Gráfico de distribución guardado en 04_results.\n\n¡FLUJO COMPLETADO!")
