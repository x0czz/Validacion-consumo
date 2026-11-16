# Análisis complementarios del paper de medición, según los criterios de la
# Reviewer's Guide (Hancock y Mueller, 2010; cap. 8, 25 y 29).
# Usa los objetos guardados por processing/analisis_factorial.qmd y escribe
# tablas en output/tables/revision_*.csv
suppressPackageStartupMessages({
  library(tidyverse); library(haven); library(here); library(psych); library(lavaan)
})

dir_tab <- here("output", "tables")
db_proc <- readRDS(here("input", "data", "proc", "db_proc.rds"))
original <- read_sav(here("input", "data", "original", "Encuesta Sociedad de Consumo 2023.sav"))
stopifnot(identical(db_proc$key, original$key))

items <- db_proc %>%
  select(matches("^O[1-4]_\\d+$")) %>%
  mutate(across(everything(), ~ as.numeric(zap_labels(.x))))
etiquetas <- map_chr(db_proc %>% select(all_of(names(items))),
                     ~ str_remove(attr(.x, "label"), "_[^_]*$"))

# ---------------------------------------------------------------------------
# 1. Descriptivos de los ítems (E5, C5) y valores perdidos en la base original
# ---------------------------------------------------------------------------
perdidos_original <- original %>% select(all_of(names(items))) %>%
  summarise(across(everything(), ~ sum(is.na(.x)))) %>% unlist()

descriptivos <- map_dfr(names(items), function(v) {
  x <- items[[v]]
  tibble(item = v, enunciado = etiquetas[v], categorias = n_distinct(x),
         media = mean(x), de = sd(x), asimetria = skew(x), curtosis = kurtosi(x),
         pct_modal = 100 * max(table(x)) / length(x), perdidos_original = perdidos_original[v])
})
write_csv(descriptivos, file.path(dir_tab, "revision_descriptivos_items.csv"))

# ---------------------------------------------------------------------------
# 2. Resultados completos del AFE de cinco factores (E11, E12)
# ---------------------------------------------------------------------------
afe_obj <- readRDS(here("output", "models", "afe_5factores.rds"))
fa5 <- afe_obj$afe
patron <- unclass(fa5$loadings)
estructura <- unclass(fa5$Structure)

# Nombre de cada factor según un ítem marcador
marcadores <- c(O3_8 = "Compra sustentable y consumo político", O2_1 = "Ahorro doméstico",
                O2_8 = "Planificación de compras", O4_3 = "Facilidad para reciclar",
                O4_1 = "Valoración del reciclaje")
nombre_factor <- setNames(rep(NA_character_, ncol(patron)), colnames(patron))
for (it in names(marcadores)) nombre_factor[which.max(abs(patron[it, ]))] <- marcadores[[it]]
stopifnot(!anyNA(nombre_factor))

afe_coef <- bind_rows(
  as_tibble(patron, rownames = "item") %>% mutate(tipo = "Patrón"),
  as_tibble(estructura, rownames = "item") %>% mutate(tipo = "Estructura")
) %>%
  pivot_longer(-c(item, tipo), names_to = "factor", values_to = "valor") %>%
  mutate(factor = nombre_factor[factor], enunciado = etiquetas[item],
         h2 = fa5$communality[item])
write_csv(afe_coef, file.path(dir_tab, "revision_afe_coeficientes.csv"))

phi <- fa5$Phi
dimnames(phi) <- list(nombre_factor[rownames(phi)], nombre_factor[colnames(phi)])
write_csv(as_tibble(phi, rownames = "factor"), file.path(dir_tab, "revision_afe_phi.csv"))

# Con rotación oblicua se informa la suma de coeficientes de estructura al cuadrado
# por factor (no es aditiva) y la varianza común total (suma de comunalidades)
n_it <- nrow(patron)
afe_varianza <- tibble(
  factor = nombre_factor[colnames(estructura)],
  suma_estructura2 = colSums(estructura^2),
  prop_estructura2 = colSums(estructura^2) / n_it
) %>% bind_rows(tibble(factor = "Varianza común total (suma de comunalidades)",
                       suma_estructura2 = sum(fa5$communality),
                       prop_estructura2 = sum(fa5$communality) / n_it))
write_csv(afe_varianza, file.path(dir_tab, "revision_afe_varianza.csv"))

# ---------------------------------------------------------------------------
# 3. AFC de las escalas breves: IC del RMSEA, diferencia de chi2, parámetros,
#    residuos y diagnóstico de soluciones impropias (C8-C13)
# ---------------------------------------------------------------------------
items_afc <- items %>% mutate(O4_7 = max(O4_7) + 1 - O4_7)
mitad2 <- items_afc[-afe_obj$idx_mitad1, ]

