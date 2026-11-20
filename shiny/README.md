# Explorador interactivo del PCA

Esta carpeta contiene la aplicación Shiny que permite modificar los valores de las siete variables sensoriales y la altitud de un lote, proyectarlo en el espacio de componentes principales y compararlo con la matriz de referencia.

## Archivos

- [app.R](./app.R): código fuente de la aplicación Shiny.
- [app_guia.Rmd](./app_guia.Rmd): guía explicada de la aplicación (qué es, cómo se usa, cómo funciona, cómo se lee el resultado y un ejemplo de demostración, con el código completo al final).
- [app.html](./app.html): resultado de renderizar `app_guia.Rmd`. **Es la guía, no la aplicación interactiva en ejecución.**

## Ejecutar localmente

1. Abre el proyecto de R desde la raíz del repositorio.
2. Verifica que existan los archivos datos/datos_final_970.rds y data/arabica_data_cleaned.csv (este último se usa para el panel de regresión).
3. Instala las dependencias de R utilizadas por la aplicación:

```r
install.packages(c("shiny", "dplyr", "ggplot2", "car"))
```

4. Desde la consola de R, situado en la raíz del proyecto, ejecuta:

```r
shiny::runApp("shiny")
```

Si la aplicación no encuentra el archivo RDS, verifica que el directorio de trabajo sea la raíz del repositorio y que exista `datos/datos_final_970.rds`. No cambies la ruta relativa del código sin ajustar también la estructura de ejecución.

La aplicación carga la matriz de referencia desde ../datos/datos_final_970.rds, por lo que debe conservarse esa estructura relativa de carpetas. El archivo `app.html` es una guía estática: se regenera con `rmarkdown::render("shiny/app_guia.Rmd", output_file = "app.html")` cuando cambie la aplicación.

## Qué representa la clasificación

Las etiquetas de calidad alta, media o baja son una **interpretación relativa implementada por la aplicación** respecto a los lotes de referencia. No constituyen una certificación CQI ni una predicción oficial de calidad.

## Regresión simple: puntaje total ~ CP1

La aplicación incluye un panel de **regresión lineal simple** entre el puntaje total de catación (`Total.Cup.Points`) y el score de CP1, ajustada con los 970 lotes de referencia: `puntaje total = 82,16 − 0,89 · CP1`, R² = 0,83. Al proyectar un lote, el panel marca su punto sobre la recta y da el puntaje total estimado con un intervalo de predicción del 95 %. Si el CP1 del lote queda fuera del rango de los lotes de referencia, la aplicación lo avisa como extrapolación.

Es una regresión **descriptiva**: el puntaje total se construye sumando los atributos sensoriales, así que CP1 (que los resume) lo explica casi por construcción. No es una predicción independiente ni una certificación del CQI. El análisis de regresión múltiple con variables que no forman parte del puntaje está en `06-regresion/`.

## Interpretación de los componentes

La matriz de cargas del PCA final (970 lotes) permite sustentar estas interpretaciones:

- **CP1 (69,3 %):** las siete variables sensoriales tienen cargas negativas (entre -0,35 y -0,39); por ello, en la orientación almacenada, scores más negativos se asocian con mayores valores sensoriales.
- **CP2 (11,6 %):** está dominado por Altitud, cuya carga es -0,98. Scores más negativos se asocian con mayor altitud relativa.
- **CP3 (5,3 %):** contrapone principalmente Aroma y Acidez (cargas negativas) frente a Cuerpo y Balance (cargas positivas). Con eigenvalor 0,42 queda por debajo del criterio de Kaiser; se muestra solo como contraste secundario.

El signo de un componente puede invertirse sin cambiar la solución matemática. Por eso, las interpretaciones anteriores corresponden a la orientación concreta de las cargas almacenadas en este repositorio.

La proyección implementada estandariza las entradas y luego utiliza el centro, la escala y la matriz de cargas del PCA de referencia. La aplicación clasifica la calidad de forma relativa a los 970 lotes; no constituye una certificación CQI ni una predicción oficial.

## Publicación

GitHub Pages sirve archivos estáticos y no ejecuta por sí solo el servidor de una aplicación Shiny. Para ofrecer la interacción en línea se requiere desplegar la aplicación en un servicio que ejecute Shiny (por ejemplo, shinyapps.io o Posit Connect) y enlazar aquí la URL de esa instancia cuando exista.

---
*Este README describe la aplicación a partir del código fuente actual. No afirma que exista una instancia interactiva publicada.*
