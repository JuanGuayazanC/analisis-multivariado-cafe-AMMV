library(shiny)
library(dplyr)
library(ggplot2)
library(car)

# ── Preprocesamiento (corre una sola vez al iniciar la app) ──────────────────

data_raw <- read.csv("../data/arabica_data_cleaned.csv")

vars_cuantitativas <- c("Aroma", "Flavor", "Aftertaste", "Acidity", "Body",
                        "Balance", "Uniformity", "Clean.Cup", "Sweetness",
                        "Cupper.Points", "Moisture", "Category.One.Defects",
                        "Category.Two.Defects", "altitude_mean_meters")

datos_full <- data_raw %>%
  filter(!is.na(altitude_mean_meters),
         altitude_mean_meters > 0,
         altitude_mean_meters <= 3000) %>%
  select(all_of(vars_cuantitativas))
datos_full <- datos_full[complete.cases(datos_full), ]

# Transformación Yeo-Johnson solo a Category.Two.Defects (misma decisión del informe)
yj_transform <- function(x, lambda) {
  if (lambda != 0) ((x + 1)^lambda - 1) / lambda else log(x + 1)
}
lambda_cat2 <- -0.217
datos_full$Category.Two.Defects <- yj_transform(datos_full$Category.Two.Defects, lambda_cat2)

# Conjunto de 11 variables del análisis principal
vars_11 <- setdiff(names(datos_full),
                   c("Category.One.Defects", "Category.Two.Defects", "Moisture"))
datos_t <- datos_full[, vars_11]

# YJ a las 11 variables con lambda óptimo individual
# Se clampea lambda al rango [-3, 3] para evitar transformaciones inestables
# en variables con distribución muy concentrada (ej. Uniformity, Sweetness)
pt_11  <- powerTransform(datos_t, family = "yjPower")
lambdas_11 <- pmax(pmin(coef(pt_11, round = FALSE), 3), -3)
datos_t_yj <- datos_t
for (v in names(datos_t)) {
  datos_t_yj[[v]] <- yjPower(datos_t[[v]], lambdas_11[v])
}
datos_t <- datos_t_yj

# PCA principal
pca <- prcomp(datos_t, center = TRUE, scale. = TRUE)

scores_df <- as.data.frame(pca$x)
var_exp   <- round(pca$sdev^2 / sum(pca$sdev^2) * 100, 1)

# Rangos observados para los sliders (variables SIN transformar, escala original)
rangos <- lapply(vars_11, function(v) {
  x <- datos_full[[v]]   # ya tiene YJ aplicado a cat2 pero las 11 vars están sin YJ aquí
  list(min = floor(min(x) * 10) / 10,
       max = ceiling(max(x) * 10) / 10,
       val = round(median(x), 1))
})
names(rangos) <- vars_11

# Nombres legibles para mostrar en la UI
nombres_ui <- c(
  Aroma            = "Aroma",
  Flavor           = "Flavor (sabor)",
  Aftertaste       = "Aftertaste (retrogusto)",
  Acidity          = "Acidity (acidez)",
  Body             = "Body (cuerpo)",
  Balance          = "Balance",
  Uniformity       = "Uniformity (uniformidad)",
  Clean.Cup        = "Clean Cup (limpieza)",
  Sweetness        = "Sweetness (dulzura)",
  Cupper.Points    = "Cupper Points",
  altitude_mean_meters = "Altitud media (metros)"
)

# ── UI ───────────────────────────────────────────────────────────────────────

