# Figuras de las diapositivas del análisis OFICIAL (Category.Two.Defects con Yeo-Johnson)
# Salida: analisis-multivariado/imagenes_canva/  (archivos 08 en adelante)
# Ejecutar desde analisis-multivariado/ :  Rscript generar_figuras_pca_oficial.R

library(dplyr)
library(ggplot2)
library(GGally)
library(ggrepel)
library(tidyr)
library(kernlab)
library(Rtsne)
library(uwot)

dir.create("imagenes_canva", showWarnings = FALSE)

# ── Datos oficiales (mismo tratamiento que informe_taller_pca.Rmd, secciones 2, 3.2 y 5) ──

data_raw <- read.csv("../data/arabica_data_cleaned.csv")

vars_cuantitativas <- c("Aroma", "Flavor", "Aftertaste", "Acidity", "Body",
                        "Balance", "Uniformity", "Clean.Cup", "Sweetness",
                        "Cupper.Points", "Moisture", "Category.One.Defects",
                        "Category.Two.Defects", "altitude_mean_meters")

data_f <- data_raw %>%
  filter(!is.na(altitude_mean_meters),
         altitude_mean_meters > 0,
         altitude_mean_meters <= 3000)

datos <- data_f %>% select(all_of(vars_cuantitativas))

yeojohnson_transform <- function(x, lambda) {
  if (lambda != 0) ((x + 1)^lambda - 1) / lambda else log(x + 1)
}
yeojohnson_loglik <- function(lambda, x) {
  y <- yeojohnson_transform(x, lambda)
  -length(x) / 2 * log(var(y)) + (lambda - 1) * sum(log(x + 1))
}
yeojohnson_fit <- function(x) {
  optimize(yeojohnson_loglik, interval = c(-5, 5), x = x, maximum = TRUE)$maximum
}

lambda_c2 <- yeojohnson_fit(datos$Category.Two.Defects)
datos_t <- datos
datos_t$Category.Two.Defects <- yeojohnson_transform(datos$Category.Two.Defects, lambda_c2)

pca <- prcomp(datos_t, center = TRUE, scale. = TRUE)

# ── Estilo común (paleta de la presentación: azul marino + turquesa/naranja) ──

azul   <- "#061d3d"
tema <- theme_minimal(base_size = 16) +
  theme(plot.title = element_text(face = "bold", color = azul),
        axis.title = element_text(color = azul),
        panel.grid.minor = element_blank())

guardar <- function(nombre, plot, w, h) {
  ggsave(file.path("imagenes_canva", nombre), plot = plot, width = w, height = h,
         dpi = 150, bg = "white")
}

# ── 08. Gráfico de codo ──────────────────────────────────────────────────────

df_codo <- data.frame(PC = 1:14, lambda = pca$sdev^2)
p <- ggplot(df_codo, aes(PC, lambda)) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "#c0392b") +
  geom_line(color = azul, linewidth = 1) +
  geom_point(color = azul, size = 3) +
  annotate("text", x = 13.6, y = 1.25, label = "Kaiser: λ = 1", color = "#c0392b",
           hjust = 1, size = 5) +
  scale_x_continuous(breaks = 1:14) +
  labs(title = "Gráfico de codo — PCA oficial",
       x = "Componente", y = "Valor propio λ") +
  tema
guardar("08_codo_pca.png", p, 8, 5.5)

# ── 09. Mapa de calor de cargas PC1–PC4 ──────────────────────────────────────

cargas <- as.data.frame(pca$rotation[, 1:4])
cargas$variable <- factor(rownames(cargas), levels = rev(vars_cuantitativas))
df_car <- pivot_longer(cargas, PC1:PC4, names_to = "PC", values_to = "carga")
etiquetas_pc <- c(PC1 = "PC1\n47,6 %", PC2 = "PC2\n9,6 %", PC3 = "PC3\n9,0 %", PC4 = "PC4\n7,5 %")
df_car$PC <- factor(etiquetas_pc[df_car$PC], levels = etiquetas_pc)

p <- ggplot(df_car, aes(PC, variable, fill = carga)) +
  geom_tile(color = "white") +
  geom_text(aes(label = sprintf("%.2f", carga)), size = 4, color = azul) +
  scale_fill_gradient2(low = "#4575b4", mid = "white", high = "#d73027",
                       midpoint = 0, limits = c(-0.8, 0.8), name = "Carga") +
  labs(title = "Cargas de PC1 a PC4", x = NULL, y = NULL) +
  tema + theme(panel.grid = element_blank())
guardar("09_cargas_heatmap.png", p, 7, 7.5)

# ── 10. Matriz de dispersión de PC1–PC4 coloreada por método de proceso ──────

scores <- as.data.frame(pca$x[, 1:4])
scores$Metodo <- ifelse(data_f$Processing.Method == "", "Sin dato", data_f$Processing.Method)
p <- ggpairs(scores, columns = 1:4,
             aes(color = Metodo, alpha = 0.5),
             upper = list(continuous = "points"),
             diag  = list(continuous = wrap("densityDiag", alpha = 0.4)),
             lower = list(continuous = wrap("points", size = 0.7)),
             legend = c(1, 1)) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom", panel.grid.minor = element_blank())
guardar("10_pairs_pca_metodo.png", p, 8.5, 8.5)

# ── 11–12. Biplots (PC1–PC2 y PC1–PC3) ───────────────────────────────────────

