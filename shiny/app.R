library(shiny)
library(dplyr)
library(ggplot2)
library(car)

# ── Preprocesamiento ──────────────────────────────────────────────────────────

# ── Matriz final de 627 lotes (pipeline oficial, misma que el informe) ─────
# Cargada desde 01-pca/datos_final_627.rds: ya incluye la depuración de atípicos
# y las lambdas Yeo-Johnson estimadas sobre la matriz final.
obj_final <- readRDS("../01-pca/datos_final_627.rds")

rename_map <- c(Aroma = "Aroma", Flavor = "Sabor", Aftertaste = "Retrogusto",
                Acidity = "Acidez", Body = "Cuerpo", Balance = "Balance",
                Cupper.Points = "Puntaje.Catador", altitude_mean_meters = "Altitud")
vars_8 <- c("Aroma", "Sabor", "Retrogusto", "Acidez",
            "Cuerpo", "Balance", "Puntaje.Catador", "Altitud")

datos_t <- obj_final$datos_limpio
names(datos_t) <- rename_map[names(datos_t)]
datos_t <- datos_t[, vars_8]

# lambda = 1 para las variables que no se transforman
lambdas_8 <- setNames(rep(1, length(vars_8)), vars_8)
lam <- obj_final$lambdas
names(lam) <- rename_map[names(lam)]
lambdas_8[names(lam)] <- lam

pca       <- prcomp(datos_t, center = TRUE, scale. = TRUE)
scores_df <- as.data.frame(pca$x)
var_exp   <- round(pca$sdev^2 / sum(pca$sdev^2) * 100, 1)

# valores crudos de los 627 lotes, para rangos y percentiles
datos_full <- obj_final$datos_originales
names(datos_full)[match(names(rename_map), names(datos_full))] <- rename_map[names(rename_map)]
datos_full <- datos_full[, vars_8]

rangos <- lapply(vars_8, function(v) {
  x <- datos_full[[v]]
  list(min = floor(min(x) * 10) / 10,
       max = ceiling(max(x) * 10) / 10,
       val = round(median(x), 1))
})
names(rangos) <- vars_8

grupo_sensorial <- c("Aroma", "Sabor", "Retrogusto", "Acidez",
                     "Cuerpo", "Balance", "Puntaje.Catador")
grupo_altitud   <- c("Altitud")

descripciones <- c(
  Aroma           = "Intensidad y calidad del aroma percibido",
  Sabor           = "Sabor percibido durante la degustación",
  Retrogusto      = "Persistencia y calidad del retrogusto",
  Acidez          = "Viveza y brillo de la acidez",
  Cuerpo          = "Sensación de peso y textura en boca",
  Balance         = "Armonía entre todos los atributos sensoriales",
  Puntaje.Catador = "Puntaje holístico del catador profesional",
  Altitud         = "Altura de la finca sobre el nivel del mar (metros)"
)

