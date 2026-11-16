# Análisis complementarios del paper de clases latentes, según la Reviewer's Guide
# (Hancock y Mueller, 2010; cap. 13). Requiere haber corrido processing/clases_latentes.qmd
# (que guarda output/models/lca_soluciones.rds). Escribe output/tables/revision_lca_*.csv
suppressPackageStartupMessages({
  library(tidyverse); library(haven); library(here); library(poLCA)
})
select <- dplyr::select
source(here("processing", "lca_funciones.R"))
dir_tab <- here("output", "tables")

r <- readRDS(here("output", "models", "lca_enumeracion.rds"))
s <- readRDS(here("output", "models", "lca_soluciones.rds"))
m <- s$sol$A$modelo
nombres <- s$sol$A$nombres
orden_clases <- s$orden_clases
db_proc <- readRDS(here("input", "data", "proc", "db_proc.rds"))
original <- read_sav(here("input", "data", "original", "Encuesta Sociedad de Consumo 2023.sav"))
stopifnot(identical(db_proc$key, original$key))
etiquetas <- map_chr(db_proc %>% select(all_of(r$items_A)),
                     ~ str_remove(attr(.x, "label"), "_[^_]*$"))

# ---------------------------------------------------------------------------
# 1. Probabilidades condicionales con errores estándar (desideratum 12)
# ---------------------------------------------------------------------------
# Las categorías de db_proc son códigos consecutivos tras el colapso de extremos.
# Se reconstruye qué códigos originales (1 = Nunca ... 5 = Siempre) contiene cada una.
mapa_categorias <- map_dfr(r$items_A, function(item) {
  proc <- as.numeric(zap_labels(db_proc[[item]]))
  orig <- as.numeric(zap_labels(original[[item]]))
  tibble(proc, orig) %>% distinct() %>% group_by(proc) %>%
    summarise(desde = min(orig), hasta = max(orig), .groups = "drop") %>%
    mutate(item = item, k = proc,
           rotulo = if_else(desde == hasta, as.character(desde), paste0(desde, "-", hasta)),
           alto = hasta >= 4)   # la categoría incluye "La mayoría de las veces" o "Siempre"
})
write_csv(mapa_categorias, file.path(dir_tab, "revision_lca_mapa_categorias.csv"))

condicionales <- imap_dfr(m$probs, function(p, item) {
  se <- m$probs.se[[item]]
  mp <- mapa_categorias %>% filter(item == !!item) %>% arrange(k)
  expand_grid(clase_num = seq_len(nrow(p)), k = seq_len(ncol(p))) %>%
    mutate(item = item, enunciado = etiquetas[item], clase = nombres[clase_num],
           categoria = mp$rotulo[k], alto = mp$alto[k], desde = mp$desde[k],
           prob = p[cbind(clase_num, k)], se = se[cbind(clase_num, k)])
})
write_csv(condicionales, file.path(dir_tab, "revision_lca_condicionales.csv"))

# Probabilidad de responder en las categorías que incluyen "La mayoría de las veces" o
# "Siempre". Si el colapso fusionó "A veces" con ellas, la categoría alta empieza en 3.
prob_alto <- condicionales %>%
  group_by(item, enunciado, clase) %>%
  summarise(p_alto = sum(prob[alto]), umbral = min(desde[alto]), .groups = "drop")
write_csv(prob_alto, file.path(dir_tab, "revision_lca_prob_alto.csv"))

# ---------------------------------------------------------------------------
# 2. Ajuste absoluto, identificación, parámetros en el límite y convergencia
#    (desiderata 9, 10, 13 y 14)
# ---------------------------------------------------------------------------
pr <- unlist(m$probs); se_all <- unlist(m$probs.se)
diagnostico <- tibble(
  G2 = m$Gsq, gl_residuales = m$resid.df,
  patrones_observados = nrow(unique(m$y)), n = m$Nobs,
  patrones_posibles = prod(sapply(m$probs, ncol)),
  npar = m$npar,
  prob_menor_001 = sum(pr < .001), prob_mayor_999 = sum(pr > .999),
  ee_no_finitos = sum(!is.finite(se_all)),
  iteraciones = m$numiter, max_iter_alcanzado = m$numiter >= m$maxiter,
  inicios = m$inicios, replicas = m$replicas
)
write_csv(diagnostico, file.path(dir_tab, "revision_lca_diagnostico.csv"))

