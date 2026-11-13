# Figuras de la secuencia de depuración, en el orden en que se presentan:
# 1) PCA de 1.070 lotes con atípicos marcados (404)
# 2) PCA de 666 lotes con atípicos marcados (39)
# 3) PCA final de 627 lotes
# 4) Cargas CP1-CP3 como mapa de calor
suppressMessages(library(ggplot2))
dir.create("figuras_revision_profesor", showWarnings = FALSE)
th <- theme_minimal(base_size = 14) + theme(legend.position = "bottom")
lim <- qchisq(0.975, 8)

base <- readRDS("base_1070.rds")
T1070 <- base$trans
pre <- prcomp(T1070, center = TRUE, scale. = TRUE)
out1 <- rowSums((pre$x / pre$sdev)^2) > lim
p1 <- data.frame(CP1 = pre$x[, 1], CP2 = pre$x[, 2], Lote = ifelse(out1, "Atípico (404)", "Conservado"))
g1 <- ggplot(p1, aes(CP1, CP2, color = Lote)) + geom_point(alpha = 0.7, size = 1.6) +
  scale_color_manual(values = c("Conservado" = "#1f4e79", "Atípico (404)" = "#c0392b")) +
  labs(title = sprintf("PCA de 1.070 lotes: %d atípicos", sum(out1)), x = sprintf("CP1 (%.1f %%)", 100 * summary(pre)$importance[2, 1]), y = sprintf("CP2 (%.1f %%)", 100 * summary(pre)$importance[2, 2]), color = NULL) + th
ggsave("figuras_revision_profesor/seq1_pca1070_atipicos.png", g1, width = 8, height = 6, dpi = 200)

M <- T1070[!out1, ]
p666 <- prcomp(M, center = TRUE, scale. = TRUE)
Zm <- scale(M)
out2 <- mahalanobis(Zm, colMeans(Zm), cov(Zm)) > lim
p2 <- data.frame(CP1 = p666$x[, 1], CP2 = p666$x[, 2], Lote = ifelse(out2, "Atípico (39)", "Conservado"))
g2 <- ggplot(p2, aes(CP1, CP2, color = Lote)) + geom_point(alpha = 0.7, size = 1.6) +
  scale_color_manual(values = c("Conservado" = "#1f4e79", "Atípico (39)" = "#c0392b")) +
  labs(title = sprintf("PCA de 666 lotes: %d atípicos más", sum(out2)), x = sprintf("CP1 (%.1f %%)", 100 * summary(p666)$importance[2, 1]), y = sprintf("CP2 (%.1f %%)", 100 * summary(p666)$importance[2, 2]), color = NULL) + th
ggsave("figuras_revision_profesor/seq2_pca666_atipicos.png", g2, width = 8, height = 6, dpi = 200)

F627 <- M[!out2, ]
pf <- prcomp(F627, center = TRUE, scale. = TRUE)
L <- as.data.frame(as.table(pf$rotation[, 1:3]))
names(L) <- c("Variable", "Componente", "Carga")
L$Variable <- factor(L$Variable, levels = rev(rownames(pf$rotation)))
L$Componente <- factor(L$Componente, labels = c("CP1", "CP2", "CP3"))
g4 <- ggplot(L, aes(Componente, Variable, fill = Carga)) + geom_tile(color = "white") +
  geom_text(aes(label = sprintf("%.2f", Carga)), size = 5) +
  scale_fill_gradient2(low = "#2166ac", mid = "white", high = "#b2182b", limits = c(-1, 1)) +
  labs(title = "Cargas de CP1, CP2 y CP3 (627 lotes)", x = NULL, y = NULL) + theme_minimal(base_size = 14)
ggsave("figuras_revision_profesor/seq4_cargas_mapa.png", g4, width = 6.5, height = 6, dpi = 200)
cat("n1070", length(out1), "out1", sum(out1), "out2", sum(out2), "final", nrow(F627), "\n")
