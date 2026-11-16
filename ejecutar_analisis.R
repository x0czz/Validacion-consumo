# Reproduce todos los análisis de los dos artículos, en orden, desde los datos originales.
# Uso: abrir el proyecto en RStudio/Positron y ejecutar source("ejecutar_analisis.R").
#
# Funciona con la versión de R y de los paquetes que tenga instalados. Los resultados
# publicados se obtuvieron con R 4.3.3, lavaan 0.6-17, semTools 0.5-6, psych 2.4.1 y
# poLCA 1.6.0.2; con otras versiones pueden variar algunos decimales. Para comparar,
# el script guarda una copia de las tablas actuales en output/tables_publicado/ y al
# final compara cada cifra con la nueva estimación (output/comparacion_versiones.csv).
# Para usar exactamente las versiones publicadas, ver REPRODUCIR.md (renv).
#
# Requisitos: la base original en input/data/original/Encuesta Sociedad de Consumo 2023.sav
# (no está en el repositorio público) y Quarto (>= 1.4).
#
# Duración aproximada: 40 a 60 minutos; la estimación de clases latentes con 100
# inicios aleatorios toma unos 25 minutos.

reestimar_clases_latentes <- TRUE   # FALSE reutiliza output/models/lca_enumeracion.rds

stopifnot(file.exists(file.path("input", "data", "original", "Encuesta Sociedad de Consumo 2023.sav")))

# Instala solo los paquetes que falten (sin cambiar los que ya tiene)
necesarios <- c("tidyverse", "here", "haven", "knitr", "rmarkdown", "psych", "GPArotation", "lavaan",
                "semTools", "poLCA", "mclust", "ggforce", "qpdf", "kableExtra", "labelled", "callr")
faltan <- necesarios[!vapply(necesarios, requireNamespace, logical(1), quietly = TRUE)]
if (length(faltan)) install.packages(faltan)

publicado <- c(R = "4.3.3", lavaan = "0.6.17", semTools = "0.5.6", psych = "2.4.1", poLCA = "1.6.0.2")
actual <- c(R = as.character(getRversion()),
            vapply(names(publicado)[-1], function(p) as.character(packageVersion(p)), character(1)))
message("Versiones usadas ahora (y las del análisis publicado):")
print(data.frame(actual = actual, publicado = publicado))

# Copia de las tablas actuales para comparar al final (solo la primera vez)
dir_pub <- file.path("output", "tables_publicado")
if (!dir.exists(dir_pub) && dir.exists(file.path("output", "tables"))) {
  dir.create(dir_pub)
  file.copy(list.files(file.path("output", "tables"), full.names = TRUE), dir_pub)
}

quarto <- function(f) {
  message("\n== Renderizando ", f)
  if (system2("quarto", c("render", f)) != 0) stop("Falló ", f)
}
script <- function(f) {
  message("\n== Ejecutando ", f)
  t0 <- Sys.time()
  callr_ok <- requireNamespace("callr", quietly = TRUE)
  # Cada script corre en una sesión limpia para que no dependa de objetos de pasos anteriores
  if (callr_ok) callr::rscript(f, show = TRUE) else source(f, local = new.env())
  message("   listo en ", round(difftime(Sys.time(), t0, units = "mins"), 1), " min")
}

# 1. Preparación de datos: colapso de categorías poco frecuentes -> input/data/proc/db_proc.rds
quarto("processing/prep_colapso_10.qmd")
# 2. Análisis factorial exploratorio y confirmatorio (división aleatoria en mitades)
quarto("processing/analisis_factorial.qmd")
# 3. Invarianza de medida por sexo, edad y NSE
quarto("processing/invarianza.qmd")
# 4. Clases latentes (estima los modelos si no existen)
if (reestimar_clases_latentes) unlink(file.path("output", "models", "lca_enumeracion.rds"))
quarto("processing/clases_latentes.qmd")
# 5. Análisis complementarios del artículo de medición
script("processing/revision_medicion.R")
script("processing/revision_informe_1.R")   # funcionamiento diferencial, Holm, anclas, ESEM
script("processing/revision_informe_2.R")   # HTMT, determinación, calidad, sensibilidad, validez económica
script("processing/revision_informe_3.R")   # matrices policóricas y umbrales para reproducir sin microdatos
script("processing/indices_robustos.R")
script("processing/verificacion_reproducibilidad.R")
script("processing/salidas_tecnicas.R")     # salidas completas de R en output/resultados_tecnicos/
script("processing/figura_esquema.R")
script("processing/sensibilidad_esem_covariables.R")  # correlaciones con covariables: AFC frente a ESEM
# 6. Análisis complementarios del artículo de clases latentes
script("processing/revision_clases.R")

# 7. Comparación con las cifras publicadas
if (dir.exists(dir_pub)) {
  suppressPackageStartupMessages(library(tidyverse))
  comparar <- function(archivo) {
    a <- tryCatch(read_csv(file.path(dir_pub, archivo), show_col_types = FALSE), error = function(e) NULL)
    b <- tryCatch(read_csv(file.path("output", "tables", archivo), show_col_types = FALSE), error = function(e) NULL)
    if (is.null(a) || is.null(b) || !identical(dim(a), dim(b))) {
      return(tibble(archivo, columna = NA_character_, max_diferencia = NA_real_,
                    nota = "No comparable (falta el archivo o cambió su forma)"))
    }
    num <- intersect(names(a)[vapply(a, is.numeric, logical(1))], names(b)[vapply(b, is.numeric, logical(1))])
    if (!length(num)) return(tibble())
    map_dfr(num, ~ tibble(archivo, columna = .x, max_diferencia = max(abs(a[[.x]] - b[[.x]]), na.rm = TRUE), nota = ""))
  }
  comp <- map_dfr(list.files(dir_pub, pattern = "\\.csv$"), comparar) %>%
    mutate(max_diferencia = if_else(is.infinite(max_diferencia), NA_real_, max_diferencia)) %>%
    arrange(desc(max_diferencia))
  write_csv(comp, file.path("output", "comparacion_versiones.csv"))
  message("\nComparación con las cifras publicadas (output/comparacion_versiones.csv).")
  message("Columnas con diferencias mayores que 0,001: ", sum(comp$max_diferencia > .001, na.rm = TRUE),
          " de ", nrow(comp), ".")
  print(head(comp %>% filter(max_diferencia > .001), 20))
}

message("\nAnálisis completos. Para generar los PDF de los preprints: source(\"render_preprints.R\")")
