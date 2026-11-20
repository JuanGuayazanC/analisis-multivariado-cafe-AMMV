# Genera el guion en formato de tarjetas por diapositiva, con el diálogo de cada persona marcado.
# Lee presentacion/guion_presentacion.txt (fuente única del texto) y escribe
#   presentacion/guion_dialogo_AMMV.html  y  presentacion/guion_dialogo_AMMV.pdf
# Uso (desde la raíz del repositorio):  Rscript presentacion/generar_guion_dialogo.R
# El PDF se genera con Edge o Chrome en modo headless si están instalados.

setwd(if (file.exists("presentacion/guion_presentacion.txt")) "presentacion" else ".")
txt <- readLines("guion_presentacion.txt", encoding = "UTF-8", warn = FALSE)

# ---- utilidades -------------------------------------------------------------
esc <- function(x) { x <- gsub("&", "&amp;", x, fixed = TRUE); x <- gsub("<", "&lt;", x, fixed = TRUE); gsub(">", "&gt;", x, fixed = TRUE) }
md <- function(x) {
  x <- esc(x)
  x <- gsub("\\*\\*(.+?)\\*\\*", "<strong>\\1</strong>", x, perl = TRUE)
  x <- gsub("`([^`]+)`", "<code>\\1</code>", x, perl = TRUE)
  x <- gsub("(?<![*\\w])\\*([^*]+)\\*(?![*\\w])", "<em>\\1</em>", x, perl = TRUE)
  x
}
quien <- c(Juan = "Juan Guayazán", Diego = "Diego Nocua", Esteban = "Esteban Valente")
clase <- c(Juan = "juan", Diego = "diego", Esteban = "esteban")

# ---- partir el guion por diapositivas --------------------------------------
i_ap <- grep("^# Apoyo para preguntas", txt)
principal <- txt[seq_len(i_ap - 1)]
apoyo <- txt[(i_ap + 1):length(txt)]

enc <- grep("^## Diapositiva [0-9]+ - ", principal)
fin_dia <- c(enc[-1] - 1, grep("^## Distribución del tiempo", principal) - 1)
slides <- lapply(seq_along(enc), function(k) {
  bloque <- principal[enc[k]:fin_dia[k]]
  tit <- sub("^## Diapositiva [0-9]+ - ", "", bloque[1])
  num <- as.integer(sub("^## Diapositiva ([0-9]+) - .*", "\\1", bloque[1]))
  meta <- bloque[grep("^\\*Tiempo:", bloque)[1]]
  dur <- sub("^\\*Tiempo: ([0-9:]+) .*", "\\1", meta)
  pers <- sub(".*Presenta: ([A-Za-z]+)\\*$", "\\1", meta)
  cuerpo <- bloque[-(1:grep("^\\*Tiempo:", bloque)[1])]
  cuerpo <- cuerpo[nzchar(trimws(cuerpo))]
  list(num = num, titulo = tit, dur = dur, pers = pers, cuerpo = cuerpo)
})

# ---- tiempos acumulados ------------------------------------------------------
a_seg <- function(m) { p <- as.integer(strsplit(m, ":")[[1]]); p[1] * 60 + p[2] }
a_txt <- function(s) sprintf("%d:%02d", s %/% 60, s %% 60)
acum <- 0
for (k in seq_along(slides)) {
  slides[[k]]$ini <- acum; acum <- acum + a_seg(slides[[k]]$dur); slides[[k]]$fin <- acum
}
rango <- function(s) paste0(a_txt(s$ini), " – ", a_txt(s$fin))

# ---- metadatos por diapositiva ----------------------------------------------
preguntas <- c("¿Qué revelan los datos detrás del café arábica?",
  "¿Qué problema tienen los datos y qué queremos responder?",
  "¿Cómo organizamos el análisis?",
  "¿De dónde salen los 970 lotes?",
  "¿Dónde caen los lotes en las dos primeras componentes?",
  "¿Cuánta variación explica cada eje y qué pesa en cada uno?",
  "¿Cómo se asocian el proceso, el color y el país?",
  "¿Cuántos grupos hay que buscar?",
  "¿Qué grupos produce K-means?",
  "¿Hay zonas densas de lotes parecidos?",
  "¿Qué muestra un método jerárquico?",
  "¿Dónde caería un lote nuevo en el PCA?",
  "¿Respondimos el objetivo?",
  "Cierre")
etiquetas <- list(c("Portada"), c("Diagnóstico", "Humedad = 0"), c("Metodología"), c("Mahalanobis", "Yeo-Johnson"),
  c("PCA"), c("PCA", "Bootstrap"), c("ACM"), c("Silueta", "Gap"), c("K-means"), c("HDBSCAN"), c("Ward.D2"),
  c("Shiny", "Demo en vivo"), c("Conclusiones"), c("Cierre"))
