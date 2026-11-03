# Regenerate the PCA figures used in the presentation from the final model in
# informe_despues.Rmd. Run from any directory with Rscript.

suppressPackageStartupMessages({
  library(dplyr)
  library(car)
  library(ggplot2)
  library(ggrepel)
  library(tidyr)
})

args <- commandArgs(trailingOnly = FALSE)
script_arg <- sub("^--file=", "", args[grepl("^--file=", args)])
script_dir <- dirname(normalizePath(script_arg, winslash = "/", mustWork = TRUE))
data_path <- file.path(script_dir, "..", "data", "arabica_data_cleaned.csv")
output_dir <- file.path(script_dir, "figuras_pca_revision")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

vars_cuantitativas <- c(
  "Aroma", "Flavor", "Aftertaste", "Acidity", "Body", "Balance",
  "Uniformity", "Clean.Cup", "Sweetness", "Cupper.Points", "Moisture",
  "Category.One.Defects", "Category.Two.Defects", "altitude_mean_meters"
)
vars_excluir <- c(
  "Category.One.Defects", "Category.Two.Defects", "Moisture",
  "Sweetness", "Uniformity", "Clean.Cup"
)
etiquetas_es <- c(
  Aroma = "Aroma", Flavor = "Sabor", Aftertaste = "Retrogusto",
  Acidity = "Acidez", Body = "Cuerpo", Balance = "Balance",
  Cupper.Points = "Puntaje catador", altitude_mean_meters = "Altitud"
)

datos_fuente <- read.csv(data_path)
datos_filtrados <- datos_fuente %>%
  filter(!is.na(altitude_mean_meters),
         altitude_mean_meters > 0,
         altitude_mean_meters <= 3000)
datos <- datos_filtrados[, vars_cuantitativas]
vars_8 <- setdiff(names(datos), vars_excluir)
datos_t <- datos[, vars_8, drop = FALSE]

if (anyNA(datos_t)) stop("Hay NA en las 8 variables; no se puede reproducir el PCA del informe sin aclarar el tratamiento.")

skew <- function(x) mean((x - mean(x))^3) / sd(x)^3
skew_pre <- sapply(datos_t, skew)
vars_transformar <- names(skew_pre[abs(skew_pre) > 1])
if (length(vars_transformar) > 0) {
  pt_sel <- car::powerTransform(datos_t[, vars_transformar, drop = FALSE], family = "yjPower")
  lambdas_sel <- coef(pt_sel, round = FALSE)
  for (v in vars_transformar) {
    datos_t[[v]] <- car::yjPower(datos_t[[v]], lambdas_sel[v])
  }
}

pca_prelim <- prcomp(datos_t, center = TRUE, scale. = TRUE)
dm2_prelim <- rowSums((pca_prelim$x / pca_prelim$sdev)^2)
umbral <- qchisq(0.975, df = ncol(datos_t))
idx_atipicos <- which(dm2_prelim > umbral)
datos_limpio <- datos_t[-idx_atipicos, , drop = FALSE]
datos_limpio <- datos_limpio[, apply(datos_limpio, 2, var) > 0, drop = FALSE]
pca <- prcomp(datos_limpio, center = TRUE, scale. = TRUE)

if (nrow(datos_limpio) != 666L || ncol(datos_limpio) != 8L) {
  stop(sprintf("El pipeline produjo %d lotes x %d variables; el informe reporta 666 x 8. No se generaron figuras.",
               nrow(datos_limpio), ncol(datos_limpio)))
}

var_exp <- pca$sdev^2 / sum(pca$sdev^2)
var_pct <- 100 * var_exp
azul <- "#061D3D"
azul_punto <- "#4A86C8"
rojo <- "#C0392B"
tema <- theme_minimal(base_size = 15) +
  theme(plot.title = element_text(face = "bold", color = azul),
        plot.subtitle = element_text(color = "#555555"),
        axis.title = element_text(color = azul),
        panel.grid.minor = element_blank())

# Scree plot — the cumulative label is computed from this exact PCA fit.
df_scree <- data.frame(
  componente = factor(paste0("CP", seq_along(var_pct)),
                      levels = paste0("CP", seq_along(var_pct))),
  varianza = var_pct
)
p_scree <- ggplot(df_scree, aes(componente, varianza)) +
  geom_col(fill = azul, width = 0.68) +
  geom_text(aes(label = sprintf("%.1f%%", varianza)),
            vjust = -0.45, color = azul, fontface = "bold", size = 4) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.14))) +
  labs(title = "Varianza explicada por componente",
       subtitle = sprintf("CP1 + CP2 = %.1f%% | PCA final: 666 lotes, 8 variables",
                          sum(var_pct[1:2])),
       x = "Componente principal", y = "Varianza explicada (%)") +
  tema

