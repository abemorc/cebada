## 📖 Acerca del Proyecto

El cultivo de cebada en el Altiplano Central (Hidalgo, Tlaxcala y Puebla) es un pilar socioeconómico para la agricultura de temporal, orientado a la industria maltera. Sin embargo, sufre de vulnerabilidades por variabilidad climática y limitantes técnicas en la estimación de cosechas (nubosidad persistente, ruido fenológico).

Este proyecto implementa un modelo de **Aprendizaje Automático geoespacial (Agronomía Satelital)** que integra variables bioclimáticas, geomorfológicas y espectrales de alta resolución.

**Objetivo Financiero:** Brindar certidumbre analítica para transformar la gestión del crédito agrícola y los seguros agropecuarios, reduciendo asimetrías de información y fomentando la inclusión financiera en el sector rural.

## 🚀 Arquitectura Tecnológica

* 🌍 **Procesamiento Satelital Híbrido:** Uso de Google Earth Engine (GEE) y la constelación PlanetScope (\~3m) para sortear la alta nubosidad.

* 🤖 **Machine Learning Predictivo (`mlr3`):** Pipeline escalable y orientado a objetos en R (4.3+) que evalúa e interpola el rendimiento agrícola.

* 💻 **Aplicación Web Interactiva:** Dashboards geoespaciales interactivos.

* 💬 **Asistente de Inteligencia Artificial:** Un chatbot integrado (RAG) diseñado para que analistas de crédito y aseguradoras pregunten en lenguaje natural sobre variables de riesgo y proyecciones por parcela sin tocar código.

## 🧮 Metodología y Respaldo Matemático

El núcleo predictivo se construyó abstrayendo la biología del cultivo a través de una profunda **Ingeniería de Características (Feature Engineering)**.

### 1. Variables Abióticas y Contexto Físico

Se integraron y analizaron más de 111 archivos ráster/shapefiles de fuentes oficiales:

* **Topografía y Suelos:** Elevación, pendiente y porcentajes de limo/arcilla (*SoilGrids*).

* **Termodinámica y Clima:** Temperatura media, máximas absolutas, radiación solar y precipitación (*ERA5-Land* y *CHIRPS*).

### 2. Procesamiento Espectral (Filtro DOY > 120)

Se calcularon series temporales del **Índice de Vegetación Mejorado (EVI)**. Para transformar las observaciones discretas en una curva fisiológica, aplicamos **Regresión LOESS**.

Se impuso una restricción agronómica para ignorar malezas de invierno ("avena loca"), forzando el inicio del ciclo a partir de mayo ($DOY > 120$). A partir de aquí se identificaron: Inicio (SOS), Pico (POS), Fin (EOS) y Duración (LOS).

### 3. Ingeniería de Variables Derivadas

Se parametrizaron proxys directos de la capacidad productiva:

* **Productividad Primaria Neta (`evi_integral`):** Área bajo la curva del EVI. Predictor principal de biomasa total.
  

  <!-- $$
  EVI_{integral} = \int_{SOS}^{EOS} f_{LOESS}(t) \, dt
  $$ -->

* **Vigor de Establecimiento (`vigor_emergencia_msavi`):** Promedio del MSAVI en los primeros 25 días.

* **Tasa de Senescencia (`tasa_senescencia`):** Pendiente de caída del EVI desde el pico (POS) al final (EOS). Indica estrés hídrico terminal o "secado arrebatado".

## 📊 Resultados del Modelo

Se compararon *Random Forest* (`ranger`), *XGBoost* y *Elastic Net* utilizando el framework `mlr3`. Dado que el objetivo exige interpolar predicciones, se contrastaron esquemas de validación espacial estricta (SpCV) contra aleatoria.

**Modelo Seleccionado:** Random Forest (Validación Aleatoria)

* **Coeficiente de Determinación (**$R^2$**):** \~0.52

* **Error Cuadrático Medio Raíz (RMSE):** \~0.54 t/ha

* **Error Absoluto Medio (MAE):** \~0.41 t/ha

**Importancia de Variables (Permutation Feature Importance):**

1. La pertenencia a clusters geográficos (`zona_cluster.2`, `zona_cluster.3`) define la línea base de rendimiento.

2. `temp_media_c`, `duracion_dias` y `radiacion_acumulada_mj` dominaron el peso predictivo a nivel microescala.

3. *Conclusión agronómica:* La capacidad estructural para interceptar luz sostenidamente pesó más que la precipitación en este régimen temporalero.

*(Las predicciones finales de los 59 polígonos de evaluación se encuentran en `data/grano_de_riesgo_prediccion_2.csv`)*

<!-- ## 📂 Estructura del Repositorio

```
📦 fira-cebada
 ┣ 📂 data
 ┃ ┣ 📜 grano_de_riesgo_prediccion_2.csv       # Inferencia final (Resultados del reto)
 ┃ ┗ 📜 ...                                    # Capas geoespaciales y climáticas
 ┣ 📂 R
 ┃ ┣ 📜 00-setup.R                             # Librerías (sf, terra, mlr3, tidyverse)
 ┃ ┣ 📜 03-indices-vegetales-planet.R          # Extracción GEE/Planet (DOY>120)
 ┃ ┗ 📜 rand-f-explo.R                         # Entrenamiento ML y Tuning
 ┣ 📂 app
 ┃ ┗ 📜 app.R                                  # Aplicación Web y Asistente de IA
 ┣ 📜 Informe.pdf                              # Reporte técnico completo
 ┗ 📜 README.md                                # Este documento

``` -->

## 💻 Instalación y Uso

### Prerrequisitos

* R (versión 4.3 o superior)

* Credenciales activas de Google Earth Engine y Planet Labs (para re-ejecutar el pipeline de imágenes).

### Instalación

1. Clona el repositorio:

   ```
   git clone https://github.com/tu-usuario/fira-cebada.git
   
   ```

2. Instala las dependencias en R, en la consola de R:

   ```
   install.packages(c("sf", "terra", "mlr3", "mlr3learners", "tidyverse", "ranger"))
   
   ```
3. Instala las dependencias de python, en la terminal ejecuta:

   ```
   uv sync   
   
   ```

### Uso

* Para entrenar el modelo: Ejecuta los scripts en la carpeta `/R` en orden secuencial.

* Para visualizar los resultados espaciales: Lanza la aplicación web corriendo el archivo `/app/app.R`.


