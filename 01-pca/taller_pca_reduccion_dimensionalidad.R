# ============================================================
# Taller práctico de Análisis Multivariado
# PCA y métodos alternativos de reducción de dimensionalidad
# Dataset: Coffee Quality Institute - arabica_data_cleaned.csv
# ============================================================

# ------------------------------------------------------------
# 2. Selección del conjunto de datos
# ------------------------------------------------------------
# Fuente: Coffee Quality Institute, vía repositorio
#   https://github.com/jldbc/coffee-quality-database
#   archivo: data/arabica_data_cleaned.csv
# Observaciones: 1311 lotes de café arábica evaluados por catadores certificados.
#
# Variables cuantitativas utilizadas (puntajes de catación, escala 0-10,
# más variables físicas del lote):
#   Aroma, Flavor, Aftertaste, Acidity, Body, Balance, Uniformity,
#   Clean.Cup, Sweetness, Cupper.Points   -> puntajes sensoriales (0-10)
#   Moisture                              -> % de humedad del grano
#   Category.One.Defects                  -> conteo de defectos primarios
#   Category.Two.Defects                  -> conteo de defectos secundarios
#   altitude_mean_meters                  -> altitud media de la finca (metros)
#
# Se excluye Total.Cup.Points del conjunto activo del PCA porque es,
# por construcción, la suma de los diez puntajes sensoriales anteriores:
# incluirla generaría una variable redundante (colinealidad perfecta con
# el resto) en vez de aportar información nueva. Se conserva aparte como
# variable ilustrativa para contrastar con las componentes obtenidas.
#
# Justificación de la selección: son las únicas variables genuinamente
# cuantitativas y continuas del dataset; el resto de columnas son
# identificadores, certificaciones o metadatos administrativos sin
# contenido analítico (Owner, Farm.Name, Lot.Number, Certification.Body, etc.).

library(dplyr)

data <- read.csv("data/arabica_data_cleaned.csv")

vars_cuantitativas <- c("Aroma", "Flavor", "Aftertaste", "Acidity", "Body",
                         "Balance", "Uniformity", "Clean.Cup", "Sweetness",
                         "Cupper.Points", "Moisture", "Category.One.Defects",
                         "Category.Two.Defects", "altitude_mean_meters")

# --- Datos faltantes ---
colSums(is.na(data[, vars_cuantitativas]))
# Único NA relevante: altitude_mean_meters (227 filas). Se documenta y se
# trata más abajo junto con el outlier conocido de esa misma variable.

# --- Outlier conocido de altitud ---
summary(data$altitude_mean_meters)
# Valor corrupto (~190000 m, imposible para una finca cafetera). Se filtra
# a un rango plausible de altitud de cultivo (0 - 3000 msnm) y se eliminan
# los NA restantes solo para las variables usadas en este taller.

datos <- data %>%
  filter(is.na(altitude_mean_meters) | (altitude_mean_meters > 0 & altitude_mean_meters <= 3000)) %>%
  filter(!is.na(altitude_mean_meters)) %>%
  select(all_of(vars_cuantitativas))

dim(datos)  # filas remanentes tras el tratamiento de NA/outlier

# ------------------------------------------------------------
# 3. Exploración inicial
# ------------------------------------------------------------
str(datos)
dim(datos)
head(datos)
summary(datos)
colSums(is.na(datos))

cor(datos)

# Puntos a discutir en la presentación (a partir de la salida anterior):
#  - diferencias de escala: altitude_mean_meters (cientos-miles de metros)
#    frente a los puntajes sensoriales (rango ~6-10) y Moisture (%).
#  - variables con mayor variabilidad: altitude_mean_meters y los conteos
#    de defectos, frente a los puntajes de catación que son mucho más
#    homogéneos entre lotes.
#  - correlaciones importantes: los puntajes sensoriales están fuertemente
#    correlacionados entre sí (Flavor-Aftertaste, Balance-Aftertaste, etc.),
#    reflejando que evalúan dimensiones relacionadas de la experiencia de cata.
#  - Category.One/Two.Defects y Moisture están poco correlacionadas con el
#    bloque sensorial: aportan información distinta (calidad física del grano).

# ------------------------------------------------------------
# 4. Matriz de varianzas-covarianzas y medidas de variabilidad
# ------------------------------------------------------------
S <- cov(datos)
S

