library(dplyr)
library(car)
library(robustbase)

dir.create("figuras_presentacion", showWarnings = FALSE)
out <- function(n) file.path("figuras_presentacion", n)

data <- read.csv("../data/arabica_data_cleaned.csv")
vars14 <- c("Aroma", "Flavor", "Aftertaste", "Acidity", "Body", "Balance",
            "Uniformity", "Clean.Cup", "Sweetness", "Cupper.Points",
            "Moisture", "Category.One.Defects", "Category.Two.Defects",
            "altitude_mean_meters")
data_f <- data %>%
  filter(is.na(altitude_mean_meters) | (altitude_mean_meters > 0 & altitude_mean_meters <= 3000)) %>%
  filter(!is.na(altitude_mean_meters))
datos14 <- data_f %>% select(all_of(vars14))

obj <- readRDS("../datos/datos_final_666.rds")
datos666 <- obj$datos_limpio
vars8 <- names(datos666)

# 1. Cajas ajustadas por medcouple (14 variables originales)
png(out("01_cajas_ajustadas_14.png"), width = as.integer(1800*1.6), height = as.integer(1200*1.6), res = 220)
par(mfrow = c(4, 4), mar = c(3, 3, 3, 1))
for (v in names(datos14)) {
  adjbox(datos14[[v]][!is.na(datos14[[v]])], main = v, col = "#f2d7a8", pch = 1, cex = 0.5)
}
plot.new()
text(0.5, 0.5, "Cajas ajustadas por medcouple\n(una escala por variable,\n1.070 lotes)", cex = 1.2)
dev.off()

# 2. Inflación de ceros y máximos
png(out("02_ceros_y_maximos.png"), width = as.integer(1500*1.6), height = as.integer(700*1.6), res = 220)
par(mfrow = c(1, 2), mar = c(4, 4, 3, 1))
hist(datos14$Moisture, breaks = 40, col = "#c9a27a", main = "Humedad: 174 lotes con valor 0",
     xlab = "Moisture (%)")
barplot(c(Sweetness = mean(datos14$Sweetness == 10), Uniformity = mean(datos14$Uniformity == 10),
          Clean.Cup = mean(datos14$Clean.Cup == 10)) * 100, col = "#8fb8a8", ylim = c(0, 100),
        ylab = "% de lotes con valor 10", main = "Inflación de máximos")
dev.off()

# 3. Asimetría antes y después de Yeo-Johnson (8 variables)
skew <- function(x) mean((x - mean(x))^3) / sd(x)^3
datos8_pre <- datos14[, vars8]
sk_pre <- sapply(datos8_pre, skew)
png(out("03_asimetria_antes_despues_YJ.png"), width = as.integer(1600*1.6), height = as.integer(800*1.6), res = 220)
par(mfrow = c(1, 2), mar = c(8, 4, 3, 1))
barplot(sk_pre, las = 2, col = ifelse(abs(sk_pre) > 1, "firebrick", "steelblue"),
        main = "Asimetría antes de Yeo-Johnson", ylab = "Asimetría")
abline(h = c(-1, 1), lty = 2)
sk_post <- sapply(datos666, skew)
barplot(sk_post, las = 2, col = "steelblue", main = "Asimetría en la matriz final (666 lotes)",
        ylab = "Asimetría")
abline(h = c(-1, 1), lty = 2)
dev.off()

# 4. Varianzas y covarianzas (matriz final)
S <- cov(datos666)
png(out("04_varianzas_covarianzas.png"), width = as.integer(1500*1.6), height = as.integer(1000*1.6), res = 220)
par(mfrow = c(1, 2), mar = c(8, 8, 3, 1))
image(1:8, 1:8, t(S[8:1, ]), col = hcl.colors(30, "Blue-Red 3"), axes = FALSE,
      main = "Matriz de covarianzas S (666 lotes, 8 variables)", xlab = "", ylab = "")
axis(1, 1:8, colnames(S), las = 2); axis(2, 1:8, rev(colnames(S)), las = 2)
R <- cor(datos666)
image(1:8, 1:8, t(R[8:1, ]), col = hcl.colors(30, "Blue-Red 3"), axes = FALSE, zlim = c(-1, 1),
      main = "Matriz de correlaciones R", xlab = "", ylab = "")
axis(1, 1:8, colnames(R), las = 2); axis(2, 1:8, rev(colnames(R)), las = 2)
dev.off()

png(out("05_varianza_por_variable.png"), width = as.integer(1400*1.6), height = as.integer(800*1.6), res = 220)
par(mar = c(8, 5, 3, 1))
barplot(diag(S), las = 2, col = "#8fb8a8", log = "y",
        main = "Varianza de cada variable (escala log): la altitud domina",
        ylab = "Varianza (log)")
dev.off()

# 5. Mahalanobis (PCA exploratorio sobre datos transformados, 1.070 lotes)
datos_t <- datos8_pre
for (v in names(obj$lambdas)) datos_t[[v]] <- car::yjPower(datos_t[[v]], obj$lambdas[v])
pca_p <- prcomp(datos_t, center = TRUE, scale. = TRUE)
dm2 <- rowSums((pca_p$x / pca_p$sdev)^2)
umbral <- qchisq(0.975, df = ncol(datos_t))
atip <- dm2 > umbral
png(out("06_mahalanobis.png"), width = as.integer(1600*1.6), height = as.integer(800*1.6), res = 220)
par(mfrow = c(1, 2), mar = c(4, 4, 3, 1))
hist(log10(dm2), breaks = 60, col = "#c9d9e8", main = "Distancias de Mahalanobis (log10 d²M)",
     xlab = "log10(d²M)")
abline(v = log10(umbral), col = "firebrick", lwd = 2)
plot(pca_p$x[, 1], pca_p$x[, 2], pch = 19, cex = 0.5,
     col = ifelse(atip, "firebrick", adjustcolor("steelblue", 0.4)),
     xlab = "PC1", ylab = "PC2", main = "PC1 vs PC2: atípicos en rojo")
dev.off()
cat("Atípicos:", sum(atip), "\n")
