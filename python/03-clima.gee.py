import ee
import pandas as pd
import geopandas as gpd

# 1. Inicialización
ee.Initialize(project='still-resource-476723-e5')

# 2. Cargar geometrías y métricas
ruta_geojson = 'data/02_interim/02-parcelas-cebada-rend.geojson'
ruta_feno = 'data/03_processed/01-metricas-fenologicas.csv'

gdf = gpd.read_file(ruta_geojson)
df_feno = pd.read_csv(ruta_feno)

gdf = gdf.merge(df_feno, left_on='id_poligon', right_on='ID_POLIGONO')

# 3. Conversión de fechas robusta
gdf['fecha_inicio'] = pd.to_datetime('2025-01-01') + pd.to_timedelta(gdf['doy_inicio'] - 1, unit='D')
gdf['fecha_fin'] = pd.to_datetime('2025-01-01') + pd.to_timedelta(gdf['doy_fin'] - 1, unit='D')

gdf['fecha_inicio_str'] = gdf['fecha_inicio'].dt.strftime('%Y-%m-%d')
gdf['fecha_fin_str'] = gdf['fecha_fin'].dt.strftime('%Y-%m-%d')

# 4. Función de extracción climática puntual (Con Termodinámica y Radiación)
def extraer_clima(feature):
    f_inicio = feature.getString('fecha_inicio')
    f_fin = feature.getString('fecha_fin')
    geom = feature.geometry() # Punto central

    # CHIRPS (Lluvia total acumulada en mm)
    chirps = ee.ImageCollection("UCSB-CHG/CHIRPS/DAILY") \
        .filterBounds(geom) \
        .filterDate(f_inicio, f_fin) \
        .select('precipitation') \
        .sum()
        
    # ERA5-Land (Clima térmico y radiación)
    era5 = ee.ImageCollection("ECMWF/ERA5_LAND/DAILY_AGGR") \
        .filterBounds(geom) \
        .filterDate(f_inicio, f_fin)
    
    # 1. Temperatura Media y Máxima Absoluta (Celsius)
    tmean_diaria = era5.select('temperature_2m').mean().subtract(273.15)
    tmax_absoluta = era5.select('temperature_2m_max').max().subtract(273.15)
    
    # 2. Grados-Día de Crecimiento (GDD) para cebada (Temp Base = 5°C)
    def calc_gdd(image):
        t_mean_c = image.select('temperature_2m').subtract(273.15)
        gdd = t_mean_c.subtract(5).max(0) 
        return gdd.rename('GDD')
        
    gdd_acumulado = era5.map(calc_gdd).sum()
    
    # 3. Radiación Solar Acumulada (Convertida a Megajoules MJ/m2)
    radiacion_acumulada = era5.select('surface_solar_radiation_downwards_sum').sum().divide(1e6)

    # Extracción puntual 
    precip_val = chirps.reduceRegion(ee.Reducer.first(), geom, 100).get('precipitation')
    tmean_val = tmean_diaria.reduceRegion(ee.Reducer.first(), geom, 100).get('temperature_2m')
    tmax_val = tmax_absoluta.reduceRegion(ee.Reducer.first(), geom, 100).get('temperature_2m_max')
    gdd_val = gdd_acumulado.reduceRegion(ee.Reducer.first(), geom, 100).get('GDD')
    rad_val = radiacion_acumulada.reduceRegion(ee.Reducer.first(), geom, 100).get('surface_solar_radiation_downwards_sum')

    return feature.set({
        'precip_acumulada_mm': precip_val,
        'temp_media_c': tmean_val,
        'temp_max_absoluta_c': tmax_val,
        'gdd_acumulado': gdd_val,
        'radiacion_acumulada_mj': rad_val
    })

# 5. Iteración por lotes para no exceder la memoria
tamaño_lote = 25
filas_csv = []

print("Extrayendo variables climáticas y radiación desde GEE por lotes...")

for i in range(0, len(gdf), tamaño_lote):
    print(f"Procesando lote {i} a {min(i + tamaño_lote, len(gdf))}...")
    lote_gdf = gdf.iloc[i:i + tamaño_lote]
    
    features_lote = []
    for idx, row in lote_gdf.iterrows():
        centroide = row.geometry.centroid
        geom = ee.Geometry.Point([centroide.x, centroide.y])
        
        feat = ee.Feature(geom, {
            'id_parcela': row['id_poligon'],
            'fecha_inicio': row['fecha_inicio_str'],
            'fecha_fin': row['fecha_fin_str']
        })
        features_lote.append(feat)
        
    fc_lote = ee.FeatureCollection(features_lote)
    fc_clima_lote = fc_lote.map(extraer_clima)
    
    resultados_lote = fc_clima_lote.getInfo()['features']
    
    # AQUÍ ESTÁ LA CORRECCIÓN: Se recogen explícitamente todas las variables nuevas
    for item in resultados_lote:
        props = item['properties']
        filas_csv.append({
            'id_parcela': props.get('id_parcela'),
            'precip_acumulada_mm': props.get('precip_acumulada_mm'),
            'temp_media_c': props.get('temp_media_c'),
            'temp_max_absoluta_c': props.get('temp_max_absoluta_c'),
            'gdd_acumulado': props.get('gdd_acumulado'),
            'radiacion_acumulada_mj': props.get('radiacion_acumulada_mj')
        })

# 6. Consolidar y guardar
df_clima = pd.DataFrame(filas_csv)
ruta_salida = 'data/02_interim/06-metricas-climaticas.csv'
df_clima.to_csv(ruta_salida, index=False)
print(f"Métricas climáticas guardadas exitosamente en '{ruta_salida}'")