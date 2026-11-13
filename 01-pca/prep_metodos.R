# Preprocesamiento común para todos los métodos.
# Base: 1.070 lotes con filtro original. Yeo-Johnson selectivo (|asimetría|>1) y estandarización,
# λ estimados sobre la base de cada análisis. Versión "sin atípicos": Mahalanobis sobre la propia
# matriz transformada y estandarizada; se re-estiman λ y estandarización sobre el subconjunto.
suppressMessages(library(car))
d <- read.csv("../data/arabica_data_cleaned.csv")
vars14 <- c("Aroma","Flavor","Aftertaste","Acidity","Body","Balance","Uniformity","Clean.Cup","Sweetness","Cupper.Points","Moisture","Category.One.Defects","Category.Two.Defects","altitude_mean_meters")
b <- d[!is.na(d$altitude_mean_meters) & d$altitude_mean_meters > 0 & d$altitude_mean_meters <= 3000, ]
b <- b[complete.cases(b[, vars14]), ]
X8 <- b[, c("Aroma","Flavor","Aftertaste","Acidity","Body","Balance","Cupper.Points","altitude_mean_meters")]
names(X8) <- c("Aroma","Sabor","Retrogusto","Acidez","Cuerpo","Balance","Puntaje.Catador","Altitud")

preprocess <- function(R) {
  sk <- sapply(R, function(x) mean((x - mean(x))^3) / sd(x)^3)
  yj <- names(sk)[abs(sk) > 1]
  T <- R
  lam <- NULL
  if (length(yj) > 0) {
    lam <- coef(powerTransform(R[, yj, drop = FALSE], family = "yjPower"), round = FALSE)
    for (v in yj) T[[v]] <- yjPower(R[[v]], lam[v])
  }
  list(raw = R, trans = T, Z = as.data.frame(scale(T)), yj = yj, lambdas = lam, skew = sk)
}

p1070 <- preprocess(X8)
md <- mahalanobis(p1070$Z, colMeans(p1070$Z), cov(p1070$Z))
keep <- md <= qchisq(0.975, 8)
psin <- preprocess(X8[keep, ])

saveRDS(p1070, "base_1070.rds")
saveRDS(psin, "base_sin_atipicos.rds")
cat("1070:", nrow(p1070$Z), " YJ:", p1070$yj, "\n")
cat("sin atipicos:", nrow(psin$Z), " eliminados:", sum(!keep), " YJ:", psin$yj, "\n")
