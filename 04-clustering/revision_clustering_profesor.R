# Revisión de agrupamiento según recomendaciones de la sustentación.
# Usa la MISMA matriz y semilla de 04-clustering/clustering.Rmd (no modifica ese archivo):
#   4 CP exploratorias estandarizadas / sqrt(4) + indicadores de Proceso, Color y País / sqrt(3)
#   1.070 lotes, 19 columnas; K-means k = 3, semilla 42, nstart 25; Ward.D2 sobre 80 lotes.
# Agrega lo que pidió el profesor:
#  - tendencia al agrupamiento: codo, silueta promedio y estadístico gap
#  - dendrograma con número de grupos y silueta por grupo
#  - prueba de proporciones entre grupos con una variable que NO entra al agrupamiento
# Salida: figuras/revision_profesor/ (dentro de 04-clustering) y resultados_clustering_profesor.txt

# Ejecutar con 04-clustering/ como directorio de trabajo (las rutas son relativas a esa carpeta).
if (!file.exists("../data/arabica_data_cleaned.csv"))
  stop("Ejecute el script desde la carpeta 04-clustering/ (no se encuentra ../data/arabica_data_cleaned.csv).")
dir.create("figuras/revision_profesor", recursive = TRUE, showWarnings = FALSE)

suppressMessages({ library(dplyr); library(car); library(cluster) })
out_txt <- character()
add <- function(...) out_txt <<- c(out_txt, paste0(...))

# == 1. Matriz de 04-clustering/clustering.Rmd (réplica exacta) ==
data_raw <- read.csv("../data/arabica_data_cleaned.csv")
datos_filtrados <- data_raw %>% filter(!is.na(altitude_mean_meters), altitude_mean_meters > 0, altitude_mean_meters <= 3000)
vars_activas <- c("Aroma", "Flavor", "Aftertaste", "Acidity", "Body", "Balance", "Cupper.Points", "altitude_mean_meters")
stopifnot(nrow(datos_filtrados) == 1070L)
datos_modelo <- datos_filtrados[, vars_activas]
sesgo <- function(x) mean((x - mean(x))^3) / sd(x)^3
vt <- names(which(abs(sapply(datos_modelo, sesgo)) > 1))
lam <- coef(powerTransform(datos_modelo[, vt], family = "yjPower"), round = FALSE)
for (v in vt) datos_modelo[[v]] <- yjPower(datos_modelo[[v]], lam[v])
pca_e <- prcomp(datos_modelo, center = TRUE, scale. = TRUE)
cat_df <- datos_filtrados %>% select(Processing.Method, Color, Country.of.Origin) %>%
  mutate(across(everything(), ~ ifelse(is.na(.) | trimws(as.character(.)) == "", "Desconocido", as.character(.))))
top5 <- names(sort(table(cat_df$Country.of.Origin), decreasing = TRUE)[1:5])
cat_df$Country.of.Origin <- ifelse(cat_df$Country.of.Origin %in% top5, cat_df$Country.of.Origin, "Otro")
cat_df <- cat_df %>% mutate(across(everything(), factor))
dummies <- model.matrix(~ Processing.Method + Color + Country.of.Origin - 1, data = cat_df)
X <- cbind(scale(pca_e$x[, 1:4]) / sqrt(4), dummies / sqrt(3))
add("Matriz de agrupamiento (igual a clustering.Rmd): ", nrow(X), " lotes x ", ncol(X), " columnas")

set.seed(42)
km <- kmeans(X, centers = 3, nstart = 25)
sil_km <- silhouette(km$cluster, dist(X))
add("K-means k = 3 (semilla 42): tamaños ", paste(km$size, collapse = ", "),
    "; silueta promedio ", round(mean(sil_km[, 3]), 3),
    "; silueta negativa ", sum(sil_km[, 3] < 0), " (", round(100 * mean(sil_km[, 3] < 0), 1), " %)")
add("Silueta por grupo K-means: ", paste(sprintf("G%d=%.3f", 1:3, tapply(sil_km[, 3], sil_km[, 1], mean)), collapse = ", "))

# == 2. Tendencia al agrupamiento ==
set.seed(42)
wss <- sapply(1:8, function(k) kmeans(X, centers = k, nstart = 25, iter.max = 100)$tot.withinss)
set.seed(42)
sil_k <- sapply(2:8, function(k) mean(silhouette(kmeans(X, centers = k, nstart = 25, iter.max = 100)$cluster, dist(X))[, 3]))
set.seed(42)
gap <- clusGap(X, FUNcluster = function(x, k) kmeans(x, centers = k, nstart = 25, iter.max = 100), K.max = 8, B = 50)
tab_k <- data.frame(k = 1:8, WSS = round(wss, 1), silueta = c(NA, round(sil_k, 3)),
                    gap = round(gap$Tab[, "gap"], 3), gap_se = round(gap$Tab[, "SE.sim"], 3))
write.csv(tab_k, "figuras/revision_profesor/tendencia_agrupamiento.csv", row.names = FALSE)
add("\n== Tendencia al agrupamiento ==")
add(paste(capture.output(print(tab_k, row.names = FALSE)), collapse = "\n"))
k_gap1 <- maxSE(gap$Tab[, "gap"], gap$Tab[, "SE.sim"], method = "firstSEmax")
k_gapG <- maxSE(gap$Tab[, "gap"], gap$Tab[, "SE.sim"], method = "globalmax")
add("k por gap: primer máximo (firstSEmax) = ", k_gap1, "; máximo global = ", k_gapG)
add("k con mayor silueta promedio: ", which.max(sil_k) + 1)
if (k_gap1 == 1)
  add("Interpretación: el gap elige k = 1, es decir, no hay evidencia de que la matriz esté más agrupada ",
      "que una referencia uniforme. La elección k = 3 es exploratoria y no la respaldan ni el gap ni la silueta.")
