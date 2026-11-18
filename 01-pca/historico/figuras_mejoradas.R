obj <- readRDS("../datos/datos_final_666.rds")
datos <- obj$datos_limpio
dir.create("figuras_presentacion", showWarnings = FALSE)

R <- cor(datos)
S <- cov(datos)
png("figuras/presentacion/04b_correlacion_y_varianza.png", width = as.integer(1800*1.6), height = as.integer(900*1.6), res = 220)
par(mfrow = c(1, 2), mar = c(9, 9, 3, 1))
image(1:8, 1:8, t(R[8:1, ]), col = hcl.colors(30, "Blue-Red 3"), zlim = c(-1, 1), axes = FALSE,
      main = "Matriz de correlaciones R (666 lotes)", xlab = "", ylab = "")
axis(1, 1:8, sub("altitude_mean_meters", "Altitud", colnames(R)), las = 2, cex.axis = 0.8)
axis(2, 1:8, rev(sub("altitude_mean_meters", "Altitud", colnames(R))), las = 2, cex.axis = 0.8)
for (i in 1:8) for (j in 1:8) text(j, 9 - i, sprintf("%.2f", R[i, j]), cex = 0.7)
v <- diag(S)
par(mar = c(9, 5, 3, 1))
b <- barplot(log10(v), names.arg = sub("altitude_mean_meters", "Altitud", names(v)), las = 2, col = "#8fb8a8",
             main = "Varianza de cada variable (log10)", ylab = "log10(varianza)")
dev.off()

pca <- prcomp(datos, center = TRUE, scale. = TRUE)
png("figuras/presentacion/07_biplot_limpio.png", width = as.integer(1200*1.6), height = as.integer(1000*1.6), res = 220)
par(mar = c(5, 5, 3, 2))
sc <- 0.85 * max(abs(pca$x[, 1:2])) / max(abs(pca$rotation[, 1:2]))
lim <- 1.25 * max(abs(c(pca$x[, 1:2], pca$rotation[, 1:2] * sc)))
plot(pca$x[, 1], pca$x[, 2], pch = 19, cex = 0.35, col = adjustcolor("steelblue", 0.45),
     xlim = c(-lim, lim), ylim = c(-lim, lim),
     xlab = paste0("CP1 (", round(summary(pca)$importance[2, 1] * 100, 1), " %)"),
     ylab = paste0("CP2 (", round(summary(pca)$importance[2, 2] * 100, 1), " %)"),
     main = "Biplot CP1 vs CP2: lotes y cargas")
sc <- 0.85 * max(abs(pca$x[, 1:2])) / max(abs(pca$rotation[, 1:2]))
arrows(0, 0, pca$rotation[, 1] * sc, pca$rotation[, 2] * sc, length = 0.1, col = "firebrick", lwd = 2)
text(pca$rotation[, 1] * sc * 1.12, pca$rotation[, 2] * sc * 1.12, rownames(pca$rotation),
     col = "firebrick", cex = 0.9)
abline(h = 0, v = 0, lty = 3, col = "grey50")
dev.off()
