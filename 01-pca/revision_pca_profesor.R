# Revisión PCA según recomendaciones de la sustentación.
# Trabaja sobre la misma cadena de depuración (1.070 -> 666 -> 627) y produce:
#  - medcouple y diagrama de cajas clásico vs ajustado (robusto para asimetría)
#  - justificación de Yeo-Johnson solo en las variables con asimetría
#  - supuestos del PCA (centrado, atípicos)
#  - gráfico del codo con intervalos de confianza bootstrap
#  - dispersión de scores ANTES de las cargas, cargas de CP1-CP3 y biplot
#  - t-SNE y UMAP exploratorios coloreados por método de proceso
# Salida: figuras_revision_profesor/ y resultados_revision_profesor.txt

suppressMessages({ library(ggplot2); library(robustbase); library(Rtsne); library(uwot) })
set.seed(2026)
dir.create("figuras_revision_profesor", showWarnings = FALSE)
out_txt <- character()
add <- function(...) out_txt <<- c(out_txt, paste0(...))

# ---- 1. Datos y cadena de depuración (idéntica a proceso_depuracion.R) ----
d <- read.csv("../data/arabica_data_cleaned.csv")
vars14 <- c("Aroma","Flavor","Aftertaste","Acidity","Body","Balance","Uniformity","Clean.Cup","Sweetness","Cupper.Points","Moisture","Category.One.Defects","Category.Two.Defects","altitude_mean_meters")
b <- d[!is.na(d$altitude_mean_meters) & d$altitude_mean_meters > 0 & d$altitude_mean_meters <= 3000, ]
b <- b[complete.cases(b[, vars14]), ]
meta <- b[, c("Processing.Method", "Color")]
X8 <- b[, c("Aroma","Flavor","Aftertaste","Acidity","Body","Balance","Cupper.Points","altitude_mean_meters")]
names(X8) <- c("Aroma","Sabor","Retrogusto","Acidez","Cuerpo","Balance","Puntaje.Catador","Altitud")
base <- readRDS("base_1070.rds")
T1070 <- base$trans
lim <- qchisq(0.975, 8)
pre <- prcomp(T1070, center = TRUE, scale. = TRUE)
out1 <- rowSums((pre$x / pre$sdev)^2) > lim
M <- T1070[!out1, ]
Zm <- scale(M)
out2 <- mahalanobis(Zm, colMeans(Zm), cov(Zm)) > lim
keep_idx <- which(!out1)[!out2]
F627 <- T1070[keep_idx, ]
meta627 <- meta[keep_idx, ]
raw627 <- X8[keep_idx, ]
add("n inicial 1070 = ", nrow(X8), "; atipicos 1a pasada = ", sum(out1), "; 2a pasada = ", sum(out2), "; n final = ", nrow(F627))
add("Verificacion contra datos_final_627.rds: ", nrow(readRDS("datos_final_627.rds")$datos_limpio) == nrow(F627))

# ---- 2. Simetría y diagrama de cajas (clásico vs ajustado) ----
mc <- sapply(X8, function(x) mc(x))
sk <- sapply(X8, function(x) mean((x - mean(x))^3) / sd(x)^3)
# Regla literal de la recomendación: si la variable es simétrica (|MC| <= 0.1) se usa
# boxplot robusto (mediana y MAD); si es asimétrica, boxplot ajustado (Hubert-Vandervieren).
tipo <- ifelse(abs(mc) > 0.1, "ajustado (asimetrico)", "robusto MAD (simetrico)")
n_cl <- sapply(X8, function(x) length(boxplot.stats(x)$out))
n_mad <- sapply(X8, function(x) sum(abs(x - median(x)) > 3 * 1.4826 * mad(x)))
n_ad <- sapply(X8, function(x) sum(x < adjboxStats(x)$stats[1] | x > adjboxStats(x)$stats[5]))
n_usado <- ifelse(abs(mc) > 0.1, n_ad, n_mad)
tab_sim <- data.frame(variable = names(X8), medcouple = round(mc, 3), asimetria = round(sk, 3),
                      boxplot = tipo, atipicos_clasico = n_cl, atipicos_robusto_usado = n_usado)
