library(mlr3pipelines)
library(mlr3tuning)
library(paradox) 
library(mlr3learners) # <-- La línea clave para habilitar ranger, xgboost y glmnet

cat("\n==============================================================================\n")
cat("FASE 3: Construcción de Pipelines y Espacios de Búsqueda (ParamSets)\n")
cat("==============================================================================\n")

# 3.1 Instanciar los Learners Base
# lrn_rf     <- lrn("regr.ranger", predict_type = "response")
# 3.1 Instanciar Learner Base de Random Forest (CON IMPORTANCIA Y MÁS ÁRBOLES)
lrn_rf <- lrn("regr.ranger", 
              predict_type = "response",
              importance = "permutation", # <--- Habilita el cálculo de importancia
              num.trees = 1000)
lrn_xgb    <- lrn("regr.xgboost", predict_type = "response")
lrn_glmnet <- lrn("regr.glmnet", predict_type = "response")

# 3.2 Construcción de los Pipelines (Grafos de preprocesamiento)

# A) Random Forest Pipeline
graph_rf <- po("encode", method = "one-hot") %>>% lrn_rf
glrn_rf <- as_learner(graph_rf)
glrn_rf$id <- "Random_Forest"

# B) XGBoost Pipeline
graph_xgb <- po("encode", method = "one-hot") %>>% lrn_xgb
glrn_xgb <- as_learner(graph_xgb)
glrn_xgb$id <- "XGBoost"

# C) Elastic Net (Línea Base Lineal) Pipeline
graph_glmnet <- po("encode", method = "one-hot") %>>% po("scale") %>>% lrn_glmnet
glrn_glmnet <- as_learner(graph_glmnet)
glrn_glmnet$id <- "Elastic_Net"

# 3.3 Definición de Espacios de Búsqueda (ParamSets) para Autotuning
cat("\nConfigurando hiperparámetros...\n")

# 3.3 Espacio de Búsqueda (ParamSet) ampliado
search_space_rf <- ps(
  regr.ranger.mtry = p_int(lower = 2, upper = 15), # <--- Ampliado de 10 a 15
  regr.ranger.min.node.size = p_int(lower = 1, upper = 10)
)

# search_space_rf <- ps(
#   regr.ranger.mtry = p_int(lower = 2, upper = 10),
#   regr.ranger.min.node.size = p_int(lower = 1, upper = 10)
# )

search_space_xgb <- ps(
  regr.xgboost.eta = p_dbl(lower = 0.01, upper = 0.2),
  regr.xgboost.max_depth = p_int(lower = 3, upper = 6),
  regr.xgboost.nrounds = p_int(lower = 50, upper = 300)
)

search_space_glmnet <- ps(
  regr.glmnet.alpha = p_dbl(lower = 0, upper = 1),
  regr.glmnet.s = p_dbl(lower = 0.001, upper = 10)
)

cat("Pipelines (GraphLearners) y ParamSets creados exitosamente.\n")


search_space_rf
