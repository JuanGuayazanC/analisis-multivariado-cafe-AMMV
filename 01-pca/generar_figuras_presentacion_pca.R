# Figuras del PCA final (970 lotes, 8 variables) para las diapositivas.
# Lee la matriz final `datos/datos_final_970.rds` que produce depuracion.Rmd y guarda
# el codo, el mapa de cargas y el biplot, con fondo transparente, en figuras/pca_revision/.
# Ejecutar desde cualquier carpeta:  Rscript 01-pca/generar_figuras_presentacion_pca.R

suppressPackageStartupMessages({
  library(ggplot2)
  library(ggrepel)
  library(tidyr)
})

args <- commandArgs(trailingOnly = FALSE)
script_arg <- sub("^--file=", "", args[grepl("^--file=", args)])
script_dir <- if (length(script_arg)) dirname(normalizePath(script_arg, winslash = "/")) else getwd()
rds_path <- file.path(script_dir, "..", "datos", "datos_final_970.rds")
output_dir <- file.path(script_dir, "figuras", "pca_revision")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

obj <- readRDS(rds_path)
datos <- obj$datos_limpio          # 970 lotes x 8 variables, ya sin Yeo-Johnson (ver depuracion.Rmd)
if (nrow(datos) != 970L || ncol(datos) != 8L) {
  stop(sprintf("datos_final_970.rds tiene %d lotes x %d variables; se esperaban 970 x 8.", nrow(datos), ncol(datos)))
}
pca <- prcomp(datos, center = TRUE, scale. = TRUE)

etiquetas_es <- c(Aroma = "Aroma", Sabor = "Sabor", Retrogusto = "Retrogusto",
                  Acidez = "Acidez", Cuerpo = "Cuerpo", Balance = "Balance",
                  Puntaje.Catador = "Puntaje catador", Altitud = "Altitud")

var_pct <- 100 * pca$sdev^2 / sum(pca$sdev^2)
azul <- "#061D3D"; azul_punto <- "#4A86C8"; rojo <- "#C0392B"
tema <- theme_minimal(base_size = 15) +
  theme(plot.title = element_text(face = "bold", color = azul),
        plot.subtitle = element_text(color = "#555555"),
        axis.title = element_text(color = azul),
        plot.background = element_rect(fill = "transparent", color = NA),
        panel.background = element_rect(fill = "transparent", color = NA),
        legend.background = element_rect(fill = "transparent", color = NA),
        legend.key = element_rect(fill = "transparent", color = NA),
        panel.grid.minor = element_blank())

# Varianza explicada por componente (todas las cifras salen de este mismo ajuste)
df_scree <- data.frame(componente = factor(paste0("CP", seq_along(var_pct)), levels = paste0("CP", seq_along(var_pct))),
                       varianza = var_pct)
p_scree <- ggplot(df_scree, aes(componente, varianza)) +
  geom_col(fill = azul, width = 0.68) +
  geom_text(aes(label = sprintf("%.1f%%", varianza)), vjust = -0.45, color = azul, fontface = "bold", size = 4) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.14))) +
  labs(title = "Varianza explicada por componente",
       subtitle = sprintf("CP1 + CP2 = %.1f%% | PCA final: 970 lotes, 8 variables", sum(var_pct[1:2])),
       x = "Componente principal", y = "Varianza explicada (%)") + tema

# Mapa de cargas de CP1-CP4
loadings <- as.data.frame(pca$rotation[, 1:4, drop = FALSE])
loadings$variable <- rownames(loadings)
df_loadings <- pivot_longer(loadings, cols = starts_with("PC"), names_to = "componente", values_to = "carga")
pc_labels <- setNames(sprintf("CP%d\n%.1f%%", 1:4, var_pct[1:4]), paste0("PC", 1:4))
df_loadings$componente <- factor(pc_labels[df_loadings$componente], levels = pc_labels[paste0("PC", 1:4)])
df_loadings$variable <- factor(etiquetas_es[as.character(df_loadings$variable)],
                               levels = rev(unname(etiquetas_es[rownames(pca$rotation)])))
p_loadings <- ggplot(df_loadings, aes(componente, variable, fill = carga)) +
  geom_tile(color = "white", linewidth = 0.7) +
  geom_text(aes(label = sprintf("%.2f", carga)), color = azul, size = 4) +
  scale_fill_gradient2(low = "#4575B4", mid = "white", high = "#D73027", midpoint = 0, limits = c(-1, 1), name = "Carga") +
  labs(title = "Cargas de las variables en CP1-CP4", x = NULL, y = NULL) + tema + theme(panel.grid = element_blank())

# Biplot CP1 vs CP2
scores <- as.data.frame(pca$x[, 1:2, drop = FALSE]); names(scores) <- c("CP1", "CP2")
load <- as.data.frame(pca$rotation[, 1:2, drop = FALSE]); names(load) <- c("CP1", "CP2")
load$variable <- unname(etiquetas_es[rownames(load)])
escala <- 0.8 * min(diff(range(scores$CP1)), diff(range(scores$CP2))) / (2 * max(abs(as.matrix(load[, c("CP1", "CP2")]))))
load$fin1 <- load$CP1 * escala; load$fin2 <- load$CP2 * escala
p_biplot <- ggplot(scores, aes(CP1, CP2)) +
  geom_hline(yintercept = 0, color = "grey82") + geom_vline(xintercept = 0, color = "grey82") +
  geom_point(color = azul_punto, alpha = 0.38, size = 1.5) +
  geom_segment(data = load, aes(x = 0, y = 0, xend = fin1, yend = fin2), inherit.aes = FALSE,
               color = rojo, linewidth = 0.8, arrow = arrow(length = unit(0.18, "cm"))) +
  geom_text_repel(data = load, aes(fin1, fin2, label = variable), inherit.aes = FALSE,
                  color = rojo, size = 4, max.overlaps = Inf, box.padding = 0.35) +
  labs(title = "Biplot PCA - CP1 vs. CP2",
       subtitle = sprintf("CP1: %.1f%% | CP2: %.1f%% | 970 lotes", var_pct[1], var_pct[2]),
       x = sprintf("CP1 (%.1f%%)", var_pct[1]), y = sprintf("CP2 (%.1f%%)", var_pct[2])) + tema

ggsave(file.path(output_dir, "pca_final_scree.png"), p_scree, width = 6, height = 6.45, dpi = 200, bg = "transparent")
ggsave(file.path(output_dir, "pca_final_cargas.png"), p_loadings, width = 6, height = 6.45, dpi = 200, bg = "transparent")
ggsave(file.path(output_dir, "pca_final_biplot.png"), p_biplot, width = 6, height = 6.45, dpi = 200, bg = "transparent")

cat(sprintf("PCA: %d lotes x %d variables | CP1=%.2f%% CP2=%.2f%% acumulado=%.2f%%\n",
            nrow(datos), ncol(datos), var_pct[1], var_pct[2], sum(var_pct[1:2])))
cat("Figuras guardadas en:", normalizePath(output_dir, winslash = "/"), "\n")
