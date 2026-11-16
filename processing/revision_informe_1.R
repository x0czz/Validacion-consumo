# Respuesta al informe de revisión (paper de medición), parte 1: análisis que pueden
# cambiar las conclusiones.
#   1. DIF de interceptos por NSE: índices de modificación, dMACS ordinal y medias
#      latentes al liberar cada intercepto (incluye la sensibilidad para O2.5).
#   2. Corrección de Holm para las diferencias de medias latentes.
#   3. Sensibilidad de las diferencias por edad a la elección de ítems ancla.
#   4. ESEM y bifactor-ESEM de los 17 ítems en la mitad confirmatoria.
# Escribe output/tables/informe_*.csv
suppressPackageStartupMessages({
  library(tidyverse); library(haven); library(here); library(lavaan); library(semTools)
})
dir_tab <- here("output", "tables")
db_proc <- readRDS(here("input", "data", "proc", "db_proc.rds"))
datos <- db_proc %>%
  mutate(sexo = factor(as.numeric(SEXO), levels = 1:2, labels = c("Hombre", "Mujer")),
         edad = cut(as.numeric(EDADR), breaks = c(1, 3, 5, 7), labels = c("18-34", "35-54", "55 o más")),
         nse  = cut(as.numeric(NSE), breaks = c(0, 3, 5, 7), labels = c("ABC1", "C2-C3", "D-E")),
         across(matches("^O[1-4]_\\d+$"), ~ as.numeric(zap_labels(.x))))

