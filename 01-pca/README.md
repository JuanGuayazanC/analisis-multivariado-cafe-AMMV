# Análisis de componentes principales (PCA)

Este módulo documenta la preparación de los datos, el análisis de componentes principales y los métodos exploratorios complementarios. Para la sustentación conviene seguir el orden **depuración → PCA final → exploraciones complementarias**.

## Ruta principal para la sustentación

| Orden | Informe | ¿Cuándo abrirlo? |
|---|---|---|
| 1 | [Depuración: 1.070 → 666 → 627 (HTML)](https://juanguayazanc.github.io/analisis-multivariado-cafe-AMMV/01-pca/depuracion.html) | Si preguntan cómo se construyó la matriz final y qué ocurrió en cada etapa. |
| 2 | [PCA final: 627 lotes y 8 variables (HTML)](https://juanguayazanc.github.io/analisis-multivariado-cafe-AMMV/01-pca/pca_final.html) | Para explicar el modelo oficial, la selección de componentes, los scores, las cargas y el biplot. |
| 3 | [Secuencia de figuras PCA (HTML)](https://juanguayazanc.github.io/analisis-multivariado-cafe-AMMV/01-pca/figuras_pca.html) | Como apoyo visual secundario. La fuente distingue ahora diagnósticos de 1.070, 666 y 627; el HTML publicado debe regenerarse para reflejar esa explicación. |

## Fuentes reproducibles

- [depuracion.Rmd](./depuracion.Rmd)
- [pca_final.Rmd](./pca_final.Rmd)
- [figuras_pca.Rmd](./figuras_pca.Rmd)

## Organización de los recursos visuales

La carpeta [`figuras/`](./figuras/) conserva los gráficos y tablas generados en las distintas etapas. Para ubicarlos rápidamente:

| Carpeta | Contenido | Uso recomendado |
|---|---|---|
| [`secuencia/`](./figuras/secuencia/) | 12 imágenes de diagnóstico, transformación, varianzas, distancias, cargas y biplot. | Recorrido visual del proceso; comprobar siempre la etapa indicada en el nombre o título. |
| [`proceso/`](./figuras/proceso/) | 3 imágenes asociadas a los diagnósticos de atípicos en 1.070 y 666 lotes. | Explicar la depuración y sus etapas. |
| [`revision_profesor/`](./figuras/revision_profesor/) | Gráficos, tablas CSV y resultados de la revisión del PCA final. | Consultar cargas, varianza e intervalos bootstrap, biplot y representaciones exploratorias. |
| [`exploratorios/`](./figuras/exploratorios/) | Resultados organizados por método y base: Kernel PCA, UMAP, t-SNE y MDS. | Comparar métodos complementarios sin confundirlos con el PCA oficial. |
| [`taller_666/`](./figuras/taller_666/) y [`kpca_666/`](./figuras/kpca_666/) | Figuras del taller y Kernel PCA sobre 666 lotes. | Material histórico o de apoyo; no atribuirlo al PCA final de 627 lotes. |

**Nota de trazabilidad:** que una figura esté guardada en el repositorio no significa que corresponda a la matriz final de 627 lotes. Antes de presentarla, verifica el tamaño de muestra, las variables y la etapa que indica su título o el documento que la genera.

## Informes complementarios

- [Métodos exploratorios: Kernel PCA, UMAP, t-SNE y MDS (HTML)](https://juanguayazanc.github.io/analisis-multivariado-cafe-AMMV/01-pca/metodos_exploratorios.html) — comparaciones exploratorias; no reemplazan el PCA oficial ni definen por sí solas grupos.
- [Guía teórica de reducción dimensional (HTML)](https://juanguayazanc.github.io/analisis-multivariado-cafe-AMMV/01-pca/guia_teorica_reduccion_dimensional.html) — apoyo conceptual.
- [Carpeta de figuras](./figuras/) — gráficos organizados por proceso, secuencia, revisión y exploraciones.
- [Histórico](./historico/) — scripts e informes de etapas y métodos anteriores; consultar como antecedente, no como resultado oficial vigente.

## Cifras que no se deben mezclar

La cadena documentada en el proceso de depuración es **1.070 → 666 → 627 lotes**. El PCA final oficial se presenta sobre **627 lotes y 8 variables**. Las figuras y documentos de métodos exploratorios pueden mostrar otras bases (por ejemplo, 1.070 o 666); siempre verifica el tamaño de muestra indicado en el título o sección antes de comparar resultados. En particular, `figuras_pca.Rmd` combina diagnósticos de distintas etapas y contiene un bloque exploratorio de Mahalanobis que aplica lambdas del objeto de 666 a filas de la base inicial de 1.070; no debe tratarse como resultado del PCA final.

El PCA final reestima los parámetros de Yeo-Johnson sobre la matriz final de 627 lotes y después estandariza. No tomes cifras de varianza, cargas o porcentajes de informes históricos como si fueran resultados del PCA final.

## Guion breve para responder preguntas

1. **¿Cómo se prepararon los datos?** Abrir *Depuración* y recorrer la secuencia 1.070 → 666 → 627.
2. **¿Qué análisis se tomó como definitivo?** Abrir *PCA final*, que identifica explícitamente 627 lotes y 8 variables.
3. **¿Qué significan las figuras adicionales?** Abrir *Secuencia de figuras* o *Métodos exploratorios*, aclarando a qué base corresponde cada resultado.

---
*Los informes HTML son archivos publicados. Los cambios en los Rmd no regeneran automáticamente esos HTML; para actualizar los resultados se debe renderizar el documento en R y publicar el HTML resultante.*