
# ==============================================================================
# INSPECCIÓN VISUAL DE PREDICCIONES
# ==============================================================================
library(sf)
library(dplyr)
library(ggplot2)

cat("Cargando archivos...\n")
# 1. Leer los archivos GeoJSON
original <- st_read("data/02_interim/02-parcelas-cebada-rend.geojson", quiet = TRUE)
predicciones <- st_read("data/04_results/04-predicciones-cebada-final.geojson", quiet = TRUE)
predicciones2 <- st_read("resultados/predicciones-cebada-spcv-coords.geojson", quiet = TRUE)



# 2. Separar e identificar los datos
# Extraemos solo las parcelas de entrenamiento (las que ya tenían rendimiento real)
entrenamiento <- original %>% 
  filter(conjunto == "ENTRENAMIENTO") %>%
  mutate(tipo = "Real (Entrenamiento)")

# A las predicciones les asignamos su etiqueta
predicciones <- predicciones %>%
  mutate(tipo = "Estimado (Predicción)")

predicciones2 <- predicciones2 %>%
  mutate(tipo = "Estimado (Predicción2)")


predicciones <- st_transform(predicciones, st_crs(original))
predicciones2 <- st_transform(predicciones2, st_crs(original))



# 3. Unir ambos conjuntos reteniendo solo geometría, rendimiento y tipo
mapa_datos <- bind_rows(
  entrenamiento %>% select(id_poligon, rendimiento_t_ha, tipo),
  predicciones %>% select(id_poligon, rendimiento_t_ha, tipo)
)
mapa_datos


mapa_datos2 <- bind_rows(
  entrenamiento %>% select(id_poligon, rendimiento_t_ha, tipo),
  predicciones2 %>% select(id_poligon, rendimiento_t_ha, tipo)
)
mapa_datos2



# 4. Generar el mapa estático con ggplot2
cat("Generando gráfico estático...\n")
grafico <- ggplot() +
  # Dibujar los polígonos, el relleno es el tonelaje y el color del borde es el tipo
  geom_sf(data = mapa_datos, aes(fill = rendimiento_t_ha, color = tipo), size = 0.8) +
  scale_fill_viridis_c(name = "Rendimiento\n(t/ha)", option = "magma", direction = -1) +
  scale_color_manual(name = "Conjunto", 
                     values = c("Real (Entrenamiento)" = "black", 
                                "Estimado (Predicción)" = "cyan")) +
  theme_minimal() +
  labs(
    title = "Mapa de Rendimiento de Cebada en el Altiplano Central",
    subtitle = "Inspección de datos reales (borde negro) vs estimados (borde cyan)",
    x = "Longitud", y = "Latitud"
  ) +
  theme(legend.position = "right")

print(grafico)

# ==============================================================================
# 5. MAPA INTERACTIVO (Recomendado para inspección manual)
# ==============================================================================
# # Si no lo tienes instalado, ejecuta en consola: install.packages("mapview")
library(mapview)

cat("Generando mapa interactivo...\n")
mapa_interactivo <- mapview(entrenamiento, zcol = "rendimiento_t_ha", 
                            layer.name = "Real (Entrenamiento)") +
                            # col.regions = viridisLite::magma(100, direction = -1)) +
                    mapview(predicciones, zcol = "rendimiento_t_ha", 
                            layer.name = "Estimado (Predicción)" ) 
                    # mapview(predicciones2, zcol = "rendimiento_t_ha", 
                            # layer.name = "Estimado (Predicción2)" )
  
                            # col.regions = viridisLite::magma(100, direction = -1))

# Al imprimirlo, se abrirá en la pestaña "Viewer" de RStudio / Positron
print(mapa_interactivo)
