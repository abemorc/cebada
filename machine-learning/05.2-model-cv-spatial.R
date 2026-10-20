# ==============================================================================
# FASE 4 Y 5: BENCHMARK Y MODELO FINAL (100% spcv_coords)
# ==============================================================================
library(mlr3spatiotempcv)
library(mlr3learners)
library(mlr3tuning)
library(future)
library(lgr)
library(sf)
library(readr)

# Silenciar logs
lgr::get_logger("mlr3")$set_threshold("warn")
lgr::get_logger("bbotk")$set_threshold("warn")

cat("\n==============================================================================\n")
cat("FASE 4: BENCHMARK CON VALIDACIÓN CRUZADA ESPACIAL ANIDADA (K-Means Coords)\n")
cat("==============================================================================\n")

# 1. Definir los remuestreos espaciales (Ambos basados en K-Means de Coordenadas)

# A) Bucle Interno (Tuning): 4 bloques espaciales para encontrar hiperparámetros
rsmp_inner_coords <- rsmp("spcv_coords", folds = 4)

# B) Bucle Externo (Benchmark): 5 bloques espaciales para evaluar el rendimiento
rsmp_outer_coords <- rsmp("spcv_coords", folds = 5)
rsmp_outer_coords$instantiate(task_cebada)

# 2. Configurar los AutoTuners con el Bucle Interno
medida <- msr("regr.rmse")
tuner <- tnr("random_search")
terminator <- trm("evals", n_evals = 50)

at_rf <- AutoTuner$new(
  learner = glrn_rf, resampling = rsmp_inner_coords, measure = medida,
  search_space = search_space_rf, terminator = terminator, tuner = tuner
)
at_rf$id <- "RF_SpatialTuning"

at_xgb <- AutoTuner$new(
  learner = glrn_xgb, resampling = rsmp_inner_coords, measure = medida,
  search_space = search_space_xgb, terminator = terminator, tuner = tuner
)
at_xgb$id <- "XGBoost_SpatialTuning"

at_glmnet <- AutoTuner$new(
  learner = glrn_glmnet, resampling = rsmp_inner_coords, measure = medida,
  search_space = search_space_glmnet, terminator = terminator, tuner = tuner
)
at_glmnet$id <- "ElasticNet_SpatialTuning"

# 3. Ejecutar el Benchmark
cat("Ejecutando Benchmark Espacial Anidado... (Utilizando todos los núcleos)\n")

design <- benchmark_grid(
  tasks = task_cebada,
  learners = list(at_rf, at_xgb, at_glmnet),
  resamplings = rsmp_outer_coords
)

plan("multisession")
set.seed(42)

library(progressr)
handlers(global = TRUE)
handlers("progress") # Esto habilita la barra de progreso en la consola

bmr_coords <- benchmark(design, store_models = TRUE)
plan("sequential")

# 4. Reporte de Métricas Finales
cat("\n================ MÉTRICAS DE EVALUACIÓN (RIGOR ESPACIAL K-MEANS) ================\n")
resultados_coords <- bmr_coords$aggregate(list(
  msr("regr.rmse"), 
  msr("regr.mae"), 
  msr("regr.rsq")
))
print(resultados_coords[, c("learner_id", "regr.rmse", "regr.mae", "regr.rsq")])


cat("\n==============================================================================\n")
cat("FASE 5: ENTRENAMIENTO DEL MODELO FINAL Y PREDICCIONES\n")
cat("==============================================================================\n")

# Para el modelo final productivo, configuramos el Random Forest (asumiendo victoria)
# para que sintonice sus parámetros usando 5 pliegues espaciales sobre todo el dataset.
rsmp_final_coords <- rsmp("spcv_coords", folds = 5)
terminator <- trm("evals", n_evals = 1500)

at_rf_final <- AutoTuner$new(
  learner = glrn_rf, 
  resampling = rsmp_final_coords, 
  measure = medida,
  search_space = search_space_rf, 
  terminator = terminator, 
  tuner = tuner
)

cat("\nAfinando y entrenando el modelo definitivo con todo el dataset...\n")
plan("multisession")
set.seed(42)


library(progressr)
handlers(global = TRUE)
handlers("progress") #

at_rf_final$train(task_cebada)
plan("sequential")

cat("Hiperparámetros óptimos seleccionados:\n")
print(at_rf_final$tuning_instance$result_learner_param_vals)

# Generar predicciones para las 59 parcelas objetivo
cat("\nGenerando predicciones geoespaciales finales...\n")
df_pred_tabular <- st_drop_geometry(df_pred_sf)
predicciones_finales <- at_rf_final$predict_newdata(newdata = df_pred_tabular)

df_pred_tabular %>% glimpse()
predicciones_finales

# Asignar resultados
df_pred_sf_final <- df_pred_sf
df_pred_sf_final$rendimiento_t_ha <- predicciones_finales$response

# Guardar los archivos de la entrega final
write_sf(df_pred_sf_final, "resultados/predicciones-cebada-spcv-coords.geojson", delete_dsn = TRUE)
write_csv(st_drop_geometry(df_pred_sf_final), "resultados/predicciones-cebada-spcv-coords.csv")

cat("\n¡Benchmark y Predicciones completados exitosamente con spcv_coords!\n")

