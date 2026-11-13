suppressMessages(library(cluster))
has_db <- requireNamespace("dbscan", quietly = TRUE)
res <- list()
for (base in c("base_1070.rds", "base_sin_atipicos.rds")) {
  tag <- if (base == "base_1070.rds") "1070" else "sin_atip"
  X <- as.matrix(readRDS(base)$Z); n <- nrow(X); D <- dist(X)
  cat("\n== base", tag, "n =", n, "\n")
  set.seed(2026)
  sil_k <- sapply(2:6, function(k) { km <- kmeans(X, k, nstart = 25); mean(silhouette(km$cluster, D)[, 3]) })
  cat("K-means silueta k=2..6:", round(sil_k, 3), "\n")
  km3 <- kmeans(X, 3, nstart = 25)
  cat("K-means k=3 silueta:", round(mean(silhouette(km3$cluster, D)[, 3]), 3), " negativas:", sum(silhouette(km3$cluster, D)[, 3] < 0), "(", round(mean(silhouette(km3$cluster, D)[, 3] < 0) * 100, 1), "%)\n")
  hc <- hclust(D, method = "ward.D2")
  cw <- cutree(hc, 3)
  cat("Ward.D2 k=3 silueta:", round(mean(silhouette(cw, D)[, 3]), 3), " tamaños:", table(cw), "\n")
  if (has_db) {
    hdb <- dbscan::hdbscan(X, minPts = 15)
    cat("HDBSCAN minPts=15: grupos =", length(unique(hdb$cluster[hdb$cluster > 0])), " ruido =", sum(hdb$cluster == 0), " (", round(mean(hdb$cluster == 0) * 100, 1), "%)\n")
  } else cat("HDBSCAN: paquete dbscan no instalado\n")
}
