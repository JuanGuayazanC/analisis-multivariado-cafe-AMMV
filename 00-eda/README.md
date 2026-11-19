# Análisis exploratorio de datos (EDA)

Este módulo describe la estructura y el comportamiento inicial de los datos de calidad de café Arábica del Coffee Quality Institute (CQI). Es el punto de partida de la sustentación: **conocer los datos antes de preparar la matriz del PCA**.

## Informe para consultar

- [Abrir informe EDA (HTML)](https://juanguayazanc.github.io/analisis-multivariado-cafe-AMMV/00-eda/eda.html)
- [Consultar fuente reproducible (R Markdown)](./eda.Rmd)

## Cómo está organizado el análisis

1. **Carga y preparación:** lectura de arabica_data_cleaned.csv, selección de variables y filtros aplicados en este documento.
2. **Estadísticos multivariados:** vector de medias, matriz de covarianzas, traza, determinante y matriz de correlaciones.
3. **Visualización:** diagramas de cajas y matriz de dispersión.
4. **Distancias:** ejemplos de distancia euclídea estandarizada y distancia de Mahalanobis.
5. **Anexo complementario:** exploración visual de las 14 variables cuantitativas originales.

## Alcance y lectura correcta

- El bloque principal calcula los estadísticos sobre **11 variables continuas**.
- El anexo complementario presenta visualizaciones de **14 variables cuantitativas**. No debe confundirse con la matriz de 11 variables del análisis principal.
- Los filtros y el número de observaciones corresponden a lo que ejecuta este R Markdown; para conocer la matriz usada en el PCA final, consulta el informe de depuración y el PCA final en 01-pca/.
- La identificación de observaciones atípicas mediante Mahalanobis es un diagnóstico exploratorio; por sí sola no implica que esas observaciones se eliminen automáticamente.

## Ruta de sustentación

**Pregunta que responde:** ¿Cómo son los datos y qué características deben tenerse en cuenta antes del análisis multivariado?

Después de este informe, continúa con [la depuración y preparación para PCA](../01-pca/README.md).

---
*Los resultados HTML corresponden a la última versión renderizada que se haya publicado. Modificar el archivo Rmd no actualiza automáticamente el HTML.*