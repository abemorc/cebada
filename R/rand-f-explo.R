# Cargar librerías necesarias
library(tidyverse)
library(randomForest) 
library(Metrics) # Para calcular RMSE y MAE

# 1. Cargar el dataset consolidado
df <- read_csv("data/03_processed/05-metricas-fenologicas-planet.csv")

# 2. Filtrar los datos y definir predictoras
datos_entrenamiento <- df %>% 
  filter(conjunto == "ENTRENAMIENTO") %>%
  drop_na(rendimiento_t_ha)

variables_predictoras <- c(
  "doy_inicio", "doy_pico", "doy_fin", "duracion_dias", 
  "evi_max", "evi_integral", "lai_pico", "vigor_emergencia_msavi", 
  "heterogeneidad_espacial", "tasa_senescencia"
)

# 3. Partición de Validación (Hold-out 80/20)
set.seed(2026) # Semilla para reproducir los mismos resultados
indice_train <- sample(1:nrow(datos_entrenamiento), 0.8 * nrow(datos_entrenamiento))

train_data <- datos_entrenamiento[indice_train, ]
test_data  <- datos_entrenamiento[-indice_train, ]

# 4. Ajustar el modelo Random Forest
cat("Ajustando el modelo Random Forest...\n")
modelo_rf <- randomForest(
  formula = as.formula(paste("rendimiento_t_ha ~", paste(variables_predictoras, collapse = " + "))),
  data = train_data,
  ntree = 500,           # Número de árboles de decisión
  mtry = 3,              # Número de variables muestreadas en cada división (aprox. p/3)
  importance = TRUE      # Requerido para analizar qué variable importa más
)

# Imprimir el resumen del modelo (te mostrará el error Out-Of-Bag)
print(modelo_rf) 

# 5. Evaluación de Precisión en el conjunto Test (20%)
predicciones_test <- predict(modelo_rf, newdata = test_data)

# Calcular métricas de error
error_rmse <- rmse(test_data$rendimiento_t_ha, predicciones_test)
error_mae <- mae(test_data$rendimiento_t_ha, predicciones_test)

cat("\n--- Métricas de Error (Conjunto de Prueba 20%) ---\n")
cat("RMSE (Error Cuadrático Medio):", round(error_rmse, 3), "toneladas/ha\n")
cat("MAE (Error Absoluto Medio):", round(error_mae, 3), "toneladas/ha\n")

# 6. Extracción y Visualización de Importancia de Variables
importancia_vars <- as.data.frame(importance(modelo_rf)) %>%
  rownames_to_column("Variable") %>%
  arrange(desc(`%IncMSE`))

grafica_importancia <- ggplot(importancia_vars, aes(x = reorder(Variable, `%IncMSE`), y = `%IncMSE`)) +
  geom_col(fill = "#2c3e50", width = 0.7) +
  coord_flip() +
  labs(
    title = "Importancia de Variables (Feature Importance)",
    subtitle = "Incremento del Error Cuadrático Medio (%IncMSE) si se omite la variable",
    x = "Métricas Fenológicas",
    y = "Importancia (%IncMSE)"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

# Mostrar la gráfica
print(grafica_importancia)

# 7. (Fase Final) Predecir la producción para las parcelas sin rendimiento conocido
datos_prediccion <- df %>% filter(conjunto == "PREDICCION")
predicciones_nuevas <- predict(modelo_rf, newdata = datos_prediccion)

datos_prediccion$rendimiento_t_ha_PREDICHO <- predicciones_nuevas