# Explorador interactivo del PCA

Esta carpeta contiene la aplicación Shiny que permite modificar los valores de las siete variables sensoriales y la altitud de un lote, proyectarlo en el espacio de componentes principales y compararlo con la matriz de referencia.

## Archivos

- [app.R](./app.R): código fuente de la aplicación Shiny.
- [app.html](./app.html): representación HTML estática del archivo de código. **No es la aplicación interactiva en ejecución.**

## Ejecutar localmente

1. Abre el proyecto de R desde la raíz del repositorio.
2. Verifica que exista el archivo datos/datos_final_627.rds.
3. Instala las dependencias de R utilizadas por la aplicación:

```r
install.packages(c("shiny", "dplyr", "ggplot2", "car"))
```

4. Desde la consola de R, situado en la raíz del proyecto, ejecuta:

```r
shiny::runApp("shiny")
```

Si la aplicación no encuentra el archivo RDS, verifica que el directorio de trabajo sea la raíz del repositorio y que exista `datos/datos_final_627.rds`. No cambies la ruta relativa del código sin ajustar también la estructura de ejecución.

La aplicación carga la matriz de referencia desde ../datos/datos_final_627.rds, por lo que debe conservarse esa estructura relativa de carpetas. El archivo `app.html` es una representación estática y debe actualizarse por separado cuando se regenere o publique una nueva versión de la aplicación.

## Qué representa la clasificación

Las etiquetas de calidad alta, media o baja son una **interpretación relativa implementada por la aplicación** respecto a los lotes de referencia. No constituyen una certificación CQI ni una predicción oficial de calidad.

## Interpretación de los componentes

La matriz de cargas del PCA final (627 lotes) permite sustentar estas interpretaciones:

- **CP1 (55,1 %):** las siete variables sensoriales tienen cargas negativas (entre -0,33 y -0,41); por ello, en la orientación almacenada, scores más negativos se asocian con mayores valores sensoriales.
- **CP2 (12,5 %):** está dominado por Altitud, cuya carga es -0,99. Scores más negativos se asocian con mayor altitud relativa.
- **CP3 (8,9 %):** contrapone principalmente Aroma y Acidez (cargas positivas) frente a Cuerpo y Balance (cargas negativas).

El signo de un componente puede invertirse sin cambiar la solución matemática. Por eso, las interpretaciones anteriores corresponden a la orientación concreta de las cargas almacenadas en este repositorio.

La proyección implementada aplica a las entradas las lambdas almacenadas y luego utiliza el centro, la escala y la matriz de cargas del PCA de referencia. La aplicación clasifica la calidad de forma relativa a los 627 lotes; no constituye una certificación CQI ni una predicción oficial.

## Publicación

GitHub Pages sirve archivos estáticos y no ejecuta por sí solo el servidor de una aplicación Shiny. Para ofrecer la interacción en línea se requiere desplegar la aplicación en un servicio que ejecute Shiny (por ejemplo, shinyapps.io o Posit Connect) y enlazar aquí la URL de esa instancia cuando exista.

---
*Este README describe la aplicación a partir del código fuente actual. No afirma que exista una instancia interactiva publicada.*