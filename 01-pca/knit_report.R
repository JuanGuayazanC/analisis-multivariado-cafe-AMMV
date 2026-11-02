Sys.setenv(RSTUDIO_PANDOC = "C:/Program Files/RStudio/resources/app/bin/quarto/bin/tools")
rmarkdown::render("C:/Users/jsegu/Documents/2026/AMMV/Proyecto/coffee-quality-database/01-pca/informe_despues.Rmd",
                  output_format = "html_document")
