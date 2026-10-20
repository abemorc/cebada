import ee
import pandas as pd
import geopandas as gpd
import json

# 1. Autenticación e Inicialización de Earth Engine
# (Si es la primera vez, ejecuta ee.Authenticate() en tu terminal)
ee.Initialize(project='still-resource-476723-e5')

# 2. Cargar los polígonos desde tu GeoJSON local
# Asumiendo que el archivo está en la raíz del proyecto
geojson_path = 'data/02_interim/02-parcelas-cebada-rend.geojson'
gdf = gpd.read_file(geojson_path)

# Convertir GeoDataFrame a ee.FeatureCollection
# (Asegúrate de que tus polígonos estén en WGS84 - EPSG:4326)
features = []
for idx, row in gdf.iterrows():
    geom = ee.Geometry.Polygon(list(row.geometry.exterior.coords))
    # Corrección: Extraer directamente el valor de la columna 'id_poligon'
    feat = ee.Feature(geom, {'id_parcela': row['id_poligon']})
    features.append(feat)

fc_parcelas = ee.FeatureCollection(features)

# 3. Definir parámetros temporales
# (Abarcando la ventana agrícola del Altiplano Central)
fecha_inicio = '2025-04-01'
fecha_fin = '2025-11-01'

# 4. Función de enmascaramiento de nubes y cálculo de índices
def procesar_sentinel(image):
    # Enmascarar nubes usando QA60
    qa = image.select('QA60')
    cloudBitMask = 1 << 10
    cirrusBitMask = 1 << 11
    mask = qa.bitwiseAnd(cloudBitMask).eq(0).And(qa.bitwiseAnd(cirrusBitMask).eq(0))
    img_masked = image.updateMask(mask)
    
    # Calcular NDVI: (NIR - RED) / (NIR + RED)
    ndvi = img_masked.normalizedDifference(['B8', 'B4']).rename('NDVI')
    
    # Calcular NDWI: (GREEN - NIR) / (GREEN + NIR) o (NIR - SWIR) dependiendo de la fórmula agronómica
    # Usaremos la clásica para vegetación/estrés hídrico: (B8 - B11) / (B8 + B11)
    ndwi = img_masked.normalizedDifference(['B8', 'B11']).rename('NDWI')
    
    # Calcular EVI: 2.5 * ((NIR - RED) / (NIR + 6 * RED - 7.5 * BLUE + 1))
    evi = img_masked.expression(
        '2.5 * ((NIR - RED) / (NIR + 6 * RED - 7.5 * BLUE + 10000))', {
            'NIR': img_masked.select('B8'),
            'RED': img_masked.select('B4'),
            'BLUE': img_masked.select('B2')
        }).rename('EVI')
    
    return img_masked.addBands([ndvi, ndwi, evi]).copyProperties(image, ['system:time_start'])

# 5. Iteración por lotes para evitar el límite de 5000 elementos de getInfo()
tamaño_lote = 50
filas_csv = []

print("Iniciando extracción por lotes...")

for i in range(0, len(gdf), tamaño_lote):
    print(f"Procesando lote de parcelas {i} a {min(i + tamaño_lote, len(gdf))}...")
    
    # Extraer el subconjunto del GeoDataFrame local
    lote_gdf = gdf.iloc[i:i + tamaño_lote]
    
    # Crear FeatureCollection solo para este lote
    features_lote = []
    for idx, row in lote_gdf.iterrows():
        geom = ee.Geometry.Polygon(list(row.geometry.exterior.coords))
        # Corrección: Extraer directamente el valor de la columna 'id_poligon' para el lote
        features_lote.append(ee.Feature(geom, {'id_parcela': row['id_poligon']}))
    fc_lote = ee.FeatureCollection(features_lote)
    
    # Filtrar colección satelital
    coleccion = (ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED')
                 .filterBounds(fc_lote)
                 .filterDate(fecha_inicio, fecha_fin)
                 .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE', 30))
                 .map(procesar_sentinel)
                 .select(['NDVI', 'NDWI', 'EVI']))
    
    # Extraer estadísticas del lote
    def extraer_por_imagen(image):
        date = ee.Date(image.get('system:time_start')).format('YYYY-MM-dd')
        reduccion = image.reduceRegions(
            collection=fc_lote,
            reducer=ee.Reducer.mean(),
            scale=10
        )
        return reduccion.map(lambda f: f.set('fecha', date))

    datos_crudos = coleccion.map(extraer_por_imagen).flatten()
    datos_filtrados = datos_crudos.filter(ee.Filter.notNull(['NDVI']))
    
    # Descargar el lote localmente (ahora estará muy por debajo de 5000)
    lista_datos = datos_filtrados.getInfo()['features']
    
    for item in lista_datos:
        props = item['properties']
        filas_csv.append({
            'id_parcela': props.get('id_parcela'),
            'fecha': props.get('fecha'),
            'NDVI': props.get('NDVI'),
            'NDWI': props.get('NDWI'),
            'EVI': props.get('EVI')
        })

# Consolidar y guardar
df_series = pd.DataFrame(filas_csv)
df_series['fecha'] = pd.to_datetime(df_series['fecha'])
df_series = df_series.sort_values(by=['id_parcela', 'fecha'])

df_series.to_csv('data/02_interim/03-data-indices-vegetales.csv', index=False)
print("Archivo 'data/02_interim/03-data-indices-vegetales.csv' generado con éxito en local.")

