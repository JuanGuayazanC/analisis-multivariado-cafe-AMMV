suppressMessages(library(ggplot2))
Z <- readRDS("base_1070.rds")$Z
md2 <- mahalanobis(Z, colMeans(Z), cov(Z)); lim <- qchisq(0.975, 8)
df <- data.frame(l = log10(md2), out = md2 > lim)
g <- ggplot(df, aes(l, fill = out)) + geom_histogram(bins = 45, color = "white") +
  geom_vline(xintercept = log10(lim), color = "#c0392b", linewidth = 1) +
  scale_fill_manual(values = c("FALSE" = "#9fc3e6", "TRUE" = "#c0392b"), labels = c("Dentro", "Fuera del umbral")) +
  labs(title = "Distancia de Mahalanobis (escala log)", subtitle = sprintf("Umbral χ² 97,5 %% (8 g.l.) = %.1f · %d lotes fuera", lim, sum(df$out)), x = "log10(d²)", y = "Lotes", fill = NULL) +
  theme_minimal(base_size = 13) + theme(panel.grid.minor = element_blank(), plot.background = element_rect(fill = NA, color = NA), panel.background = element_rect(fill = NA, color = NA), legend.position = "bottom")
ggsave("figuras_1070/1070_mahalanobis.png", g, width = 8, height = 6.5, dpi = 200, bg = "transparent")
cat("ok\n")