bloques <- list(
  list(num = "I", nombre = "Problema y datos", dias = 1:4),
  list(num = "II", nombre = "PCA y variables categóricas", dias = 5:7),
  list(num = "III", nombre = "Agrupamiento", dias = 8:11),
  list(num = "IV", nombre = "Demostración", dias = 12),
  list(num = "V", nombre = "Conclusiones y cierre", dias = 13:14))

# ---- tarjetas ---------------------------------------------------------------
tarjeta <- function(s) {
  p <- s$pers; cl <- clase[[p]]
  lineas <- character()
  for (l in s$cuerpo) {
    if (grepl("^\\*\\*Transición:\\*\\*", l)) {
      lineas <- c(lineas, sprintf('<div class="trans"><span class="lab">Relevo / transición</span> %s</div>', md(sub("^\\*\\*Transición:\\*\\* *", "", l))))
    } else if (grepl("^\\*\\*Acción:\\*\\*", l)) {
      lineas <- c(lineas, sprintf('<div class="accion"><span class="lab">Acción en pantalla</span> %s</div>', md(sub("^\\*\\*Acción:\\*\\* *", "", l))))
    } else {
      lineas <- c(lineas, sprintf('<div class="linea"><span class="spk %s">%s</span><p>%s</p></div>', cl, toupper(p), md(l)))
    }
  }
  sprintf('<div class="card"><div class="head"><span class="n">%d</span><span class="t">%s</span><span class="tm">%s</span></div>
<div class="quien"><span class="chip %s">%s</span><span class="dur">habla %s</span></div>
<p class="q">%s</p>%s<div class="tags">%s</div></div>',
    s$num, esc(s$titulo), rango(s), cl, quien[[p]], s$dur, esc(preguntas[s$num]), paste(lineas, collapse = "\n"),
    paste(sprintf("<span>%s</span>", esc(etiquetas[[s$num]])), collapse = ""))
}

cuerpo_html <- character()
for (b in bloques) {
  ss <- slides[b$dias]
  cuerpo_html <- c(cuerpo_html, sprintf('<div class="bloque"><span class="bn">%s · %s</span><span class="bt">%s – %s</span></div>',
    b$num, esc(b$nombre), a_txt(ss[[1]]$ini), a_txt(ss[[length(ss)]]$fin)))
  cuerpo_html <- c(cuerpo_html, vapply(ss, tarjeta, character(1)))
}

# ---- tabla resumen ----------------------------------------------------------
resumen <- data.frame(
  d = 1:14,
  tema = c("Portada", "Diagnóstico", "Metodología", "Depuración", "PCA: nube", "PCA: varianza y cargas", "ACM", "Selección de k", "K-means", "HDBSCAN", "Ward.D2", "Demo Shiny", "Conclusiones", "Cierre"),
  pregunta = c("¿Qué revelan los datos?", "¿Qué problema hay en los datos?", "¿Cómo se organiza el análisis?", "¿De dónde salen los 970 lotes?",
    "¿Dónde caen los lotes?", "¿Cuánto explica cada eje?", "¿Cómo se asocian las categorías?", "¿Cuántos grupos buscar?",
    "¿Qué grupos produce K-means?", "¿Hay zonas densas?", "¿Qué muestra el árbol?", "¿Dónde caería un lote nuevo?", "¿Respondimos el objetivo?", "—"),
  clave = c("1.070 lotes del CQI", "174 lotes con humedad 0", "4 etapas; 8 variables", "100 atípicos retirados (9,3 %); quedan 970",
    "Una sola nube continua", "CP1 69,3 %; CP1+CP2 80,9 %", "Eje 1: datos sin registrar; eje 2: Brasil/natural frente a lavado",
    "Silueta máxima con k = 2; el gap elige k = 1", "Silueta 0,116; 104 lotes negativos", "58,5 % de ruido",
    "ARI 0,471 con K-means", "Percentil y regresión sobre CP1", "Calidad en 2 dimensiones; sin grupos naturales", "—"),
  stringsAsFactors = FALSE)
fila <- function(r) sprintf("<tr><td>%d</td><td>%s</td><td><strong>%s</strong></td><td>%s</td><td>%s</td></tr>",
  r$d, slides[[r$d]]$pers, esc(r$tema), esc(r$pregunta), esc(r$clave))
tabla <- paste(vapply(seq_len(nrow(resumen)), function(k) fila(resumen[k, ]), character(1)), collapse = "\n")

tot <- tapply(vapply(slides, function(s) a_seg(s$dur), numeric(1)), vapply(slides, function(s) s$pers, character(1)), sum)
reparto <- paste(sprintf('<div class="rep"><span class="chip %s">%s</span><span class="big">%s</span><span class="sub">%s</span></div>',
  clase[names(tot)], quien[names(tot)], vapply(tot, a_txt, character(1)),
  c(Diego = "diapositivas 5 a 8", Esteban = "diapositivas 9 a 12", Juan = "diapositivas 1 a 4, 13 y 14")[names(tot)]), collapse = "")