# 4.1. Varianza total
varianza_total <- sum(diag(S))
varianza_total
# Dominada casi por completo por altitude_mean_meters, dado que su varianza
# está en una escala de miles de metros^2 frente a puntajes en escala 0-10.

# 4.2. Varianza generalizada
varianza_generalizada <- det(S)
varianza_generalizada
# Mide la variabilidad conjunta (volumen del elipsoide de dispersión).
# Un valor cercano a cero indicaría multicolinealidad severa o redundancia
# casi perfecta entre variables (lo que aquí no ocurre de forma extrema
# tras excluir Total.Cup.Points, pero sí hay colinealidad moderada-alta
# entre los puntajes sensoriales).

p <- ncol(datos)
varianza_total_media <- varianza_total / p
varianza_generalizada_media <- varianza_generalizada^(1 / p)
varianza_total_media
varianza_generalizada_media
# Las versiones "promedio" (dividiendo por p o tomando la raíz p-ésima)
# permiten comparar variabilidad entre conjuntos de variables de distinto
# tamaño p, cosa que la varianza total y el determinante crudo no permiten
# al depender de la dimensión y de las unidades de cada variable.

# ------------------------------------------------------------
# 4.3. Transformación de Yeo-Johnson (solo Category.Two.Defects)
# ------------------------------------------------------------
# Category.Two.Defects es muy asimétrica (informe, sección 3.1) y su lambda de
# máxima verosimilitud es estable (~ -0.217). Moisture y Category.One.Defects
# están infladas en cero: lambda se pega al borde del rango y no se transforman.
yeojohnson_transform <- function(x, lambda) {
  if (lambda != 0) ((x + 1)^lambda - 1) / lambda else log(x + 1)
}
yeojohnson_loglik <- function(lambda, x) {
  y <- yeojohnson_transform(x, lambda)
  -length(x) / 2 * log(var(y)) + (lambda - 1) * sum(log(x + 1))
}
yeojohnson_fit <- function(x) {
  optimize(yeojohnson_loglik, interval = c(-5, 5), x = x, maximum = TRUE)$maximum
}

lambda_c2 <- yeojohnson_fit(datos$Category.Two.Defects)
lambda_c2

# datos_t: conjunto oficial del análisis (13 variables originales + Category.Two.Defects transformada)
datos_t <- datos
datos_t$Category.Two.Defects <- yeojohnson_transform(datos$Category.Two.Defects, lambda_c2)

# ------------------------------------------------------------
# 5. Análisis de Componentes Principales
# ------------------------------------------------------------
# Decisión: ESTANDARIZAR. Las variables tienen unidades y escalas muy
# distintas (metros vs. puntaje 0-10 vs. porcentaje vs. conteo de defectos).
# Sin estandarizar, altitude_mean_meters dominaría por completo la varianza
# total y, por tanto, el primer componente, ocultando la estructura de los
# puntajes sensoriales que es el objeto real de interés del análisis.

pca <- prcomp(datos_t, center = TRUE, scale. = TRUE)

# ------------------------------------------------------------
# 6. Selección del número de componentes
# ------------------------------------------------------------
summary(pca)
pca$sdev^2

screeplot(pca, type = "lines", main = "Gráfico de codo - PCA café")

# Criterio de decisión (ajustar la lectura una vez ejecutado en clase):
#  - varianza acumulada explicada por las primeras 3-4 componentes;
#  - codo visible en el screeplot;
#  - interpretabilidad de cada componente en términos de las variables
#    originales (ver sección 7).
# El número final de componentes a conservar (k) debe fijarse con base en
# estos criterios y no de forma arbitraria.

# ------------------------------------------------------------
# 7. Interpretación de las componentes
# ------------------------------------------------------------
pca$rotation

# Para cada componente conservada, identificar en pca$rotation:
#  - variables con mayor carga absoluta (mayor peso);
#  - variables con cargas del mismo signo (comportamiento similar);
#  - variables con cargas de signo opuesto (relación inversa);
#  - propuesta de nombre/significado del componente en el contexto cafetero
#    (p. ej., un componente dominado por Aroma/Flavor/Aftertaste/Balance
#    puede leerse como un eje general de "calidad sensorial"; un componente
#    dominado por Category.One/Two.Defects y Moisture puede leerse como un
#    eje de "calidad física del grano").

