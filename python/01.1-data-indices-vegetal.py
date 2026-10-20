import pandas as pd
import geopandas as gpd

# 1. Cargar el GeoJSON original y el CSV descargado
gdf = gpd.read_file('data/02_interim/02-parcelas-cebada-rend.geojson')
df_series = pd.read_csv('data/03_interim/01-data-indices-vegetales.csv')

# 2. Crear un diccionario que asocie el índice (0-196) con el 'id_poligon' real
mapeo_ids = dict(zip(gdf.index, gdf['id_poligon']))

# 3. Reemplazar los números por los IDs correctos en el CSV
df_series['id_parcela'] = df_series['id_parcela'].map(mapeo_ids)

# 4. Sobrescribir el CSV con la información corregida
df_series.to_csv('../series_temporales_parcelas.csv', index=False)
print("IDs corregidos exitosamente.")