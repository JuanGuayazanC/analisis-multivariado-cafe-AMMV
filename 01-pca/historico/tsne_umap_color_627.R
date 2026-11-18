# t-SNE y UMAP sobre la matriz final de 627 lotes, coloreados por método de proceso.
# Usa la misma cadena de depuración que revision_pca_profesor.R (secciones 1 a 2).
library(Rtsne); library(uwot); library(ggplot2)
source_lines <- readLines("revision_pca_profesor.R")
eval(parse(text = source_lines[1:40]))   # define F627 y meta627 con la misma depuración
dir.create("figuras_revision_profesor", showWarnings = FALSE)
Z <- scale(F627)
pm <- trimws(as.character(meta627$Processing.Method))
pm[is.na(pm) | pm == ""] <- "Desconocido"
grupo <- factor(pm)
set.seed(2026); tsne <- Rtsne(Z, dims = 2, perplexity = 30, theta = 0.5, check_duplicates = FALSE)
set.seed(2026); um <- umap(Z, n_neighbors = 15, min_dist = 0.1)
mk <- function(xy, xl, yl, ttl) {
  df <- data.frame(x = xy[, 1], y = xy[, 2], Proceso = grupo)
  ggplot(df, aes(x, y, colour = Proceso)) + geom_point(alpha = 0.7, size = 1.6) +
    labs(title = ttl, x = xl, y = yl, colour = "Método de proceso") +
    theme_minimal(base_size = 12) +
    theme(plot.background = element_rect(fill = "transparent", colour = NA),
          panel.background = element_rect(fill = "transparent", colour = NA),
          legend.background = element_rect(fill = "transparent", colour = NA))
}
ggsave("figuras/revision_profesor/tsne_color_proceso.png", mk(tsne$Y, "t-SNE 1", "t-SNE 2", "t-SNE (perplexity = 30), 627 lotes"), width = 9, height = 6, dpi = 180, bg = "transparent")
ggsave("figuras/revision_profesor/umap_color_proceso.png", mk(um, "UMAP 1", "UMAP 2", "UMAP (15 vecinos, min_dist = 0,1), 627 lotes"), width = 9, height = 6, dpi = 180, bg = "transparent")
cat("tabla de procesos:\n"); print(table(grupo))
