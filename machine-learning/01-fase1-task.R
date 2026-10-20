library(tidyverse)
library(sf)
library(mlr3)
library(mlr3spatiotempcv) # Extensión crítica para la validación cruzada espacial

# ==============================================================================
# FASE 1: Inicialización y Construcción de la Tarea Espacial
# ==============================================================================

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
# IMPORTANTE: Cambia "rendimiento" por el nombre exacto de tu columna de toneladas/ha.
df_train_sf <- parcelas_sf %>% filter(!is.na(rendimiento))
df_pred_sf  <- parcelas_sf %>% filter(is.na(rendimiento))

cat("Parcelas de entrenamiento (Con rendimiento):", nrow(df_train_sf), "\n")
cat("Parcelas a predecir (Sin rendimiento):", nrow(df_pred_sf), "\n")

# 1.3 Creación del TaskRegrST
# mlr3 requiere un data.frame tabular (no un objeto 'sf'), por lo que soltamos 
# la lista de geometrías, pero conservamos las columnas 'x' e 'y'.
df_train_tabular <- df_train_sf %>% st_drop_geometry()

# Instanciar la Tarea de Regresión Espacial
task_cebada <- as_task_regr_st(
  x = df_train_tabular,
  target = "rendimiento",         # Tu variable a predecir
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
