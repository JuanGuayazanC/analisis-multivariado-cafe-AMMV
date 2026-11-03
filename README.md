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
bloque temático del programa y se desarrolla de forma progresiva, reutilizando
el mismo pipeline de preprocesamiento.

## Estructura del proyecto

```
├── data/
│   └── arabica_data_cleaned.csv        ← dataset original (no modificar)
│
├── 00-eda/
│   └── eda.Rmd                         ← Semanas 2-3: EDA, matrices, distancias
│
├── 01-pca/
│   ├── informe_antes.Rmd               ← PCA con 14 vars (estado problemático)
│   └── informe_despues.Rmd             ← PCA corregido: 11 vars + YJ completo
│
├── 02-factorial-correspondencias/
│   └── factorial_correspondencias.Rmd  ← Semana 7: AF + análisis de correspondencias
│
├── 03-escalamiento/
│   └── escalamiento_mds.Rmd            ← Semana 8: MDS y representación de proximidades
│
├── 04-clustering/
│   ├── clustering.Rmd                  ← K-means + Ward.D2 (R)
│   ├── clustering.html                 ← informe reproducido
│   ├── hdbscan_python.py               ← implementación Python vista en clase
│   └── requirements-hdbscan.txt        ← dependencia Python del análisis
│
├── 05-clasificacion/
│   └── clasificacion.Rmd               ← Semanas 12-13: LDA, QDA, SVM, Random Forest
│
├── 06-regresion/
│   └── regresion.Rmd                   ← Semana 14: regresión lineal multivariada
│
├── 07-proyecto-final/
│   └── proyecto_final.Rmd              ← Semanas 15-17: comparación integrada
│
└── shiny/
    └── app.R                           ← Explorador PCA interactivo
```

## Tecnologías

- **R** — análisis estadístico principal (`prcomp`, `car`, `factoextra`, `dbscan`, `MASS`, `randomForest`)
- **Python** (complementario) — HDBSCAN, scikit-learn para clasificación en AA/ML
- **R Markdown** — documentos reproducibles con HTML knitteado
- **Shiny** — aplicación interactiva de exploración PCA

HDBSCAN se ejecuta por separado con Python. El script lee el CSV, prepara su
propia matriz de análisis y guarda etiquetas, resumen de tamaños y gráfico en
`04-clustering/`:

```powershell
py -3.14 -m pip install -r 04-clustering/requirements-hdbscan.txt
py 04-clustering/hdbscan_python.py
```
