# ==============================================================================
# FASE 4: AutoTuning y Benchmark Espacial
# ==============================================================================
library(lgr)
library(future) # Para la paralelización

# Reducir mensajes en consola
lgr::get_logger("mlr3")$set_threshold("warn")
lgr::get_logger("bbotk")$set_threshold("warn")

cat("\nConfigurando AutoTuners...\n")

rsmp_inner <- rsmp("cv", folds = 3)
medida     <- msr("regr.rmse")
tuner      <- tnr("random_search")
terminator <- trm("evals", n_evals = 20)

at_rf <- AutoTuner$new(
  learner = glrn_rf, resampling = rsmp_inner, measure = medida,
  search_space = search_space_rf, terminator = terminator, tuner = tuner
)
at_rf$id <- "AutoTune_RF"

at_xgb <- AutoTuner$new(
  learner = glrn_xgb, resampling = rsmp_inner, measure = medida,
  search_space = search_space_xgb, terminator = terminator, tuner = tuner
)
at_xgb$id <- "AutoTune_XGBoost"

at_glmnet <- AutoTuner$new(
  learner = glrn_glmnet, resampling = rsmp_inner, measure = medida,
  search_space = search_space_glmnet, terminator = terminator, tuner = tuner
)
at_glmnet$id <- "AutoTune_ElasticNet"

cat("Diseñando el Benchmark Grid...\n")
design <- benchmark_grid(
  tasks = task_cebada,
  learners = list(at_rf, at_xgb, at_glmnet),
  resamplings = resampling_knndm
)

cat("Ejecutando Benchmark Espacial Anidado... (Utilizando paralelización)\n")

# 1. ENCENDER LA PARALELIZACIÓN
plan("multisession") 
set.seed(42)

# 2. EJECUTAR (Aquí R usará múltiples núcleos)
bmr <- benchmark(design, store_models = TRUE)

# 3. APAGAR LA PARALELIZACIÓN (Liberar RAM)
plan("sequential")

cat("\n================ RESULTADOS DEL BENCHMARK ================\n")
resultados <- bmr$aggregate(list(
  msr("regr.rmse"), 
  msr("regr.mae"), 
  msr("regr.rsq")
))

print(resultados[, c("learner_id", "regr.rmse", "regr.mae", "regr.rsq")])

resultados %>% str
