import ee

ee.Initialize(project='still-resource-476723-e5')

# Bounding Box de los municipios
xmin, ymin, xmax, ymax = -98.61299, 19.52382, -98.19670, 19.98437
roi = ee.Geometry.BBox(xmin, ymin, xmax, ymax)

# 1. Filtrar exactamente el 27 de octubre de 2025
# (En GEE, el límite superior del filtro de fechas es exclusivo)
s2_dia = (ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED')
          .filterBounds(roi)
          .filterDate('2025-10-27', '2025-10-28'))

# 2. Unir los cuadrantes que cubren la zona en un solo mosaico
mosaico = s2_dia.mosaic()

# 3. Calcular NDVI directamente sobre el mosaico
# (B8 - B4) / (B8 + B4)
ndvi_27oct = mosaico.normalizedDifference(['B8', 'B4']).rename('NDVI').clip(roi)

# 4. Exportar a Drive como GeoTIFF optimizado para la nube (COG)
task = ee.batch.Export.image.toDrive(
    image=ndvi_27oct,
    description='NDVI_Altiplano_20251027_COG',
    folder='Datos_GEE_Cultivos',
    region=roi,
    scale=10,                # Resolución nativa de 10 metros
    crs='EPSG:4326',
    maxPixels=1e10,
    fileFormat='GeoTIFF',
    formatOptions={'cloudOptimized': True}
)

task.start()
print("Tarea enviada: Exportando NDVI continuo del 27 de octubre a Drive...")