nombres_ui <- c(
  Aroma           = "Aroma",
  Sabor           = "Sabor",
  Retrogusto      = "Retrogusto",
  Acidez          = "Acidez",
  Cuerpo          = "Cuerpo",
  Balance         = "Balance",
  Puntaje.Catador = "Puntaje Catador",
  Altitud         = "Altitud (metros)"
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

.radio-ejes label { font-size: 13px; color: #444; }
.radio-ejes .radio { margin: 3px 0; }

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
.pc-badge .pc-desc { font-size: 10px; color: #666; margin-top: 2px; line-height: 1.3; }

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

.quality-badge {
  display: inline-block; border-radius: 20px;
  padding: 4px 12px; font-size: 12px; font-weight: 700;
  margin-bottom: 10px;
}
.q-alta  { background: #d4edda; color: #155724; }
.q-media { background: #fff3cd; color: #856404; }
.q-baja  { background: #f8d7da; color: #721c24; }

.interp-item {
  padding: 8px 10px; border-radius: 8px;
  background: #f7f9fc; margin-bottom: 6px;
  border-left: 3px solid #1a4a7a;
}
.interp-item.alt { border-left-color: #6c8ebf; }
.interp-item.con { border-left-color: #27ae60; }
.interp-pc  { font-size: 11px; font-weight: 700; color: #888; margin-bottom: 2px; }
.interp-val { font-size: 13px; color: #222; line-height: 1.4; }

.info-box {
  background: #eef4fb; border: 1px solid #c8ddf2;
  border-radius: 8px; padding: 10px 14px;
  font-size: 12px; color: #2c5f8a; line-height: 1.5;
  margin-bottom: 14px;
}
.info-box b { font-weight: 600; }

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
    step <- if (v == "Altitud") 10 else 0.1
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

  div(class = "app-header",
    h2("Explorador PCA — Calidad de Café Arábica · CQI"),
    p(class = "subtitle",
      "Ajusta los atributos sensoriales y agroclimáticos de un lote nuevo para ubicarlo en el espacio de componentes principales respecto a los 627 lotes de referencia"),
    div(class = "stat-chips",
      span(class = "chip", "627 lotes · matriz final"),
      span(class = "chip", "8 variables (7 sensoriales + altitud)"),
      span(class = "chip", paste0("CP1 explica ", var_exp[1], "% de la varianza")),
      span(class = "chip", paste0("CP1+CP2 = ", var_exp[1] + var_exp[2], "%"))
    )
  ),

  div(style = "padding: 0 0 4px;",
    div(class = "pc-strip",
      div(class = "pc-badge",
        div(class = "pc-name", "CP1"),
        div(class = "pc-var",  paste0(var_exp[1], "%")),
        div(class = "pc-desc", "Calidad sensorial general")
      ),
      div(class = "pc-badge",
        div(class = "pc-name", "CP2"),
        div(class = "pc-var",  paste0(var_exp[2], "%")),
        div(class = "pc-desc", "Contraste entre atributos")
      ),
      div(class = "pc-badge",
        div(class = "pc-name", "CP3"),
        div(class = "pc-var",  paste0(var_exp[3], "%")),
        div(class = "pc-desc", "Componente de altitud")
      ),
      div(class = "pc-badge",
        div(class = "pc-name", "CP4"),
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
          del modelo (Yeo-Johnson) y se ubica en el espacio PCA de los 627 lotes de referencia."
        ),

        div(class = "group-label", "Puntajes sensoriales  ·  escala 0 – 10"),
        slider_group(grupo_sensorial),

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
        column(8,
          div(class = "card",
            div(class = "card-title", textOutput("titulo_plot", inline = TRUE)),
            plotOutput("biplot", height = "400px"),
            div(class = "radio-ejes", style = "margin-top:8px;",
              radioButtons("ejes", NULL,
                choices = setNames(
                  c("12", "13"),
                  c(paste0("CP1 vs CP2 — Calidad sensorial  ↔  Contraste atributos (", var_exp[1], "% + ", var_exp[2], "%)"),
                    paste0("CP1 vs CP3 — Calidad sensorial  ↔  Altitud              (", var_exp[1], "% + ", var_exp[3], "%)"))
                ),
                selected = "12", inline = FALSE)
            )
          )
        ),
        column(4,
          div(class = "card",
            div(class = "card-title", "Scores del nuevo lote"),
            uiOutput("scores_ui")
          ),
          div(class = "card",
            div(class = "card-title", "Interpretación"),
            uiOutput("interpretacion_ui")
          )
        )
      ),
      fluidRow(
        column(4,
          div(class = "card",
            div(class = "card-title", "Varianza por componente"),
            plotOutput("scree", height = "320px"),
            div(style = "font-size:12px; color:#666;",
              "Cada barra es el porcentaje de varianza que explica el componente. CP1 y CP2 suman 66,8 %.")
          )
        ),
        column(4,
          div(class = "card",
            div(class = "card-title", "Cargas de las variables (CP1–CP4)"),
            plotOutput("cargas", height = "320px"),
            div(style = "font-size:12px; color:#666;",
              "CP1 agrupa los puntajes sensoriales; CP2 es principalmente altitud.")
          )
        ),
        column(4,
          div(class = "card",
            div(class = "card-title", "Distribución de CP1 y tu lote"),
            plotOutput("dens", height = "320px"),
            div(style = "font-size:12px; color:#666;",
              "La línea roja marca la posición de tu lote dentro de los 627 de referencia.")
          )
        )
      )
    )
  )
)

# ── Server ────────────────────────────────────────────────────────────────────

server <- function(input, output, session) {

  observeEvent(input$reset, {
    for (v in vars_8) updateSliderInput(session, v, value = rangos[[v]]$val)
  })

  nuevo_score <- eventReactive(input$proyectar, {
    nuevo_df <- as.data.frame(setNames(lapply(vars_8, function(v) input[[v]]), vars_8))
    for (v in vars_yj) nuevo_df[[v]] <- yjPower(nuevo_df[[v]], lambdas_8[v])
    nuevo_scaled <- scale(nuevo_df, center = pca$center, scale = pca$scale)
    scores <- as.numeric(nuevo_scaled %*% pca$rotation)
    names(scores) <- paste0("PC", seq_along(scores))
    scores
  }, ignoreNULL = TRUE)

  ejes_sel <- reactive({ as.integer(strsplit(input$ejes, "")[[1]]) })

  output$titulo_plot <- renderText({
    e <- ejes_sel()
    paste0("Plano CP", e[1], " – CP", e[2])
  })

  output$biplot <- renderPlot({
    e  <- ejes_sel()
    cx <- paste0("PC", e[1])
    cy <- paste0("PC", e[2])

    p <- ggplot(scores_df, aes_string(x = cx, y = cy)) +
      geom_point(alpha = 0.18, color = "#2563a8", size = 1.1) +
      geom_hline(yintercept = 0, linetype = "dashed", color = "#ccc", linewidth = 0.4) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "#ccc", linewidth = 0.4) +
      labs(
        x = paste0("CP", e[1], "  (", var_exp[e[1]], " % de la varianza)"),
        y = paste0("CP", e[2], "  (", var_exp[e[2]], " % de la varianza)"),
        caption = "Cada punto es uno de los 627 lotes del Coffee Quality Institute (CQI)"
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
      pct_pc1    <- mean(scores_df$PC1 <= ns[1]) * 100
      pct_calidad <- 100 - pct_pc1   # PC1 negativo = mayor calidad sensorial
      calidad <- if (pct_calidad >= 75) "Alta calidad" else if (pct_calidad >= 25) "Calidad media" else "Baja calidad"
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

  output$scree <- renderPlot({
    df <- data.frame(PC = factor(paste0("CP", seq_along(var_exp)), levels = paste0("CP", seq_along(var_exp))),
                     pct = var_exp)
    ggplot(df, aes(x = PC, y = pct)) +
      geom_col(fill = "#2563a8", width = 0.7) +
      geom_text(aes(label = paste0(pct, " %")), vjust = -0.4, size = 3.4, color = "#333") +
      labs(x = NULL, y = "Varianza explicada (%)") +
      theme_minimal(base_size = 12) +
      theme(panel.grid.minor = element_blank(),
            plot.background = element_rect(fill = "white", color = NA))
  }, bg = "white")

  output$cargas <- renderPlot({
    rot <- pca$rotation[, 1:4]
    df <- data.frame(
      Variable = rep(rownames(rot), times = 4),
      Componente = factor(rep(paste0("CP", 1:4), each = nrow(rot)), levels = paste0("CP", 1:4)),
      Carga = as.vector(rot)
    )
    df$Variable <- factor(df$Variable, levels = rev(rownames(rot)))
    ggplot(df, aes(x = Componente, y = Variable, fill = Carga)) +
      geom_tile(color = "white") +
      geom_text(aes(label = sprintf("%.2f", Carga)), size = 3.3, color = "#222") +
      scale_fill_gradient2(low = "#2563a8", mid = "white", high = "#c0392b",
                           limits = c(-1, 1), name = "Carga") +
      labs(x = NULL, y = NULL) +
      theme_minimal(base_size = 12) +
      theme(panel.grid = element_blank(),
            plot.background = element_rect(fill = "white", color = NA))
  }, bg = "white")

  output$dens <- renderPlot({
    ns <- nuevo_score()
    p <- ggplot(scores_df, aes(x = PC1)) +
      geom_density(fill = "#9fc3e6", alpha = 0.6, color = "#2563a8") +
      labs(x = paste0("CP1 (", var_exp[1], " %)  ·  más bajo = mayor calidad sensorial"), y = "Densidad") +
      theme_minimal(base_size = 12) +
      theme(panel.grid.minor = element_blank(),
            plot.background = element_rect(fill = "white", color = NA))
    if (!is.null(ns)) {
      p <- p + geom_vline(xintercept = ns[1], color = "#c0392b", linewidth = 1)
    }
    p
  }, bg = "white")

  output$scores_ui <- renderUI({
    ns <- nuevo_score()
    if (is.null(ns)) {
      return(div(class = "placeholder",
        div(class = "icon", "☕"),
        "Ajusta los sliders y presiona", br(), tags$b("«Proyectar este lote»")
      ))
    }

    pc_colors <- c("#1a4a7a", "#27ae60", "#6c8ebf", "#9b59b6")
    max_abs   <- max(abs(ns[1:4]))

    tagList(
      lapply(1:4, function(k) {
        score   <- ns[k]
        pct     <- mean(scores_df[[paste0("PC", k)]] <= score) * 100
        bar_pct <- min(100, abs(score) / max(max_abs, 0.01) * 100)
        div(class = "score-row",
          div(class = "score-label", paste0("CP", k)),
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
          "p = percentil dentro de los 627 lotes de referencia")
    )
  })

  output$interpretacion_ui <- renderUI({
    ns <- nuevo_score()
    if (is.null(ns)) return(NULL)

    pct_pc1     <- mean(scores_df$PC1 <= ns[1]) * 100
    pct_pc3     <- mean(scores_df$PC3 <= ns[3]) * 100
    pct_calidad <- 100 - pct_pc1   # PC1 negativo = mayor calidad sensorial

    if (pct_calidad >= 75) {
      badge_class <- "quality-badge q-alta"
      badge_text  <- "Alta calidad sensorial"
    } else if (pct_calidad >= 25) {
      badge_class <- "quality-badge q-media"
      badge_text  <- "Calidad sensorial media"
    } else {
      badge_class <- "quality-badge q-baja"
      badge_text  <- "Calidad sensorial baja"
    }

    pc2_txt <- if (ns[2] > 0.8) {
      "Perfil con mayor peso en atributos secundarios (Retrogusto, Balance, Cuerpo)"
    } else if (ns[2] < -0.8) {
      "Perfil con mayor peso en atributos primarios (Aroma, Sabor, Acidez, Puntaje Catador)"
    } else {
      "Perfil equilibrado entre atributos primarios y secundarios"
    }

    pc3_txt <- if (ns[3] > 0.8) {
      paste0("Altitud de cultivo alta — percentil ", round(pct_pc3), " en el dataset")
    } else if (ns[3] < -0.8) {
      paste0("Altitud de cultivo baja — percentil ", round(pct_pc3), " en el dataset")
    } else {
      paste0("Altitud de cultivo típica — percentil ", round(pct_pc3), " en el dataset")
    }

    tagList(
      div(class = badge_class, badge_text),
      div(style = "font-size:12px; color:#666; margin-bottom:10px;",
          sprintf("Superior al %.0f%% de los lotes en calidad sensorial (CP1, percentil %d).",
                  pct_calidad, round(pct_calidad))),
      div(class = "interp-item con",
        div(class = "interp-pc", "CP2 · Contraste entre atributos sensoriales"),
        div(class = "interp-val", pc2_txt)
      ),
      div(class = "interp-item alt",
        div(class = "interp-pc", "CP3 · Altitud de cultivo"),
        div(class = "interp-val", pc3_txt)
      ),
      div(style = "font-size:11px; color:#aaa; margin-top:10px; line-height:1.5;",
        paste0("CP1 captura el ", var_exp[1], "% de la varianza total. ",
               "Score negativo en CP1 indica mayor calidad sensorial ",
               "(los 7 atributos sensoriales cargan negativamente en CP1).")
      )
    )
  })
}

shinyApp(ui, server)
