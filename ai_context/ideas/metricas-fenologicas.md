# Estrategia de Modelado: Extracción de Fenología Satelital para Predicción de Rendimiento Agrícola


**Restricciones y estado de los datos:**
* Se cuenta con **150 parcelas** de entrenamiento.
* Se conoce la **ubicación espacial** (polígonos) y el **rendimiento final** (cosecha) de cada parcela.
* **Limitación Crítica:** No se cuenta con metadatos de manejo agrícola. Específicamente, **se desconocen las fechas de siembra y cosecha** de cada parcela.

## 2. La Hipótesis Agronómica
Existe una fuerte sospecha basada en la literatura agronómica local de que **la fecha de siembra es un factor determinante en el rendimiento final**. Las parcelas sembradas tardíamente probablemente tienen un menor rendimiento debido a que no aprovechan de manera óptima la ventana de radiación solar y el régimen de lluvias del temporal. 

Para que el Random Forest pueda aprender este patrón, necesita conocer el calendario de cada parcela. Dado que no existe registro tabular de esto, se requiere aplicar ingeniería de características (Feature Engineering) para descubrir estas fechas de forma retroactiva.

## 3. La Solución Propuesta: Fenología de Superficie (Land Surface Phenology)
La estrategia consiste en utilizar series de tiempo de imágenes satelitales (Sentinel-2) para reconstruir la "película" del desarrollo vegetativo de cada parcela y extraer sus métricas fenológicas mediante análisis de curvas. Al observar cómo evoluciona el Índice de Vegetación de Diferencia Normalizada (NDVI) a lo largo del tiempo, es posible identificar matemáticamente el inicio, pico y fin del ciclo del cultivo.

## 4. Flujo de Trabajo Técnico (Pipeline)

El pipeline se divide en las siguientes etapas que deben ser programadas e integradas:

### Fase A: Extracción de Series de Tiempo (Google Earth Engine / Python)
En lugar de descargar imágenes pesadas, se utilizará GEE para extraer datos tabulares:
1. Cargar los polígonos de las 150 parcelas.
2. Filtrar la colección Sentinel-2 (S2_SR_HARMONIZED) para la ventana agrícola (ej. abril a octubre de 2025).
3. Aplicar una máscara de nubes utilizando la banda de calidad QA60.
4. Extraer el valor promedio de NDVI de cada parcela para cada fecha de paso del satélite.
5. Exportar un archivo `.csv` donde las filas son las parcelas y las columnas son las lecturas de NDVI a lo largo del tiempo.

### Fase B: Suavizado de Curva y Detección Fenológica (R o Python local)
La serie de tiempo satelital tendrá "ruido" (caídas abruptas de NDVI debido a sombras o nubes residuales). Se requiere modelar la curva:
1. **Limpieza e Interpolación:** Rellenar huecos de datos (NAs) usando interpolación lineal o splines.
2. **Suavizado (Smoothing):** Aplicar un filtro (por ejemplo, filtro Savitzky-Golay o una regresión armónica/función logística doble) para obtener una "campana" de crecimiento perfecta y continua.
3. **Extracción de Métricas (Derivadas):** Analizar la curva suavizada para extraer puntos clave por parcela:
   * **SOS (Start of Season):** Fecha de inicio de verdor (aproximación de siembra/emergencia).
   * **POS (Peak of Season):** Fecha e intensidad del NDVI máximo (floración/espigado).
   * **EOS (End of Season):** Fecha de senescencia/cosecha.
   * **LOS (Length of Season):** Duración total del ciclo en días.

### Fase C: 
1. Integrar las nuevas variables fenológicas (SOS, POS, EOS, LOS) al dataset original.

## 5. Justificación del Enfoque
* **Resiliencia a nubes:** Al modelar una curva matemática sobre toda la temporada, se infiere el comportamiento del cultivo incluso en los días donde el satélite solo vio nubes.