write.csv(tab_sim, "figuras_revision_profesor/tabla_simetria_boxplot.csv", row.names = FALSE)
add("\n== Simetria (medcouple) y tipo de diagrama de cajas ==")
add(paste(capture.output(print(tab_sim, row.names = FALSE)), collapse = "\n"))

png("figuras_revision_profesor/boxplot_clasico_vs_ajustado.png", width = 2000, height = 1100, res = 180)
par(mfrow = c(2, 4), mar = c(4, 4, 3, 1))
for (v in names(X8)) {
  x <- X8[[v]]
  boxplot(x, main = paste0(v, " (MC=", round(mc[v], 2), ")"), col = if (abs(mc[v]) > 0.1) "#f5cba7" else "#aed6f1", outcol = "#c0392b")
  if (abs(mc[v]) > 0.1) {
    st <- adjboxStats(x)$stats
  } else {
    st <- median(x) + c(-3, 3) * 1.4826 * mad(x)
  }
  abline(h = st[c(1, length(st))], lty = 3, col = "#117a65")
}
dev.off()

# ---- 3. Justificación de Yeo-Johnson ----
add("\n== Yeo-Johnson: solo variables con |asimetria| > 1 (lambdas de base_1070) ==")
add("Variables transformadas: ", paste(names(base$lambdas), collapse = ", "))
add("Lambdas: ", paste(round(base$lambdas, 3), collapse = ", "))
skew_627_raw <- sapply(raw627, function(x) mean((x - mean(x))^3) / sd(x)^3)
skew_627_trans <- sapply(F627, function(x) mean((x - mean(x))^3) / sd(x)^3)
add("Asimetria antes (raw, 627): ", paste(names(skew_627_raw), round(skew_627_raw, 2), collapse = " | "))
add("Asimetria despues (transformada, 627): ", paste(names(skew_627_trans), round(skew_627_trans, 2), collapse = " | "))

# ---- 4. Supuestos del PCA ----
Zf <- scale(F627, center = TRUE, scale = TRUE)
add("\n== Supuestos del PCA (627 lotes) ==")
add("prcomp centra internamente (center = TRUE); Altitud tiene media ~", round(mean(F627[, 8])), " m antes de centrar")
md627 <- mahalanobis(Zf, colMeans(Zf), cov(Zf))
add("Atipicos multivariados restantes (d2 > chi2 0.975, 8 g.l.): ", sum(md627 > lim), " de ", nrow(Zf), " (esperados por azar ~", round(0.025 * nrow(Zf)), ")")

# ---- 5. PCA final, codo con IC bootstrap ----
pca <- prcomp(F627, center = TRUE, scale. = TRUE)
prop <- pca$sdev^2 / sum(pca$sdev^2)
B <- 2000
boot_prop <- matrix(NA, B, 8)
for (i in seq_len(B)) {
  idx <- sample(nrow(F627), replace = TRUE)
  s <- prcomp(F627[idx, ], center = TRUE, scale. = TRUE)$sdev^2
  boot_prop[i, ] <- s / sum(s)
}
ci <- t(apply(boot_prop, 2, quantile, c(0.025, 0.975)))
tab_var <- data.frame(componente = paste0("CP", 1:8), varianza = round(prop * 100, 1),
                      ic_inf = round(ci[, 1] * 100, 1), ic_sup = round(ci[, 2] * 100, 1))
tab_var$acum_CP1_CP2 <- round(sum(prop[1:2]) * 100, 1)
write.csv(tab_var, "figuras_revision_profesor/tabla_varianza_IC.csv", row.names = FALSE)
add("\n== Varianza por componente con IC 95 % (bootstrap B = 2000) ==")
add(paste(capture.output(print(tab_var, row.names = FALSE)), collapse = "\n"))
add("IC acumulado CP1+CP2: ", paste(round(quantile(rowSums(boot_prop[, 1:2]), c(0.025, 0.975)) * 100, 1), collapse = " a "), " %")