ui <- fluidPage(
  tags$head(tags$style(HTML("
    body { font-family: 'Helvetica Neue', Arial, sans-serif; background: #f8f9fa; }
    .sidebar-title { font-size: 13px; font-weight: 600; color: #061d3d;
                     text-transform: uppercase; letter-spacing: 0.5px;
                     margin-bottom: 12px; }
    .well { background: #ffffff; border: 1px solid #dee2e6; border-radius: 8px; }
    .btn-primary { background-color: #061d3d; border-color: #061d3d;
                   width: 100%; margin-top: 8px; }
    .btn-primary:hover { background-color: #1a3a6b; border-color: #1a3a6b; }
    .score-box { background: #ffffff; border-radius: 8px; padding: 14px 18px;
                 border: 1px solid #dee2e6; margin-bottom: 12px; }
    .score-box h5 { margin: 0 0 8px 0; color: #061d3d; font-size: 13px;
                    font-weight: 600; text-transform: uppercase; }
    .interp-text { font-size: 14px; color: #333; line-height: 1.6; }
    h4.panel-title { color: #061d3d; font-weight: 700; }
  "))),

  titlePanel(
    div(
      h3("Explorador PCA — Calidad de Café Arábica",
         style = "color:#061d3d; font-weight:700; margin-bottom:2px;"),
      p(paste0("1.070 lotes · 11 variables · PC1 explica ", var_exp[1],
               " % de la varianza"),
        style = "color:#666; font-size:13px; margin-top:0;")
    )
  ),

  sidebarLayout(
    sidebarPanel(
      width = 3,
      div(class = "sidebar-title", "Nuevo lote de café"),
      p("Ajusta los puntajes del lote a proyectar:",
        style = "font-size:12px; color:#666; margin-bottom:10px;"),

      lapply(vars_11, function(v) {
        r <- rangos[[v]]
        step <- if (v == "altitude_mean_meters") 10 else 0.1
        sliderInput(
          inputId = v,
          label   = nombres_ui[[v]],
          min     = r$min,
          max     = r$max,
          value   = r$val,
          step    = step
        )
      }),

      actionButton("proyectar", "Proyectar este lote", class = "btn-primary"),
      actionButton("reset", "Restablecer valores", class = "btn btn-default",
                   style = "width:100%; margin-top:6px;")
    ),

    mainPanel(
      width = 9,
      fluidRow(
        column(8,
          div(class = "score-box",
            h4(class = "panel-title",
               textOutput("titulo_plot", inline = TRUE)),
            plotOutput("biplot", height = "420px"),
            div(style = "margin-top:6px;",
              radioButtons("ejes", NULL,
                choices = c("PC1 vs PC2 — Calidad sensorial / Consistencia" = "12",
                            "PC1 vs PC3 — Calidad sensorial / Altitud"      = "13"),
                selected = "12", inline = TRUE))
          )
        ),
        column(4,
          div(class = "score-box",
            h5("Scores del nuevo lote"),
            uiOutput("scores_ui")
          ),
          div(class = "score-box",
            h5("Interpretación"),
            uiOutput("interpretacion_ui")
          )
        )
      )
    )
  )
)

# ── Server ───────────────────────────────────────────────────────────────────

server <- function(input, output, session) {

  # Botón reset: devuelve sliders a la mediana
  observeEvent(input$reset, {
    for (v in vars_11) {
      updateSliderInput(session, v, value = rangos[[v]]$val)
    }
  })

  # Proyección del nuevo lote
  nuevo_score <- eventReactive(input$proyectar, {
    nuevo_raw <- setNames(
      lapply(vars_11, function(v) input[[v]]),
      vars_11
    )
    nuevo_df <- as.data.frame(nuevo_raw)

    # Aplicar YJ con los mismos lambdas del modelo
    for (v in names(nuevo_df)) {
      nuevo_df[[v]] <- yjPower(nuevo_df[[v]], lambdas_11[v])
    }

    # Proyectar: centrar y escalar con los parámetros del PCA original
    nuevo_scaled <- scale(nuevo_df,
                          center = pca$center,
                          scale  = pca$scale)
    scores <- as.numeric(nuevo_scaled %*% pca$rotation)
    names(scores) <- paste0("PC", seq_along(scores))
    scores
  }, ignoreNULL = TRUE)

  # Ejes seleccionados
  ejes_sel <- reactive({
    as.integer(strsplit(input$ejes, "")[[1]])
  })

  # Título dinámico
  output$titulo_plot <- renderText({
    e <- ejes_sel()
    paste0("Plano PC", e[1], "–PC", e[2])
  })

  # Biplot
  output$biplot <- renderPlot({
    e  <- ejes_sel()
    cx <- paste0("PC", e[1])
    cy <- paste0("PC", e[2])

    p <- ggplot(scores_df, aes_string(x = cx, y = cy)) +
      geom_point(alpha = 0.25, color = "#1a6fa8", size = 1.2) +
      geom_hline(yintercept = 0, linetype = "dashed", color = "#aaa", linewidth = 0.4) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "#aaa", linewidth = 0.4) +
      labs(
        x = paste0(cx, " (", var_exp[e[1]], " %)"),
        y = paste0(cy, " (", var_exp[e[2]], " %)")
      ) +
      theme_minimal(base_size = 13) +
      theme(
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(color = "#eeeeee"),
        axis.title       = element_text(color = "#333"),
        plot.background  = element_rect(fill = "white", color = NA)
      )

    ns <- nuevo_score()
    if (!is.null(ns)) {
      nd <- data.frame(x = ns[e[1]], y = ns[e[2]])
      names(nd) <- c(cx, cy)
      p <- p +
        geom_point(data = nd, aes_string(x = cx, y = cy),
                   color = "#e74c3c", size = 5, shape = 17) +
        geom_point(data = nd, aes_string(x = cx, y = cy),
                   color = "#e74c3c", size = 10, shape = 17, alpha = 0.25)
    }
    p
  })

  # Scores numéricos
  output$scores_ui <- renderUI({
    ns <- nuevo_score()
    if (is.null(ns)) {
      return(p("Ajusta los sliders y presiona «Proyectar».",
               style = "color:#999; font-size:13px;"))
    }
    tags$table(
      style = "width:100%; font-size:13px;",
      tags$thead(
        tags$tr(
          tags$th("Componente", style = "text-align:left; color:#666; font-weight:600;"),
          tags$th("Score",      style = "text-align:right; color:#666; font-weight:600;"),
          tags$th("Var. %",     style = "text-align:right; color:#666; font-weight:600;")
        )
      ),
      tags$tbody(
        lapply(1:4, function(k) {
          tags$tr(
            tags$td(paste0("PC", k)),
            tags$td(style = "text-align:right; font-weight:600;",
                    sprintf("%+.2f", ns[k])),
            tags$td(style = "text-align:right; color:#888;",
                    paste0(var_exp[k], " %"))
          )
        })
      )
    )
  })

  # Interpretación
  output$interpretacion_ui <- renderUI({
    ns <- nuevo_score()
    if (is.null(ns)) return(NULL)

    # Percentil de cada score dentro de la distribución histórica
    pct_pc1 <- mean(scores_df$PC1 <= ns[1]) * 100
    pct_pc2 <- mean(scores_df$PC2 <= ns[2]) * 100
    pct_pc3 <- mean(scores_df$PC3 <= ns[3]) * 100

    # PC1: score negativo = alta calidad (las cargas son negativas para calidad alta)
    cal_label <- if (pct_pc1 < 25) "alta calidad sensorial"
                 else if (pct_pc1 < 60) "calidad sensorial media"
                 else "baja calidad sensorial"

    # PC2: positivo = más consistencia/dulzura; negativo = más intensidad
    pc2_label <- if (ns[2] > 0.5) "alta consistencia y dulzura"
                 else if (ns[2] < -0.5) "alta intensidad sensorial"
                 else "balance entre consistencia e intensidad"

    # PC3: altitud
    alt_label <- if (ns[3] > 0.5) "altitud de producción relativamente alta"
                 else if (ns[3] < -0.5) "altitud de producción relativamente baja"
                 else "altitud de producción típica"

    div(class = "interp-text",
      tags$ul(style = "padding-left:16px; margin:0;",
        tags$li(strong("PC1: "), cal_label,
                sprintf(" (percentil %.0f)", pct_pc1)),
        tags$li(strong("PC2: "), pc2_label),
        tags$li(strong("PC3: "), alt_label)
      )
    )
  })
}

shinyApp(ui, server)
