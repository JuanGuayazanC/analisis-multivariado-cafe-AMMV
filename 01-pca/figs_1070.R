suppressMessages({library(ggplot2); library(car)})
obj <- readRDS("base_1070.rds")
Z <- obj$Z; R <- obj$raw; T <- obj$trans; n <- nrow(Z)
pca <- prcomp(Z, center = TRUE, scale. = TRUE)
sc <- as.data.frame(pca$x)
ve <- round(summary(pca)$importance[2, ] * 100, 1)
md2 <- mahalanobis(Z, colMeans(Z), cov(Z)); lim <- qchisq(0.975, 8)
cat("n=", n, " varianza:", ve, "\n"); print(round(pca$rotation[, 1:2], 2))
cat("Mahalanobis sobre umbral:", sum(md2 > lim), " max=", round(max(md2), 1), "\n")
th <- theme_minimal(base_size = 13) + theme(panel.grid.minor = element_blank(), plot.background = element_rect(fill = "white", color = NA))
df <- data.frame(PC = factor(paste0("CP", 1:8), levels = paste0("CP", 1:8)), pct = ve)
ggsave("figuras_1070/pca_1070_scree.png", ggplot(df, aes(PC, pct)) + geom_col(fill = "#0d2137", width = 0.7) +
  geom_text(aes(label = sprintf("%.1f%%", pct)), vjust = -0.4, fontface = "bold", size = 4) +
  labs(title = "Varianza explicada por componente", subtitle = sprintf("CP1 + CP2 = %.1f%% | PCA: %d lotes, 8 variables", ve[1] + ve[2], n), x = "Componente principal", y = "Varianza explicada (%)") +
  coord_cartesian(ylim = c(0, 70)) + th, width = 6.5, height = 6.8, dpi = 200, bg = "white")
rot <- pca$rotation[, 1:4]
cd <- data.frame(Variable = factor(rep(rownames(rot), 4), levels = rev(rownames(rot))),
                 Comp = factor(rep(paste0("CP", 1:4), each = nrow(rot)), levels = paste0("CP", 1:4)),
                 Carga = unlist(lapply(1:4, function(k) rot[, k])))
ggsave("figuras_1070/pca_1070_cargas.png", ggplot(cd, aes(Comp, Variable, fill = Carga)) + geom_tile(color = "white") +
  geom_text(aes(label = sprintf("%.2f", Carga)), size = 4) +
  scale_fill_gradient2(low = "#4575b4", mid = "white", high = "#d73027", limits = c(-1, 1), name = "Carga") +
  scale_x_discrete(labels = paste0(paste0("CP", 1:4), "\n", ve[1:4], "%")) +
  labs(title = "Cargas de las variables en CP1-CP4", x = NULL, y = NULL) + th + theme(panel.grid = element_blank()),
  width = 6.5, height = 6.8, dpi = 200, bg = "white")
ld <- as.data.frame(pca$rotation[, 1:2] * 4); ld$name <- rownames(ld)
ggsave("figuras_1070/pca_1070_biplot.png", ggplot(sc, aes(PC1, PC2)) + geom_point(alpha = 0.35, color = "#2563a8", size = 1.4) +
  geom_hline(yintercept = 0, color = "grey80") + geom_vline(xintercept = 0, color = "grey80") +
  geom_segment(data = ld, aes(x = 0, y = 0, xend = PC1, yend = PC2), inherit.aes = FALSE, arrow = arrow(length = unit(0.2, "cm")), color = "#c0392b") +
  geom_text(data = ld, aes(PC1, PC2, label = name), inherit.aes = FALSE, color = "#c0392b", size = 3.4, vjust = -0.5) +
  labs(title = "Biplot PCA - CP1 vs. CP2", subtitle = sprintf("CP1: %.1f%% | CP2: %.1f%% | %d lotes", ve[1], ve[2], n), x = sprintf("CP1 (%.1f%%)", ve[1]), y = sprintf("CP2 (%.1f%%)", ve[2])) + th,
  width = 6.5, height = 6.5, dpi = 200, bg = "white")
pl <- do.call(rbind, lapply(1:4, function(i) do.call(rbind, lapply(1:4, function(j) if (i != j) data.frame(x = sc[[j]], y = sc[[i]], xi = paste0("CP", j), yi = paste0("CP", i)) else NULL))))
ggsave("figuras_1070/pca_1070_dispersion.png", ggplot(pl, aes(x, y)) + geom_point(alpha = 0.3, size = 0.5, color = "#2563a8") +
  facet_grid(yi ~ xi, scales = "free") + labs(title = "Dispersión de componentes CP1 a CP4", subtitle = sprintf("%d lotes", n), x = NULL, y = NULL) + th + theme(strip.text = element_text(size = 9)),
  width = 9, height = 9, dpi = 200, bg = "white")
sk <- function(x) mean((x - mean(x))^3) / sd(x)^3
vy <- obj$yj
a <- rbind(data.frame(Variable = vy, Asimetria = sapply(R[, vy], sk), Momento = "Antes de Yeo-Johnson"),
           data.frame(Variable = vy, Asimetria = sapply(T[, vy], sk), Momento = "Después de Yeo-Johnson"))
ggsave("figuras_1070/1070_asimetria.png", ggplot(a, aes(Variable, Asimetria, fill = Momento)) + geom_col(position = "dodge", width = 0.7) +
  geom_hline(yintercept = c(-1, 1), linetype = "dashed", color = "grey40") + scale_fill_manual(values = c("#c0392b", "#2563a8")) +
  labs(title = "Asimetría antes y después de Yeo-Johnson", subtitle = sprintf("%d lotes", n), x = NULL, y = "Asimetría", fill = NULL) +
  th + theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "bottom"), width = 9, height = 6, dpi = 200, bg = "white")
ggsave("figuras_1070/1070_mahalanobis.png", ggplot(data.frame(md2 = md2), aes(md2)) + geom_histogram(bins = 40, fill = "#9fc3e6", color = "white") +
  geom_vline(xintercept = lim, color = "#c0392b", linewidth = 1) +
  labs(title = "Distancia de Mahalanobis", subtitle = sprintf("Umbral χ² 97,5 %% (8 g.l.) = %.1f · %d sobre el umbral", lim, sum(md2 > lim)), x = "d² de Mahalanobis", y = "Lotes") + th,
  width = 7, height = 6.5, dpi = 200, bg = "white")
cat("figuras listas\n")
