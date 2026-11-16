# Genera los PDF completos de los preprints en la carpeta preprints/:
#   - Medición: solo el artículo (el anexo metodológico y el suplemento se renderizan
#     aparte y se publican en el repositorio, enlazados desde el preprint).
#   - Clases latentes: artículo + material suplementario.
# Uso: abrir el proyecto y ejecutar source("render_preprints.R"), o en la terminal:
#   Rscript render_preprints.R
# Antes: python processing/generar_preprint_medicion.py y processing/generar_preprint_clases.py
# si se editaron paper_medicion.qmd o paper_clases.qmd.
# Requisitos: Quarto >= 1.4 (incluye Typst, no necesita LaTeX) y los paquetes de R
# tidyverse, here, knitr, haven y qpdf. Los documentos solo leen los resultados ya
# guardados en output/tables/; no reestiman los modelos.
# Nota: anexo_metodologico_medicion.qmd es un archivo propio (ya no se genera desde
# paper_medicion.qmd) y contiene los procedimientos y resultados técnicos completos.
if (!requireNamespace("qpdf", quietly = TRUE)) install.packages("qpdf")

renderizar <- function(qmd) {
  message("Renderizando ", qmd, " ...")
  estado <- system2("quarto", c("render", qmd, "--to", "typst"))
  if (estado != 0) stop("Falló el render de ", qmd)
  sub("\\.qmd$", ".pdf", qmd)
}
dir.create("preprints", showWarnings = FALSE)

# Medición: el preprint va solo; el anexo metodológico y el suplemento se publican aparte
# en el repositorio, y el preprint enlaza a ellos.
medicion <- vapply(c("preprint_medicion.qmd", "anexo_metodologico_medicion.qmd", "suplemento_medicion.qmd"),
                   renderizar, character(1))
file.copy(medicion[1], "preprints/Marambio_Outerbridge_2026_medicion_preprint.pdf", overwrite = TRUE)

clases <- vapply(c("preprint_clases.qmd", "suplemento_clases.qmd"), renderizar, character(1))
qpdf::pdf_combine(clases, output = "preprints/Marambio_Outerbridge_2026_clases_preprint.pdf")

message("Listo: los PDF completos están en la carpeta preprints/.")
