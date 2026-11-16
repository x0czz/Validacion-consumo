# Respuesta al informe de revisión (paper de medición), parte 2: análisis complementarios.
#   1. Registro de la depuración estricta (escalas breves, mitad 1).
#   2. Validez discriminante: HTMT.
#   3. Determinación de los puntajes factoriales y correlación con puntajes suma.
#   4. Categorías observadas por grupo.
#   5. Calidad de datos: respuestas rápidas y en línea recta; sensibilidad sin esos casos.
#   6. Sensibilidad sin colapsar categorías.
#   7. Validez con indicadores de situación económica y sensibilidad de la posición política.
# Escribe output/tables/informe_*.csv
suppressPackageStartupMessages({
  library(tidyverse); library(haven); library(here); library(psych); library(GPArotation)
  library(lavaan); library(semTools)
})
dir_tab <- here("output", "tables")
db_proc <- readRDS(here("input", "data", "proc", "db_proc.rds"))
original <- read_sav(here("input", "data", "original", "Encuesta Sociedad de Consumo 2023.sav"))
stopifnot(identical(db_proc$key, original$key))
num <- function(x) as.numeric(zap_labels(x))

items <- db_proc %>% select(matches("^O[1-4]_\\d+$")) %>% mutate(across(everything(), num))
afe_obj <- readRDS(here("output", "models", "afe_5factores.rds"))
idx_m1 <- afe_obj$idx_mitad1

m_pub <- 'compra_sust =~ O2_11 + O2_12 + O3_4 + O3_7
          consumo_pol =~ O3_2 + O3_3 + O3_5 + O3_8 + O3_9'
m_dom <- 'ahorro =~ O2_1 + O2_2 + O2_3 + O2_4 + O2_5
          planificacion =~ O1_10 + O2_8 + O2_9'
escalas <- list("Consumo sustentable y político" = m_pub, "Prácticas domésticas" = m_dom)
items17 <- c("O2_11", "O2_12", "O3_4", "O3_7", "O3_2", "O3_3", "O3_5", "O3_8", "O3_9",
             "O2_1", "O2_2", "O2_3", "O2_4", "O2_5", "O1_10", "O2_8", "O2_9")
ajustar <- function(m, d) cfa(m, data = d, ordered = TRUE, estimator = "WLSMV")
indices <- c("chisq.scaled", "df", "cfi.scaled", "tli.scaled", "rmsea.scaled", "srmr")

# ---------------------------------------------------------------------------
# 1. Depuración estricta (carga ≥ ,50, sin cargas cruzadas ≥ ,30), mitad 1, 3 a 5 factores
# ---------------------------------------------------------------------------
R_m1 <- polychoric(items[idx_m1, ])$rho
depurar_registro <- function(k, umbral = .50) {
  vars <- colnames(R_m1); reg <- tibble()
  repeat {
    f <- fa(R_m1[vars, vars], nfactors = k, n.obs = length(idx_m1), fm = "minres", rotate = "oblimin")
    L <- abs(unclass(f$loadings)); cm <- apply(L, 1, max); cr <- apply(L >= .30, 1, sum)
    malos <- names(cm)[cm < umbral | cr >= 2]
    if (!length(malos)) break
    peor <- malos[which.min(cm[malos] - 0.1 * (cr[malos] >= 2))]
    reg <- bind_rows(reg, tibble(factores = k, paso = nrow(reg) + 1, item = peor, carga_max = cm[peor],
                                 motivo = if_else(cr[peor] >= 2, "Carga cruzada", "Carga máxima < ,50")))
    vars <- setdiff(vars, peor)
  }
  L <- unclass(f$loadings); prim <- apply(abs(L), 1, which.max)
  list(registro = reg,
       final = tibble(factores = k, item = names(prim), factor = paste0("F", prim),
                      carga = L[cbind(seq_along(prim), prim)]))
}
estricta <- map(3:5, depurar_registro)
write_csv(map_dfr(estricta, "registro"), file.path(dir_tab, "informe_breve_registro.csv"))
write_csv(map_dfr(estricta, "final"), file.path(dir_tab, "informe_breve_final.csv"))

# ---------------------------------------------------------------------------
# 2. HTMT (muestra completa, correlaciones policóricas)
# ---------------------------------------------------------------------------
R_full <- polychoric(items[, items17])$rho
htmt_val <- htmt(paste(m_pub, m_dom, sep = "\n"), sample.cov = R_full)
write_csv(as_tibble(as.matrix(htmt_val), rownames = "factor"), file.path(dir_tab, "informe_htmt.csv"))