biplot_gg <- function(pcs, titulo, xlim, ylim, nota) {
  sc <- as.data.frame(pca$x[, pcs]); names(sc) <- c("x", "y")
  ld <- as.data.frame(pca$rotation[, pcs]); names(ld) <- c("x", "y")
  ld$var <- rownames(ld)
  escala <- 0.9 * min(min(abs(xlim)) / max(abs(ld$x)), min(abs(ylim)) / max(abs(ld$y)))
  ld$xe <- ld$x * escala; ld$ye <- ld$y * escala
  destacados <- c(1070, 1014, 435, 1047)   # lote con todo en 0 y lotes con 31 defectos primarios
  sc$id <- ""; sc$id[destacados] <- destacados
  sc$id[sc$x < xlim[1] | sc$x > xlim[2] | sc$y < ylim[1] | sc$y > ylim[2]] <- ""   # solo etiquetar lo visible
  ggplot() +
    geom_hline(yintercept = 0, color = "grey75") + geom_vline(xintercept = 0, color = "grey75") +
    geom_point(data = sc, aes(x, y), color = "#4a86c8", alpha = 0.35, size = 1.2) +
    geom_segment(data = ld, aes(0, 0, xend = xe, yend = ye), color = "#c0392b",
                 arrow = arrow(length = unit(0.15, "cm")), linewidth = 0.6) +
    geom_text_repel(data = ld, aes(xe, ye, label = var), color = "#c0392b", size = 3.6,
                    max.overlaps = Inf, box.padding = 0.35, segment.color = "grey70") +
    geom_text_repel(data = subset(sc, id != ""), aes(x, y, label = paste("lote", id)),
                    color = azul, size = 3.4, box.padding = 0.5, max.overlaps = Inf) +
    coord_cartesian(xlim = xlim, ylim = ylim) +
    labs(title = titulo, caption = nota,
         x = paste0("PC", pcs[1], " (", sprintf("%.1f", 100 * pca$sdev[pcs[1]]^2 / 14), " %)"),
         y = paste0("PC", pcs[2], " (", sprintf("%.1f", 100 * pca$sdev[pcs[2]]^2 / 14), " %)")) +
    tema
}
guardar("11_biplot_pc1_pc2.png",
        biplot_gg(c(1, 2), "Biplot — PC1 vs PC2", c(-8, 12), c(-8, 4),
                  "Fuera del recuadro: lote 1070 (todos los puntajes en 0, PC1 = 56) y lote 1069"), 8.5, 7)
guardar("12_biplot_pc1_pc3.png",
        biplot_gg(c(1, 3), "Biplot — PC1 vs PC3 (eje de defectos)", c(-8, 12), c(-4.5, 11.5),
                  "Fuera del recuadro: lote 1070 (todos los puntajes en 0, PC1 = 56)"), 8.5, 7)

# ── Kernel PCA (mismo código que la sección 10 del informe) ──────────────────

datos_esc <- as.data.frame(scale(datos_t))
kp <- kpca(~., data = datos_esc, kernel = "rbfdot", kpar = list(sigma = 0.05), features = 5)
kp_alto <- kpca(~., data = datos_esc, kernel = "rbfdot", kpar = list(sigma = 1), features = 5)

pairs_png <- function(archivo, m, titulo, color, w = 900, h = 900) {
  png(file.path("imagenes_canva", archivo), width = w, height = h, res = 130, bg = "white")
  pairs(m, main = titulo, pch = 19, col = adjustcolor(color, alpha.f = 0.4),
        labels = paste0("KPC", 1:ncol(m)))
  dev.off()
}
pairs_png("13_kpca_sigma005.png", rotated(kp)[, 1:5],
          "Kernel PCA (RBF, sigma = 0.05)", "darkorange")
pairs_png("14_kpca_sigma1.png", rotated(kp_alto)[, 1:5],
          "Kernel PCA (RBF, sigma = 1)", "firebrick")

# ── t-SNE y UMAP (mismas semillas y parámetros que las secciones 12 y 13) ────

X <- scale(datos_t)

dispersion_png <- function(archivo, m, titulo, color, xl, yl) {
  png(file.path("imagenes_canva", archivo), width = 1000, height = 750, res = 130, bg = "white")
  par(mar = c(4.5, 4.5, 3.5, 1))
  plot(m[, 1], m[, 2], pch = 19, col = adjustcolor(color, alpha.f = 0.5),
       xlab = xl, ylab = yl, main = titulo, cex.main = 1.3)
  dev.off()
}

set.seed(123)
tsne30 <- Rtsne(X, dims = 2, perplexity = 30, theta = 0.5)
dispersion_png("15_tsne_perp30.png", tsne30$Y, "t-SNE (perplexity = 30)", "seagreen", "t-SNE 1", "t-SNE 2")

set.seed(123)
tsne5 <- Rtsne(X, dims = 2, perplexity = 5, theta = 0.5)
dispersion_png("16_tsne_perp5.png", tsne5$Y, "t-SNE (perplexity = 5)", "seagreen", "t-SNE 1", "t-SNE 2")

set.seed(123)
um <- umap(X)
dispersion_png("17_umap_default.png", um, "UMAP (parámetros por defecto)", "mediumpurple", "UMAP1", "UMAP2")

set.seed(123)
um5 <- umap(X, n_neighbors = 5)
dispersion_png("18_umap_nn5.png", um5, "UMAP (n_neighbors = 5)", "mediumpurple", "UMAP1", "UMAP2")

cat("\n✓ Figuras 08–18 generadas en analisis-multivariado/imagenes_canva/\n")
