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
│   └── clustering.Rmd                  ← Semanas 9-10: jerárquico + K-means + HDBSCAN
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