# ------------------------------------------------------------
# 8. Matriz de gráficos de dispersión de las componentes
# ------------------------------------------------------------
k <- 4  # ajustar según la decisión tomada en la sección 6

pca$x[1:6, 1:k]

pairs(pca$x[, 1:k],
      main = "Matriz de dispersión - Componentes principales (café)",
      pch = 19, col = adjustcolor("steelblue", alpha.f = 0.4))

# Revisar si aparecen agrupamientos (p. ej., por Processing.Method o
# Country.of.Origin, no usados como variables activas del PCA pero
# disponibles en `data` para colorear los puntos si se desea profundizar),
# patrones no lineales, separación entre observaciones y posibles atípicos
# multivariados. Analizar si estos patrones se repiten entre distintos
# pares de componentes o son específicos de un par en particular.

# Versión coloreada por Processing.Method (metadato no usado como variable
# activa del PCA, disponible en `data` tras aplicar el mismo filtro que dio
# lugar a `datos`): permite ver si el método de proceso del café separa a
# los lotes en el espacio de componentes.
library(GGally)

processing_method <- data %>%
  filter(is.na(altitude_mean_meters) | (altitude_mean_meters > 0 & altitude_mean_meters <= 3000)) %>%
  filter(!is.na(altitude_mean_meters)) %>%
  pull(Processing.Method)

pca_scores <- as.data.frame(pca$x[, 1:k])
pca_scores$Processing.Method <- processing_method

ggpairs(pca_scores, columns = 1:k, aes(color = Processing.Method, alpha = 0.5)) +
  ggtitle("Matriz de dispersión de componentes principales (color = método de proceso)")

# No se observa separación por método de proceso: los lotes forman una
# nube continua independientemente de si el café fue Washed/Wet, Natural/Dry,
# Semi-washed/Semi-pulped u Otro.

# ------------------------------------------------------------
# 9. Biplot
# ------------------------------------------------------------
biplot(pca, choices = c(1, 2), cex = 0.6,
       main = "Biplot PCA - Componentes 1 y 2 (café)")

# El biplot añade, sobre la matriz de dispersión, la dirección y magnitud
# de cada variable original en el espacio de componentes: permite ver
# simultáneamente qué variables "empujan" hacia dónde a las observaciones,
# información que la matriz de dispersión (solo puntos) no muestra por sí sola.

# ------------------------------------------------------------
# 10. Kernel PCA
# ------------------------------------------------------------
library(kernlab)

datos_esc <- as.data.frame(scale(datos_t))

kp <- kpca(~., data = datos_esc,
           kernel = "rbfdot",
           kpar = list(sigma = 0.05),
           features = 5)

eig <- kp@eig
var_exp <- eig / sum(eig)
round(var_exp, 3)
round(cumsum(var_exp), 3)

# El kernel RBF (gaussiano) se eligió porque permite capturar relaciones
# no lineales suaves entre los puntajes de catación sin imponer una forma
# funcional específica; sigma controla qué tan "local" es la noción de
# similitud entre lotes de café (sigma pequeño = vecindades más estrechas).
# A diferencia de PCA, las coordenadas de Kernel PCA no son combinaciones
# lineales directas de las variables originales, por lo que no se
# interpretan mediante cargas (rotation) sino de forma relacional
# (qué observaciones quedan cerca/lejos en el espacio transformado).

# ------------------------------------------------------------
# 11. Matriz de dispersión de Kernel PCA
# ------------------------------------------------------------
scores_kpca <- rotated(kp)

pairs(scores_kpca[, 1:5],
      main = "Matriz de dispersión - Kernel PCA (café)",
      pch = 19, col = adjustcolor("darkorange", alpha.f = 0.4))

# Comparar contra la matriz de dispersión de PCA (sección 8): ¿aparecen
# agrupamientos o curvaturas que PCA lineal no mostraba?

# Variación de un parámetro relevante (sigma) para ver el efecto:
kp_sigma_alto <- kpca(~., data = datos_esc,
                       kernel = "rbfdot",
                       kpar = list(sigma = 1),
                       features = 5)
