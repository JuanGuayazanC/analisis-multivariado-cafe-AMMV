# Genera imágenes para Canva — análisis de outliers y Yeo-Johnson
# Output: analisis-multivariado/imagenes_canva/

library(robustbase)
library(ggplot2)
library(dplyr)
library(tidyr)
library(patchwork)

dir.create("imagenes_canva", showWarnings = FALSE)

# ── Datos ────────────────────────────────────────────────────────────────────

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

# ── Helpers Yeo-Johnson ───────────────────────────────────────────────────────

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

lambdas <- sapply(datos[c("Moisture", "Category.One.Defects", "Category.Two.Defects")],
                  yeojohnson_fit)

# ── 1. Comparación cajas clásicas vs ajustadas — Moisture ────────────────────

png("imagenes_canva/01_moisture_cajas_comparacion.png",
    width = 1600, height = 900, res = 150)
par(mfrow = c(1, 2), mar = c(5, 4, 5, 2), bg = "white",
    family = "sans", cex.main = 1.4, cex.axis = 1.1)

boxplot(datos$Moisture,
        main = "Moisture\nCaja clásica (Tukey)\n222 outliers",
        col = "#ffb3ba", border = "#c0392b",
        ylab = "Humedad (%)", outline = TRUE,
        outcol = "#c0392b", outpch = 19, outcex = 0.5)

adjbox(datos$Moisture,
       main = "Moisture\nCaja ajustada (medcouple)\n114 outliers",
       col = "#b3d9ff", border = "#2980b9",
       ylab = "Humedad (%)",
       col.out = "#2980b9", pch.out = 19, cex.out = 0.5)

dev.off()

# ── 2. Comparación cajas clásicas vs ajustadas — Category.Two.Defects ────────

png("imagenes_canva/02_defectos2_cajas_comparacion.png",
    width = 1600, height = 900, res = 150)
par(mfrow = c(1, 2), mar = c(5, 4, 5, 2), bg = "white",
    family = "sans", cex.main = 1.4, cex.axis = 1.1)

boxplot(datos$Category.Two.Defects,
        main = "Category.Two.Defects\nCaja clásica (Tukey)\n77 outliers",
        col = "#ffb3ba", border = "#c0392b",
        ylab = "Conteo de defectos",
        outcol = "#c0392b", outpch = 19, outcex = 0.5)

adjbox(datos$Category.Two.Defects,
       main = "Category.Two.Defects\nCaja ajustada (medcouple)\n20 outliers",
       col = "#b3d9ff", border = "#2980b9",
       ylab = "Conteo de defectos",
       col.out = "#2980b9", pch.out = 19, cex.out = 0.5)

dev.off()

# ── 3. Panel combinado (slide-ready) ─────────────────────────────────────────

png("imagenes_canva/03_cajas_panel_completo.png",
    width = 2400, height = 900, res = 150)
par(mfrow = c(2, 2), mar = c(4, 4, 4.5, 1), bg = "white",
    family = "sans", cex.main = 1.2, cex.axis = 1.0)

boxplot(datos$Moisture,
        main = "Moisture — clásica (222 outliers)",
        col = "#ffb3ba", border = "#c0392b",
        outcol = "#c0392b", outpch = 19, outcex = 0.4)

adjbox(datos$Moisture,
       main = "Moisture — ajustada (114 outliers)",
       col = "#b3d9ff", border = "#2980b9",
       col.out = "#2980b9", pch.out = 19, cex.out = 0.4)

boxplot(datos$Category.Two.Defects,
        main = "Defects2 — clásica (77 outliers)",
        col = "#ffb3ba", border = "#c0392b",
        outcol = "#c0392b", outpch = 19, outcex = 0.4)

adjbox(datos$Category.Two.Defects,
       main = "Defects2 — ajustada (20 outliers)",
       col = "#b3d9ff", border = "#2980b9",
       col.out = "#2980b9", pch.out = 19, cex.out = 0.4)

dev.off()

# ── 4. Curva log-verosimilitud Yeo-Johnson — Category.Two.Defects (converge) ─

lambda_seq <- seq(-3, 3, length.out = 300)
ll_cat2 <- sapply(lambda_seq, yeojohnson_loglik, x = datos$Category.Two.Defects)
lambda_opt_cat2 <- lambdas["Category.Two.Defects"]

png("imagenes_canva/04_yeojohnson_cat2_loglik.png",
    width = 1600, height = 900, res = 150)
par(mar = c(5, 5, 4, 2), bg = "white", family = "sans",
    cex.main = 1.4, cex.axis = 1.1, cex.lab = 1.2)

plot(lambda_seq, ll_cat2, type = "l", lwd = 2.5, col = "#27ae60",
     xlab = expression(lambda),
     ylab = "Log-verosimilitud perfilada",
     main = paste0("Yeo-Johnson — Category.Two.Defects\n",
                   "λ óptimo = ", round(lambda_opt_cat2, 3),
                   " (máximo interior, estimación estable)"))
