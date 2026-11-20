# Checklist: recomendaciones del profesor frente al proyecto

Estado según el repositorio (970 lotes). **Sí** = está hecho y comprobado en el archivo indicado; **Parcial** = hecho con una salvedad; **Pendiente** = falta.

## Recomendaciones dadas a otro grupo

| Recomendación | Estado | Dónde está |
|---|---|---|
| Poner los intervalos de confianza | Sí | `01-pca/pca_final.Rmd` §6 (bootstrap, B = 2000): CP1 67,5–70,9 %, CP2 11,2–12,0 %, CP1+CP2 79,3–82,5 %. Figura `codo_IC.png`. Guion, diapositiva 4. |
| Qué diagrama de cajas se usó | Sí | `pca_final.Rmd` §3: clásico frente a robusto (MAD) frente a ajustado (medcouple). Guion, diapositiva 3. |
| Revisar simetría y usar caja robusta si es simétrica | Sí | `pca_final.Rmd` §3, regla \|medcouple\| ≤ 0,1. Tabla `tabla_simetria_boxplot.csv`. |
| Estandarizar centra los datos | Sí | Guion, diapositiva 3; `pca_final.Rmd` §5. |
| Supuesto del PCA: sin atípicos fuertes | Parcial | `pca_final.Rmd` §5. Tras la única pasada de Mahalanobis quedan 63 lotes marcados de 970 (por azar se esperarían unos 24); no se retiran para no filtrar en cadena. |
| Diagrama de dispersión del PCA | Sí | `pca_final.Rmd` §7, `dispersion_CP1_CP2.png` (coloreado por método de proceso). |
| Yeo-Johnson solo a las variables que lo necesitan | Sí | `depuracion.Rmd` §1 (\|asimetría\| > 1). En los 970 lotes ninguna lo necesita. |
| Mostrar el gráfico del codo | Sí | `codo_IC.png`; `01-pca/figuras/pca_revision/pca_final_scree.png`. |
| Transformar solo con evidencia (cajas robustas) | Sí | `pca_final.Rmd` §3 y §4. |
| Primero la nube de dispersión y después los pesos | Parcial | El guion ya sigue ese orden. **El deck de Canva no:** la diapositiva 5 muestra varianza y cargas antes que la nube (diapositiva 6). |
| Explicar las cargas de las tres componentes | Sí | `pca_final.Rmd` §8 y `cargas_CP1_CP3.csv`. Guion, diapositiva 4. |
| Biplot | Sí | `biplot.png`; `pca_revision/pca_final_biplot.png`. |
| t-SNE exploratorio, puntos coloreados por tipo | Sí | `pca_final.Rmd` §9, `tsne_perp30.png` (color = método de proceso). |
| UMAP | Sí | `umap_vecinos15.png`. |
| Tendencia al agrupamiento: codo, silueta promedio y gap | Sí | `04-clustering/revision_clustering_profesor.R`, `resultados_clustering_profesor.txt`, `tendencia_codo_silueta_gap.png`. El gap elige k = 1 y la silueta, k = 2. |
| Dendrograma: cuántos grupos; silueta por grupo de Ward | Sí | `dendrograma_ward_k3.png`, `silueta_ward_por_grupo.png`. |
| El PCA no sirve para agrupar | Sí | Guion, diapositiva 4. |
| Semilla en K-means | Sí | `clustering.Rmd`: `set.seed(42)`, `nstart = 25`. Guion, diapositiva 5. |
| Prueba de proporciones | Sí | `resultados_clustering_profesor.txt`: χ² = 45,98, 2 g.l., p ≈ 1e-10 (humedad 0 por grupo K-means). |

## Retroalimentación sobre este proyecto

| Observación | Estado | Cómo se atiende |
|---|---|---|
| Orden: transformar las problemáticas y luego quitar atípicos | Sí | La cadena es Yeo-Johnson → estandarizar → Mahalanobis → volver a medir la asimetría. Explicado en la diapositiva 3 del guion. Salvedad que hay que decir: en los 970 lotes finales no queda ninguna variable por transformar, así que el PCA final solo estandariza. |
| Reportar los atípicos retirados | Sí | **100 lotes (9,3 %)** por distancia de Mahalanobis con χ² al 97,5 % y 8 g.l. (la cifra de 404 era un error de cálculo; ver `REVISION_DIEGO.md`). Guion, diapositiva 3. |
| Interpretar los grupos | Sí | K-means: perfiles en puntaje total, altitud mediana y proporción de humedad 0 (guion, diapositiva 5). Ward: perfiles por grupo (diapositiva 8). HDBSCAN solo se describe por tamaños; no se interpreta. |
| El dendrograma muestra 4 grupos, no 3 | Sí | Guion, diapositiva 7: se reconoce que admite 4 (alturas 5,53 · 4,50 · 3,75 · 3,17 · 3,11); con k = 4 el grupo de 42 se parte en 27 y 15 lotes; la silueta de Ward es 0,128 con k = 3 y 0,113 con k = 4. Ni la silueta global (mejor con k = 2) ni el gap respaldan k = 3: es una elección exploratoria. |

## Pendiente en Canva (no editable desde esta sesión)

- Reordenar para mostrar la nube de dispersión antes que las cargas.
- Diapositiva 3: dice "907 lotes" (debe ser 970).
- Notas de las diapositivas 7 a 10: aún dicen k = 8, 896 lotes, silueta 0,42, 82 % de coincidencia HDBSCAN/K-means y HDBSCAN con 3 clústeres.
- La diapositiva de K-means nombra los clusters Specialty, Premium y Commodity; el guion advierte que no se pueden llamar así.
