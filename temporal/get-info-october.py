
import ee

# Inicializa con tu proyecto
ee.Initialize(project='still-resource-476723-e5')

# Tu Bounding Box
xmin, ymin, xmax, ymax = -98.61299, 19.52382, -98.19670, 19.98437
roi = ee.Geometry.BBox(xmin, ymin, xmax, ymax)

# Filtrar la colección para octubre de 2025
s2_collection = (ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED')
                 .filterBounds(roi)
                 .filterDate('2025-10-01', '2025-10-31')
                 .sort('system:time_start')) # Ordenar cronológicamente

# Función para extraer la fecha y las nubes de cada imagen sin descargarla
def get_metadata(image):
    # Formatear la fecha a Año-Mes-Día
    date = ee.Date(image.get('system:time_start')).format('YYYY-MM-dd')
    clouds = image.get('CLOUDY_PIXEL_PERCENTAGE')
    # Devolver un Feature vacío (sin geometría) solo con las propiedades que nos interesan
    return ee.Feature(None, {'fecha': date, 'nubes': clouds})

# Mapear la función sobre la colección y traer los datos a Python con getInfo()
metadatos = s2_collection.map(get_metadata).getInfo()

# Imprimir los resultados en formato tabla
print(f"{'Fecha':<15} | {'Nubosidad (%)'}")
print("-" * 32)

for feature in metadatos['features']:
    fecha = feature['properties']['fecha']
    nubes = feature['properties']['nubes']
    print(f"{fecha:<15} | {nubes:.2f}%")