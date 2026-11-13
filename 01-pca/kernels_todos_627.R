library(kernlab)

set.seed(2026)
obj <- readRDS("datos_final_627.rds")
X <- as.data.frame(scale(obj$datos_limpio))
p <- ncol(X)
dir.create("figuras_kpca_627", showWarnings = FALSE)

configs <- list(
  list(name = "vanilladot", kernel = "vanilladot", kpar = list()),
  list(name = "rbfdot_sigma0.1", kernel = "rbfdot", kpar = list(sigma = 0.1)),
  list(name = "rbfdot_sigma1", kernel = "rbfdot", kpar = list(sigma = 1)),
  list(name = "polydot_grado2", kernel = "polydot", kpar = list(degree = 2, scale = 1, offset = 1)),
  list(name = "polydot_grado3", kernel = "polydot", kpar = list(degree = 3, scale = 1, offset = 1)),
  list(name = "tanhdot", kernel = "tanhdot", kpar = list(scale = 0.1, offset = 1)),
  list(name = "laplacedot_sigma0.1", kernel = "laplacedot", kpar = list(sigma = 0.1)),
  list(name = "besseldot", kernel = "besseldot", kpar = list(sigma = 1, order = 1, degree = 1)),
  list(name = "anovadot", kernel = "anovadot", kpar = list(sigma = 1, degree = 1)),
  list(name = "splinedot", kernel = "splinedot", kpar = list())
)

tabla <- data.frame()
for (cfg in configs) {
  kp <- tryCatch(
    kpca(~., data = X, kernel = cfg$kernel, kpar = cfg$kpar, features = p),
    error = function(e) { message("Falló ", cfg$name, ": ", conditionMessage(e)); NULL }
  )
  if (is.null(kp)) next
  frac <- kp@eig / sum(kp@eig)
  fila <- data.frame(kernel = cfg$name, t(round(frac[1:min(p, length(frac))] * 100, 1)))
  names(fila)[-1] <- paste0("CP", seq_len(ncol(fila) - 1))
  tabla <- rbind(tabla, fila)

  sc <- rotated(kp)
  png(sprintf("figuras_kpca_627/pairs_%s.png", cfg$name), width = 1400, height = 1400, res = 150)
  pairs(sc[, 1:4], pch = 19, cex = 0.4, col = adjustcolor("firebrick", 0.5),
        main = cfg$name)
  dev.off()
}

write.csv(tabla, "varianza_kpca_todos_627.csv", row.names = FALSE)
print(tabla)
