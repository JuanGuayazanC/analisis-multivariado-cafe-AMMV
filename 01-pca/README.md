# Análisis de componentes principales (PCA)

Este módulo documenta la preparación de los datos, el análisis de componentes principales y los métodos exploratorios complementarios. Para la sustentación conviene seguir el orden **depuración → PCA final → exploraciones complementarias**.

## Ruta principal para la sustentación

| Orden | Informe | ¿Cuándo abrirlo? |
|---|---|---|
| 1 | [Depuración: 1.070 → 970 (HTML)](https://juanguayazanc.github.io/analisis-multivariado-cafe-AMMV/01-pca/depuracion.html) | Si preguntan cómo se construyó la matriz final y qué ocurrió en cada etapa. |
| 2 | [PCA final: 970 lotes y 8 variables (HTML)](https://juanguayazanc.github.io/analisis-multivariado-cafe-AMMV/01-pca/pca_final.html) | Para explicar el modelo oficial, la selección de componentes, los scores, las cargas y el biplot. |
| 3 | [Secuencia de figuras PCA (HTML)](https://juanguayazanc.github.io/analisis-multivariado-cafe-AMMV/01-pca/figuras_pca.html) | Como apoyo visual secundario. Distingue diagnósticos de 1.070 lotes (base inicial) y de 970 lotes (matriz final). |

## Fuentes reproducibles

- [depuracion.Rmd](./depuracion.Rmd)
- [pca_final.Rmd](./pca_final.Rmd)
- [figuras_pca.Rmd](./figuras_pca.Rmd)

## Organización de los recursos visuales

La carpeta [`figuras/`](./figuras/) conserva los gráficos y tablas generados en las distintas etapas. Para ubicarlos rápidamente:

| Carpeta | Contenido | Uso recomendado |
|---|---|---|
| [`secuencia/`](./figuras/secuencia/) | Imágenes de diagnóstico, asimetría, varianzas, distancias, cargas y biplot (1.070 y 970 lotes). | Recorrido visual del proceso; comprobar siempre la etapa indicada en el nombre o título. |
| [`proceso/`](./figuras/proceso/) | Imágenes de los diagnósticos de Mahalanobis sobre los 1.070 lotes. | Explicar la depuración y sus etapas. |
| [`revision_profesor/`](./figuras/revision_profesor/) | Gráficos, tablas CSV y resultados de la revisión del PCA final. | Consultar cargas, varianza e intervalos bootstrap, biplot y representaciones exploratorias. |
| [`exploratorios/`](./figuras/exploratorios/) | Resultados organizados por método y base: Kernel PCA, UMAP, t-SNE y MDS. | Comparar métodos complementarios sin confundirlos con el PCA oficial. |
| [`taller_970/`](./figuras/taller_970/) | Figuras del taller (PCA, Kernel PCA, t-SNE y UMAP) sobre la matriz final de 970 lotes. | Apoyo del taller; coinciden con la matriz del PCA final. |
| [`pca_revision/`](./figuras/pca_revision/) | Codo, cargas y biplot del PCA final de 970 lotes, con fondo transparente. | Imágenes de las diapositivas. |

**Nota de trazabilidad:** que una figura esté guardada en el repositorio no significa que corresponda a la matriz final de 970 lotes. Antes de presentarla, verifica el tamaño de muestra, las variables y la etapa que indica su título o el documento que la genera.

## Informes complementarios

- [Métodos exploratorios: Kernel PCA, UMAP, t-SNE y MDS (HTML)](https://juanguayazanc.github.io/analisis-multivariado-cafe-AMMV/01-pca/metodos_exploratorios.html) — comparaciones exploratorias; no reemplazan el PCA oficial ni definen por sí solas grupos.
- [Guía teórica de reducción dimensional (HTML)](https://juanguayazanc.github.io/analisis-multivariado-cafe-AMMV/01-pca/guia_teorica_reduccion_dimensional.html) — apoyo conceptual.
- [Carpeta de figuras](./figuras/) — gráficos organizados por proceso, secuencia, revisión y exploraciones.
- [Histórico](./historico/) — scripts e informes de etapas y métodos anteriores; consultar como antecedente, no como resultado oficial vigente.

## Cifras que no se deben mezclar

La cadena documentada en el proceso de depuración es **1.070 → 970 lotes** (una sola pasada de Mahalanobis: 100 lotes retirados). El PCA final oficial se presenta sobre **970 lotes y 8 variables**. Las figuras y documentos de métodos exploratorios también muestran la base inicial de 1.070 lotes; siempre verifica el tamaño de muestra indicado en el título o sección antes de comparar resultados. Las cifras de 666 y 627 lotes de versiones anteriores provenían de un error de cálculo de la distancia de Mahalanobis (ver `../REVISION_DIEGO.md`) y ya no son vigentes.

El PCA final reevalúa la asimetría sobre los 970 lotes: ninguna variable supera |asimetría| > 1, así que no se aplica Yeo-Johnson y solo se estandariza. No tomes cifras de varianza, cargas o porcentajes de informes históricos como si fueran resultados del PCA final.

## Guion breve para responder preguntas

1. **¿Cómo se prepararon los datos?** Abrir *Depuración* y recorrer la cadena 1.070 → 970.
2. **¿Qué análisis se tomó como definitivo?** Abrir *PCA final*, que identifica explícitamente 970 lotes y 8 variables.
3. **¿Qué significan las figuras adicionales?** Abrir *Secuencia de figuras* o *Métodos exploratorios*, aclarando a qué base corresponde cada resultado.

---
*Los informes HTML son archivos publicados. Los cambios en los Rmd no regeneran automáticamente esos HTML; para actualizar los resultados se debe renderizar el documento en R y publicar el HTML resultante.*
