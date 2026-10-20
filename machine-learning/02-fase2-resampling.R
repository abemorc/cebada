# ==============================================================================
# FASE 2: Configuración del Resampling Espacial (KNN Distance Matching) CORREGIDA 2
# ==============================================================================

cat("\nConfigurando KNN Distance Matching Resampling...\n")

# Extraer SOLAMENTE la columna de geometría (sfc_POINT) de los centroides
puntos_prediccion <- st_geometry(st_centroid(df_pred_sf))

# 2.1 Instanciar el método de remuestreo con la pura geometría de los predpoints
resampling_knndm <- rsmp("spcv_knndm", folds = 5, predpoints = puntos_prediccion)

# 2.2 Instanciar el remuestreo explícitamente sobre nuestra Tarea Espacial
resampling_knndm$instantiate(task_cebada)

# 2.3 Validar cómo quedaron distribuidas las particiones (Folds)
cat("Resumen de las particiones geográficas (Train / Test):\n")
for (i in 1:5) {
  cat(sprintf("Fold %d: %d parcelas entrenamiento | %d parcelas prueba\n", 
              i, 
              length(resampling_knndm$train_set(i)), 
              length(resampling_knndm$test_set(i))))
}

resampling_knndm

# (Opcional) Ver mapa de particiones
library(mlr3viz)
library(ggplot2)
autoplot(resampling_knndm, task_cebada)