abline(v = lambda_opt_cat2, col = "#e74c3c", lwd = 2, lty = 2)
abline(v = 1, col = "gray60", lwd = 1.5, lty = 3)
legend("bottomright",
       legend = c(paste0("λ óptimo = ", round(lambda_opt_cat2, 3)),
                  "λ = 1 (sin transformar)"),
       col = c("#e74c3c", "gray60"), lwd = c(2, 1.5), lty = c(2, 3),
       bty = "n", cex = 1.1)
dev.off()

# ── 5. Curvas log-verosimilitud — Moisture y Category.One.Defects (no conv.) ─

ll_moist <- sapply(lambda_seq, yeojohnson_loglik, x = datos$Moisture)
ll_cat1  <- sapply(lambda_seq, yeojohnson_loglik, x = datos$Category.One.Defects)

png("imagenes_canva/05_yeojohnson_infladas_cero.png",
    width = 2000, height = 900, res = 150)
par(mfrow = c(1, 2), mar = c(5, 5, 4.5, 2), bg = "white", family = "sans",
    cex.main = 1.2, cex.axis = 1.0, cex.lab = 1.1)

plot(lambda_seq, ll_moist, type = "l", lwd = 2.5, col = "#e67e22",
     xlab = expression(lambda), ylab = "Log-verosimilitud perfilada",
     main = paste0("Moisture — λ estimado = ", round(lambdas["Moisture"], 3),
                   "\n(pegado al límite inferior: variable inflada en cero)"))
abline(v = lambdas["Moisture"], col = "#e74c3c", lwd = 2, lty = 2)
abline(v = -5, col = "gray40", lwd = 1.5, lty = 3)

plot(lambda_seq, ll_cat1, type = "l", lwd = 2.5, col = "#8e44ad",
     xlab = expression(lambda), ylab = "Log-verosimilitud perfilada",
     main = paste0("Category.One.Defects — λ estimado = ",
                   round(lambdas["Category.One.Defects"], 3),
                   "\n(pegado al límite: variable inflada en cero)"))
abline(v = lambdas["Category.One.Defects"], col = "#e74c3c", lwd = 2, lty = 2)

dev.off()

# ── 6. Distribución antes/después — Category.Two.Defects transformada ─────────

cat2_original   <- datos$Category.Two.Defects
cat2_transf     <- yeojohnson_transform(cat2_original, lambda_opt_cat2)

df_hist <- data.frame(
  valor = c(cat2_original, cat2_transf),
  tipo  = rep(c("Original", paste0("Yeo-Johnson (λ=",
                                    round(lambda_opt_cat2, 2), ")")),
              each = length(cat2_original))
)

p <- ggplot(df_hist, aes(x = valor, fill = tipo)) +
  geom_histogram(bins = 40, color = "white", alpha = 0.85) +
  facet_wrap(~tipo, scales = "free") +
  scale_fill_manual(values = c("#e74c3c", "#27ae60")) +
  labs(title = "Category.Two.Defects — antes y después de Yeo-Johnson",
       x = "Valor", y = "Frecuencia") +
  theme_minimal(base_size = 14) +
  theme(legend.position = "none",
        plot.title = element_text(face = "bold", hjust = 0.5),
        strip.text = element_text(size = 13, face = "bold"))

ggsave("imagenes_canva/06_cat2_distribucion_antes_despues.png",
       plot = p, width = 14, height = 6, dpi = 150, bg = "white")

# ── 07. Matriz de correlación (diapositiva 3, Exploración) ────────────────────

R_mat <- cor(datos)
df_cor <- as.data.frame(as.table(R_mat))
names(df_cor) <- c("x", "y", "r")
df_cor$x <- factor(df_cor$x, levels = vars_cuantitativas)
df_cor$y <- factor(df_cor$y, levels = rev(vars_cuantitativas))

p <- ggplot(df_cor, aes(x, y, fill = r)) +
  geom_tile(color = "white") +
  geom_text(aes(label = sprintf("%.2f", r)), size = 3.3, color = "#061d3d") +
  scale_fill_gradient2(low = "#4575b4", mid = "white", high = "#d73027",
                       midpoint = 0, limits = c(-1, 1), name = "r") +
  labs(title = "Matriz de correlación de las 14 variables", x = NULL, y = NULL) +
  theme_minimal(base_size = 14) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        panel.grid = element_blank(),
        plot.title = element_text(face = "bold", color = "#061d3d"))

ggsave("imagenes_canva/07_matriz_correlacion.png",
       plot = p, width = 9.5, height = 8.5, dpi = 150, bg = "white")

cat("\n✓ 7 imágenes generadas en analisis-multivariado/imagenes_canva/\n")
cat("  01_moisture_cajas_comparacion.png\n")
cat("  02_defectos2_cajas_comparacion.png\n")
cat("  03_cajas_panel_completo.png\n")
cat("  04_yeojohnson_cat2_loglik.png\n")
cat("  05_yeojohnson_infladas_cero.png\n")
cat("  06_cat2_distribucion_antes_despues.png\n")
cat("  07_matriz_correlacion.png\n")
