# Plan de Acción: Extracción de Variables para Modelado Predictivo de Cebada

Este documento detalla el flujo de trabajo paso a paso para la obtención, procesamiento e integración de las variables necesarias para el modelo predictivo de rendimiento de cebada en el Altiplano Central. 

## 1. Configuración del Entorno y Preparación de Datos Base
- [ ] **1.1. Estructura de directorios:** Crear la estructura base del proyecto (`R/`, `python/`, `data/raw/`, `data/processed/`).
- [ ] **1.2. Configuración de entornos:** 
    - Inicializar entorno Python con `uv` (instalar `geopandas`, `earthengine-api`, `xarray`, `rasterio`).
    - Configurar entorno R (instalar `sf`, `terra`, `soilDB`).
- [ ] **1.3. Carga y validación del GeoJSON:** Leer el archivo de polígonos, verificar el sistema de coordenadas (CRS) y separar lógicamente en *datasets* de "ENTRENAMIENTO" y "PREDICCION".

## 2. Extracción de Variables Edafológicas (Vía API/WCS)
- [ ] **2.1. Script de conexión a SoilGrids:** Desarrollar el script (recomendado en R usando `soilDB` o llamadas directas al WCS) para consultar las capas a 250m.
- [ ] **2.2. Descarga de propiedades físicas:** Extraer para cada polígono las variables `bdod` (densidad aparente) y texturas (`sand`, `silt`, `clay`) a distintas profundidades (ej. 0-5cm, 5-15cm, 15-30cm).
- [ ] **2.3. Cálculo de Capacidad de Retención:** Extraer `wv0033` y `wv1500` para derivar la Capacidad de Agua Disponible (AWC).
- [ ] **2.4. Agregación espacial:** Calcular el promedio intra-parcelario de estas variables para cada `id_poligon` y guardar en `data/processed/suelos.csv`.

## 3. Extracción de Variables Satelitales y Climáticas (Google Earth Engine API)
- [ ] **3.1. Autenticación y setup GEE:** Configurar credenciales de Earth Engine en el script de Python (`ee.Initialize()`).
- [ ] **3.2. Extracción de Geomorfología (Copernicus DEM):** 
    - Extraer elevación y derivar pendiente para cada polígono.
    - Calcular el Índice Topográfico de Humedad (TWI) e identificar "sumideros".
- [ ] **3.3. Extracción de Forzamientos Meteorológicos (ERA5-Land / CHIRPS):**
    - Definir las ventanas temporales (ciclo vegetativo: ej. mayo a septiembre).
    - Extraer precipitación diaria acumulada (CHIRPS).
    - Extraer temperaturas extremas (mínimas/máximas) y calcular Grados-Día de Crecimiento (ERA5-Land).
- [ ] **3.4. Extracción de Fenología Óptica y Radar (Sentinel-1 y 2):**
    - Construir series temporales del índice NDVI o EVI (Sentinel-2) filtrando nubes.
    - Extraer series de retrodispersión VV/VH (Sentinel-1) para biomasa y estructura.
- [ ] **3.5. Extracción de Fluorescencia (TROPOMI SIF):** Extraer métricas de SIF durante las semanas críticas de floración y llenado de grano.
- [ ] **3.6. Reducción espacial y temporal:** Generar estadísticas zonales (media, desviación estándar) por parcela y exportar a `data/processed/clima_satelite.csv`.

## 4. Recopilación de Variables Socio-Productivas (Manual / Web Scraping)
- [ ] **4.1. Estadísticas de SIAP/SIACON:** Descargar datos históricos (archivos CSV/Excel) de rendimientos y fechas de siembra para los municipios clave (Apan, Almoloya, Chignahuapan, etc.).
- [ ] **4.2. Datos de Adopción Tecnológica (SNICS):** Recopilar estimaciones de uso de semilla certificada para el ciclo de estudio.
- [ ] **4.3. Limpieza y estandarización:** Homologar los nombres de los municipios y generar un *dataset* tabular a nivel municipal en `data/processed/socioeconomico.csv`.

## 5. Integración y Construcción de la Matriz de Diseño
- [ ] **5.1. Unión de datasets (Merge):** Realizar un *join* (usando `id_poligon` y municipio) de los archivos `suelos.csv`, `clima_satelite.csv` y `socioeconomico.csv` con el GeoJSON original.
- [ ] **5.2. Control de calidad y limpieza (QA/QC):** Identificar y tratar valores nulos (NaN), *outliers* extremos o errores de extracción.
- [ ] **5.3. Exportación de Matriz Final:** Guardar la matriz tabular completa (`matriz_modelado_cebada.csv` / `.parquet`) lista para la fase de entrenamiento de *Machine Learning*.