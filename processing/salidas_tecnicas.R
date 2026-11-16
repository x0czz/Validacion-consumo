# Salidas técnicas completas de los modelos factoriales y de invarianza, para el
# repositorio. Escribe output/resultados_tecnicos/*.txt (una salida por modelo) y
# output/resultados_tecnicos/salidas_tecnicas_completas.txt (todas juntas).
suppressPackageStartupMessages({
  library(tidyverse); library(haven); library(here); library(psych); library(GPArotation)
  library(lavaan); library(semTools)
})
dir <- here("output", "resultados_tecnicos"); dir.create(dir, showWarnings = FALSE, recursive = TRUE)
db_proc <- readRDS(here("input", "data", "proc", "db_proc.rds"))
items <- db_proc %>% select(matches("^O[1-4]_\\d+$")) %>% mutate(across(everything(), ~ as.numeric(zap_labels(.x))))
idx_m1 <- readRDS(here("output", "models", "afe_5factores.rds"))$idx_mitad1
mitad1 <- items[idx_m1, ]; mitad2 <- items[-idx_m1, ]
salidas <- list()
guardar <- function(nombre, titulo, expr) {
  txt <- capture.output(expr)
  txt <- c(strrep("=", 90), titulo, strrep("=", 90), "", txt, "")
  writeLines(txt, file.path(dir, paste0(nombre, ".txt")))
  salidas[[nombre]] <<- txt
}
opciones <- function(f) summary(f, fit.measures = TRUE, standardized = TRUE, rsquare = TRUE)

# 1. Análisis factorial exploratorio (mitad exploratoria) --------------------------
R1 <- polychoric(mitad1)$rho
guardar("01_afe_bartlett_kmo", "Bartlett y KMO, mitad exploratoria (46 ítems, correlaciones policóricas)", {
  print(cortest.bartlett(R1, n = nrow(mitad1))); print(KMO(R1))
})
guardar("02_afe_numero_factores", "Análisis paralelo y MAP, mitad exploratoria", {
  set.seed(2023)
  print(fa.parallel(R1, n.obs = nrow(mitad1), fm = "minres", fa = "fa", plot = FALSE))
  print(VSS(R1, n = 8, n.obs = nrow(mitad1), fm = "minres", rotate = "oblimin", plot = FALSE))
})
afe5 <- readRDS(here("output", "models", "afe_5factores.rds"))
guardar("03_afe_solucion_final", "Solución exploratoria final de cinco factores (residuos mínimos, oblimin), mitad exploratoria", {
  obj <- afe5$afe
  if (inherits(obj, "fa")) print(obj, digits = 3, sort = TRUE) else str(obj, max.level = 1)
})

# 2. Análisis factoriales confirmatorios ------------------------------------------
m_pub <- 'compra_sust =~ O2_11 + O2_12 + O3_4 + O3_7
          consumo_pol =~ O3_2 + O3_3 + O3_5 + O3_8 + O3_9'
m_dom <- 'ahorro =~ O2_1 + O2_2 + O2_3 + O2_4 + O2_5
          planificacion =~ O1_10 + O2_8 + O2_9'
m_uni9 <- 'critico =~ O2_11 + O2_12 + O3_4 + O3_7 + O3_2 + O3_3 + O3_5 + O3_8 + O3_9'
afc <- function(m, d) cfa(m, data = d, ordered = TRUE, estimator = "WLSMV")
for (spec in list(list("10_afc_consumo_sustentable_politico_mitad_prueba", m_pub, mitad2, "mitad de prueba"),
                  list("11_afc_consumo_sustentable_politico_muestra_completa", m_pub, items, "muestra completa"),
                  list("12_afc_consumo_un_factor_mitad_prueba", m_uni9, mitad2, "mitad de prueba (alternativa de un factor)"),
                  list("13_afc_practicas_domesticas_mitad_prueba", m_dom, mitad2, "mitad de prueba"),
                  list("14_afc_practicas_domesticas_muestra_completa", m_dom, items, "muestra completa"),
                  list("15_afc_modelo_conjunto_mitad_prueba", paste(m_pub, m_dom, sep = "\n"), mitad2, "mitad de prueba"))) {
  f <- afc(spec[[2]], spec[[3]])
  guardar(spec[[1]], paste("AFC (WLSMV, ítems ordinales):", spec[[1]], "-", spec[[4]]), {
    print(opciones(f))
    cat("\nCorrelaciones residuales (|r| > ,10 marcadas con *):\n")
    rc <- residuals(f, type = "cor")$cov
    print(round(rc, 3))
    cat("\nNúmero de correlaciones residuales mayores que |,10|:", sum(abs(rc[lower.tri(rc)]) > .10), "\n")
    cat("\nConfiabilidad (semTools::compRelSEM y AVE):\n")
    print(compRelSEM(f)); print(AVE(f))
  })
}
guardar("16_afc_comparacion_uno_vs_dos_factores", "Prueba de diferencia de chi-cuadrado escalada: uno vs. dos factores (mitad de prueba)", {
  print(lavTestLRT(afc(m_pub, mitad2), afc(m_uni9, mitad2)))
})
facs <- c("compra_sust", "consumo_pol", "ahorro", "planificacion")
items17 <- c("O2_11", "O2_12", "O3_4", "O3_7", "O3_2", "O3_3", "O3_5", "O3_8", "O3_9",
             "O2_1", "O2_2", "O2_3", "O2_4", "O2_5", "O1_10", "O2_8", "O2_9")
