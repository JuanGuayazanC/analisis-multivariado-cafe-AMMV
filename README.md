# Proyecto Final — Analítica y Métodos Multivariados
## Café Arábica · Coffee Quality Institute (CQI)

**Curso:** Analítica y Métodos Multivariados — Escuela Colombiana de Ingeniería Julio Garavito
**Docente:** Jaime Roberto Muñoz Luque, Ph.D.
**Autores:** Juan Sebastián Guayazán · Esteban Valente · Diego Nocua
**Dataset:** 1.070 lotes de café arábica — [Coffee Quality Institute](https://www.coffeeinstitute.org/)

---

## Descripción

Aplicación integral de los métodos de analítica multivariada vistos en el curso
sobre un dataset real de calidad de café arábica. Cada módulo corresponde a un
bloque temático del programa y reutiliza el mismo pipeline de preprocesamiento.

## Selección del dataset

Antes de empezar, se descargaron y analizaron tres candidatos con Python/pandas
(dimensiones, tipos de variable, valores faltantes, correlaciones, balance de
clases y outliers). Luego se consultó a cinco agentes de IA con enfoques
distintos (LLM Council: Contrarian, First Principles, Expansionist, Outsider y
Executor). Cada agente respondió sin ver a los demás, después revisó anónimamente
las cinco respuestas, y un agente sintetizó el veredicto final.

| Dataset | Tamaño | Hallazgo clave (verificado) | Decisión |
|---|---|---|---|
| Coffee Quality Institute (`arabica_data_cleaned.csv`) | 1.311 filas × 44 columnas | Variables de catación correlacionadas de forma natural (r ≈ 0,8–0,9) | **Elegido** |
| AI vs Human Academic Writing | 10.200 filas × 20 columnas | Dos variables (Typing_Speed r = 0,81; Revision_Count r = −0,87) casi resuelven la clasificación solas; desbalance 85/15 | Descartado: riesgo de resultados engañosos y poca exigencia multivariada |
| Smart City Traffic (CityFlow) | 204.000 filas × 47 columnas | Pares con r = 1,00 y 0,99: identidades algebraicas, no estructura latente. 94 vías repetidas miles de veces (pseudo-replicación) | Descartado: invalida la independencia de las observaciones |

**Recomendación del consejo:** usar CQI para el taller y para el proyecto final,
un solo dataset para las 17 semanas del semestre.

**Puntos ciegos detectados en la revisión cruzada**
- `Processing.Method` tiene grupos pequeños (56, 26 y 14 filas). El análisis discriminante puede fallar por matrices de covarianza casi singulares. Se decidió colapsar las categorías de procesamiento.
- `Total.Cup.Points` es prácticamente la suma de los atributos de catación. Usarla como respuesta en la regresión, después de usar esos mismos atributos en el análisis factorial, es una fuga de información. Por eso la regresión usa `Puntaje.Total` solo como referencia y se advierte en el notebook.
- `Country.of.Origin` tiene 36 niveles. Si se usa en discriminante, debe colapsarse a un grupo de países fijado de antemano, no elegido después de ver los resultados.
- Con 1.311 filas repartidas entre PCA, factorial, conglomerados, discriminante y regresión, cada técnica debe declarar si parte de las variables originales o reutiliza resultados previos.

**Antes de cada análisis**
- Probar un LDA rápido con `Processing.Method` y confirmar si hay matrices singulares.
- Definir la variable de clase del discriminante antes de ver resultados.
- Filtrar o imputar el outlier de altitud (190.164 m) y los 227 NA de esa columna.
- Evitar `Total.Cup.Points` como respuesta si sus componentes ya se usaron en el análisis factorial.

## Estructura del proyecto

Cada tema tiene su carpeta con su `.Rmd` (el HTML generado es el anexo que se
abre si preguntan por ese tema), sus scripts y sus figuras. Los datos
intermedios compartidos están en `datos/`.

```
├── data/                               ← CSV original (no modificar)
├── datos/                              ← .rds intermedios compartidos (leídos por 01-pca y shiny)
├── presentacion/                       ← guion de la presentación (texto y PDF)
├── clean_coffee_data.R/.html           ← limpieza inicial del CSV
│
├── 00-eda/                             ← Semanas 2-3: EDA (eda.Rmd) y eda_coffee.R, con HTML
├── 01-pca/                             ← PCA, Kernel PCA, t-SNE, UMAP
│   ├── figuras/                        ← figuras generadas, por tema
│   │   ├── revision_profesor/          ← revisión del profesor (PCA y agrupamiento)
│   │   │   ├── kpca_666/                   ← Kernel PCA (666 lotes)
│   │   ├── taller_666/                 ← taller PCA (666 lotes)
│   │   ├── pca_revision/               ← revisión PCA
│   │   └── proceso/                    ← proceso de depuración de atípicos
│   ├── pca_final.Rmd/.html             ← PCA final oficial: 627 lotes, 8 variables (demo y anexo)
│   ├── historico/                      ← informes del método anterior (11 y 8 variables); no son el oficial
│   ├── guia_teorica_reduccion_dimensional.Rmd/.html
│   ├── depuracion.Rmd/.html            ← cadena de depuración 1.070 → 666 → 627 y base de datos
│   ├── figuras_pca.Rmd/.html           ← figuras de la secuencia y justificación (en figuras/secuencia/)
│   └── historico/                      ← scripts fuente ya incluidos en depuracion.Rmd y figuras_pca.Rmd, y el método anterior
├── 02-factorial-correspondencias/      ← Semana 7: AF + análisis de correspondencias
├── 03-escalamiento/                    ← Semana 8: MDS y representación de proximidades
├── 04-clustering/                      ← K-means, Ward.D2, HDBSCAN y revisión del agrupamiento (R y Python)
│   └── figuras/revision_profesor/      ← figuras de la revisión de agrupamiento
├── 05-clasificacion/                   ← Semanas 12-13: LDA, QDA, SVM, Random Forest
├── 06-regresion/                       ← Semana 14: regresión lineal multivariada
├── 07-proyecto-final/                  ← Semanas 15-17: comparación integrada
├── scraper/                            ← scripts Python de extracción (cada uno con .html)
├── shiny/
│   ├── app.R / app.html                ← explorador PCA interactivo
└── imagenes_presentacion/              ← imágenes usadas en la presentación
```

## Tecnologías

- **R** — análisis estadístico principal (`prcomp`, `car`, `factoextra`, `dbscan`, `MASS`, `kernlab`, `Rtsne`, `uwot`)
- **Python** (complementario) — HDBSCAN
- **R Markdown** — documentos reproducibles con HTML knitteado
- **Shiny** — aplicación interactiva de exploración PCA

## Ejecución

HDBSCAN se ejecuta por separado con Python. El script lee el CSV, prepara su
propia matriz de análisis y guarda etiquetas, resumen de tamaños y gráfico en
`04-clustering/`:

```powershell
py -3.14 -m pip install -r 04-clustering/requirements-hdbscan.txt
py 04-clustering/hdbscan_python.py
```

Los scripts de `01-pca/` se ejecutan con `01-pca/` como directorio de trabajo,
porque leen y escriben rutas relativas a esa carpeta.
