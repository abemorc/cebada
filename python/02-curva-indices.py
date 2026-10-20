import pandas as pd
import numpy as np
from scipy.signal import savgol_filter

# 1. Cargar la serie temporal en bruto
input_path = 'data/02_interim/03-data-indices-vegetales.csv'
df = pd.read_csv(input_path, parse_dates=['fecha'])

# Definir el umbral de amplitud para marcar el Inicio (SOS) y Fin (EOS) de temporada.
# Agronómicamente, el 20% de la amplitud desde el valle hasta el pico suele coincidir con el verdor visible.
PORCENTAJE_UMBRAL = 0.20

# 2. Función núcleo para procesar la curva de CADA parcela individualmente
def extraer_fenologia(grupo):
    # Ordenar cronológicamente y eliminar lecturas duplicadas el mismo día (solapamiento de órbitas)
    grupo = grupo.sort_values('fecha').set_index('fecha')
    grupo = grupo[~grupo.index.duplicated(keep='first')]

    # Crear un índice de tiempo diario estricto (del 1 de abril al 1 de noviembre)
    fecha_min = pd.to_datetime('2025-04-01')
    fecha_max = pd.to_datetime('2025-11-01')
    rango_diario = pd.date_range(start=fecha_min, end=fecha_max, freq='D')

    # Reindexar e interpolar los huecos provocados por la máscara de nubes
    grupo_diario = grupo.reindex(rango_diario)
    grupo_diario['NDVI'] = grupo_diario['NDVI'].interpolate(method='time')
    grupo_diario['EVI'] = grupo_diario['EVI'].interpolate(method='time')
    grupo_diario['NDWI'] = grupo_diario['NDWI'].interpolate(method='time')
    
    # Rellenar extremos si la serie no llega exactamente al 1 de abril o 1 de noviembre
    grupo_diario = grupo_diario.bfill().ffill()

    # 3. Aplicar Filtro Savitzky-Golay para suavizar la curva
    # Ventana de 45 días (debe ser impar), polinomio de orden 3
    window_length = 45 
    polyorder = 3
    
    grupo_diario['NDVI_smooth'] = savgol_filter(grupo_diario['NDVI'], window_length, polyorder)
    grupo_diario['EVI_smooth'] = savgol_filter(grupo_diario['EVI'], window_length, polyorder)
    grupo_diario['NDWI_smooth'] = savgol_filter(grupo_diario['NDWI'], window_length, polyorder)

    # 4. Extracción de Métricas Fenológicas basadas en la curva NDVI
    ndvi_curva = grupo_diario['NDVI_smooth']
    
    # Peak of Season (POS): El pico máximo de biomasa (floración/espigado)
    pos_idx = ndvi_curva.idxmax()
    pos_doy = pos_idx.dayofyear
    pos_val = ndvi_curva.max()

    # Calcular la amplitud de la curva
    base_val = ndvi_curva.min()
    amplitud = pos_val - base_val
    umbral = base_val + (amplitud * PORCENTAJE_UMBRAL)

    # Start of Season (SOS): Primer día antes del POS que cruza el umbral hacia arriba (Siembra/Emergencia)
    fase_crecimiento = ndvi_curva.loc[:pos_idx]
    sos_candidatos = fase_crecimiento[fase_crecimiento >= umbral]
    sos_doy = sos_candidatos.index[0].dayofyear if not sos_candidatos.empty else fase_crecimiento.index[0].dayofyear

    # End of Season (EOS): Primer día después del POS que cae por debajo del umbral (Maduración/Cosecha)
    fase_senescencia = ndvi_curva.loc[pos_idx:]
    eos_candidatos = fase_senescencia[fase_senescencia <= umbral]
    eos_doy = eos_candidatos.index[0].dayofyear if not eos_candidatos.empty else fase_senescencia.index[-1].dayofyear

    # Length of Season (LOS): Duración total en días
    los = eos_doy - sos_doy

    # 5. Extraer valores de estrés y verdor en la etapa crítica (POS)
    max_ndwi = grupo_diario.loc[pos_idx, 'NDWI_smooth']
    max_evi = grupo_diario['EVI_smooth'].max()

    return pd.Series({
        'SOS_DOY': sos_doy,
        'POS_DOY': pos_doy,
        'EOS_DOY': eos_doy,
        'LOS_dias': los,
        'NDVI_max': pos_val,
        'NDWI_en_POS': max_ndwi,
        'EVI_max': max_evi
    })

print("Suavizando curvas y calculando métricas fenológicas por parcela...")
metricas = df.groupby('id_parcela').apply(extraer_fenologia).reset_index()

# 6. Guardar el dataset resultante
output_path = 'data/03_processed/01-py-metricas-fenologicas.csv'
metricas.to_csv(output_path, index=False)
print(f"Métricas extraídas exitosamente en: {output_path}")
