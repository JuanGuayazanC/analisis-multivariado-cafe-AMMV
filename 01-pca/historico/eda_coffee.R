# EDA — Coffee Quality Institute
# Exploración inicial de las 14 variables cuantitativas
# Complemento visual al informe del taller (informe_taller_pca.Rmd)

library(dplyr)
library(ggplot2)
library(tidyr)

# ── Datos ────────────────────────────────────────────────────────────────────

data <- read.csv("../data/arabica_data_cleaned.csv")

vars_cuantitativas <- c("Aroma", "Flavor", "Aftertaste", "Acidity", "Body",
                        "Balance", "Uniformity", "Clean.Cup", "Sweetness",
                        "Cupper.Points", "Moisture", "Category.One.Defects",
                        "Category.Two.Defects", "altitude_mean_meters")

data_f <- data %>%
  filter(is.na(altitude_mean_meters) |
           (altitude_mean_meters > 0 & altitude_mean_meters <= 3000)) %>%
  filter(!is.na(altitude_mean_meters))

datos <- data_f %>% select(all_of(vars_cuantitativas))

# ── 1. Diagrama de cajas — todas las variables en escala original ─────────────
# Muestra diferencias de escala: altitude_mean_meters domina el rango.

datos_long <- datos %>%
  pivot_longer(everything(), names_to = "variable", values_to = "valor")

ggplot(datos_long, aes(x = reorder(variable, valor, FUN = median), y = valor)) +
  geom_boxplot(fill = "steelblue", alpha = 0.6, outlier.size = 0.8,
               outlier.alpha = 0.5) +
  coord_flip() +
  labs(title = "Diagrama de cajas — variables en escala original",
       x = NULL, y = "Valor") +
  theme_minimal(base_size = 13)

# ── 2. Diagrama de cajas — variables estandarizadas ──────────────────────────
# Permite comparar dispersión entre variables en la misma escala (z-scores).
# Outliers visibles en todas las variables a la vez.

datos_z <- as.data.frame(scale(datos))

datos_z_long <- datos_z %>%
  pivot_longer(everything(), names_to = "variable", values_to = "z")

ggplot(datos_z_long, aes(x = reorder(variable, z, FUN = median), y = z)) +
  geom_boxplot(fill = "darkorange", alpha = 0.6, outlier.size = 0.8,
               outlier.alpha = 0.5) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  coord_flip() +
  labs(title = "Diagrama de cajas — variables estandarizadas (z-scores)",
       x = NULL, y = "z-score") +
  theme_minimal(base_size = 13)

# ── 3. Cajas solo para los puntajes sensoriales ───────────────────────────────
# Revela la asimetría izquierda: la mayoría de lotes puntúa alto (7–8.5),
# con unos pocos outliers bajos — en particular el lote con todo en cero.

vars_sensoriales <- c("Aroma", "Flavor", "Aftertaste", "Acidity", "Body",
                      "Balance", "Uniformity", "Clean.Cup", "Sweetness",
                      "Cupper.Points")

datos %>%
  select(all_of(vars_sensoriales)) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "puntaje") %>%
  ggplot(aes(x = reorder(variable, puntaje, FUN = median), y = puntaje)) +
  geom_boxplot(fill = "seagreen", alpha = 0.6, outlier.size = 1,
               outlier.alpha = 0.5) +
  coord_flip() +
  labs(title = "Puntajes sensoriales — distribución por variable",
       x = NULL, y = "Puntaje (0–10)") +
  theme_minimal(base_size = 13)

# ── 4. Cajas para variables físicas ───────────────────────────────────────────
# Moisture, defectos y altitud: escalas completamente distintas entre sí.

vars_fisicas <- c("Moisture", "Category.One.Defects",
                  "Category.Two.Defects", "altitude_mean_meters")

datos %>%
  select(all_of(vars_fisicas)) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "valor") %>%
  ggplot(aes(x = variable, y = valor)) +
  geom_boxplot(fill = "mediumpurple", alpha = 0.6, outlier.size = 1,
               outlier.alpha = 0.5) +
  facet_wrap(~variable, scales = "free") +
  labs(title = "Variables físicas — distribución individual",
       x = NULL, y = "Valor") +
  theme_minimal(base_size = 13)

# ── 5. Cajas ajustadas (robustas a asimetría) vs. clásicas ────────────────────
# La regla clásica de Tukey (1.5*RIC a ambos lados) sobre-marca atípicos en
# variables sesgadas. adjbox() (Hubert & Vandervieren) ajusta los bigotes con el
# medcouple: Moisture pasa de 222 a 114 atípicos y Category.Two.Defects de 77 a 20.

library(robustbase)

par(mfrow = c(1, 2))
adjbox(datos$Moisture, main = "Moisture (caja ajustada)", col = "lightblue")
boxplot(datos$Moisture, main = "Moisture (caja clásica)", col = "lightpink")
adjbox(datos$Category.Two.Defects, main = "Category.Two.Defects (ajustada)", col = "lightblue")
boxplot(datos$Category.Two.Defects, main = "Category.Two.Defects (clásica)", col = "lightpink")
par(mfrow = c(1, 1))
