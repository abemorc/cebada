Fase 1: Inicialización y Construcción de la Tarea Espacial
1.1. División del Dataset Maestro: Cargar el archivo GeoJSON consolidado y separarlo lógicamente en dos conjuntos utilizando la variable de rendimiento: el conjunto de entrenamiento/entrenamiento-cruzado (138 parcelas con datos de toneladas por hectárea) y el conjunto objetivo (59 parcelas con rendimiento nulo/faltante).
1.2. Derivación de Coordenadas y Clustering: Extraer explícitamente las coordenadas X e Y de las geometrías y ejecutar un algoritmo de K-Means (k=3) para crear la variable categórica zona_cluster, capturando la macro-zona a la que pertenece cada parcela.
1.3. Creación del TaskRegrST: Instanciar la Tarea Espacial en mlr3 utilizando las 138 observaciones. Definir explícitamente el rendimiento como target, las variables extraídas como features, las columnas X/Y como coordenadas espaciales, y asignar el rol de name o ignore a los IDs (como id_poligon) para que el algoritmo no intente usarlos como predictores.

Fase 2: Configuración del Resampling (El Núcleo Espacial)
2.1. Extracción de Puntos Objetivo (Prediction Grid): Ailar las coordenadas X e Y de las 59 parcelas que no tienen rendimiento.
2.2. Instanciación de spcv_knndm: Crear el objeto de resampling rsmp("spcv_knndm", folds = 5) y alimentarlo con la Tarea Espacial y las coordenadas de las 59 parcelas objetivo. El algoritmo internamente calculará la función de distribución acumulada empírica (ECDF) de las distancias para asegurar que los folds simulen el desafío geográfico final.
2.3. Auditoría Espacial (Opcional pero recomendada): Generar un gráfico con autoplot(resampling, task) para validar visualmente en el mapa cómo mlr3 distribuyó las particiones.

Fase 3: Ingeniería de Pipelines y Espacios de Búsqueda
3.1. Definición de Learners Base: Instanciar los tres algoritmos a comparar: regr.ranger (Random Forest), regr.xgboost (XGBoost) y regr.glmnet (Elastic Net como línea base penalizada).
3.2. Construcción de Grafos (Pipelines): Utilizar mlr3pipelines para asegurar que cada modelo reciba los datos en el formato correcto. Por ejemplo, XGBoost y GLMNet requieren un paso previo de codificación de variables categóricas (como zona_cluster) a variables dummy/one-hot (po("encode")), y GLMNet requiere escalado espacial (po("scale")).
3.3. Configuración de Hiperparámetros (ParamSet): Definir los rangos de búsqueda. Para Random Forest: mtry (variables por corte) y min.node.size. Para XGBoost: eta (tasa de aprendizaje) y max_depth (profundidad para evitar sobreajuste en 138 filas).

Fase 4: Autotuning y Ejecución del Benchmark
4.1. Envoltura en AutoTuners: Combinar los Learners (o Pipelines), los espacios de búsqueda y una métrica de error absoluta (msr("regr.mae") o msr("regr.rmse")) dentro de la función AutoTuner. Esto asegura que la selección de hiperparámetros se realice de forma anidada y segura, sin contaminar la validación cruzada externa.
4.2. Diseño del Experimento: Crear el benchmark_grid() cruzando la Tarea Espacial (TaskRegrST), los tres AutoTuners y el esquema de evaluación espacial (spcv_knndm).
4.3. Ejecución y Comparación: Correr el benchmark() y analizar los resultados estadísticos (media de error y varianza espacial) para coronar empíricamente al algoritmo más robusto.

Fase 5: Inferencia y Generación del Entregable
5.1. Entrenamiento Final: Extraer el pipeline del modelo ganador (con sus mejores hiperparámetros globales) y entrenarlo utilizando la totalidad de las 138 parcelas de entrenamiento.
5.2. Predicción de Objetivos: Pasar el subconjunto de las 59 parcelas sin rendimiento a la función predict() del modelo ganador.
5.3. Ensamblaje de Resultados: Unir las predicciones de rendimiento generadas con el GeoJSON original de las 59 parcelas.
5.4. Exportación: Guardar el archivo final predictivo para su análisis o visualización en plataformas de mapeo.
