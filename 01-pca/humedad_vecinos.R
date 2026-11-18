d <- read.csv("../data/arabica_data_cleaned.csv")
vars14 <- c("Aroma","Flavor","Aftertaste","Acidity","Body","Balance","Uniformity","Clean.Cup","Sweetness","Cupper.Points","Moisture","Category.One.Defects","Category.Two.Defects","altitude_mean_meters")
b <- d[!is.na(d$altitude_mean_meters) & d$altitude_mean_meters > 0 & d$altitude_mean_meters <= 3000, ]
b <- b[complete.cases(b[, vars14]), ]
z0 <- b$Moisture == 0
cat("Humedad=0 en base:", sum(z0), "de", nrow(b), "=", round(mean(z0) * 100, 1), "%\n")
for (base in c("base_1070.rds", "base_sin_atipicos.rds")) {
  obj <- readRDS(base); X <- as.matrix(obj$Z)
  # rows of the base correspond to b (1070) or b[keep] (sin atipicos): use names via matching on the 8 raw columns
  if (base == "base_1070.rds") idx <- seq_len(nrow(b)) else {
    md <- mahalanobis(X, colMeans(X), cov(X)); idx <- which(md <= qchisq(0.975, 8)) }
  zz <- z0[idx]
  D <- as.matrix(dist(X))
  diag(D) <- Inf
  nb <- t(apply(D, 1, function(r) order(r)[1:15]))
  frac <- sapply(which(zz), function(i) mean(zz[nb[i, ]]))
  cat(base, ": lotes con Humedad=0:", sum(zz), " vecinos (k=15) con Humedad=0 en promedio:", round(mean(frac) * 100, 1), "%  base:", round(mean(zz) * 100, 1), "%\n")
}