modelos <- list(
  "Consumo sustentable y político" = '
    compra_sust =~ O2_11 + O2_12 + O3_4 + O3_7
    consumo_pol =~ O3_2 + O3_3 + O3_5 + O3_8 + O3_9',
  "Prácticas domésticas" = '
    ahorro        =~ O2_1 + O2_2 + O2_3 + O2_4 + O2_5
    planificacion =~ O1_10 + O2_8 + O2_9')
factor_de <- c(O2_11 = "compra_sust", O2_12 = "compra_sust", O3_4 = "compra_sust", O3_7 = "compra_sust",
               O3_2 = "consumo_pol", O3_3 = "consumo_pol", O3_5 = "consumo_pol", O3_8 = "consumo_pol",
               O3_9 = "consumo_pol", O2_1 = "ahorro", O2_2 = "ahorro", O2_3 = "ahorro", O2_4 = "ahorro",
               O2_5 = "ahorro", O1_10 = "planificacion", O2_8 = "planificacion", O2_9 = "planificacion")
indices <- c("chisq.scaled", "df", "cfi.scaled", "tli.scaled", "rmsea.scaled", "srmr")

# --- Funciones de invarianza (idénticas a processing/invarianza.qmd) ---
datos_por <- function(grupo) datos %>% arrange(.data[[grupo]])
items_de <- function(modelo) lavNames(cfa(modelo, data = datos), "ov")
sintaxis_escalar <- function(modelo, grupo) {
  as.character(measEq.syntax(
    configural.model = modelo, data = datos_por(grupo), ordered = items_de(modelo),
    parameterization = "theta", ID.fac = "std.lv", ID.cat = "Wu.Estabrook.2016",
    group = grupo, group.equal = c("thresholds", "loadings", "intercepts")))
}
liberar_intercepto <- function(sintaxis, item, n_grupos) {
  lineas <- strsplit(sintaxis, "\n")[[1]]
  objetivo <- grepl(paste0("^", item, " ~ c\\("), lineas) & grepl("\\*1", lineas)
  stopifnot(sum(objetivo) == 1)
  lineas[objetivo] <- paste0(item, " ~ c(0, ", paste(rep("NA", n_grupos - 1), collapse = ", "), ")*1")
  paste(lineas, collapse = "\n")
}
estimar <- function(sintaxis, modelo, grupo) {
  cfa(sintaxis, data = datos_por(grupo), group = grupo, ordered = items_de(modelo),
      group.label = levels(datos[[grupo]]), estimator = "WLSMV", parameterization = "theta")
}
medias_latentes <- function(f) {
  parameterEstimates(f) %>%
    filter(op == "~1", lhs %in% lavNames(f, "lv"), group > 1) %>%
    transmute(grupo = lavInspect(f, "group.label")[group], factor = lhs,
              media = est, ee = se, ic_inf = ci.lower, ic_sup = ci.upper, p = pvalue)
}

# dMACS para ítems ordinales (Nye y Drasgow, 2011, adaptado a la escala de respuesta
# esperada): raíz del promedio, sobre la distribución latente del grupo focal, de la
# diferencia al cuadrado entre las puntuaciones esperadas del ítem en el grupo de
# referencia y en el focal, dividida por la DE combinada del ítem observado.
puntaje_esperado <- function(eta, est, item, fac) {
  lam <- est$lambda[item, fac]; nu <- est$nu[item, 1]; th <- est$theta[item, item]
  tau <- est$tau[grep(paste0("^", item, "\\|"), rownames(est$tau)), 1]
  1 + rowSums(sapply(tau, function(t) pnorm((nu + lam * eta - t) / sqrt(th))))
}
dmacs <- function(f, item, grupo, focal) {
  est <- lavInspect(f, "est"); fac <- factor_de[[item]]
  ref <- est[[1]]; foc <- est[[focal]]
  eta <- seq(-6, 6, length.out = 2001)
  dens <- dnorm(eta, foc$alpha[fac, 1], sqrt(foc$psi[fac, fac]))
  dif2 <- (puntaje_esperado(eta, ref, item, fac) - puntaje_esperado(eta, foc, item, fac))^2
  d <- datos_por(grupo); g <- levels(datos[[grupo]])
  y_ref <- d[[item]][d[[grupo]] == g[1]]; y_foc <- d[[item]][d[[grupo]] == g[focal]]
  sd_comb <- sqrt(((length(y_ref) - 1) * var(y_ref) + (length(y_foc) - 1) * var(y_foc)) /
                    (length(y_ref) + length(y_foc) - 2))
  sqrt(sum(dif2 * dens) / sum(dens)) / sd_comb
}

# ---------------------------------------------------------------------------
# 1. DIF de interceptos por NSE (y también por sexo, cuyos ΔCFI quedaron en el límite)
# ---------------------------------------------------------------------------
dif_grupo <- function(modelo, nombre_modelo, grupo) {
  n_g <- nlevels(datos[[grupo]])
  s_esc <- sintaxis_escalar(modelo, grupo)
  f_esc <- estimar(s_esc, modelo, grupo)
  fm_esc <- fitMeasures(f_esc, indices)
  mi <- suppressWarnings(modindices(f_esc, op = "~1", free.remove = FALSE)) %>%
    filter(lhs %in% items_de(modelo)) %>% group_by(item = lhs) %>%
    summarise(MI = sum(mi), .groups = "drop")
  base_medias <- medias_latentes(f_esc) %>% mutate(item_libre = "Ninguno")
  por_item <- map(items_de(modelo), function(it) {
    f <- estimar(liberar_intercepto(s_esc, it, n_g), modelo, grupo)
    fm <- fitMeasures(f, indices)
    list(
      resumen = tibble(modelo = nombre_modelo, variable = grupo, item = it,
                       dCFI = fm["cfi.scaled"] - fm_esc["cfi.scaled"],
                       dRMSEA = fm["rmsea.scaled"] - fm_esc["rmsea.scaled"],
                       p_dif = lavTestLRT(f, f_esc)[2, "Pr(>Chisq)"],
                       !!!setNames(map(2:n_g, ~ dmacs(f, it, grupo, .x)),
                                   paste0("dMACS_", levels(datos[[grupo]])[2:n_g]))),
      medias = medias_latentes(f) %>% mutate(item_libre = it))
  })
  list(dif = map_dfr(por_item, "resumen") %>% left_join(mi, by = "item"),
       medias = bind_rows(base_medias, map_dfr(por_item, "medias")) %>%
         mutate(modelo = nombre_modelo, variable = grupo, .before = 1))
}
dif <- list()
for (nm in names(modelos)) for (g in c("nse", "sexo")) dif[[paste(nm, g)]] <- dif_grupo(modelos[[nm]], nm, g)
write_csv(map_dfr(dif, "dif"), file.path(dir_tab, "informe_dif_interceptos.csv"))
write_csv(map_dfr(dif, "medias"), file.path(dir_tab, "informe_dif_medias.csv"))

# ---------------------------------------------------------------------------
# 2. Corrección de Holm sobre todas las diferencias de medias latentes informadas
# ---------------------------------------------------------------------------
medias_pub <- read_csv(file.path(dir_tab, "invarianza_medias_latentes.csv"), show_col_types = FALSE) %>%
  mutate(p_holm = p.adjust(p, method = "holm"))
write_csv(medias_pub, file.path(dir_tab, "informe_medias_holm.csv"))

# ---------------------------------------------------------------------------
# 3. Edad: sensibilidad de las diferencias de medias a los ítems ancla.
#    Para cada factor y cada par de ítems usado como único ancla (interceptos iguales),
#    se liberan los interceptos de los demás ítems de ese factor. El otro factor de la
#    escala conserva la especificación del modelo parcial publicado.
# ---------------------------------------------------------------------------
libres_pub <- list("Consumo sustentable y político" = "O3_9",
                   "Prácticas domésticas" = c("O2_2", "O2_5"))
anclas <- map_dfr(names(modelos), function(nm) {
  modelo <- modelos[[nm]]; its <- items_de(modelo); s_esc <- sintaxis_escalar(modelo, "edad")
  map_dfr(unique(factor_de[its]), function(fac) {
    its_f <- its[factor_de[its] == fac]
    otros_libres <- setdiff(libres_pub[[nm]], its_f)
    map_dfr(combn(its_f, 2, simplify = FALSE), function(par) {
      s <- s_esc
      for (it in c(setdiff(its_f, par), otros_libres)) s <- liberar_intercepto(s, it, 3)
      f <- estimar(s, modelo, "edad")
      medias_latentes(f) %>% filter(factor == fac) %>%
        mutate(modelo = nm, anclas = paste(par, collapse = " + "), .before = 1)
    })
  })
})
write_csv(anclas, file.path(dir_tab, "informe_edad_anclas.csv"))

# ---------------------------------------------------------------------------
# 4. ESEM y bifactor-ESEM de los 17 ítems (mitad confirmatoria)
# ---------------------------------------------------------------------------
afe_obj <- readRDS(here("output", "models", "afe_5factores.rds"))
items17 <- names(factor_de)
mitad2 <- datos[-afe_obj$idx_mitad1, items17]
facs <- c("compra_sust", "consumo_pol", "ahorro", "planificacion")
objetivo <- matrix(0, length(items17), 4, dimnames = list(items17, facs))
for (it in items17) objetivo[it, factor_de[[it]]] <- NA
m_esem <- paste(paste0('efa("b")*', facs, collapse = " + "), "=~", paste(items17, collapse = " + "))
f_esem <- cfa(m_esem, data = mitad2, ordered = TRUE, estimator = "WLSMV",
              rotation = "target", rotation.args = list(target = objetivo))
m_bif <- paste(paste0('efa("b")*', c("general", facs), collapse = " + "), "=~", paste(items17, collapse = " + "))
f_bif <- cfa(m_bif, data = mitad2, ordered = TRUE, estimator = "WLSMV",
             rotation = "bigeomin")
f_cfa <- cfa(paste(modelos, collapse = "\n"), data = mitad2, ordered = TRUE, estimator = "WLSMV")

resid_entre <- function(f) {
  rc <- residuals(f, type = "cor")$cov
  pr <- which(lower.tri(rc), arr.ind = TRUE)
  esc <- c(compra_sust = "P", consumo_pol = "P", ahorro = "D", planificacion = "D")
  e1 <- esc[factor_de[rownames(rc)[pr[, 1]]]]; e2 <- esc[factor_de[colnames(rc)[pr[, 2]]]]
  c(resid_entre_010 = sum(abs(rc[pr][e1 != e2]) > .10), resid_dentro_010 = sum(abs(rc[pr][e1 == e2]) > .10))
}
esem_ajuste <- imap_dfr(list("CFA de cuatro factores" = f_cfa, "ESEM de cuatro factores (rotación objetivo)" = f_esem,
                             "Bifactor-ESEM (bigeomin)" = f_bif), function(f, nm) {
  tibble(modelo = nm, !!!as.list(fitMeasures(f, c(indices, "rmsea.ci.lower.scaled", "rmsea.ci.upper.scaled"))),
         !!!as.list(resid_entre(f)), admisible = lavInspect(f, "post.check"),
         convergio = lavInspect(f, "converged"))
})
write_csv(esem_ajuste, file.path(dir_tab, "informe_esem_ajuste.csv"))
cargas_esem <- standardizedSolution(f_esem) %>% filter(op == "=~") %>%
  transmute(factor = lhs, item = rhs, carga = est.std, principal = factor_de[rhs] == lhs)
write_csv(cargas_esem, file.path(dir_tab, "informe_esem_cargas.csv"))
write_csv(standardizedSolution(f_esem) %>% filter(op == "~~", lhs != rhs, lhs %in% facs) %>%
            transmute(factor1 = lhs, factor2 = rhs, r = est.std, ic_inf = ci.lower, ic_sup = ci.upper),
          file.path(dir_tab, "informe_esem_cor.csv"))
write_csv(standardizedSolution(f_bif) %>% filter(op == "=~") %>% transmute(factor = lhs, item = rhs, carga = est.std),
          file.path(dir_tab, "informe_bifactor_cargas.csv"))
