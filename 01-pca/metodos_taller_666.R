library(kernlab)
library(Rtsne)
library(uwot)

set.seed(2026)
obj <- readRDS("datos_final_666.rds")
datos <- obj$datos_limpio
X <- scale(datos)
p <- ncol(datos)
dir.create("figuras_taller_666", showWarnings = FALSE)
res <- list()

S <- cov(datos)
res$varianza_total <- sum(diag(S))
res$varianza_generalizada <- det(S)
res$varianza_total_media <- res$varianza_total / p
res$varianza_generalizada_media <- res$varianza_generalizada^(1 / p)
res$S <- S

pca <- prcomp(datos, center = TRUE, scale. = TRUE)
res$pca_var <- summary(pca)$importance[2, ] * 100
res$pca_rot <- pca$rotation
res$pca_scores <- pca$x

png("figuras/taller_666/pca_pairs.png", width = as.integer(1400*1.6), height = as.integer(1400*1.6), res = 220)
pairs(pca$x[, 1:4], pch = 19, cex = 0.4, col = adjustcolor("steelblue", 0.5))
dev.off()
png("figuras/taller_666/pca_biplot.png", width = as.integer(1200*1.6), height = as.integer(1000*1.6), res = 220)
biplot(pca, scale = 0, cex = 0.5)
dev.off()
png("figuras/taller_666/pca_codo.png", width = as.integer(1000*1.6), height = as.integer(700*1.6), res = 220)
screeplot(pca, main = "Gráfico de codo — PCA 666 lotes")
dev.off()

kp_rbf <- kpca(~., data = as.data.frame(X), kernel = "rbfdot",
               kpar = list(sigma = 0.1), features = 5)
kp_rbf_sigma_alto <- kpca(~., data = as.data.frame(X), kernel = "rbfdot",
                          kpar = list(sigma = 1), features = 5)
kp_poly <- kpca(~., data = as.data.frame(X), kernel = "polydot",
                kpar = list(degree = 2, scale = 1, offset = 1), features = 5)
res$kpca_rbf_var <- round(kp_rbf@eig / sum(kp_rbf@eig), 3)
res$kpca_rbf_sigma1_var <- round(kp_rbf_sigma_alto@eig / sum(kp_rbf_sigma_alto@eig), 3)
res$kpca_poly_var <- round(kp_poly@eig / sum(kp_poly@eig), 3)

png("figuras/taller_666/kpca_rbf_pairs.png", width = as.integer(1400*1.6), height = as.integer(1400*1.6), res = 220)
pairs(rotated(kp_rbf)[, 1:4], pch = 19, cex = 0.4, col = adjustcolor("firebrick", 0.5))
dev.off()
png("figuras/taller_666/kpca_rbf_sigma1_pairs.png", width = as.integer(1400*1.6), height = as.integer(1400*1.6), res = 220)
pairs(rotated(kp_rbf_sigma_alto)[, 1:4], pch = 19, cex = 0.4, col = adjustcolor("firebrick", 0.5))
dev.off()

tsne30 <- Rtsne(X, dims = 2, perplexity = 30, theta = 0.5, check_duplicates = FALSE)
tsne5 <- Rtsne(X, dims = 2, perplexity = 5, theta = 0.5, check_duplicates = FALSE)
png("figuras/taller_666/tsne_perp30.png", width = as.integer(1000*1.6), height = as.integer(1000*1.6), res = 220)
plot(tsne30$Y, pch = 19, cex = 0.5, col = adjustcolor("darkgreen", 0.5),
     xlab = "t-SNE 1", ylab = "t-SNE 2", main = "t-SNE (perplejidad = 30)")
dev.off()
png("figuras/taller_666/tsne_perp5.png", width = as.integer(1000*1.6), height = as.integer(1000*1.6), res = 220)
plot(tsne5$Y, pch = 19, cex = 0.5, col = adjustcolor("darkgreen", 0.5),
     xlab = "t-SNE 1", ylab = "t-SNE 2", main = "t-SNE (perplejidad = 5)")
dev.off()

um15 <- umap(X, n_neighbors = 15)
um5 <- umap(X, n_neighbors = 5)
png("figuras/taller_666/umap_vecinos15.png", width = as.integer(1000*1.6), height = as.integer(1000*1.6), res = 220)
plot(um15[, 1], um15[, 2], pch = 19, cex = 0.5, col = adjustcolor("purple", 0.5),
     xlab = "UMAP1", ylab = "UMAP2", main = "UMAP (vecinos = 15)")
dev.off()
png("figuras/taller_666/umap_vecinos5.png", width = as.integer(1000*1.6), height = as.integer(1000*1.6), res = 220)
plot(um5[, 1], um5[, 2], pch = 19, cex = 0.5, col = adjustcolor("purple", 0.5),
     xlab = "UMAP1", ylab = "UMAP2", main = "UMAP (vecinos = 5)")
dev.off()

saveRDS(res, "resultados_taller_666.rds")
cat("Varianza total:", round(res$varianza_total, 3), "\n")
cat("Varianza generalizada:", signif(res$varianza_generalizada, 3), "\n")
cat("PCA % varianza:", round(res$pca_var[1:4], 1), "\n")
cat("Kernel RBF sigma=0.1 (eig frac):", res$kpca_rbf_var, "\n")
cat("Kernel RBF sigma=1 (eig frac):", res$kpca_rbf_sigma1_var, "\n")
cat("Kernel polinomial grado 2 (eig frac):", res$kpca_poly_var, "\n")
