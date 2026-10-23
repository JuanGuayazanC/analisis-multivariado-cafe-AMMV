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

**Registros totales en el dataset:** 1.312 lotes (1.311 arábica + 28 robusta). Tras filtrar altitudes faltantes o fuera de rango (0–3.000 msnm), el **conjunto activo del análisis es de 1.070 lotes arábica**.

El dataset original contiene **43 columnas** (más el índice de fila), divididas en variables cualitativas y cuantitativas:

---

### Variables cualitativas (categóricas)

| Variable | Descripción |
|---|---|
| `Species` | Especie del café (Arabica / Robusta) |
| `Owner` | Propietario del lote |
| `Country.of.Origin` | País de origen de la finca |
| `Farm.Name` | Nombre de la finca |
| `Lot.Number` | Número de lote asignado por el productor |
| `Mill` | Nombre del beneficio/molino donde se procesó |
| `ICO.Number` | Número de registro ICO (International Coffee Organization) |
| `Company` | Empresa exportadora o comercializadora |
| `Altitude` | Altitud declarada por el productor (campo de texto libre, sin estandarizar) |
| `Region` | Región geográfica dentro del país de origen |
| `Producer` | Nombre del productor |
| `Bag.Weight` | Peso del saco (texto, p.ej. "60 kg") |
| `In.Country.Partner` | Socio local del CQI en el país de origen |
| `Harvest.Year` | Año de cosecha (campo de texto, no siempre numérico) |
| `Grading.Date` | Fecha de evaluación por el catador |
| `Owner.1` | Campo alternativo de propietario (duplicado parcial de `Owner`) |
| `Variety` | Variedad botánica del grano (Bourbon, Typica, Caturra, etc.) |
| `Processing.Method` | Método de beneficio (Washed, Natural, Honey, etc.) |
| `Color` | Color del grano en pergamino (Green, Blue-Green, etc.) |
| `Expiration` | Fecha de vencimiento de la certificación |
| `Certification.Body` | Organismo certificador que avaló la cata |
| `Certification.Address` | Dirección del organismo certificador |
| `Certification.Contact` | Contacto del organismo certificador |
| `unit_of_measurement` | Unidad de medida de altitud reportada (m / ft) |

---

### Variables cuantitativas

#### Puntajes de catación — escala 0 a 10

Evaluados por Q Graders certificados por el CQI. Las 10 variables de intensidad sensorial más el puntaje global del catador.

| Variable | Descripción |
|---|---|
| `Aroma` | Intensidad y calidad del aroma del café preparado |
| `Flavor` | Sabor percibido durante la degustación |
| `Aftertaste` | Persistencia y calidad del retrogusto |
| `Acidity` | Viveza y brillo de la acidez |
| `Body` | Sensación de cuerpo o peso en boca |
| `Balance` | Armonía entre todos los atributos sensoriales |
| `Uniformity` | Consistencia entre las 5 tazas evaluadas del mismo lote |
| `Clean.Cup` | Ausencia de sabores extraños o defectos en taza |
| `Sweetness` | Presencia de dulzura natural |
| `Cupper.Points` | Puntaje holístico asignado por el catador |
| `Total.Cup.Points` | **Suma** de los 10 puntajes anteriores *(excluida del PCA por colinealidad perfecta)* |

#### Variables de calidad física del grano

| Variable | Descripción | Unidad |
|---|---|---|
| `Moisture` | Humedad del grano al momento de la cata | % |
| `Category.One.Defects` | Conteo de defectos primarios (granos negros, vinagres, etc.) | unidades |
| `Category.Two.Defects` | Conteo de defectos secundarios (granos partidos, conchas, etc.) | unidades |
| `Quakers` | Conteo de granos inmaduros (no oscurecen al tostar) | unidades |

#### Variables logísticas y agroclimáticas

| Variable | Descripción | Unidad |
|---|---|---|
| `Number.of.Bags` | Número de sacos del lote | sacos |
| `altitude_low_meters` | Límite inferior del rango de altitud de la finca | metros |
| `altitude_high_meters` | Límite superior del rango de altitud de la finca | metros |
| `altitude_mean_meters` | Altitud media de la finca *(usada en el análisis)* | metros |

---

### Variables del análisis principal (11)

Del total de variables cuantitativas, el análisis PCA usa las siguientes 11, tras excluir las que presentan problemas de calidad de datos no corregibles:

| Variable | Rol en el PCA |
|---|---|
| Aroma, Flavor, Aftertaste, Acidity, Body, Balance, Uniformity, Clean.Cup, Sweetness, Cupper.Points | Bloque sensorial — definen PC1 (calidad general) y PC2 (consistencia vs. intensidad) |
| `altitude_mean_meters` | Variable agroclimática — define PC3 (altitud de producción) |

> **Variables cuantitativas excluidas del análisis principal:**
> - `Total.Cup.Points`: suma exacta de los 10 puntajes → colinealidad perfecta con el bloque sensorial.
> - `Moisture`, `Category.One.Defects`: inflación de ceros (la mayoría de lotes tiene valor 0); Yeo-Johnson no converge para estas variables.
> - `Category.Two.Defects`: transformada con Yeo-Johnson (λ ≈ −0.22) en el análisis exploratorio de la sección 3.2, pero excluida del análisis principal por coherencia con la exclusión de Cat1 y Moisture.
> - `Quakers`, `Number.of.Bags`, `altitude_low_meters`, `altitude_high_meters`: redundantes o con alta proporción de datos faltantes.

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
