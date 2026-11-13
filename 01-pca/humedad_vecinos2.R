d <- read.csv("../data/arabica_data_cleaned.csv")
vars14 <- c("Aroma","Flavor","Aftertaste","Acidity","Body","Balance","Uniformity","Clean.Cup","Sweetness","Cupper.Points","Moisture","Category.One.Defects","Category.Two.Defects","altitude_mean_meters")
b <- d[!is.na(d$altitude_mean_meters) & d$altitude_mean_meters > 0 & d$altitude_mean_meters <= 3000, ]
b <- b[complete.cases(b[, vars14]), ]
z0 <- b$Moisture == 0
X1 <- as.matrix(readRDS("base_1070.rds")$Z)
md1 <- mahalanobis(X1, colMeans(X1), cov(X1)); keep <- md1 <= qchisq(0.975, 8)
Xs <- as.matrix(readRDS("base_sin_atipicos.rds")$Z)
stats <- function(X, zz) {
  D <- as.matrix(dist(X)); diag(D) <- Inf
  nb <- t(apply(D, 1, function(r) order(r)[1:15]))
  fr <- sapply(which(zz), function(i) mean(zz[nb[i, ]]))
  c(n = nrow(X), zeros = sum(zz), vecinos_pct = round(mean(fr) * 100, 1), base_pct = round(mean(zz) * 100, 1))
}
print(stats(X1, z0))
print(stats(Xs, z0[keep]))