m_r2 <- "critico =~ O2_11 + O2_12 + O3_4 + O3_7 + O3_2 + O3_3 + O3_5 + O3_8 + O3_9"
m_r3 <- "compra_sust =~ O2_11 + O2_12 + O3_4 + O3_7
         consumo_pol =~ O3_2 + O3_3 + O3_5 + O3_8 + O3_9"
m_r4 <- "ahorro =~ O2_1 + O2_2 + O2_3 + O2_4 + O2_5"
m_r5 <- "ahorro =~ O2_1 + O2_2 + O2_3 + O2_4 + O2_5
         planificacion =~ O1_10 + O2_8 + O2_9"
estimar <- function(m, d) cfa(m, data = d, ordered = TRUE, estimator = "WLSMV")

m_r1 <- "critico =~ O3_2 + O3_3 + O3_4 + O3_5 + O3_7 + O3_8 + O3_9"
m_r6 <- paste(m_r3, m_r5, sep = "\n")
fits <- list(
  "Consumo crítico, un factor|Mitad 2"                    = estimar(m_r1, mitad2),
  "Ahorro doméstico, un factor|Mitad 2"                   = estimar(m_r4, mitad2),
  "Ambas escalas en un modelo conjunto|Mitad 2"           = estimar(m_r6, mitad2),
  "Consumo sustentable y político, un factor|Mitad 2"     = estimar(m_r2, mitad2),
  "Consumo sustentable y político, dos factores|Mitad 2"  = estimar(m_r3, mitad2),
  "Prácticas domésticas, dos factores|Mitad 2"            = estimar(m_r5, mitad2),
  "Consumo sustentable y político, dos factores|Muestra completa" = estimar(m_r3, items_afc),
  "Prácticas domésticas, dos factores|Muestra completa"           = estimar(m_r5, items_afc)
)

indices <- c("chisq.scaled", "df.scaled", "pvalue.scaled", "cfi.scaled", "tli.scaled",
             "rmsea.scaled", "rmsea.ci.lower.scaled", "rmsea.ci.upper.scaled", "srmr")
ajuste <- imap_dfr(fits, function(f, nombre) {
  fm <- fitMeasures(f, indices)
  res <- residuals(f, type = "cor")$cov
  res <- res[lower.tri(res)]
  tibble(modelo = str_split_i(nombre, "\\|", 1), muestra = str_split_i(nombre, "\\|", 2),
         n = lavInspect(f, "nobs"), !!!as.list(fm),
         resid_max = max(abs(res)), resid_mayor_010 = sum(abs(res) > .10),
         solucion_admisible = lavInspect(f, "post.check"),
         convergio = lavInspect(f, "converged"))
})
write_csv(ajuste, file.path(dir_tab, "revision_afc_ajuste.csv"))

# Diferencia de chi2 escalada: un factor (anidado) vs. dos factores, mitad 2
dif <- lavTestLRT(fits[["Consumo sustentable y político, dos factores|Mitad 2"]],
                  fits[["Consumo sustentable y político, un factor|Mitad 2"]])
dif_chi <- tibble(comparacion = "Un factor vs. dos factores (consumo sustentable y político)",
                  dif_chi2 = dif$`Chisq diff`[2], dif_gl = dif$`Df diff`[2], p = dif$`Pr(>Chisq)`[2])
write_csv(dif_chi, file.path(dir_tab, "revision_afc_dif_chi.csv"))

# Localización del desajuste del modelo conjunto (mitad 2): correlaciones residuales
# dentro de una misma escala frente a entre escalas, y por par de factores
f_conj <- fits[["Ambas escalas en un modelo conjunto|Mitad 2"]]
factor_de <- c(setNames(rep("Compra sustentable", 4), c("O2_11", "O2_12", "O3_4", "O3_7")),
               setNames(rep("Consumo político", 5), c("O3_2", "O3_3", "O3_5", "O3_8", "O3_9")),
               setNames(rep("Ahorro doméstico", 5), paste0("O2_", 1:5)),
               setNames(rep("Planificación", 3), c("O1_10", "O2_8", "O2_9")))
escala_de <- c("Compra sustentable" = "Pública", "Consumo político" = "Pública",
               "Ahorro doméstico" = "Doméstica", "Planificación" = "Doméstica")
rc <- residuals(f_conj, type = "cor")$cov
pares <- which(lower.tri(rc), arr.ind = TRUE)
res_pares <- tibble(item1 = rownames(rc)[pares[, 1]], item2 = colnames(rc)[pares[, 2]],
                    resid = rc[pares]) %>%
  mutate(f1 = factor_de[item1], f2 = factor_de[item2],
         tipo = case_when(escala_de[f1] != escala_de[f2] ~ "Entre escalas",
                          f1 == f2 ~ "Mismo factor",
                          TRUE ~ "Misma escala, distinto factor"),
         par_factores = map2_chr(f1, f2, ~ paste(sort(c(.x, .y)), collapse = " – ")))