limite <- condicionales %>% filter(prob < .001 | prob > .999)
write_csv(limite, file.path(dir_tab, "revision_lca_limite.csv"))

# Comparación con la estimación previa de 20 inicios (si existe)
previo <- here("..", "lca_enumeracion_20inicios.rds")
if (file.exists(previo)) {
  p20 <- readRDS(previo)$enumeracion %>% filter(str_detect(modelo, "^A")) %>% select(clases, LL20 = LL)
  comp_inicios <- r$enumeracion %>% filter(str_detect(modelo, "^A")) %>%
    select(clases, LL100 = LL, replicas, inicios) %>% left_join(p20, by = "clases") %>%
    mutate(diferencia = LL100 - LL20)
  write_csv(comp_inicios, file.path(dir_tab, "revision_lca_inicios.csv"))
}

# ---------------------------------------------------------------------------
# 3. Sensibilidad al tratamiento nominal: ítems dicotomizados (desideratum 4)
#    1 = categoría que incluye "La mayoría de las veces" o "Siempre"; 0 = resto.
#    Si las clases dependen del orden de las categorías tratado como nominal,
#    deberían cambiar al usar una sola distinción ordenada por ítem.
# ---------------------------------------------------------------------------
dic <- db_proc %>% select(all_of(r$items_A)) %>%
  mutate(across(everything(), function(x) {
    it <- cur_column()
    altos <- mapa_categorias$k[mapa_categorias$item == it & mapa_categorias$alto]
    if_else(as.numeric(zap_labels(x)) %in% altos, 2L, 1L)
  }))
f_dic <- as.formula(paste0("cbind(", paste(r$items_A, collapse = ", "), ") ~ 1"))
estimar_dic <- function(k, inicios = 50) {
  set.seed(20231 + k)
  aj <- lapply(seq_len(inicios), function(i)
    tryCatch(poLCA(f_dic, data = dic, nclass = k, maxiter = 5000, nrep = 1, verbose = FALSE),
             error = function(e) NULL))
  aj <- Filter(Negate(is.null), aj)
  ll <- sapply(aj, `[[`, "llik")
  mejor <- aj[[which.max(ll)]]; mejor$replicas <- sum(abs(ll - max(ll)) < .01); mejor$inicios <- length(ll)
  mejor
}
mods_dic <- lapply(1:7, estimar_dic)
enum_dic <- map_dfr(mods_dic, function(md) {
  n <- md$Nobs; p <- md$npar; ll <- md$llik
  post <- md$posterior
  tibble(clases = ncol(post), LL = ll, npar = p, BIC = -2 * ll + p * log(n),
         CAIC = -2 * ll + p * (log(n) + 1),
         entropia = if (ncol(post) == 1) NA else 1 - sum(-post * log(pmax(post, 1e-300))) / (n * log(ncol(post))),
         clase_min = min(md$P), replicas = md$replicas)
})
write_csv(enum_dic, file.path(dir_tab, "revision_lca_dicotomico_enumeracion.csv"))

