suppressMessages(library(MASS))
X <- as.matrix(readRDS("base_1070.rds")$Z)
set.seed(2026)
nm <- isoMDS(dist(X), k = 2, trace = FALSE)
p <- nm$points
lx <- quantile(p[, 1], c(0.01, 0.99)); ly <- quantile(p[, 2], c(0.01, 0.99))
out <- sum(p[, 1] < lx[1] | p[, 1] > lx[2] | p[, 2] < ly[1] | p[, 2] > ly[2])
png("figuras_mds_1070/mds_no_metrico.png", width = 1400, height = 1400, res = 150)
plot(p, pch = 19, cex = 0.5, col = adjustcolor("darkgreen", 0.5), xlim = lx * 1.1, ylim = ly * 1.1,
     main = sprintf("MDS no métrico (Kruskal) · stress = %.1f %% · n=1070", nm$stress), xlab = "Dimensión 1", ylab = "Dimensión 2")
mtext(sprintf("Zoom al 98 %% central; %d lotes fuera de la escala", out), side = 1, line = 4, cex = 0.8)
dev.off()
cat("stress", round(nm$stress, 1), " fuera:", out, "\n")
