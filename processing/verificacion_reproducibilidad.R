# Verificación de reproducibilidad de las cifras de Bartlett/KMO y de invarianza.
# Reestima desde los datos procesados y compara con las tablas guardadas.
#   1. Bartlett y KMO: muestra completa (como se informó) y mitad exploratoria (donde se
#      hizo el AFE); fórmula de Bartlett recalculada a mano desde el determinante.
#   2. Invarianza: (a) misma especificación (Wu y Estabrook vía measEq.syntax) reestimada
#      desde cero; (b) ruta independiente con las restricciones nativas de lavaan para los
#      niveles configural y escalar, cuyo ajuste debe ser idéntico al de (a).
#   3. Modelo parcial por edad y medias latentes con group.partial de semTools.
# Escribe output/tables/verificacion_*.csv
suppressPackageStartupMessages({
  library(tidyverse); library(haven); library(here); library(psych); library(lavaan); library(semTools)
})
dir_tab <- here("output", "tables")
db_proc <- readRDS(here("input", "data", "proc", "db_proc.rds"))
items <- db_proc %>% select(matches("^O[1-4]_\\d+$")) %>% mutate(across(everything(), ~ as.numeric(zap_labels(.x))))
idx_m1 <- readRDS(here("output", "models", "afe_5factores.rds"))$idx_mitad1

# ---------------------------------------------------------------------------
# 1. Bartlett y KMO
# ---------------------------------------------------------------------------
bartlett_manual <- function(R, n) {
  p <- ncol(R); chi2 <- -(n - 1 - (2 * p + 5) / 6) * log(det(R)); gl <- p * (p - 1) / 2
  c(chi2 = chi2, gl = gl, p = pchisq(chi2, gl, lower.tail = FALSE))
}
pruebas <- function(datos, muestra) {
  R <- polychoric(datos)$rho
  defpos <- all(eigen(R, only.values = TRUE)$values > 0)
  if (!defpos) R <- cor.smooth(R)
  b <- cortest.bartlett(R, n = nrow(datos)); m <- bartlett_manual(R, nrow(datos)); k <- KMO(R)
  tibble(muestra, n = nrow(datos), items = ncol(datos), definida_positiva = defpos,
         chi2_psych = b$chisq, chi2_manual = m["chi2"], gl = b$df, p = b$p.value,
         KMO = k$MSA, MSA_min = min(k$MSAi), item_MSA_min = names(which.min(k$MSAi)))
}
verif_bartlett <- bind_rows(pruebas(items, "Muestra completa"), pruebas(items[idx_m1, ], "Mitad exploratoria"))
publicado <- read_csv(file.path(dir_tab, "pruebas_previas_conjuntos.csv"), show_col_types = FALSE)[1, ]
verif_bartlett <- verif_bartlett %>%
  mutate(chi2_publicado = if_else(muestra == "Muestra completa", publicado$bartlett_chi2, NA_real_),
         KMO_publicado = if_else(muestra == "Muestra completa", publicado$kmo_global, NA_real_))
write_csv(verif_bartlett, file.path(dir_tab, "verificacion_bartlett.csv"))

# ---------------------------------------------------------------------------
# 2. Invarianza
# ---------------------------------------------------------------------------
datos <- db_proc %>%
  mutate(Sexo = factor(as.numeric(SEXO), levels = 1:2, labels = c("Hombre", "Mujer")),
         Edad = cut(as.numeric(EDADR), breaks = c(1, 3, 5, 7), labels = c("18-34", "35-54", "55 o más")),
         NSE  = cut(as.numeric(NSE), breaks = c(0, 3, 5, 7), labels = c("ABC1", "C2-C3", "D-E")),
         across(matches("^O[1-4]_\\d+$"), ~ as.numeric(zap_labels(.x))))
