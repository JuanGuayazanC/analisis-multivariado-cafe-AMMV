# Revisión de agrupamiento según recomendaciones de la sustentación.
# Script nuevo: no modifica clustering_bases.R (trabajo de otro integrante).
#  - tendencia al agrupamiento: codo, silueta promedio y estadístico gap
#  - dendrograma Ward.D2 con número de grupos y silueta por grupo
#  - k de K-means elegido con el dendrograma, con semilla fija
#  - prueba de proporciones entre grupos
# Salida: figuras_revision_profesor/ y resultados_clustering_profesor.txt

suppressMessages({ library(cluster); library(factoextra) })
set.seed(2026)
dir.create("figuras_revision_profesor", showWarnings = FALSE)
out_txt <- character()
add <- function(...) out_txt <<- c(out_txt, paste0(...))

base <- readRDS("base_1070.rds")
Z <- base$Z
raw <- base$raw
d <- read.csv("../data/arabica_data_cleaned.csv")
b <- d[!is.na(d$altitude_mean_meters) & d$altitude_mean_meters > 0 & d$altitude_mean_meters <= 3000, ]
vars14 <- c("Aroma","Flavor","Aftertaste","Acidity","Body","Balance","Uniformity","Clean.Cup","Sweetness","Cupper.Points","Moisture","Category.One.Defects","Category.Two.Defects","altitude_mean_meters")
b <- b[complete.cases(b[, vars14]), ]
proc <- b$Processing.Method

# ---- 1. Tendencia al agrupamiento ----
set.seed(2026)
wss <- sapply(1:8, function(k) kmeans(Z, centers = k, nstart = 20, iter.max = 100)$tot.withinss)
sil_k <- sapply(2:8, function(k) {
  km <- kmeans(Z, centers = k, nstart = 20, iter.max = 100)
  mean(silhouette(km$cluster, dist(Z))[, 3])
})
set.seed(2026)
gap <- clusGap(Z, FUNcluster = function(x, k) kmeans(x, centers = k, nstart = 20, iter.max = 100), K.max = 8, B = 50)
tab_k <- data.frame(k = 1:8, WSS = round(wss, 1), silueta_k = c(NA, round(sil_k, 3)),
                    gap = round(gap$Tab[, "gap"], 3), gap_se = round(gap$Tab[, "SE.sim"], 3))
write.csv(tab_k, "figuras_revision_profesor/tendencia_agrupamiento.csv", row.names = FALSE)
add("== Tendencia al agrupamiento (1.070 lotes estandarizados) ==")
add(paste(capture.output(print(tab_k, row.names = FALSE)), collapse = "\n"))
k_gap <- maxSE(gap$Tab[, "gap"], gap$Tab[, "SE.sim"], method = "firstSEmax")
add("k sugerido por gap (regla firstSEmax): ", k_gap)
add("k con mayor silueta promedio (k >= 2): ", which.max(sil_k) + 1)

png("figuras_revision_profesor/tendencia_codo_silueta_gap.png", width = 2400, height = 800, res = 170)
par(mfrow = c(1, 3), mar = c(4, 4, 3, 1))
plot(1:8, wss, type = "b", pch = 19, xlab = "k", ylab = "WSS", main = "Codo")
plot(2:8, sil_k, type = "b", pch = 19, xlab = "k", ylab = "Silueta promedio", main = "Silueta promedio")
plot(gap, main = "Estadístico gap")
dev.off()

# ---- 2. Dendrograma Ward.D2 con silueta por grupo ----
idx <- sample(nrow(Z), 80)
Zs <- Z[idx, ]
hc <- hclust(dist(Zs), method = "ward.D2")
k_hc <- 3
grp <- cutree(hc, k_hc)
sil_hc <- silhouette(grp, dist(Zs))
png("figuras_revision_profesor/dendrograma_ward_k3.png", width = 2200, height = 1100, res = 170)
plot(hc, labels = FALSE, main = "Dendrograma Ward.D2 (muestra de 80 lotes)", xlab = "", sub = "")
rect.hclust(hc, k = k_hc, border = c("#c0392b", "#1f4e79", "#117a65"))
dev.off()
png("figuras_revision_profesor/silueta_ward_por_grupo.png", width = 1800, height = 1100, res = 170)
plot(sil_hc, border = NA, main = sprintf("Silueta por grupo, Ward.D2 k = %d (promedio %.3f)", k_hc, mean(sil_hc[, 3])))
dev.off()
add("\n== Ward.D2 (muestra 80 lotes, k = ", k_hc, ") ==")
add("Silueta promedio: ", round(mean(sil_hc[, 3]), 3))
add("Silueta por grupo: ", paste(sprintf("G%d=%.3f", 1:k_hc, tapply(sil_hc[, 3], sil_hc[, 1], mean)), collapse = ", "))

# ---- 3. K-means con k elegido del dendrograma y semilla fija ----
set.seed(2026)
km <- kmeans(Z, centers = k_hc, nstart = 50, iter.max = 200)
sil_km <- silhouette(km$cluster, dist(Z))
add("\n== K-means (k = ", k_hc, ", semilla 2026, nstart = 50) ==")
add("Tamaños: ", paste(km$size, collapse = ", "))
add("Silueta promedio: ", round(mean(sil_km[, 3]), 3))
add("Lotes con silueta negativa: ", sum(sil_km[, 3] < 0), " (", round(100 * mean(sil_km[, 3] < 0), 1), " %)")

# ---- 4. Prueba de proporciones entre grupos ----
# Proporción de lotes con proceso Washed / Wet entre los dos grupos más grandes de K-means.
w <- as.integer(proc == "Washed / Wet")
ord <- order(km$size, decreasing = TRUE)
g1 <- ord[1]; g2 <- ord[2]
x <- c(sum(w[km$cluster == g1]), sum(w[km$cluster == g2]))
n <- c(sum(km$cluster == g1), sum(km$cluster == g2))
pt <- prop.test(x, n)
add("\n== Prueba de proporciones (Washed / Wet), grupos K-means ", g1, " vs ", g2, " ==")
add(sprintf("Proporciones: %.3f vs %.3f", x[1] / n[1], x[2] / n[2]))
add(sprintf("Chi-cuadrado = %.2f, gl = %d, p = %.4g", pt$statistic, pt$parameter, pt$p.value))
add("IC 95 % de la diferencia: ", paste(round(pt$conf.int, 3), collapse = " a "))

writeLines(out_txt, "resultados_clustering_profesor.txt")
cat(out_txt, sep = "\n")