# ---------------------------------------------------------------------------
# 3. Determinación de los puntajes factoriales (sobre la matriz de respuestas latentes
#    implicada por el modelo) y correlación entre puntajes suma y puntajes factoriales
# ---------------------------------------------------------------------------
fits_full <- map(escalas, ~ ajustar(.x, items))
determinacion <- imap_dfr(fits_full, function(f, escala) {
  est <- lavInspect(f, "std")
  L <- est$lambda; Phi <- est$psi; Sigma <- lavInspect(f, "cor.ov")
  rho <- sqrt(diag(Phi %*% t(L) %*% solve(Sigma) %*% L %*% Phi))
  fs <- lavPredict(f, method = "EBM")
  map_dfr(colnames(L), function(fac) {
    its <- rownames(L)[L[, fac] != 0]
    suma <- rowMeans(items[, its])
    tibble(escala, factor = fac, determinacion = rho[fac],
           r_suma_factorial = cor(suma, fs[, fac]),
           alfa_ordinal = psych::alpha(polychoric(items[, its])$rho, warnings = FALSE)$total$raw_alpha)
  })
})
write_csv(determinacion, file.path(dir_tab, "informe_determinacion.csv"))

# ---------------------------------------------------------------------------
# 4. Categorías observadas en cada grupo (17 ítems)
# ---------------------------------------------------------------------------
grupos <- db_proc %>%
  transmute(Sexo = factor(num(SEXO), 1:2, c("Hombre", "Mujer")),
            Edad = cut(num(EDADR), c(1, 3, 5, 7), c("18-34", "35-54", "55 o más")),
            NSE  = cut(num(NSE), c(0, 3, 5, 7), c("ABC1", "C2-C3", "D-E")))
celdas <- map_dfr(names(grupos), function(g) map_dfr(items17, function(it) {
  tab <- table(grupos[[g]], items[[it]])
  as_tibble(as.data.frame(tab)) %>% transmute(variable = g, grupo = as.character(Var1), item = it,
                                              categoria = as.character(Var2), n = Freq)
}))
write_csv(celdas %>% group_by(variable, item) %>% slice_min(n, n = 1, with_ties = FALSE) %>% ungroup(),
          file.path(dir_tab, "informe_celdas_minimas.csv"))
write_csv(celdas, file.path(dir_tab, "informe_celdas.csv"))

# ---------------------------------------------------------------------------
# 5. Calidad de datos
# ---------------------------------------------------------------------------
orig_items <- original %>% select(matches("^O[1-3]_\\d+$")) %>% mutate(across(everything(), num))
linea_recta <- function(prefijo) apply(orig_items %>% select(starts_with(prefijo)), 1, function(x) sd(x) == 0)
dur <- as.numeric(original$duration)
calidad <- tibble(
  duracion_min = dur / 60,
  rapido_50 = dur < .5 * median(dur), rapido_33 = dur < median(dur) / 3,
  recta_O1 = linea_recta("O1_"), recta_O2 = linea_recta("O2_"), recta_O3 = linea_recta("O3_"),
  movil = num(original$DEVICE))
calidad <- calidad %>% mutate(n_rectas = recta_O1 + recta_O2 + recta_O3,
                              excluir = rapido_33 | n_rectas >= 2)
resumen_calidad <- tibble(
  indicador = c("Mediana de duración (min)", "Duración < 50% de la mediana", "Duración < 1/3 de la mediana",
                "Línea recta en O1 (10 ítems)", "Línea recta en O2 (14 ítems)", "Línea recta en O3 (10 ítems)",
                "Línea recta en dos o más baterías", "Casos marcados (rápidos < 1/3 o línea recta en ≥ 2 baterías)"),
  valor = c(median(calidad$duracion_min), sum(calidad$rapido_50), sum(calidad$rapido_33),
            sum(calidad$recta_O1), sum(calidad$recta_O2), sum(calidad$recta_O3),
            sum(calidad$n_rectas >= 2), sum(calidad$excluir)))
write_csv(resumen_calidad, file.path(dir_tab, "informe_calidad.csv"))

comparar <- function(lista_fits, etiqueta) {
  imap_dfr(lista_fits, function(f, escala) {
    tibble(analisis = etiqueta, escala, n = lavInspect(f, "nobs"), !!!as.list(fitMeasures(f, indices)),
           carga_min = min(standardizedSolution(f)$est.std[standardizedSolution(f)$op == "=~"]),
           r_factores = standardizedSolution(f)$est.std[standardizedSolution(f)$op == "~~" &
                                                          standardizedSolution(f)$lhs != standardizedSolution(f)$rhs])
  })
}
mitad2 <- items[-idx_m1, ]
sens <- bind_rows(
  comparar(fits_full, "Publicado (muestra completa)"),
  comparar(map(escalas, ~ ajustar(.x, items[!calidad$excluir, ])), "Sin casos de baja calidad (muestra completa)"),
  comparar(map(escalas, ~ ajustar(.x, mitad2)), "Publicado (mitad 2)"),
  comparar(map(escalas, ~ ajustar(.x, orig_items[-idx_m1, ])), "Sin colapsar categorías (mitad 2)"),
  comparar(map(escalas, ~ ajustar(.x, orig_items)), "Sin colapsar categorías (muestra completa)"))