modelos <- list(
  "Consumo sustentable y político" = 'compra_sust =~ O2_11 + O2_12 + O3_4 + O3_7
                                      consumo_pol =~ O3_2 + O3_3 + O3_5 + O3_8 + O3_9',
  "Prácticas domésticas" = 'ahorro =~ O2_1 + O2_2 + O2_3 + O2_4 + O2_5
                            planificacion =~ O1_10 + O2_8 + O2_9')
libres_edad <- list("Consumo sustentable y político" = "O3_9", "Prácticas domésticas" = c("O2_2", "O2_5"))
niveles <- list("Configural" = "", "Umbrales" = "thresholds", "Métrica" = c("thresholds", "loadings"),
                "Escalar" = c("thresholds", "loadings", "intercepts"))
indices <- c("chisq.scaled", "df", "cfi.scaled", "tli.scaled", "rmsea.scaled", "srmr")
ord_de <- function(m) lavNames(cfa(m, data = datos), "ov")
por <- function(g) datos %>% arrange(.data[[g]])

we <- function(m, g, eq) {
  s <- as.character(measEq.syntax(configural.model = m, data = por(g), ordered = ord_de(m),
                                  parameterization = "theta", ID.fac = "std.lv",
                                  ID.cat = "Wu.Estabrook.2016", group = g, group.equal = eq))
  cfa(s, data = por(g), group = g, ordered = ord_de(m), group.label = levels(datos[[g]]),
      estimator = "WLSMV", parameterization = "theta")
}
nativo <- function(m, g, eq = "", parcial = character(0)) {
  cfa(m, data = por(g), group = g, ordered = ord_de(m), group.label = levels(datos[[g]]),
      estimator = "WLSMV", parameterization = "theta", std.lv = TRUE,
      group.equal = if (identical(eq, "")) "" else eq,
      group.partial = if (length(parcial)) paste0(parcial, "~1") else "")
}

rep_we <- list(); filas <- list()
for (nm in names(modelos)) for (g in c("Sexo", "Edad", "NSE")) {
  fits <- map(niveles, ~ we(modelos[[nm]], g, .x))
  rep_we[[paste(nm, g)]] <- fits
  fn_conf <- nativo(modelos[[nm]], g)
  fn_esc <- nativo(modelos[[nm]], g, c("thresholds", "loadings", "intercepts"))
  filas[[paste(nm, g)]] <- imap_dfr(fits, function(f, niv) {
    fm <- fitMeasures(f, indices)
    nat <- switch(niv, "Configural" = fitMeasures(fn_conf, indices), "Escalar" = fitMeasures(fn_esc, indices), NULL)
    tibble(modelo = nm, variable = g, nivel = niv, !!!as.list(fm),
           chisq_nativo = if (is.null(nat)) NA else nat["chisq.scaled"],
           df_nativo = if (is.null(nat)) NA else nat["df"],
           cfi_nativo = if (is.null(nat)) NA else nat["cfi.scaled"])
  }) %>% mutate(dCFI = cfi.scaled - lag(cfi.scaled), dRMSEA = rmsea.scaled - lag(rmsea.scaled),
                p_dif = c(NA, map_dbl(2:4, ~ lavTestLRT(fits[[.x]], fits[[.x - 1]])[2, "Pr(>Chisq)"])))
}
verif_inv <- bind_rows(filas)
pub <- read_csv(file.path(dir_tab, "invarianza_secuencia.csv"), show_col_types = FALSE)
comp <- verif_inv %>%
  left_join(pub %>% select(modelo, variable, nivel, chisq_pub = chisq.scaled, df_pub = df, cfi_pub = cfi.scaled,
                           rmsea_pub = rmsea.scaled, dCFI_pub = dCFI, dRMSEA_pub = dRMSEA, p_pub = p_dif),
            by = c("modelo", "variable", "nivel")) %>%
  mutate(dif_chisq_pub = chisq.scaled - chisq_pub, dif_cfi_pub = cfi.scaled - cfi_pub,
         dif_chisq_nativo = chisq.scaled - chisq_nativo, dif_df_nativo = df - df_nativo)
write_csv(comp, file.path(dir_tab, "verificacion_invarianza.csv"))

# ---------------------------------------------------------------------------
# 3. Modelo escalar parcial por edad y medias latentes.
#    lavaan::cfa() fija en 0 los interceptos de ítems ordinales y no permite liberarlos
#    con group.partial, por lo que la ruta nativa no sirve aquí. Se verifica con el
#    argumento group.partial de semTools::measEq.syntax(), que funciona con un solo
#    parámetro; para la escala doméstica (dos interceptos) se libera O2.2 con
#    group.partial y O2.5 editando la sintaxis generada por semTools.
# ---------------------------------------------------------------------------
parcial_edad <- function(m, libres) {
  s <- as.character(measEq.syntax(configural.model = m, data = por("Edad"), ordered = ord_de(m),
                                  parameterization = "theta", ID.fac = "std.lv", ID.cat = "Wu.Estabrook.2016",
                                  group = "Edad", group.equal = c("thresholds", "loadings", "intercepts"),
                                  group.partial = paste0(libres[1], "~1")))
  l <- strsplit(s, "\n")[[1]]
  for (it in libres[-1]) {
    k <- grepl(paste0("^", it, " ~ c\\("), l) & grepl("\\*1", l)
    stopifnot(sum(k) == 1); l[k] <- paste0(it, " ~ c(0, NA, NA)*1")
  }
  cfa(paste(l, collapse = "\n"), data = por("Edad"), group = "Edad", ordered = ord_de(m),
      group.label = levels(datos$Edad), estimator = "WLSMV", parameterization = "theta")
}
medias_verif <- imap_dfr(modelos, function(m, nm) {
  f <- parcial_edad(m, libres_edad[[nm]])
  fm <- fitMeasures(f, indices)
  parameterEstimates(f) %>% filter(op == "~1", lhs %in% lavNames(f, "lv"), group > 1) %>%
    transmute(modelo = nm, variable = "Edad", grupo = lavInspect(f, "group.label")[group], factor = lhs,
              media_verif = est, p_verif = pvalue, cfi_parcial = fm["cfi.scaled"], df_parcial = fm["df"])
})
med_pub <- read_csv(file.path(dir_tab, "invarianza_medias_latentes.csv"), show_col_types = FALSE)
write_csv(medias_verif %>%
            left_join(med_pub %>% select(modelo, variable, grupo, factor, media_pub = media, p_pub = p),
                      by = c("modelo", "variable", "grupo", "factor")) %>%
            mutate(dif_media = media_verif - media_pub),
          file.path(dir_tab, "verificacion_medias.csv"))
writeLines(c(R.version.string, paste("lavaan", packageVersion("lavaan")), paste("semTools", packageVersion("semTools")),
             paste("psych", packageVersion("psych"))), file.path(dir_tab, "verificacion_versiones.txt"))
