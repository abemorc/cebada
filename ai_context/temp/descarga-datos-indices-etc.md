Fase 1: Reconstrucción del Calendario (Pipeline Fenológico)

Extracción de Series Temporales: Utiliza la API de Google Earth Engine (GEE) en Python para iterar sobre los 150 polígonos. Filtra la colección Sentinel-2 (abril a octubre), aplica la máscara de nubes QA60 y exporta un CSV con el NDVI promedio por parcela por fecha.   
MD
+ 1

Suavizado y Derivación: En R o Python, interpola los valores faltantes y aplica un filtro Savitzky-Golay a la curva de NDVI. Extrae como columnas tabulares el Día del Año (DOY) correspondiente al Start of Season (SOS), Peak of Season (POS) y End of Season (EOS), además del valor máximo de NDVI alcanzado.   
MD
+ 1

Fase 2: Geometría y Drenaje del Terreno

Procesamiento DEM: Descarga el Copernicus DEM a 30m. En el entorno de R, reproyecta los 150 polígonos a un CRS métrico local.   
MD

Cálculo Topológico: Genera rasters de Pendiente y TWI. Extrae estadísticas zonales (media y desviación estándar) por cada polígono para mapear su riesgo de anoxia (encharcamiento) y erosión por escorrentía.   
MD
+ 1

Fase 3: Parametrización del Sustrato (Proxy de Tepetate)

Conexión a SoilGrids: Automatiza peticiones a SoilGrids 250m para extraer predicciones a intervalos de 0-5 cm hasta 60-100 cm.   
MD

Variables Objetivo: Descarga el contenido volumétrico de agua a 33 kPa y 1500 kPa para calcular la Capacidad de Agua Disponible (AWC) integrada, así como la densidad aparente (bdod). Agrega estos valores como columnas descriptivas del perfil del suelo por parcela.   
MD

Fase 4: Integración Climática y Discriminación de Maleza

Acumulación Meteorológica: Cruza el SOS y EOS calculados en la Fase 1 con los rasters de CHIRPS (precipitación) y ERA5-Land (temperatura/radiación) para obtener la lluvia y los Grados-Día exactos recibidos durante el ciclo de vida de esa parcela específica.   
MD

Vector de Competencia (Opcional pero recomendado): Para evitar el falso positivo de rendimiento por infestación de Avena fatua (que genera un alto NDVI), extrae la retrodispersión VV/VH de Sentinel-1 o la pendiente de caída (senescencia) post-POS. La maleza madura y seca a un ritmo distinto que la cebada maltera.   
MD
+ 1

Fase 5: Ensamblaje y Entrenamiento
Consolida todas las estadísticas zonales extraídas en un único Data Frame final. Las columnas predictoras (X) serán las métricas fenológicas, climáticas, topográficas y edafológicas, y la variable objetivo (Y) será el rendimiento en toneladas. Este enfoque transformará los 150 polígonos ciegos en un conjunto de datos multivariado rico en contexto fisiológico, listo para que el Random Forest encuentre las divisiones no lineales óptimas.