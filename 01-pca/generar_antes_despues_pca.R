# Genera imágenes "antes vs después" de aplicar Yeo-Johnson a Category.Two.Defects
# Output: analisis-multivariado/comparacion_pca/

library(dplyr)

dir.create("comparacion_pca", showWarnings = FALSE)

# ── Datos ─────────────────────────────────────────────────────────────────────

data_raw <- read.csv("../data/arabica_data_cleaned.csv")

vars_cuantitativas <- c("Aroma", "Flavor", "Aftertaste", "Acidity", "Body",
                        "Balance", "Uniformity", "Clean.Cup", "Sweetness",
                        "Cupper.Points", "Moisture", "Category.One.Defects",
                        "Category.Two.Defects", "altitude_mean_meters")

datos <- data_raw %>%
  filter(!is.na(altitude_mean_meters),
         altitude_mean_meters > 0,
         altitude_mean_meters <= 3000) %>%
  select(all_of(vars_cuantitativas))

# ── Yeo-Johnson ───────────────────────────────────────────────────────────────

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

lambda_cat2 <- yeojohnson_fit(datos$Category.Two.Defects)

datos_transformados <- datos
datos_transformados$Category.Two.Defects <- yeojohnson_transform(
  datos$Category.Two.Defects, lambda_cat2)

# ── PCA antes y después ───────────────────────────────────────────────────────

pca_antes    <- prcomp(datos,             center = TRUE, scale. = TRUE)
pca_despues  <- prcomp(datos_transformados, center = TRUE, scale. = TRUE)

k <- 4

# Índices de outliers conocidos
idx_cero     <- which(datos$Aroma == 0)[1]               # lote con todo en cero
idx_defectos <- order(datos$Category.One.Defects, decreasing = TRUE)[1:3]  # más defectos primarios

col_puntos <- rep(adjustcolor("steelblue", 0.35), nrow(datos))
col_puntos[idx_cero]     <- "#e74c3c"   # rojo: error de captura (puntajes en cero)
col_puntos[idx_defectos] <- "#e67e22"   # naranja: defectos extremos

pch_puntos <- rep(19, nrow(datos))
pch_puntos[c(idx_cero, idx_defectos)] <- 17   # triángulo para destacarlos

# ── 1. Scatter matrix ANTES ───────────────────────────────────────────────────

png("comparacion_pca/01_ANTES_scatter_matrix_sin_transformar.png",
    width = 1600, height = 1600, res = 150)
pairs(pca_antes$x[, 1:k],
      main = paste0("Scatter matrix PCA  —  ANTES de Yeo-Johnson\n",
                    "(Category.Two.Defects en escala original)"),
      pch  = pch_puntos,
      col  = col_puntos,
      cex  = 0.6,
      labels = c("PC1\n47.7%", "PC2\n10.0%", "PC3\n9.6%", "PC4\n7.3%"))

legend("topright",
       legend = c("Lotes normales",
                  "Lote con puntajes = 0 (error de captura)",
                  "Lotes con 23–31 defectos primarios"),
       col  = c(adjustcolor("steelblue", 0.5), "#e74c3c", "#e67e22"),
       pch  = c(19, 17, 17),
       bty  = "n", cex = 0.9)
dev.off()

# ── 2. Scatter matrix DESPUÉS ─────────────────────────────────────────────────

# En la versión transformada, Category.Two.Defects pasa a ser PC3 (no PC2).
# Los mismos outliers, mismos colores, para comparar directamente.

png("comparacion_pca/02_DESPUES_scatter_matrix_con_yeojohnson.png",
    width = 1600, height = 1600, res = 150)

# Varianza explicada de la versión transformada
var_exp <- round(summary(pca_despues)$importance[2, 1:k] * 100, 1)

pairs(pca_despues$x[, 1:k],
      main = paste0("Scatter matrix PCA  —  DESPUÉS de Yeo-Johnson\n",
                    "(Category.Two.Defects con λ≈", round(lambda_cat2, 2), ")"),
      pch  = pch_puntos,
      col  = col_puntos,
      cex  = 0.6,
      labels = paste0("PC", 1:k, "\n", var_exp, "%"))

