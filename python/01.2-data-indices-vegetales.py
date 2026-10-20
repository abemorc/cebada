import ee
import pandas as pd
import geopandas as gpd

# 1. Autenticación e Inicialización de Earth Engine
ee.Initialize(project='still-resource-476723-e5')

# 2. Cargar los polígonos desde tu GeoJSON local
geojson_path = 'data/02_interim/02-parcelas-cebada-rend.geojson'
gdf = gpd.read_file(geojson_path)

# Convertir GeoDataFrame a ee.FeatureCollection usando explícitamente id_poligon
features = []
for idx, row in gdf.iterrows():
    geom = ee.Geometry.Polygon(list(row.geometry.exterior.coords))
    # Asignación estricta del nombre de la parcela
    feat = ee.Feature(geom, {'id_parcela': row['id_poligon']})
    features.append(feat)

fc_parcelas = ee.FeatureCollection(features)

# 3. Definir parámetros temporales
fecha_inicio = '2025-01-01'
fecha_fin = '2025-12-31'

# 4. Función de enmascaramiento de nubes y cálculo de índices
def procesar_sentinel(image):
    qa = image.select('QA60')
    cloudBitMask = 1 << 10
    cirrusBitMask = 1 << 11
    mask = qa.bitwiseAnd(cloudBitMask).eq(0).And(qa.bitwiseAnd(cirrusBitMask).eq(0))
    img_masked = image.updateMask(mask)
    
    ndvi = img_masked.normalizedDifference(['B8', 'B4']).rename('NDVI')
    ndwi = img_masked.normalizedDifference(['B8', 'B11']).rename('NDWI')
    evi = img_masked.expression(
        '2.5 * ((NIR - RED) / (NIR + 6 * RED - 7.5 * BLUE + 10000))', {
            'NIR': img_masked.select('B8'),
            'RED': img_masked.select('B4'),
            'BLUE': img_masked.select('B2')
        }).rename('EVI')
    
    return img_masked.addBands([ndvi, ndwi, evi]).copyProperties(image, ['system:time_start'])

# 5. Iteración por lotes para extracción masiva segura
tamaño_lote = 50
filas_csv = []

print("Iniciando extracción nativa por lotes...")

for i in range(0, len(gdf), tamaño_lote):
    print(f"Procesando lote de parcelas {i} a {min(i + tamaño_lote, len(gdf))}...")
    lote_gdf = gdf.iloc[i:i + tamaño_lote]
    
    features_lote = []
    for idx, row in lote_gdf.iterrows():
        geom = ee.Geometry.Polygon(list(row.geometry.exterior.coords))
        features_lote.append(ee.Feature(geom, {'id_parcela': row['id_poligon']}))
    fc_lote = ee.FeatureCollection(features_lote)
    
    coleccion = (ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED')
                 .filterBounds(fc_lote)
                 .filterDate(fecha_inicio, fecha_fin)
                 .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE', 30))
                 .map(procesar_sentinel)
                 .select(['NDVI', 'NDWI', 'EVI']))
    
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

# 6. Consolidar y guardar
df_series = pd.DataFrame(filas_csv)
df_series['fecha'] = pd.to_datetime(df_series['fecha'])
df_series = df_series.sort_values(by=['id_parcela', 'fecha'])

df_series.to_csv('data/02_interim/03-data-indices-vegetales.csv', index=False)
print("Archivo '03-data-indices-vegetales.csv' generado.")