perfil_dicotomico <- function(md) {
  perfil <- imap_dfr(md$probs, ~ tibble(item = .y, clase_dic = seq_len(nrow(.x)), p_alto = .x[, 2])) %>%
    mutate(dim = dimension[item]) %>%
    group_by(clase_dic, dim) %>% summarise(p_alto = mean(p_alto), .groups = "drop") %>%
    pivot_wider(names_from = dim, values_from = p_alto) %>%
    mutate(proporcion = md$P[clase_dic], clases = length(md$P))
  # Clase del modelo principal más frecuente entre las personas de cada clase dicotómica
  cruce <- as.data.frame.matrix(table(principal = nombres[m$predclass], dicotomico = md$predclass))
  perfil %>% mutate(clase_principal = rownames(cruce)[apply(cruce, 2, which.max)][clase_dic],
                    pct_clase_principal = 100 * apply(cruce, 2, max)[clase_dic] / colSums(cruce)[clase_dic])
}
dimension <- c(O2_11 = "Compra sustentable", O2_12 = "Compra sustentable", O3_4 = "Compra sustentable",
               O3_7 = "Compra sustentable", O3_2 = "Consumo político", O3_3 = "Consumo político",
               O3_5 = "Consumo político", O3_8 = "Consumo político", O3_9 = "Consumo político",
               O2_1 = "Ahorro doméstico", O2_2 = "Ahorro doméstico", O2_3 = "Ahorro doméstico",
               O2_4 = "Ahorro doméstico", O2_5 = "Ahorro doméstico", O1_10 = "Planificación",
               O2_8 = "Planificación", O2_9 = "Planificación")
m_dic5 <- mods_dic[[5]]
perfil_dic <- bind_rows(perfil_dicotomico(mods_dic[[5]]), perfil_dicotomico(mods_dic[[6]]))
write_csv(perfil_dic, file.path(dir_tab, "revision_lca_dicotomico_perfiles.csv"))
write_csv(tibble(clases = 5:6, ARI = c(mclust::adjustedRandIndex(m$predclass, mods_dic[[5]]$predclass),
                                       mclust::adjustedRandIndex(m$predclass, mods_dic[[6]]$predclass))),
          file.path(dir_tab, "revision_lca_dicotomico_ari.csv"))

# ---------------------------------------------------------------------------
# 4. Validez de las clases con variables externas (desideratum 16):
#    tres pasos con posición política (M9) y significado político del consumo (C3_14),
#    controlando por sexo, edad y NSE. Ambas se estandarizan.
# ---------------------------------------------------------------------------
grupos <- db_proc %>%
  transmute(Sexo = factor(as.numeric(SEXO), levels = 1:2, labels = c("Hombre", "Mujer")),
            Edad = cut(as.numeric(EDADR), breaks = c(1, 3, 5, 7), labels = c("18-34", "35-54", "55 o más")),
            NSE  = cut(as.numeric(NSE), breaks = c(0, 3, 5, 7), labels = c("ABC1", "C2-C3", "D-E"))) %>%
  bind_cols(original %>% transmute(Derecha = as.numeric(scale(as.numeric(zap_labels(M9)))),
                                   ConsumoPolitico = as.numeric(scale(as.numeric(zap_labels(C3_14))))))
Z <- model.matrix(~ Sexo + Edad + NSE + Derecha + ConsumoPolitico, grupos)
tp <- tres_pasos_ml(m, Z, ref = which(nombres == "Intermedio"))
stopifnot(tp$convergencia == 0)
ee <- matrix(sqrt(diag(tp$vcov)), nrow = nrow(tp$coef), dimnames = dimnames(tp$coef))
coef_ext <- expand_grid(termino = c("Derecha", "ConsumoPolitico"), k = seq_len(ncol(tp$coef))) %>%
  mutate(clase = nombres[tp$otras[k]], b = map2_dbl(termino, k, ~ tp$coef[.x, .y]),
         ee = map2_dbl(termino, k, ~ ee[.x, .y]), OR = exp(b),
         OR_inf = exp(b - 1.96 * ee), OR_sup = exp(b + 1.96 * ee), p = 2 * pnorm(-abs(b / ee))) %>%
  select(-k)
write_csv(coef_ext, file.path(dir_tab, "revision_lca_validez_externa.csv"))
write_csv(bind_rows(wald_covariable(tp, "Derecha") %>% mutate(variable = "Posición política"),
                    wald_covariable(tp, "ConsumoPolitico") %>% mutate(variable = "Consumo como postura política")),
          file.path(dir_tab, "revision_lca_validez_wald.csv"))

writeLines(c(R.version.string, paste("poLCA", packageVersion("poLCA"))),
           file.path(dir_tab, "revision_lca_versiones.txt"))
