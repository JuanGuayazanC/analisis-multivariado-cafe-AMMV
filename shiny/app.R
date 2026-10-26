library(shiny)
library(dplyr)
library(ggplot2)
library(car)

# ── Preprocesamiento ──────────────────────────────────────────────────────────

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

yj_transform <- function(x, lambda) {
  if (lambda != 0) ((x + 1)^lambda - 1) / lambda else log(x + 1)
}
datos_full$Category.Two.Defects <- yj_transform(datos_full$Category.Two.Defects, -0.217)

vars_11 <- setdiff(names(datos_full),
                   c("Category.One.Defects", "Category.Two.Defects", "Moisture"))
datos_t <- datos_full[, vars_11]

pt_11      <- powerTransform(datos_t, family = "yjPower")
lambdas_11 <- pmax(pmin(coef(pt_11, round = FALSE), 3), -3)
datos_t_yj <- datos_t
for (v in names(datos_t)) datos_t_yj[[v]] <- yjPower(datos_t[[v]], lambdas_11[v])
datos_t <- datos_t_yj

pca      <- prcomp(datos_t, center = TRUE, scale. = TRUE)
scores_df <- as.data.frame(pca$x)
var_exp   <- round(pca$sdev^2 / sum(pca$sdev^2) * 100, 1)

rangos <- lapply(vars_11, function(v) {
  x <- datos_full[[v]]
  list(min = floor(min(x) * 10) / 10,
       max = ceiling(max(x) * 10) / 10,
       val = round(median(x), 1))
})
names(rangos) <- vars_11

# Grupos de variables para organizar la UI
grupo_intensidad  <- c("Aroma", "Flavor", "Aftertaste", "Acidity", "Body",
                       "Balance", "Cupper.Points")
grupo_consistencia <- c("Uniformity", "Clean.Cup", "Sweetness")
grupo_altitud      <- c("altitude_mean_meters")

descripciones <- c(
  Aroma            = "Intensidad y calidad del aroma",
  Flavor           = "Sabor percibido durante la degustación",
  Aftertaste       = "Persistencia del retrogusto",
  Acidity          = "Viveza y brillo de la acidez",
  Body             = "Sensación de peso en boca",
  Balance          = "Armonía entre todos los atributos",
  Cupper.Points    = "Puntaje holístico del catador",
  Uniformity       = "Consistencia entre las 5 tazas evaluadas",
  Clean.Cup        = "Ausencia de sabores extraños",
  Sweetness        = "Presencia de dulzura natural",
  altitude_mean_meters = "Altura de la finca sobre el nivel del mar"
)

nombres_ui <- c(
  Aroma            = "Aroma",
  Flavor           = "Flavor",
  Aftertaste       = "Aftertaste",
  Acidity          = "Acidity",
  Body             = "Body",
  Balance          = "Balance",
  Cupper.Points    = "Cupper Points",
  Uniformity       = "Uniformity",
  Clean.Cup        = "Clean Cup",
  Sweetness        = "Sweetness",
  altitude_mean_meters = "Altitud (metros)"
)

# ── CSS ───────────────────────────────────────────────────────────────────────

css <- "
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');

* { box-sizing: border-box; }
body {
  font-family: 'Inter', 'Helvetica Neue', Arial, sans-serif;
  background: #f0f2f5;
  color: #1a1a2e;
  font-size: 14px;
}