conj_resid <- bind_rows(
  res_pares %>% group_by(grupo = tipo) %>%
    summarise(pares = n(), mayores_010 = sum(abs(resid) > .10),
              medio_abs = mean(abs(resid)), max_abs = max(abs(resid)), .groups = "drop") %>%
    mutate(nivel = "tipo"),
  res_pares %>% filter(tipo == "Entre escalas") %>% group_by(grupo = par_factores) %>%
    summarise(pares = n(), mayores_010 = sum(abs(resid) > .10),
              medio_abs = mean(abs(resid)), max_abs = max(abs(resid)),
              positivos_010 = sum(resid > .10), .groups = "drop") %>%
    mutate(nivel = "par_entre_escalas"))
write_csv(conj_resid, file.path(dir_tab, "revision_afc_conjunto_residuos.csv"))
write_csv(standardizedSolution(f_conj) %>% filter(op == "~~", lhs != rhs) %>%
            transmute(factor1 = lhs, factor2 = rhs, r = est.std, ic_inf = ci.lower, ic_sup = ci.upper),
          file.path(dir_tab, "revision_afc_conjunto_cor.csv"))

# Parámetros en la muestra completa: cargas no estandarizadas (EE) y estandarizadas,
# R2 de cada ítem y correlación entre factores de cada escala
completos <- fits[str_detect(names(fits), "Muestra completa")]
parametros <- imap_dfr(completos, function(f, nombre) {
  ne <- parameterEstimates(f) %>% filter(op == "=~") %>% select(lhs, rhs, est, se)
  st <- standardizedSolution(f) %>% filter(op == "=~") %>% select(lhs, rhs, std = est.std)
  left_join(ne, st, by = c("lhs", "rhs")) %>%
    mutate(escala = str_split_i(nombre, "\\|", 1), R2 = std^2, .before = 1)
})
write_csv(parametros, file.path(dir_tab, "revision_afc_parametros.csv"))

cor_factores <- imap_dfr(completos, function(f, nombre) {
  standardizedSolution(f) %>% filter(op == "~~", lhs != rhs) %>%
    transmute(escala = str_split_i(nombre, "\\|", 1), factor1 = lhs, factor2 = rhs,
              r = est.std, se, ic_inf = ci.lower, ic_sup = ci.upper)
})
write_csv(cor_factores, file.path(dir_tab, "revision_afc_cor_factores.csv"))

# ---------------------------------------------------------------------------
# 4. Evidencia de validez con variables externas (cap. 25; E15, C13)
#    Correlaciones latentes con tres variables de la encuesta, cada una como
#    factor de un solo indicador ordinal:
#    - C3_14 "La forma en que uno consume algunos bienes tiene que ver con la
#      postura política de uno" (1 = muy en desacuerdo, 5 = muy de acuerdo)
#    - M9 posición política (1 = izquierda, 10 = derecha)
#    - M4 nivel educacional (1 = sin estudios, 10 = postgrado)
# ---------------------------------------------------------------------------
externas <- original %>%
  transmute(C3_14 = as.numeric(zap_labels(C3_14)), M9 = as.numeric(zap_labels(M9)),
            M4 = as.numeric(zap_labels(M4)))
d_ext <- bind_cols(items_afc, externas)
# Cada variable externa entra como indicador continuo único de un factor, con carga 1
# y varianza residual 0, de modo que el factor es la variable observada. Los ítems de
# las escalas siguen siendo ordinales; la correlación resultante es de tipo polyserial.
bloque_ext <- "
politica_consumo =~ 1*C3_14
posicion_politica =~ 1*M9
educacion =~ 1*M4
C3_14 ~~ 0*C3_14
M9 ~~ 0*M9
M4 ~~ 0*M4
"
validez <- imap_dfr(list("Consumo sustentable y político" = m_r3,
                         "Prácticas domésticas" = m_r5), function(m, escala) {
  ordinales <- str_extract_all(m, "O\\d_\\d+")[[1]]
  f <- cfa(paste(m, bloque_ext), data = d_ext, ordered = ordinales, estimator = "WLSMV")
  stopifnot(lavInspect(f, "post.check"))
  standardizedSolution(f) %>%
    filter(op == "~~", lhs %in% c("compra_sust", "consumo_pol", "ahorro", "planificacion"),
           rhs %in% c("politica_consumo", "posicion_politica", "educacion")) %>%
    transmute(escala, factor = lhs, variable = rhs, r = est.std, se,
              ic_inf = ci.lower, ic_sup = ci.upper, p = pvalue)
})
write_csv(validez, file.path(dir_tab, "revision_validez_externa.csv"))

writeLines(c(R.version.string,
             paste("lavaan", packageVersion("lavaan")), paste("semTools", packageVersion("semTools")),
             paste("psych", packageVersion("psych"))),
           file.path(dir_tab, "revision_versiones.txt"))