legend("topright",
       legend = c("Lotes normales",
                  "Lote con puntajes = 0 (error de captura)",
                  "Lotes con 23–31 defectos primarios"),
       col  = c(adjustcolor("steelblue", 0.5), "#e74c3c", "#e67e22"),
       pch  = c(19, 17, 17),
       bty  = "n", cex = 0.9)
dev.off()

# ── 3. Zoom: eje de defectos ANTES (PC2) vs DESPUÉS (PC3) ────────────────────
# Muestra el lote 987 (45 defectos secundarios) que desaparece como outlier.

idx_987 <- order(datos$Category.Two.Defects, decreasing = TRUE)[2]   # fila con 45 defectos secundarios y 0 primarios

col_zoom <- rep(adjustcolor("steelblue", 0.3), nrow(datos))
col_zoom[idx_cero]     <- "#e74c3c"
col_zoom[idx_defectos] <- "#e67e22"
col_zoom[idx_987]      <- "#8e44ad"   # morado: el que desaparece al transformar

pch_zoom <- rep(19, nrow(datos))
pch_zoom[c(idx_cero, idx_defectos)] <- 17
pch_zoom[idx_987] <- 15   # cuadrado para el lote 987

png("comparacion_pca/03_ZOOM_eje_defectos_antes_PC1vPC2.png",
    width = 1400, height = 700, res = 150)
par(mfrow = c(1, 2), mar = c(5, 5, 5, 2), bg = "white",
    family = "sans", cex.main = 1.2, cex.axis = 1.0, cex.lab = 1.1)

# Antes: defectos en PC2
plot(pca_antes$x[, 1], pca_antes$x[, 2],
     xlab = "PC1 — Calidad sensorial (47.7%)",
     ylab = "PC2 — Defectos físicos (10.0%)",
     main = "ANTES: defectos en PC2\n(escala original)",
     pch  = pch_zoom, col = col_zoom, cex = 0.6)
abline(h = 0, v = 0, col = "gray70", lty = 2)

# Después: defectos en PC3 (ahora PC1 vs PC3)
plot(pca_despues$x[, 1], pca_despues$x[, 3],
     xlab = paste0("PC1 — Calidad sensorial (", var_exp[1], "%)"),
     ylab = paste0("PC3 — Defectos físicos (", var_exp[3], "%)"),
     main = paste0("DESPUÉS: defectos en PC3\n(Yeo-Johnson λ≈", round(lambda_cat2, 2), ")"),
     pch  = pch_zoom, col = col_zoom, cex = 0.6)
abline(h = 0, v = 0, col = "gray70", lty = 2)

legend("topright",
       legend = c("Normales",
                  "Puntajes = 0",
                  "31 defectos primarios",
                  "45 def. sec. / 0 primarios\n(desaparece al transformar)"),
       col  = c(adjustcolor("steelblue", 0.4), "#e74c3c", "#e67e22", "#8e44ad"),
       pch  = c(19, 17, 17, 15),
       bty  = "n", cex = 0.8)
dev.off()

cat("\n✓ 3 imágenes generadas en analisis-multivariado/comparacion_pca/\n")
cat("  01_ANTES_scatter_matrix_sin_transformar.png\n")
cat("  02_DESPUES_scatter_matrix_con_yeojohnson.png\n")
cat("  03_ZOOM_eje_defectos_antes_PC1vPC2.png\n")
cat("\nLote clave (morado):\n")
cat("  fila", idx_987, "— Category.Two.Defects =", datos$Category.Two.Defects[idx_987],
    "| Category.One.Defects =", datos$Category.One.Defects[idx_987], "\n")
cat("  PC2 antes:", round(pca_antes$x[idx_987, 2], 2),
    "| PC3 despues:", round(pca_despues$x[idx_987, 3], 2), "\n")
