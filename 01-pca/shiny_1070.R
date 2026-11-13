b <- readRDS("base_1070.rds")
en <- c(Sabor = "Flavor", Retrogusto = "Aftertaste", Acidez = "Acidity", Cuerpo = "Body", Puntaje.Catador = "Cupper.Points", Altitud = "altitude_mean_meters")
ren <- function(df) { n <- names(df); n <- ifelse(n %in% names(en), en[n], n); names(df) <- n; df }
t <- ren(b$trans); r <- ren(b$raw)
lam <- b$lambdas; names(lam) <- ifelse(names(lam) %in% names(en), en[names(lam)], names(lam))
yj <- ifelse(b$yj %in% names(en), en[b$yj], b$yj)
out <- list(datos_limpio = t, datos_originales = r, lambdas = lam, vars_transformar = yj)
saveRDS(out, "datos_final_1070.rds")
cat("cols:", names(t), "\nlambdas:", names(lam), "\n")