png("figuras_revision_profesor/codo_IC.png", width = 1800, height = 1100, res = 180)
bp <- barplot(prop[1:6] * 100, names.arg = paste0("CP", 1:6), col = "#1f4e79", ylim = c(0, 65), ylab = "Varianza explicada (%)", main = "Codo con IC 95 % (bootstrap)")
arrows(bp, ci[1:6, 1] * 100, bp, ci[1:6, 2] * 100, angle = 90, code = 3, length = 0.05, col = "#c0392b")
text(bp, prop[1:6] * 100 + 3, paste0(round(prop[1:6] * 100, 1), "%"))
dev.off()

# ---- 6. Dispersión de scores ANTES de las cargas ----
sc <- data.frame(CP1 = pca$x[, 1], CP2 = pca$x[, 2], CP3 = pca$x[, 3], Proceso = meta627$Processing.Method)
sc$Proceso[is.na(sc$Proceso) | sc$Proceso == ""] <- "Sin dato"
top <- names(sort(table(sc$Proceso), decreasing = TRUE))[1:5]
sc$Proceso[!(sc$Proceso %in% top)] <- "Otro"
p_sc <- ggplot(sc, aes(CP1, CP2, color = Proceso)) + geom_point(alpha = 0.7, size = 1.6) +
  labs(title = "Dispersión de los lotes en CP1 y CP2 (627 lotes)", x = sprintf("CP1 (%.1f %%)", prop[1] * 100), y = sprintf("CP2 (%.1f %%)", prop[2] * 100), color = "Método de proceso") +
  theme_minimal(base_size = 13)
ggsave("figuras_revision_profesor/dispersion_CP1_CP2.png", p_sc, width = 8, height = 6, dpi = 200)

# ---- 7. Cargas de CP1-CP3 y biplot ----
L <- round(pca$rotation[, 1:3], 2)
write.csv(L, "figuras_revision_profesor/cargas_CP1_CP3.csv")
add("\n== Cargas CP1-CP3 ==")
add(paste(capture.output(print(L)), collapse = "\n"))
png("figuras_revision_profesor/biplot.png", width = 1800, height = 1400, res = 180)
biplot(pca, choices = 1:2, cex = c(0.4, 0.9), col = c("grey40", "#c0392b"), xlab = sprintf("CP1 (%.1f %%)", prop[1] * 100), ylab = sprintf("CP2 (%.1f %%)", prop[2] * 100), main = "Biplot (627 lotes)")
dev.off()

# ---- 8. t-SNE y UMAP exploratorios ----
set.seed(2026)
ts <- Rtsne(Zf, perplexity = 30, check_duplicates = FALSE, verbose = FALSE, max_iter = 1000)
dt <- data.frame(X = ts$Y[, 1], Y = ts$Y[, 2], Proceso = sc$Proceso)
ggsave("figuras_revision_profesor/tsne_perp30.png", ggplot(dt, aes(X, Y, color = Proceso)) + geom_point(alpha = 0.7, size = 1.4) +
  labs(title = "t-SNE (perplejidad 30), exploratorio", subtitle = "Ejes no interpretables; no son PC1 ni PC2", x = "Dim 1", y = "Dim 2", color = "Método de proceso") + theme_minimal(base_size = 13),
  width = 8, height = 6, dpi = 200)
set.seed(2026)
um <- umap(Zf, n_neighbors = 15, min_dist = 0.1, n_components = 2)
du <- data.frame(X = um[, 1], Y = um[, 2], Proceso = sc$Proceso)
ggsave("figuras_revision_profesor/umap_vecinos15.png", ggplot(du, aes(X, Y, color = Proceso)) + geom_point(alpha = 0.7, size = 1.4) +
  labs(title = "UMAP (15 vecinos), exploratorio", subtitle = "Ejes no interpretables; la estructura depende de los parámetros", x = "UMAP1", y = "UMAP2", color = "Método de proceso") + theme_minimal(base_size = 13),
  width = 8, height = 6, dpi = 200)
add("\nt-SNE: perplejidad 30, semilla 2026. UMAP: 15 vecinos, min_dist 0.1, semilla 2026. Exploratorios.")

writeLines(out_txt, "resultados_revision_profesor.txt")
cat(out_txt, sep = "\n")
