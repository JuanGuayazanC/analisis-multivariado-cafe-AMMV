suppressMessages(library(MASS))
res <- data.frame()
for (base in c("base_1070.rds", "base_sin_atipicos.rds")) {
  tag <- if (base == "base_1070.rds") "1070" else "sin_atip"
  X <- as.matrix(readRDS(base)$Z); n <- nrow(X)
  dir.create(paste0("figuras_mds_", tag), showWarnings = FALSE)
  D <- dist(X)
  set.seed(2026)
  nm <- isoMDS(D, k = 2, trace = FALSE)
  cl <- cmdscale(D, k = 2)
  dcl <- as.vector(dist(cl)); dor <- as.vector(D)
  stress_nm <- nm$stress
  png(sprintf("figuras_mds_%s/mds_no_metrico.png", tag), width = 1400, height = 1400, res = 150)
  plot(nm$points, pch = 19, cex = 0.5, col = adjustcolor("darkgreen", 0.5), main = sprintf("MDS no métrico (Kruskal) · stress = %.1f %% · n=%d", stress_nm, n), xlab = "Dimensión 1", ylab = "Dimensión 2")
  dev.off()
  png(sprintf("figuras_mds_%s/shepard_clasico.png", tag), width = 1400, height = 1400, res = 150)
  plot(dor, dcl, pch = 19, cex = 0.3, col = adjustcolor("steelblue", 0.2), main = sprintf("Diagrama de Shepard · MDS clásico · n=%d", n), xlab = "Distancia original", ylab = "Distancia en el mapa 2D")
  abline(0, 1, col = "red", lty = 2)
  dev.off()
  cat(tag, "n=", n, " stress no métrico (%) =", round(stress_nm, 1), " corr(original, 2D clásico) =", round(cor(dor, dcl), 3), "\n")
}
