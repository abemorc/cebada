# Carpeta: RawData (Datos Crudos, Variables Espaciales y Documentación)

## Descripción General
Este directorio es el núcleo de datos del proyecto para el **Reto AgroCebada 2026**. Contiene los conjuntos de datos crudos proporcionados para predecir el rendimiento agrícola de cebada (toneladas por hectárea) en la región central de México (Hidalgo, Puebla, Tlaxcala)[cite: 1, 2]. 

La carpeta almacena geometrías de parcelas, series temporales rasterizadas de clima, modelos de elevación, datasets tabulares con índices satelitales precalculados y toda la documentación técnica de respaldo[cite: 2].

---

## 1. Documentación Técnica y Metadatos (Archivos Raíz)

Estos archivos son fundamentales para comprender la naturaleza de los datos y el sustento matemático de las variables generadas:

* **`Diccionario_de_indices_satelitales.docx`**[cite: 2]: Un glosario textual que define los acrónimos y el propósito de los diversos Índices de Vegetación (VIs) utilizados en el proyecto (ej. NDVI, EVI, LAI, SAVI).
* **`Ecuaciones_indices_AgroCebada_FIRA_2026.pdf`**[cite: 2]: Documento de respaldo matemático que contiene las fórmulas algorítmicas exactas mostrando cómo se calculó cada índice a partir de las bandas espectrales de los satélites (Landsat/Sentinel-2).
* **`Descripcion_general_variables_DataSet.docx`**[cite: 2]: Detalla la metadata explicativa de cada columna presente en los archivos `.csv` del proyecto, sirviendo como guía humana para el diccionario de datos.
* **`metadatos_RawData.txt`**[cite: 2]: Bitácora autogenerada (vía consola de R) que contiene el esquema interno (tipos de datos, resúmenes estadísticos `summary()`, nombres exactos de columnas `glimpse()`) de los datos geoespaciales y tabulares de esta carpeta. **Agentes de IA y analistas humanos deben revisar este archivo para entender la estructura de los datos sin necesidad de cargar los archivos en memoria.**
* **`inventario-archivos.csv`**[cite: 2]: Un archivo tabular previamente generado que sirve como índice rápido de todos los archivos y rutas de esta ubicación.

---

## 2. Archivos Tabulares Base (Target y Predictores Satelitales)

* **`ID_area_rendimiento_70_30_Reto_AgroCebada.csv`**[cite: 2]: **Archivo crítico.** Contiene la variable objetivo a predecir.
  * *Contenido:* `ID_POLIGONO` (llave foránea), `AREA_HA` (área en hectáreas), `RENDIMIENTO_T_HA` (rendimiento en ton/ha, con valores `NA` para el conjunto de prueba) y la columna `CONJUNTO` (Entrenamiento/Predicción)[cite: 1]. Existe una columna vacía `...5` que debe descartarse en limpieza[cite: 1].
* **`Conjunto_datos_BASICO_AgroCebada2026.csv`**[cite: 2]: Dataset tabular que almacena series temporales con estadísticas pre-extraídas de índices satelitales (NDVI, EVI, etc.) agrupadas por parcela (`ID_POLIGONO`) y `fecha_captura`, utilizando sensores como Landsat y Sentinel-2[cite: 1].
* **`Conjunto_datos_PRO_AgroCebada.csv`**[cite: 2]: Una versión extendida, procesada o enriquecida del dataset satelital básico.

---

## 3. Datos Geoespaciales Vectoriales (Geometrías)

* **Directorio: `Parcelas_Reto_AGC_CONJUNTO_70_30/`**[cite: 2]
  * **Objetivo:** Contiene la delimitación geográfica exacta de las 197 parcelas objetivo.
  * **Composición:** Formato Shapefile (`.shp`, `.dbf`, `.prj`, `.shx`, `.cpg`)[cite: 2].
  * **Detalle Técnico:** Las geometrías vienen por defecto en formato tridimensional (`POLYGON Z`). Poseen el identificador único `ID_POLIGON` que funciona como llave primaria[cite: 1]. El sistema de coordenadas es WGS 84[cite: 1].
  * *Respaldo:* El archivo comprimido `Parcelas_Reto_AGC_CONJUNTO_70_30.zip` es el origen de estos archivos[cite: 2].