add("Nota: la referencia del gap es uniforme en la caja de cada columna; con 15 columnas binarias (dummies) ",
    "esa referencia es poco realista, así que el gap debe leerse junto con la silueta y no como prueba formal.")

png("figuras/revision_profesor/tendencia_codo_silueta_gap.png", width = 2400, height = 800, res = 170, bg = "transparent")
par(mfrow = c(1, 3), mar = c(4.2, 4.2, 3, 1))
plot(1:8, wss, type = "b", pch = 19, xlab = "k", ylab = "WSS", main = "Codo")
abline(v = 3, lty = 3, col = "#c0392b")
plot(2:8, sil_k, type = "b", pch = 19, xlab = "k", ylab = "Silueta promedio", main = "Silueta promedio")
abline(v = 3, lty = 3, col = "#c0392b")
plot(gap, main = "Estadístico gap", xlab = "k")
dev.off()

# == 3. Dendrograma Ward.D2 (misma muestra de 80) y silueta por grupo ==
set.seed(42)
idx <- sample(seq_len(nrow(X)), 80)
Xw <- X[idx, ]
hc <- hclust(dist(Xw), method = "ward.D2")
gw <- cutree(hc, k = 3)
sil_w <- silhouette(gw, dist(Xw))
ari <- function(a, b) {
  t <- table(a, b); n <- sum(t); s <- function(x) sum(choose(x, 2))
  e <- s(rowSums(t)) * s(colSums(t)) / choose(n, 2); m <- (s(rowSums(t)) + s(colSums(t))) / 2
  (s(t) - e) / (m - e)
}
alturas <- rev(hc$height)[1:4]
add("\n== Ward.D2 (muestra de 80, misma semilla) ==")
add("Tamaños: ", paste(table(gw), collapse = ", "), "; silueta promedio ", round(mean(sil_w[, 3]), 3))
add("Silueta por grupo Ward: ", paste(sprintf("G%d=%.3f", 1:3, tapply(sil_w[, 3], sil_w[, 1], mean)), collapse = ", "))
add("Alturas de las últimas fusiones (de 1 a 4 grupos): ", paste(round(alturas, 2), collapse = ", "),
    "; el corte en k = 3 queda entre ", round(alturas[3], 2), " y ", round(alturas[2], 2),
    ". El mayor salto es entre ", which.max(-diff(alturas)), " y ", which.max(-diff(alturas)) + 1, " grupos.")
add("ARI K-means / Ward en la muestra: ", round(ari(km$cluster[idx], gw), 3))

png("figuras/revision_profesor/dendrograma_ward_k3.png", width = 2200, height = 1100, res = 170, bg = "transparent")
plot(hc, labels = FALSE, main = "Ward.D2 (muestra de 80 lotes): corte en k = 3", xlab = "", sub = "", ylab = "Altura")
rect.hclust(hc, k = 3, border = c("#c0392b", "#1f4e79", "#117a65"))
dev.off()
png("figuras/revision_profesor/silueta_ward_por_grupo.png", width = 1800, height = 1100, res = 170, bg = "transparent")
plot(sil_w, border = NA, col = c("#c0392b", "#1f4e79", "#117a65")[sort(gw)],
     main = sprintf("Silueta por grupo, Ward.D2 k = 3 (promedio %.3f)", mean(sil_w[, 3])))
dev.off()

# == 4. Prueba de proporciones: Humedad = 0 por grupo de K-means ==
# Humedad no entra en la matriz de agrupamiento, así que la comparación es informativa.
h0 <- datos_filtrados$Moisture == 0
tab <- table(Grupo = km$cluster, Humedad0 = h0)
pt <- prop.test(tab[, "TRUE"], rowSums(tab))
props <- tab[, "TRUE"] / rowSums(tab)
add("\n== Prueba de proporciones: lotes con Humedad = 0 por grupo de K-means ==")
add("Proporciones: ", paste(sprintf("G%d=%.1f %% (%d de %d)", 1:3, 100 * props, tab[, "TRUE"], rowSums(tab)), collapse = "; "))
add(sprintf("Chi-cuadrado = %.2f, gl = %d, p = %.3g", pt$statistic, pt$parameter, pt$p.value))
saveRDS(list(props = props, n = rowSums(tab), x = tab[, "TRUE"], p = pt$p.value, stat = pt$statistic, df = pt$parameter),
        "figuras/revision_profesor/prop_humedad_kmeans.rds")

png("figuras/revision_profesor/prop_humedad_kmeans.png", width = 1400, height = 1100, res = 200, bg = "transparent")
par(mar = c(4.5, 4.5, 3, 1))
b <- barplot(100 * props, names.arg = sprintf("Grupo %d\n(%d lotes)", 1:3, rowSums(tab)), col = c("#c0392b", "#1f4e79", "#117a65"),
             ylim = c(0, max(100 * props) * 1.3), ylab = "Lotes con Humedad = 0 (%)", border = NA,
             main = sprintf("Humedad = 0 por grupo (p %s)", ifelse(pt$p.value < 0.001, "< 0,001", paste("=", format(round(pt$p.value, 3), decimal.mark = ",")))))
text(b, 100 * props, labels = paste0(format(round(100 * props, 1), decimal.mark = ","), " %"), pos = 3)
dev.off()

writeLines(out_txt, "resultados_clustering_profesor.txt")
cat(out_txt, sep = "\n")