reparto <- paste(sprintf('<div class="rep"><span class="chip %s">%s</span><span class="big">%s</span><span class="sub">%s</span></div>',
  clase[c("Juan", "Diego", "Esteban")], quien[c("Juan", "Diego", "Esteban")], vapply(tot[c("Juan", "Diego", "Esteban")], a_txt, character(1)),
  c("diapositivas 1 a 4, 13 y 14", "diapositivas 5 a 8", "diapositivas 9 a 12")), collapse = "")

# ---- antes de ensayar y apoyo -----------------------------------------------
i_ae <- grep("^## Antes de ensayar", principal)
ae <- principal[(i_ae + 1):length(principal)]
ae <- ae[grepl("^- ", ae)]
ae_html <- paste(sprintf("<li>%s</li>", md(sub("^- ", "", ae))), collapse = "")

enc_ap <- grep("^## ", apoyo)
fin_ap <- c(enc_ap[-1] - 1, length(apoyo))
quien_ap <- function(t) { n <- as.integer(sub("^## Diapositivas? ([0-9]+).*", "\\1", t)); if (is.na(n)) "Juan" else if (n <= 4) "Juan" else if (n <= 8) "Diego" else if (n <= 12) "Esteban" else "Juan" }
apoyo_html <- character()
for (k in seq_along(enc_ap)) {
  b <- apoyo[enc_ap[k]:fin_ap[k]]
  t <- sub("^## ", "", b[1]); lis <- b[grepl("^- ", b)]
  if (!length(lis)) next
  p <- quien_ap(b[1])
  apoyo_html <- c(apoyo_html, sprintf('<div class="card apoyo"><div class="head"><span class="t">%s</span><span class="chip %s">Responde %s</span></div><ul>%s</ul></div>',
    esc(t), clase[[p]], quien[[p]], paste(sprintf("<li>%s</li>", md(sub("^- ", "", lis))), collapse = "")))
}