# Loadings heatmap for the first four components.
loadings <- as.data.frame(pca$rotation[, 1:4, drop = FALSE])
loadings$variable <- rownames(loadings)
df_loadings <- pivot_longer(loadings, cols = starts_with("PC"),
                            names_to = "componente", values_to = "carga")
pc_labels <- setNames(
  sprintf("CP%d\n%.1f%%", 1:4, var_pct[1:4]), paste0("PC", 1:4)
)
df_loadings$componente <- factor(pc_labels[df_loadings$componente],
                                 levels = pc_labels[paste0("PC", 1:4)])
df_loadings$variable <- factor(
  etiquetas_es[as.character(df_loadings$variable)],
  levels = rev(unname(etiquetas_es[rownames(pca$rotation)]))
)
p_loadings <- ggplot(df_loadings, aes(componente, variable, fill = carga)) +
  geom_tile(color = "white", linewidth = 0.7) +
  geom_text(aes(label = sprintf("%.2f", carga)), color = azul, size = 4) +
  scale_fill_gradient2(low = "#4575B4", mid = "white", high = "#D73027",
                       midpoint = 0, limits = c(-1, 1), name = "Carga") +
  labs(title = "Cargas de las variables en CP1-CP4", x = NULL, y = NULL) +
  tema + theme(panel.grid = element_blank())

# PCA biplot: scores and loading vectors from the same final fit.
scores <- as.data.frame(pca$x[, 1:2, drop = FALSE])
names(scores) <- c("CP1", "CP2")
scores$lote <- seq_len(nrow(scores))
load <- as.data.frame(pca$rotation[, 1:2, drop = FALSE])
names(load) <- c("CP1", "CP2")
load$variable <- unname(etiquetas_es[rownames(load)])
score_span <- min(diff(range(scores$CP1)), diff(range(scores$CP2)))
escala <- 0.8 * score_span / (2 * max(abs(as.matrix(load[, c("CP1", "CP2")]))) )
load$fin1 <- load$CP1 * escala
load$fin2 <- load$CP2 * escala
p_biplot <- ggplot(scores, aes(CP1, CP2)) +
  geom_hline(yintercept = 0, color = "grey82") +
  geom_vline(xintercept = 0, color = "grey82") +
  geom_point(color = azul_punto, alpha = 0.38, size = 1.5) +
  geom_segment(data = load, aes(x = 0, y = 0, xend = fin1, yend = fin2),
               inherit.aes = FALSE, color = rojo, linewidth = 0.8,
               arrow = arrow(length = unit(0.18, "cm"))) +
  geom_text_repel(data = load, aes(fin1, fin2, label = variable),
                  inherit.aes = FALSE, color = rojo, size = 4,
                  max.overlaps = Inf, box.padding = 0.35) +
  labs(title = "Biplot PCA - CP1 vs. CP2",
       subtitle = sprintf("CP1: %.1f%% | CP2: %.1f%% | 666 lotes",
                          var_pct[1], var_pct[2]),
       x = sprintf("CP1 (%.1f%%)", var_pct[1]),
       y = sprintf("CP2 (%.1f%%)", var_pct[2])) +
  tema

ggsave(file.path(output_dir, "pca_final_scree.png"), p_scree,
       width = 6, height = 6.45, dpi = 200, bg = "white")
ggsave(file.path(output_dir, "pca_final_cargas.png"), p_loadings,
       width = 6, height = 6.45, dpi = 200, bg = "white")
ggsave(file.path(output_dir, "pca_final_biplot.png"), p_biplot,
       width = 6, height = 6.45, dpi = 200, bg = "white")

cat(sprintf("PCA reproducido: %d lotes x %d variables; atípicos retirados: %d\n",
            nrow(datos_limpio), ncol(datos_limpio), length(idx_atipicos)))
cat(sprintf("Varianza CP1=%.2f%%; CP2=%.2f%%; acumulada=%.2f%%\n",
            var_pct[1], var_pct[2], sum(var_pct[1:2])))
cat("Figuras guardadas en:", normalizePath(output_dir, winslash = "/"), "\n")