fac_de <- setNames(rep(facs, c(4, 5, 5, 3)), items17)
objetivo <- matrix(0, 17, 4, dimnames = list(items17, facs)); for (it in items17) objetivo[it, fac_de[[it]]] <- NA
f_esem <- cfa(paste(paste0('efa("b")*', facs, collapse = " + "), "=~", paste(items17, collapse = " + ")),
              data = mitad2, ordered = TRUE, estimator = "WLSMV", rotation = "target", rotation.args = list(target = objetivo))
guardar("17_esem_mitad_prueba", "ESEM de cuatro factores con rotación objetivo, mitad de prueba", print(opciones(f_esem)))

# 3. Invarianza ------------------------------------------------------------------
datos <- db_proc %>%
  mutate(Sexo = factor(as.numeric(SEXO), 1:2, c("Hombre", "Mujer")),
         Edad = cut(as.numeric(EDADR), c(1, 3, 5, 7), c("18-34", "35-54", "55 o más")),
         NSE  = cut(as.numeric(NSE), c(0, 3, 5, 7), c("ABC1", "C2-C3", "D-E")),
         across(matches("^O[1-4]_\\d+$"), ~ as.numeric(zap_labels(.x))))
por <- function(g) datos %>% arrange(.data[[g]])
niveles <- list("Configural" = "", "Umbrales" = "thresholds", "Métrica" = c("thresholds", "loadings"),
                "Escalar" = c("thresholds", "loadings", "intercepts"))
libres_edad <- list(pub = "O3_9", dom = c("O2_2", "O2_5"))
sint <- function(m, g, eq, partial = character(0)) {
  s <- as.character(measEq.syntax(configural.model = m, data = por(g), ordered = lavNames(cfa(m, data = datos), "ov"),
                                  parameterization = "theta", ID.fac = "std.lv", ID.cat = "Wu.Estabrook.2016",
                                  group = g, group.equal = eq))
  l <- strsplit(s, "\n")[[1]]
  for (it in partial) { k <- grepl(paste0("^", it, " ~ c\\("), l) & grepl("\\*1", l); l[k] <- paste0(it, " ~ c(0, NA, NA)*1") }
  paste(l, collapse = "\n")
}
est <- function(s, m, g) cfa(s, data = por(g), group = g, ordered = lavNames(cfa(m, data = datos), "ov"),
                             group.label = levels(datos[[g]]), estimator = "WLSMV", parameterization = "theta")
n <- 20
for (esc in list(list("pub", m_pub, "Consumo sustentable y político"), list("dom", m_dom, "Prácticas domésticas"))) {
  for (g in c("Sexo", "Edad", "NSE")) {
    fits <- map(niveles, ~ est(sint(esc[[2]], g, .x), esc[[2]], g))
    if (g == "Edad") fits[["Escalar parcial"]] <- est(sint(esc[[2]], g, niveles$Escalar, libres_edad[[esc[[1]]]]), esc[[2]], g)
    n <- n + 1
    guardar(sprintf("%02d_invarianza_%s_%s", n, esc[[1]], tolower(g)),
            paste("Invarianza (Wu y Estabrook, WLSMV, theta):", esc[[3]], "por", g), {
      cat("Índices de ajuste por nivel:\n")
      print(round(t(sapply(fits, fitMeasures, c("chisq.scaled", "df", "pvalue.scaled", "cfi.scaled", "tli.scaled",
                                                 "rmsea.scaled", "rmsea.ci.lower.scaled", "rmsea.ci.upper.scaled", "srmr"))), 4))
      cat("\nPruebas de diferencia de chi-cuadrado escaladas entre niveles sucesivos:\n")
      for (k in 2:4) print(lavTestLRT(fits[[k]], fits[[k - 1]]))
      if (g == "Edad") { cat("\nEscalar parcial frente a métrico:\n"); print(lavTestLRT(fits[["Escalar parcial"]], fits[["Métrica"]])) }
      final <- if (g == "Edad") fits[["Escalar parcial"]] else fits[["Escalar"]]
      cat("\nModelo final (escalar", if (g == "Edad") "parcial" else "", "), estimaciones completas:\n")
      print(summary(final, fit.measures = TRUE, standardized = TRUE))
      cat("\nÍndices de modificación de los interceptos en el modelo escalar completo:\n")
      print(modindices(fits[["Escalar"]], op = "~1", free.remove = FALSE) %>% filter(mi > 0) %>% arrange(desc(mi)) %>% head(20))
    })
  }
}
guardar("99_versiones", "Versiones del software", { print(sessionInfo()) })
writeLines(unlist(salidas), file.path(dir, "salidas_tecnicas_completas.txt"))
