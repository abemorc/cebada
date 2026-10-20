# ==============================================================================
# FASE 5: Producción - Modelo Final y Predicciones de Parcelas Objetivo
# ==============================================================================

cat("\n==============================================================================\n")
cat("FASE 5: Entrenamiento del Modelo Final (Producción) y Predicciones\n")
cat("==============================================================================\n")

# 1. Entrenar el modelo final usando Random Forest sobre TODA la base de datos
cat("Entrenando Random Forest con las 138 parcelas...\n")
set.seed(42)






library(future)

# 1. Configurar un AutoTuner más exhaustivo (50 evaluaciones) con CV estándar
rsmp_inner <- rsmp("cv", folds = 5) 
medida <- msr("regr.rmse")
tuner <- tnr("random_search")
terminator <- trm("evals", n_evals = 50) # <--- Aumentado a 50 intentos

at_rf <- AutoTuner$new(
  learner = glrn_rf, 
  resampling = rsmp_inner, 
  measure = medida,
  search_space = search_space_rf, 
  terminator = terminator, 
  tuner = tuner
)

# 2. Entrenar usando todos tus núcleos
cat("\nAfinando y entrenando el modelo final (50 evaluaciones)...\n")
plan("multisession")
set.seed(42)
at_rf$train(task_cebada)
plan("sequential")

cat("\nHiperparámetros óptimos seleccionados:\n")
print(at_rf$tuning_instance$result_learner_param_vals)


cat("\nHiperparámetros óptimos seleccionados por el modelo final:\n")
print(at_rf$tuning_instance$result_learner_param_vals)

# 2. Preparar los datos nuevos (Las 59 parcelas objetivo de df_pred_sf)
# mlr3 espera un data.frame tabular para $predict_newdata()
df_pred_sf
df_pred_tabular <- st_drop_geometry(df_pred_sf)

# 3. Realizar las predicciones
cat("\nGenerando estimaciones de rendimiento para las 59 parcelas objetivo...\n")
predicciones_rf <- at_rf$predict_newdata(newdata = df_pred_tabular)
predicciones_rf

# 4. Asignar las predicciones al objeto espacial original
# Remplazamos los valores NA en la columna rendimiento_t_ha con la salida del modelo
df_pred_sf$rendimiento_t_ha <- predicciones_rf$response
df_pred_sf

# Imprimir un resumen estadístico de las predicciones

cat("\nResumen del rendimiento estimado (Toneladas / Hectárea):\n")
print(summary(df_pred_sf$rendimiento_t_ha))

# 5. Exportar los resultados finales
# NOTA: Asegúrate de que la carpeta "data/04_results" exista en tu directorio de trabajo.
# dir.create("data/04_results", showWarnings = FALSE)

library(readr)
write_sf(df_pred_sf, "resultados/predicciones-cebada.geojson")
write_csv(st_drop_geometry(df_pred_sf), "resultados/predicciones-cebada.csv")

cat("\n¡Flujo completado! Resultados guardados en la carpeta 04_results.\n")






