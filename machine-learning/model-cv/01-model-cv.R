
# ==============================================================================
# SCRIPT MAESTRO FINAL: RETO AGROCEBADA 2026
# ==============================================================================
library(mlr3pipelines)
library(mlr3learners)
library(mlr3tuning)
library(future)
library(lgr)
library(sf)
library(dplyr)
library(ggplot2)
library(readr)
library(mlr3spatial)
library(mlr3spatiotempcv)



# 1.1 Cargar el Dataset Maestro
ruta_maestro <- "data/03_processed/dataset_maestro.geojson"
parcelas_sf <- st_read(ruta_maestro, quiet = TRUE)

# Asegurar que estamos en el sistema métrico UTM 14N para el clustering
parcelas_sf <- st_transform(parcelas_sf, crs = 32614)

# 1.2 Derivación de Coordenadas y Clustering (Macro-Zonas)
# Extraer el centroide exacto de cada parcela y guardar X e Y como columnas numéricas
coords <- st_coordinates(st_centroid(parcelas_sf))
parcelas_sf$x <- coords[, "X"]
parcelas_sf$y <- coords[, "Y"]

# Agrupar espacialmente usando K-Means con k=3 para identificar las zonas principales
set.seed(42) # Semilla para que los clusters siempre sean idénticos
parcelas_sf$zona_cluster <- as.factor(kmeans(coords, centers = 3)$cluster)

# Separar el dataset utilizando la columna de la variable objetivo.
df_train_sf <- parcelas_sf %>% filter(!is.na(rendimiento_t_ha))
df_pred_sf  <- parcelas_sf %>% filter(is.na(rendimiento_t_ha))

cat("Parcelas de entrenamiento (Con rendimiento):", nrow(df_train_sf), "\n")
cat("Parcelas a predecir (Sin rendimiento):", nrow(df_pred_sf), "\n")

# 1.3 Creación del TaskRegrST
# mlr3 requiere un data.frame tabular (no un objeto 'sf'), por lo que soltamos 
# la lista de geometrías, pero conservamos las columnas 'x' e 'y'.
df_train_tabular <- df_train_sf %>% st_drop_geometry()

# Instanciar la Tarea de Regresión Espacial
task_cebada <- as_task_regr_st(
  x = df_train_tabular,
  target = "rendimiento_t_ha",         # Tu variable a predecir
  id = "prediccion_cebada_fira",
  coordinate_names = c("x", "y"), # Columnas espaciales
  crs = 32614                     # EPSG UTM Zona 14N
)

# Proteger la columna identificadora. 
# Al asignarle el rol 'name', mlr3 la conserva para identificar las filas, 
# pero le prohíbe a los algoritmos (Random Forest) usarla como predictor.
task_cebada$set_col_roles("id_poligon", roles = "name")

# Imprimir un resumen en consola para validar que mlr3 leyó todo correctamente
print(task_cebada)




# 1.4 Limpieza de features (Ajuste de Roles)
cols_ignorar <- c("cultivo", "estado", "municipio", "conjunto")

# Remover el rol "feature" de estas columnas
task_cebada$set_col_roles(cols_ignorar, remove_from = "feature")

cat("\nVariables predictoras finales (Features):", length(task_cebada$feature_names), "\n")
print(task_cebada$feature_names)


task_cebada


#----------



library(progressr)

# Habilitar las barras de progreso en la consola
handlers(global = TRUE)
handlers("progress")

lgr::get_logger("mlr3")$set_threshold("warn")
lgr::get_logger("bbotk")$set_threshold("warn")

cat("\n--- INICIANDO CONFIGURACIÓN DEL MODELO PRODUCTIVO ---\n")

# 1. Configurar Random Forest con importancia de variables y 1000 árboles
lrn_rf <- lrn("regr.ranger", 
              predict_type = "response",
              importance = "permutation", 
              num.trees = 1000)           

graph_rf <- po("encode", method = "one-hot") %>>% lrn_rf
glrn_rf <- as_learner(graph_rf)
glrn_rf$id <- "Random_Forest_Final"

# 2. Espacio de Búsqueda ampliado (mtry hasta 15)
search_space_rf <- ps(
  regr.ranger.mtry = p_int(lower = 2, upper = 15),
  regr.ranger.min.node.size = p_int(lower = 1, upper = 10)
)

# 3. Configurar AutoTuner (Enfoque de Interpolación: 5 Folds Aleatorios, 50 Intentos)
rsmp_inner <- rsmp("cv", folds = 5) 
at_rf_final <- AutoTuner$new(
  learner = glrn_rf, 
  resampling = rsmp_inner, 
  measure = msr("regr.rmse"),
  search_space = search_space_rf, 
  terminator = trm("evals", n_evals = 1000), 
  tuner = tnr("random_search")
)

# 4. Entrenamiento Multicore
cat("Afinando y entrenando el modelo definitivo con 50 evaluaciones...\n")
plan("multisession")
set.seed(42)
at_rf_final$train(task_cebada)
plan("sequential")

cat("\nHiperparámetros óptimos seleccionados:\n")
print(at_rf_final$tuning_instance$result_learner_param_vals)

# ==============================================================================
# PREDICCIONES Y GUARDADO
# ==============================================================================
cat("\n--- GENERANDO PREDICCIONES Y EXPORTANDO ---\n")

df_pred_tabular <- st_drop_geometry(df_pred_sf)
predicciones_finales <- at_rf_final$predict_newdata(newdata = df_pred_tabular)

df_pred_sf_final <- df_pred_sf
df_pred_sf_final$rendimiento_t_ha <- predicciones_finales$response

dir.create("data/04_results", showWarnings = FALSE)
dir.create("models", showWarnings = FALSE)

write_sf(df_pred_sf_final, "data/04_results/04-predicciones-cebada-final.geojson", delete_dsn = TRUE)
write_csv(st_drop_geometry(df_pred_sf_final), "data/04_results/04-predicciones-cebada-final.csv")
saveRDS(at_rf_final, "models/rf_autotuner_final.rds")

cat("Predicciones y modelo (.rds) guardados exitosamente.\n")

# ==============================================================================
# GENERACIÓN DE GRÁFICAS PARA EL REPORTE
# ==============================================================================
cat("\n--- GENERANDO GRÁFICAS PARA ANEXOS ---\n")

# A) Gráfica de Importancia de Variables
modelo_base_rf <- at_rf_final$learner$model

if (!is.null(modelo_base_rf$variable.importance)) {
  importancia <- data.frame(
    Variable = names(modelo_base_rf$variable.importance),
    Importancia = as.numeric(modelo_base_rf$variable.importance)
  ) %>%
    arrange(Importancia) %>%
    tail(15) 
  
  grafico_importancia <- ggplot(importancia, aes(x = reorder(Variable, Importancia), y = Importancia)) +
    geom_bar(stat = "identity", fill = "#2c3e50") +
    coord_flip() +
    theme_minimal(base_size = 14) +
    labs(
      title = "Top 15 Variables de Mayor Impacto Predictivo",
      subtitle = "Importancia por Reducción de Varianza (Permutation)",
      x = "Variable Biofísica / Climática",
      y = "Importancia Relativa"
    )
  
  ggsave("data/04_results/grafico_importancia.png", grafico_importancia, width = 9, height = 6, dpi = 300, bg = "white")
  cat("Gráfico de importancia guardado en 04_results.\n")
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

ggsave("data/04_results/grafico_distribucion.png", grafico_distribucion, width = 9, height = 6, dpi = 300, bg = "white")
cat("Gráfico de distribución guardado en 04_results.\n\n¡FLUJO COMPLETADO!")