# ---- documento ---------------------------------------------------------------
css <- '
@page { size: A4; margin: 16mm 14mm 16mm 14mm; }
* { box-sizing: border-box; }
body { font-family: "Segoe UI", Arial, sans-serif; color: #3a3029; font-size: 10.5pt; line-height: 1.5; margin: 0; }
h1 { font-family: Georgia, "Times New Roman", serif; font-size: 27pt; color: #5b3a1e; margin: 0 0 4px; }
.sub { color: #8a7c6e; }
.meta { color: #8a7c6e; margin: 0 0 10px; }
.chips span.c { display: inline-block; margin-right: 14px; font-size: 9.5pt; color: #6d5d4e; }
.hilo { border-left: 4px solid #d4a24c; padding: 8px 0 8px 14px; margin: 14px 0 16px; color: #4a3d33; }
.hilo strong { color: #3a2a1a; }
.reparto { display: flex; gap: 10px; margin: 8px 0 6px; }
.rep { flex: 1; border: 1px solid #e3d6c6; border-radius: 10px; padding: 8px 12px; background: #fcf9f4; }
.rep .big { display: block; font-family: Georgia, serif; font-size: 18pt; color: #5b3a1e; margin-top: 4px; }
.rep .sub { font-size: 9pt; }
.bloque { display: flex; justify-content: space-between; align-items: baseline; margin: 20px 0 8px; break-after: avoid; }
.bn { font-family: Georgia, serif; font-size: 14pt; font-weight: bold; color: #6b4423; }
.bt { font-size: 10pt; color: #6b4423; font-weight: 600; }
.card { border: 1.4px solid #5b4636; border-radius: 12px; padding: 10px 16px 8px; margin: 0 0 10px; break-inside: avoid; box-shadow: 0 2px 5px rgba(0,0,0,.18); background: #fff; }
.head { display: flex; align-items: baseline; gap: 10px; }
.n { font-weight: 700; color: #6b4423; width: 20px; }
.t { font-weight: 600; flex: 1; color: #3a3029; }
.tm { color: #8a7c6e; font-size: 9.5pt; }
.quien { margin: 6px 0 2px 30px; font-size: 9pt; color: #8a7c6e; }
.chip { display: inline-block; padding: 1px 9px; border-radius: 99px; font-size: 8.5pt; font-weight: 600; margin-right: 8px; color: #fff; }
.chip.juan, .spk.juan { background: #8a5a2b; }
.chip.diego, .spk.diego { background: #2f7d6b; }
.chip.esteban, .spk.esteban { background: #3d6aa5; }
.q { font-style: italic; color: #8a5a2b; margin: 6px 0 6px 30px; }
.linea { display: flex; gap: 9px; margin: 5px 0 5px 30px; align-items: flex-start; }
.linea p { margin: 0; flex: 1; }
.spk { flex: none; font-size: 7.5pt; font-weight: 700; color: #fff; padding: 2px 7px; border-radius: 4px; margin-top: 2px; letter-spacing: .4px; }
.trans, .accion { margin: 6px 0 4px 30px; font-size: 9.5pt; padding: 4px 10px; border-radius: 6px; }
.trans { background: #f4efe7; color: #5b4636; }
.accion { background: #eef5f2; color: #24574a; }
.lab { font-weight: 700; margin-right: 6px; }
.tags { margin: 8px 0 2px 30px; }
.tags span { display: inline-block; font-size: 8.5pt; color: #8a7c6e; background: #f4efe7; padding: 1px 8px; border-radius: 4px; margin-right: 6px; }
h2 { font-family: Georgia, serif; color: #6b4423; font-size: 15pt; margin: 26px 0 8px; break-after: avoid; }
table { border-collapse: collapse; width: 100%; font-size: 9.5pt; }
th { text-align: left; font-size: 8pt; letter-spacing: .6px; color: #8a7c6e; padding: 6px 6px; border-bottom: 1px solid #cdbfae; text-transform: uppercase; }
td { padding: 7px 6px; border-bottom: 1.5px solid #5b4636; vertical-align: top; }
tr { break-inside: avoid; }
.antes { background: #fcf9f4; border: 1px solid #e3d6c6; border-radius: 10px; padding: 8px 16px; }
.antes li { margin: 4px 0; }
.apoyo ul { margin: 6px 0 4px 26px; padding-left: 16px; }
.apoyo li { margin: 3px 0; font-size: 9.5pt; }
.apoyo .head { justify-content: space-between; }
code { background: #f4efe7; padding: 0 4px; border-radius: 3px; font-size: 9pt; }
.salto { break-before: page; }
'
html <- sprintf('<!doctype html><html lang="es"><head><meta charset="utf-8"><title>Guion — Exposición 10 min</title><style>%s</style></head><body>
<h1>Guion — Exposición 10 min</h1>
<p class="meta">Analítica y Métodos Multivariados · Dataset CQI Café Arábica · ECI Ingeniería Estadística</p>
<div class="chips"><span class="c">14 diapositivas</span><span class="c">10 min de exposición</span><span class="c">3 expositores</span><span class="c">1.070 lotes · 8 variables</span></div>
<div class="hilo"><strong>Hilo conductor:</strong> una sola pregunta guía toda la presentación: <em>¿se puede resumir la calidad del café en pocas dimensiones y existen grupos reales entre los lotes?</em> Primero la base y su preparación; luego qué resume el PCA; después los métodos de agrupamiento; y al final la herramienta interactiva y las conclusiones. Cada tarjeta muestra <strong>quién habla</strong>, cuánto dura y lo que dice, palabra por palabra.</div>
<div class="reparto">%s</div>
%s
<h2 class="salto">Resumen: quién dice qué y qué se concluye</h2>
<table><thead><tr><th>Slide</th><th>Presenta</th><th>Tema</th><th>Pregunta que responde</th><th>Resultado clave</th></tr></thead><tbody>%s</tbody></table>
<h2>Antes de ensayar</h2><div class="antes"><ul>%s</ul></div>
<h2 class="salto">Apoyo para preguntas <span class="sub" style="font-size:10pt">(no se lee)</span></h2>
%s
</body></html>', css, reparto, paste(cuerpo_html, collapse = "\n"), tabla, ae_html, paste(apoyo_html, collapse = "\n"))
writeLines(html, "guion_dialogo_AMMV.html", useBytes = TRUE)

# ---- PDF con Edge o Chrome headless -----------------------------------------
nav <- c("C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe", "C:/Program Files/Microsoft/Edge/Application/msedge.exe",
         "C:/Program Files/Google/Chrome/Application/chrome.exe")
nav <- nav[file.exists(nav)][1]
if (is.na(nav)) { cat("HTML generado; no hay Edge ni Chrome para crear el PDF.\n") } else {
  ruta <- normalizePath("guion_dialogo_AMMV.html", winslash = "/")
  salida <- file.path(normalizePath(".", winslash = "/"), "guion_dialogo_AMMV.pdf")
  system2(nav, c("--headless", "--disable-gpu", "--no-pdf-header-footer", paste0('--print-to-pdf="', salida, '"'), paste0("file:///", ruta)), stdout = FALSE, stderr = FALSE)
  cat(if (file.exists(salida)) paste("PDF generado:", salida, "\n") else "No se pudo generar el PDF.\n")
}
