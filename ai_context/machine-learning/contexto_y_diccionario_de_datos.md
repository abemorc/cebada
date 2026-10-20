# Contexto y Diccionario de Datos: Modelo Espacial de Rendimiento de Cebada Maltera

## 1. Contexto del Proyecto
Este proyecto tiene como objetivo entrenar un modelo de Machine Learning (Random Forest) para predecir espacialmente el rendimiento de la **cebada maltera** cultivada bajo régimen de temporal (secano) en el **Altiplano Central Mexicano** (cuenca productora de Tlaxcala, Hidalgo y Puebla).

La agricultura en esta región se caracteriza por una altísima variabilidad en el rendimiento debido a fricciones sociológicas y climáticas. Los retrasos en la entrega de créditos obligan a siembras tardías, empujando el ciclo del cultivo hacia el otoño e invierno. Esto expone a la planta a un severo estrés hídrico terminal (canícula) y a heladas prematuras que abortan el llenado del grano. 

Para resolver la falta de registros históricos de manejo a nivel de parcela, se ha construido un **Dataset Maestro Multivariado** utilizando teledetección (GEE), motores geoespaciales y APIs de la nube, extrayendo *proxies* fisiológicos que explican la interacción de la planta con su entorno.

## 2. Estructura del Conjunto de Datos
*   **Datos de Entrenamiento (Etiquetados):** El conjunto consta de **197 parcelas (polígonos)** que cuentan con registros reales de rendimiento en toneladas (`rendimiento`). Este será el dataset de entrenamiento y validación (Train/Test).
*   **Datos de Inferencia (Para Predecir):** Una vez entrenado, el modelo no se aplicará sobre polígonos, sino sobre rasters continuos de toda la región productora, pixel por pixel, utilizando las mismas covariables espaciales extraídas aquí.
*   **Temporalidad:** Ciclo agrícola Primavera-Verano / Otoño-Invierno 2025.

---

## 3. Diccionario de Variables (Features)

### A. Identificadores y Variable Objetivo (Target)
*   **`id_poligon`**: Identificador único alfanumérico de la parcela.
*   **`rendimiento`**: (Variable Target - *Y*) Rendimiento final de la cebada maltera, típicamente expresado en toneladas por hectárea (t/ha).

### B. Métricas Fenológicas (Dinámica Biológica - Sentinel 2)
Extraídas mediante el suavizado Savitzky-Golay de la curva temporal de vegetación. Cuantifican el calendario biológico real de la parcela.
*   **`doy_inicio` (Start of Season):** Día del año de inicio de temporada. Funciona como proxy de la **fecha de siembra**. Valores altos indican retrasos en el crédito/insumos, empujando la cosecha hacia fechas de alto riesgo de heladas.
*   **`doy_pico` (Peak of Season):** Día del año en que la planta alcanzó su biomasa foliar máxima (etapa de espigado/floración).
*   **`doy_fin` (End of Season):** Día del año en que el cultivo maduró fisiológicamente y se secó (proxy de cosecha).
*   **`duracion_dias` (Length of Season):** Duración total del ciclo vegetativo en días.
*   **`evi_max`**: Pico máximo absoluto de verdor (biomasa).
*   **`EVI_max`**: Vigor máximo corregido por saturación, útil para diferenciar fenotipos de altísimo rendimiento.
y otras que se han agregado:

evi_max	evi_integral	lai_pico	vigor_emergencia_msavi	heterogeneidad_espacial	tasa_senescencia


### C. Métricas Topográficas (Relieve - Copernicus DEM)
Definen la exposición del cultivo a riesgos meteorológicos localizados (microclimas).
*   **`elevacion`**: Altitud sobre el nivel del mar en metros. Relacionado con el gradiente térmico base de la parcela.
*   **`pendiente_grados`**: Inclinación del terreno. A mayor pendiente, menor infiltración de agua y mayor riesgo de erosión del horizonte fértil.
*   **`tpi_depresiones`**: Índice de Posición Topográfica. 
    *   *Valores negativos:* Indican sumideros cóncavos (ej. Tecocomulco). En estas zonas se estanca el agua (asfixia radicular) y se asienta el aire frío (congelamiento de la espiga).
    *   *Valores positivos:* Lomas y crestas con buen drenaje pero propensas a sequía rápida.

### D. Métricas Edafológicas (Sustrato - SoilGrids v2.0)
Describen la capacidad física del suelo para proteger al cultivo durante los periodos sin lluvia. Extraídas a profundidades estratégicas (15-30 cm para raíz primaria, 30-60 cm para subsuelo).
*   **`bdod_15_30cm` / `bdod_30_60cm`**: Densidad Aparente (Bulk Density). Proxy matemático de la capa endurecida conocida como **"tepetate"**. Valores altos indican compactación severa que impide el desarrollo radicular.
*   **`clay_15_30cm`**: Porcentaje de arcilla. A mayor arcilla, mayor retención hídrica pero también mayor riesgo de anoxia.
*   **`sand_15_30cm`**: Porcentaje de arena. A mayor arena, mayor infiltración pero pérdida rápida de humedad.
*   **`silt_15_30cm`**: Porcentaje de limo.

### E. Forzamiento Climático (Termodinámica - CHIRPS y ERA5-Land)
Estas variables fueron extraídas *dinámicamente*, midiendo el clima **exclusivamente** durante los días en que el cultivo estuvo vivo en cada parcela (desde su SOS hasta su EOS).
*   **`precip_acumulada_mm`**: Lluvia total recibida por la planta durante todo su ciclo biológico.
*   **`temp_media_c`**: Temperatura promedio experimentada (°C).
*   **`temp_max_absoluta_c`**: Pico de calor más alto registrado en el ciclo. Temperaturas extremas en floración causan esterilidad del polen.
*   **`gdd_acumulado`**: Grados-Día de Crecimiento (Temp Base 5°C). Mide la "energía térmica" acumulada, esencial para que el grano logre el peso hectolítrico exigido por la industria maltera.
*   **`radiacion_acumulada_mj`**: Radiación solar total incidente (Megajoules/m2). El combustible real de la fotosíntesis; compensa la posible falta de sol en años extremadamente nublados.