write_csv(sens, file.path(dir_tab, "informe_sensibilidad.csv"))

cargas_comp <- bind_rows(
  standardizedSolution(fits_full[[1]]) %>% bind_rows(standardizedSolution(fits_full[[2]])) %>%
    filter(op == "=~") %>% transmute(item = rhs, colapsado = est.std),
) %>% left_join(
  map_dfr(escalas, ~ standardizedSolution(ajustar(.x, orig_items)) %>% filter(op == "=~")) %>%
    transmute(item = rhs, sin_colapsar = est.std), by = "item")
write_csv(cargas_comp, file.path(dir_tab, "informe_cargas_sin_colapsar.csv"))

# ---------------------------------------------------------------------------
# 7. Validez con indicadores de situación económica (variables continuas de un indicador)
#    E2 ingreso del hogar (1-5; "prefiero no responder" = perdido), deuda para alimentos
#    (principal o segundo motivo de deuda), más endeudado que hace tres años (M15 = 1).
#    Además: posición política excluyendo el punto medio (5), muy frecuente.
# ---------------------------------------------------------------------------
motivo <- function(v) as.character(as_factor(original[[v]]))
d_eco <- items %>% bind_cols(tibble(
  ingreso = num(original$E2),
  deuda_alimentos = as.numeric(coalesce(motivo("M16R_1") == "Supermercado/Alimentos", FALSE) |
                               coalesce(motivo("M16R_2") == "Supermercado/Alimentos", FALSE)),
  mas_endeudado = as.numeric(num(original$M15) == 1),
  M9 = num(original$M9), C3_14 = num(original$C3_14)))
d_eco$ingreso[d_eco$ingreso > 5] <- NA
externas <- function(vars) paste(sprintf("%s_l =~ 1*%s\n%s ~~ 0*%s", vars, vars, vars, vars), collapse = "\n")
validez_eco <- imap_dfr(escalas, function(m, escala) {
  ords <- str_extract_all(m, "O\\d_\\d+")[[1]]
  map_dfr(list(ingreso = "ingreso", deuda_alimentos = "deuda_alimentos", mas_endeudado = "mas_endeudado"),
          function(v) {
            d <- d_eco %>% filter(!is.na(.data[[v]]))
            # Variables binarias: ordinales, con varianza de la variable latente fijada en 1
            # (equivale a una correlación tetracórica/policórica con los factores)
            if (v == "ingreso") {
              f <- cfa(paste(m, externas(v), sep = "\n"), data = d, ordered = ords, estimator = "WLSMV")
            } else {
              f <- cfa(paste(m, sprintf("%s_l =~ 1*%s\n%s_l ~~ 1*%s_l", v, v, v, v), sep = "\n"),
                       data = d, ordered = c(ords, v), estimator = "WLSMV")
            }
            stopifnot(lavInspect(f, "post.check"))
            standardizedSolution(f) %>% filter(op == "~~", rhs == paste0(v, "_l") | lhs == paste0(v, "_l"),
                                               lhs != rhs) %>%
              transmute(escala, factor = if_else(lhs == paste0(v, "_l"), rhs, lhs), variable = v,
                        n = nrow(d), r = est.std, ic_inf = ci.lower, ic_sup = ci.upper, p = pvalue)
          })
})
# Posición política sin el punto medio
validez_m9 <- imap_dfr(escalas, function(m, escala) {
  ords <- str_extract_all(m, "O\\d_\\d+")[[1]]
  d <- d_eco %>% filter(M9 != 5)
  f <- cfa(paste(m, externas(c("M9", "C3_14")), sep = "\n"), data = d, ordered = ords, estimator = "WLSMV")
  standardizedSolution(f) %>% filter(op == "~~", rhs %in% c("M9_l", "C3_14_l"), !lhs %in% c("M9_l", "C3_14_l")) %>%
    transmute(escala, factor = lhs, variable = paste0(rhs, " (sin M9 = 5)"), n = nrow(d), r = est.std,
              ic_inf = ci.lower, ic_sup = ci.upper, p = pvalue)
})
write_csv(bind_rows(validez_eco, validez_m9), file.path(dir_tab, "informe_validez_economica.csv"))
write_csv(tibble(M9 = names(table(d_eco$M9)), n = as.integer(table(d_eco$M9))), file.path(dir_tab, "informe_m9_distribucion.csv"))
