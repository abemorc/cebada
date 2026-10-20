01 limpieza datos raw

# Checkpoint de Proyecto: 

## 1. Resumen del Proyecto y Estado Actual
*   **Objetivo:** Desarrollar un modelo de Machine Learning espacial para estimar el rendimiento agrícola (`rendimiento_t_ha`) a nivel de parcela para el cultivo de cebada.
*   **Volumen de Datos:** 197 parcelas en total (estado de Hidalgo).
    *   **Conjunto de Entrenamiento:** 138 parcelas (con datos históricos de rendimiento conocidos).
    *   **Conjunto de Predicción:** 59 parcelas (sin etiquetas de rendimiento, objetivo del modelo).
*   **Hito actual:** La fase de ingesta, unión y limpieza de datos espaciales y tabulares base en R ha sido completada. El proyecto está listo para iniciar la fase de *Feature Engineering* y Modelado.

## 2. Fase 1 Completada: Limpieza y Preparación de Datos (R)
Se utilizó el paquete `sf` junto con `dplyr` y `janitor` para procesar los datos crudos.

**Archivos de Origen (Raw Data):**
*   `data/01_raw/Parcelas_Reto_AGC_CONJUNTO_70_30/Parcelas_Reto_AGC_CONJUNTO.shp`: Shapefile original con las geometrías. Venía con una dimensión Z vacía que causaba ruido.
*   `data/01_raw/ID_area_rendimiento_70_30_Reto_AgroCebada.csv`: Archivo tabular con el rendimiento e identificadores.

**Proceso de Limpieza Aplicado:**
1.  **Corrección Espacial:** Se importó el shapefile y se eliminó la dimensión Z vacía usando `st_zm()`, dejando las geometrías en 2D (XY) sobre el CRS WGS 84 (EPSG: 4326).
2.  **Integración (Join):** Se unió el vector espacial con el CSV tabular mediante un `left_join` utilizando las llaves `ID_POLIGON == ID_POLIGONO`.
3.  **Depuración de Columnas:** Se eliminaron columnas redundantes generadas en la unión (`AREA_HA`, `CONJUNTO.y`) y una columna "fantasma" (`X`) proveniente del CSV.
4.  **Estandarización de Texto:** Se unificó la variable `Cultivo` a mayúsculas ("CEBADA") para evitar duplicados por errores de captura. Se verificó la correcta ortografía de municipios y estados.
5.  **Formato de Variables:** Se aplicó `janitor::clean_names()` para convertir todos los nombres de columnas a formato *snake_case* (amigable para IA/ML). La columna de geometría se reubicó al final del dataset.

**Archivos Resultantes (Interim Data):**
*   **`data/02_interim/Parcelas_Reto_AGC_CONJUNTO_Unidas.geojson`**: Archivo principal. Contiene las geometrías unidas con los atributos limpios, listo para visualización o extracción espacial.
*   **`data/02_interim/Atributos_Parcelas_Limpias.csv`**: Archivo tabular puro. Se generó aplicando `st_drop_geometry()` para poder analizar los datos en librerías estándar de ML sin conflictos con el formato de lista espacial.


**Instrucción para el Asistente de IA:**
Basándote en este contexto, asume que los datos base ya están limpios en la ruta `02_interim`. Retoma el proyecto desde la fase de *Feature Engineering* (extracción de variables espaciales) o la configuración inicial del modelo de Machine Learning respetando las reglas de validación espacial y dimensionalidad mencionadas.


Checkpoint Fase 1.1 (Extracción GEE): Se configuró el script en /python/extraccion_series.py para iterar sobre los polígonos y descargar series temporales de NDVI, EVI y NDWI. La inclusión de NDWI se justificó para detectar el estrés hídrico de la canícula, y el EVI para evitar la saturación de verdor masivo provocado por fenotipos tardíos o maleza.

Checkpoint Fase 2 (Microtopografía): Se implementó un pipeline en R utilizando elevatr y terra proyectado en UTM 14N (EPSG:32614). Se extrajo la altitud media, la pendiente en grados y el Índice de Posición Topográfica (TPI) como proxy de exposición a heladas en sumideros térmicos y asfixia radicular, resolviendo espacialmente las fricciones agronómicas del Altiplano.


Checkpoint Fase 4 (Climatología Fenológica): Se implementó la extracción meteorológica de precipitación (CHIRPS) y temperatura (ERA5-Land). Mediante un mapeo dinámico en GEE, cada parcela fue evaluada exclusivamente durante su ventana biológica real (del SOS al EOS), capturando con total precisión el volumen de lluvia y el calor asimilado por la cebada, independientemente de cuándo fue sembrada.

Checkpoint Fase 5 (Ensamblaje Maestro): Se consolidó el feature engineering espacial en un único dataset procesado (/data/03_processed/dataset_maestro). El conjunto integra la biomasa fenológica (Sentinel-2), estrés climático termodinámico (CHIRPS/ERA5-Land), resiliencia edafológica de "tepetate" (SoilGrids) y exposición topográfica (Copernicus DEM), transformando polígonos ciegos en matrices multidimensionales listas para el entrenamiento del Random Forest.




