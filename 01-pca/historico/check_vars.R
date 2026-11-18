library(dplyr)
data <- read.csv("../data/arabica_data_cleaned.csv")
vars_cuant <- c("Aroma","Flavor","Aftertaste","Acidity","Body","Balance",
                "Uniformity","Clean.Cup","Sweetness","Cupper.Points","Moisture",
                "Category.One.Defects","Category.Two.Defects","altitude_mean_meters")
data_f <- data %>%
  filter(!is.na(altitude_mean_meters), altitude_mean_meters > 0, altitude_mean_meters <= 3000)
datos <- data_f %>% select(all_of(vars_cuant))

vars_11 <- c("Aroma","Flavor","Aftertaste","Acidity","Body","Balance",
             "Uniformity","Clean.Cup","Sweetness","Cupper.Points","altitude_mean_meters")
datos_t <- datos[, vars_11]

cat("=== Fraccion con valor == 10 ===\n")
frac10 <- sapply(datos_t, function(x) mean(x == 10))
print(round(frac10, 3))

skew <- function(x) mean((x - mean(x))^3) / sd(x)^3
cat("\n=== Skewness de las 11 variables ===\n")
sk <- sapply(datos_t, skew)
print(round(sk, 3))
cat("\nVariables con |skewness| > 1:\n")
print(names(sk[abs(sk) > 1]))

cat("\n=== Tabla Sweetness ===\n"); print(table(datos$Sweetness))
cat("\n=== Tabla Uniformity ===\n"); print(table(datos$Uniformity))
cat("\n=== Tabla Clean.Cup ===\n"); print(table(datos$Clean.Cup))
