# Respuesta al informe de revisión, parte 3: matrices policóricas y umbrales de los
# 17 ítems, en la muestra completa y por grupo, para reproducir los modelos sin
# acceder a los microdatos. Escribe output/reproducibilidad/*.csv
suppressPackageStartupMessages({ library(tidyverse); library(haven); library(here); library(lavaan) })
db_proc <- readRDS(here("input", "data", "proc", "db_proc.rds"))
items17 <- c("O2_11", "O2_12", "O3_4", "O3_7", "O3_2", "O3_3", "O3_5", "O3_8", "O3_9",
             "O2_1", "O2_2", "O2_3", "O2_4", "O2_5", "O1_10", "O2_8", "O2_9")
d <- db_proc %>%
  transmute(Sexo = factor(as.numeric(SEXO), 1:2, c("Hombre", "Mujer")),
            Edad = cut(as.numeric(EDADR), c(1, 3, 5, 7), c("18-34", "35-54", "55 o más")),
            NSE  = cut(as.numeric(NSE), c(0, 3, 5, 7), c("ABC1", "C2-C3", "D-E")),
            across(all_of(items17), ~ as.numeric(zap_labels(db_proc[[cur_column()]]))))
dir <- here("output", "reproducibilidad"); dir.create(dir, showWarnings = FALSE)
guardar <- function(datos, etiqueta) {
  st <- lavCor(datos[, items17], ordered = items17, output = "sampstat")
  write_csv(as_tibble(unclass(st$cov), rownames = "item"), file.path(dir, paste0("policoricas_", etiqueta, ".csv")))
  write_csv(tibble(umbral = names(st$th), valor = as.numeric(st$th), n = nrow(datos)),
            file.path(dir, paste0("umbrales_", etiqueta, ".csv")))
}
guardar(d, "muestra_completa")
for (g in c("Sexo", "Edad", "NSE")) for (niv in levels(d[[g]]))
  guardar(d[d[[g]] == niv, ], paste0(g, "_", str_replace_all(iconv(niv, to = "ASCII//TRANSLIT"), "[^A-Za-z0-9]+", "")))
