# Revisión de la parte de Diego Nocua

Archivos revisados: `01-pca/metodos_exploratorios.Rmd`, `03-escalamiento/escalamiento_mds.Rmd`, `04-clustering/clustering.Rmd`, `04-clustering/revision_clustering_profesor.R`, `05-clasificacion/clasificacion.Rmd` y `06-regresion/regresion.Rmd`.

Todos se volvieron a ejecutar en R 4.3 y los HTML de esta carpeta se generaron con el código corregido.

## Error que afecta a todo el proyecto (no es de Diego)

En `depuracion.Rmd`, `pca_final.Rmd` y `figuras_pca.Rmd` la distancia de Mahalanobis se calcula con `rowSums((pre$x / pre$sdev)^2)`. En R, dividir una matriz entre un vector recicla el vector por filas, no por columnas, así que cada score se divide por la desviación de otra componente.

| Cálculo | Atípicos en 1.070 lotes |
|---|---|
| Código actual | 404 |
| Correcto: `sweep(pre$x, 2, pre$sdev, "/")` o `mahalanobis()` | **100** |

Las bases de 666 y 627 lotes, el PCA "oficial" (55,1 % / 12,5 %) y la app de Shiny vienen de ese error. Las secciones 2 a 4 de `metodos_exploratorios.Rmd` usan esas bases; quedan bien en cuanto a su código, pero heredan el problema.

## 1. `metodos_exploratorios.Rmd`

| # | Error | Corrección |
|---|---|---|
| 1 | **% de varianza de Kernel PCA inflado.** `kp@eig` guarda solo los primeros 8 valores propios, y el código dividía entre su suma. Así se obtiene la proporción dentro de esas 8 componentes, no la de la inercia total. Ejemplo con 627 lotes y RBF σ = 0,1: CP1 aparecía con 33,4 %, pero la cifra real es **18,9 %** (las 8 CP explican solo el 56,5 %). Con RBF σ = 1, CP1 pasa de 19,0 % a 1,3 %. | El porcentaje se calcula sobre la traza de la matriz núcleo doblemente centrada. Se agregan las columnas `acum_CP1_8` y `autovalores_neg`. |
| 2 | `tanhdot`, `besseldot` y `splinedot` dan valores propios negativos: no son núcleos válidos (semidefinidos positivos) con estos datos. | Se informan y se advierte que sus porcentajes son solo de referencia. |
| 3 | La base "1.070 sin atípicos" tiene en realidad **970** lotes. | Se corrigen títulos y texto. |
| 4 | Varianza total = 112.993 y generalizada = 5,18e17, calculadas sobre datos transformados sin estandarizar (λ ≈ 3, altitud en metros). No son interpretables. | Se calculan sobre R: traza = 8 y det(R) = 0,023. |
| 5 | La figura `kpca_666` se guardaba en `figuras/kpca_666/`, fuera de `exploratorios/`. | Se corrige la ruta. |
| 6 | Hay tres copias idénticas de la lista de núcleos y del bucle. | Se reemplazan por una sola función. |
| 7 | t-SNE de la sección 4 usaba `pca = TRUE` y la sección 5 `pca = FALSE`; además, la semilla no se fijaba en cada corrida. | Se usa la misma configuración en ambas y una semilla por corrida. |
| 8 | El zoom del MDS hacía `xlim = cuantiles * 1,1`, que solo funciona si el rango cruza el cero. | Se usa un margen del 5 % del rango. |

**Para la presentación:** si `kpca_00_resumen_kernels.png` u otra figura muestra los porcentajes viejos de Kernel PCA, hay que actualizarla con los nuevos CSV.

## 2. `escalamiento_mds.Rmd`

