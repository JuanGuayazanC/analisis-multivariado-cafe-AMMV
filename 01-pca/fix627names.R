obj <- readRDS("datos_final_627.rds")
en <- c(Sabor = "Flavor", Retrogusto = "Aftertaste", Acidez = "Acidity", Cuerpo = "Body", Puntaje.Catador = "Cupper.Points", Altitud = "altitude_mean_meters")
ren <- function(df) { n <- names(df); n <- ifelse(n %in% names(en), en[n], n); names(df) <- n; df }
out <- list(datos_limpio = ren(obj$datos_limpio), datos_originales = ren(obj$datos_originales),
            lambdas = { l <- obj$lambdas; names(l) <- ifelse(names(l) %in% names(en), en[names(l)], names(l)); l },
            vars_transformar = ifelse(obj$vars_transformar %in% names(en), en[obj$vars_transformar], obj$vars_transformar))
saveRDS(out, "datos_final_627.rds")
cat("cols:", names(out$datos_limpio), "\n")
