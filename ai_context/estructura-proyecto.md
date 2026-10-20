# Estructura del proyecto FIRA-Cebada

```text
fira-cebada
|-- ai_context
|   |-- 00_master_promt.md
|   |-- checkpoint.md
|   |-- estructura-proyecto.md
|   |-- promts-log.md
|-- data
|   |-- 01_raw
|   |   |-- layers-gobierno
|   |   |   |-- layers
|   |   |   |   |-- conagua-acuiferos.geojson
|   |   |   |   |-- conagua-calidad-agua.geojson
|   |   |   |   |-- conagua-consejos-cuenca.geojson
|   |   |   |   |-- conagua-cotas.geojson
|   |   |   |   |-- conagua-cuencas.geojson
|   |   |   |   |-- conagua-cuerpos-agua-mx.geojson
|   |   |   |   |-- conagua-cuerpos-agua.geojson
|   |   |   |   |-- conagua-disponibilidad-cuen.geojson
|   |   |   |   |-- conagua-disponibilidad-sub-2023.geojson
|   |   |   |   |-- conagua-disponibilidad-sub.geojson
|   |   |   |   |-- conagua-estaciones-medicion.geojson
|   |   |   |   |-- conagua-humedales.geojson
|   |   |   |   |-- conagua-organismos-cuenca.geojson
|   |   |   |   |-- conagua-piezometria-2025.geojson
|   |   |   |   |-- conagua-plantas-tratam.geojson
|   |   |   |   |-- conagua-presas.geojson
|   |   |   |   |-- conagua-ramsar.geojson
|   |   |   |   |-- conagua-regiones-hidro.geojson
|   |   |   |   |-- conagua-reservas-vedas.geojson
|   |   |   |   |-- conagua-rios-canales.geojson
|   |   |   |   |-- conagua-rios-principales.geojson
|   |   |   |   |-- conagua-sobreexplotados.geojson
|   |   |   |   |-- conagua-zonas-inundacion.geojson
|   |   |   |   |-- inegi-blocks.geojson
|   |   |   |   |-- inegi-climate.geojson
|   |   |   |   |-- inegi-denue-all.geojson
|   |   |   |   |-- inegi-denue-banks.geojson
|   |   |   |   |-- inegi-denue-fire-stations.geojson
|   |   |   |   |-- inegi-denue-hospitals.geojson
|   |   |   |   |-- inegi-denue-hotels.geojson
|   |   |   |   |-- inegi-denue-logistics.geojson
|   |   |   |   |-- inegi-denue-notaries.geojson
|   |   |   |   |-- inegi-denue-police.geojson
|   |   |   |   |-- inegi-denue-schools.geojson
|   |   |   |   |-- inegi-faults.geojson
|   |   |   |   |-- inegi-geology-lines.geojson
|   |   |   |   |-- inegi-geology-points.geojson
|   |   |   |   |-- inegi-geology.geojson
|   |   |   |   |-- inegi-highways.geojson
|   |   |   |   |-- inegi-irrigation-requirements.geojson
|   |   |   |   |-- inegi-land-use.geojson
|   |   |   |   |-- inegi-landforms.geojson
|   |   |   |   |-- inegi-localities.geojson
|   |   |   |   |-- inegi-municipalities.geojson
|   |   |   |   |-- inegi-physiographic.geojson
|   |   |   |   |-- inegi-rivers.geojson
|   |   |   |   |-- inegi-rnc-estructura.geojson
|   |   |   |   |-- inegi-rnc-localidad.geojson
|   |   |   |   |-- inegi-rnc-maniobra-prohibida.geojson
|   |   |   |   |-- inegi-rnc-plaza-cobro.geojson
|   |   |   |   |-- inegi-rnc-poste-de-referencia.geojson
|   |   |   |   |-- inegi-rnc-puente.geojson
|   |   |   |   |-- inegi-rnc-sitio-de-interes.geojson
|   |   |   |   |-- inegi-rnc-transbordador.geojson
|   |   |   |   |-- inegi-rnc-union.geojson
|   |   |   |   |-- inegi-rural-agebs.geojson
|   |   |   |   |-- inegi-rural-localities.geojson
|   |   |   |   |-- inegi-soils.geojson
|   |   |   |   |-- inegi-streets.geojson
|   |   |   |   |-- inegi-topo-acueducto250-l.geojson
|   |   |   |   |-- inegi-topo-aerodromo250-a.geojson
|   |   |   |   |-- inegi-topo-bordo250-l.geojson
|   |   |   |   |-- inegi-topo-bordo250-p.geojson
|   |   |   |   |-- inegi-topo-camino250-l.geojson
|   |   |   |   |-- inegi-topo-canal250-l.geojson
|   |   |   |   |-- inegi-topo-carretera250-l.geojson
|   |   |   |   |-- inegi-topo-cementerio250-p.geojson
|   |   |   |   |-- inegi-topo-conducto250-l.geojson
|   |   |   |   |-- inegi-topo-corriente-ag250-l.geojson
|   |   |   |   |-- inegi-topo-corriente-de250-p.geojson
|   |   |   |   |-- inegi-topo-cuerpo-agua250-a.geojson
|   |   |   |   |-- inegi-topo-curva-nivel250-l.geojson
|   |   |   |   |-- inegi-topo-elemento-ins250-a.geojson
|   |   |   |   |-- inegi-topo-enlace-fluvi250-l.geojson
|   |   |   |   |-- inegi-topo-entrada-cavi250-p.geojson
|   |   |   |   |-- inegi-topo-ins-diversa250-a.geojson
|   |   |   |   |-- inegi-topo-ins-diversa250-p.geojson
|   |   |   |   |-- inegi-topo-ins-industr250-a.geojson
|   |   |   |   |-- inegi-topo-ins-industr250-p.geojson
|   |   |   |   |-- inegi-topo-ins-telecom250-p.geojson
|   |   |   |   |-- inegi-topo-limite250-l.geojson
|   |   |   |   |-- inegi-topo-lindero250-l.geojson
|   |   |   |   |-- inegi-topo-linea-transm250-l.geojson
|   |   |   |   |-- inegi-topo-localidad250-a.geojson
|   |   |   |   |-- inegi-topo-localidad250-p.geojson
|   |   |   |   |-- inegi-topo-malpais250-a.geojson
|   |   |   |   |-- inegi-topo-manantial250-p.geojson
|   |   |   |   |-- inegi-topo-nieve-perpet250-a.geojson
|   |   |   |   |-- inegi-topo-pista-aviaci250-l.geojson
|   |   |   |   |-- inegi-topo-planta-gener250-p.geojson
|   |   |   |   |-- inegi-topo-plaza-cobro250-p.geojson
|   |   |   |   |-- inegi-topo-presa250-l.geojson
|   |   |   |   |-- inegi-topo-presa250-p.geojson
|   |   |   |   |-- inegi-topo-puente250-l.geojson
|   |   |   |   |-- inegi-topo-punto-acotad250-p.geojson
|   |   |   |   |-- inegi-topo-rasgo-arqueo250-a.geojson
|   |   |   |   |-- inegi-topo-rasgo-arqueo250-p.geojson
|   |   |   |   |-- inegi-topo-referencia-g250-p.geojson
|   |   |   |   |-- inegi-topo-salina250-a.geojson
|   |   |   |   |-- inegi-topo-salto-agua250-p.geojson
|   |   |   |   |-- inegi-topo-subesta-elec250-a.geojson
|   |   |   |   |-- inegi-topo-subesta-elec250-p.geojson
|   |   |   |   |-- inegi-topo-terreno-suje250-a.geojson
|   |   |   |   |-- inegi-topo-tunel250-l.geojson
|   |   |   |   |-- inegi-topo-vegetacion250-a.geojson
|   |   |   |   |-- inegi-topo-via-ferrea250-l.geojson
|   |   |   |   |-- inegi-topo-vialidad250-l.geojson
|   |   |   |   |-- inegi-urban-agebs.geojson
|   |   |   |   |-- inegi-uso-potencial-agr.geojson
|   |   |   |   |-- inegi-uso-potencial-for.geojson
|   |   |   |   |-- inegi-uso-potencial-pec.geojson
|   |   |   |-- metadatos.txt
|   |   |-- Parcelas_Reto_AGC_CONJUNTO_70_30
|   |   |   |-- Parcelas_Reto_AGC_CONJUNTO.cpg
|   |   |   |-- Parcelas_Reto_AGC_CONJUNTO.dbf
|   |   |   |-- Parcelas_Reto_AGC_CONJUNTO.prj
|   |   |   |-- Parcelas_Reto_AGC_CONJUNTO.shp
|   |   |   |-- Parcelas_Reto_AGC_CONJUNTO.shx
|   |   |-- Reto_AgroCebada_CHIRPS_Precipitacion_2022_2025
|   |   |   |-- Precipitacion_mensual
|   |   |   |   |-- 2022
|   |   |   |   |   |-- PREC_2022_01.tif
|   |   |   |   |   |-- PREC_2022_02.tif
|   |   |   |   |   |-- PREC_2022_03.tif
|   |   |   |   |   |-- PREC_2022_04.tif
|   |   |   |   |   |-- PREC_2022_05.tif
|   |   |   |   |   |-- PREC_2022_06.tif
|   |   |   |   |   |-- PREC_2022_07.tif
|   |   |   |   |   |-- PREC_2022_08.tif
|   |   |   |   |   |-- PREC_2022_09.tif
|   |   |   |   |   |-- PREC_2022_10.tif
|   |   |   |   |   |-- PREC_2022_11.tif
|   |   |   |   |   |-- PREC_2022_12.tif
|   |   |   |   |-- 2023
|   |   |   |   |   |-- PREC_2023_01.tif
|   |   |   |   |   |-- PREC_2023_02.tif
|   |   |   |   |   |-- PREC_2023_03.tif
|   |   |   |   |   |-- PREC_2023_04.tif
|   |   |   |   |   |-- PREC_2023_05.tif
|   |   |   |   |   |-- PREC_2023_06.tif
|   |   |   |   |   |-- PREC_2023_07.tif
|   |   |   |   |   |-- PREC_2023_08.tif
|   |   |   |   |   |-- PREC_2023_09.tif
|   |   |   |   |   |-- PREC_2023_10.tif
|   |   |   |   |   |-- PREC_2023_11.tif
|   |   |   |   |   |-- PREC_2023_12.tif
|   |   |   |   |-- 2024
|   |   |   |   |   |-- PREC_2024_01.tif
|   |   |   |   |   |-- PREC_2024_02.tif
|   |   |   |   |   |-- PREC_2024_03.tif
|   |   |   |   |   |-- PREC_2024_04.tif
|   |   |   |   |   |-- PREC_2024_05.tif
|   |   |   |   |   |-- PREC_2024_06.tif
|   |   |   |   |   |-- PREC_2024_07.tif
|   |   |   |   |   |-- PREC_2024_08.tif
|   |   |   |   |   |-- PREC_2024_09.tif
|   |   |   |   |   |-- PREC_2024_10.tif
|   |   |   |   |   |-- PREC_2024_11.tif
|   |   |   |   |   |-- PREC_2024_12.tif
|   |   |   |   |-- 2025
|   |   |   |   |   |-- PREC_2025_01.tif
|   |   |   |   |   |-- PREC_2025_02.tif
|   |   |   |   |   |-- PREC_2025_03.tif
|   |   |   |   |   |-- PREC_2025_04.tif
|   |   |   |   |   |-- PREC_2025_05.tif
|   |   |   |   |   |-- PREC_2025_06.tif
|   |   |   |   |   |-- PREC_2025_07.tif
|   |   |   |   |   |-- PREC_2025_08.tif
|   |   |   |   |   |-- PREC_2025_09.tif
|   |   |   |   |   |-- PREC_2025_10.tif
|   |   |   |   |   |-- PREC_2025_11.tif
|   |   |   |   |   |-- PREC_2025_12.tif
|   |   |   |-- inventario_CHIRPS_precipitacion_mensual_2022_2025.csv
|   |   |   |-- LEEME.txt
|   |   |-- Reto_AgroCebada_Temperatura_2022_2025
|   |   |   |-- Tmax
|   |   |   |   |-- 2022
|   |   |   |   |   |-- Tmax_2022_01.tif
|   |   |   |   |   |-- Tmax_2022_02.tif
|   |   |   |   |   |-- Tmax_2022_03.tif
|   |   |   |   |   |-- Tmax_2022_04.tif
|   |   |   |   |   |-- Tmax_2022_05.tif
|   |   |   |   |   |-- Tmax_2022_06.tif
|   |   |   |   |   |-- Tmax_2022_07.tif
|   |   |   |   |   |-- Tmax_2022_08.tif
|   |   |   |   |   |-- Tmax_2022_09.tif
|   |   |   |   |   |-- Tmax_2022_10.tif
|   |   |   |   |   |-- Tmax_2022_11.tif
|   |   |   |   |   |-- Tmax_2022_12.tif
|   |   |   |   |-- 2023
|   |   |   |   |   |-- Tmax_2023_01.tif
|   |   |   |   |   |-- Tmax_2023_02.tif
|   |   |   |   |   |-- Tmax_2023_03.tif
|   |   |   |   |   |-- Tmax_2023_04.tif
|   |   |   |   |   |-- Tmax_2023_05.tif
|   |   |   |   |   |-- Tmax_2023_06.tif
|   |   |   |   |   |-- Tmax_2023_07.tif
|   |   |   |   |   |-- Tmax_2023_08.tif
|   |   |   |   |   |-- Tmax_2023_09.tif
|   |   |   |   |   |-- Tmax_2023_10.tif
|   |   |   |   |   |-- Tmax_2023_11.tif
|   |   |   |   |   |-- Tmax_2023_12.tif
|   |   |   |   |-- 2024
|   |   |   |   |   |-- Tmax_2024_01.tif
|   |   |   |   |   |-- Tmax_2024_02.tif
|   |   |   |   |   |-- Tmax_2024_03.tif
|   |   |   |   |   |-- Tmax_2024_04.tif
|   |   |   |   |   |-- Tmax_2024_05.tif
|   |   |   |   |   |-- Tmax_2024_06.tif
|   |   |   |   |   |-- Tmax_2024_07.tif
|   |   |   |   |   |-- Tmax_2024_08.tif
|   |   |   |   |   |-- Tmax_2024_09.tif
|   |   |   |   |   |-- Tmax_2024_10.tif
|   |   |   |   |   |-- Tmax_2024_11.tif
|   |   |   |   |   |-- Tmax_2024_12.tif
|   |   |   |   |-- 2025
|   |   |   |   |   |-- Tmax_2025_01.tif
|   |   |   |   |   |-- Tmax_2025_02.tif
|   |   |   |   |   |-- Tmax_2025_03.tif
|   |   |   |   |   |-- Tmax_2025_04.tif
|   |   |   |   |   |-- Tmax_2025_05.tif
|   |   |   |   |   |-- Tmax_2025_06.tif
|   |   |   |   |   |-- Tmax_2025_07.tif
|   |   |   |   |   |-- Tmax_2025_08.tif
|   |   |   |   |   |-- Tmax_2025_09.tif
|   |   |   |   |   |-- Tmax_2025_10.tif
|   |   |   |   |   |-- Tmax_2025_11.tif
|   |   |   |   |   |-- Tmax_2025_12.tif
|   |   |   |-- Tmin
|   |   |   |   |-- 2022
|   |   |   |   |   |-- Tmin_2022_01.tif
|   |   |   |   |   |-- Tmin_2022_02.tif
|   |   |   |   |   |-- Tmin_2022_03.tif
|   |   |   |   |   |-- Tmin_2022_04.tif
|   |   |   |   |   |-- Tmin_2022_05.tif
|   |   |   |   |   |-- Tmin_2022_06.tif
|   |   |   |   |   |-- Tmin_2022_07.tif
|   |   |   |   |   |-- Tmin_2022_08.tif
|   |   |   |   |   |-- Tmin_2022_09.tif
|   |   |   |   |   |-- Tmin_2022_10.tif
|   |   |   |   |   |-- Tmin_2022_11.tif
|   |   |   |   |   |-- Tmin_2022_12.tif
|   |   |   |   |-- 2023
|   |   |   |   |   |-- Tmin_2023_01.tif
|   |   |   |   |   |-- Tmin_2023_02.tif
|   |   |   |   |   |-- Tmin_2023_03.tif
|   |   |   |   |   |-- Tmin_2023_04.tif
|   |   |   |   |   |-- Tmin_2023_05.tif
|   |   |   |   |   |-- Tmin_2023_06.tif
|   |   |   |   |   |-- Tmin_2023_07.tif
|   |   |   |   |   |-- Tmin_2023_08.tif
|   |   |   |   |   |-- Tmin_2023_09.tif
|   |   |   |   |   |-- Tmin_2023_10.tif
|   |   |   |   |   |-- Tmin_2023_11.tif
|   |   |   |   |   |-- Tmin_2023_12.tif
|   |   |   |   |-- 2024
|   |   |   |   |   |-- Tmin_2024_01.tif
|   |   |   |   |   |-- Tmin_2024_02.tif
|   |   |   |   |   |-- Tmin_2024_03.tif
|   |   |   |   |   |-- Tmin_2024_04.tif
|   |   |   |   |   |-- Tmin_2024_05.tif
|   |   |   |   |   |-- Tmin_2024_06.tif
|   |   |   |   |   |-- Tmin_2024_07.tif
|   |   |   |   |   |-- Tmin_2024_08.tif
|   |   |   |   |   |-- Tmin_2024_09.tif
|   |   |   |   |   |-- Tmin_2024_10.tif
|   |   |   |   |   |-- Tmin_2024_11.tif
|   |   |   |   |   |-- Tmin_2024_12.tif
|   |   |   |   |-- 2025
|   |   |   |   |   |-- Tmin_2025_01.tif
|   |   |   |   |   |-- Tmin_2025_02.tif
|   |   |   |   |   |-- Tmin_2025_03.tif
|   |   |   |   |   |-- Tmin_2025_04.tif
|   |   |   |   |   |-- Tmin_2025_05.tif
|   |   |   |   |   |-- Tmin_2025_06.tif
|   |   |   |   |   |-- Tmin_2025_07.tif
|   |   |   |   |   |-- Tmin_2025_08.tif
|   |   |   |   |   |-- Tmin_2025_09.tif
|   |   |   |   |   |-- Tmin_2025_10.tif
|   |   |   |   |   |-- Tmin_2025_11.tif
|   |   |   |   |   |-- Tmin_2025_12.tif
|   |   |   |-- inventario_temperatura_2022_2025.csv
|   |   |   |-- LEEME_.txt
|   |   |-- Reto_AgroCebada_Topografia_INEGI_CEM4
|   |   |   |-- Reto_AgroCebada_Topografia_INEGI_CEM4
|   |   |   |   |-- Elevacion_INEGI_CEM4_120m.tif
|   |   |   |   |-- inventario_topografia.csv
|   |   |   |   |-- LEEME.txt
|   |   |   |   |-- Pendiente_INEGI_CEM4_120m_grados.tif
|   |   |-- Conjunto_datos_BASICO_AgroCebada2026.csv
|   |   |-- Conjunto_datos_PRO_AgroCebada.csv
|   |   |-- Descripcion_general_variables_DataSet.docx
|   |   |-- Descripcion_general_variables_DataSet.pdf
|   |   |-- Diccionario_de_indices_satelitales.docx
|   |   |-- Diccionario_de_indices_satelitales.pdf
|   |   |-- Ecuaciones_indices_AgroCebada_FIRA_2026.pdf
|   |   |-- ID_area_rendimiento_70_30_Reto_AgroCebada.csv
|   |   |-- inventario-archivos.csv
|   |   |-- metadatos_RawData.txt
|   |   |-- Readme.md
|   |-- 02_interim
|   |   |-- 01-parcelas-cebada.geojson
|   |   |-- 02-parcelas-cebada-rend.geojson
|   |   |-- 02-parecelas-rend-atributos.csv
|   |   |-- landast-sentinel-parcelas-yada.csv
|   |-- 03_processed
|-- models
|-- notebooks
|-- outputs
|-- python
|   |-- ejemplo.py
|-- R
|   |-- utils
|   |   |-- crear-tree.R
|   |-- 00-setup.R
|   |-- 01-shp-2-geojson.R
|   |-- 02-parc-join-rendimient.R
|-- temporal
|   |-- 02-ndvi-test-toDrive.py
|   |-- get-info-october.py
|-- pyproject.toml
|-- README.md
|-- uv.lock
```

