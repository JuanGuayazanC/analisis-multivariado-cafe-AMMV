# Análisis Multivariado — Reducción de Dimensionalidad en Datos de Calidad de Café

**Curso:** Análisis Multivariado y Métodos de Visualización (AMMV)  
**Autor:** Juan Sebastian Guayazan  
**Institución:** Universidad EAN  
**Año:** 2026

---

## Descripción del proyecto

Este repositorio contiene el taller de reducción de dimensionalidad desarrollado para el curso AMMV. Se aplican y comparan cuatro métodos — **PCA**, **Kernel PCA**, **t-SNE** y **UMAP** — sobre un conjunto de datos real de calidad de café arábica, con el objetivo de responder:

> ¿Qué información de los datos intenta preservar cada método y qué se puede interpretar a partir de la representación obtenida?

---

## Datos

**Fuente:** [Coffee Quality Institute (CQI)](https://database.coffeeinstitute.org/), a través del repositorio original [jldbc/coffee-quality-database](https://github.com/jldbc/coffee-quality-database).

**Conjunto activo:** 1.070 lotes de café arábica evaluados por catadores certificados (Q Graders), con 11 variables cuantitativas tras el tratamiento de datos.

### Variables del análisis principal (11 variables)

| Variable | Descripción | Unidad |
|---|---|---|
| Aroma | Puntaje de aroma | 0–10 |
| Flavor | Puntaje de sabor | 0–10 |
| Aftertaste | Puntaje de retrogusto | 0–10 |
| Acidity | Puntaje de acidez | 0–10 |
| Body | Puntaje de cuerpo | 0–10 |
| Balance | Puntaje de balance | 0–10 |
| Uniformity | Puntaje de uniformidad taza a taza | 0–10 |
| Clean.Cup | Puntaje de limpieza de taza | 0–10 |
| Sweetness | Puntaje de dulzura | 0–10 |
| Cupper.Points | Puntaje global del catador | 0–10 |
| altitude_mean_meters | Altitud media de la finca | metros |

> **Variables excluidas del análisis principal:** `Category.One.Defects`, `Category.Two.Defects` y `Moisture` presentan inflación de ceros que Yeo-Johnson no puede corregir (la optimización no converge). Se mantienen en la sección de análisis de sensibilidad (sección 18.1 del informe) como evidencia del antes/después.

---

## Metodología

### Preprocesamiento
- Filtrado de valores faltantes y valor corrupto en altitud (~190.000 m)
- Detección de valores atípicos univariados con diagramas de cajas ajustados (Hubert & Vandervieren, 2008), usando el *medcouple* como corrección por asimetría
- **Transformación Yeo-Johnson** aplicada a las 11 variables del análisis principal con lambda óptimo estimado por máxima verosimilitud (`car::powerTransform`), para reducir el sesgo residual y los patrones no elípticos en la nube de dispersión de scores

### Métodos de reducción de dimensionalidad

| Método | Tipo | Paquete R | Característica principal |
|---|---|---|---|
| PCA | Lineal | `stats::prcomp` | Maximiza varianza; interpretable por cargas |
| Kernel PCA | No lineal | `kernlab::kpca` | Captura estructura no lineal vía kernel RBF |
| t-SNE | No lineal | `Rtsne::Rtsne` | Preserva vecindades locales; sensible a perplejidad |
| UMAP | No lineal | `uwot::umap` | Balance entre estructura local y global |

### Selección del número de componentes (PCA)
Regla del codo + criterio de Kaiser (valores propios > 1): se retienen **4 componentes** que explican ~75% de la varianza total.

---

## Estructura del repositorio

```
├── analisis-multivariado/
│   ├── informe_taller_pca.Rmd       # Informe principal (código + análisis + teoría)
│   ├── informe_taller_pca.html      # Informe renderizado
│   ├── comparacion_pca/             # Imágenes antes/después de la transformación YJ
│   ├── imagenes_canva/              # Figuras exportadas para la presentación
│   └── guia_teorica_reduccion_dimensional.Rmd  # Guía teórica complementaria
├── data/
│   ├── arabica_data_cleaned.csv     # Datos arábica limpios (fuente original)
│   └── arabica_ratings_raw.csv      # Datos arábica crudos
└── scraper/                         # Scripts originales de scraping (jldbc)
```

---

## Hallazgos principales

1. **PC1 (≈ 50 % de la varianza):** eje único de calidad sensorial general — todos los atributos de catación cargan con el mismo signo. Es el "ranking de qué tan buena es la taza".

2. **PC2:** contraste entre consistencia/dulzura (Sweetness, Uniformity, Clean.Cup) e intensidad sensorial (Flavor, Aroma, Acidity).

3. **PC3:** eje de altitud de producción, prácticamente independiente del bloque sensorial.

4. **PC4:** residuo de variación sensorial fina; contraste secundario dentro del bloque de intensidad.

5. **Kernel PCA (RBF):** confirma la estructura lineal de PC1 — no emerge estructura no lineal relevante en los datos de calidad sensorial de café.

6. **t-SNE y UMAP:** revelan que los lotes con `Moisture = 0` (mediciones faltantes codificadas como cero) forman un clúster artificial separado del resto, validando la decisión de excluir esa variable del análisis principal.

---

## Requisitos

```r
# Paquetes R necesarios
install.packages(c(
  "dplyr", "robustbase", "car",
  "kernlab", "Rtsne", "uwot",
  "ggplot2", "corrplot"
))
```

**Versión de R:** 4.4.3  
**Versión de RStudio:** compatible con RStudio 2024+

---

## Créditos

- Datos originales: [jldbc/coffee-quality-database](https://github.com/jldbc/coffee-quality-database) (James LeDoux, 2018)
- Datos recolectados del sitio del [Coffee Quality Institute](https://database.coffeeinstitute.org/)
