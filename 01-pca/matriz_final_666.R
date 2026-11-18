library(dplyr)
library(car)

data <- read.csv("../data/arabica_data_cleaned.csv")

vars_cuantitativas <- c("Aroma", "Flavor", "Aftertaste", "Acidity", "Body", "Balance",
                        "Uniformity", "Clean.Cup", "Sweetness", "Cupper.Points",
                        "Moisture", "Category.One.Defects", "Category.Two.Defects",
                        "altitude_mean_meters")

data_f <- data %>%
  filter(is.na(altitude_mean_meters) | (altitude_mean_meters > 0 & altitude_mean_meters <= 3000)) %>%
  filter(!is.na(altitude_mean_meters))
datos <- data_f %>% select(all_of(vars_cuantitativas))

vars_8 <- setdiff(names(datos),
                  c("Category.One.Defects", "Category.Two.Defects", "Moisture",
                    "Sweetness", "Uniformity", "Clean.Cup"))
datos_t <- datos[, vars_8]

skew <- function(x) mean((x - mean(x))^3) / sd(x)^3
skew_pre <- sapply(datos_t, skew)
vars_transformar <- names(skew_pre[abs(skew_pre) > 1])
if (length(vars_transformar) > 0) {
  pt_sel <- powerTransform(datos_t[, vars_transformar, drop = FALSE], family = "yjPower")
  lambdas_sel <- coef(pt_sel, round = FALSE)
  for (v in vars_transformar) datos_t[[v]] <- yjPower(datos_t[[v]], lambdas_sel[v])
}

pca_prelim <- prcomp(datos_t, center = TRUE, scale. = TRUE)
dm2_prelim <- rowSums((pca_prelim$x / pca_prelim$sdev)^2)
umbral_chi2 <- qchisq(0.975, df = ncol(datos_t))
idx_atipicos <- which(dm2_prelim > umbral_chi2)

datos_limpio <- datos_t[-idx_atipicos, ]

cat("Variables transformadas (YJ):", vars_transformar, "\n")
cat("Lotes retirados:", length(idx_atipicos), "de", nrow(datos_t), "\n")
cat("Matriz final:", nrow(datos_limpio), "x", ncol(datos_limpio), "\n")

pca_check <- prcomp(datos_limpio, center = TRUE, scale. = TRUE)
print(round(summary(pca_check)$importance[2, 1:3] * 100, 1))

saveRDS(list(datos_limpio = datos_limpio,
             vars_transformar = vars_transformar,
             lambdas = lambdas_sel,
             idx_atipicos = idx_atipicos,
             datos_originales = datos[-idx_atipicos, ]),
        "datos_final_666.rds")
