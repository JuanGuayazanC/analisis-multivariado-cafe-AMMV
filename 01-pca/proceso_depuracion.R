suppressMessages(library(ggplot2))
b <- readRDS("base_1070.rds")
T <- b$trans
pre <- prcomp(T, center = TRUE, scale. = TRUE)
dm2_pre <- rowSums((pre$x / pre$sdev)^2)
lim <- qchisq(0.975, 8)
out1 <- dm2_pre > lim
cat("Paso 1 (PCA preliminar, 1070): varianza", round(summary(pre)$importance[2,1:3]*100,1), " atipicos:", sum(out1), "\n")
M <- T[!out1, ]
p666 <- prcomp(M, center = TRUE, scale. = TRUE)
cat("Paso 2 (PCA 666):", round(summary(p666)$importance[2,1:3]*100,1), " n=", nrow(M), "\n")
Zm <- scale(M)
md2 <- mahalanobis(Zm, colMeans(Zm), cov(Zm))
out2 <- md2 > lim
cat("Paso 3 (Mahalanobis sobre 666 estandarizada): atipicos:", sum(out2), " quedan:", sum(!out2), "\n")
F <- M[!out2, ]
pf <- prcomp(F, center = TRUE, scale. = TRUE)
cat("Paso 4 (PCA final):", round(summary(pf)$importance[2,1:3]*100,1), " n=", nrow(F), "\n")
th <- theme_minimal(base_size = 13) + theme(panel.grid.minor = element_blank(), plot.background = element_rect(fill = NA, color = NA), panel.background = element_rect(fill = NA, color = NA), legend.position = "bottom")
ggsave("figuras_proceso/paso1_mahalanobis_pca_prelim.png", ggplot(data.frame(l = log10(dm2_pre), out = out1), aes(l, fill = out)) + geom_histogram(bins = 45, color = "white") +
  geom_vline(xintercept = log10(lim), color = "#c0392b", linewidth = 1) + scale_fill_manual(values = c("FALSE" = "#9fc3e6", "TRUE" = "#c0392b"), labels = c("Dentro", "Fuera")) +
  labs(title = "Paso 1 · distancia sobre los scores del PCA preliminar", subtitle = sprintf("%d lotes fuera del umbral χ² (8 g.l.) = %.1f", sum(out1), lim), x = "log10(d²)", y = "Lotes", fill = NULL) + th,
  width = 8, height = 6.5, dpi = 200, bg = "transparent")
ggsave("figuras_proceso/paso3_mahalanobis_666.png", ggplot(data.frame(l = log10(md2), out = out2), aes(l, fill = out)) + geom_histogram(bins = 45, color = "white") +
  geom_vline(xintercept = log10(lim), color = "#c0392b", linewidth = 1) + scale_fill_manual(values = c("FALSE" = "#9fc3e6", "TRUE" = "#c0392b"), labels = c("Dentro", "Fuera")) +
  labs(title = "Paso 3 · distancia en la matriz de 666 lotes", subtitle = sprintf("%d lotes fuera del umbral", sum(out2)), x = "log10(d²)", y = "Lotes", fill = NULL) + th,
  width = 8, height = 6.5, dpi = 200, bg = "transparent")