| # | Error | Corrección |
|---|---|---|
| 1 | **El Rmd no compilaba:** el color `"#ccc"` hace fallar a ggplot actual. El HTML entregado era de una versión anterior y mostraba cifras (52,5 % + 16,1 %, stress 11,6) que el Rmd ya no produce. | Se cambia a `"#cccccc"` y se regenera el HTML. |
| 2 | Se usaba `library(smacof)` sin usarlo. | Se elimina. |
| 3 | El preprocesamiento no era el del proyecto. Usaba 11 variables, incluidas las 3 descartadas por efecto techo, con Yeo-Johnson aplicado a todas y λ recortados a ±3. | Se usa `base_1070.rds`: 8 variables y Yeo-Johnson selectivo. |
| 4 | Se trabajaba con una muestra de 150 lotes, sin necesidad. | Se usan los 1.070 lotes. Resultado: 67,2 % + 11,9 % = 79,1 %, stress no métrico 6,1 % ("bueno"). |
| 5 | Al corregir lo anterior aparecían 547 "autovalores negativos", pero son ceros numéricos (±1e-12). Con distancia euclídea no existen autovalores negativos reales. | Se cuenta con tolerancia: 8 positivos y 0 negativos. |

## 3. `clustering.Rmd`

| # | Error | Corrección |
|---|---|---|
| 1 | El texto dice "14 columnas dummy", pero son 15. | Se corrige. |
| 2 | "Los números 3 o 8…": el 8 es un resto de una versión vieja. | Se reescribe. |
| 3 | El "rango" de WSS imprimía los 20 valores unidos por "a". | Se usa `range()`. |
| 4 | Faltaba la sección 8 (de la 7 se saltaba a la 9). | Se renumera. |
| 5 | **Los perfiles de Ward del guion (7,71 de aroma y 82,9 puntos) no tenían código en el repositorio.** | Se agrega la sección 6.1, que los reproduce: G1 = 82,86, G2 = 82,72, G3 = 79,90. |
| 6 | El anexo hablaba de "dos bases de 1.070" (la segunda tiene 970) y no aclaraba que usa **otra matriz**: 8 numéricas, sin dummies, con Ward sobre todos los lotes. | Se aclara, junto con el hecho de que HDBSCAN en R deja ahí el 100 % como ruido. |
| 7 | La conclusión no mencionaba que el gap elige k = 1 y la silueta k = 2. | Se agrega. |

## 4. `revision_clustering_profesor.R`

| # | Error | Corrección |
|---|---|---|
| 1 | No se podía generar el HTML con `rmarkdown::render()`: los separadores `# ---- … ----` se interpretan como encabezados de chunk y fallan. | Se cambian por `# == … ==`. |
| 2 | La frase "El mayor salto es entre 1 y 2 grupos…" estaba escrita a mano. | Ahora se calcula. |
| 3 | No creaba `figuras/revision_profesor/` ni verificaba el directorio de trabajo. | Se agregan ambas cosas. |
| 4 | No interpretaba el gap = 1. | Se agrega la interpretación y la advertencia de que la referencia uniforme es poco realista con columnas binarias. |

## 5. `clasificacion.Rmd` (no tenía HTML)

| # | Error | Corrección |
|---|---|---|
| 1 | **Fuga de información:** Yeo-Johnson se estimaba con toda la base antes de partir en train/test. | Los λ se estiman solo en train. |
| 2 | El Kappa se multiplicaba por 100 como si fuera un porcentaje. | Se reporta en su escala (0–1). |
| 3 | El comentario de QDA dice "Uniformidad", pero la variable excluida es Taza Limpia. | Se corrige. |
| 4 | La circularidad solo se advertía con texto. | Se muestra con números: la regla "suma de atributos" acierta el **98,5 %** sin ningún modelo. |
| 5 | No había una medida predictiva honesta. | Se agrega la sección 8 con variables que no forman la etiqueta (altitud, humedad, defectos, proceso y país). Random Forest acierta **56,6 %** frente a 50,6 % de la tasa de no información (Kappa 0,26). |

Resultados: SVM 94,4 %, RF 92,9 %, LDA 79,4 %, QDA 79,4 %.

## 6. `regresion.Rmd`