pairs(rotated(kp_sigma_alto)[, 1:5],
      main = "Kernel PCA con sigma = 1 (café)",
      pch = 19, col = adjustcolor("firebrick", alpha.f = 0.4))

# ------------------------------------------------------------
# 12. t-SNE
# ------------------------------------------------------------
library(Rtsne)

X <- scale(datos_t)

set.seed(123)
tsne <- Rtsne(X, dims = 2, perplexity = 30, theta = 0.5)

plot(tsne$Y,
     pch = 19, col = adjustcolor("seagreen", alpha.f = 0.5),
     xlab = "t-SNE 1", ylab = "t-SNE 2",
     main = "t-SNE - Café (perplexity = 30)")

# Recordar: los ejes de t-SNE no son componentes principales y no tienen
# interpretación directa en términos de las variables originales; lo que
# importa es la vecindad relativa entre observaciones, no la posición
# absoluta ni la distancia entre grupos alejados.

# Variación de un parámetro relevante (perplexity):
set.seed(123)
tsne_perp5 <- Rtsne(X, dims = 2, perplexity = 5, theta = 0.5)
plot(tsne_perp5$Y,
     pch = 19, col = adjustcolor("seagreen", alpha.f = 0.5),
     xlab = "t-SNE 1", ylab = "t-SNE 2",
     main = "t-SNE - Café (perplexity = 5)")

# ------------------------------------------------------------
# 13. UMAP
# ------------------------------------------------------------
library(uwot)

X <- scale(datos_t)

set.seed(123)
um <- umap(X)
head(um)

plot(um[, 1], um[, 2],
     pch = 19, col = adjustcolor("mediumpurple", alpha.f = 0.5),
     xlab = "UMAP1", ylab = "UMAP2",
     main = "UMAP - Café (parámetros por defecto)")

# Variación de un parámetro relevante (n_neighbors):
set.seed(123)
um_vecinos <- umap(X, n_neighbors = 5)
plot(um_vecinos[, 1], um_vecinos[, 2],
     pch = 19, col = adjustcolor("mediumpurple", alpha.f = 0.5),
     xlab = "UMAP1", ylab = "UMAP2",
     main = "UMAP - Café (n_neighbors = 5)")

# Igual que en t-SNE, las coordenadas de UMAP no son componentes
# principales ni tienen relación directa e interpretable con las
# variables originales; la diferencia respecto de t-SNE está en que
# UMAP intenta preservar mejor tanto la estructura local (vecindades)
# como parte de la estructura global (distancia relativa entre grupos).

# ------------------------------------------------------------
# 14. Comparación de los cuatro métodos
# ------------------------------------------------------------
# Completar esta tabla con base en los resultados obtenidos arriba
# (no son valores genéricos de teoría, sino lo observado con estos datos):
#
# Aspecto                          | PCA | Kernel PCA | t-SNE | UMAP
# Lineal / no lineal                |     |            |       |
# Estructura que enfatiza           |     |            |       |
# Interpretación de los ejes        |     |            |       |
# Relación con variables originales |     |            |       |
# Patrones identificados            |     |            |       |
# Agrupamientos                     |     |            |       |
# Posibles atípicos                 |     |            |       |
# Utilidad principal                |     |            |       |
# Uso potencial en modelamiento     |     |            |       |
# Transformación de nuevas obs.     |     |            |       |
# Principales limitaciones          |     |            |       |

# ------------------------------------------------------------
# 15. Visualización frente a modelamiento
# ------------------------------------------------------------
# Discusión a desarrollar en la presentación:
# Una representación bidimensional (p. ej. de t-SNE o UMAP) que muestra
# grupos visualmente separados no garantiza que esas dos coordenadas sean
# una buena transformación de entrada para un modelo predictivo: t-SNE y
# UMAP distorsionan deliberadamente las distancias globales para privilegiar
# la vecindad local, no son invertibles ni se definen mediante una función
# fija aplicable a observaciones nuevas (a diferencia de PCA/Kernel PCA,
# que sí permiten proyectar datos nuevos usando las cargas o el kernel ya
# ajustado), y su resultado cambia con la semilla aleatoria y con
# parámetros como perplexity o n_neighbors. Son herramientas de
# visualización/exploración, no de generación de variables estables para
# un pipeline de modelamiento.