/* Header */
.app-header {
  background: linear-gradient(135deg, #0d2137 0%, #1a4a7a 100%);
  color: white;
  padding: 20px 28px 16px;
  margin: -15px -15px 20px -15px;
  border-radius: 0 0 12px 12px;
}
.app-header h2 { margin: 0 0 4px; font-size: 20px; font-weight: 700; }
.app-header .subtitle { font-size: 13px; opacity: 0.75; margin: 0; }
.stat-chips { display: flex; gap: 10px; margin-top: 12px; flex-wrap: wrap; }
.chip {
  background: rgba(255,255,255,0.15);
  border: 1px solid rgba(255,255,255,0.25);
  border-radius: 20px;
  padding: 3px 10px;
  font-size: 12px;
  font-weight: 500;
}

/* Sidebar */
.sidebar-panel {
  background: white;
  border-radius: 12px;
  padding: 16px;
  box-shadow: 0 1px 4px rgba(0,0,0,0.08);
  height: 100%;
}
.group-label {
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 1px;
  color: #888;
  margin: 14px 0 6px;
  padding-bottom: 4px;
  border-bottom: 1px solid #eee;
}
.group-label:first-child { margin-top: 0; }
.slider-wrap { margin-bottom: 2px; }
.slider-desc { font-size: 11px; color: #999; margin: -8px 0 4px; line-height: 1.3; }

.btn-proyectar {
  background: #1a4a7a; color: white; border: none;
  width: 100%; padding: 10px; border-radius: 8px;
  font-size: 14px; font-weight: 600; cursor: pointer;
  margin-top: 14px; transition: background 0.2s;
}
.btn-proyectar:hover { background: #0d2137; }
.btn-reset {
  background: white; color: #666; border: 1px solid #ddd;
  width: 100%; padding: 8px; border-radius: 8px;
  font-size: 13px; cursor: pointer; margin-top: 6px;
  transition: all 0.2s;
}
.btn-reset:hover { border-color: #999; color: #333; }

/* Cards */
.card {
  background: white;
  border-radius: 12px;
  padding: 18px 20px;
  box-shadow: 0 1px 4px rgba(0,0,0,0.07);
  margin-bottom: 14px;
}
.card-title {
  font-size: 12px; font-weight: 700; text-transform: uppercase;
  letter-spacing: 0.8px; color: #888; margin: 0 0 12px;
}

/* Ejes radio */
.radio-ejes label { font-size: 13px; color: #444; }
.radio-ejes .radio { margin: 3px 0; }

/* PC info strip */
.pc-strip {
  display: flex; gap: 8px; margin-bottom: 14px; flex-wrap: wrap;
}
.pc-badge {
  flex: 1; min-width: 80px; background: #f7f9fc;
  border: 1px solid #e8edf3; border-radius: 8px;
  padding: 8px 10px; text-align: center;
}
.pc-badge .pc-name { font-size: 11px; font-weight: 700; color: #888; }
.pc-badge .pc-var  { font-size: 18px; font-weight: 700; color: #1a4a7a; }
.pc-badge .pc-pct  { font-size: 11px; color: #aaa; }
.pc-badge .pc-desc { font-size: 10px; color: #666; margin-top: 2px; line-height: 1.3; }

/* Score result rows */
.score-row {
  display: flex; align-items: center; gap: 10px;
  padding: 8px 0; border-bottom: 1px solid #f0f0f0;
}
.score-row:last-child { border-bottom: none; }
.score-label { font-size: 12px; font-weight: 600; color: #555; width: 34px; }
.score-bar-wrap { flex: 1; background: #f0f2f5; border-radius: 4px; height: 6px; overflow: hidden; }
.score-bar { height: 6px; border-radius: 4px; transition: width 0.4s; }
.score-val { font-size: 13px; font-weight: 700; width: 46px; text-align: right; }
.score-pct { font-size: 11px; color: #aaa; width: 40px; text-align: right; }

/* Quality badge */
.quality-badge {
  display: inline-block; border-radius: 20px;
  padding: 4px 12px; font-size: 12px; font-weight: 700;
  margin-bottom: 10px;
}
.q-alta    { background: #d4edda; color: #155724; }
.q-media   { background: #fff3cd; color: #856404; }
.q-baja    { background: #f8d7da; color: #721c24; }

/* Interpretacion items */
.interp-item {
  padding: 8px 10px; border-radius: 8px;
  background: #f7f9fc; margin-bottom: 6px;
  border-left: 3px solid #1a4a7a;
}
.interp-item.alt { border-left-color: #6c8ebf; }
.interp-item.con { border-left-color: #27ae60; }
.interp-pc  { font-size: 11px; font-weight: 700; color: #888; margin-bottom: 2px; }
.interp-val { font-size: 13px; color: #222; line-height: 1.4; }

/* Info box */
.info-box {
  background: #eef4fb; border: 1px solid #c8ddf2;
  border-radius: 8px; padding: 10px 14px;
  font-size: 12px; color: #2c5f8a; line-height: 1.5;
  margin-bottom: 14px;
}
.info-box b { font-weight: 600; }

/* Placeholder */
.placeholder {
  text-align: center; color: #bbb;
  padding: 30px 10px; font-size: 13px;
}
.placeholder .icon { font-size: 32px; margin-bottom: 8px; }
"

# ── UI ────────────────────────────────────────────────────────────────────────

slider_group <- function(vars) {
  lapply(vars, function(v) {
    r    <- rangos[[v]]
    step <- if (v == "altitude_mean_meters") 10 else 0.1
    tagList(
      div(class = "slider-wrap",
        sliderInput(v, label = nombres_ui[[v]],
                    min = r$min, max = r$max, value = r$val, step = step,
                    width = "100%")
      ),
      div(class = "slider-desc", descripciones[[v]])
    )
  })
}

ui <- fluidPage(
  tags$head(
    tags$style(HTML(css)),
    tags$link(rel = "stylesheet",
              href = "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap")
  ),

  # Header
  div(class = "app-header",
    h2("Explorador PCA — Calidad de Café Arábica"),
    p(class = "subtitle",
      "Ingresa los atributos de un lote nuevo y observa dónde se ubica en el espacio de componentes principales"),
    div(class = "stat-chips",
      span(class = "chip", "1.070 lotes de referencia"),
      span(class = "chip", "11 variables"),
      span(class = "chip", paste0("PC1 explica ", var_exp[1], " % de la varianza")),
      span(class = "chip", "Café Arábica · CQI")
    )
  ),

  # Info strip con los 4 PC
  div(style = "padding: 0 0 4px;",
    div(class = "pc-strip",
      div(class = "pc-badge",
        div(class = "pc-name", "PC1"),
        div(class = "pc-var",  paste0(var_exp[1], "%")),
        div(class = "pc-desc", "Calidad sensorial general")
      ),
      div(class = "pc-badge",
        div(class = "pc-name", "PC2"),
        div(class = "pc-var",  paste0(var_exp[2], "%")),
        div(class = "pc-desc", "Consistencia vs. intensidad")
      ),
      div(class = "pc-badge",
        div(class = "pc-name", "PC3"),
        div(class = "pc-var",  paste0(var_exp[3], "%")),
        div(class = "pc-desc", "Altitud de producción")
      ),
      div(class = "pc-badge",
        div(class = "pc-name", "PC4"),
        div(class = "pc-var",  paste0(var_exp[4], "%")),
        div(class = "pc-desc", "Contraste sensorial fino")
      )
    )
  ),

  sidebarLayout(
    sidebarPanel(
      width = 3,
      div(class = "sidebar-panel",
        div(class = "info-box",
          tags$b("¿Cómo funciona?"), " Ajusta los puntajes del lote que quieres analizar.
          Al presionar «Proyectar», el lote se transforma con el mismo preprocesamiento
          del modelo (Yeo-Johnson) y se ubica en el espacio PCA de los 1.070 lotes de referencia."
        ),

        div(class = "group-label", "Puntajes de intensidad  ·  escala 0 – 10"),
        slider_group(grupo_intensidad),

        div(class = "group-label", "Consistencia y pureza  ·  escala 0 – 10"),
        slider_group(grupo_consistencia),

        div(class = "group-label", "Agroclimático"),
        slider_group(grupo_altitud),

        tags$button("Proyectar este lote", class = "btn-proyectar",
                    onclick = "Shiny.setInputValue('proyectar', Math.random())"),
        tags$button("Restablecer medianas", class = "btn-reset",
                    onclick = "Shiny.setInputValue('reset', Math.random())")
      )
    ),

    mainPanel(
      width = 9,

      fluidRow(
        # Biplot
        column(8,
          div(class = "card",
            div(class = "card-title", textOutput("titulo_plot", inline = TRUE)),
            plotOutput("biplot", height = "400px"),
            div(class = "radio-ejes", style = "margin-top:8px;",
              radioButtons("ejes", NULL,
                choices = c(
                  paste0("PC1 vs PC2 — Calidad sensorial  ↔  Consistencia (", var_exp[1], "% + ", var_exp[2], "%)") = "12",
                  paste0("PC1 vs PC3 — Calidad sensorial  ↔  Altitud       (", var_exp[1], "% + ", var_exp[3], "%)") = "13"
                ),
                selected = "12", inline = FALSE)
            )
          )
        ),

        # Panel derecho
        column(4,
          # Scores
          div(class = "card",
            div(class = "card-title", "Scores del nuevo lote"),
            uiOutput("scores_ui")
          ),
          # Interpretación
          div(class = "card",
            div(class = "card-title", "Interpretación"),
            uiOutput("interpretacion_ui")
          )
        )
      )
    )
  )
)

# ── Server ────────────────────────────────────────────────────────────────────

server <- function(input, output, session) {

  observeEvent(input$reset, {
    for (v in vars_11) updateSliderInput(session, v, value = rangos[[v]]$val)
  })

  nuevo_score <- eventReactive(input$proyectar, {
    nuevo_df <- as.data.frame(setNames(lapply(vars_11, function(v) input[[v]]), vars_11))
    for (v in names(nuevo_df)) nuevo_df[[v]] <- yjPower(nuevo_df[[v]], lambdas_11[v])
    nuevo_scaled <- scale(nuevo_df, center = pca$center, scale = pca$scale)
    scores <- as.numeric(nuevo_scaled %*% pca$rotation)
    names(scores) <- paste0("PC", seq_along(scores))
    scores
  }, ignoreNULL = TRUE)

  ejes_sel <- reactive({ as.integer(strsplit(input$ejes, "")[[1]]) })

  output$titulo_plot <- renderText({
    e <- ejes_sel()
    paste0("Plano PC", e[1], " – PC", e[2])
  })

  output$biplot <- renderPlot({
    e  <- ejes_sel()
    cx <- paste0("PC", e[1])
    cy <- paste0("PC", e[2])

    p <- ggplot(scores_df, aes_string(x = cx, y = cy)) +
      geom_point(alpha = 0.18, color = "#2563a8", size = 1.1) +
      geom_hline(yintercept = 0, linetype = "dashed", color = "#ccc", linewidth = 0.4) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "#ccc", linewidth = 0.4) +
      annotate("text", x = Inf, y = Inf,
               label = paste0("← alta calidad"),
               hjust = 1.1, vjust = 1.6, size = 3, color = "#aaa") +
      labs(
        x = paste0(cx, "  (", var_exp[e[1]], " % de la varianza)"),
        y = paste0(cy, "  (", var_exp[e[2]], " % de la varianza)"),
        caption = "Cada punto es uno de los 1.070 lotes del Coffee Quality Institute (CQI)"
      ) +
      theme_minimal(base_size = 13) +
      theme(
        panel.grid.minor   = element_blank(),
        panel.grid.major   = element_line(color = "#f0f0f0"),
        axis.title         = element_text(color = "#555", size = 11),
        plot.caption       = element_text(color = "#aaa", size = 10),
        plot.background    = element_rect(fill = "white", color = NA),
        panel.background   = element_rect(fill = "white", color = NA)
      )

    ns <- nuevo_score()
    if (!is.null(ns)) {
      nd <- setNames(data.frame(ns[e[1]], ns[e[2]]), c(cx, cy))
      pct_pc1 <- mean(scores_df$PC1 <= ns[1]) * 100
      calidad <- if (pct_pc1 < 25) "Alta calidad" else if (pct_pc1 < 60) "Calidad media" else "Baja calidad"
      p <- p +
        geom_point(data = nd, aes_string(x = cx, y = cy),
                   color = "#e74c3c", size = 12, shape = 21,
                   fill = "#e74c3c", alpha = 0.15) +
        geom_point(data = nd, aes_string(x = cx, y = cy),
                   color = "#e74c3c", size = 5, shape = 17) +
        annotate("label", x = nd[[cx]], y = nd[[cy]],
                 label = paste0(" Tu lote\n ", calidad),
                 vjust = -0.7, hjust = 0.5,
                 size = 3.2, color = "#c0392b",
                 fill = "white", label.size = 0.3,
                 label.padding = unit(0.3, "lines"))
    }
    p
  }, bg = "white")

  # Scores panel
  output$scores_ui <- renderUI({
    ns <- nuevo_score()
    if (is.null(ns)) {
      return(div(class = "placeholder",
        div(class = "icon", "☕"),
        "Ajusta los sliders y presiona", br(), tags$b("«Proyectar este lote»")
      ))
    }

    pc_descs <- c("Calidad sensorial general",
                  "Consistencia vs. intensidad",
                  "Altitud de producción",
                  "Contraste sensorial fino")
    pc_colors <- c("#1a4a7a", "#27ae60", "#6c8ebf", "#9b59b6")

    max_abs <- max(abs(ns[1:4]))

    tagList(
      lapply(1:4, function(k) {
        score   <- ns[k]
        pct     <- mean(scores_df[[paste0("PC", k)]] <= score) * 100
        bar_pct <- min(100, abs(score) / max(max_abs, 0.01) * 100)
        div(class = "score-row",
          div(class = "score-label", paste0("PC", k)),
          div(class = "score-bar-wrap",
            div(class = "score-bar",
                style = paste0("width:", bar_pct, "%; background:", pc_colors[k], ";"))
          ),
          div(class = "score-val",
              style = paste0("color:", pc_colors[k], ";"),
              sprintf("%+.2f", score)),
          div(class = "score-pct", paste0("p", round(pct), "°"))
        )
      }),
      div(style = "font-size:11px; color:#aaa; margin-top:8px;",
          "p = percentil dentro de los 1.070 lotes de referencia")
    )
  })

  # Interpretación
  output$interpretacion_ui <- renderUI({
    ns <- nuevo_score()
    if (is.null(ns)) return(NULL)

    pct_pc1 <- mean(scores_df$PC1 <= ns[1]) * 100
    pct_pc2 <- mean(scores_df$PC2 <= ns[2]) * 100
    pct_pc3 <- mean(scores_df$PC3 <= ns[3]) * 100

    # Badge de calidad
    if (pct_pc1 < 25) {
      badge_class <- "quality-badge q-alta"
      badge_text  <- "Alta calidad sensorial"
    } else if (pct_pc1 < 60) {
      badge_class <- "quality-badge q-media"
      badge_text  <- "Calidad sensorial media"
    } else {
      badge_class <- "quality-badge q-baja"
      badge_text  <- "Calidad sensorial baja"
    }

    # PC2 texto
    pc2_txt <- if (ns[2] > 0.8) {
      "Destaca en consistencia y dulzura (Uniformity, Sweetness, Clean Cup elevados)"
    } else if (ns[2] < -0.8) {
      "Destaca en intensidad sensorial (Flavor, Aroma, Acidity elevados)"
    } else {
      "Balance entre consistencia y dulzura"
    }

    # PC3 texto
    pc3_txt <- if (ns[3] > 0.8) {
      paste0("Altitud relativamente alta (percentil ", round(pct_pc3), " entre los lotes de referencia)")
    } else if (ns[3] < -0.8) {
      paste0("Altitud relativamente baja (percentil ", round(pct_pc3), " entre los lotes de referencia)")
    } else {
      paste0("Altitud típica del dataset (percentil ", round(pct_pc3), ")")
    }

    tagList(
      div(class = badge_class, badge_text),
      div(style = "font-size:12px; color:#666; margin-bottom:10px;",
          sprintf("Percentil %d en PC1 — el %.0f%% de los lotes tiene menor calidad sensorial.",
                  round(pct_pc1), pct_pc1)),
      div(class = "interp-item con",
        div(class = "interp-pc", "PC2 · Consistencia vs. Intensidad"),
        div(class = "interp-val", pc2_txt)
      ),
      div(class = "interp-item alt",
        div(class = "interp-pc", "PC3 · Altitud"),
        div(class = "interp-val", pc3_txt)
      ),
      div(style = "font-size:11px; color:#aaa; margin-top:10px; line-height:1.5;",
        "Los scores negativos en PC1 indican mayor calidad sensorial
        (las cargas sensoriales apuntan en dirección negativa)."
      )
    )
  })
}

shinyApp(ui, server)