| # | Error | Corrección |
|---|---|---|
| 1 | **El HTML estaba desactualizado y el Rmd no compilaba:** el color `"#333"` lo rompía. | Se corrige y se regenera el HTML. |
| 2 | Un lote con **todo en 0** (registro vacío) quedaba en el modelo. Dominaba la regresión simple: el intercepto de 21,49 es exactamente su residuo. | Se excluye y se informa. Sin él, la regresión simple da R² = 0,71 (antes 0,80, inflado por ese punto). |
| 3 | R² = 1 es una identidad contable: el puntaje total es la suma de los 10 atributos. Los diagnósticos y los valores p no tienen sentido. | Se demuestra en la sección 1.1 y se advierte. |
| 4 | Decía "puntaje total del catador". | Se cambia a "puntaje total de taza" (el del catador es `Cupper.Points`). |
| 5 | No había un modelo con contenido real. | Se agrega la sección 7, con predictores de origen y grano verde: R² en train 0,195 y **R² predictivo en test 0,131**. Altitud, defectos de categoría 2 y país son significativos. |
| 6 | `regresion_ramdomForest.html` no tiene Rmd fuente y su título interno es "regresion.knit". | Se recomienda borrarlo o subir su fuente. |

## Inconsistencias en el guion de la presentación

- **Diapositiva 6 (HDBSCAN):** las cifras "5 grupos (39, 52, 101, 96, 89), 693 de ruido, tamaño mínimo 20" no coinciden con ninguna salida guardada:
  - `hdbscan_tamanos.csv`: 6 grupos y 58,5 % de ruido, con tamaño mínimo 10 por defecto.
  - `clustering_HDBSCAN.html`: 6 grupos y 57 % de ruido.
- **Diapositiva 7:** "Silhouette con k = 3 ligeramente mejor que con k = 4" es cierto (0,115 frente a 0,114), pero la mejor es k = 2 (0,151) y el gap elige k = 1. No se debe decir que el ARI de 0,471 "refuerza que hay una estructura real".
- **Diapositiva 8:** el grupo 1 de Ward no es "el más intenso en casi todos los atributos". El grupo 2 lo supera en acidez, balance y puntaje del catador; solo destaca en aroma.

## 7. `01-pca/depuracion.Rmd` y `01-pca/pca_final.Rmd` (Mahalanobis)

| # | Error | Corrección |
|---|---|---|
| 1 | **La distancia de Mahalanobis estaba mal calculada:** `rowSums((pre$x / pre$sdev)^2)`. En R, dividir una matriz entre un vector recicla el vector por filas, no por columnas, así que cada score se dividía entre la desviación de otra componente. Marcaba **404** atípicos en vez de **100**. | Se usa `sweep(pre$x, 2, pre$sdev, "/")`, que divide cada columna entre su propia desviación. El documento comprueba que da lo mismo que `mahalanobis()` (diferencia máxima 4e-13) y muestra que el código anterior marcaba 404. |
| 2 | Como el primer filtro estaba mal, la cadena hacía una segunda pasada: **1.070 → 666 → 627**. | Una sola pasada: **1.070 → 970**. Una segunda pasada marcaría 63 lotes más; se informa como referencia, pero no se retiran, porque repetir el filtro seguiría quitando lotes en cada vuelta. |
| 3 | `pca_final.Rmd` ajustaba el PCA oficial sobre 627 lotes. | Ahora lo ajusta sobre 970: CP1 69,3 %, CP2 11,6 %, acumulado 80,9 % (IC bootstrap 79,3–82,5 %). Son las mismas cifras de la exposición. |

Notas:
- Se crea `datos/datos_final_970.rds`, con la misma estructura que los archivos de 666 y 627.
- **No se borraron ni se cambiaron** `datos_final_666.rds` ni `datos_final_627.rds`, porque `figuras_pca.Rmd`, `metodos_exploratorios.Rmd` y `shiny/app.R` todavía los leen. Esos tres archivos siguen trabajando con 627/666 y habría que pasarlos a 970.
- Sin los 100 atípicos, ninguna variable tiene |asimetría| > 1 (la mayor es altitud, −0,69). Con la misma regla del proyecto, el PCA de 970 no aplica Yeo-Johnson. Aplicarlo de todas formas a los 7 atributos daría prácticamente lo mismo (69,2 % y 11,6 %).
- Las figuras viejas `figuras/proceso/paso3_mahalanobis_666.png` y `figuras/revision_profesor/seq*_...png` ya no se generan. Se pueden borrar.