---

## 4. Datos Geoespaciales Raster (Imágenes de Variables Continuas)

Estos directorios contienen series de datos rasterizados (`.tif`) que se deben cruzar espacialmente con las parcelas para extraer variables (Zonal Statistics).

* **Topografía (INEGI CEM 4.0):**
  * **Directorio:** `Reto_AgroCebada_Topografia_INEGI_CEM4/`[cite: 2]
  * **Contenido:** Contiene un archivo de instrucciones (`LEEME.txt`), un inventario CSV y dos archivos raster clave de resolución 120m[cite: 2]: 
    * `Elevacion_INEGI_CEM4_120m.tif` (Metros sobre el nivel del mar).
    * `Pendiente_INEGI_CEM4_120m_grados.tif` (Inclinación del terreno).
  * *Respaldo:* Archivo `Reto_AgroCebada_Topografia_INEGI_CEM4.zip`[cite: 2].

* **Clima - Precipitación Mensual (CHIRPS):**
  * **Directorio:** `Reto_AgroCebada_CHIRPS_Precipitacion_2022_2025/`[cite: 2]
  * **Contenido:** Subcarpetas estructuradas por año (2022 a 2025). Cada año tiene 12 archivos `.tif` (ej. `PREC_2022_01.tif`) representando la precipitación mensual acumulada[cite: 2]. Incluye `LEEME.txt` e `inventario_...csv`[cite: 2].
  * *Respaldo:* Archivos `Reto_AgroCebada_CHIRPS_Precipitacion_2022_2025.zip` y una variante recortada `Reto_AgroCebada_Temperatura_2022_2025_RECORTADA_CHIRPS.zip`[cite: 2].

* **Clima - Temperaturas (CHIRTS-ERA5):**
  * **Directorio:** `Reto_AgroCebada_Temperatura_2022_2025/`[cite: 2]
  * **Contenido:** Dividido en dos subcarpetas climáticas: `Tmax/` (Temperatura máxima) y `Tmin/` (Temperatura mínima)[cite: 2].
  * Estructura idéntica a CHIRPS: organizada por años (2022-2025) y meses en archivos `.tif` (ej. `Tmax_2023_04.tif`)[cite: 2]. Incluye archivo de notas `LEEME_.txt`[cite: 2].

---

## 5. Flujo de Unión (Join) y Preprocesamiento Recomendado

**Aviso Multilingüe:** El entorno de exploración base es R (sf, terra, tidyverse), pero para automatizar flujos de Machine Learning o preprocesamiento masivo, se tiene libertad para usar Python (geopandas, rasterio, scikit-learn, xarray).

### Pasos Lógicos Clave para Integración de Datos:
1. **Normalización Espacial:** Importar el Shapefile vectorial (`Parcelas_Reto...shp`) y forzar su geometría de `POLYGON Z` a geometría bidimensional (2D) para asegurar compatibilidad en librerías espaciales.
2. **Merge de Variable Objetivo (Target):** Ejecutar un cruce relacional (*Left Join*) entre el Shapefile y el archivo `ID_area_rendimiento...csv`. 
   * **Llave Espacial:** `ID_POLIGON`
   * **Llave Tabular:** `ID_POLIGONO`
3. **Extracción de Variables (Zonal Stats):** Utilizando los polígonos del resultado anterior como "moldes", iterar sobre los cientos de archivos `.tif` (Raster) de CHIRPS, Tmax, Tmin y CEM 4.0. Se debe extraer una métrica de resumen (ej. valor promedio del píxel) para cada parcela temporal y estáticamente.

*Sugerencia de la lógica básica en código (R):*
```r
library(sf)
library(dplyr)

# 1. Leer y limpiar a 2D
sfParcelas <- read_sf("Ruta_al_Shapefile.shp") |> st_zm()

# 2. Leer objetivo
dfRendimiento <- read_csv("Ruta_a_rendimiento.csv")

# 3. Unir
dataset_unificado <- sfParcelas |> 
  left_join(dfRendimiento, by = c("ID_POLIGON" = "ID_POLIGONO"))
