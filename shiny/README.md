# Explorador interactivo del PCA

Esta carpeta contiene la aplicación Shiny que permite modificar los valores de las siete variables sensoriales y la altitud de un lote, proyectarlo en el espacio de componentes principales y compararlo con la matriz de referencia.

## Archivos

- [app.R](./app.R): código fuente de la aplicación Shiny.
- [app.html](./app.html): representación HTML estática del archivo de código. **No es la aplicación interactiva en ejecución.**

## Ejecutar localmente

1. Abre el proyecto de R desde la raíz del repositorio.
2. Verifica que exista el archivo datos/datos_final_627.rds.
3. Instala las dependencias de R utilizadas por la aplicación (shiny, dplyr, ggplot2 y car).
4. Desde la consola de R, en la raíz del proyecto, ejecuta:

```r
shiny::runApp("shiny")
```

La aplicación carga la matriz de referencia desde ../datos/datos_final_627.rds, por lo que debe conservarse esa estructura relativa de carpetas.

## Qué representa la clasificación

Las etiquetas de calidad alta, media o baja son una **interpretación relativa implementada por la aplicación** respecto a los lotes de referencia. No constituyen una certificación CQI ni una predicción oficial de calidad.

## Interpretación de los componentes

La aplicación presenta CP1 como dirección de calidad sensorial, CP2 como contraste entre atributos y CP3 como componente asociado a la altitud. El código muestra las cargas del PCA que ajusta sobre `datos_final_627.rds`, pero estas interpretaciones deben contrastarse con los valores numéricos de la matriz de cargas del PCA final antes de afirmarlas en la sustentación. En particular, el signo de un componente puede invertirse sin cambiar la solución matemática, por lo que la regla «CP1 negativo = mayor calidad» depende de la orientación concreta de las cargas.

La proyección implementada aplica a las entradas las lambdas almacenadas, y luego utiliza el centro, la escala y la matriz de cargas del PCA de referencia. Esto describe la operación que realiza el código; no valida por sí solo la interpretación semántica de cada componente.

## Publicación

GitHub Pages sirve archivos estáticos y no ejecuta por sí solo el servidor de una aplicación Shiny. Para ofrecer la interacción en línea se requiere desplegar la aplicación en un servicio que ejecute Shiny (por ejemplo, shinyapps.io o Posit Connect) y enlazar aquí la URL de esa instancia cuando exista.

---
*Este README describe la aplicación a partir del código fuente actual. No afirma que exista una instancia interactiva publicada.*