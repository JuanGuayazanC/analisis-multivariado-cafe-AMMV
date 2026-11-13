suppressMessages({library(uwot); library(Rtsne)})
for (base in c("base_1070.rds", "base_sin_atipicos.rds")) {
  tag <- if (base == "base_1070.rds") "1070" else "sin_atip"
  X <- as.matrix(readRDS(base)$Z)
  n <- nrow(X)
  dir.create(paste0("figuras_umap_tsne_", tag), showWarnings = FALSE)
  for (nn in c(15, 5)) {
    set.seed(2026)
    U <- umap(X, n_neighbors = nn, n_components = 2, min_dist = 0.1)
    png(sprintf("figuras_umap_tsne_%s/umap_vecinos%d.png", tag, nn), width = 1400, height = 1400, res = 150)
    plot(U, pch = 19, cex = 0.5, col = adjustcolor("purple", 0.5), main = sprintf("UMAP (vecinos = %d) · %s · n=%d", nn, tag, n), xlab = "UMAP1", ylab = "UMAP2")
    dev.off()
  }
  for (pp in c(30, 5)) {
    set.seed(2026)
    T <- Rtsne(X, perplexity = pp, check_duplicates = FALSE, pca = FALSE, verbose = FALSE)$Y
    png(sprintf("figuras_umap_tsne_%s/tsne_perp%d.png", tag, pp), width = 1400, height = 1400, res = 150)
    plot(T, pch = 19, cex = 0.5, col = adjustcolor("forestgreen", 0.5), main = sprintf("t-SNE (perplejidad = %d) · %s · n=%d", pp, tag, n), xlab = "t-SNE 1", ylab = "t-SNE 2")
    dev.off()
  }
  cat("base", tag, "listo, n =", n, "\n")
}
